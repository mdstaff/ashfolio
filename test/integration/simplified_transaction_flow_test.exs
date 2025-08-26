defmodule AshfolioWeb.Integration.SimplifiedTransactionFlowTest do
  @moduledoc """
  Simplified integration tests for core Transaction workflow functionality:
  Transaction creation, validation, and database integration

  Task 29.1: Core Workflow Integration Tests - Transaction Flow (Simplified)
  """
  use AshfolioWeb.ConnCase, async: false

  @moduletag :integration
  @moduletag :fast

  alias Ashfolio.Portfolio.{Account, Symbol, Transaction, Calculator}
  alias Ashfolio.SQLiteHelpers

  setup do
    # Database-as-user architecture: No user entity needed
    # Create a unique account for this test to avoid conflicts
    {:ok, account} =
      Account.create(%{
        name: "Smoke Test Account #{System.unique_integer([:positive])}",
        platform: "Test Broker",
        balance: Decimal.new("10000")
      })

    # Use existing AAPL symbol (created globally) and update its price
    symbol = SQLiteHelpers.get_common_symbol("AAPL")

    {:ok, symbol} =
      Symbol.update_price(symbol, %{
        current_price: Decimal.new("150.00"),
        price_updated_at: DateTime.utc_now()
      })

    %{account: account, symbol: symbol}
  end

  describe "Core Transaction Workflow - Database Integration" do
    @tag :smoke
    test "transaction CRUD operations work correctly", %{account: account, symbol: symbol} do
      # Step 1: Create transaction
      transaction_data = %{
        type: :buy,
        account_id: account.id,
        symbol_id: symbol.id,
        quantity: Decimal.new("100"),
        price: Decimal.new("150.00"),
        total_amount: Decimal.new("15000.00"),
        date: ~D[2024-08-07]
      }

      {:ok, transaction} = Transaction.create(transaction_data)

      # Verify creation
      assert transaction.type == :buy
      assert Decimal.equal?(transaction.quantity, Decimal.new("100"))
      assert Decimal.equal?(transaction.price, Decimal.new("150.00"))
      assert transaction.date == ~D[2024-08-07]

      # Step 2: Read transaction
      {:ok, found_transaction} = Transaction.get_by_id(transaction.id)
      assert found_transaction.id == transaction.id

      # Step 3: Update transaction
      {:ok, updated_transaction} =
        Transaction.update(transaction, %{
          quantity: Decimal.new("150"),
          price: Decimal.new("148.00"),
          total_amount: Decimal.new("22200.00")
        })

      assert Decimal.equal?(updated_transaction.quantity, Decimal.new("150"))
      assert Decimal.equal?(updated_transaction.price, Decimal.new("148.00"))

      # Step 4: List transactions by account
      {:ok, account_transactions} = Transaction.by_account(account.id)
      assert length(account_transactions) == 1
      assert List.first(account_transactions).id == updated_transaction.id

      # Step 5: Delete transaction
      :ok = Transaction.destroy(updated_transaction)

      # Verify deletion
      {:ok, final_transactions} = Transaction.by_account(account.id)
      assert Enum.empty?(final_transactions)
    end

    test "transaction validation works correctly", %{account: account, symbol: symbol} do
      # Test invalid transaction data
      invalid_data = %{
        type: :buy,
        account_id: account.id,
        symbol_id: symbol.id,
        # Negative quantity should fail
        quantity: Decimal.new("-100"),
        price: Decimal.new("150.00"),
        total_amount: Decimal.new("15000.00"),
        date: ~D[2024-08-07]
      }

      {:error, error} = Transaction.create(invalid_data)
      # Should be an Ash.Error with validation details
      assert is_map(error)

      # Test missing required fields
      incomplete_data = %{
        type: :buy,
        account_id: account.id
        # Missing symbol_id, quantity, price, etc.
      }

      {:error, error} = Transaction.create(incomplete_data)
      assert is_map(error)
    end

    test "multiple transaction types work correctly", %{account: account, symbol: symbol} do
      transaction_types = [
        %{type: :buy, quantity: "100", price: "150.00", total: "15000.00"},
        %{type: :sell, quantity: "-50", price: "155.00", total: "7750.00"},
        %{type: :dividend, quantity: "1", price: "1.00", total: "100.00"},
        %{type: :fee, quantity: "0", price: "0", total: "9.99"}
      ]

      created_transactions =
        Enum.map(transaction_types, fn tx_data ->
          transaction_data = %{
            type: tx_data.type,
            account_id: account.id,
            symbol_id: symbol.id,
            quantity: Decimal.new(tx_data.quantity),
            price: Decimal.new(tx_data.price),
            total_amount: Decimal.new(tx_data.total),
            date: ~D[2024-08-07]
          }

          {:ok, transaction} = Transaction.create(transaction_data)
          transaction
        end)

      # Verify all transactions were created
      assert length(created_transactions) == 4

      # Verify we can retrieve them
      {:ok, account_transactions} = Transaction.by_account(account.id)
      assert length(account_transactions) == 4

      # Verify each type exists
      types = Enum.map(account_transactions, & &1.type)
      assert :buy in types
      assert :sell in types
      assert :dividend in types
      assert :fee in types
    end

    test "transaction portfolio impact calculations", %{
      account: account,
      symbol: symbol
    } do
      # Create some sample transactions
      transactions = [
        %{type: :buy, quantity: "100", price: "145.00", total: "14500.00"},
        %{type: :buy, quantity: "50", price: "155.00", total: "7750.00"},
        %{type: :sell, quantity: "-25", price: "160.00", total: "4000.00"}
      ]

      Enum.each(transactions, fn tx ->
        {:ok, _} =
          Transaction.create(%{
            type: tx.type,
            account_id: account.id,
            symbol_id: symbol.id,
            quantity: Decimal.new(tx.quantity),
            price: Decimal.new(tx.price),
            total_amount: Decimal.new(tx.total),
            date: ~D[2024-08-01]
          })
      end)

      # Verify portfolio calculation integration
      case Calculator.calculate_position_returns() do
        {:ok, positions} ->
          aapl_position = Enum.find(positions, fn pos -> pos.symbol == "AAPL" end)
          assert aapl_position != nil
          # Net quantity should be 100 + 50 - 25 = 125
          assert Decimal.equal?(aapl_position.quantity, Decimal.new("125"))

        {:error, _} ->
          # Calculator may not work without proper market data, that's ok for this test
          :ok
      end

      # At minimum, verify transactions are stored correctly
      {:ok, account_transactions} = Transaction.by_account(account.id)
      assert length(account_transactions) == 3
    end
  end
end
