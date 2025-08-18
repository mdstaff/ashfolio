# Test Consistency Standards for Ashfolio

## Overview

This document establishes consistency standards across all test files in the Ashfolio project. These standards ensure maintainability, readability, and reliability for both human developers and AI agents working on the codebase.

## File Organization Standards

### Directory Structure

```
test/
├── ashfolio/                          # Unit tests for business logic
│   ├── portfolio/                     # Ash resources (User, Account, Symbol, Transaction)
│   ├── market_data/                   # Market data and pricing (YahooFinance, PriceManager)
│   └── *.exs                         # Infrastructure (cache, validation, error handling)
├── ashfolio_web/                      # Web layer tests
│   ├── live/                         # LiveView tests (dashboard, forms, components)
│   ├── controllers/                  # Controller tests (minimal, mostly errors)
│   └── *.exs                        # Web infrastructure (routing, accessibility)
├── integration/                      # End-to-end workflow tests
├── support/                          # Test helpers and utilities
└── test_helper.exs                   # Global test configuration
```

### File Naming Conventions

| Test Type        | Pattern                  | Example                                            |
| ---------------- | ------------------------ | -------------------------------------------------- |
| Unit Test        | `module_name_test.exs`   | `user_test.exs`, `calculator_test.exs`             |
| LiveView Test    | `live_module_test.exs`   | `dashboard_live_test.exs`, `account_live_test.exs` |
| Integration Test | `workflow_name_test.exs` | `account_management_flow_test.exs`                 |
| Helper Module    | `helper_name.ex`         | `sqlite_helpers.ex`, `yahoo_finance_mock.ex`       |

## Module Structure Standards

### Standard Module Template

```elixir
defmodule Ashfolio.ModuleTest do
  use Ashfolio.DataCase, async: false

  # Imports in order of specificity
  import Ashfolio.SQLiteHelpers

  # Aliases for modules under test
  alias Ashfolio.Module

  # Module-level setup (if needed)
  setup do
    # Setup code here
    :ok
  end

  # Test organization with describe blocks
  describe "primary_function/1" do
    test "handles valid input successfully" do
      # Test implementation
    end

    test "handles invalid input with proper error" do
      # Test implementation
    end
  end

  describe "validation" do
    test "validates required fields" do
      # Test implementation
    end
  end

  describe "edge_cases" do
    test "handles boundary conditions" do
      # Test implementation
    end
  end
end
```

### LiveView Module Template

```elixir
defmodule AshfolioWeb.FeatureLiveTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ashfolio.SQLiteHelpers

  # LiveView-specific aliases
  alias AshfolioWeb.FeatureLive

  setup do
    # Provide consistent test context

    account = get_default_account()
    %{ account: account}
  end

  describe "page_rendering" do
    test "displays initial state correctly", %{conn: conn} do
      # Test implementation
    end
  end

  describe "user_interactions" do
    test "handles form submission", %{conn: conn} do
      # Test implementation
    end
  end

  describe "real_time_updates" do
    test "responds to PubSub events", %{conn: conn} do
      # Test implementation
    end
  end
end
```

### Integration Test Template

```elixir
defmodule Ashfolio.Integration.WorkflowTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ashfolio.SQLiteHelpers

  describe "complete_workflow_name" do
    test "user completes full workflow successfully", %{conn: conn} do
      # Step 1: Setup


      # Step 2: Navigate to starting point
      {:ok, view, _html} = live(conn, "/start-url")

      # Step 3: Execute workflow steps with verification
      # ... implementation

      # Step 4: Verify final state
      # ... assertions
    end

    test "workflow handles errors gracefully", %{conn: conn} do
      # Error scenario testing
    end
  end
end
```

## Naming Conventions

### Test Function Names

**Pattern**: `test "verb + object + condition"`

```elixir
# ✅ GOOD - Clear, descriptive names
test "creates user with valid attributes"
test "updates account balance successfully"
test "validates symbol format requirements"
test "handles database connection timeout gracefully"
test "calculates portfolio return for multiple holdings"

# ❌ AVOID - Vague or unclear names
test "user test"
test "it works"
test "basic case"
test "error"
```

### Describe Block Names

**Pattern**: Use function names or feature groups

