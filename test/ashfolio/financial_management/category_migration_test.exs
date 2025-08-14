defmodule Ashfolio.FinancialManagement.CategoryMigrationTest do
  @moduledoc """
  Integration tests for the category seeding migration.

  Tests the data migration that seeds investment categories for existing users
  who don't have categories yet. Ensures idempotent behavior and proper
  rollback functionality.
  """

  use Ashfolio.DataCase, async: false

  @moduletag :migration
  @moduletag :integration

  alias Ashfolio.Portfolio.User
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Repo

  import Ecto.Query

  describe "category seeding migration" do
    test "seeds categories for users without categories" do
      # Create a user without categories
      {:ok, user} =
        User.create(%{
          name: "Migration Test User",
          currency: "USD",
          locale: "en-US"
        })

      # Verify user has no categories initially
      {:ok, initial_categories} = TransactionCategory.categories_for_user(user.id)
      assert length(initial_categories) == 0

      # Simulate the migration logic
      simulate_migration_for_user(user.id)

      # Verify categories were created
      {:ok, final_categories} = TransactionCategory.categories_for_user(user.id)
      assert length(final_categories) == 6

      # Verify correct categories were created
      expected_names = ["Growth", "Income", "Speculative", "Index", "Cash", "Bonds"]
      actual_names = Enum.map(final_categories, & &1.name) |> Enum.sort()
      assert actual_names == Enum.sort(expected_names)

      # Verify all categories are system categories
      assert Enum.all?(final_categories, &(&1.is_system == true))

      # Verify all categories belong to the user
      assert Enum.all?(final_categories, &(&1.user_id == user.id))
    end

    test "does not create duplicate categories for users who already have categories" do
      # Create a user and give them some categories
      {:ok, user} =
        User.create(%{
          name: "User With Categories",
          currency: "USD",
          locale: "en-US"
        })

      # Create one category manually
      {:ok, _existing_category} =
        TransactionCategory.create(%{
          name: "Existing Category",
          color: "#FF0000",
          is_system: false,
          user_id: user.id
        })

      # Verify user has 1 category
      {:ok, initial_categories} = TransactionCategory.categories_for_user(user.id)
      assert length(initial_categories) == 1

      # Simulate migration (should not create categories for this user)
      users_without_categories = find_users_without_categories()
      refute user.id in users_without_categories

      # Verify category count unchanged
      {:ok, final_categories} = TransactionCategory.categories_for_user(user.id)
      assert length(final_categories) == 1
    end

    test "handles multiple users correctly" do
      # Create multiple users - some with categories, some without
      {:ok, user1} = User.create(%{name: "User 1", currency: "USD", locale: "en-US"})
      {:ok, user2} = User.create(%{name: "User 2", currency: "USD", locale: "en-US"})
      {:ok, user3} = User.create(%{name: "User 3", currency: "USD", locale: "en-US"})

      # Give user2 a category
      {:ok, _category} =
        TransactionCategory.create(%{
          name: "Manual Category",
          color: "#FF0000",
          is_system: false,
          user_id: user2.id
        })

      # Find users without categories
      users_without_categories = find_users_without_categories()

      # user1 and user3 should be in the list, user2 should not
      assert user1.id in users_without_categories
      assert user3.id in users_without_categories
      refute user2.id in users_without_categories

      # Simulate seeding for users without categories
      Enum.each([user1.id, user3.id], &simulate_migration_for_user/1)

      # Verify results
      {:ok, user1_categories} = TransactionCategory.categories_for_user(user1.id)
      {:ok, user2_categories} = TransactionCategory.categories_for_user(user2.id)
      {:ok, user3_categories} = TransactionCategory.categories_for_user(user3.id)

      # Got seeded categories
      assert length(user1_categories) == 6
      # Still has only manual category
      assert length(user2_categories) == 1
      # Got seeded categories
      assert length(user3_categories) == 6
    end

    test "migration is idempotent" do
      # Create a user
      {:ok, user} =
        User.create(%{
          name: "Idempotent Test User",
          currency: "USD",
          locale: "en-US"
        })

      # Run migration simulation twice
      simulate_migration_for_user(user.id)
      simulate_migration_for_user(user.id)

      # Should still have exactly 6 categories
      {:ok, categories} = TransactionCategory.categories_for_user(user.id)
      assert length(categories) == 6
    end

    test "rollback removes only system categories" do
      # Create user without any categories first
      {:ok, user} =
        User.create(%{
          name: "Rollback Test User",
          currency: "USD",
          locale: "en-US"
        })

      # Simulate migration seeding (user has no categories, so seeding will happen)
      simulate_migration_for_user(user.id)

      # Should have 6 system categories
      {:ok, categories_after_seeding} = TransactionCategory.categories_for_user(user.id)
      assert length(categories_after_seeding) == 6

      # Now create a manual (non-system) category
      {:ok, manual_category} =
        TransactionCategory.create(%{
          name: "Manual Category",
          color: "#FF0000",
          is_system: false,
          user_id: user.id
        })

      # Should have 7 categories (6 system + 1 manual)
      {:ok, categories_with_manual} = TransactionCategory.categories_for_user(user.id)
      assert length(categories_with_manual) == 7

      # Simulate rollback (remove system categories)
      simulate_migration_rollback()

      # Should have only 1 category (the manual one)
      {:ok, categories_after_rollback} = TransactionCategory.categories_for_user(user.id)
      assert length(categories_after_rollback) == 1
      assert hd(categories_after_rollback).id == manual_category.id
    end
  end

  # Private helper functions that simulate the migration logic

  defp find_users_without_categories do
    from(u in "users",
      left_join: tc in "transaction_categories",
      on: tc.user_id == u.id,
      where: is_nil(tc.id),
      select: u.id,
      distinct: true
    )
    |> Repo.all()
  end

  defp simulate_migration_for_user(user_id) do
    # Only seed if user has no categories (migration logic)
    {:ok, existing_categories} = TransactionCategory.categories_for_user(user_id)

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
            user_id: user_id,
            parent_category_id: nil
          })
      end)
    end
  end

  defp simulate_migration_rollback do
    # Get all system categories and destroy them via direct SQL
    # This simulates the migration rollback behavior
    from(tc in "transaction_categories",
      where:
        tc.is_system == true and
          tc.name in ["Growth", "Income", "Speculative", "Index", "Cash", "Bonds"]
    )
    |> Repo.delete_all()
  end
end
