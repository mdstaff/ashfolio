# Test Data Implementation Patterns

## Overview

This document provides concrete implementation patterns based on the architectural guidance from our project architect and technical writing standards. These patterns implement the requirements defined in [Global Test Data Requirements](./global-test-data-requirements.md).

## Infrastructure vs State Separation

### Test Infrastructure Pattern

_(Global, Immutable, Performance-Optimized)_

```elixir
# /test/support/test_infrastructure.ex
defmodule Ashfolio.TestInfrastructure do
  @moduledoc """
  Global test infrastructure that provides shared, immutable reference data.

  Database-as-user architecture: Creates baseline infrastructure without user_id dependencies.
  """

  def setup_global_infrastructure! do
    create_market_symbols!()      # Immutable reference data
    create_transaction_categories!() # Hierarchical categories
    create_test_user_settings!()  # Database-as-user singleton

    # Note: NO accounts or transactions created globally
    validate_infrastructure!()
  end

  defp create_market_symbols! do
    # Create symbols with prices but no holdings
    symbols = [
      {"AAPL", "Apple Inc.", "150.00"},
      {"GOOGL", "Alphabet Inc.", "2500.00"},
      {"MSFT", "Microsoft Corp.", "300.00"},
      {"TSLA", "Tesla Inc.", "200.00"}
    ]

    Enum.each(symbols, fn {ticker, name, price} ->
      Symbol.get_or_create!(ticker, %{
        name: name,
        current_price: Decimal.new(price),
        asset_class: :stock,
        data_source: :manual
      })
    end)
  end

  defp validate_infrastructure! do
    # Ensure global state is as expected
    symbols = Symbol.read!()
    assert length(symbols) >= 4, "Missing required test symbols"

    categories = TransactionCategory.read!()
    assert length(categories) > 0, "Missing transaction categories"

    IO.puts(" Test infrastructure validated: #{length(symbols)} symbols, #{length(categories)} categories")
  end
end
```

### Per-Test Account Management Pattern

_(Isolated, Clean, Predictable)_

```elixir
# /test/support/test_accounts.ex
defmodule Ashfolio.TestAccounts do
  @moduledoc """
  Per-test account management with automatic cleanup.

  Database-as-user architecture: Accounts exist without user_id references.
  """

  def create_test_account(attrs \\ %{}) do
    default_attrs = %{
      name: "Test Account #{System.unique_integer([:positive])}",
      balance: Decimal.new("0.00"),  # Always start with zero
      account_type: :investment,
      platform: "Test Platform"
    }

    attrs = Map.merge(default_attrs, attrs)
    {:ok, account} = Account.create(attrs)

    # Register for cleanup
    ExUnit.Callbacks.on_exit(fn ->
      Account.destroy(account)
    end)

    account
  end

  def create_cash_account(balance, type \\ :checking) do
    create_test_account(%{
      account_type: type,
      balance: Decimal.new(to_string(balance))
    })
  end

  def create_investment_account do
    create_test_account(%{
      account_type: :investment,
      balance: Decimal.new("0.00")  # Investment value from transactions only
    })
  end

  def reset_global_account_balances! do
    Account.read!()
    |> Enum.each(fn account ->
      Account.update!(account, %{balance: Decimal.new("0")})
    end)
  end
end
```

## Test Category Patterns

### Unit Tests: Pure, Fast, No Database

```elixir
defmodule Ashfolio.Portfolio.HoldingsCalculatorTest do
  use ExUnit.Case  # No DataCase needed

  @moduletag :unit
  @moduletag :fast

  # Test pure calculations with constructed data
  test "FIFO cost basis calculation" do
    transactions = [
      build_transaction(:buy, 10, "100.00"),
      build_transaction(:sell, 5, "150.00")
    ]

    result = HoldingsCalculator.calculate_cost_basis(transactions)
    assert result.realized_gain == Decimal.new("250.00")
  end

  defp build_transaction(type, quantity, price) do
    # Create struct without database dependency
    %Transaction{
      type: type,
      quantity: Decimal.new(to_string(quantity)),
      price: Decimal.new(price),
      date: ~D[2024-01-15]
    }
  end
end
```

### Integration Tests: Database, Isolated, Realistic

```elixir
defmodule Ashfolio.FinancialManagement.NetWorthCalculatorTest do
  use Ashfolio.DataCase, async: false

  @moduletag :integration

  import Ashfolio.TestAccounts

  setup do
    # Reset any global state to zero
    reset_global_account_balances!()
    :ok
  end

  test "net worth calculation with mixed account types" do
    # Create test-specific accounts
    investment_account = create_investment_account()
    checking_account = create_cash_account(2500, :checking)
    savings_account = create_cash_account(10000, :savings)

    # Create investment position using global symbol
    symbol = Symbol.get!("AAPL")
    create_buy_transaction(investment_account, symbol, 10, "150.00")

    # Calculate net worth
    {:ok, result} = NetWorthCalculator.calculate_current_net_worth()

    assert result.investment_value == Decimal.new("1500.00")  # 10 * $150
    assert result.cash_value == Decimal.new("12500.00")       # $2,500 + $10,000
    assert result.net_worth == Decimal.new("14000.00")
  end

  defp create_buy_transaction(account, symbol, quantity, price) do
    Transaction.create(%{
      type: :buy,
      symbol_id: symbol.id,
      account_id: account.id,
      quantity: Decimal.new(to_string(quantity)),
      price: Decimal.new(price),
      total_amount: Decimal.mult(Decimal.new(to_string(quantity)), Decimal.new(price)),
      date: Date.utc_today()
    })
  end
end
```

