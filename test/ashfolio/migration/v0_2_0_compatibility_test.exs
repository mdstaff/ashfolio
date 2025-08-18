defmodule Ashfolio.Migration.V020CompatibilityTest do
  @moduledoc """
  Comprehensive feature compatibility and data integrity tests for v0.2.0.

  Tests the database-as-user architecture with enhanced features including:
  - Account types (investment, checking, savings)
  - Transaction categories (optional)
  - Context API functionality
  - Data integrity and performance
  - Feature compatibility across components

  Note: In v0.2.0, we use database-as-user architecture where each SQLite 
  database represents one complete user portfolio.
  """

  use Ashfolio.DataCase, async: false

  @moduletag :migration
  @moduletag :compatibility
  @moduletag :v0_2_0

  alias Ashfolio.Portfolio.{Account, Transaction, Symbol}
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Context
  alias Ashfolio.SQLiteHelpers

  describe "account type compatibility" do
    test "default investment accounts work correctly" do
      # Create basic investment account (default type)
      {:ok, account} =
        Account.create(%{
          name: "Investment Account",
          platform: "Brokerage",
          balance: Decimal.new("50000"),
          currency: "USD"
        })

      # Default should be investment type
      assert account.account_type == :investment
      assert is_nil(account.interest_rate)
      assert is_nil(account.minimum_balance)

      # Context API should categorize correctly
      {:ok, dashboard_data} = Context.get_user_dashboard_data()

      investment_accounts =
        Enum.filter(dashboard_data.accounts, &(&1.account_type == :investment))

      assert length(investment_accounts) >= 1
    end

    test "cash account types support additional attributes" do
      # Create savings account with interest rate
      {:ok, savings} =
        Account.create(%{
          name: "Savings Account",
          platform: "Bank",
          balance: Decimal.new("5000"),
          account_type: :savings,
          interest_rate: Decimal.new("2.5"),
          minimum_balance: Decimal.new("1000")
        })

      assert savings.account_type == :savings
      assert Decimal.equal?(savings.interest_rate, Decimal.new("2.5"))
      assert Decimal.equal?(savings.minimum_balance, Decimal.new("1000"))

      # Create checking account without interest rate
      {:ok, checking} =
        Account.create(%{
          name: "Checking Account",
          platform: "Credit Union",
          balance: Decimal.new("2000"),
          account_type: :checking
        })

      assert checking.account_type == :checking
      assert is_nil(checking.interest_rate)
      assert is_nil(checking.minimum_balance)
    end

    test "account type upgrades work correctly" do
      # Create basic account
      {:ok, account} =
        Account.create(%{
          name: "Flexible Account",
          platform: "Multi-Platform",
          balance: Decimal.new("10000")
        })

      # Should default to investment
      assert account.account_type == :investment

      # Upgrade to savings with additional attributes
      {:ok, upgraded} =
        Account.update(account.id, %{
          account_type: :savings,
          interest_rate: Decimal.new("1.8"),
          minimum_balance: Decimal.new("500")
        })

      assert upgraded.account_type == :savings
      assert Decimal.equal?(upgraded.interest_rate, Decimal.new("1.8"))
      assert Decimal.equal?(upgraded.minimum_balance, Decimal.new("500"))
    end
  end

  describe "transaction category compatibility" do
    test "transactions work without categories (optional feature)" do
      account = SQLiteHelpers.get_default_account()

      symbol =
        SQLiteHelpers.get_or_create_symbol("COMPAT", %{
          name: "Compatibility Test Stock",
          current_price: Decimal.new("100")
        })

      # Create transaction without category
      {:ok, transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("50"),
          total_amount: Decimal.new("5000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Should work without category
      assert is_nil(transaction.category_id)

      # Context API should handle uncategorized transactions
      {:ok, recent_txs} = Context.get_recent_transactions(10)
      uncategorized = Enum.filter(recent_txs, &is_nil(&1.category_id))
      assert length(uncategorized) >= 1
    end

    test "transactions can be assigned categories" do
      account = SQLiteHelpers.get_default_account()

      symbol =
        SQLiteHelpers.get_or_create_symbol("CATTEST", %{
          name: "Category Test Stock",
          current_price: Decimal.new("150")
        })

      # Create category
      {:ok, category} =
        TransactionCategory.create(%{
          name: "Growth",
          color: "#10B981",
          is_system: true
        })

      # Create categorized transaction
      {:ok, transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("50"),
          price: Decimal.new("150"),
          total_amount: Decimal.new("7500"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: category.id
        })

      assert transaction.category_id == category.id

      # Load with category relationship
      loaded = Ash.load!(transaction, [:category])
      assert loaded.category.name == "Growth"
    end

    test "mixed categorized and uncategorized transactions work together" do
      account = SQLiteHelpers.get_default_account()

      symbol =
        SQLiteHelpers.get_or_create_symbol("MIXED", %{
          name: "Mixed Test Stock",
          current_price: Decimal.new("200")
        })

      # Create category
      {:ok, category} =
        TransactionCategory.create(%{
          name: "Income",
          color: "#3B82F6",
          is_system: true
        })

      # Create uncategorized transaction
      {:ok, _tx1} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("25"),
          price: Decimal.new("200"),
          total_amount: Decimal.new("5000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Create categorized transaction
      {:ok, _tx2} =
        Transaction.create(%{
          type: :dividend,
          quantity: Decimal.new("25"),
          price: Decimal.new("2"),
          total_amount: Decimal.new("50"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: category.id
        })

      # Both should work through Context API
      {:ok, recent_txs} = Context.get_recent_transactions(10)
      categorized = Enum.filter(recent_txs, & &1.category_id)
      uncategorized = Enum.filter(recent_txs, &is_nil(&1.category_id))

      assert length(categorized) >= 1
      assert length(uncategorized) >= 1
    end
  end

  describe "Context API functionality" do
    test "Context.get_user_dashboard_data works in database-as-user architecture" do
      # Context API should work without user_id parameters
      {:ok, dashboard_data} = Context.get_user_dashboard_data()

      assert is_list(dashboard_data.accounts)
      assert is_struct(dashboard_data.summary.total_balance, Decimal)
      assert is_integer(dashboard_data.summary.account_count)
      assert is_list(dashboard_data.recent_transactions)
    end

    test "Context.get_portfolio_summary calculates correctly" do
      account = SQLiteHelpers.get_default_account()

      symbol =
        SQLiteHelpers.get_or_create_symbol("PORTFOLIO", %{
          name: "Portfolio Test Stock",
          current_price: Decimal.new("100")
        })

      # Create transaction
      {:ok, _transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("100"),
          total_amount: Decimal.new("10000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Portfolio summary should calculate correctly
      {:ok, summary} = Context.get_portfolio_summary()

      assert is_struct(summary.total_value, Decimal)
      assert is_list(summary.accounts)
      assert is_list(summary.holdings)
    end

    test "Context.get_net_worth includes all account types" do
      # Create mixed account types
      {:ok, investment} =
        Account.create(%{
          name: "Brokerage",
          balance: Decimal.new("50000"),
          account_type: :investment
        })

      {:ok, checking} =
        Account.create(%{
          name: "Checking",
          balance: Decimal.new("5000"),
          account_type: :checking
        })

      # Net worth should include both
      {:ok, net_worth} = Context.get_net_worth()

      assert is_struct(net_worth.total_net_worth, Decimal)
      assert Decimal.compare(net_worth.total_net_worth, Decimal.new("0")) == :gt

      # Should have breakdown by account type
      assert is_map(net_worth.breakdown)
    end
  end

  describe "data integrity verification" do
    test "account balances remain accurate through operations" do
      # Create accounts with specific balances
      accounts_data = [
        %{name: "Account 1", balance: Decimal.new("1000.50")},
        %{name: "Account 2", balance: Decimal.new("2500.75")},
        %{name: "Account 3", balance: Decimal.new("10000.00")}
      ]

      created_accounts =
        Enum.map(accounts_data, fn data ->
          {:ok, account} = Account.create(data)
          account
        end)

      # Verify balances preserved
      Enum.zip(created_accounts, accounts_data)
      |> Enum.each(fn {account, original_data} ->
        assert Decimal.equal?(account.balance, original_data.balance)
      end)

      # Verify total calculation correct
      expected_total =
        accounts_data
        |> Enum.map(& &1.balance)
        |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)

      actual_total =
        created_accounts
        |> Enum.map(& &1.balance)
        |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)

      assert Decimal.equal?(expected_total, actual_total)
    end

    test "transaction amounts and calculations remain consistent" do
      account = SQLiteHelpers.get_default_account()

      symbol =
        SQLiteHelpers.get_or_create_symbol("INTEGRITY", %{
          name: "Integrity Test Stock",
          current_price: Decimal.new("50")
        })

      # Create transactions with specific values
      transactions_data = [
        %{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("50"),
          total_amount: Decimal.new("5000")
        },
        %{
          type: :sell,
          quantity: Decimal.new("-50"),
          price: Decimal.new("55"),
          total_amount: Decimal.new("-2750")
        },
        %{
          type: :dividend,
          quantity: Decimal.new("100"),
          price: Decimal.new("1"),
          total_amount: Decimal.new("100")
        }
      ]

      created_txs =
        Enum.map(transactions_data, fn data ->
          {:ok, tx} =
            Transaction.create(
              Map.merge(data, %{
                account_id: account.id,
                symbol_id: symbol.id,
                date: Date.utc_today()
              })
            )

          tx
        end)

      # Verify transaction integrity
      Enum.zip(created_txs, transactions_data)
      |> Enum.each(fn {tx, original_data} ->
        assert tx.type == original_data.type
        assert Decimal.equal?(tx.quantity, original_data.quantity)
        assert Decimal.equal?(tx.price, original_data.price)
        assert Decimal.equal?(tx.total_amount, original_data.total_amount)
      end)
    end

    test "account and transaction relationships remain intact" do
      # Create account
      {:ok, account} =
        Account.create(%{
          name: "Relationship Test Account",
          platform: "Test Platform",
          balance: Decimal.new("1000")
        })

      symbol =
        SQLiteHelpers.get_or_create_symbol("RELTEST", %{
          name: "Relationship Test Stock",
          current_price: Decimal.new("25")
        })

      # Create multiple transactions
      {:ok, tx1} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("40"),
          price: Decimal.new("25"),
          total_amount: Decimal.new("1000"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, tx2} =
        Transaction.create(%{
          type: :dividend,
          quantity: Decimal.new("40"),
          price: Decimal.new("0.50"),
          total_amount: Decimal.new("20"),
          date: Date.utc_today(),
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Verify relationships
      loaded_account = Ash.load!(account, [:transactions])
      transaction_ids = Enum.map(loaded_account.transactions, & &1.id)

      assert tx1.id in transaction_ids
      assert tx2.id in transaction_ids
      assert length(loaded_account.transactions) == 2
    end
  end

  describe "performance verification" do
    @tag :performance
    test "dashboard loading performance is acceptable" do
      # Create realistic test data
      setup_performance_test_data()

      # Measure Context API performance
      {time_us, {:ok, _result}} =
        :timer.tc(fn ->
          Context.get_user_dashboard_data()
        end)

      # Convert to milliseconds
      time_ms = time_us / 1000

      # Should load in reasonable time (< 100ms for test data)
      assert time_ms < 100, "Dashboard loading took #{time_ms}ms, expected < 100ms"
    end

    @tag :performance
    test "transaction query performance with categories" do
      account = SQLiteHelpers.get_default_account()

      symbol =
        SQLiteHelpers.get_or_create_symbol("PERFTEST", %{
          name: "Performance Test Stock",
          current_price: Decimal.new("10")
        })

      # Create many transactions (mix of categorized and uncategorized)
      for i <- 1..50 do
        {:ok, _tx} =
          Transaction.create(%{
            type: :buy,
            quantity: Decimal.new(to_string(i)),
            price: Decimal.new("10"),
            total_amount: Decimal.new(to_string(i * 10)),
            date: Date.add(Date.utc_today(), -i),
            account_id: account.id,
            symbol_id: symbol.id
          })
      end

      # Measure query performance
      {time_us, {:ok, _result}} =
        :timer.tc(fn ->
          Context.get_recent_transactions(25)
        end)

      time_ms = time_us / 1000

      # Should query efficiently
      assert time_ms < 50, "Transaction query took #{time_ms}ms, expected < 50ms"
    end

    @tag :performance
    test "net worth calculation performance with multiple accounts" do
      # Create various account types
      for i <- 1..5 do
        {:ok, _account} =
          Account.create(%{
            name: "Performance Account #{i}",
            balance: Decimal.new(to_string(i * 1000)),
            account_type: if(rem(i, 2) == 0, do: :checking, else: :investment)
          })
      end

      # Measure net worth calculation
      {time_us, {:ok, _result}} =
        :timer.tc(fn ->
          Context.get_net_worth()
        end)

      time_ms = time_us / 1000

      # Should calculate efficiently
      assert time_ms < 30, "Net worth calculation took #{time_ms}ms, expected < 30ms"
    end
  end

  describe "feature rollback capabilities" do
    test "category assignments can be removed" do
      account = SQLiteHelpers.get_default_account()

      symbol =
        SQLiteHelpers.get_or_create_symbol("ROLLBACK", %{
          name: "Rollback Test Stock",
          current_price: Decimal.new("75")
        })

      {:ok, category} =
        TransactionCategory.create(%{
          name: "Test Category",
          color: "#000000",
          is_system: false
        })

      # Create categorized transaction
      {:ok, transaction} =
        Transaction.create(%{
          account_id: account.id,
          symbol_id: symbol.id,
          category_id: category.id,
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("75"),
          total_amount: Decimal.new("750"),
          date: Date.utc_today()
        })

      assert transaction.category_id == category.id

      # Remove category assignment
      {:ok, uncategorized} =
        Transaction.update(transaction.id, %{
          category_id: nil
        })

      assert is_nil(uncategorized.category_id)
    end

    test "account types can be changed" do
      {:ok, account} =
        Account.create(%{
          name: "Flexible Account",
          platform: "Multi-Purpose",
          balance: Decimal.new("5000")
        })

      original_type = account.account_type
      assert original_type == :investment

      # Change to cash account
      {:ok, updated} =
        Account.update(account.id, %{
          account_type: :savings,
          interest_rate: Decimal.new("2.0")
        })

      assert updated.account_type == :savings
      assert Decimal.equal?(updated.interest_rate, Decimal.new("2.0"))

      # Revert to original
      {:ok, reverted} =
        Account.update(updated.id, %{
          account_type: original_type,
          interest_rate: nil
        })

      assert reverted.account_type == original_type
      assert is_nil(reverted.interest_rate)
    end
  end

  # Helper functions for test data setup

  defp setup_performance_test_data do
    # Create realistic test data for performance testing
    {:ok, account1} =
      Account.create(%{
        name: "Performance Checking",
        balance: Decimal.new("5000"),
        account_type: :checking
      })

    {:ok, account2} =
      Account.create(%{
        name: "Performance Investment",
        balance: Decimal.new("50000"),
        account_type: :investment
      })

    # Use unique symbols to avoid collision with global test data
    symbol1 =
      SQLiteHelpers.get_or_create_symbol("PERF1", %{
        name: "Performance Test Symbol 1",
        current_price: Decimal.new("100")
      })

    symbol2 =
      SQLiteHelpers.get_or_create_symbol("PERF2", %{
        name: "Performance Test Symbol 2",
        current_price: Decimal.new("50")
      })

    # Create some transactions
    for i <- 1..10 do
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new(to_string(i * 10)),
          price: Decimal.new("10"),
          total_amount: Decimal.new(to_string(i * 100)),
          date: Date.add(Date.utc_today(), -i),
          account_id: Enum.random([account1.id, account2.id]),
          symbol_id: Enum.random([symbol1.id, symbol2.id])
        })
    end

    :ok
  end
end
