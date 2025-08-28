defmodule AshfolioWeb.ExpenseLive.EnhancedAnalyticsTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Ashfolio.FinancialManagement.Expense
  alias Ashfolio.FinancialManagement.TransactionCategory

  setup do
    # Create test data - following existing patterns from other tests
    {:ok, checking_account} =
      Ashfolio.Portfolio.Account.create(%{
        name: "Test Checking",
        account_type: :checking,
        balance: Decimal.new("5000.00")
      })

    {:ok, groceries_category} =
      TransactionCategory.create(%{
        name: "Groceries",
        color: "#4CAF50"
      })

    {:ok, gas_category} =
      TransactionCategory.create(%{
        name: "Gas",
        color: "#FF9800"
      })

    # Create test expenses for different years to test year-over-year
    {:ok, expense_2023} =
      Expense.create(%{
        description: "Groceries 2023",
        amount: Decimal.new("125.50"),
        date: ~D[2023-08-15],
        category_id: groceries_category.id,
        account_id: checking_account.id
      })

    {:ok, expense_2024} =
      Expense.create(%{
        description: "Groceries 2024",
        amount: Decimal.new("135.75"),
        date: ~D[2024-08-15],
        category_id: groceries_category.id,
        account_id: checking_account.id
      })

    %{
      checking_account: checking_account,
      categories: %{groceries: groceries_category, gas: gas_category},
      expenses: %{expense_2023: expense_2023, expense_2024: expense_2024}
    }
  end

  describe "Enhanced Analytics - Year over Year Comparisons" do
    test "renders year-over-year comparison section", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/expenses/analytics")

      # Should show year-over-year section
      assert html =~ "Year-over-Year Analysis"
      assert html =~ "2024 vs 2023"
    end

    test "shows percentage change between years", %{conn: conn, expenses: _expenses} do
      {:ok, _view, html} = live(conn, ~p"/expenses/analytics")

      # Should show year-over-year percentage change
      # 2024: $135.75 vs 2023: $125.50 = +8.2% increase
      assert html =~ "+8.2%"
      assert html =~ "increase from last year"
    end

    test "displays year-over-year comparison chart", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/expenses/analytics")

      # Should render Contex chart for year comparison
      assert html =~ "svg"
      assert html =~ "year-comparison-chart"
    end

    test "allows year selection for comparison", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/expenses/analytics")

      # Should have year selection dropdowns
      assert has_element?(view, "select[name='base_year']")
      assert has_element?(view, "select[name='compare_year']")

      # Should have current and previous years as options
      assert html =~ "2024"
      assert html =~ "2023"
    end

    test "updates comparison when year selection changes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/expenses/analytics")

      # Change comparison years
      view
      |> form("#year-comparison-form")
      |> render_change(%{base_year: "2024", compare_year: "2023"})

      html = render(view)

      # Should update the comparison display
      assert html =~ "2024 vs 2023"
      assert html =~ "+8.2%"
    end
  end

  describe "Enhanced Analytics - Spending Trends" do
    test "renders spending trends section", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/expenses/analytics")

      # Should show spending trends section
      assert html =~ "Spending Trends"
      assert html =~ "Monthly Trend Analysis"
    end

    test "displays trend direction indicators", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/expenses/analytics")

      # Should show trend indicators (up/down arrows, percentages)
      assert html =~ "trend-indicator"
      assert html =~ "Last 3 Months"
      assert html =~ "Last 6 Months"
    end
  end

  describe "Enhanced Analytics - Advanced Filtering" do
    test "renders advanced filter controls", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/expenses/analytics")

      # Should show advanced filtering options
      assert html =~ "Advanced Filters"
      assert has_element?(view, "select[name='category_filter']")
      assert has_element?(view, "select[name='amount_range']")
      assert has_element?(view, "input[name='merchant_filter']")
    end

    test "filters data when advanced filters applied", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/expenses/analytics")

      # Apply category filter
      view
      |> form("#advanced-filters")
      |> render_change(%{category_filter: "groceries"})

      html = render(view)

      # Should show only groceries-related data
      assert html =~ "Groceries"
      refute html =~ "Gas"
    end
  end

  describe "Enhanced Analytics - Custom Date Ranges" do
    test "renders custom date range picker", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/expenses/analytics")

      # Should show custom date range controls
      assert html =~ "Custom Date Range"
      assert has_element?(view, "input[name='start_date'][type='date']")
      assert has_element?(view, "input[name='end_date'][type='date']")
    end

    test "updates analytics when custom date range selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/expenses/analytics")

      # Set custom date range
      view
      |> form("#date-range-form")
      |> render_change(%{start_date: "2023-01-01", end_date: "2023-12-31"})

      html = render(view)

      # Should show data only for 2023
      assert html =~ "2023"
      assert html =~ "Groceries 2023"
    end
  end

  describe "Enhanced Analytics - Mobile Responsiveness" do
    test "renders mobile-responsive charts", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/expenses/analytics")

      # Should have mobile-responsive chart containers
      assert html =~ "chart-container"
      assert html =~ "responsive"
    end
  end
end
