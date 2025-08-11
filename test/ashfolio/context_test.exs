defmodule Ashfolio.ContextTest do
  @moduledoc """
  Tests for the Ashfolio.Context module.

  Tests the high-level Context API that provides reusable functions
  for common data access patterns across domains.
  """

  use Ashfolio.DataCase, async: false

  @moduletag :context_api
  @moduletag :unit
  @moduletag :fast

  alias Ashfolio.Context
  alias Ashfolio.Portfolio.{User, Account, Transaction, Symbol}

  describe "get_user_dashboard_data/1" do
    test "returns comprehensive dashboard data for default user" do
      # Get the default user that exists in the system
      {:ok, [default_user]} = User.get_default_user()

      # Create test data for the default user
      investment_account = create_investment_account(default_user.id)
      _cash_account = create_cash_account(default_user.id)
      symbol = create_symbol()
      _transaction = create_transaction(investment_account.id, symbol.id)

      # Test the dashboard data
      assert {:ok, dashboard_data} = Context.get_user_dashboard_data()

      assert dashboard_data.user.id == default_user.id
      assert dashboard_data.user.name == default_user.name

      # Check accounts are properly categorized
      # The default user already has at least the test accounts plus the ones we created
      assert length(dashboard_data.accounts.all) >= 2
      assert length(dashboard_data.accounts.investment) >= 1
      assert length(dashboard_data.accounts.cash) >= 1
      assert length(dashboard_data.accounts.active) >= 2

      # Check summary calculations
      assert dashboard_data.summary.account_count >= 2
      assert dashboard_data.summary.active_count >= 2
      assert dashboard_data.summary.cash_accounts >= 1
      assert dashboard_data.summary.investment_accounts >= 1
      assert is_struct(dashboard_data.summary.total_balance, Decimal)

      # Check recent transactions
      assert length(dashboard_data.recent_transactions) >= 0
      assert is_struct(dashboard_data.last_updated, DateTime)
    end

    test "returns dashboard data for specific user" do
      user = create_user()
      _account = create_investment_account(user.id)

      assert {:ok, dashboard_data} = Context.get_user_dashboard_data(user.id)
      assert dashboard_data.user.id == user.id
    end

    test "returns error for invalid user ID" do
      assert {:error, :user_not_found} = Context.get_user_dashboard_data("invalid-uuid")
    end

    test "handles accounts with different types" do
      user = create_user()

      # Create different account types
      checking = create_account(user.id, :checking, "Checking Account")
      savings = create_account(user.id, :savings, "Savings Account")
      investment = create_account(user.id, :investment, "Investment Account")

      assert {:ok, dashboard_data} = Context.get_user_dashboard_data(user.id)

      # Verify categorization
      assert length(dashboard_data.accounts.all) == 3
      assert length(dashboard_data.accounts.cash) == 2
      assert length(dashboard_data.accounts.investment) == 1

      cash_account_ids = Enum.map(dashboard_data.accounts.cash, & &1.id)
      assert checking.id in cash_account_ids
      assert savings.id in cash_account_ids

      investment_account_ids = Enum.map(dashboard_data.accounts.investment, & &1.id)
      assert investment.id in investment_account_ids
    end

    test "handles excluded accounts correctly" do
      user = create_user()
      active_account = create_investment_account(user.id)
      excluded_account = create_investment_account(user.id, %{is_excluded: true})

      assert {:ok, dashboard_data} = Context.get_user_dashboard_data(user.id)

      assert length(dashboard_data.accounts.all) == 2
      assert length(dashboard_data.accounts.active) == 1
      assert length(dashboard_data.accounts.excluded) == 1

      active_ids = Enum.map(dashboard_data.accounts.active, & &1.id)
      excluded_ids = Enum.map(dashboard_data.accounts.excluded, & &1.id)

      assert active_account.id in active_ids
      assert excluded_account.id in excluded_ids
    end
  end

  describe "get_account_with_transactions/2" do
    test "returns account data with transaction history" do
      user = create_user()
      account = create_investment_account(user.id)
      symbol = create_symbol()
      transaction = create_transaction(account.id, symbol.id)

      assert {:ok, account_data} = Context.get_account_with_transactions(account.id)

      assert account_data.account.id == account.id
      assert length(account_data.transactions) >= 1

      # Check transaction summary
      assert is_integer(account_data.summary.transaction_count)
      assert is_struct(account_data.summary.total_inflow, Decimal)
      assert is_struct(account_data.summary.total_outflow, Decimal)
      assert is_struct(account_data.summary.net_flow, Decimal)

      # Check balance history
      assert is_list(account_data.balance_history)

      assert is_struct(account_data.last_updated, DateTime)
    end

    test "respects transaction limit parameter" do
      user = create_user()
      account = create_investment_account(user.id)
      symbol = create_symbol()

      # Create multiple transactions
      _t1 = create_transaction(account.id, symbol.id, %{date: days_ago(3)})
      _t2 = create_transaction(account.id, symbol.id, %{date: days_ago(2)})
      _t3 = create_transaction(account.id, symbol.id, %{date: days_ago(1)})

      assert {:ok, account_data} = Context.get_account_with_transactions(account.id, 2)
      assert length(account_data.transactions) <= 2
    end

    test "returns error for invalid account ID" do
      assert {:error, _reason} = Context.get_account_with_transactions("invalid-uuid")
    end

    test "calculates transaction summary correctly" do
      user = create_user()
      account = create_investment_account(user.id)
      symbol = create_symbol()

      # Create buy transaction (+inflow)
      _buy_tx = create_transaction(account.id, symbol.id, %{
        type: :buy,
        total_amount: Decimal.new(1000)
      })

      # Create dividend transaction (+inflow)
      _div_tx = create_transaction(account.id, symbol.id, %{
        type: :dividend,
        total_amount: Decimal.new(25)
      })

      assert {:ok, account_data} = Context.get_account_with_transactions(account.id)

      # Check inflows are calculated correctly
      expected_inflow = Decimal.add(Decimal.new(1000), Decimal.new(25))
      assert Decimal.equal?(account_data.summary.total_inflow, expected_inflow)
    end
  end

  describe "get_portfolio_summary/1" do
    test "returns comprehensive portfolio summary" do
      user = create_user()
      account = create_investment_account(user.id)
      symbol = create_symbol()
      _transaction = create_transaction(account.id, symbol.id)

      assert {:ok, summary} = Context.get_portfolio_summary()

      assert is_struct(summary.total_value, Decimal)
      assert is_map(summary.total_return)
      assert is_struct(summary.total_return.amount, Decimal)
      assert is_struct(summary.total_return.percentage, Decimal)
      assert is_list(summary.accounts)
      assert is_list(summary.holdings)
      assert is_map(summary.performance)
      assert is_struct(summary.last_updated, DateTime)
    end

    test "returns portfolio summary for specific user" do
      user = create_user()
      _account = create_investment_account(user.id)

      assert {:ok, summary} = Context.get_portfolio_summary(user.id)
      assert is_struct(summary.total_value, Decimal)
    end

    test "returns error for invalid user ID" do
      assert {:error, :user_not_found} = Context.get_portfolio_summary("invalid-uuid")
    end

    test "filters out excluded accounts from portfolio summary" do
      user = create_user()
      active_account = create_investment_account(user.id)
      excluded_account = create_investment_account(user.id, %{is_excluded: true})

      assert {:ok, summary} = Context.get_portfolio_summary(user.id)

      account_ids = Enum.map(summary.accounts, & &1.id)
      assert active_account.id in account_ids
      refute excluded_account.id in account_ids
    end
  end

  describe "get_recent_transactions/2" do
    test "returns recent transactions across all accounts" do
      user = create_user()
      account1 = create_investment_account(user.id)
      account2 = create_investment_account(user.id)
      symbol = create_symbol()

      _tx1 = create_transaction(account1.id, symbol.id, %{date: days_ago(2)})
      _tx2 = create_transaction(account2.id, symbol.id, %{date: days_ago(1)})

      assert {:ok, transactions} = Context.get_recent_transactions(user.id, 10)
      assert length(transactions) >= 2

      # Check that transactions are sorted by date (most recent first)
      dates = Enum.map(transactions, & &1.date)
      sorted_dates = Enum.sort(dates, {:desc, Date})
      assert dates == sorted_dates
    end

    test "respects the limit parameter" do
      user = create_user()
      account = create_investment_account(user.id)
      symbol = create_symbol()

      # Create 5 transactions
      for i <- 1..5 do
        create_transaction(account.id, symbol.id, %{date: days_ago(i)})
      end

      assert {:ok, transactions} = Context.get_recent_transactions(user.id, 3)
      assert length(transactions) == 3
    end

    test "returns empty list when no transactions exist" do
      user = create_user()
      _account = create_investment_account(user.id)

      assert {:ok, transactions} = Context.get_recent_transactions(user.id, 10)
      assert transactions == []
    end
  end

  describe "get_net_worth/1" do
    test "calculates net worth combining investment and cash balances" do
      user = create_user()

      # Create investment account with balance
      _investment = create_account(user.id, :investment, "Investment", %{balance: Decimal.new(10000)})

      # Create cash accounts with balances
      _checking = create_account(user.id, :checking, "Checking", %{balance: Decimal.new(5000)})
      _savings = create_account(user.id, :savings, "Savings", %{balance: Decimal.new(15000)})

      assert {:ok, net_worth} = Context.get_net_worth(user.id)

      assert is_struct(net_worth.total_net_worth, Decimal)
      assert is_struct(net_worth.investment_value, Decimal)
      assert is_struct(net_worth.cash_balance, Decimal)

      # Cash balance should be 5000 + 15000 = 20000
      assert Decimal.equal?(net_worth.cash_balance, Decimal.new(20000))

      # Check breakdown
      assert net_worth.breakdown.cash_accounts == 2
      assert net_worth.breakdown.investment_accounts == 1
      assert is_struct(net_worth.breakdown.cash_percentage, Decimal)
      assert is_struct(net_worth.breakdown.investment_percentage, Decimal)
    end

    test "returns error for invalid user ID" do
      assert {:error, :user_not_found} = Context.get_net_worth("invalid-uuid")
    end

    test "handles zero balances correctly" do
      user = create_user()
      _account = create_account(user.id, :checking, "Empty Account", %{balance: Decimal.new(0)})

      assert {:ok, net_worth} = Context.get_net_worth(user.id)
      assert Decimal.equal?(net_worth.total_net_worth, Decimal.new(0))
      assert Decimal.equal?(net_worth.cash_balance, Decimal.new(0))
    end
  end

  describe "performance monitoring" do
    test "tracks telemetry events" do
      # Set up telemetry handler for testing
      test_pid = self()

      handler_id = :test_handler
      :telemetry.attach_many(
        handler_id,
        [
          [:ashfolio, :context, :get_user_dashboard_data],
          [:ashfolio, :context, :get_user_dashboard_data, :success]
        ],
        fn event, measurements, metadata, _ ->
          send(test_pid, {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      # Create test data and call function
      user = create_user()
      _account = create_investment_account(user.id)

      assert {:ok, _data} = Context.get_user_dashboard_data(user.id)

      # Check that telemetry events were emitted
      assert_receive {:telemetry, [:ashfolio, :context, :get_user_dashboard_data], %{duration: _}, %{operation: :get_user_dashboard_data}}
      assert_receive {:telemetry, [:ashfolio, :context, :get_user_dashboard_data, :success], %{}, %{}}

      :telemetry.detach(handler_id)
    end
  end

  # Helper functions for creating test data

  defp create_user(attrs \\ %{}) do
    default_attrs = %{
      name: "Test User",
      currency: "USD",
      locale: "en-US"
    }

    attrs = Map.merge(default_attrs, attrs)
    {:ok, user} = User.create(attrs)
    user
  end

  defp create_investment_account(user_id, attrs \\ %{}) do
    create_account(user_id, :investment, "Investment Account", attrs)
  end

  defp create_cash_account(user_id, attrs \\ %{}) do
    create_account(user_id, :checking, "Checking Account", attrs)
  end

  defp create_account(user_id, account_type, name, attrs \\ %{}) do
    default_attrs = %{
      user_id: user_id,
      name: name,
      account_type: account_type,
      currency: "USD",
      balance: Decimal.new(1000),
      platform: "Test Platform"
    }

    attrs = Map.merge(default_attrs, attrs)
    {:ok, account} = Account.create(attrs)
    account
  end

  defp create_symbol(attrs \\ %{}) do
    # Generate unique symbol to avoid conflicts
    unique_suffix = :crypto.strong_rand_bytes(4) |> Base.encode16()

    default_attrs = %{
      symbol: "AAPL#{unique_suffix}",
      name: "Apple Inc. #{unique_suffix}",
      asset_class: :stock,
      data_source: :manual,
      current_price: Decimal.new("150.00")
    }

    attrs = Map.merge(default_attrs, attrs)
    {:ok, symbol} = Symbol.create(attrs)
    symbol
  end

  defp create_transaction(account_id, symbol_id, attrs \\ %{}) do
    default_attrs = %{
      account_id: account_id,
      symbol_id: symbol_id,
      type: :buy,
      quantity: Decimal.new(10),
      price: Decimal.new("100.00"),
      total_amount: Decimal.new(1000),
      date: Date.utc_today()
    }

    attrs = Map.merge(default_attrs, attrs)
    {:ok, transaction} = Transaction.create(attrs)
    transaction
  end

  defp days_ago(days) do
    Date.utc_today()
    |> Date.add(-days)
  end
end
