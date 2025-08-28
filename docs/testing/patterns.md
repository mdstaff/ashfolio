# SQLite Concurrency Testing Patterns

## Overview

This document provides detailed patterns and solutions for handling SQLite concurrency challenges in the Ashfolio test suite. SQLite has unique limitations compared to PostgreSQL that require specific handling strategies.

## SQLite Concurrency Challenges

### Core Limitations

1.  Only one process can write to SQLite at a time
2.  Multiple processes competing for database access cause "Database busy" errors
3.  Unlike PostgreSQL, SQLite can't handle multiple simultaneous transactions
4.  GenServers running in separate processes need special database access permissions

### Common Error Patterns

```
 (Ash.Error.Unknown) %Sqlite.DbConnection.Error{
  message: "database is locked",
  sqlite: %{extended_code: 5, code: :busy}
}

 (MatchError) no match of right hand side value:
{:error, %{message: "Database busy"}}
```

## Ashfolio's Solution Architecture

### 1. Global Test Data Strategy

Creating users/accounts in each test causes concurrency conflicts.

Pre-create all common test data once before any tests run.

```elixir
# test_helper.exs - Called ONCE before test suite starts
Ashfolio.SQLiteHelpers.setup_global_test_data!()

# This creates:
# - Default User (ID: consistent across test runs)
# - Default Account (linked to default user)
# - Common Symbols (AAPL, MSFT, GOOGL, TSLA)
# - All committed to database permanently
```

- Eliminates user creation race conditions
- Provides consistent test data across all tests
- Reduces test execution time
- Minimizes database write operations

### 2. Retry Logic with Exponential Backoff

Occasional "Database busy" errors for custom resource creation.

Retry pattern with intelligent backoff.

```elixir
def with_retry(fun, max_attempts \\ 3, delay_ms \\ 100) do
  do_with_retry(fun, max_attempts, delay_ms, 1)
end

defp do_with_retry(fun, max_attempts, delay_ms, attempt) do
  try do
    fun.()
  rescue
    error ->
      if sqlite_busy_error?(error) and attempt < max_attempts do
        # Exponential backoff with jitter to prevent thundering herd
        sleep_time = delay_ms * attempt + :rand.uniform(50)
        Process.sleep(sleep_time)
        do_with_retry(fun, max_attempts, delay_ms, attempt + 1)
      else
        reraise error, __STACKTRACE__
      end
  end
end

# Detects SQLite-specific busy errors
defp sqlite_busy_error?(%Ash.Error.Unknown{}), do: true
defp sqlite_busy_error?(error) do
  error_string = inspect(error)
  String.contains?(error_string, "Database busy") or
  String.contains?(error_string, "database is locked")
end
```

```elixir
# Creating custom account with retry protection
account = with_retry(fn ->
  case Account.create(params, actor: user) do
    {:ok, account} -> account
    {:error, error} -> raise "Failed to create account: #{inspect(error)}"
  end
end)
```

### 3. Sandbox Management

SQLite sandbox mode needs careful management.

Dedicated DataCase with proper checkout/checkin.

```elixir
# test/support/data_case.ex
def setup_sandbox(_tags) do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ashfolio.Repo)
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.checkin(Ashfolio.Repo) end)
end
```

- No `Sandbox.mode/2` calls needed
- No `allow/3` for most tests (single-threaded)
- Checkout/checkin pattern works reliably

### 4. GenServer Database Access

PriceManager GenServer can't access test database.

Explicit permission granting.

```elixir
def allow_price_manager_db_access do
  try do
    price_manager_pid = Process.whereis(Ashfolio.MarketData.PriceManager)

    if price_manager_pid do
      # Allow GenServer to access test database
      Ecto.Adapters.SQL.Sandbox.allow(Ashfolio.Repo, self(), price_manager_pid)

      # Allow GenServer to use Mox expectations
      Mox.allow(YahooFinanceMock, self(), price_manager_pid)
    end
  rescue
    _ -> :ok  # Graceful failure if GenServer not running
  end
end
```

- Tests that trigger PriceManager.refresh_prices/1
- Integration tests involving price fetching
- Any test that indirectly calls GenServer functions

## Implementation Patterns

### Pattern 1: Global Data First

```elixir
#  PREFERRED - Use pre-created global data
test "portfolio calculation" do
             # No database write
  account = get_default_account() # No database write
  symbol = get_common_symbol("AAPL")  # No database write

  # Test logic using existing data
end

# ❌ AVOID - Creating data in each test
test "portfolio calculation" do
  {:ok, symbol} = Symbol.create(%{symbol: "AAPL"})     # Database write

  # Risk of concurrency conflicts
end
```

### Pattern 2: Custom Resources with Retry

