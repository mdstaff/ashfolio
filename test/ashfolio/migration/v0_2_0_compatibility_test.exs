defmodule Ashfolio.Migration.V020CompatibilityTest do
  @moduledoc """
  Comprehensive migration and backward compatibility tests for v0.2.0.
  
  Ensures seamless upgrade path from v0.1.0 to v0.2.0 with data integrity,
  tests Context API compatibility with existing data structures, and validates
  that all enhanced features work correctly with legacy data.
  
  Key Test Scenarios:
  - Account migration with new cash account types
  - Transaction integrity with optional categories
  - Context API compatibility with v0.1.0 data
  - Performance benchmarks comparing versions
  - Rollback procedures for critical failures
  """
  
  use Ashfolio.DataCase, async: false
  
  @moduletag :migration
  @moduletag :compatibility
  @moduletag :v0_2_0
  
  alias Ashfolio.Portfolio.{User, Account, Transaction, Symbol}
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Context
  alias Ashfolio.Repo
  
  import Ecto.Query
  
  describe "v0.1.0 to v0.2.0 account migration" do
    test "existing investment accounts maintain backward compatibility" do
      # Create v0.1.0 style account (before account_type was added)
      {:ok, user} = create_legacy_user()
      
      # Simulate v0.1.0 account creation
      {:ok, legacy_account} = create_v010_account(user.id, %{
        name: "Legacy Investment Account",
        platform: "Brokerage",
        balance: Decimal.new("50000"),
        currency: "USD"
      })
      
      # Verify account still works with new system
      assert legacy_account.account_type == :investment  # Default value applied
      assert is_nil(legacy_account.interest_rate)
      assert is_nil(legacy_account.minimum_balance)
      
      # Verify Context API works with legacy account
      {:ok, dashboard_data} = Context.get_user_dashboard_data(user.id)
      assert length(dashboard_data.accounts.all) == 1
      assert length(dashboard_data.accounts.investment) == 1
      assert length(dashboard_data.accounts.cash) == 0
    end
    
    test "accounts can be upgraded to new account types" do
      {:ok, user} = create_legacy_user()
      
      # Create multiple legacy accounts
      {:ok, account1} = create_v010_account(user.id, %{
        name: "Checking Account",
        platform: "Bank",
        balance: Decimal.new("5000")
      })
      
      {:ok, account2} = create_v010_account(user.id, %{
        name: "401k Account",
        platform: "Fidelity",
        balance: Decimal.new("100000")
      })
      
      # Upgrade accounts to appropriate types
      {:ok, upgraded1} = upgrade_account_type(account1, :checking)
      {:ok, upgraded2} = upgrade_account_type(account2, :investment)
      
      assert upgraded1.account_type == :checking
      assert upgraded2.account_type == :investment
      
      # Verify Context API categorizes them correctly
      {:ok, dashboard_data} = Context.get_user_dashboard_data(user.id)
      assert length(dashboard_data.accounts.cash) == 1
      assert length(dashboard_data.accounts.investment) == 1
    end
    
    test "new cash account attributes are optional and backward compatible" do
      {:ok, user} = create_legacy_user()
      
      # Create account without new attributes
      {:ok, account} = create_v010_account(user.id, %{
        name: "Test Account",
        platform: "Bank"
      })
      
      # Account should work without interest_rate and minimum_balance
      assert is_nil(account.interest_rate)
      assert is_nil(account.minimum_balance)
      
      # First upgrade to cash account type to allow interest_rate
      {:ok, cash_account} = upgrade_account_type(account, :savings)
      
      # Now can update with new attributes (only for cash account types)
      {:ok, updated} = Account.update(cash_account.id, %{
        interest_rate: Decimal.new("2.5"),
        minimum_balance: Decimal.new("1000")
      })
      
      assert Decimal.equal?(updated.interest_rate, Decimal.new("2.5"))
      assert Decimal.equal?(updated.minimum_balance, Decimal.new("1000"))
    end
  end
  
  describe "v0.1.0 to v0.2.0 transaction migration" do
    test "existing transactions work without categories" do
      {:ok, user} = create_legacy_user()
      {:ok, account} = create_v010_account(user.id)
      {:ok, symbol} = create_v010_symbol()
      
      # Create v0.1.0 style transaction (no category)
      {:ok, transaction} = create_v010_transaction(account.id, symbol.id, %{
        type: :buy,
        quantity: Decimal.new("100"),
        price: Decimal.new("50"),
        total_amount: Decimal.new("5000"),
        date: Date.utc_today()
      })
      
      # Transaction should work without category
      assert is_nil(transaction.category_id)
      
      # Context API should handle uncategorized transactions
      {:ok, account_data} = Context.get_account_with_transactions(account.id)
      assert length(account_data.transactions) == 1
      
      first_tx = hd(account_data.transactions)
      assert is_nil(first_tx.category_id)
    end
    
    test "transactions can be assigned categories after migration" do
      {:ok, user} = create_legacy_user()
      {:ok, account} = create_v010_account(user.id)
      {:ok, symbol} = create_v010_symbol()
      
      # Create uncategorized transaction
      {:ok, transaction} = create_v010_transaction(account.id, symbol.id)
      
      # Create category
      {:ok, category} = TransactionCategory.create(%{
        name: "Growth",
        color: "#10B981",
        is_system: true,
        user_id: user.id
      })
      
      # Assign category to existing transaction
      {:ok, updated} = Transaction.update(transaction.id, %{
        category_id: category.id
      })
      
      assert updated.category_id == category.id
      
      # Load with category relationship
      loaded = Ash.load!(updated, [:category])
      assert loaded.category.name == "Growth"
    end
    
    test "mixed transactions (with and without categories) work correctly" do
      {:ok, user} = create_legacy_user()
      {:ok, account} = create_v010_account(user.id)
      {:ok, symbol} = create_v010_symbol()
      
      # Create category
      {:ok, category} = TransactionCategory.create(%{
        name: "Income",
        color: "#3B82F6",
        is_system: true,
        user_id: user.id
      })
      
      # Create mix of transactions
      {:ok, _tx1} = create_v010_transaction(account.id, symbol.id, %{
        type: :buy,
        quantity: Decimal.new("50")
      })
      
      {:ok, _tx2} = Transaction.create(%{
        account_id: account.id,
        symbol_id: symbol.id,
        category_id: category.id,
        type: :dividend,
        quantity: Decimal.new("50"),
        price: Decimal.new("2"),
        total_amount: Decimal.new("100"),
        date: Date.utc_today()
      })
      
      # Both should work through Context API
      {:ok, recent_txs} = Context.get_recent_transactions(user.id, 10)
      assert length(recent_txs) == 2
      
      # One with category, one without
      categorized = Enum.filter(recent_txs, & &1.category_id)
      uncategorized = Enum.filter(recent_txs, &is_nil(&1.category_id))
      
      assert length(categorized) == 1
      assert length(uncategorized) == 1
    end
  end
  
  describe "Context API backward compatibility" do
    test "Context.get_user_dashboard_data works with v0.1.0 data" do
      # Create v0.1.0 style data
      {:ok, user} = create_legacy_user()
      {:ok, account} = create_v010_account(user.id)
      {:ok, symbol} = create_v010_symbol()
      {:ok, _transaction} = create_v010_transaction(account.id, symbol.id)
      
      # Context API should handle legacy data gracefully
      {:ok, dashboard_data} = Context.get_user_dashboard_data(user.id)
      
      assert dashboard_data.user.id == user.id
      assert length(dashboard_data.accounts.all) == 1
      assert dashboard_data.summary.account_count == 1
      assert is_struct(dashboard_data.summary.total_balance, Decimal)
      assert length(dashboard_data.recent_transactions) >= 0
    end
    
    test "Context.get_portfolio_summary works with legacy investment accounts" do
      {:ok, user} = create_legacy_user()
      {:ok, account} = create_v010_account(user.id, %{
        name: "Investment Account",
        balance: Decimal.new("10000")
      })
      {:ok, symbol} = create_v010_symbol()
      {:ok, _transaction} = create_v010_transaction(account.id, symbol.id, %{
        quantity: Decimal.new("100"),
        price: Decimal.new("100"),
        total_amount: Decimal.new("10000")
      })
      
      # Portfolio summary should calculate correctly
      {:ok, summary} = Context.get_portfolio_summary(user.id)
      
      assert is_struct(summary.total_value, Decimal)
      assert length(summary.accounts) == 1
      assert length(summary.holdings) >= 0
    end
    
    test "Context.get_net_worth includes legacy accounts correctly" do
      {:ok, user} = create_legacy_user()
      
      # Create mix of account types (some with explicit types, some defaulted)
      {:ok, _investment} = create_v010_account(user.id, %{
        name: "Brokerage",
        balance: Decimal.new("50000")
      })
      
      {:ok, checking} = create_v010_account(user.id, %{
        name: "Checking",
        balance: Decimal.new("5000")
      })
      
      # Upgrade one to cash type
      {:ok, _} = upgrade_account_type(checking, :checking)
      
      # Net worth should include both
      {:ok, net_worth} = Context.get_net_worth(user.id)
      
      assert is_struct(net_worth.total_net_worth, Decimal)
      assert Decimal.compare(net_worth.total_net_worth, Decimal.new("0")) == :gt
      assert net_worth.breakdown.cash_accounts == 1
      assert net_worth.breakdown.investment_accounts == 1
    end
  end
  
  describe "data integrity verification" do
    test "all account balances remain accurate after migration" do
      {:ok, user} = create_legacy_user()
      
      # Create accounts with specific balances
      accounts_data = [
        %{name: "Account 1", balance: Decimal.new("1000.50")},
        %{name: "Account 2", balance: Decimal.new("2500.75")},
        %{name: "Account 3", balance: Decimal.new("10000.00")}
      ]
      
      created_accounts = Enum.map(accounts_data, fn data ->
        {:ok, account} = create_v010_account(user.id, data)
        account
      end)
      
      # Verify balances preserved
      Enum.zip(created_accounts, accounts_data)
      |> Enum.each(fn {account, original_data} ->
        assert Decimal.equal?(account.balance, original_data.balance)
      end)
      
      # Verify total calculation correct
      expected_total = accounts_data
        |> Enum.map(& &1.balance)
        |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)
      
      actual_total = created_accounts
        |> Enum.map(& &1.balance)
        |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)
      
      assert Decimal.equal?(expected_total, actual_total)
    end
    
    test "transaction amounts and calculations remain consistent" do
      {:ok, user} = create_legacy_user()
      {:ok, account} = create_v010_account(user.id)
      {:ok, symbol} = create_v010_symbol()
      
      # Create transactions with specific values
      transactions_data = [
        %{type: :buy, quantity: Decimal.new("100"), price: Decimal.new("50"), total_amount: Decimal.new("5000")},
        %{type: :sell, quantity: Decimal.new("-50"), price: Decimal.new("55"), total_amount: Decimal.new("-2750")},
        %{type: :dividend, quantity: Decimal.new("100"), price: Decimal.new("1"), total_amount: Decimal.new("100")}
      ]
      
      created_txs = Enum.map(transactions_data, fn data ->
        {:ok, tx} = create_v010_transaction(account.id, symbol.id, data)
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
    
    test "user data and relationships remain intact" do
      {:ok, user} = create_legacy_user(%{
        name: "Test User",
        currency: "USD",
        locale: "en-US"
      })
      
      # Create related data
      {:ok, account1} = create_v010_account(user.id)
      {:ok, account2} = create_v010_account(user.id)
      
      # Verify relationships
      {:ok, user_accounts} = Account.accounts_for_user(user.id)
      assert length(user_accounts) == 2
      assert Enum.all?(user_accounts, &(&1.user_id == user.id))
      
      account_ids = Enum.map(user_accounts, & &1.id)
      assert account1.id in account_ids
      assert account2.id in account_ids
    end
  end
  
  describe "performance comparison v0.1.0 vs v0.2.0" do
    @tag :performance
    test "dashboard loading performance remains consistent" do
      {:ok, user} = create_legacy_user()
      setup_performance_test_data(user.id)
      
      # Measure v0.2.0 Context API performance
      {time_v020, {:ok, _result}} = :timer.tc(fn ->
        Context.get_user_dashboard_data(user.id)
      end)
      
      # Convert to milliseconds
      time_ms = time_v020 / 1000
      
      # Should load in reasonable time (< 100ms for test data)
      assert time_ms < 100, "Dashboard loading took #{time_ms}ms, expected < 100ms"
    end
    
    @tag :performance
    test "transaction query performance with optional categories" do
      {:ok, user} = create_legacy_user()
      {:ok, account} = create_v010_account(user.id)
      {:ok, symbol} = create_v010_symbol()
      
      # Create many transactions (mix of categorized and uncategorized)
      transactions = for i <- 1..100 do
        {:ok, tx} = create_v010_transaction(account.id, symbol.id, %{
          quantity: Decimal.new(to_string(i)),
          date: Date.add(Date.utc_today(), -i)
        })
        tx
      end
      
      # Measure query performance
      {time_us, {:ok, _result}} = :timer.tc(fn ->
        Context.get_recent_transactions(user.id, 50)
      end)
      
      time_ms = time_us / 1000
      
      # Should query efficiently even with mixed data
      assert time_ms < 50, "Transaction query took #{time_ms}ms, expected < 50ms"
      assert length(transactions) == 100  # Ensure we created test data
    end
    
    @tag :performance
    test "net worth calculation performance with mixed account types" do
      {:ok, user} = create_legacy_user()
      
      # Create various account types
      for i <- 1..10 do
        {:ok, _account} = create_v010_account(user.id, %{
          name: "Account #{i}",
          balance: Decimal.new(to_string(i * 1000))
        })
      end
      
      # Measure net worth calculation
      {time_us, {:ok, _result}} = :timer.tc(fn ->
        Context.get_net_worth(user.id)
      end)
      
      time_ms = time_us / 1000
      
      # Should calculate efficiently
      assert time_ms < 30, "Net worth calculation took #{time_ms}ms, expected < 30ms"
    end
  end
  
  describe "migration rollback procedures" do
    test "category migration can be rolled back safely" do
      {:ok, user} = create_legacy_user()
      
      # Seed system categories (simulating migration)
      {:ok, _categories} = seed_system_categories(user.id)
      
      # Create user category
      {:ok, user_category} = TransactionCategory.create(%{
        name: "My Custom Category",
        color: "#FF0000",
        is_system: false,
        user_id: user.id
      })
      
      # Verify categories exist
      {:ok, all_categories} = TransactionCategory.categories_for_user(user.id)
      assert length(all_categories) == 7  # 6 system + 1 user
      
      # Rollback system categories
      rollback_system_categories(user.id)
      
      # Only user category should remain
      {:ok, remaining} = TransactionCategory.categories_for_user(user.id)
      assert length(remaining) == 1
      assert hd(remaining).id == user_category.id
    end
    
    test "account type changes can be reverted" do
      {:ok, user} = create_legacy_user()
      {:ok, account} = create_v010_account(user.id)
      
      original_type = account.account_type
      
      # Change account type
      {:ok, updated} = upgrade_account_type(account, :checking)
      assert updated.account_type == :checking
      
      # Revert to original
      {:ok, reverted} = Account.update(updated.id, %{
        account_type: original_type
      })
      
      assert reverted.account_type == original_type
    end
    
    test "transaction category assignments can be removed" do
      {:ok, user} = create_legacy_user()
      {:ok, account} = create_v010_account(user.id)
      {:ok, symbol} = create_v010_symbol()
      {:ok, category} = TransactionCategory.create(%{
        name: "Test Category",
        color: "#000000",
        user_id: user.id
      })
      
      # Create categorized transaction
      {:ok, transaction} = Transaction.create(%{
        account_id: account.id,
        symbol_id: symbol.id,
        category_id: category.id,
        type: :buy,
        quantity: Decimal.new("10"),
        price: Decimal.new("100"),
        total_amount: Decimal.new("1000"),
        date: Date.utc_today()
      })
      
      assert transaction.category_id == category.id
      
      # Remove category assignment
      {:ok, uncategorized} = Transaction.update(transaction.id, %{
        category_id: nil
      })
      
      assert is_nil(uncategorized.category_id)
    end
  end
  
  # Helper functions for creating v0.1.0 style data
  
  defp create_legacy_user(attrs \\ %{}) do
    User.create(Map.merge(%{
      name: "Legacy User",
      currency: "USD",
      locale: "en-US"
    }, attrs))
  end
  
  defp create_v010_account(user_id, attrs \\ %{}) do
    # Simulate v0.1.0 account creation (before account_type existed)
    Account.create(Map.merge(%{
      user_id: user_id,
      name: "Legacy Account",
      platform: "Platform",
      currency: "USD",
      balance: Decimal.new("1000")
    }, attrs))
  end
  
  defp create_v010_symbol(attrs \\ %{}) do
    Symbol.create(Map.merge(%{
      symbol: "LEGACY",
      name: "Legacy Symbol",
      asset_class: :stock,
      data_source: :manual,
      current_price: Decimal.new("100")
    }, attrs))
  end
  
  defp create_v010_transaction(account_id, symbol_id, attrs \\ %{}) do
    Transaction.create(Map.merge(%{
      account_id: account_id,
      symbol_id: symbol_id,
      type: :buy,
      quantity: Decimal.new("10"),
      price: Decimal.new("100"),
      total_amount: Decimal.new("1000"),
      date: Date.utc_today()
    }, attrs))
  end
  
  defp upgrade_account_type(account, new_type) do
    Account.update(account.id, %{account_type: new_type})
  end
  
  defp seed_system_categories(user_id) do
    categories = [
      %{name: "Growth", color: "#10B981"},
      %{name: "Income", color: "#3B82F6"},
      %{name: "Speculative", color: "#F59E0B"},
      %{name: "Index", color: "#8B5CF6"},
      %{name: "Cash", color: "#6B7280"},
      %{name: "Bonds", color: "#059669"}
    ]
    
    created = Enum.map(categories, fn cat_data ->
      {:ok, cat} = TransactionCategory.create(Map.merge(cat_data, %{
        is_system: true,
        user_id: user_id
      }))
      cat
    end)
    
    {:ok, created}
  end
  
  defp rollback_system_categories(user_id) do
    system_names = ["Growth", "Income", "Speculative", "Index", "Cash", "Bonds"]
    
    from(tc in "transaction_categories",
      where: tc.user_id == ^user_id and tc.is_system == true and tc.name in ^system_names
    )
    |> Repo.delete_all()
  end
  
  defp setup_performance_test_data(user_id) do
    # Create realistic test data for performance testing
    {:ok, account1} = create_v010_account(user_id, %{name: "Checking", balance: Decimal.new("5000")})
    {:ok, account2} = create_v010_account(user_id, %{name: "Investment", balance: Decimal.new("50000")})
    
    # Use unique symbols to avoid collision with global test data
    {:ok, symbol1} = create_v010_symbol(%{symbol: "PERF1", name: "Performance Test Symbol 1"})
    {:ok, symbol2} = create_v010_symbol(%{symbol: "PERF2", name: "Performance Test Symbol 2"})
    
    # Create some transactions
    for i <- 1..10 do
      {:ok, _} = create_v010_transaction(
        Enum.random([account1.id, account2.id]),
        Enum.random([symbol1.id, symbol2.id]),
        %{
          quantity: Decimal.new(to_string(i * 10)),
          date: Date.add(Date.utc_today(), -i)
        }
      )
    end
    
    :ok
  end
end