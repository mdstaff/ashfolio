defmodule AshfolioWeb.DashboardLive.ExpenseWidgetTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "expense widget" do
    setup do
      # Create test expenses using Ash directly
      {:ok, expense1} = 
        Ashfolio.FinancialManagement.Expense.create(%{
          amount: Decimal.new("100.00"),
          date: Date.utc_today(),
          description: "Test expense 1"
        })
      
      {:ok, expense2} = 
        Ashfolio.FinancialManagement.Expense.create(%{
          amount: Decimal.new("50.00"),
          date: Date.add(Date.utc_today(), -5),
          description: "Test expense 2"
        })
      
      %{expenses: [expense1, expense2]}
    end

    test "displays expense summary stats", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      
      # Should display total expenses
      assert has_element?(view, "[data-testid='expense-widget-total']", "$150.00")
      
      # Should display expense count
      assert has_element?(view, "[data-testid='expense-widget-count']", "2")
      
      # Should display current month total
      assert has_element?(view, "[data-testid='expense-widget-month']", "$150.00")
    end

    test "shows empty state when no expenses", %{conn: conn} do
      # Clear any existing expenses
      Ashfolio.FinancialManagement.Expense
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(&Ashfolio.FinancialManagement.Expense.destroy/1)
      
      {:ok, view, _html} = live(conn, ~p"/")
      
      # Should show zero amounts
      assert has_element?(view, "[data-testid='expense-widget-total']", "$0.00")
      assert has_element?(view, "[data-testid='expense-widget-count']", "0")
      assert has_element?(view, "[data-testid='expense-widget-month']", "$0.00")
    end

    test "links to expense page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      
      # Should have link to expenses page
      assert has_element?(view, "a[href='/expenses']", "View All Expenses")
    end
  end
end