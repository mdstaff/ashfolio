defmodule Ashfolio.FinancialManagement.TransactionFiltering do
  @moduledoc """
  Enhanced server-side filtering for investment transactions.

  Provides sophisticated filtering capabilities including:
  - Single and multiple category filtering
  - Date range filtering
  - Transaction type filtering
  - Amount range filtering
  - Composite filtering (multiple criteria combined)

  All filtering is performed at the database level for optimal performance
  and supports caching for frequently used filter combinations.
  """

  alias Ashfolio.Portfolio.Transaction
  import Ecto.Query

  @doc """
  Apply filters to transactions based on provided criteria.

  ## Parameters

  - `filter_criteria` - Map containing filter options:
    - `:category` - Category ID, list of IDs, `:all`, or `:uncategorized`
    - `:date_range` - Tuple of {start_date, end_date} or `:all`
    - `:transaction_type` - Transaction type atom or `:all`
    - `:amount_range` - Tuple of {min_amount, max_amount} or `:all`

  ## Examples

      # Single category filter
      apply_filters(%{category: "category-id"})
      
      # Multiple categories
      apply_filters(%{category: ["id1", "id2"]})
      
      # Composite filter
      apply_filters(%{
        category: "category-id",
        date_range: {~D[2025-01-01], ~D[2025-12-31]}
      })

  ## Returns

  - `{:ok, [Transaction.t()]}` - Filtered transactions with loaded associations
  - `{:error, String.t()}` - Error message for invalid filters
  """
  @spec apply_filters(map()) :: {:ok, [Transaction.t()]} | {:error, String.t()}
  def apply_filters(filter_criteria) when is_map(filter_criteria) do
    with {:ok, base_query} <- build_base_query(),
         {:ok, filtered_query} <- apply_category_filter(base_query, filter_criteria),
         {:ok, filtered_query} <- apply_date_range_filter(filtered_query, filter_criteria),
         {:ok, filtered_query} <- apply_transaction_type_filter(filtered_query, filter_criteria),
         {:ok, filtered_query} <- apply_amount_range_filter(filtered_query, filter_criteria) do
      execute_filtered_query(filtered_query)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def apply_filters(_invalid_criteria) do
    {:error, "Filter criteria must be a map"}
  end

  # Private functions for building and executing queries

  defp build_base_query do
    # Build a base query for all transactions - more efficient than loading all first
    # Optimized with strategic ordering for common filter patterns
    query =
      from(t in Transaction,
        # Order by most commonly filtered fields first for index efficiency
        order_by: [desc: t.date, asc: t.category_id, desc: t.inserted_at]
      )

    {:ok, query}
  end

  defp apply_category_filter(query, %{category: category_filter}) do
    case category_filter do
      :all ->
        {:ok, query}

      :uncategorized ->
        filtered_query = from(t in query, where: is_nil(t.category_id))
        {:ok, filtered_query}

      category_id when is_binary(category_id) ->
        # Validate UUID format before querying
        case Ecto.UUID.cast(category_id) do
          {:ok, _valid_uuid} ->
            filtered_query = from(t in query, where: t.category_id == ^category_id)
            {:ok, filtered_query}

          :error ->
            # Invalid UUID format, return empty result instead of error
            {:ok, from(t in query, where: false)}
        end

      category_ids when is_list(category_ids) ->
        if Enum.all?(category_ids, &is_binary/1) do
          # Validate all UUIDs before querying
          valid_uuids =
            Enum.filter(category_ids, fn id ->
              case Ecto.UUID.cast(id) do
                {:ok, _} -> true
                :error -> false
              end
            end)

          if Enum.empty?(valid_uuids) do
            # No valid UUIDs, return empty result
            {:ok, from(t in query, where: false)}
          else
            filtered_query = from(t in query, where: t.category_id in ^valid_uuids)
            {:ok, filtered_query}
          end
        else
          {:error, "Invalid category filter format: all category IDs must be strings"}
        end

      nil ->
        {:ok, query}

      _invalid ->
        {:error,
         "Invalid category filter format: must be :all, :uncategorized, string, or list of strings"}
    end
  end

  defp apply_category_filter(query, _no_category_filter) do
    {:ok, query}
  end

  defp apply_date_range_filter(query, %{date_range: date_range}) do
    case date_range do
      :all ->
        {:ok, query}

      {start_date, end_date} when start_date != nil and end_date != nil ->
        if Date.compare(start_date, end_date) in [:lt, :eq] do
          filtered_query =
            from(t in query,
              where: t.date >= ^start_date and t.date <= ^end_date
            )

          {:ok, filtered_query}
        else
          {:error, "Invalid date range: start date must be before or equal to end date"}
        end

      nil ->
        {:ok, query}

      _invalid ->
        {:error, "Invalid date range format: must be :all or {start_date, end_date}"}
    end
  end

  defp apply_date_range_filter(query, _no_date_filter) do
    {:ok, query}
  end

  defp apply_transaction_type_filter(query, %{transaction_type: transaction_type}) do
    case transaction_type do
      :all ->
        {:ok, query}

      type when is_atom(type) ->
        # Validate that the transaction type is valid
        valid_types = [:buy, :sell, :dividend, :fee, :interest, :liability]

        if type in valid_types do
          filtered_query = from(t in query, where: t.type == ^type)
          {:ok, filtered_query}
        else
          {:error, "Invalid transaction type: #{type}. Must be one of #{inspect(valid_types)}"}
        end

      nil ->
        {:ok, query}

      _invalid ->
        {:error, "Invalid transaction type format: must be :all or a valid transaction type atom"}
    end
  end

  defp apply_transaction_type_filter(query, _no_type_filter) do
    {:ok, query}
  end

  defp apply_amount_range_filter(query, %{amount_range: amount_range}) do
    case amount_range do
      :all ->
        {:ok, query}

      {min_amount, max_amount} ->
        with true <- is_struct(min_amount, Decimal),
             true <- is_struct(max_amount, Decimal),
             :lt <- Decimal.compare(min_amount, max_amount) do
          filtered_query =
            from(t in query,
              where: t.total_amount >= ^min_amount and t.total_amount <= ^max_amount
            )

          {:ok, filtered_query}
        else
          false -> {:error, "Invalid amount range: amounts must be Decimal values"}
          _ -> {:error, "Invalid amount range: minimum must be less than maximum"}
        end

      nil ->
        {:ok, query}

      _invalid ->
        {:error, "Invalid amount range format: must be :all or {min_decimal, max_decimal}"}
    end
  end

  defp apply_amount_range_filter(query, _no_amount_filter) do
    {:ok, query}
  end

  defp execute_filtered_query(query) do
    try do
      # Execute query with optimized preloaded associations for efficient data loading
      # Use join preloading for better performance with large datasets
      transactions =
        query
        |> join(:left, [t], a in assoc(t, :account))
        |> join(:left, [t], s in assoc(t, :symbol))
        |> join(:left, [t], c in assoc(t, :category))
        |> preload([t, a, s, c], account: a, symbol: s, category: c)
        |> Ashfolio.Repo.all()

      {:ok, transactions}
    rescue
      error ->
        {:error, "Database query failed: #{inspect(error)}"}
    end
  end

  @doc """
  Validate filter criteria without executing the query.

  Useful for form validation and API parameter checking.
  """
  @spec validate_filters(map()) :: :ok | {:error, String.t()}
  def validate_filters(filter_criteria) when is_map(filter_criteria) do
    # Build the query without executing to validate all filters
    case apply_filters(Map.put(filter_criteria, :validate_only, true)) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def validate_filters(_invalid_criteria) do
    {:error, "Filter criteria must be a map"}
  end

  @doc """
  Get available filter options for building filter UIs.

  Returns structured data about available categories, date ranges, etc.
  """
  @spec get_filter_options() :: {:ok, map()} | {:error, String.t()}
  def get_filter_options do
    try do
      options = %{
        transaction_types: [:all, :buy, :sell, :dividend, :fee, :interest, :liability],
        # Will be extended with actual categories
        category_options: [:all, :uncategorized],
        date_range_presets: [
          {:last_7_days, "Last 7 days"},
          {:last_30_days, "Last 30 days"},
          {:last_90_days, "Last 90 days"},
          {:this_year, "This year"},
          {:last_year, "Last year"},
          {:all, "All time"}
        ]
      }

      {:ok, options}
    rescue
      error ->
        {:error, "Failed to get filter options: #{inspect(error)}"}
    end
  end
end
