# Ashfolio Testing Framework Documentation

## Overview

This document provides comprehensive guidance for testing the Ashfolio application, with special emphasis on SQLite concurrency handling and consistency patterns for AI agents working on the codebase.

## Project Status

- **Total Test Files**: 38 test files
- **Test Categories**: Unit tests, Integration tests, LiveView tests
- **SQLite Concurrency**: Advanced handling with retry patterns
- **Test Organization**: Structured with consistent patterns and helpers

## Test Suite Structure

### Core Test Categories

#### 1. Unit Tests (`test/ashfolio/`)

- **Ash Resources**: `user_test.exs`, `account_test.exs`, `symbol_test.exs`, `transaction_test.exs`
- **Business Logic**: `calculator_test.exs`, `holdings_calculator_test.exs`, `calculator_edge_cases_test.exs`
- **Market Data**: `yahoo_finance_test.exs`, `price_manager_test.exs`
- **Infrastructure**: `cache_test.exs`, `validation_test.exs`, `error_handler_test.exs`

#### 2. LiveView Tests (`test/ashfolio_web/live/`)

- **Dashboard**: `dashboard_live_test.exs`, `dashboard_pubsub_test.exs`
- **Account Management**: `account_live/index_test.exs`, `account_live/show_test.exs`, `account_live/form_component_test.exs`
- **Transaction Management**: `transaction_live/index_test.exs`
- **Helpers**: `format_helpers_test.exs`, `error_helpers_test.exs`

#### 3. Integration Tests (`test/integration/`)

- **Workflow Tests**: `account_management_flow_test.exs`, `transaction_flow_test.exs`
- **Performance**: `performance_benchmarks_test.exs`
- **Critical Points**: `critical_integration_points_test.exs`
- **PubSub Integration**: `transaction_pubsub_test.exs`

#### 4. Web Tests (`test/ashfolio_web/`)

- **Controllers**: `page_controller_test.exs`, `error_html_test.exs`, `error_json_test.exs`
- **Infrastructure**: `router_test.exs`, `accessibility_test.exs`, `responsive_design_test.exs`

### Special Test Categories

#### Edge Case Tests

- **File**: `test/ashfolio/portfolio/calculator_edge_cases_test.exs`
- **Purpose**: Comprehensive edge case testing for portfolio calculations
- **Coverage**: Zero values, extreme precision, complex transaction sequences, error handling
- **Integration**: Uses SQLiteHelpers patterns for robust database operations

#### Seeding Tests

- **File**: `test/ashfolio/seeding_test.exs`
- **Tag**: `@moduletag :seeding`
- **Exclusion**: Excluded by default in `test_helper.exs` with `exclude_tags: [:seeding]`
- **Purpose**: Tests database seeding functionality (slow, separated for performance)

## SQLite Concurrency Architecture

### Global Test Data Strategy

The project uses a **global test data approach** to eliminate SQLite concurrency issues:

```elixir
# test_helper.exs - Called ONCE before any tests
Ashfolio.SQLiteHelpers.setup_global_test_data!()
```

This creates:

- **Default User**: Created once, used by all tests
- **Default Account**: Created once, available globally
- **Common Symbols**: AAPL, MSFT, GOOGL, TSLA created once
- **Baseline Data**: All essential test data committed permanently

### SQLite Helpers Module

Location: `test/support/sqlite_helpers.ex`

#### Core Functions

```elixir
# Global Setup (called once from test_helper.exs)
setup_global_test_data!()

# Simple Getters (no concurrency issues)
get_default_user()
get_default_account(user \\ nil)
get_common_symbol(ticker)

# Custom Resource Creation (with retry logic)
get_or_create_account(user, attrs \\ %{})
get_or_create_symbol(ticker, attrs \\ %{})
create_test_transaction(user, account, symbol, attrs \\ %{})
```

#### Retry Logic Pattern

