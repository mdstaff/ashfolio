defmodule AshfolioWeb.ExpenseLive.FormComponentTest do
  use AshfolioWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  describe "expense form component" do
    setup do
      # Reset account balances for clean test state
      require Ash.Query

      Ashfolio.Portfolio.Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(fn account ->
        Ashfolio.Portfolio.Account.update(account, %{balance: Decimal.new("0.00")})
      end)

      {:ok, checking_account} =
        Ashfolio.Portfolio.Account.create(%{
          name: "Test Checking",
          account_type: :checking,
          balance: Decimal.new("5000.00")
        })

      {:ok, category} =
        Ashfolio.FinancialManagement.TransactionCategory.create(%{
          name: "Groceries",
          color: "#4CAF50"
        })

      %{checking_account: checking_account, category: category}
    end

    test "new expense form renders all fields", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/expenses/new")

      # Should show form title
      assert html =~ "Add Expense"

      # Should have all required form fields
      assert has_element?(view, "input[name='description']")
      assert has_element?(view, "input[name='amount']")
      assert has_element?(view, "input[name='date']")
      assert has_element?(view, "input[name='merchant']")
      assert has_element?(view, "select[name='category_id']")
      assert has_element?(view, "select[name='account_id']")
      assert has_element?(view, "textarea[name='notes']")

      # Should have submit button
      assert has_element?(view, "button[type='submit']", "Save Expense")
    end

    test "form validates required fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/expenses/new")

      # Submit form without required fields
      view
      |> form("#expense-form", %{"date" => ""})
      |> render_submit()

      html = render(view)

      # Should show validation errors
      assert html =~ "Description can&#39;t be blank"
      assert html =~ "Amount can&#39;t be blank"
      assert html =~ "Date can&#39;t be blank"
    end

    test "form validates amount is positive", %{conn: conn, checking_account: account} do
      {:ok, view, _html} = live(conn, ~p"/expenses/new")

      view
      |> form("#expense-form", %{
        description: "Test expense",
        amount: "-50.00",
        date: "2024-08-15",
        account_id: account.id
      })
      |> render_submit()

      html = render(view)
      assert html =~ "Amount must be greater than 0"
    end

    test "successful expense creation redirects to index", %{
      conn: conn,
      checking_account: account,
      category: category
    } do
      {:ok, view, _html} = live(conn, ~p"/expenses/new")

      view
      |> form("#expense-form", %{
        description: "Test expense",
        amount: "75.25",
        date: "2024-08-15",
        merchant: "Test Store",
        category_id: category.id,
        account_id: account.id,
        notes: "Test notes"
      })
      |> render_submit()

      # Should redirect to expenses index
      assert_patch(view, ~p"/expenses")

      # Expense should be created in database
      expenses = Ashfolio.FinancialManagement.Expense.list!()
      assert length(expenses) == 1

      expense = List.first(expenses)
      assert expense.description == "Test expense"
      assert Decimal.equal?(expense.amount, Decimal.new("75.25"))
      assert expense.merchant == "Test Store"
    end

    test "category dropdown shows available categories", %{conn: conn, category: category} do
      {:ok, _view, html} = live(conn, ~p"/expenses/new")

      # Should show category in dropdown
      assert html =~ ~r/<option[^>]*value="#{category.id}"[^>]*>Groceries<\/option>/
    end

    test "account dropdown shows available accounts", %{conn: conn, checking_account: account} do
      {:ok, _view, html} = live(conn, ~p"/expenses/new")

      # Should show account in dropdown
      assert html =~ ~r/<option[^>]*value="#{account.id}"[^>]*>Test Checking<\/option>/
    end

    test "date field defaults to today", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/expenses/new")

      today = Date.utc_today() |> Date.to_iso8601()
      assert html =~ ~r/<input[^>]*name="date"[^>]*value="#{today}"[^>]*>/
    end
  end

  describe "edit expense form" do
    setup do
      # Reset account balances
      require Ash.Query

      Ashfolio.Portfolio.Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(fn account ->
        Ashfolio.Portfolio.Account.update(account, %{balance: Decimal.new("0.00")})
      end)

      {:ok, checking_account} =
        Ashfolio.Portfolio.Account.create(%{
          name: "Test Checking",
          account_type: :checking,
          balance: Decimal.new("5000.00")
        })

      {:ok, category} =
        Ashfolio.FinancialManagement.TransactionCategory.create(%{
          name: "Groceries",
          color: "#4CAF50"
        })

      {:ok, expense} =
        Ashfolio.FinancialManagement.Expense.create(%{
          description: "Original expense",
          amount: Decimal.new("100.00"),
          date: ~D[2024-08-10],
          merchant: "Original Store",
          category_id: category.id,
          account_id: checking_account.id
        })

      %{expense: expense, checking_account: checking_account, category: category}
    end

    test "edit form pre-populates with expense data", %{conn: conn, expense: expense} do
      {:ok, _view, html} = live(conn, ~p"/expenses/#{expense.id}/edit")

      # Should show edit form title
      assert html =~ "Edit Expense"

      # Should pre-populate form fields
      assert html =~ ~r/<input[^>]*name="description"[^>]*value="Original expense"[^>]*>/
      assert html =~ ~r/<input[^>]*name="amount"[^>]*value="100"[^>]*>/
      assert html =~ ~r/<input[^>]*name="date"[^>]*value="2024-08-10"[^>]*>/
      assert html =~ ~r/<input[^>]*name="merchant"[^>]*value="Original Store"[^>]*>/
    end

    test "successful edit updates expense", %{
      conn: conn,
      expense: expense,
      category: category,
      checking_account: account
    } do
      {:ok, view, _html} = live(conn, ~p"/expenses/#{expense.id}/edit")

      view
      |> form("#expense-form", %{
        description: "Updated expense",
        amount: "150.75",
        date: "2024-08-12",
        merchant: "Updated Store",
        category_id: category.id,
        account_id: account.id
      })
      |> render_submit()

      # Should redirect back to index
      assert_patch(view, ~p"/expenses")

      # Should update expense in database
      {:ok, updated_expense} = Ashfolio.FinancialManagement.Expense.get_by_id(expense.id)
      assert updated_expense.description == "Updated expense"
      assert Decimal.equal?(updated_expense.amount, Decimal.new("150.75"))
      assert updated_expense.date == ~D[2024-08-12]
    end
  end
end