```elixir
# ✅ GOOD - Function-based organization
describe "calculate_portfolio_value/1" do
  # Tests for this specific function
end

describe "create/2" do
  # Tests for create function with various scenarios
end

# ✅ GOOD - Feature-based organization
describe "validation" do
  # All validation-related tests
end

describe "error_handling" do
  # All error scenario tests
end
```

### Variable Names

```elixir
# ✅ GOOD - Descriptive and consistent

account = get_default_account()
symbol = get_common_symbol("AAPL")
transaction = create_test_transaction(user, account, symbol)

# ✅ GOOD - Context-specific names
high_balance_account = get_or_create_account(%{balance: Decimal.new("100000.00")})
expensive_symbol = get_or_create_symbol("TSLA", %{current_price: Decimal.new("800.00")})

# ❌ AVOID - Generic or unclear names
u = get_default_user()
acc1 = get_default_account()
thing = create_test_transaction()
```

## Data Usage Standards

### Priority Order for Test Data

1. **Global Data (Highest Priority)**

   ```elixir

   account = get_default_account()
   symbol = get_common_symbol("AAPL")  # AAPL, MSFT, GOOGL, TSLA
   ```

2. **Helper Functions (Medium Priority)**

   ```elixir
   custom_account = get_or_create_account(%{balance: Decimal.new("50000.00")})
   custom_symbol = get_or_create_symbol("NVDA", %{current_price: Decimal.new("800.00")})
   transaction = create_test_transaction(user, account, symbol, %{type: :sell})
   ```

3. **Direct Creation (Lowest Priority)**
   ```elixir
   # Only when absolutely necessary and with retry logic
   result = with_retry(fn ->
     SpecialResource.create(unique_params)
   end)
   ```

### Data Creation Patterns

```elixir
# ✅ STANDARD PATTERN - Use helper functions
test "portfolio calculation with custom data" do


  # Custom account for this test scenario
  high_value_account = get_or_create_account(%{
    name: "High Value Account",
    balance: Decimal.new("100000.00"),
    platform: "Premium Platform"
  })

  # Custom symbol with specific price
  volatile_symbol = get_or_create_symbol("CRYPTO", %{
    name: "Crypto Asset",
    current_price: Decimal.new("50000.00"),
    asset_class: :cryptocurrency
  })

  # Multiple transactions for complex scenario
  transactions = [
    create_test_transaction(user, high_value_account, volatile_symbol, %{
      type: :buy,
      quantity: Decimal.new("0.5"),
      price: Decimal.new("45000.00")
    }),
    create_test_transaction(user, high_value_account, volatile_symbol, %{
      type: :sell,
      quantity: Decimal.new("0.2"),
      price: Decimal.new("55000.00")
    })
  ]

  # Test complex calculation
  result = Calculator.calculate_portfolio_value(user)
  assert %Decimal{} = result
end

# ✅ GLOBAL DATA CONFLICT AVOIDANCE - Use unique identifiers
test "symbol validation with unique data" do
  # Avoid conflicts with global symbols (AAPL, MSFT, GOOGL, TSLA)
  unique_symbol = "TEST#{System.unique_integer([:positive])}"

  {:ok, symbol} = Symbol.create(%{
    symbol: unique_symbol,
    asset_class: :stock,
    data_source: :yahoo_finance
  })

  assert symbol.symbol == unique_symbol
end

# ✅ GLOBAL DATA COMPATIBLE ASSERTIONS - Work with existing data
test "account listing with global data" do


  {:ok, test_account} = Account.create(%{
    name: "Test Account"
  })

  {:ok, accounts} = Account.list()

  # ❌ AVOID - Expects exact count (fails with global data)
  # assert length(accounts) == 1

  # ✅ CORRECT - Verifies test data exists alongside global data
  account_names = Enum.map(accounts, & &1.name)
  assert "Test Account" in account_names
  assert length(accounts) >= 1
end
```

## Global Data Compatibility Standards

### Working with Global Test Data

The Ashfolio project uses a global test data strategy where default users, accounts, and symbols are created once and persist across tests. Tests must be designed to work alongside this existing data.

#### ✅ Global Data Compatible Patterns

