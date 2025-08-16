defmodule Ashfolio.Integration.NetWorthIntegrationTest do
  @moduledoc """
  Comprehensive integration tests for net worth calculation across mixed account types.

  Tests the integration between Portfolio and FinancialManagement domains for:
  - Investment accounts + cash accounts = total net worth
  - Real-time net worth updates when balances change
  - Performance optimization with NetWorthCalculatorOptimized
  - PubSub notifications for net worth changes
  - Edge cases with zero balances and excluded accounts
  """

  use Ashfolio.DataCase, async: false

  @moduletag :integration
  @moduletag :v0_2_0

  alias Ashfolio.Context
  alias Ashfolio.Portfolio.{User, Account, Symbol, Transaction}
  # alias Ashfolio.Portfolio.Calculator
  alias Ashfolio.FinancialManagement.{NetWorthCalculator, BalanceManager}
  alias Phoenix.PubSub

  describe "net worth calculation across mixed account types" do
    setup do
      {:ok, user} =
        User.create(%{
          name: "Net Worth Test User",
          currency: "USD",
          locale: "en-US"
        })

      # Create a symbol for transaction testing
      {:ok, symbol} =
        Symbol.create(%{
          symbol: "VTI",
          name: "Vanguard Total Stock Market ETF",
          current_price: Decimal.new("220.50"),
          data_source: :manual,
          asset_class: :etf
        })

      {:ok, user: user, symbol: symbol}
    end

    test "investment accounts + cash accounts = total net worth", %{user: user, symbol: symbol} do
      # Create investment account with transactions
      {:ok, brokerage} =
        Account.create(%{
          name: "Main Brokerage",
          account_type: :investment,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("0")
        })

      # Add investment transaction
      {:ok, _transaction} =
        Transaction.create(%{
          account_id: brokerage.id,
          symbol_id: symbol.id,
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("220.50"),
          date: Date.utc_today(),
          total_amount: Decimal.new("22050.00")
        })

      # Create cash accounts
      {:ok, _checking} =
        Account.create(%{
          name: "Checking",
          account_type: :checking,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("5000.00")
        })

      {:ok, _savings} =
        Account.create(%{
          name: "Savings",
          account_type: :savings,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("15000.00")
        })

      # Calculate net worth
      {:ok, net_worth} = Context.get_net_worth(user.id)

      # Verify components
      assert Decimal.equal?(net_worth.cash_balance, Decimal.new("20000.00"))
      assert Decimal.equal?(net_worth.investment_value, Decimal.new("22050.00"))
      assert Decimal.equal?(net_worth.total_net_worth, Decimal.new("42050.00"))

      # Verify breakdown percentages
      cash_pct = net_worth.breakdown.cash_percentage
      investment_pct = net_worth.breakdown.investment_percentage

      # Cash should be ~47.6% (20000/42050)
      assert Decimal.compare(cash_pct, Decimal.new("47")) == :gt
      assert Decimal.compare(cash_pct, Decimal.new("48")) == :lt

      # Investment should be ~52.4%
      assert Decimal.compare(investment_pct, Decimal.new("52")) == :gt
      assert Decimal.compare(investment_pct, Decimal.new("53")) == :lt
    end

    test "net worth updates when investment prices change", %{user: user, symbol: symbol} do
      # Create investment account with position
      {:ok, brokerage} =
        Account.create(%{
          name: "Price Change Test",
          account_type: :investment,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("0")
        })

      {:ok, _transaction} =
        Transaction.create(%{
          account_id: brokerage.id,
          symbol_id: symbol.id,
          type: :buy,
          quantity: Decimal.new("50"),
          price: Decimal.new("220.50"),
          date: Date.utc_today(),
          total_amount: Decimal.new("11025.00")
        })

      # Create cash account
      {:ok, _checking} =
        Account.create(%{
          name: "Checking",
          account_type: :checking,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("5000.00")
        })

      # Initial net worth calculation
      {:ok, initial_net_worth} = Context.get_net_worth(user.id)
      assert Decimal.equal?(initial_net_worth.total_net_worth, Decimal.new("16025.00"))

      # Update symbol price
      {:ok, _updated_symbol} =
        Symbol.update_price(symbol, %{current_price: Decimal.new("250.00")})

      # Recalculate net worth after price change
      {:ok, updated_net_worth} = Context.get_net_worth(user.id)

      # Investment value should increase: 50 shares * $250 = $12,500
      # Total net worth: $12,500 (investment) + $5,000 (cash) = $17,500
      assert Decimal.equal?(updated_net_worth.investment_value, Decimal.new("12500.00"))
      assert Decimal.equal?(updated_net_worth.cash_balance, Decimal.new("5000.00"))
      assert Decimal.equal?(updated_net_worth.total_net_worth, Decimal.new("17500.00"))

      # Verify the change
      net_worth_increase =
        Decimal.sub(updated_net_worth.total_net_worth, initial_net_worth.total_net_worth)

      assert Decimal.equal?(net_worth_increase, Decimal.new("1475.00"))
    end

    test "net worth updates when cash balances change", %{user: user, symbol: symbol} do
      # Create stable investment
      {:ok, brokerage} =
        Account.create(%{
          name: "Stable Investment",
          account_type: :investment,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("0")
        })

      {:ok, _transaction} =
        Transaction.create(%{
          account_id: brokerage.id,
          symbol_id: symbol.id,
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("220.50"),
          date: Date.utc_today(),
          total_amount: Decimal.new("2205.00")
        })

      # Create cash account
      {:ok, savings} =
        Account.create(%{
          name: "Variable Savings",
          account_type: :savings,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("10000.00")
        })

      # Initial calculation
      {:ok, initial_net_worth} = Context.get_net_worth(user.id)
      assert Decimal.equal?(initial_net_worth.total_net_worth, Decimal.new("12205.00"))

      # Update cash balance
      {:ok, _updated_account} =
        BalanceManager.update_cash_balance(
          savings.id,
          Decimal.new("15000.00"),
          "Large deposit"
        )

      # Recalculate after cash change
      {:ok, updated_net_worth} = Context.get_net_worth(user.id)

      # Investment value stays same, cash increases
      assert Decimal.equal?(updated_net_worth.investment_value, Decimal.new("2205.00"))
      assert Decimal.equal?(updated_net_worth.cash_balance, Decimal.new("15000.00"))
      assert Decimal.equal?(updated_net_worth.total_net_worth, Decimal.new("17205.00"))

      # Verify the change
      increase = Decimal.sub(updated_net_worth.total_net_worth, initial_net_worth.total_net_worth)
      assert Decimal.equal?(increase, Decimal.new("5000.00"))
    end

    test "excluded accounts don't affect net worth", %{user: user, symbol: symbol} do
      # Create included investment account
      {:ok, main_brokerage} =
        Account.create(%{
          name: "Main Brokerage",
          account_type: :investment,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("0"),
          is_excluded: false
        })

      # Create excluded investment account
      {:ok, retired_401k} =
        Account.create(%{
          name: "Old 401k",
          account_type: :investment,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("0"),
          is_excluded: true
        })

      # Add transactions to both accounts
      {:ok, _main_transaction} =
        Transaction.create(%{
          account_id: main_brokerage.id,
          symbol_id: symbol.id,
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("220.50"),
          date: Date.utc_today(),
          total_amount: Decimal.new("22050.00")
        })

      {:ok, _excluded_transaction} =
        Transaction.create(%{
          account_id: retired_401k.id,
          symbol_id: symbol.id,
          type: :buy,
          quantity: Decimal.new("50"),
          price: Decimal.new("220.50"),
          date: Date.utc_today(),
          total_amount: Decimal.new("11025.00")
        })

      # Create cash accounts - one included, one excluded
      {:ok, _checking} =
        Account.create(%{
          name: "Main Checking",
          account_type: :checking,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("8000.00"),
          is_excluded: false
        })

      {:ok, _escrow} =
        Account.create(%{
          name: "Escrow Account",
          account_type: :savings,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("3000.00"),
          is_excluded: true
        })

      # Calculate net worth - should only include non-excluded accounts
      {:ok, net_worth} = Context.get_net_worth(user.id)

      # Only main brokerage ($22,050) and checking ($8,000) should count
      assert Decimal.equal?(net_worth.investment_value, Decimal.new("22050.00"))
      assert Decimal.equal?(net_worth.cash_balance, Decimal.new("8000.00"))
      assert Decimal.equal?(net_worth.total_net_worth, Decimal.new("30050.00"))

      # Verify breakdown only counts non-excluded accounts
      assert net_worth.breakdown.investment_accounts == 1
      assert net_worth.breakdown.cash_accounts == 1
    end

    test "net worth calculation with zero balances", %{user: user} do
      # Create accounts with zero balances
      {:ok, _empty_checking} =
        Account.create(%{
          name: "Empty Checking",
          account_type: :checking,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("0")
        })

      {:ok, _empty_brokerage} =
        Account.create(%{
          name: "Empty Brokerage",
          account_type: :investment,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("0")
        })

      # Calculate net worth
      {:ok, net_worth} = Context.get_net_worth(user.id)

      # All values should be zero
      assert Decimal.equal?(net_worth.investment_value, Decimal.new("0"))
      assert Decimal.equal?(net_worth.cash_balance, Decimal.new("0"))
      assert Decimal.equal?(net_worth.total_net_worth, Decimal.new("0"))

      # Percentages should handle zero division gracefully
      assert Decimal.equal?(net_worth.breakdown.cash_percentage, Decimal.new("0"))
      assert Decimal.equal?(net_worth.breakdown.investment_percentage, Decimal.new("0"))

      # Counts should still be accurate
      assert net_worth.breakdown.cash_accounts == 1
      assert net_worth.breakdown.investment_accounts == 1
    end
  end

  describe "net worth calculation performance and optimization" do
    setup do
      {:ok, user} =
        User.create(%{
          name: "Performance Test User",
          currency: "USD",
          locale: "en-US"
        })

      {:ok, user: user}
    end

    test "net worth calculation performance with multiple accounts", %{user: user} do
      # Create multiple accounts to test performance
      _accounts =
        for i <- 1..10 do
          balance = Decimal.mult(Decimal.new(i), Decimal.new("1000"))
          account_type = if rem(i, 2) == 0, do: :checking, else: :savings

          {:ok, account} =
            Account.create(%{
              name: "Account #{i}",
              account_type: account_type,
              currency: "USD",
              user_id: user.id,
              balance: balance
            })

          account
        end

      # Measure calculation time
      start_time = System.monotonic_time()
      {:ok, net_worth} = Context.get_net_worth(user.id)
      end_time = System.monotonic_time()

      duration_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

      # Verify calculation is correct
      # Sum of 1000 + 2000 + ... + 10000
      expected_total = Decimal.new("55000.00")
      assert Decimal.equal?(net_worth.cash_balance, expected_total)
      assert net_worth.breakdown.cash_accounts == 10

      # Performance should be under 100ms for 10 accounts
      assert duration_ms < 100, "Net worth calculation took #{duration_ms}ms, expected < 100ms"
    end

    test "Context API vs direct calculator performance comparison", %{user: user} do
      # Create test accounts
      {:ok, _checking} =
        Account.create(%{
          name: "Performance Checking",
          account_type: :checking,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("5000.00")
        })

      # Measure Context API time
      context_start = System.monotonic_time()
      {:ok, context_result} = Context.get_net_worth(user.id)
      context_end = System.monotonic_time()

      context_duration =
        System.convert_time_unit(context_end - context_start, :native, :millisecond)

      # Measure direct calculator time
      calculator_start = System.monotonic_time()
      {:ok, calculator_result} = NetWorthCalculator.calculate_net_worth(user.id)
      calculator_end = System.monotonic_time()

      calculator_duration =
        System.convert_time_unit(calculator_end - calculator_start, :native, :millisecond)

      # Results should be equivalent
      assert Decimal.equal?(context_result.total_net_worth, calculator_result.net_worth)

      # Context API should have minimal overhead (< 50% additional time)
      overhead_factor = context_duration / max(calculator_duration, 1)
      assert overhead_factor < 1.5, "Context API overhead too high: #{overhead_factor}x"
    end
  end

  describe "net worth PubSub integration" do
    setup do
      {:ok, user} =
        User.create(%{
          name: "PubSub Test User",
          currency: "USD",
          locale: "en-US"
        })

      {:ok, user: user}
    end

    @tag :skip
    test "net worth updates broadcast via PubSub", %{user: user} do
      # TODO: PubSub functionality needs implementation
      # Subscribe to net worth updates
      topic = "net_worth_updates:#{user.id}"
      PubSub.subscribe(Ashfolio.PubSub, topic)

      # Create initial account
      {:ok, checking} =
        Account.create(%{
          name: "PubSub Checking",
          account_type: :checking,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("1000.00")
        })

      # Update balance which should trigger net worth recalculation and broadcast
      {:ok, _updated} =
        BalanceManager.update_cash_balance(
          checking.id,
          Decimal.new("2000.00"),
          "PubSub test update"
        )

      # Assert we receive net worth update notification
      assert_receive {:net_worth_updated, payload}, 5000

      assert payload.user_id == user.id
      assert Decimal.equal?(payload.total_net_worth, Decimal.new("2000.00"))
      assert Decimal.equal?(payload.cash_balance, Decimal.new("2000.00"))
      assert payload.breakdown.cash_accounts == 1
    end
  end
end
