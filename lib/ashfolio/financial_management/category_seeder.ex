defmodule Ashfolio.FinancialManagement.CategorySeeder do
  @moduledoc """
  Module for seeding investment system categories for users.

  Provides idempotent category seeding functionality that creates standard
  investment categories (Growth, Income, Speculative, Index, Cash, Bonds)
  for users while avoiding duplicates.

  ## Investment Categories

  The seeded categories are designed for investment portfolio management:

  - **Growth** (#10B981): Growth-oriented investments
  - **Income** (#3B82F6): Income-producing investments  
  - **Speculative** (#F59E0B): High-risk/high-reward investments
  - **Index** (#8B5CF6): Index funds and ETFs
  - **Cash** (#6B7280): Cash and cash equivalents
  - **Bonds** (#059669): Fixed income investments

  ## Usage

      # Seed categories for a specific user
      {:ok, categories} = CategorySeeder.seed_system_categories(user_id)
      
      # Safe to run multiple times - idempotent behavior
      {:ok, categories} = CategorySeeder.seed_system_categories(user_id)

  """

  require Ash.Query

  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Portfolio.User

  @doc """
  Seeds investment system categories for a specific user.

  Creates 6 standard investment categories with predefined names and colors.
  This function is idempotent - running it multiple times will not create
  duplicate categories.

  ## Parameters

  - `user_id` - The UUID of the user to seed categories for

  ## Returns

  - `{:ok, categories}` - List of created/existing categories
  - `{:error, reason}` - Error tuple with failure reason

  ## Examples

      {:ok, categories} = CategorySeeder.seed_system_categories(user.id)
      assert length(categories) == 6
      
      # Running again returns same categories
      {:ok, same_categories} = CategorySeeder.seed_system_categories(user.id)
      assert length(same_categories) == 6

  """
  @spec seed_system_categories(String.t()) :: {:ok, [TransactionCategory.t()]} | {:error, term()}
  def seed_system_categories(user_id) when is_binary(user_id) do
    # Validate user exists first
    case validate_user_exists(user_id) do
      {:ok, _user} ->
        # Create or find categories (no transaction wrapper needed for this simple case)
        create_or_find_categories(user_id)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def seed_system_categories(_invalid_user_id) do
    {:error, :invalid_user_id}
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

  defp validate_user_exists(user_id) do
    case User.get_by_id(user_id) do
      {:ok, user} when not is_nil(user) -> {:ok, user}
      {:ok, nil} -> {:error, :user_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp create_or_find_categories(user_id) do
    # Get existing categories for this user
    existing_categories = get_existing_categories(user_id)
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
          case create_category(user_id, name, color) do
            {:ok, category} ->
              category

            {:error, _reason} ->
              # If creation fails, try to find existing (race condition handling)
              case find_category_by_name(user_id, name) do
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

  defp get_existing_categories(user_id) do
    case TransactionCategory.categories_for_user(user_id) do
      {:ok, categories} -> categories
      {:error, _} -> []
    end
  end

  defp create_category(user_id, name, color) do
    TransactionCategory.create(%{
      name: name,
      color: color,
      is_system: true,
      user_id: user_id,
      parent_category_id: nil
    })
  end

  defp find_category_by_name(user_id, name) do
    query =
      TransactionCategory
      |> Ash.Query.filter(user_id == ^user_id and name == ^name)
      |> Ash.Query.limit(1)

    case Ash.read(query) do
      {:ok, [category]} -> {:ok, category}
      {:ok, []} -> {:ok, nil}
      {:error, reason} -> {:error, reason}
    end
  end
end