```elixir
# Resource existence checks
test "verify test resource exists" do


  {:ok, account} = Account.create(%{name: "Test Account"})
  {:ok, accounts} = Account.list()

  # Check our resource is in the results
  account_ids = Enum.map(accounts, & &1.id)
  assert account.id in account_ids
end

# Unique identifier usage
test "create unique resources" do
  unique_id = System.unique_integer([:positive])
  unique_symbol = "TEST#{unique_id}"

  {:ok, symbol} = Symbol.create(%{symbol: unique_symbol, ...})
  assert symbol.symbol == unique_symbol
end

# Functional verification over count verification
test "verify functionality not isolation" do
  {:ok, active_accounts} = Account.active_accounts()

  # Verify all returned accounts meet criteria
  assert Enum.all?(active_accounts, fn acc -> acc.is_excluded == false end)
  # Don't assert exact count - global data may exist
end
```

#### ❌ Global Data Incompatible Patterns

```elixir
# Expecting empty database
test "problematic isolation assumption" do
  {:ok, accounts} = Account.list()
  assert Enum.empty?(accounts)  # ❌ Fails with global data
end

# Expecting exact counts
test "problematic count assumption" do
  {:ok, accounts} = Account.list()
  assert length(accounts) == 1  # ❌ Fails with global data
end

# Using hardcoded symbols that exist globally
test "problematic symbol conflict" do
  {:ok, symbol} = Symbol.create(%{symbol: "AAPL", ...})  # ❌ Conflicts with global AAPL
end
```

#### Global Data Resources Available

- **Default User**: Available via `get_default_user()`
- **Default Account**: Available via `get_default_account()`
- **Common Symbols**: AAPL, MSFT, GOOGL, TSLA via `get_common_symbol(ticker)`

## Assertion Standards

### Assertion Types and Usage

```elixir
# ✅ Pattern Matching - Preferred for structured data
assert {:ok, user} = User.create(params)
assert {:error, changeset} = User.create(invalid_params)
assert %User{name: "Test User"} = user

# ✅ Specific Value Assertions - For exact matches
assert user.name == "Test User"
assert account.balance == Decimal.new("10000.00")
assert length(transactions) == 3

# ✅ Type and Structure Assertions - For flexible validation
assert %Decimal{} = portfolio_value
assert is_list(holdings)
assert is_binary(error_message)

# ✅ Content Assertions - For UI and text validation
assert html =~ "Portfolio Dashboard"
assert has_element?(view, "[data-test='account-balance']")

# ✅ Boolean Assertions - For state validation
assert account.excluded == false
assert symbol.price_updated_at != nil
```

### Error Assertion Patterns

```elixir
# ✅ STANDARD - Test expected errors
test "validates required email field" do
  params = %{name: "Test User"}  # Missing email

  assert {:error, changeset} = User.create(params)
  assert %{email: ["is required"]} = errors_on(changeset)
end

# ✅ STANDARD - Test business rule violations
test "prevents overselling stock position" do

  account = get_default_account()
  symbol = get_common_symbol("AAPL")

  # Create position with 10 shares
  _buy_tx = create_test_transaction(user, account, symbol, %{
    type: :buy,
    quantity: Decimal.new("10")
  })

  # Attempt to sell 15 shares (should fail)
  result = create_test_transaction(user, account, symbol, %{
    type: :sell,
    quantity: Decimal.new("15")
  })

  assert {:error, _error} = result
end

# ✅ STANDARD - Test external service errors
test "handles yahoo finance API timeout" do
  expect(YahooFinanceMock, :fetch_price, fn _symbol ->
    {:error, :timeout}
  end)

  result = PriceManager.refresh_symbol_price("AAPL")
  assert {:error, :timeout} = result
end
```

## Setup and Teardown Standards

### Setup Block Patterns

