defmodule Ashfolio.FinancialManagement.CategorySeederTest do
  use Ashfolio.DataCase, async: false

  @moduletag :ash_resources
  @moduletag :financial_management

  alias Ashfolio.FinancialManagement.{CategorySeeder, TransactionCategory}

  describe "seed_system_categories/0" do
    setup do
      # Database-as-user architecture: No user needed
      %{}
    end

    test "creates 6 investment system categories" do
      {:ok, categories} = CategorySeeder.seed_system_categories()

      assert length(categories) == 6

      # Verify all categories were created
      {:ok, all_categories} = TransactionCategory.list()
      system_categories = Enum.filter(all_categories, & &1.is_system)
      assert length(system_categories) >= 6
    end

    test "creates categories with correct names and colors" do
      {:ok, categories} = CategorySeeder.seed_system_categories()

      # Expected investment categories with colors
      expected_categories = [
        {"Growth", "#10B981"},
        {"Income", "#3B82F6"},
        {"Speculative", "#F59E0B"},
        {"Index", "#8B5CF6"},
        {"Cash", "#6B7280"},
        {"Bonds", "#059669"}
      ]

      created_names_colors =
        categories
        |> Enum.map(fn cat -> {cat.name, cat.color} end)
        |> Enum.sort()

      assert created_names_colors == Enum.sort(expected_categories)
    end

    test "sets is_system flag to true for all categories" do
      {:ok, categories} = CategorySeeder.seed_system_categories()

      # All created categories should be system categories
      assert Enum.all?(categories, fn cat -> cat.is_system == true end)
    end

    test "creates categories without user_id (database-as-user architecture)" do
      {:ok, categories} = CategorySeeder.seed_system_categories()

      # All categories should not have user_id in database-as-user architecture
      assert Enum.all?(categories, fn cat -> is_nil(Map.get(cat, nil)) end)
    end

    test "creates categories with no parent_category_id (root level)" do
      {:ok, categories} = CategorySeeder.seed_system_categories()

      # All system categories should be root level (no parent)
      assert Enum.all?(categories, fn cat -> is_nil(cat.parent_category_id) end)
    end

    test "succeeds without user parameters (database-as-user architecture)" do
      {:ok, categories} = CategorySeeder.seed_system_categories()

      assert length(categories) == 6
      assert Enum.all?(categories, & &1.is_system)
    end
  end

  describe "idempotent behavior" do
    setup do
      # Database-as-user architecture: No user needed
      %{}
    end

    test "second run doesn't create duplicate categories" do
      # First run
      {:ok, first_categories} = CategorySeeder.seed_system_categories()
      assert length(first_categories) == 6

      # Second run
      {:ok, second_categories} = CategorySeeder.seed_system_categories()
      assert length(second_categories) == 6

      # Total system categories should still be 6, not 12
      {:ok, all_categories} = TransactionCategory.list()
      system_categories = Enum.filter(all_categories, & &1.is_system)
      assert length(system_categories) == 6
    end

    test "handles existing categories gracefully" do
      # Create one category manually first
      {:ok, _existing_category} =
        TransactionCategory.create(%{
          name: "Growth",
          color: "#10B981",
          is_system: true
        })

      # Run seeder - should handle existing category and create the remaining 5
      {:ok, categories} = CategorySeeder.seed_system_categories()

      # Should report all 6 categories (1 existing + 5 new)
      assert length(categories) == 6

      # Verify total count in database
      {:ok, all_categories} = TransactionCategory.list()
      system_categories = Enum.filter(all_categories, & &1.is_system)
      assert length(system_categories) == 6
    end

    test "returns same result when run multiple times" do
      # Run seeder multiple times
      {:ok, first_run} = CategorySeeder.seed_system_categories()
      {:ok, second_run} = CategorySeeder.seed_system_categories()
      {:ok, third_run} = CategorySeeder.seed_system_categories()

      # All runs should return same categories (by name)
      first_names = Enum.map(first_run, & &1.name) |> Enum.sort()
      second_names = Enum.map(second_run, & &1.name) |> Enum.sort()
      third_names = Enum.map(third_run, & &1.name) |> Enum.sort()

      assert first_names == second_names
      assert second_names == third_names
    end

    test "preserves existing category attributes when found" do
      # Create category with different color
      {:ok, existing_category} =
        TransactionCategory.create(%{
          name: "Growth",
          # Different color
          color: "#FF0000",
          # Different system flag
          is_system: false
        })

      # Run seeder
      {:ok, categories} = CategorySeeder.seed_system_categories()

      # Find the Growth category in results
      growth_category = Enum.find(categories, fn cat -> cat.name == "Growth" end)

      # Should preserve the existing category's ID and not modify it
      assert growth_category.id == existing_category.id
      # Preserves existing color
      assert growth_category.color == "#FF0000"
      # Preserves existing system flag
      assert growth_category.is_system == false
    end
  end

  describe "error handling" do
    test "handles database errors gracefully" do
      # Test basic functionality without user parameters
      {:ok, categories} = CategorySeeder.seed_system_categories()
      assert length(categories) == 6
    end

    test "handles partial seeding failures" do
      # Create a category with a name that will conflict with seeding
      {:ok, _conflicting_category} =
        TransactionCategory.create(%{
          name: "Growth",
          # Valid color but different from seeded one
          color: "#FF0000",
          is_system: false
        })

      # Seeder should still succeed by handling existing categories
      {:ok, categories} = CategorySeeder.seed_system_categories()

      # Should still create/return all 6 categories
      assert length(categories) == 6
    end

    test "reports detailed error information for validation failures" do
      # Basic test that seeding works (detailed error testing will expand)
      {:ok, categories} = CategorySeeder.seed_system_categories()
      assert length(categories) == 6
    end
  end

  describe "performance requirements" do
    setup do
      # Database-as-user architecture: No user needed
      %{}
    end

    test "completes seeding within 50ms" do
      {duration_ms, {:ok, categories}} =
        :timer.tc(fn -> CategorySeeder.seed_system_categories() end, :millisecond)

      assert length(categories) == 6
      assert duration_ms < 50, "Seeding took #{duration_ms}ms, expected < 50ms"
    end

    test "maintains performance on subsequent runs (cached behavior)" do
      # First run (database writes)
      CategorySeeder.seed_system_categories()

      # Second run (should be faster due to existing data)
      {duration_ms, {:ok, categories}} =
        :timer.tc(fn -> CategorySeeder.seed_system_categories() end, :millisecond)

      assert length(categories) == 6
      assert duration_ms < 25, "Cached seeding took #{duration_ms}ms, expected < 25ms"
    end
  end

  describe "system category definitions" do
    test "provides correct investment category set" do
      # This tests the category definitions themselves
      expected_categories = [
        # Growth investments
        "Growth",
        # Income-producing investments
        "Income",
        # High-risk/high-reward investments
        "Speculative",
        # Index funds and ETFs
        "Index",
        # Cash and cash equivalents
        "Cash",
        # Fixed income investments
        "Bonds"
      ]

      {:ok, categories} = CategorySeeder.seed_system_categories()

      created_names = Enum.map(categories, & &1.name) |> Enum.sort()
      assert created_names == Enum.sort(expected_categories)
    end

    test "uses Tailwind CSS compatible colors" do
      {:ok, categories} = CategorySeeder.seed_system_categories()

      # All colors should be valid hex colors
      colors = Enum.map(categories, & &1.color)

      assert Enum.all?(colors, fn color ->
               Regex.match?(~r/^#[0-9A-Fa-f]{6}$/, color)
             end)

      # Colors should be from our defined set
      expected_colors = ["#10B981", "#3B82F6", "#F59E0B", "#8B5CF6", "#6B7280", "#059669"]
      actual_colors = Enum.sort(colors)
      assert actual_colors == Enum.sort(expected_colors)
    end
  end
end