```elixir
def with_retry(fun, max_attempts \\ 3, delay_ms \\ 100) do
  # Handles SQLite "Database busy" errors
  # Uses exponential backoff with jitter
  # Covers both Ash.Error.Unknown and direct SQLite errors
end
```

### Database Sandbox Handling

Location: `test/support/data_case.ex`

```elixir
def setup_sandbox(_tags) do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ashfolio.Repo)
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.checkin(Ashfolio.Repo) end)
end
```

**Key Features**:

- Uses checkout/checkin pattern for SQLite
- No `allow/3` calls needed for single-threaded SQLite
- Global data created before sandbox mode starts

### PriceManager GenServer Testing

Special handling for GenServer database access:

```elixir
def allow_price_manager_db_access do
  price_manager_pid = Process.whereis(Ashfolio.MarketData.PriceManager)
  if price_manager_pid do
    Ecto.Adapters.SQL.Sandbox.allow(Ashfolio.Repo, self(), price_manager_pid)
    Mox.allow(YahooFinanceMock, self(), price_manager_pid)
  end
end
```

## Test Patterns and Conventions

### Standard Test Structure

#### Ash Resource Tests

```elixir
defmodule Ashfolio.Portfolio.UserTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.Portfolio.User

  describe "crud operations" do
    test "creates user successfully" do
      # Test implementation
    end
  end

  describe "validations" do
    test "validates required fields" do
      # Test implementation
    end
  end
end
```

#### LiveView Tests

```elixir
defmodule AshfolioWeb.DashboardLiveTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ashfolio.SQLiteHelpers

  setup do
    user = get_default_user()
    account = get_default_account(user)
    %{user: user, account: account}
  end

  describe "dashboard functionality" do
    test "renders dashboard", %{conn: conn} do
      # Test implementation
    end
  end
end
```

#### Integration Tests

```elixir
defmodule Ashfolio.Integration.AccountManagementFlowTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ashfolio.SQLiteHelpers

  describe "account management workflow" do
    test "complete account lifecycle", %{conn: conn} do
      # End-to-end test implementation
    end
  end
end
```

### Mocking Patterns

#### YahooFinance Mocking

```elixir
# In test_helper.exs
Mox.defmock(Ashfolio.Test.Support.YahooFinanceMock, for: Ashfolio.MarketData.YahooFinanceBehaviour)

# In individual tests
setup do
  # Mock Yahoo Finance responses
  expect(YahooFinanceMock, :fetch_price, fn _symbol ->
    {:ok, %{price: Decimal.new("150.00"), timestamp: DateTime.utc_now()}}
  end)
  :ok
end
```

### Data Creation Patterns

#### Using Global Data (Preferred)

```elixir
test "portfolio calculation with default data" do
  user = get_default_user()
  account = get_default_account(user)
  symbol = get_common_symbol("AAPL")

  # Use existing data - no creation needed
end
```

#### Creating Custom Data (When Needed)

```elixir
test "custom account scenarios" do
  user = get_default_user()

  # Custom account with retry logic
  account = get_or_create_account(user, %{
    name: "Custom Account",
    balance: Decimal.new("25000.00")
  })

  # Custom symbol with price
  symbol = get_or_create_symbol("NVDA", %{
    current_price: Decimal.new("800.00")
  })

  # Custom transaction
  transaction = create_test_transaction(user, account, symbol, %{
    type: :sell,
    quantity: Decimal.new("5")
  })
end
```

## Running Tests - Modular Strategy

### Basic Just Commands

```bash
# Main test suite (excludes seeding tests)
just test

# Specific test file
just test-file test/ashfolio/portfolio/user_test.exs

# Verbose output
just test-verbose

# Coverage analysis
just test-coverage

# Watch mode
just test-watch

# Failed tests only
just test-failed

# Seeding tests only
just test-seeding

# Full suite including seeding
just test-all
```

### Architectural Layer Testing (NEW)

