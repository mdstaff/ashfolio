defmodule Ashfolio.Portfolio.TransactionTest do
  use Ashfolio.DataCase, async: false

  @moduletag :ash_resources
  @moduletag :unit
  @moduletag :fast
  @moduletag :smoke

  alias Ashfolio.Portfolio.{Transaction, User, Account, Symbol}
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
end
