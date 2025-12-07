defmodule Ashfolio.FinancialManagement.TransactionFiltering do
  @moduledoc """
  Enhanced server-side filtering for investment transactions.
  """

  alias Ashfolio.Portfolio.Transaction

  require Ash.Query

  @doc """
  Apply filters to transactions based on provided criteria.
  Returns an Ash.Query that can be further modified (e.g. paginated) or executed.
  """
  @spec apply_filters(map()) :: {:ok, Ash.Query.t()} | {:error, String.t()}
  def apply_filters(filter_criteria) when is_map(filter_criteria) do
    with {:ok, base_query} <- build_base_query(),
         {:ok, filtered_query} <- apply_category_filter(base_query, filter_criteria),
         {:ok, filtered_query} <- apply_date_range_filter(filtered_query, filter_criteria),
         {:ok, filtered_query} <- apply_transaction_type_filter(filtered_query, filter_criteria) do
      apply_amount_range_filter(filtered_query, filter_criteria)
    end
  end

  def apply_filters(_invalid_criteria) do
    {:error, "Filter criteria must be a map"}
  end

  defp build_base_query do
    query =
      Transaction
      |> Ash.Query.sort(date: :desc, category_id: :asc, inserted_at: :desc)
      |> Ash.Query.load([:account, :symbol, :category])

    {:ok, query}
  end

  defp apply_category_filter(query, %{category: category_filter}) do
    case category_filter do
      :all -> {:ok, query}
      :uncategorized -> {:ok, Ash.Query.filter(query, is_nil(category_id))}
      category_id when is_binary(category_id) -> {:ok, Ash.Query.filter(query, category_id == ^category_id)}
      category_ids when is_list(category_ids) -> {:ok, Ash.Query.filter(query, category_id in ^category_ids)}
      nil -> {:ok, query}
      _ -> {:error, "Invalid category filter format"}
    end
  end

  defp apply_category_filter(query, _), do: {:ok, query}

  defp apply_date_range_filter(query, %{date_range: {start_date, end_date}})
       when not is_nil(start_date) and not is_nil(end_date) do
    if Date.compare(start_date, end_date) in [:lt, :eq] do
      {:ok, Ash.Query.filter(query, date >= ^start_date and date <= ^end_date)}
    else
      {:error, "Invalid date range"}
    end
  end

  defp apply_date_range_filter(query, _), do: {:ok, query}

  defp apply_transaction_type_filter(query, %{transaction_type: type}) when is_atom(type) and type != :all do
    valid_types = [:buy, :sell, :dividend, :fee, :interest, :liability]

    if type in valid_types do
      {:ok, Ash.Query.filter(query, type == ^type)}
    else
      {:error, "Invalid transaction type"}
    end
  end

  defp apply_transaction_type_filter(query, _), do: {:ok, query}

  defp apply_amount_range_filter(query, %{amount_range: {min, max}}) do
    {:ok, Ash.Query.filter(query, total_amount >= ^min and total_amount <= ^max)}
  end

  defp apply_amount_range_filter(query, _), do: {:ok, query}
end
