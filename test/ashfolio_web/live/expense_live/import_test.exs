defmodule AshfolioWeb.ExpenseLive.ImportTest do
  use AshfolioWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  describe "expense import wizard" do
    setup do
      # Reset account balances for clean test state
      require Ash.Query

      Ashfolio.Portfolio.Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(fn account ->
        Ashfolio.Portfolio.Account.update(account, %{balance: Decimal.new("0.00")})
      end)

      # Create test account and category
      {:ok, checking_account} =
        Ashfolio.Portfolio.Account.create(%{
          name: "Test Checking",
          account_type: :checking,
          balance: Decimal.new("5000.00")
        })

      {:ok, groceries_category} =
        Ashfolio.FinancialManagement.TransactionCategory.create(%{
          name: "Groceries",
          color: "#4CAF50"
        })

      {:ok, gas_category} =
        Ashfolio.FinancialManagement.TransactionCategory.create(%{
          name: "Gas",
          color: "#FF9800"
        })

      %{
        checking_account: checking_account,
        categories: %{groceries: groceries_category, gas: gas_category}
      }
    end

    test "import page renders file upload form", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/expenses/import")

      # Should show import page title
      assert html =~ "Import Expenses"

      # Should have file upload form
      assert has_element?(view, "form[phx-submit='upload']")
      assert has_element?(view, "input[type='file'][accept='.csv']")

      # Should have upload button
      assert has_element?(view, "button[type='submit']", "Upload CSV")
    end

    test "CSV upload shows preview with mapping controls", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/expenses/import")

      # Create test CSV content
      csv_content = """
      Date,Description,Amount,Category
      2024-08-15,Groceries at Whole Foods,125.50,Food
      2024-08-10,Gas Station Fill Up,45.20,Transportation
      2024-08-12,Coffee Shop,8.75,Dining
      """

      # Upload CSV file (simulate file upload)
      view
      |> file_input("#upload-form", :csv_file, [
        %{
          name: "expenses.csv",
          content: csv_content,
          type: "text/csv"
        }
      ])
      |> render_upload("expenses.csv")

      # Submit the form to trigger the upload event
      view
      |> form("#upload-form")
      |> render_submit()

      html = render(view)

      # Should show preview section
      assert html =~ "Preview &amp; Map Columns"
      assert html =~ "3 expenses found"

      # Should show data preview
      assert html =~ "Groceries at Whole Foods"
      assert html =~ "Gas Station Fill Up"
      assert html =~ "Coffee Shop"

      # Should show column mapping controls
      assert has_element?(view, "select[name='column_mapping[date]']")
      assert has_element?(view, "select[name='column_mapping[description]']")
      assert has_element?(view, "select[name='column_mapping[amount]']")
      assert has_element?(view, "select[name='column_mapping[category]']")
    end

    test "category mapping shows existing categories", %{conn: conn, categories: _categories} do
      {:ok, view, _html} = live(conn, ~p"/expenses/import")

      csv_content = """
      Date,Description,Amount,Category
      2024-08-15,Groceries,125.50,Food
      """

      view
      |> file_input("#upload-form", :csv_file, [
        %{name: "expenses.csv", content: csv_content, type: "text/csv"}
      ])
      |> render_upload("expenses.csv")

      # Submit the form to trigger the upload event
      view
      |> form("#upload-form")
      |> render_submit()

      html = render(view)

      # Should show category mapping section
      assert html =~ "Map Categories"

      # Should show existing categories as options
      assert html =~ "Groceries"
      assert html =~ "Gas"

      # Should show unmapped CSV categories
      # From CSV, needs mapping
      assert html =~ "Food"
    end

    test "successful import creates expenses in database", %{
      conn: conn,
      checking_account: account,
      categories: %{groceries: groceries}
    } do
      {:ok, view, _html} = live(conn, ~p"/expenses/import")

      csv_content = """
      Transaction Date,Description,Amount,Category
      08/15/2024,Weekly Groceries,-125.50,Food
      08/10/2024,Gas Fill Up,-45.20,Transportation
      """

      # Upload and preview
      view
      |> file_input("#upload-form", :csv_file, [
        %{name: "expenses.csv", content: csv_content, type: "text/csv"}
      ])
      |> render_upload("expenses.csv")

      # Submit the form to trigger the upload event
      view
      |> form("#upload-form")
      |> render_submit()

      # Map categories and set account
      view
      |> form("#import-form", %{
        account_id: account.id,
        category_mapping: %{
          "Food" => groceries.id,
          # Map to existing category for test
          "Transportation" => groceries.id
        }
      })
      |> render_change()

      # Submit import via form submit with proper data
      _html =
        view
        |> form("#import-form", %{
          account_id: account.id,
          category_mapping: %{
            "Food" => groceries.id,
            "Transportation" => groceries.id
          }
        })
        |> render_submit()

      # Check if expenses were created in database
      expenses = Ashfolio.FinancialManagement.Expense |> Ash.Query.for_read(:read) |> Ash.read!()

      assert length(expenses) == 2

      expense1 = Enum.find(expenses, &(&1.description == "Weekly Groceries"))
      assert Decimal.equal?(expense1.amount, Decimal.new("125.50"))
      assert expense1.date == ~D[2024-08-15]
      assert expense1.account_id == account.id
      assert expense1.category_id == groceries.id
    end

    @tag :skip
    test "import validation shows errors for invalid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/expenses/import")

      # CSV with invalid data
      csv_content = """
      Date,Description,Amount,Category
      invalid-date,Missing Amount,,Food
      2024-08-15,,0,Food
      2024-08-10,Valid Entry,25.50,Food
      """

      view
      |> file_input("#upload-form", :csv_file, [
        %{name: "expenses.csv", content: csv_content, type: "text/csv"}
      ])
      |> render_upload("expenses.csv")

      # Submit the form to trigger the upload event
      view
      |> form("#upload-form")
      |> render_submit()

      html = render(view)

      # Should show validation errors
      assert html =~ "Validation Errors"
      assert html =~ "Invalid date format"
      assert html =~ "Description is required"
      assert html =~ "Amount must be greater than 0"

      # Should show valid entries count
      assert html =~ "1 valid expense"
      assert html =~ "2 errors"
    end

    @tag :skip
    test "import handles duplicate detection", %{
      conn: conn,
      checking_account: account,
      categories: %{groceries: groceries}
    } do
      # Create existing expense
      {:ok, _existing_expense} =
        Ashfolio.FinancialManagement.Expense.create(%{
          description: "Weekly Groceries",
          amount: Decimal.new("125.50"),
          date: ~D[2024-08-15],
          account_id: account.id,
          category_id: groceries.id
        })

      {:ok, view, _html} = live(conn, ~p"/expenses/import")

      # CSV with duplicate data
      csv_content = """
      Date,Description,Amount,Category
      2024-08-15,Weekly Groceries,125.50,Food
      2024-08-10,New Expense,45.20,Food
      """

      view
      |> file_input("#upload-form", :csv_file, [
        %{name: "expenses.csv", content: csv_content, type: "text/csv"}
      ])
      |> render_upload("expenses.csv")

      # Submit the form to trigger the upload event
      view
      |> form("#upload-form")
      |> render_submit()

      html = render(view)

      # Should show duplicate detection
      assert html =~ "Potential Duplicates"
      assert html =~ "1 potential duplicate found"
      assert html =~ "Weekly Groceries"

      # Should have option to skip duplicates
      assert has_element?(view, "input[type='checkbox'][name='skip_duplicates']")
    end
  end
end
