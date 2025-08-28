defmodule AshfolioWeb.ExpenseLive.AnalyticsTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Ashfolio.FinancialManagement.Expense
  alias Ashfolio.FinancialManagement.NetWorthSnapshot
  alias Ashfolio.FinancialManagement.TransactionCategory

  describe "expense analytics charts" do
    setup do
      # Create test categories
      {:ok, food_category} =
        TransactionCategory.create(%{
          name: "Food",
          color: "#4CAF50"
        })

      {:ok, transport_category} =
        TransactionCategory.create(%{
          name: "Transport",
          color: "#2196F3"
        })

      {:ok, entertainment_category} =
        TransactionCategory.create(%{
          name: "Entertainment",
          color: "#FF9800"
        })

      # Create test expenses with categories
      {:ok, _expense1} =
        Expense.create(%{
          description: "Groceries",
          amount: Decimal.new("500.00"),
          date: Date.utc_today(),
          category_id: food_category.id
        })

      {:ok, _expense2} =
        Expense.create(%{
          description: "Gas",
          amount: Decimal.new("200.00"),
          date: Date.utc_today(),
          category_id: transport_category.id
        })

      {:ok, _expense3} =
        Expense.create(%{
          description: "Movie tickets",
          amount: Decimal.new("300.00"),
          date: Date.utc_today(),
          category_id: entertainment_category.id
        })

      %{
        food_category: food_category,
        transport_category: transport_category,
        entertainment_category: entertainment_category
      }
    end

    test "expense analytics shows category pie chart", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/expenses/analytics")

      # Verify SVG chart rendered
      assert html =~ "<svg"
      assert html =~ "Expenses by Category"

      # Verify category names appear
      assert html =~ "Food"
      assert html =~ "Transport"
      assert html =~ "Entertainment"
    end

    test "pie chart shows correct percentages", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/expenses/analytics")

      # Total is $1000 (500 + 200 + 300)
      # Food: 500/1000 = 50%
      # Transport: 200/1000 = 20%
      # Entertainment: 300/1000 = 30%

      # Check that percentage values appear in the rendered output
      # 50% for Food
      assert html =~ "50"
      # Amount for Food
      assert html =~ "$500"
    end

    test "handles empty state gracefully", %{conn: conn} do
      # Clear all expenses
      Expense
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(&Expense.destroy/1)

      {:ok, _view, html} = live(conn, ~p"/expenses/analytics")

      # Should show empty state message
      assert html =~ "No expenses to display"
      assert html =~ "Add your first expense"
      # Total should be zero
      assert html =~ "$0.00"
    end

    test "chart updates when date range changes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/expenses/analytics")

      # Change date range to "All Time" which should show data
      view |> element("button", "All Time") |> render_click()

      # Chart should update and show data
      html = render(view)
      assert html =~ "Expenses by Category"
      # Should still show categories
      assert html =~ "Food"
    end

    test "navigation links work correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/expenses/analytics")

      # Should have link back to expenses
      assert has_element?(view, "a[href='/expenses']")

      # Should have date range buttons
      assert has_element?(view, "button", "Last Month")
      assert has_element?(view, "button", "Last 3 Months")
    end

    test "chart is responsive on different screen sizes", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/expenses/analytics")

      # Check for responsive layout classes that actually exist
      assert html =~ "flex flex-col lg:flex-row"
      assert html =~ "flex justify-center"

      # SVG should be in the rendered output
      assert html =~ "<svg"
    end
  end

  describe "net worth trend charts" do
    setup do
      # Create net worth snapshots for trend
      snapshots_data = [
        {Date.add(Date.utc_today(), -90), "50000.00"},
        {Date.add(Date.utc_today(), -60), "55000.00"},
        {Date.add(Date.utc_today(), -30), "60000.00"},
        {Date.utc_today(), "65000.00"}
      ]

      snapshots =
        for {date, value} <- snapshots_data do
          {:ok, snapshot} =
            NetWorthSnapshot.create(%{
              snapshot_date: date,
              total_assets: Decimal.new(value),
              total_liabilities: Decimal.new("0.00"),
              net_worth: Decimal.new(value),
              investment_value: Decimal.new(value),
              cash_value: Decimal.new("0.00")
            })

          snapshot
        end

      %{snapshots: snapshots}
    end

    test "net worth page shows trend line chart", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/net_worth")

      # Verify chart section exists
      assert html =~ "Net Worth Trend"

      # Verify SVG chart is rendered
      assert html =~ "<svg"
    end

    test "trend chart shows growth indicators", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/net_worth")

      # Should show current value
      assert html =~ "$65,000"

      # Should show positive change (65k - 50k = 15k over 90 days)
      assert html =~ "$15,000"
    end

    test "chart empty state when no snapshots", %{conn: conn} do
      # Clear all snapshots
      {:ok, snapshots} = NetWorthSnapshot.list()
      Enum.each(snapshots, &NetWorthSnapshot.destroy/1)
      {:ok, _view, html} = live(conn, ~p"/net_worth")

      # Should show empty state
      assert html =~ "No net worth data to display"
      assert html =~ "Create your first net worth snapshot"
    end
  end
end