```bash
# Business logic layer
just test-ash                    # Ash Resources (User, Account, Symbol, Transaction)
just test-ash-verbose            # With detailed output

# UI layer
just test-liveview              # Phoenix LiveView components
just test-liveview-verbose      # With detailed output
just test-ui                    # User interface and accessibility

# Calculation engine
just test-calculations          # Portfolio math and FIFO calculations
just test-calculations-verbose  # With detailed output

# Market data system
just test-market-data           # Price fetching and Yahoo Finance
just test-market-data-verbose   # With detailed output

# Integration workflows
just test-integration           # End-to-end workflows
just test-integration-verbose   # With detailed output
```

### Performance-Based Testing (NEW)

```bash
# Development workflow optimization
just test-fast                  # Quick tests for rapid feedback (< 100ms)
just test-fast-verbose          # With detailed output

# Test scope categories
just test-unit                  # Isolated unit tests
just test-unit-verbose          # With detailed output
just test-slow                  # Slower comprehensive tests
just test-slow-verbose          # With detailed output

# Dependency-based testing
just test-external              # Tests requiring external APIs
just test-external-verbose      # With detailed output
just test-mocked                # Tests using Mox for external services
just test-mocked-verbose        # With detailed output
```

### Development Workflow Testing (NEW)

```bash
# Essential testing
just test-smoke                 # Critical tests that must pass
just test-smoke-verbose         # With detailed output

# Quality assurance
just test-regression            # Tests for previously fixed bugs
just test-regression-verbose    # With detailed output
just test-edge-cases            # Boundary conditions and unusual scenarios
just test-edge-cases-verbose    # With detailed output
just test-error-handling        # Error conditions and fault tolerance
just test-error-handling-verbose # With detailed output
```

### Advanced Filter Usage

```bash
# Combine multiple filters
mix test --only unit --only fast           # Fast unit tests only
mix test --include slow --include external # Include slower external tests
mix test --exclude external_deps           # Exclude external dependencies

# Filter by architectural layer
mix test --only ash_resources              # Only Ash Resource tests
mix test --only liveview --only ui         # Only UI-related tests

# Development workflow combinations
mix test --only smoke --only fast          # Essential fast tests
mix test --only regression --include slow  # All regression tests including slow ones
```

### Test Configuration

Location: `test_helper.exs`

```elixir
ExUnit.configure(
  trace: System.get_env("CI") == "true",
  capture_log: true,
  colors: [enabled: true],
  timeout: 120_000,
  exclude_tags: [:seeding],
  formatters: [ExUnit.CLIFormatter]
)
```

## AI Agent Guidelines

### For AI Agents Working on Tests

#### 1. Always Use Global Data First

```elixir
# ✅ CORRECT - Use global data when possible
user = get_default_user()
account = get_default_account(user)
symbol = get_common_symbol("AAPL")

# ❌ AVOID - Creating unnecessary data
{:ok, user} = User.create(%{name: "Test User"})
```

#### 1.5. Handle Global Data Conflicts Properly

```elixir
# ✅ CORRECT - Use unique identifiers for test resources
unique_symbol = "TEST#{System.unique_integer([:positive])}"
{:ok, symbol} = Symbol.create(%{symbol: unique_symbol, ...})

# ✅ CORRECT - Assert membership, not exact counts
{:ok, accounts} = Account.list()
account_ids = Enum.map(accounts, & &1.id)
assert test_account.id in account_ids

# ❌ AVOID - Hardcoded symbols that conflict with global data
{:ok, symbol} = Symbol.create(%{symbol: "AAPL", ...})  # Conflicts with global AAPL

# ❌ AVOID - Expecting database isolation
assert length(accounts) == 1  # Fails when global accounts exist
assert Enum.empty?(accounts)  # Fails when global accounts exist
```

#### 2. Understand SQLite Limitations

- **No Async Tests**: Always use `async: false`
- **Use Retry Logic**: When creating custom resources
- **Leverage Global Data**: Minimizes concurrency conflicts

#### 3. Test File Patterns

