defmodule Ashfolio.DataHelpers do
  @moduledoc """
  Common data transformation utilities used across LiveViews.

  Consolidates repetitive patterns for:
  - Date range filtering
  - Category/status filtering
  - List sorting and grouping
  - Aggregation calculations
  """

  @doc """
  Filters a collection by date range using common period names.

  ## Examples

      iex> today = Date.utc_today()
      iex> expenses = [%{date: Date.add(today, -10), id: 1}, %{date: Date.add(today, -200), id: 2}]
      iex> result = Ashfolio.DataHelpers.filter_by_date_range(expenses, "last_3_months")
      iex> length(result)
      1

      iex> snapshots = [%{snapshot_date: ~D[2023-09-01], id: 1}]
      iex> Ashfolio.DataHelpers.filter_by_date_range(snapshots, "all_time", :snapshot_date)
      [%{snapshot_date: ~D[2023-09-01], id: 1}]
  """
  def filter_by_date_range(collection, period, date_field \\ :date)

  def filter_by_date_range(collection, "current_month", date_field) do
    start_date = Date.beginning_of_month(Date.utc_today())
    filter_by_date_from(collection, start_date, date_field)
  end

  def filter_by_date_range(collection, "last_month", date_field) do
    today = Date.utc_today()
    start_date = today |> Date.beginning_of_month() |> Date.add(-1) |> Date.beginning_of_month()
    end_date = Date.end_of_month(start_date)
    filter_by_date_between(collection, start_date, end_date, date_field)
  end

  def filter_by_date_range(collection, "last_3_months", date_field) do
    start_date = Date.add(Date.utc_today(), -90)
    filter_by_date_from(collection, start_date, date_field)
  end

  def filter_by_date_range(collection, "last_6_months", date_field) do
    start_date = Date.add(Date.utc_today(), -180)
    filter_by_date_from(collection, start_date, date_field)
  end

  def filter_by_date_range(collection, "last_year", date_field) do
    start_date = Date.add(Date.utc_today(), -365)
    filter_by_date_from(collection, start_date, date_field)
  end

  def filter_by_date_range(collection, "all_time", _date_field) do
    collection
  end

  def filter_by_date_range(collection, _, date_field) do
    filter_by_date_range(collection, "last_6_months", date_field)
  end

  @doc """
  Filters collection by date from a specific date onwards.
  """
  def filter_by_date_from(collection, from_date, date_field \\ :date) do
    Enum.filter(collection, fn item ->
      item_date = Map.get(item, date_field)
      item_date && Date.compare(item_date, from_date) != :lt
    end)
  end

  @doc """
  Filters collection by date range between two dates.
  """
  def filter_by_date_between(collection, from_date, to_date, date_field \\ :date) do
    Enum.filter(collection, fn item ->
      item_date = Map.get(item, date_field)

      item_date &&
        Date.compare(item_date, from_date) != :lt &&
        Date.compare(item_date, to_date) != :gt
    end)
  end

  @doc """
  Groups collection by account ID.

  ## Examples

      iex> transactions = [%{account_id: 1, amount: 100}, %{account_id: 1, amount: 50}]
      iex> Ashfolio.DataHelpers.group_by_account(transactions)
      %{1 => [%{account_id: 1, amount: 100}, %{account_id: 1, amount: 50}]}
  """
  def group_by_account(collection) do
    Enum.group_by(collection, & &1.account_id)
  end

  @doc """
  Groups collection by category ID.
  """
  def group_by_category(collection) do
    Enum.group_by(collection, & &1.category_id)
  end

  @doc """
  Groups collection by a custom field.
  """
  def group_by_field(collection, field) do
    Enum.group_by(collection, &Map.get(&1, field))
  end

  @doc """
  Applies sorting to a collection with standard field extraction.

  ## Examples

      iex> goals = [%{name: "Car"}, %{name: "Emergency Fund"}]
      iex> Ashfolio.DataHelpers.sort_collection(goals, :name, :asc)
      [%{name: "Car"}, %{name: "Emergency Fund"}]

      iex> expenses = [%{amount: 1000}, %{amount: 500}]
      iex> Ashfolio.DataHelpers.sort_collection(expenses, :amount, :desc)
      [%{amount: 1000}, %{amount: 500}]
  """
  def sort_collection(collection, sort_by, sort_dir \\ :asc) do
    Enum.sort_by(collection, &get_sorting_key(&1, sort_by), sort_direction_to_sorter(sort_dir))
  end

  @doc """
  Filters collection by status with common status patterns.
  """
  def filter_by_status(collection, status, status_field \\ :status)

  def filter_by_status(collection, "", _status_field), do: collection
  def filter_by_status(collection, nil, _status_field), do: collection
  def filter_by_status(collection, "all", _status_field), do: collection

  def filter_by_status(collection, "active", status_field) do
    Enum.filter(collection, fn item ->
      status = Map.get(item, status_field)
      status == :active || has_active_flag?(item)
    end)
  end

  def filter_by_status(collection, "paused", status_field) do
    Enum.filter(collection, fn item ->
      status = Map.get(item, status_field)
      status == :paused || status == "paused"
    end)
  end

  def filter_by_status(collection, "completed", status_field) do
    Enum.filter(collection, fn item ->
      status = Map.get(item, status_field)
      status == :completed || status == "completed"
    end)
  end

  def filter_by_status(collection, target_status, status_field) do
    Enum.filter(collection, fn item ->
      status = Map.get(item, status_field)
      to_string(status) == to_string(target_status)
    end)
  end

  @doc """
  Filters collection by category ID or special category filters.
  """
  def filter_by_category_id(collection, category_filter, category_field \\ :category_id)

  def filter_by_category_id(collection, "", _category_field), do: collection
  def filter_by_category_id(collection, nil, _category_field), do: collection
  def filter_by_category_id(collection, "all", _category_field), do: collection

  def filter_by_category_id(collection, "uncategorized", category_field) do
    Enum.filter(collection, fn item ->
      category_id = Map.get(item, category_field)
      is_nil(category_id)
    end)
  end

  def filter_by_category_id(collection, category_id, category_field) when is_binary(category_id) do
    case Integer.parse(category_id) do
      {id, ""} ->
        Enum.filter(collection, fn item ->
          Map.get(item, category_field) == id
        end)

      _ ->
        collection
    end
  end

  def filter_by_category_id(collection, category_id, category_field) when is_integer(category_id) do
    Enum.filter(collection, fn item ->
      Map.get(item, category_field) == category_id
    end)
  end

  @doc """
  Calculates sum of a numeric field across collection.

  Handles both Decimal and regular numeric types.
  """
  def sum_field(collection, field) do
    Enum.reduce(collection, get_zero_value(collection, field), fn item, acc ->
      value = Map.get(item, field)
      add_values(acc, value)
    end)
  end

  @doc """
  Chains multiple filter operations together.

  ## Examples

      iex> expenses = [%{date: Date.utc_today(), category_id: 2, status: :active, amount: 100}]
      iex> result = Ashfolio.DataHelpers.filter_chain(expenses, [
      ...>   {:category_id, 2},
      ...>   {:status, "active"}
      ...> ])
      iex> length(result)
      1
  """
  def filter_chain(collection, filters) do
    Enum.reduce(filters, collection, fn filter, acc ->
      apply_filter(acc, filter)
    end)
  end

  # Private helpers

  defp get_sorting_key(item, :name), do: Map.get(item, :name) || ""
  defp get_sorting_key(item, :amount), do: Map.get(item, :amount) || 0
  defp get_sorting_key(item, :date), do: Map.get(item, :date) || Date.utc_today()
  defp get_sorting_key(item, :created_at), do: Map.get(item, :created_at) || DateTime.utc_now()
  defp get_sorting_key(item, :updated_at), do: Map.get(item, :updated_at) || DateTime.utc_now()
  defp get_sorting_key(item, field), do: Map.get(item, field)

  defp sort_direction_to_sorter(:asc), do: :asc
  defp sort_direction_to_sorter(:desc), do: :desc
  defp sort_direction_to_sorter("asc"), do: :asc
  defp sort_direction_to_sorter("desc"), do: :desc
  defp sort_direction_to_sorter(_), do: :asc

  defp get_zero_value([], _field), do: 0

  defp get_zero_value([first | _], field) do
    case Map.get(first, field) do
      %Decimal{} -> Decimal.new(0)
      _ -> 0
    end
  end

  defp add_values(%Decimal{} = acc, %Decimal{} = value), do: Decimal.add(acc, value)
  defp add_values(%Decimal{} = acc, value) when is_number(value), do: Decimal.add(acc, Decimal.new(value))
  defp add_values(acc, %Decimal{} = value) when is_number(acc), do: Decimal.add(Decimal.new(acc), value)
  defp add_values(acc, value) when is_number(acc) and is_number(value), do: acc + value
  defp add_values(acc, nil), do: acc
  defp add_values(acc, _), do: acc

  defp apply_filter(collection, {:date_range, period, field}) do
    filter_by_date_range(collection, period, field)
  end

  defp apply_filter(collection, {:date_range, period}) do
    filter_by_date_range(collection, period, :date)
  end

  defp apply_filter(collection, {:category_id, category_id}) do
    filter_by_category_id(collection, category_id, :category_id)
  end

  defp apply_filter(collection, {:category_id, category_id, field}) do
    filter_by_category_id(collection, category_id, field)
  end

  defp apply_filter(collection, {:status, status}) do
    filter_by_status(collection, status, :status)
  end

  defp apply_filter(collection, {:status, status, field}) do
    filter_by_status(collection, status, field)
  end

  defp apply_filter(collection, {:sort, field, direction}) do
    sort_collection(collection, field, direction)
  end

  defp apply_filter(collection, _unknown_filter), do: collection

  @doc """
  Predicate function to check if an item has the active flag set.

  Returns true if the item is a map with `is_active: true`, false otherwise.
  This is used as a fallback in status filtering when the main status field
  doesn't contain :active but the item should still be considered active.

  ## Examples

      iex> Ashfolio.DataHelpers.has_active_flag?(%{is_active: true})
      true

      iex> Ashfolio.DataHelpers.has_active_flag?(%{is_active: false})
      false

      iex> Ashfolio.DataHelpers.has_active_flag?(%{status: :active})
      false

      iex> Ashfolio.DataHelpers.has_active_flag?("active")
      false
  """
  def has_active_flag?(%{is_active: true}), do: true
  def has_active_flag?(_), do: false

  @doc """
  Predicate function to check if an item has the inactive flag set.

  Returns true if the item is a map with `is_active: false`, false otherwise.
  This provides the inverse check of `has_active_flag?/1`.

  ## Examples

      iex> Ashfolio.DataHelpers.has_inactive_flag?(%{is_active: false})
      true

      iex> Ashfolio.DataHelpers.has_inactive_flag?(%{is_active: true})
      false

      iex> Ashfolio.DataHelpers.has_inactive_flag?(%{status: :inactive})
      false

      iex> Ashfolio.DataHelpers.has_inactive_flag?("inactive")
      false
  """
  def has_inactive_flag?(%{is_active: false}), do: true
  def has_inactive_flag?(_), do: false
end
