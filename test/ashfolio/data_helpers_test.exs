defmodule Ashfolio.DataHelpersTest do
  use ExUnit.Case, async: true

  alias Ashfolio.DataHelpers

  doctest DataHelpers

  describe "filter_by_date_range/3" do
    setup do
      today = Date.utc_today()
      current_month_start = Date.beginning_of_month(today)

      expenses = [
        # > 1 year ago
        %{date: Date.add(today, -400), amount: Decimal.new("100")},
        # ~6-7 months ago
        %{date: Date.add(today, -200), amount: Decimal.new("200")},
        # ~3 months ago
        %{date: Date.add(today, -100), amount: Decimal.new("300")},
        # ~1.5 months ago
        %{date: Date.add(today, -50), amount: Decimal.new("400")},
        # current month start
        %{date: current_month_start, amount: Decimal.new("500")},
        # today
        %{date: today, amount: Decimal.new("600")}
      ]

      snapshots = [
        %{snapshot_date: Date.add(today, -200), value: Decimal.new("1000")},
        %{snapshot_date: Date.add(today, -30), value: Decimal.new("2000")},
        %{snapshot_date: today, value: Decimal.new("3000")}
      ]

      {:ok, expenses: expenses, snapshots: snapshots, today: today}
    end

    test "filters by current_month", %{expenses: expenses} do
      result = DataHelpers.filter_by_date_range(expenses, "current_month")
      assert length(result) == 2
      assert Enum.all?(result, &(&1.amount in [Decimal.new("500"), Decimal.new("600")]))
    end

    test "filters by last_3_months", %{expenses: expenses} do
      result = DataHelpers.filter_by_date_range(expenses, "last_3_months")
      # Should include: current month start, today, 50 days ago, 100 days ago (if within 90 days)
      assert length(result) >= 3
    end

    test "filters by last_6_months", %{expenses: expenses} do
      result = DataHelpers.filter_by_date_range(expenses, "last_6_months")
      # Should include: current month start, today, 50 days ago, 100 days ago (if within 180 days)
      assert length(result) >= 4
    end

    test "filters by last_year", %{expenses: expenses} do
      result = DataHelpers.filter_by_date_range(expenses, "last_year")
      # Should include: current month start, today, 50 days ago, 100 days ago, 200 days ago (if within 365 days)
      assert length(result) >= 5
    end

    test "returns all for all_time", %{expenses: expenses} do
      result = DataHelpers.filter_by_date_range(expenses, "all_time")
      assert length(result) == 6
    end

    test "defaults to last_6_months for unknown period", %{expenses: expenses} do
      result = DataHelpers.filter_by_date_range(expenses, "unknown_period")
      assert length(result) >= 4
    end

    test "works with custom date field", %{snapshots: snapshots} do
      result = DataHelpers.filter_by_date_range(snapshots, "last_6_months", :snapshot_date)
      assert length(result) == 2
    end
  end

  describe "filter_by_date_from/3" do
    setup do
      today = Date.utc_today()

      collection = [
        %{date: Date.add(today, -10), id: 1},
        %{date: Date.add(today, -5), id: 2},
        %{date: today, id: 3}
      ]

      {:ok, collection: collection, today: today}
    end

    test "filters from specific date", %{collection: collection, today: today} do
      from_date = Date.add(today, -7)
      result = DataHelpers.filter_by_date_from(collection, from_date)

      assert length(result) == 2
      assert Enum.map(result, & &1.id) == [2, 3]
    end

    test "works with custom field", %{today: today} do
      collection = [%{created_at: Date.add(today, -5), id: 1}, %{created_at: today, id: 2}]
      from_date = Date.add(today, -3)

      result = DataHelpers.filter_by_date_from(collection, from_date, :created_at)
      assert length(result) == 1
      assert hd(result).id == 2
    end
  end

  describe "filter_by_date_between/4" do
    test "filters between two dates" do
      today = Date.utc_today()

      collection = [
        %{date: Date.add(today, -10), id: 1},
        %{date: Date.add(today, -5), id: 2},
        %{date: today, id: 3}
      ]

      from_date = Date.add(today, -7)
      to_date = Date.add(today, -3)

      result = DataHelpers.filter_by_date_between(collection, from_date, to_date)
      assert length(result) == 1
      assert hd(result).id == 2
    end
  end

  describe "grouping functions" do
    setup do
      transactions = [
        %{account_id: 1, category_id: 10, amount: 100},
        %{account_id: 1, category_id: 20, amount: 200},
        %{account_id: 2, category_id: 10, amount: 300},
        %{account_id: 2, category_id: 20, amount: 400}
      ]

      {:ok, transactions: transactions}
    end

    test "group_by_account/1", %{transactions: transactions} do
      result = DataHelpers.group_by_account(transactions)

      assert Map.has_key?(result, 1)
      assert Map.has_key?(result, 2)
      assert length(result[1]) == 2
      assert length(result[2]) == 2
    end

    test "group_by_category/1", %{transactions: transactions} do
      result = DataHelpers.group_by_category(transactions)

      assert Map.has_key?(result, 10)
      assert Map.has_key?(result, 20)
      assert length(result[10]) == 2
      assert length(result[20]) == 2
    end

    test "group_by_field/2", %{transactions: transactions} do
      result = DataHelpers.group_by_field(transactions, :account_id)

      assert Map.has_key?(result, 1)
      assert Map.has_key?(result, 2)
      assert length(result[1]) == 2
    end
  end

  describe "sort_collection/3" do
    setup do
      goals = [
        %{name: "Vacation", amount: Decimal.new("5000"), target_date: ~D[2024-06-01]},
        %{name: "Emergency Fund", amount: Decimal.new("10000"), target_date: ~D[2024-01-01]},
        %{name: "Car", amount: Decimal.new("15000"), target_date: ~D[2024-12-01]}
      ]

      {:ok, goals: goals}
    end

    test "sorts by name ascending", %{goals: goals} do
      result = DataHelpers.sort_collection(goals, :name, :asc)
      names = Enum.map(result, & &1.name)
      assert names == ["Car", "Emergency Fund", "Vacation"]
    end

    test "sorts by name descending", %{goals: goals} do
      result = DataHelpers.sort_collection(goals, :name, :desc)
      names = Enum.map(result, & &1.name)
      assert names == ["Vacation", "Emergency Fund", "Car"]
    end

    test "sorts by amount", %{goals: goals} do
      result = DataHelpers.sort_collection(goals, :amount, :asc)
      amounts = Enum.map(result, & &1.amount)
      assert amounts == [Decimal.new("5000"), Decimal.new("10000"), Decimal.new("15000")]
    end

    test "sorts by date", %{goals: goals} do
      result = DataHelpers.sort_collection(goals, :target_date, :asc)
      dates = Enum.map(result, & &1.target_date)
      assert dates == [~D[2024-01-01], ~D[2024-06-01], ~D[2024-12-01]]
    end

    test "defaults to ascending", %{goals: goals} do
      result = DataHelpers.sort_collection(goals, :name)
      names = Enum.map(result, & &1.name)
      assert names == ["Car", "Emergency Fund", "Vacation"]
    end
  end

  describe "filter_by_status/3" do
    setup do
      goals = [
        %{name: "Goal 1", status: :active, is_active: true},
        %{name: "Goal 2", status: :paused},
        %{name: "Goal 3", status: :completed},
        %{name: "Goal 4", is_active: true},
        %{name: "Goal 5", is_active: false}
      ]

      {:ok, goals: goals}
    end

    test "filters active items", %{goals: goals} do
      result = DataHelpers.filter_by_status(goals, "active")
      names = Enum.map(result, & &1.name)
      assert "Goal 1" in names
      assert "Goal 4" in names
      assert length(result) == 2
    end

    test "filters paused items", %{goals: goals} do
      result = DataHelpers.filter_by_status(goals, "paused")
      assert length(result) == 1
      assert hd(result).name == "Goal 2"
    end

    test "filters completed items", %{goals: goals} do
      result = DataHelpers.filter_by_status(goals, "completed")
      assert length(result) == 1
      assert hd(result).name == "Goal 3"
    end

    test "returns all for empty/nil/all status", %{goals: goals} do
      assert DataHelpers.filter_by_status(goals, "") == goals
      assert DataHelpers.filter_by_status(goals, nil) == goals
      assert DataHelpers.filter_by_status(goals, "all") == goals
    end

    test "works with custom status field" do
      items = [%{custom_status: :active}, %{custom_status: :inactive}]
      result = DataHelpers.filter_by_status(items, "active", :custom_status)
      assert length(result) == 1
    end
  end

  describe "filter_by_category_id/3" do
    setup do
      expenses = [
        %{category_id: 1, description: "Groceries"},
        %{category_id: 2, description: "Gas"},
        %{category_id: nil, description: "Uncategorized"},
        %{category_id: 1, description: "More groceries"}
      ]

      {:ok, expenses: expenses}
    end

    test "filters by integer category id", %{expenses: expenses} do
      result = DataHelpers.filter_by_category_id(expenses, 1)
      assert length(result) == 2
      descriptions = Enum.map(result, & &1.description)
      assert "Groceries" in descriptions
      assert "More groceries" in descriptions
    end

    test "filters by string category id", %{expenses: expenses} do
      result = DataHelpers.filter_by_category_id(expenses, "2")
      assert length(result) == 1
      assert hd(result).description == "Gas"
    end

    test "filters uncategorized items", %{expenses: expenses} do
      result = DataHelpers.filter_by_category_id(expenses, "uncategorized")
      assert length(result) == 1
      assert hd(result).description == "Uncategorized"
    end

    test "returns all for empty/nil/all", %{expenses: expenses} do
      assert DataHelpers.filter_by_category_id(expenses, "") == expenses
      assert DataHelpers.filter_by_category_id(expenses, nil) == expenses
      assert DataHelpers.filter_by_category_id(expenses, "all") == expenses
    end

    test "handles invalid string category id", %{expenses: expenses} do
      result = DataHelpers.filter_by_category_id(expenses, "invalid")
      assert result == expenses
    end
  end

  describe "sum_field/2" do
    test "sums decimal fields" do
      items = [
        %{amount: Decimal.new("100.50")},
        %{amount: Decimal.new("200.25")},
        %{amount: Decimal.new("50.00")}
      ]

      result = DataHelpers.sum_field(items, :amount)
      assert Decimal.equal?(result, Decimal.new("350.75"))
    end

    test "sums numeric fields" do
      items = [
        %{quantity: 10},
        %{quantity: 20},
        %{quantity: 5}
      ]

      result = DataHelpers.sum_field(items, :quantity)
      assert result == 35
    end

    test "handles mixed decimal and numeric" do
      items = [
        %{amount: Decimal.new("100")},
        %{amount: 50},
        %{amount: Decimal.new("25")}
      ]

      result = DataHelpers.sum_field(items, :amount)
      assert Decimal.equal?(result, Decimal.new("175"))
    end

    test "handles nil values" do
      items = [
        %{amount: Decimal.new("100")},
        %{amount: nil},
        %{amount: Decimal.new("50")}
      ]

      result = DataHelpers.sum_field(items, :amount)
      assert Decimal.equal?(result, Decimal.new("150"))
    end

    test "returns zero for empty collection" do
      assert DataHelpers.sum_field([], :amount) == 0
    end
  end

  describe "filter_chain/2" do
    setup do
      today = Date.utc_today()

      transactions = [
        %{
          date: Date.add(today, -10),
          category_id: 1,
          status: :active,
          amount: Decimal.new("100")
        },
        %{
          date: Date.add(today, -200),
          category_id: 2,
          status: :active,
          amount: Decimal.new("200")
        },
        %{
          date: Date.add(today, -10),
          category_id: 1,
          status: :paused,
          amount: Decimal.new("300")
        }
      ]

      {:ok, transactions: transactions}
    end

    test "applies multiple filters in sequence", %{transactions: transactions} do
      filters = [
        {:date_range, "last_3_months"},
        {:category_id, 1},
        {:status, "active"}
      ]

      result = DataHelpers.filter_chain(transactions, filters)

      assert length(result) == 1
      assert hd(result).amount == Decimal.new("100")
    end

    test "applies sort at the end", %{transactions: transactions} do
      filters = [
        {:category_id, 1},
        {:sort, :amount, :desc}
      ]

      result = DataHelpers.filter_chain(transactions, filters)

      assert length(result) == 2
      amounts = Enum.map(result, & &1.amount)
      assert amounts == [Decimal.new("300"), Decimal.new("100")]
    end

    test "handles empty filter list", %{transactions: transactions} do
      result = DataHelpers.filter_chain(transactions, [])
      assert result == transactions
    end

    test "ignores unknown filters", %{transactions: transactions} do
      filters = [
        {:unknown_filter, "value"},
        {:category_id, 1}
      ]

      result = DataHelpers.filter_chain(transactions, filters)
      assert length(result) == 2
    end
  end
end