```elixir
# Required module structure
defmodule MyTest do
  use Ashfolio.DataCase, async: false  # Always async: false

  import Ashfolio.SQLiteHelpers  # Access to helper functions

  # Use describe blocks for organization
  describe "feature group" do
    test "specific behavior" do
      # Implementation
    end
  end
end
```

#### 4. Debugging Failed Tests

```bash
# 1. Run specific failing test with verbose output
just test-file-verbose test/path/to/failing_test.exs

# 2. Check for SQLite concurrency issues in output
# Look for: "Database busy", "database is locked"

# 3. Run failed tests only
just test-failed

# 4. Check compilation
just compile
```

#### 5. Common Pitfalls

- **Don't use `async: true`** - SQLite doesn't support it well
- **Don't create duplicate users** - Use global user
- **Don't ignore retry logic** - Use `with_retry/1` for custom resources
- **Don't mock unnecessarily** - Use real data when possible
- **Don't expect database isolation** - Global data persists across tests
- **Don't use hardcoded symbols** - AAPL, MSFT, GOOGL, TSLA exist globally
- **Don't assert exact counts** - Use membership checks instead

### Creating New Tests

#### Step 1: Determine Test Type

- **Unit Test**: Single module/function
- **Integration Test**: Multiple modules/workflows
- **LiveView Test**: UI interactions
- **Flow Test**: End-to-end scenarios

#### Step 2: Use Appropriate Template

```elixir
# Unit Test Template
defmodule Ashfolio.MyModuleTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.MyModule
  import Ashfolio.SQLiteHelpers

  describe "function_group" do
    test "specific_behavior" do
      # Test implementation
    end
  end
end

# LiveView Test Template
defmodule AshfolioWeb.MyLiveTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ashfolio.SQLiteHelpers

  setup do
    user = get_default_user()
    %{user: user}
  end

  describe "liveview_feature" do
    test "interaction", %{conn: conn, user: user} do
      # LiveView test implementation
    end
  end
end
```

#### Step 3: Follow Data Patterns

1. **Use global data** when possible
2. **Create custom data** only when needed
3. **Use retry helpers** for custom resources
4. **Clean up** is handled automatically by sandbox

## Troubleshooting

### Common Issues

#### "Database busy" Errors

```elixir
# Solution: Use retry logic
user = with_retry(fn ->
  case User.create(params) do
    {:ok, user} -> user
    {:error, error} -> raise "Failed: #{inspect(error)}"
  end
end)
```

#### Test Timeouts

- Increase timeout in `test_helper.exs`: `timeout: 120_000`
- Check for infinite loops or database locks
- Use `--trace` flag to identify slow tests

#### Missing Test Data

```elixir
# Ensure global setup was called
# Check test_helper.exs has:
Ashfolio.SQLiteHelpers.setup_global_test_data!()

# Verify data exists
user = get_default_user()  # Should not raise
```

#### PriceManager Tests Failing

```elixir
# Add to test setup
setup do
  allow_price_manager_db_access()
  :ok
end
```

### Performance Optimization

#### Fast Test Execution

1. **Use global data** (no creation overhead)
2. **Exclude seeding tests** by default
3. **Run specific files** during development
4. **Use silent commands** for quick feedback

#### Coverage Analysis

```bash
# Quick coverage check
just test-coverage-summary

# Full coverage report
just test-coverage
```

## Best Practices Summary

### ✅ DO

- Use `async: false` for all SQLite tests
- Leverage global test data whenever possible
- Use retry logic for custom resource creation
- Follow consistent describe/test structure
- Use appropriate helpers from SQLiteHelpers
- Test both success and error cases
- Use descriptive test names
- Group related tests in describe blocks

### ❌ DON'T

- Use `async: true` with SQLite
- Create unnecessary duplicate test data
- Ignore concurrency error handling
- Mix test concerns (unit vs integration)
- Skip error scenario testing
- Use hard-coded timing in tests
- Create tests without cleanup (handled by sandbox)

This framework ensures consistent, reliable testing patterns while handling SQLite's unique concurrency challenges effectively.