```elixir
# ✅ MINIMAL SETUP - For tests using only global data
setup do
  # No setup needed - use get_default_user() in tests
  :ok
end

# ✅ BASIC SETUP - For tests needing consistent context
setup do

  account = get_default_account()
  %{ account: account}
end

# ✅ FEATURE SETUP - For related test groups
describe "portfolio calculations" do
  setup do

    account = get_default_account()

    # Create test portfolio scenario
    symbols = ["AAPL", "MSFT", "GOOGL"]
    transactions = Enum.map(symbols, fn ticker ->
      symbol = get_common_symbol(ticker)
      create_test_transaction(user, account, symbol, %{
        type: :buy,
        quantity: Decimal.new("10")
      })
    end)

    %{ account: account, transactions: transactions}
  end

  # All tests in this describe block get this context
end

# ✅ GENSERVER SETUP - For PriceManager tests
setup do
  allow_price_manager_db_access()

  expect(YahooFinanceMock, :fetch_price, fn _symbol ->
    {:ok, %{price: Decimal.new("150.00"), timestamp: DateTime.utc_now()}}
  end)

  :ok
end
```

### No Explicit Teardown

```elixir
# ✅ CORRECT - No teardown needed
# DataCase automatically handles database cleanup via sandbox
# No manual cleanup required for:
# - Database records
# - ETS tables
# - Process state
# - Mox expectations
```

## Error Handling Standards

### Comprehensive Error Testing

```elixir
describe "error_scenarios" do
  test "handles invalid decimal values gracefully" do


    # Test with various invalid inputs
    invalid_amounts = [
      "not_a_number",
      "",
      nil,
      %{invalid: "structure"}
    ]

    Enum.each(invalid_amounts, fn invalid_amount ->
      result = Calculator.calculate_fee(invalid_amount)
      assert {:error, _reason} = result
    end)
  end

  test "handles database connection failures" do
    # Simulate database unavailability
    with_mock(Repo, [:passthrough], [aggregate: fn _, _ -> {:error, :unavailable} end]) do
      result = Portfolio.get_total_accounts()
      assert {:error, :database_unavailable} = result
    end
  end

  test "handles concurrent access gracefully" do


    # Test retry logic under simulated contention
    result = with_retry(fn ->
      # This should succeed after retries
      get_or_create_account(%{name: "Retry Test Account"})
    end)

    assert %Account{name: "Retry Test Account"} = result
  end
end
```

## Documentation Standards

### Test Documentation

```elixir
defmodule Ashfolio.ComplexModuleTest do
  @moduledoc """
  Tests for ComplexModule functionality.

  This module handles complex financial calculations and requires
  specific test data scenarios. All tests use SQLite-safe patterns
  with retry logic for custom resource creation.

  Test Categories:
  - Basic calculations (using global data)
  - Edge cases (custom data scenarios)
  - Error handling (invalid inputs, boundary conditions)
  - Integration (cross-module interactions)
  """

  use Ashfolio.DataCase, async: false

  import Ashfolio.SQLiteHelpers

  alias Ashfolio.ComplexModule

  describe "primary_calculation/2" do
    @describedoc """
    Tests the main calculation function with various input scenarios.
    Uses default test data for consistent results.
    """

    test "calculates correct value for standard portfolio" do
      # Implementation with inline comments for complex logic


      # Use pre-seeded portfolio data for consistent calculation base
      result = ComplexModule.primary_calculation(user, %{type: :standard})

      # Verify specific calculation requirements
      assert %Decimal{} = result
      assert Decimal.gt?(result, Decimal.new("0"))
    end
  end
end
```

### Inline Comments for Complex Logic

```elixir
test "handles complex FIFO cost basis calculation" do

  account = get_default_account()
  symbol = get_common_symbol("AAPL")

  # Scenario: Multiple buy transactions at different prices
  # Expected: FIFO (First In, First Out) cost basis calculation

  # Buy 1: 10 shares at $100 (total cost: $1000)
  _buy1 = create_test_transaction(user, account, symbol, %{
    type: :buy,
    quantity: Decimal.new("10"),
    price: Decimal.new("100.00"),
    date: ~D[2023-01-01]
  })

  # Buy 2: 5 shares at $120 (total cost: $600)
  _buy2 = create_test_transaction(user, account, symbol, %{
    type: :buy,
    quantity: Decimal.new("5"),
    price: Decimal.new("120.00"),
    date: ~D[2023-01-02]
  })

  # Sell: 8 shares at $110
  # FIFO: Should sell 8 of the first 10 shares (cost basis: $100 each)
  # Expected gain: (110 - 100) * 8 = $80
  _sell = create_test_transaction(user, account, symbol, %{
    type: :sell,
    quantity: Decimal.new("8"),
    price: Decimal.new("110.00"),
    date: ~D[2023-01-03]
  })

  # Calculate remaining cost basis
  # Remaining: 2 shares from Buy 1 at $100, 5 shares from Buy 2 at $120
  # Expected cost basis: (2 * $100) + (5 * $120) = $800
  cost_basis = HoldingsCalculator.calculate_cost_basis(user, symbol.symbol)

  assert cost_basis == Decimal.new("800.00")
end
```

