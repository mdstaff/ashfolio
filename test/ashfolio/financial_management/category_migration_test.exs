defmodule Ashfolio.FinancialManagement.CategoryMigrationTest do
  @moduledoc """
  Integration tests for the category seeding migration.

  Tests the data migration that seeds investment categories for existing users
  who don't have categories yet. Ensures idempotent behavior and proper
  rollback functionality.
  """

  use Ashfolio.DataCase, async: false

  import Ecto.Query

  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Repo

  @moduletag :migration
  @moduletag :integration

  # Database-as-user architecture: No User entity needed
  describe "category seeding migration" do
    test "seeds categories for users without categories" do
      # Database-as-user architecture: test database state
      # Verify database has no categories initially
      {:ok, initial_categories} = TransactionCategory.list()
      assert Enum.empty?(initial_categories)

      # Simulate the migration logic
      simulate_migration_for_user()

      # Verify categories were created
      {:ok, final_categories} = TransactionCategory.list()
      assert length(final_categories) == 6

      # Verify correct categories were created
      expected_names = ["Growth", "Income", "Speculative", "Index", "Cash", "Bonds"]
      actual_names = final_categories |> Enum.map(& &1.name) |> Enum.sort()
      assert actual_names == Enum.sort(expected_names)

      # Verify all categories are system categories
      assert Enum.all?(final_categories, &(&1.is_system == true))

      # In database-as-user architecture, categories belong to the database
    end

    test "does not create duplicate categories when categories already exist" do
      # Database-as-user architecture: test database with existing categories
      # Create one category manually
      {:ok, _existing_category} =
        TransactionCategory.create(%{
          name: "Existing Category",
          color: "#FF0000",
          is_system: false
        })

      # Verify database has 1 category
      {:ok, initial_categories} = TransactionCategory.list()
      assert length(initial_categories) == 1

      # Simulate migration (should not create categories if they already exist)
      # In database-as-user architecture, check if categories exist
      {:ok, existing_categories} = TransactionCategory.list()
      categories_exist = length(existing_categories) > 0

      # Don't run migration if categories exist
      if !categories_exist do
        simulate_migration_for_user()
      end

      # Verify category count unchanged
      {:ok, final_categories} = TransactionCategory.list()
      assert length(final_categories) == 1
    end

    test "handles database without existing categories correctly" do
      # Database-as-user architecture: test database state, not multiple users
      # Ensure database starts empty
      {:ok, initial_categories} = TransactionCategory.list()
      assert Enum.empty?(initial_categories)

      # Simulate the migration process
      simulate_migration_for_user()

      # Verify seeded categories were created
      {:ok, final_categories} = TransactionCategory.list()
      assert length(final_categories) == 6

      # Verify all are system categories
      assert Enum.all?(final_categories, &(&1.is_system == true))
    end

    test "migration is idempotent" do
      # Database-as-user architecture: test migration idempotency

      # Run migration simulation twice
      simulate_migration_for_user()
      simulate_migration_for_user()

      # Should still have exactly 6 categories
      {:ok, categories} = TransactionCategory.list()
      assert length(categories) == 6
    end

    test "rollback removes only system categories" do
      # Database-as-user architecture: test rollback functionality
      # Start with empty database and simulate migration seeding
      simulate_migration_for_user()

      # Should have 6 system categories
      {:ok, categories_after_seeding} = TransactionCategory.list()
      assert length(categories_after_seeding) == 6

      # Now create a manual (non-system) category
      {:ok, manual_category} =
        TransactionCategory.create(%{
          name: "Manual Category",
          color: "#FF0000",
          is_system: false
        })

      # Should have 7 categories (6 system + 1 manual)
      {:ok, categories_with_manual} = TransactionCategory.list()
      assert length(categories_with_manual) == 7

      # Simulate rollback (remove system categories)
      simulate_migration_rollback()

      # Should have only 1 category (the manual one)
      {:ok, categories_after_rollback} = TransactionCategory.list()
      assert length(categories_after_rollback) == 1
      assert hd(categories_after_rollback).id == manual_category.id
    end
  end

  # Private helper functions that simulate the migration logic
  # Database-as-user architecture: No user-based queries needed

  defp simulate_migration_for_user do
    # Only seed if database has no categories (migration logic)
    {:ok, existing_categories} = TransactionCategory.list()

    if Enum.empty?(existing_categories) do
      investment_categories = [
        {"Growth", "#10B981"},
        {"Income", "#3B82F6"},
        {"Speculative", "#F59E0B"},
        {"Index", "#8B5CF6"},
        {"Cash", "#6B7280"},
        {"Bonds", "#059669"}
      ]

      # Use Ash.create instead of direct Ecto insert to ensure proper type handling
      Enum.each(investment_categories, fn {name, color} ->
        {:ok, _category} =
          TransactionCategory.create(%{
            name: name,
            color: color,
            is_system: true,
            parent_category_id: nil
          })
      end)
    end
  end

  defp simulate_migration_rollback do
    # Get all system categories and destroy them via direct SQL
    # This simulates the migration rollback behavior
    Repo.delete_all(
      from(tc in "transaction_categories",
        where: tc.is_system == true and tc.name in ["Growth", "Income", "Speculative", "Index", "Cash", "Bonds"]
      )
    )
  end
end
