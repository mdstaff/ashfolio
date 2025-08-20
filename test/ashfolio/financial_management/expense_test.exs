defmodule Ashfolio.FinancialManagement.ExpenseTest do
  use Ashfolio.DataCase

  alias Ashfolio.FinancialManagement
  alias Ashfolio.FinancialManagement.Expense

  describe "expense creation" do
    setup do
      # Create test category and account
      {:ok, category} =
        FinancialManagement.TransactionCategory.create(%{
          name: "Groceries",
          color: "#3B82F6"
        })

      {:ok, account} =
        Ashfolio.Portfolio.Account.create(%{
          name: "Checking",
          account_type: :checking,
          currency: "USD"
        })

      %{category: category, account: account}
    end

    test "creates expense with valid attributes", %{category: category, account: account} do
      attrs = %{
        description: "Weekly groceries",
        amount: Decimal.new("125.50"),
        date: ~D[2024-01-15],
        merchant: "Whole Foods",
        notes: "Weekly shopping",
        category_id: category.id,
        account_id: account.id
      }

      assert {:ok, expense} = Expense.create(attrs)
      assert expense.description == "Weekly groceries"
      assert Decimal.equal?(expense.amount, Decimal.new("125.50"))
      assert expense.date == ~D[2024-01-15]
      assert expense.merchant == "Whole Foods"
      assert expense.category_id == category.id
      assert expense.account_id == account.id
    end

    test "requires description" do
      attrs = %{
        amount: Decimal.new("50.00"),
        date: ~D[2024-01-15]
      }

      assert {:error, changeset} = Expense.create(attrs)
      assert "is required" in errors_on(changeset).description
    end

    test "requires amount" do
      attrs = %{
        description: "Test expense",
        date: ~D[2024-01-15]
      }

      assert {:error, changeset} = Expense.create(attrs)
      assert "is required" in errors_on(changeset).amount
    end

    test "requires date" do
      attrs = %{
        description: "Test expense",
        amount: Decimal.new("50.00")
      }

      assert {:error, changeset} = Expense.create(attrs)
      assert "is required" in errors_on(changeset).date
    end

    test "validates amount is positive", %{category: category, account: account} do
      attrs = %{
        description: "Invalid expense",
        amount: Decimal.new("-50.00"),
        date: ~D[2024-01-15],
        category_id: category.id,
        account_id: account.id
      }

      assert {:error, changeset} = Expense.create(attrs)
      assert "must be greater than 0" in errors_on(changeset).amount
    end
  end

  describe "expense queries" do
    setup do
      {:ok, category1} =
        FinancialManagement.TransactionCategory.create(%{
          name: "Food",
          color: "#10B981"
        })

      {:ok, category2} =
        FinancialManagement.TransactionCategory.create(%{
          name: "Transport",
          color: "#F59E0B"
        })

      {:ok, account} =
        Ashfolio.Portfolio.Account.create(%{
          name: "Main Checking",
          account_type: :checking,
          currency: "USD"
        })

      # Create test expenses
      {:ok, expense1} =
        Expense.create(%{
          description: "Lunch",
          amount: Decimal.new("15.00"),
          date: ~D[2024-01-15],
          category_id: category1.id,
          account_id: account.id
        })

      {:ok, expense2} =
        Expense.create(%{
          description: "Gas",
          amount: Decimal.new("45.00"),
          date: ~D[2024-01-20],
          category_id: category2.id,
          account_id: account.id
        })

      {:ok, expense3} =
        Expense.create(%{
          description: "Dinner",
          amount: Decimal.new("85.00"),
          date: ~D[2024-02-10],
          category_id: category1.id,
          account_id: account.id
        })

      %{
        category1: category1,
        category2: category2,
        expense1: expense1,
        expense2: expense2,
        expense3: expense3
      }
    end

    test "lists all expenses" do
      expenses = Expense.list!()
      assert length(expenses) == 3
    end

    test "filters expenses by month", %{expense1: expense1, expense2: expense2} do
      expenses = Expense.by_month!(2024, 1)
      assert length(expenses) == 2

      expense_ids = Enum.map(expenses, & &1.id)
      assert expense1.id in expense_ids
      assert expense2.id in expense_ids
    end

    test "filters expenses by category", %{
      category1: category1,
      expense1: expense1,
      expense3: expense3
    } do
      expenses = Expense.by_category!(category1.id)
      assert length(expenses) == 2

      expense_ids = Enum.map(expenses, & &1.id)
      assert expense1.id in expense_ids
      assert expense3.id in expense_ids
    end

    test "filters expenses by date range" do
      expenses = Expense.by_date_range!(~D[2024-01-01], ~D[2024-01-31])
      assert length(expenses) == 2
    end
  end

  describe "expense aggregations" do
    setup do
      {:ok, category} =
        FinancialManagement.TransactionCategory.create(%{
          name: "Shopping",
          color: "#8B5CF6"
        })

      {:ok, account} =
        Ashfolio.Portfolio.Account.create(%{
          name: "Credit Card",
          account_type: :checking,
          currency: "USD"
        })

      # Create expenses for aggregation
      for {amount, date} <- [
            {"100.00", ~D[2024-01-05]},
            {"200.00", ~D[2024-01-15]},
            {"150.00", ~D[2024-01-25]},
            {"300.00", ~D[2024-02-10]}
          ] do
        Expense.create(%{
          description: "Purchase",
          amount: Decimal.new(amount),
          date: date,
          category_id: category.id,
          account_id: account.id
        })
      end

      :ok
    end

    test "calculates monthly totals" do
      totals = Expense.monthly_totals!(2024)

      # Handle nil values for missing months
      jan_total = Map.get(totals, "2024-01", Decimal.new(0))
      feb_total = Map.get(totals, "2024-02", Decimal.new(0))

      assert Decimal.equal?(jan_total, Decimal.new("450.00"))
      assert Decimal.equal?(feb_total, Decimal.new("300.00"))
    end

    test "calculates category totals" do
      totals = Expense.category_totals!(~D[2024-01-01], ~D[2024-02-28])

      assert length(Map.keys(totals)) == 1
      total_sum = Map.values(totals) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
      assert Decimal.equal?(total_sum, Decimal.new("750.00"))
    end
  end

  describe "expense updates" do
    setup do
      {:ok, category} =
        FinancialManagement.TransactionCategory.create(%{
          name: "Entertainment",
          color: "#EC4899"
        })

      {:ok, account} =
        Ashfolio.Portfolio.Account.create(%{
          name: "Debit Card",
          account_type: :checking,
          currency: "USD"
        })

      {:ok, expense} =
        Expense.create(%{
          description: "Movie tickets",
          amount: Decimal.new("30.00"),
          date: ~D[2024-01-15],
          category_id: category.id,
          account_id: account.id
        })

      %{expense: expense}
    end

    test "updates expense attributes", %{expense: expense} do
      {:ok, updated} =
        Expense.update(expense, %{
          description: "Concert tickets",
          amount: Decimal.new("75.00")
        })

      assert updated.description == "Concert tickets"
      assert Decimal.equal?(updated.amount, Decimal.new("75.00"))
    end

    test "validates updates", %{expense: expense} do
      {:error, changeset} =
        Expense.update(expense, %{
          amount: Decimal.new("-10.00")
        })

      assert "must be greater than 0" in errors_on(changeset).amount
    end
  end

  describe "expense deletion" do
    setup do
      {:ok, category} =
        FinancialManagement.TransactionCategory.create(%{
          name: "Utilities",
          color: "#6366F1"
        })

      {:ok, account} =
        Ashfolio.Portfolio.Account.create(%{
          name: "Bills Account",
          account_type: :checking,
          currency: "USD"
        })

      {:ok, expense} =
        Expense.create(%{
          description: "Electric bill",
          amount: Decimal.new("120.00"),
          date: ~D[2024-01-15],
          category_id: category.id,
          account_id: account.id
        })

      %{expense: expense}
    end

    test "deletes expense", %{expense: expense} do
      assert :ok = Expense.destroy(expense)
      assert Expense.list!() == []
    end
  end
end
