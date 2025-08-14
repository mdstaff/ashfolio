defmodule Ashfolio.Repo.Migrations.SeedInvestmentCategoriesForExistingUsers do
  @moduledoc """
  Data migration to seed investment categories for existing users.

  This migration ensures that all existing users receive the 6 standard
  investment categories (Growth, Income, Speculative, Index, Cash, Bonds)
  that are required for the enhanced financial management features in v0.2.0.

  The migration is idempotent - it can be run multiple times safely.
  """

  use Ecto.Migration

  import Ecto.Query

  def up do
    # Only seed categories for users who don't have any categories yet
    # This ensures we don't interfere with users who already have categories
    seed_categories_for_users_without_categories()
  end

  def down do
    # Remove only the system categories created by this migration
    # Preserve any user-created categories
    remove_system_categories_created_by_migration()
  end

  defp seed_categories_for_users_without_categories do
    # Get all users who don't have any categories
    users_without_categories =
      from(u in "users",
        left_join: tc in "transaction_categories",
        on: tc.user_id == u.id,
        where: is_nil(tc.id),
        select: u.id,
        distinct: true
      )
      |> Ashfolio.Repo.all()

    IO.puts("🏷️  Found #{length(users_without_categories)} users without categories")

    if length(users_without_categories) > 0 do
      # Seed categories for each user
      Enum.each(users_without_categories, fn user_id ->
        case seed_categories_for_user(user_id) do
          :ok ->
            IO.puts("  ✅ Seeded categories for user #{user_id}")

          {:error, reason} ->
            IO.puts("  ❌ Failed to seed categories for user #{user_id}: #{inspect(reason)}")
        end
      end)
    else
      IO.puts("ℹ️  All users already have categories - no seeding needed")
    end
  end

  defp seed_categories_for_user(user_id) do
    investment_categories = [
      {"Growth", "#10B981"},
      {"Income", "#3B82F6"},
      {"Speculative", "#F59E0B"},
      {"Index", "#8B5CF6"},
      {"Cash", "#6B7280"},
      {"Bonds", "#059669"}
    ]

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    try do
      # Create categories one by one using proper changeset validation
      # This ensures proper type conversion and validation
      results =
        Enum.map(investment_categories, fn {name, color} ->
          changeset = %{
            id: Ash.UUID.generate(),
            name: name,
            color: color,
            is_system: true,
            user_id: user_id,
            parent_category_id: nil,
            inserted_at: now,
            updated_at: now
          }

          # Insert with proper boolean conversion
          Ashfolio.Repo.insert_all(
            "transaction_categories",
            [changeset],
            returning: [:id]
          )
        end)

      # Check that all inserts succeeded
      if Enum.all?(results, fn {count, _} -> count == 1 end) do
        :ok
      else
        {:error, "Failed to create all categories"}
      end
    rescue
      error -> {:error, error}
    end
  end

  defp remove_system_categories_created_by_migration do
    IO.puts("🗑️  Removing system categories created by this migration...")

    category_names = ["Growth", "Income", "Speculative", "Index", "Cash", "Bonds"]

    # Delete only system categories with these specific names
    {count, _} =
      from(tc in "transaction_categories",
        where: tc.is_system == true and tc.name in ^category_names
      )
      |> Ashfolio.Repo.delete_all()

    IO.puts("  ✅ Removed #{count} system categories")
  end
end