```elixir
#  CORRECT - Custom data with retry protection
test "special account scenario" do


  # Custom account with specific attributes
  account = get_or_create_account(%{
    name: "High Balance Account",
    balance: Decimal.new("100000.00")
  })  # Uses with_retry/1 internally

  # Custom symbol with specific price
  symbol = get_or_create_symbol("NVDA", %{
    current_price: Decimal.new("800.00")
  })  # Uses with_retry/1 internally

  # Test with custom data
end

# ❌ AVOID - Direct creation without retry
test "special account scenario" do


  {:ok, account} = Account.create(%{
    name: "High Balance Account",
    balance: Decimal.new("100000.00")
  })  # May fail with "Database busy"
end
```

### Pattern 3: Transaction Creation

```elixir
#  PREFERRED - Using helper with retry logic
test "transaction scenarios" do

  account = get_default_account()
  symbol = get_common_symbol("AAPL")

  # Create buy transaction
  buy_tx = create_test_transaction(user, account, symbol, %{
    type: :buy,
    quantity: Decimal.new("10"),
    price: Decimal.new("150.00")
  })

  # Create sell transaction
  sell_tx = create_test_transaction(user, account, symbol, %{
    type: :sell,
    quantity: Decimal.new("5"),
    price: Decimal.new("160.00")
  })

  # Test portfolio calculations
end
```

### Pattern 4: PriceManager Integration Tests

```elixir
defmodule PriceManagerIntegrationTest do
  use Ashfolio.DataCase, async: false

  import Ashfolio.SQLiteHelpers

  setup do
    # Critical: Allow GenServer database access
    allow_price_manager_db_access()

    # Mock Yahoo Finance responses
    expect(YahooFinanceMock, :fetch_price, fn symbol ->
      {:ok, %{price: Decimal.new("150.00"), timestamp: DateTime.utc_now()}}
    end)

    :ok
  end

  test "price refresh updates symbols" do
    # Test can now call PriceManager functions that write to database
    result = Ashfolio.MarketData.PriceManager.refresh_prices()
    assert {:ok, _updated_symbols} = result
  end
end
```

## Test Organization Strategies

### Strategy 1: Async False Always

```elixir
#  REQUIRED for SQLite
defmodule MyTest do
  use Ashfolio.DataCase, async: false  # Always false

  # Test implementation
end
```

- SQLite can't handle concurrent database access
- Tests running in parallel cause lock contention
- Even read-only tests may conflict with cleanup operations

### Strategy 2: Describe Block Organization

```elixir
defmodule AccountTest do
  use Ashfolio.DataCase, async: false

  import Ashfolio.SQLiteHelpers

  describe "crud operations" do
    test "creates account with valid data" do


      account = get_or_create_account(%{
        name: "Test Account",
        balance: Decimal.new("5000.00")
      })

      assert account.name == "Test Account"
    end

    test "updates account balance" do
      # Test implementation
    end
  end

  describe "validations" do
    test "requires name" do
      # Test implementation
    end
  end

  describe "relationships" do
    test "belongs to user" do
      # Test implementation
    end
  end
end
```

### Strategy 3: Setup Block Patterns

```elixir
#  LIGHTWEIGHT - For tests using global data only
setup do

  account = get_default_account()
  %{ account: account}
end

#  CUSTOM DATA - For tests needing special resources
setup do


  special_account = get_or_create_account(%{
    name: "Special Account",
    balance: Decimal.new("25000.00")
  })

  %{ special_account: special_account}
end

#  GENSERVER TESTS - For PriceManager integration
setup do
  allow_price_manager_db_access()

  expect(YahooFinanceMock, :fetch_price, fn _symbol ->
    {:ok, %{price: Decimal.new("100.00"), timestamp: DateTime.utc_now()}}
  end)

  :ok
end
```

## Error Recovery Patterns

### Pattern 1: Graceful Degradation

```elixir
def get_or_create_symbol(ticker, attrs \\ %{}) do
  with_retry(fn ->
    case Symbol.find_by_symbol(ticker) do
      {:ok, [symbol]} ->
        # Update price if provided
        if attrs[:current_price] do
          update_symbol_price(symbol, attrs[:current_price])
        else
          symbol
        end
      {:ok, []} ->
        create_new_symbol(ticker, attrs)
      {:error, error} ->
        raise "Failed to query symbol #{ticker}: #{inspect(error)}"
    end
  end)
end

defp update_symbol_price(symbol, price) do
  case Symbol.update_price(symbol, %{
    current_price: price,
    price_updated_at: DateTime.utc_now()
  }) do
    {:ok, updated_symbol} -> updated_symbol
    {:error, error} ->
      # Graceful degradation - return original symbol
      Logger.warn("Failed to update symbol price: #{inspect(error)}")
      symbol
  end
end
```

### Pattern 2: Circuit Breaker

```elixir
defmodule SQLiteCircuitBreaker do
  @max_consecutive_failures 5
  @reset_timeout_ms 30_000

  def call_with_circuit_breaker(fun) do
    case get_circuit_state() do
      :closed -> try_operation(fun)
      :open -> {:error, :circuit_open}
      :half_open -> try_reset(fun)
    end
  end

  defp try_operation(fun) do
    try do
      result = fun.()
      reset_failure_count()
      result
    rescue
      error ->
        if sqlite_busy_error?(error) do
          increment_failure_count()
          {:error, :database_busy}
        else
          reraise error, __STACKTRACE__
        end
    end
  end

  # Implementation details...
end
```