## Performance Standards

### Test Execution Efficiency

```elixir
# ✅ EFFICIENT - Minimize database operations
test "efficient portfolio calculation" do
  # Use global data (no database writes)

  account = get_default_account()

  # Batch related operations
  symbols = ["AAPL", "MSFT", "GOOGL"]
  results = Enum.map(symbols, fn ticker ->
    symbol = get_common_symbol(ticker)  # No database write
    Calculator.get_symbol_value(symbol)
  end)

  assert length(results) == 3
end

# ❌ INEFFICIENT - Multiple individual database operations
test "inefficient approach" do
  # Each call creates new database records
  user1 = create_user(%{name: "User 1"})    # Database write
  user2 = create_user(%{name: "User 2"})    # Database write
  user3 = create_user(%{name: "User 3"})    # Database write

  # Unnecessary resource creation for simple test
end
```

### Test Organization for Performance

```elixir
# ✅ EFFICIENT - Group related tests with shared setup
describe "with_high_value_portfolio" do
  setup do


    # Create complex test scenario once for all tests in this group
    account = get_or_create_account(%{balance: Decimal.new("100000.00")})

    symbols_data = [
      {"AAPL", "500.00", "10"},
      {"MSFT", "300.00", "20"},
      {"GOOGL", "2500.00", "5"}
    ]

    transactions = Enum.map(symbols_data, fn {ticker, price, quantity} ->
      symbol = get_or_create_symbol(ticker, %{current_price: Decimal.new(price)})
      create_test_transaction(user, account, symbol, %{
        type: :buy,
        quantity: Decimal.new(quantity),
        price: Decimal.new(price)
      })
    end)

    %{ account: account, transactions: transactions}
  end

  test "calculates high value portfolio correctly", context do
    # All tests in this describe use the shared expensive setup
    result = Calculator.calculate_portfolio_value(context.user)
    assert Decimal.gt?(result, Decimal.new("50000.00"))
  end

  test "handles high value account exclusion", context do
    # Reuses the same expensive setup
    result = Calculator.calculate_portfolio_value(context.user, exclude_accounts: [context.account.id])
    assert result == Decimal.new("0.00")
  end
end
```

## Quality Checklist

### Pre-submission Checklist

**File Structure**:

- [ ] Correct module name and file location
- [ ] `use Ashfolio.DataCase, async: false` (never async: true)
- [ ] Proper imports (`import Ashfolio.SQLiteHelpers`)
- [ ] Logical describe block organization

**Test Data**:

- [ ] Used global data when possible (`get_default_user()`, etc.)
- [ ] Used helper functions for custom resources
- [ ] No direct resource creation without retry logic
- [ ] Appropriate data complexity for test scope

**Test Quality**:

- [ ] Descriptive test names explaining behavior
- [ ] Both success and error scenarios covered
- [ ] Appropriate assertion types used
- [ ] Complex logic explained with comments

**SQLite Compatibility**:

- [ ] No async: true usage
- [ ] Proper GenServer database permissions when needed
- [ ] Mox expectations for external services
- [ ] No direct database operations without retry protection

**Performance**:

- [ ] Minimized unnecessary database operations
- [ ] Shared setup for related tests
- [ ] Appropriate test type (unit vs integration)
- [ ] Efficient resource usage

### Code Review Standards

**Reviewers should check for**:

1. **Consistency**: Follows established patterns and naming conventions
2. **Reliability**: Proper SQLite concurrency handling
3. **Efficiency**: Minimal database operations and appropriate data usage
4. **Coverage**: Tests both happy path and error scenarios
5. **Clarity**: Descriptive names and adequate documentation
6. **Maintainability**: Uses helper functions and avoids duplication

This standards document ensures all tests in the Ashfolio project maintain consistency, reliability, and performance while being accessible to both human developers and AI agents.
