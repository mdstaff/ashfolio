defmodule Ashfolio.FinancialManagement.CategorySeeder do
  @moduledoc """
  Module for seeding investment system categories in the database-as-user architecture.

  Provides idempotent category seeding functionality that creates standard
  investment categories (Growth, Income, Speculative, Index, Cash, Bonds)
  while avoiding duplicates.

  ## Investment Categories

  The seeded categories are designed for investment portfolio management:

  - **Growth** (#10B981): Growth-oriented investments
  - **Income** (#3B82F6): Income-producing investments
  - **Speculative** (#F59E0B): High-risk/high-reward investments
  - **Index** (#8B5CF6): Index funds and ETFs
  - **Cash** (#6B7280): Cash and cash equivalents
  - **Bonds** (#059669): Fixed income investments

  ## Usage

      # Seed categories for the database-as-user architecture
      {:ok, categories} = CategorySeeder.seed_system_categories()

      # Safe to run multiple times - idempotent behavior
      {:ok, categories} = CategorySeeder.seed_system_categories()

  """

  alias Ashfolio.FinancialManagement.TransactionCategory

  require Ash.Query

  @doc """
  Seeds investment system categories for the database-as-user architecture.

  Creates 6 standard investment categories with predefined names and colors.
  This function is idempotent - running it multiple times will not create
  duplicate categories.

  ## Returns

  - `{:ok, categories}` - List of created/existing categories
  - `{:error, reason}` - Error tuple with failure reason

  ## Examples

      {:ok, categories} = CategorySeeder.seed_system_categories()
      assert length(categories) == 6

      # Running again returns same categories
      {:ok, same_categories} = CategorySeeder.seed_system_categories()
      assert length(same_categories) == 6

  """
  @spec seed_system_categories() :: {:ok, [TransactionCategory.t()]} | {:error, term()}
  def seed_system_categories do
    # Create or find categories (no user validation needed for database-as-user architecture)
    create_or_find_categories()
  end

  # Private helper functions

  @investment_categories [
    {"Growth", "#10B981"},
    {"Income", "#3B82F6"},
    {"Speculative", "#F59E0B"},
    {"Index", "#8B5CF6"},
    {"Cash", "#6B7280"},
    {"Bonds", "#059669"}
  ]

  defp create_or_find_categories do
    # Get existing categories (database-as-user architecture)
    existing_categories = get_existing_categories()
    existing_names = MapSet.new(existing_categories, & &1.name)

    # Create missing categories
    results =
      @investment_categories
      |> Enum.map(fn {name, color} ->
        if MapSet.member?(existing_names, name) do
          # Return existing category
          Enum.find(existing_categories, &(&1.name == name))
        else
          # Create new category
          case create_category(name, color) do
            {:ok, category} ->
              category

            {:error, _reason} ->
              # If creation fails, try to find existing (race condition handling)
              case find_category_by_name(name) do
                {:ok, category} when not is_nil(category) -> category
                _ -> nil
              end
          end
        end
      end)
      |> Enum.reject(&is_nil/1)

    # Verify we have all 6 categories
    if length(results) == 6 do
      {:ok, results}
    else
      {:error, :incomplete_seeding}
    end
  end

  defp get_existing_categories do
    case TransactionCategory.list() do
      {:ok, categories} -> categories
      {:error, _} -> []
    end
  end

  defp create_category(name, color) do
    TransactionCategory.create(%{
      name: name,
      color: color,
      is_system: true,
      parent_category_id: nil
    })
  end

  defp find_category_by_name(name) do
    query =
      TransactionCategory
      |> Ash.Query.filter(name == ^name)
      |> Ash.Query.limit(1)

    case Ash.read(query) do
      {:ok, [category]} -> {:ok, category}
      {:ok, []} -> {:ok, nil}
      {:error, reason} -> {:error, reason}
    end
  end
end
