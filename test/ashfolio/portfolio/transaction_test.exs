defmodule Ashfolio.Portfolio.TransactionTest do
  use Ashfolio.DataCase, async: false

  @moduletag :ash_resources
  @moduletag :unit
  @moduletag :fast
  @moduletag :smoke

  alias Ashfolio.Portfolio.{Transaction, User, Account, Symbol}
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.SQLiteHelpers

  describe "Transaction resource" do
    setup do
      # Use hybrid approach: get global defaults or create custom resources with retry logic
      user = SQLiteHelpers.get_default_user()
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Brokerage", platform: "Test Platform"})
      symbol = SQLiteHelpers.get_common_symbol("AAPL")

      %{user: user, account: account, symbol: symbol}
    end

    test "creates a buy transaction successfully", %{account: account, symbol: symbol} do
      transaction_params = %{
        type: :buy,
        quantity: Decimal.new("100"),
        price: Decimal.new("150.50"),
        total_amount: Decimal.new("15050.00"),
        fee: Decimal.new("9.95"),
        date: Date.utc_today(),
        notes: "Initial purchase",
        account_id: account.id,
        symbol_id: symbol.id
      }

      {:ok, transaction} = Transaction.create(transaction_params)

      assert transaction.type == :buy
      assert Decimal.equal?(transaction.quantity, Decimal.new("100"))
      assert Decimal.equal?(transaction.price, Decimal.new("150.50"))
      assert Decimal.equal?(transaction.total_amount, Decimal.new("15050.00"))
      assert Decimal.equal?(transaction.fee, Decimal.new("9.95"))
      assert transaction.date == Date.utc_today()
      assert transaction.notes == "Initial purchase"
      assert transaction.account_id == account.id
      assert transaction.symbol_id == symbol.id
    end

    test "creates a sell transaction successfully", %{account: account, symbol: symbol} do
      transaction_params = %{
        type: :sell,
        quantity: Decimal.new("-50"),
        price: Decimal.new("160.00"),
        total_amount: Decimal.new("7990.05"),
        fee: Decimal.new("9.95"),
        date: Date.utc_today(),
        account_id: account.id,
        symbol_id: symbol.id
      }

      {:ok, transaction} = Transaction.create(transaction_params)

      assert transaction.type == :sell
      assert Decimal.equal?(transaction.quantity, Decimal.new("-50"))
      assert Decimal.equal?(transaction.price, Decimal.new("160.00"))
    end

    test "creates a dividend transaction successfully", %{account: account, symbol: symbol} do
      transaction_params = %{
        type: :dividend,
        quantity: Decimal.new("100"),
        price: Decimal.new("0.25"),
        total_amount: Decimal.new("25.00"),
        fee: Decimal.new("0"),
        date: Date.utc_today(),
        account_id: account.id,
        symbol_id: symbol.id
      }

      {:ok, transaction} = Transaction.create(transaction_params)

      assert transaction.type == :dividend
      assert Decimal.equal?(transaction.quantity, Decimal.new("100"))
      assert Decimal.equal?(transaction.price, Decimal.new("0.25"))
    end

    test "creates a fee transaction successfully", %{account: account, symbol: symbol} do
      transaction_params = %{
        type: :fee,
        quantity: Decimal.new("0"),
        price: Decimal.new("0"),
        total_amount: Decimal.new("15.00"),
        fee: Decimal.new("15.00"),
        date: Date.utc_today(),
        account_id: account.id,
        symbol_id: symbol.id
      }

      {:ok, transaction} = Transaction.create(transaction_params)

      assert transaction.type == :fee
      assert Decimal.equal?(transaction.quantity, Decimal.new("0"))
      assert Decimal.equal?(transaction.fee, Decimal.new("15.00"))
    end

    test "validates required fields" do
      {:error, changeset} = Transaction.create(%{})

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :type
             end)

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :quantity
             end)

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :price
             end)

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :total_amount
             end)

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :date
             end)
    end

    test "validates positive price" do
      {:error, changeset} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("-10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today()
        })

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :price and String.contains?(error.message, "negative")
             end)
    end

    test "validates non-negative fee" do
      {:error, changeset} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          fee: Decimal.new("-5"),
          date: Date.utc_today()
        })

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :fee and String.contains?(error.message, "negative")
             end)
    end

    test "validates buy transaction quantity is positive" do
      {:error, changeset} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("-100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today()
        })

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :quantity and String.contains?(error.message, "positive for buy")
             end)
    end

    test "validates sell transaction quantity is negative" do
      {:error, changeset} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today()
        })

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :quantity and String.contains?(error.message, "negative for sell")
             end)
    end

    test "validates future date" do
      future_date = Date.utc_today() |> Date.add(1)

      {:error, changeset} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: future_date
        })

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :date and String.contains?(error.message, "future")
             end)
    end

    test "queries transactions by account", %{account: account, symbol: symbol} do
      # Create transactions
      {:ok, _transaction1} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, transactions} = Transaction.by_account(account.id)
      assert length(transactions) == 1
    end

    test "queries transactions by symbol", %{account: account, symbol: symbol} do
      # Create transactions
      {:ok, _transaction1} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, transactions} = Transaction.by_symbol(symbol.id)
      assert length(transactions) == 1
    end

    test "queries transactions by type", %{account: account, symbol: symbol} do
      # Create buy transaction
      {:ok, _transaction1} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Create sell transaction
      {:ok, _transaction2} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("-50"),
          price: Decimal.new("12"),
          total_amount: Decimal.new("600"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, buy_transactions} = Transaction.by_type(:buy)
      {:ok, sell_transactions} = Transaction.by_type(:sell)

      assert length(buy_transactions) == 1
      assert length(sell_transactions) == 1
    end

    test "queries transactions by date range", %{account: account, symbol: symbol} do
      today = Date.utc_today()
      yesterday = Date.add(today, -1)
      tomorrow = Date.add(today, 1)

      # Create transaction for today
      {:ok, _transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: today,
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Query for yesterday to tomorrow (should include today's transaction)
      {:ok, transactions} = Transaction.by_date_range(yesterday, tomorrow)
      assert length(transactions) == 1

      # Query for future dates (should be empty)
      future_start = Date.add(today, 2)
      future_end = Date.add(today, 3)
      {:ok, future_transactions} = Transaction.by_date_range(future_start, future_end)
      assert length(future_transactions) == 0
    end

    test "queries recent transactions", %{account: account, symbol: symbol} do
      # Create transaction for today (should be included)
      {:ok, _transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, recent_transactions} = Transaction.recent_transactions()
      assert length(recent_transactions) == 1
    end

    test "queries holdings data", %{account: account, symbol: symbol} do
      # Create buy transaction
      {:ok, _transaction1} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Create sell transaction
      {:ok, _transaction2} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("-25"),
          price: Decimal.new("12"),
          total_amount: Decimal.new("300"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, holdings} = Transaction.holdings_data()
      # Both buy and sell transactions
      assert length(holdings) == 2
    end

    test "updates transaction successfully", %{account: account, symbol: symbol} do
      {:ok, transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, updated_transaction} =
        Transaction.update(transaction, %{
          notes: "Updated notes"
        })

      assert updated_transaction.notes == "Updated notes"
    end

    test "destroys transaction successfully", %{account: account, symbol: symbol} do
      {:ok, transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      :ok = Transaction.destroy(transaction)

      # Verify transaction is deleted
      {:ok, transactions} = Transaction.list()
      assert length(transactions) == 0
    end
  end

  describe "Transaction category relationships" do
    setup do
      user = SQLiteHelpers.get_default_user()
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Brokerage", platform: "Test Platform"})
      symbol = SQLiteHelpers.get_common_symbol("AAPL")

      # Create a test category
      {:ok, category} = TransactionCategory.create(%{
        name: "Growth",
        color: "#10B981",
        user_id: user.id
      })

      %{user: user, account: account, symbol: symbol, category: category}
    end

    test "creates transaction with category successfully", %{account: account, symbol: symbol, category: category} do
      transaction_params = %{
        type: :buy,
        quantity: Decimal.new("100"),
        price: Decimal.new("150.50"),
        total_amount: Decimal.new("15050.00"),
        fee: Decimal.new("9.95"),
        date: Date.utc_today(),
        notes: "Growth investment",
        account_id: account.id,
        symbol_id: symbol.id,
        category_id: category.id
      }

      {:ok, transaction} = Transaction.create(transaction_params)

      assert transaction.category_id == category.id
      assert transaction.type == :buy
      assert transaction.notes == "Growth investment"
    end

    test "creates transaction without category successfully", %{account: account, symbol: symbol} do
      transaction_params = %{
        type: :buy,
        quantity: Decimal.new("100"),
        price: Decimal.new("150.50"),
        total_amount: Decimal.new("15050.00"),
        fee: Decimal.new("9.95"),
        date: Date.utc_today(),
        account_id: account.id,
        symbol_id: symbol.id
      }

      {:ok, transaction} = Transaction.create(transaction_params)

      assert is_nil(transaction.category_id)
      assert transaction.type == :buy
    end

    test "updates transaction category successfully", %{account: account, symbol: symbol, category: category} do
      # Create transaction without category
      {:ok, transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      assert is_nil(transaction.category_id)

      # Update to add category
      {:ok, updated_transaction} =
        Transaction.update(transaction, %{
          category_id: category.id
        })

      assert updated_transaction.category_id == category.id
    end

    test "removes category from transaction successfully", %{account: account, symbol: symbol, category: category} do
      # Create transaction with category
      {:ok, transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: category.id
        })

      assert transaction.category_id == category.id

      # Update to remove category
      {:ok, updated_transaction} =
        Transaction.update(transaction, %{
          category_id: nil
        })

      assert is_nil(updated_transaction.category_id)
    end

    test "queries transactions by category", %{account: account, symbol: symbol, category: category, user: user} do
      # Create another category
      {:ok, income_category} = TransactionCategory.create(%{
        name: "Income",
        color: "#3B82F6",
        user_id: user.id
      })

      # Create transactions with different categories
      {:ok, _growth_transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: category.id
        })

      {:ok, _income_transaction} =
        Transaction.create(%{
          type: :dividend,
          quantity: Decimal.new("100"),
          price: Decimal.new("0.25"),
          total_amount: Decimal.new("25"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: income_category.id
        })

      # Query by growth category
      {:ok, growth_transactions} = Transaction.by_category(category.id)
      assert length(growth_transactions) == 1
      assert hd(growth_transactions).type == :buy

      # Query by income category
      {:ok, income_transactions} = Transaction.by_category(income_category.id)
      assert length(income_transactions) == 1
      assert hd(income_transactions).type == :dividend
    end

    test "queries uncategorized transactions", %{account: account, symbol: symbol, category: category} do
      # Create transaction with category
      {:ok, _categorized_transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: category.id
        })

      # Create transaction without category
      {:ok, _uncategorized_transaction} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("-50"),
          price: Decimal.new("12"),
          total_amount: Decimal.new("600"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Query uncategorized transactions
      {:ok, uncategorized_transactions} = Transaction.uncategorized_transactions()
      assert length(uncategorized_transactions) == 1
      assert hd(uncategorized_transactions).type == :sell
      assert is_nil(hd(uncategorized_transactions).category_id)
    end

    test "validates category belongs to valid category resource", %{account: account, symbol: symbol} do
      # Try to create transaction with invalid category_id
      invalid_uuid = Ecto.UUID.generate()

      {:error, changeset} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: invalid_uuid
        })

      # Should fail due to foreign key constraint
      assert changeset.errors != []
    end

    test "loads category relationship", %{account: account, symbol: symbol, category: category} do
      require Ash.Query

      # Create transaction with category
      {:ok, transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("10"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: category.id
        })

      # Load transaction with category relationship
      {:ok, loaded_transaction} =
        Transaction
        |> Ash.Query.filter(id == ^transaction.id)
        |> Ash.Query.load(:category)
        |> Ash.read_first()

      assert loaded_transaction.category.id == category.id
      assert loaded_transaction.category.name == "Growth"
      assert loaded_transaction.category.color == "#10B981"
    end

    test "handles all transaction types with categories", %{account: account, symbol: symbol, category: category} do
      transaction_types = [
        {:buy, Decimal.new("100")},
        {:sell, Decimal.new("-50")},
        {:dividend, Decimal.new("100")},
        {:fee, Decimal.new("0")},
        {:interest, Decimal.new("100")},
        {:liability, Decimal.new("-25")}
      ]

      # Create transactions of each type with category
      created_transactions =
        Enum.map(transaction_types, fn {type, quantity} ->
          {:ok, transaction} =
            Transaction.create(%{
              type: type,
              quantity: quantity,
              price: Decimal.new("10"),
              total_amount: Decimal.new("1000"),
              date: Date.utc_today(),
              account_id: account.id,
              symbol_id: symbol.id,
              category_id: category.id
            })
          transaction
        end)

      # Verify all transactions have the category
      Enum.each(created_transactions, fn transaction ->
        assert transaction.category_id == category.id
      end)

      # Query by category should return all transactions
      {:ok, category_transactions} = Transaction.by_category(category.id)
      assert length(category_transactions) == 6
    end
  end
end