## Performance Optimization

### Optimization 1: Batch Operations

```elixir
#  EFFICIENT - Batch multiple related operations
def create_portfolio_scenario do
  with_retry(fn ->


    # Create multiple accounts in single transaction
    Repo.transaction(fn ->
      Enum.map(["Account A", "Account B", "Account C"], fn name ->
        params = %{name: name, balance: Decimal.new("5000.00")}
        case Account.create(params, actor: user) do
          {:ok, account} -> account
          {:error, error} -> raise "Failed to create #{name}: #{inspect(error)}"
        end
      end)
    end)
  end)
end

# ❌ INEFFICIENT - Multiple separate database operations
def create_portfolio_scenario do


  account_a = get_or_create_account(%{name: "Account A"})
  account_b = get_or_create_account(%{name: "Account B"})
  account_c = get_or_create_account(%{name: "Account C"})

  [account_a, account_b, account_c]
end
```

### Optimization 2: Smart Caching

```elixir
defmodule TestDataCache do
  @cache_table :test_data_cache

  def get_or_create_cached_symbol(ticker) do
    case :ets.lookup(@cache_table, {:symbol, ticker}) do
      [{_, symbol}] ->
        symbol
      [] ->
        symbol = get_or_create_symbol(ticker)
        :ets.insert(@cache_table, {{:symbol, ticker}, symbol})
        symbol
    end
  end

  def setup_cache do
    :ets.new(@cache_table, [:set, :public, :named_table])
  end

  def clear_cache do
    :ets.delete_all_objects(@cache_table)
  end
end
```

## Debugging SQLite Issues

### Debug Pattern 1: Enhanced Logging

```elixir
def debug_with_retry(fun, context \\ "operation") do
  Logger.info("Starting #{context}")

  try do
    result = with_retry(fun)
    Logger.info("Completed #{context} successfully")
    result
  rescue
    error ->
      Logger.error("Failed #{context} after retries: #{inspect(error)}")
      reraise error, __STACKTRACE__
  end
end
```

### Debug Pattern 2: Database State Inspection

```elixir
def inspect_database_state do
  Repo.transaction(fn ->
    users = Repo.aggregate(User, :count)
    accounts = Repo.aggregate(Account, :count)
    symbols = Repo.aggregate(Symbol, :count)
    transactions = Repo.aggregate(Transaction, :count)

    Logger.info("Database state - Users: #{users}, Accounts: #{accounts}, Symbols: #{symbols}, Transactions: #{transactions}")
  end)
end
```

### Debug Pattern 3: Lock Detection

```elixir
def detect_database_locks do
  case Repo.query("PRAGMA locking_mode;") do
    {:ok, result} ->
      Logger.info("Locking mode: #{inspect(result)}")
    {:error, error} ->
      Logger.error("Failed to check locking mode: #{inspect(error)}")
  end

  case Repo.query("PRAGMA journal_mode;") do
    {:ok, result} ->
      Logger.info("Journal mode: #{inspect(result)}")
    {:error, error} ->
      Logger.error("Failed to check journal mode: #{inspect(error)}")
  end
end
```

## Migration from PostgreSQL Patterns

### Common PostgreSQL -> SQLite Changes

```elixir
# PostgreSQL Pattern (DON'T USE)
defmodule MyTest do
  use MyApp.DataCase, async: true  # async: true works in PostgreSQL

  setup do
    Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)  # auto mode for PostgreSQL
    :ok
  end
end

# SQLite Pattern (CORRECT)
defmodule MyTest do
  use Ashfolio.DataCase, async: false  # async: false required for SQLite

  import Ashfolio.SQLiteHelpers  # Use specialized helpers

  # No setup needed - DataCase handles sandbox automatically
end
```

### Concurrency Model Differences

| Aspect           | PostgreSQL                 | SQLite                       |
| ---------------- | -------------------------- | ---------------------------- |
| Concurrent Tests | `async: true` supported    | `async: false` required      |
| Sandbox Mode     | `:auto` or `:manual`       | Checkout/checkin only        |
| Transactions     | Full ACID with concurrency | Single writer limitation     |
| GenServer Access | `allow/3` commonly needed  | `allow/3` for specific cases |
| Error Recovery   | Connection pooling helps   | Retry logic essential        |

## Summary

SQLite concurrency in tests requires:

1. Global test data strategy to minimize writes
2. Retry logic with exponential backoff for custom resources
3. Proper sandbox management with checkout/checkin
4. GenServer permission handling for cross-process access
5. Always async: false for all test modules
6. Smart use of helpers from SQLiteHelpers module

This approach provides reliable, fast test execution while working within SQLite's limitations.
