defmodule AshfolioWeb.ExpenseLive.IndexTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Ashfolio.FinancialManagement.Expense
  alias Ashfolio.Portfolio.Account

  describe "expense index" do
    setup do
      # Reset account balances for clean test state
      require Ash.Query

      Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(fn account ->
        Account.update(account, %{balance: Decimal.new("0.00")})
      end)

      # Create test expense data
      {:ok, checking_account} =
        Account.create(%{
          name: "Test Checking",
          account_type: :checking,
          balance: Decimal.new("5000.00")
        })

      {:ok, category} =
        Ashfolio.FinancialManagement.TransactionCategory.create(%{
          name: "Groceries",
          color: "#4CAF50"
        })

      {:ok, expense1} =
        Expense.create(%{
          description: "Weekly groceries",
          amount: Decimal.new("125.50"),
          date: ~D[2024-08-15],
          merchant: "Whole Foods",
          category_id: category.id,
          account_id: checking_account.id
        })

      {:ok, expense2} =
        Expense.create(%{
          description: "Gas station",
          amount: Decimal.new("45.20"),
          date: ~D[2024-08-10],
          merchant: "Shell",
          category_id: category.id,
          account_id: checking_account.id
        })

      %{checking_account: checking_account, category: category, expenses: [expense1, expense2]}
    end

    test "displays expense list with proper formatting", %{conn: conn, expenses: _expenses} do
      {:ok, _view, html} = live(conn, ~p"/expenses")

      # Should show page title
      assert html =~ "Expenses"

      # Should show expense data
      assert html =~ "Weekly groceries"
      assert html =~ "$125.50"
      assert html =~ "Whole Foods"
      assert html =~ "Aug 15, 2024"

      assert html =~ "Gas station"
      assert html =~ "$45.20"
      assert html =~ "Shell"
    end

    test "shows expense summary statistics", %{conn: conn, expenses: _expenses} do
      {:ok, _view, html} = live(conn, ~p"/expenses")

      # Should show total expenses
      # 125.50 + 45.20
      assert html =~ "$170.70"

      # Should show expense count
      assert html =~ "2 expenses"

      # Should show current month total
      assert html =~ "This Month"
    end

    test "expense table has proper sortable columns", %{conn: conn, expenses: expenses} do
      {:ok, _view, html} = live(conn, ~p"/expenses")

      # Debug: Check if we have expenses
      assert length(expenses) == 2, "Expected 2 expenses in test setup"

      # Should show expenses in the HTML
      assert html =~ "Weekly groceries", "Should show first expense"
      assert html =~ "Gas station", "Should show second expense"

      # Should have sortable column headers with data-sort attributes
      assert html =~ "data-sort=\"date\"", "Should have date sort attribute"
      assert html =~ "data-sort=\"amount\"", "Should have amount sort attribute"
      assert html =~ "data-sort=\"description\"", "Should have description sort attribute"
      assert html =~ "data-sort=\"category\"", "Should have category sort attribute"

      # Should have column header text
      assert html =~ "Date"
      assert html =~ "Amount"
      assert html =~ "Description"
      assert html =~ "Category"
      assert html =~ "Actions"
    end

    test "clicking sort headers changes expense order", %{conn: conn, expenses: _expenses} do
      {:ok, view, html} = live(conn, ~p"/expenses")

      # Default sort should be by date desc (newest first)
      # Check that the content is in the expected order
      assert html =~ "Weekly groceries"
      assert html =~ "Gas station"

      # Debug: check if we're showing the empty state
      if html =~ "No expenses" do
        flunk("Expected to show expenses but got empty state. HTML contains: #{String.slice(html, 0, 500)}...")
      end

      # Look for expenses specifically in the table body to verify order
      # Find the table body section
      table_start = html |> :binary.match("<tbody") |> elem(0)
      table_html = String.slice(html, table_start..-1//1)

      # The positions of "Weekly groceries" and "Gas station" in the table should show date order
      groceries_pos = table_html |> :binary.match("Weekly groceries") |> elem(0)
      gas_pos = table_html |> :binary.match("Gas station") |> elem(0)
      # Weekly groceries (Aug 15) should appear before Gas station (Aug 10) in desc order
      assert groceries_pos < gas_pos

      # Click amount header to sort by amount
      view |> element("[data-sort='amount']") |> render_click()

      html = render(view)
      # Should now be sorted by amount asc (Gas station $45.20 before Weekly groceries $125.50)
      table_start = html |> :binary.match("<tbody") |> elem(0)
      table_html = String.slice(html, table_start..-1//1)

      groceries_pos = table_html |> :binary.match("Weekly groceries") |> elem(0)
      gas_pos = table_html |> :binary.match("Gas station") |> elem(0)
      # Gas station ($45.20) should be before Weekly groceries ($125.50) in asc order
      assert gas_pos < groceries_pos
    end

    test "has Add Expense button", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/expenses")

      assert html =~ "Add Expense"

      assert has_element?(
               view,
               "a[data-phx-link='patch'][data-phx-link-state='push'][href='/expenses/new']"
             )
    end

    test "edit links navigate to expense edit page", %{
      conn: conn,
      expenses: [expense1, _expense2]
    } do
      {:ok, view, _html} = live(conn, ~p"/expenses")

      # Should have edit links for each expense
      assert has_element?(view, "a[data-phx-link='patch'][href='/expenses/#{expense1.id}/edit']")

      # Click edit link
      view
      |> element("a[data-phx-link='patch'][href='/expenses/#{expense1.id}/edit']")
      |> render_click()

      # Should navigate to edit page
      assert_patch(view, ~p"/expenses/#{expense1.id}/edit")
    end
  end
end