### Performance Tests: Large Scale, Measured

```elixir
defmodule Ashfolio.Performance.NetWorthCalculationPerformanceTest do
  use Ashfolio.DataCase, async: false

  @moduletag :performance
  @moduletag :slow

  import Ashfolio.TestAccounts

  test "net worth calculation scales linearly with account count" do
    # Create many accounts to test performance
    accounts = for i <- 1..100 do
      create_cash_account(1000 + i, :checking)
    end

    # Measure calculation time
    {time_microseconds, {:ok, result}} = :timer.tc(fn ->
      NetWorthCalculator.calculate_current_net_worth()
    end)

    time_milliseconds = time_microseconds / 1000

    # Performance assertions
    assert time_milliseconds < 100, "Calculation took #{time_milliseconds}ms, expected < 100ms"
    assert Decimal.compare(result.cash_value, Decimal.new("105050")) == :eq  # Sum of 1001..1100

    IO.puts(" Performance: #{length(accounts)} accounts calculated in #{time_milliseconds}ms")
  end
end
```

## Financial Domain Test Scenarios

### Complex Portfolio Scenario

```elixir
# /test/support/test_scenarios.ex
defmodule Ashfolio.TestScenarios do
  @moduledoc """
  Pre-built test scenarios for complex v0.3.0+ features.
  """

  import Ashfolio.TestAccounts

  def retirement_portfolio_scenario do
    # Create diversified portfolio
    accounts = %{
      retirement_401k: create_retirement_account(:traditional_401k, 150000),
      roth_ira: create_retirement_account(:roth_ira, 75000),
      taxable: create_investment_account(),
      emergency_fund: create_cash_account(25000, :savings)
    }

    # Add investment positions
    add_diversified_holdings(accounts.taxable)
    add_retirement_holdings(accounts.retirement_401k)

    %{
      accounts: accounts,
      total_value: calculate_total_portfolio_value(accounts),
      allocation: calculate_asset_allocation(accounts)
    }
  end

  def expense_tracking_scenario do
    # Create monthly expense pattern
    categories = %{
      housing: get_category("Housing"),
      food: get_category("Food"),
      transportation: get_category("Transportation"),
      utilities: get_category("Utilities")
    }

    expenses = create_monthly_expenses(categories)

    %{
      categories: categories,
      monthly_total: calculate_monthly_total(expenses),
      annual_projection: calculate_annual_projection(expenses)
    }
  end

  defp create_retirement_account(type, balance) do
    create_test_account(%{
      account_type: :investment,
      sub_type: type,
      balance: Decimal.new(to_string(balance)),
      platform: "Retirement Provider"
    })
  end
end
```

## SQLite-Specific Patterns

### Transaction Management

```elixir
# Use transactions for multi-step test setup
test "complex portfolio calculation maintains consistency" do
  result = Ashfolio.Repo.transaction(fn ->
    # All operations in single transaction for performance
    account = create_test_account()
    transactions = create_transaction_history(account, 100)

    # Calculations are consistent within transaction
    portfolio_value = calculate_portfolio_performance(account)

    assert portfolio_value.success
    portfolio_value
  end)

  assert {:ok, _portfolio} = result
end
```

### Retry Pattern for Concurrency

```elixir
defp create_test_data_with_retry(attempts \\ 3) do
  try do
    create_test_accounts()
  rescue
    Ecto.ConstraintError ->
      if attempts > 1 do
        Process.sleep(10)  # Brief delay
        create_test_data_with_retry(attempts - 1)
      else
        reraise
      end
  end
end
```

## Success Validation

### Test Health Checks

```elixir
# Add to test_helper.exs
defmodule TestHealthCheck do
  def validate_test_environment! do
    # Verify global infrastructure
    symbols = Symbol.read!()
    assert length(symbols) >= 4, "Missing required test symbols"

    # Verify SQLite performance
    {time, _} = :timer.tc(fn -> Account.read!() end)
    assert time < 50_000, "Database queries too slow: #{time}μs"

    # Verify clean state
    accounts_with_balance = Account.read!()
    |> Enum.filter(&(Decimal.compare(&1.balance, Decimal.new("0")) != :eq))

    if length(accounts_with_balance) > 0 do
      IO.warn("Found accounts with non-zero balances: #{inspect(accounts_with_balance)}")
    end

    IO.puts(" Test environment validated")
  end
end

# Run health check before tests
TestHealthCheck.validate_test_environment!()
```

## Documentation Maintenance

### Regular Reviews

1.  Update test scenarios
2.  Review global infrastructure
3.  Check SQLite patterns
4.  Validate all patterns still work

### Success Metrics

- Zero test failures from global data interference
- Consistent test execution times (< 2s for full suite)
- Clear separation between unit/integration/performance tests
- Easy onboarding for new developers and AI agents

This implementation guide provides concrete patterns that align with Ashfolio's database-as-user architecture while ensuring reliable, maintainable tests through v1.0 and beyond.
