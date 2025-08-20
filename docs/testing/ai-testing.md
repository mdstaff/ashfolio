# AI Agent Testing Guide for Ashfolio

## Overview

This guide provides specific instructions for AI agents working on the Ashfolio test suite. It focuses on practical patterns, common pitfalls, and decision-making frameworks for efficient test development.

## Quick Reference for AI Agents

### Essential Commands

```bash
# Basic Commands
just test-file test/path/to/test.exs     # Test specific file
just test-file-verbose test/path/to/test.exs  # Verbose output for debugging
just compile                             # Check compilation
just test-failed                         # Run failed tests only
just test                               # Full test suite (takes longer)

# NEW: Modular Testing Commands (Use These for Focused Development)
just test-fast                          # Quick development feedback (< 100ms tests)
just test-smoke                         # Essential tests that must always pass

# Test by architectural layer
just test-ash                           # Business logic (User, Account, Symbol, Transaction)
just test-liveview                      # UI components and interactions
just test-calculations                  # Portfolio math and FIFO calculations
just test-market-data                   # Price fetching and Yahoo Finance integration

# Test by scope
just test-unit                          # Isolated unit tests
just test-integration                   # End-to-end workflows

# Test with specific dependencies
just test-external                      # Tests requiring external APIs
just test-mocked                        # Tests using Mox for external services

# All commands support -verbose variants for detailed output
just test-fast-verbose                  # Fast tests with detailed output
just test-ash-verbose                   # Business logic tests with detailed output
```

### Critical File Locations

- `test/test_helper.exs` - Global configuration
- `test/support/sqlite_helpers.ex` - Core helper functions
- `test/support/data_case.ex` - Database setup
- `test/support/live_view_case.ex` - LiveView setup

## Decision Tree for AI Agents

### 1. What Type of Test Should I Create?

```
Is this testing a single module/function?
├─ YES → Unit Test (test/ashfolio/module_test.exs)
└─ NO → Is this testing UI interactions?
   ├─ YES → LiveView Test (test/ashfolio_web/live/feature_test.exs)
   └─ NO → Is this testing end-to-end workflows?
      ├─ YES → Integration Test (test/integration/workflow_test.exs)
      └─ NO → Determine most appropriate category
```

### 2. What Data Should I Use?

```
Do I need standard user/account/symbol data?
├─ YES → Use global data (get_default_user(), get_default_account(), get_common_symbol())
└─ NO → Do I need custom attributes?
   ├─ YES → Use retry helpers (get_or_create_account(), get_or_create_symbol())
   └─ NO → Create custom with create_test_transaction()
```

### 3. How Should I Handle Database Operations?

```
Is this a simple read operation?
├─ YES → Use global data getters directly
└─ NO → Is this creating new resources?
   ├─ YES → Use retry helpers (with_retry or helper functions)
   └─ NO → Are you testing GenServer operations?
      ├─ YES → Add allow_price_manager_db_access() to setup
      └─ NO → Follow standard DataCase pattern
```

## Code Templates for AI Agents

### Template 1: Basic Unit Test

```elixir
defmodule Ashfolio.MyModuleTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.MyModule
  import Ashfolio.SQLiteHelpers

  describe "function_name/1" do
    test "handles valid input" do
      # Use global data when possible


      # Test the function
      result = MyModule.function_name(user)

      # Assert expected behavior
      assert {:ok, _} = result
    end

    test "handles invalid input" do
      # Test error cases
      result = MyModule.function_name(nil)
      assert {:error, _} = result
    end
  end
end
```

### Template 2: LiveView Test

```elixir
defmodule AshfolioWeb.MyLiveTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ashfolio.SQLiteHelpers

  setup do
    # Always provide basic context

    account = get_default_account()
    %{ account: account}
  end

  describe "page rendering" do
    test "displays correct content", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/my-page")

      assert html =~ "Expected Content"
    end
  end

  describe "user interactions" do
    test "handles button click", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/my-page")

      # Simulate user interaction
      result = view |> element("button[data-test='my-button']") |> render_click()

      # Assert expected outcome
      assert result =~ "Success Message"
    end
  end
end
```

### Template 3: Integration Test

```elixir
defmodule Ashfolio.Integration.MyWorkflowTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ashfolio.SQLiteHelpers

  describe "complete workflow" do
    test "user can complete full process", %{conn: conn} do
      # Step 1: Setup


      # Step 2: Navigate to starting point
      {:ok, view, _html} = live(conn, "/start-page")

      # Step 3: Execute workflow steps
      view
      |> element("button[data-test='step-1']")
      |> render_click()

      # Step 4: Verify intermediate state
      assert has_element?(view, "[data-test='step-1-complete']")

      # Step 5: Continue workflow
      view
      |> element("button[data-test='step-2']")
      |> render_click()

      # Step 6: Verify final outcome
      assert has_element?(view, "[data-test='workflow-complete']")
    end
  end
end
```

### Template 4: PriceManager/GenServer Test

```elixir
defmodule Ashfolio.PriceManagerTest do
  use Ashfolio.DataCase, async: false

  import Ashfolio.SQLiteHelpers

  alias Ashfolio.MarketData.PriceManager

  setup do
    # CRITICAL: Allow GenServer database access
    allow_price_manager_db_access()

    # Mock external API calls
    expect(YahooFinanceMock, :fetch_price, fn _symbol ->
      {:ok, %{price: Decimal.new("150.00"), timestamp: DateTime.utc_now()}}
    end)

    :ok
  end

  describe "price refresh" do
    test "updates symbol prices successfully" do
      # Test can now call GenServer functions
      result = PriceManager.refresh_prices()

      assert {:ok, updated_symbols} = result
      assert length(updated_symbols) > 0
    end
  end
end
```

## Common Patterns for AI Agents

### Pattern 1: Using Global Data (Most Common)

```elixir
test "portfolio calculation" do
  #  FAST - Uses pre-created data

  account = get_default_account()
  symbol = get_common_symbol("AAPL")  # AAPL, MSFT, GOOGL, TSLA available

  # Your test logic here
  result = Calculator.calculate_portfolio_value(user)
  assert %Decimal{} = result
end
```

### Pattern 2: Creating Custom Resources (When Needed)

```elixir
test "custom account scenario" do


  #  SAFE - Uses retry logic internally
  custom_account = get_or_create_account(%{
    name: "High Balance Account",
    balance: Decimal.new("50000.00"),
    platform: "Custom Platform"
  })

  #  SAFE - Updates existing or creates new
  expensive_symbol = get_or_create_symbol("NVDA", %{
    current_price: Decimal.new("800.00")
  })

  # Test with custom data
end
```

### Pattern 3: Transaction Scenarios

```elixir
test "multiple transaction types" do

  account = get_default_account()
  symbol = get_common_symbol("MSFT")

  #  EFFICIENT - Uses helper with retry logic
  buy_tx = create_test_transaction(user, account, symbol, %{
    type: :buy,
    quantity: Decimal.new("10"),
    price: Decimal.new("300.00")
  })

  sell_tx = create_test_transaction(user, account, symbol, %{
    type: :sell,
    quantity: Decimal.new("5"),
    price: Decimal.new("320.00")
  })

  # Test calculations with transaction history
  holdings = HoldingsCalculator.get_holdings_summary(user)
  assert length(holdings) > 0
end
```

## Error Handling Patterns

### Pattern 1: Expected Errors

```elixir
test "handles invalid input gracefully" do
  # Test expected error conditions
  result = MyModule.process_data(nil)

  assert {:error, :invalid_input} = result
end

test "validates required fields" do
  assert {:error, changeset} = result
  assert %{name: ["is required"]} = errors_on(changeset)
end
```

### Pattern 2: Database Errors

```elixir
test "handles database constraints" do


  # First account with name
  account1 = get_or_create_account(%{name: "Unique Name"})
  assert account1.name == "Unique Name"

  # Attempt duplicate name (should fail gracefully)
  result = with_retry(fn ->
    Account.create(%{
      name: "Unique Name",  # Duplicate name
      balance: Decimal.new("1000.00")
    }, actor: user)
  end)

  # Assert appropriate error handling
  assert {:error, _changeset} = result
end
```

## AI Agent Decision Guidelines

### When to Use Global Data

#### New: Use Modular Testing Commands for Focused Development

```bash
#  FAST DEVELOPMENT - Use targeted commands for development workflow
just test-fast           # Quick feedback during development (< 100ms tests)
just test-smoke          # Essential functionality verification

#  ARCHITECTURAL FOCUS - Match your development area
just test-ash           # When working on business logic (User, Account, Symbol, Transaction)
just test-liveview      # When working on UI components and interactions
just test-calculations  # When working on portfolio math and FIFO calculations
just test-market-data   # When working on price fetching and Yahoo Finance

#  SCOPE-BASED DEVELOPMENT - Choose appropriate test scope
just test-unit          # For isolated functionality testing
just test-integration   # For end-to-end workflow testing
just test-regression    # For bug fix validation
just test-error-handling # For fault tolerance testing

# ❌ AVOID during active development - Use for final validation only
just test               # Full test suite (slow feedback loop)
just test-all           # Comprehensive suite including seeding tests
```

- Testing calculations with standard data
- Need basic user/account/symbol for context
- Testing read-only operations
- Performance is important

```elixir
# Portfolio calculations

holdings = Calculator.calculate_holdings(user)

# Symbol lookups
symbol = get_common_symbol("AAPL")
price = symbol.current_price
```

### When to Create Custom Data

- Testing edge cases or specific scenarios
- Need unusual attribute combinations
- Testing validation logic
- Simulating complex portfolios

```elixir
# High-balance account for testing
account = get_or_create_account(%{
  balance: Decimal.new("1000000.00")
})

# Specific price for calculation testing
symbol = get_or_create_symbol("TEST", %{
  current_price: Decimal.new("0.01")
})
```

### When to Use Integration Tests

- Testing complete user workflows
- Multiple modules interact
- UI and backend integration
- Testing system behavior

- Account creation → Transaction entry → Portfolio calculation
- Price refresh → Cache update → Dashboard display
- User navigation → Form submission → Database update

## Debugging Guide for AI Agents

### Step 1: Identify Test Failure Type

```bash
# Run specific failing test with full output
just test-file-verbose test/path/to/failing_test.exs
```

```
# SQLite Concurrency Issue
** (Ash.Error.Unknown) %Sqlite.DbConnection.Error{message: "database is locked"}
→ Solution: Use retry helpers or global data

# Missing Test Data
** (RuntimeError) Default user not found
→ Solution: Ensure setup_global_test_data!/0 was called

# LiveView Error
** (ArgumentError) expected first argument to be a %Phoenix.LiveView.Socket{}
→ Solution: Check LiveView test setup and imports

# Mox Error
** (Mox.UnexpectedCallError) no expectation defined for YahooFinanceMock.fetch_price/1
→ Solution: Add expect() calls in test setup
```

### Step 2: Common Fix Patterns

```elixir
# Fix 1: SQLite Busy Errors
# Replace direct creation:
{:ok, account} = Account.create(params)

# With retry helper:
account = get_or_create_account(params)

# Fix 2: Missing GenServer Permissions
# Add to setup block:
setup do
  allow_price_manager_db_access()
  :ok
end

# Fix 3: Missing Mock Expectations
# Add to setup or test:
expect(YahooFinanceMock, :fetch_price, fn _symbol ->
  {:ok, %{price: Decimal.new("100.00"), timestamp: DateTime.utc_now()}}
end)

# Fix 4: Missing Test Data
# Replace custom user creation:
{:ok, user} = User.create(%{name: "Test"})

# With global data:

```

### Step 3: Verification Steps

```bash
# 1. Verify compilation
just compile

# 2. Run single test
just test-file test/specific/test_file.exs

# 3. Run full suite if needed
just test

# 4. Check for warnings
just compile-warnings
```

## Performance Tips for AI Agents

### Tip 1: Minimize Database Writes

```elixir
#  FAST - Uses existing data
test "fast test" do
          # No DB write
  account = get_default_account()  # No DB write
  # Test logic
end

# ❌ SLOW - Creates new data
test "slow test" do
  {:ok, user} = User.create(%{})     # DB write
  {:ok, account} = Account.create(%{}) # DB write
  # Test logic
end
```

### Tip 2: Use Appropriate Test Types

```elixir
#  UNIT TEST - Fast, focused
test "calculation logic" do
  input = %{amount: Decimal.new("100.00")}
  result = Calculator.add_fee(input, Decimal.new("5.00"))
  assert result == Decimal.new("105.00")
end

#  INTEGRATION TEST - Slower, comprehensive
test "complete portfolio workflow" do
  # Multi-step workflow testing
end
```

### Tip 3: Smart Test Organization

```elixir
defmodule MyTest do
  # Group related tests that can share setup
  describe "with basic data" do
    setup do

      %{user: user}
    end

    test "scenario 1", %{user: user} do
      # Uses shared setup
    end

    test "scenario 2", %{user: user} do
      # Uses shared setup
    end
  end

  describe "with custom data" do
    setup do

      custom_account = get_or_create_account(%{balance: Decimal.new("50000.00")})
      %{ account: custom_account}
    end

    # Tests that need custom data
  end
end
```

## Quality Checklist for AI Agents

Before submitting test code, verify:

### Structure Checklist

- [ ] `use Ashfolio.DataCase, async: false` (never async: true)
- [ ] `import Ashfolio.SQLiteHelpers` included
- [ ] Tests organized in logical `describe` blocks
- [ ] Descriptive test names explaining behavior

### Data Usage Checklist

- [ ] Used global data (`get_default_user()`) when possible
- [ ] Used retry helpers for custom resources
- [ ] No direct `User.create()` or `Account.create()` calls without retry
- [ ] Used `create_test_transaction()` for transaction tests

### Error Handling Checklist

- [ ] Tests both success and error cases
- [ ] Uses `assert {:ok, _}` and `assert {:error, _}` patterns
- [ ] Validates error messages when relevant
- [ ] Handles expected exceptions gracefully

### Performance Checklist

- [ ] Minimized database write operations
- [ ] Used appropriate test type (unit vs integration)
- [ ] Avoided unnecessary data creation
- [ ] Shared setup data when possible

### Special Cases Checklist

- [ ] Added `allow_price_manager_db_access()` for GenServer tests
- [ ] Added Mox expectations for external API calls
- [ ] Used proper LiveView test imports and setup
- [ ] Handled async operations correctly

## Summary for AI Agents

1. **Always use `async: false`** for SQLite compatibility
2. **Prefer global data** over custom creation for performance
3. **Use retry helpers** when custom resources are needed
4. **Structure tests** with descriptive describe blocks
5. **Handle both success and error cases**
6. **Add proper setup** for GenServer and LiveView tests

7. Using `async: true` (causes SQLite conflicts)
8. Creating users/accounts directly without retry logic
9. Missing GenServer database permissions
10. Forgetting Mox expectations for external calls
11. Not testing error scenarios
12. Creating unnecessary custom data

Following these patterns will result in reliable, fast, maintainable tests that work well with Ashfolio's SQLite-based architecture.

## Integration Test Patterns (Recently Added)

### Pattern: LiveView Form Testing with Global Data

When testing LiveView forms, ensure the test data matches what the form expects:

```elixir
# ❌ PROBLEMATIC - Creates data that form doesn't recognize
test "form submission" do
  {:ok, account} = Account.create(%{name: "Test Account"})

  # Form will fail because account.id isn't in form's select options
  form_data = %{account_id: account.id, ...}
end

#  CORRECT - Uses global data that form recognizes
test "form submission" do

  account = SQLiteHelpers.get_default_account()

  # Form will work because account.id matches form's select options
  form_data = %{account_id: account.id, ...}
end
```

### Pattern: Performance Test Data Setup

For performance tests that need realistic data volumes:

```elixir
#  CORRECT - Uses get_or_create for existing symbols
test "performance with realistic data" do

  account = SQLiteHelpers.get_default_account()

  # Use existing symbols or create if needed
  symbols = ["AAPL", "MSFT", "GOOGL", "TSLA", "AMZN"]
  created_symbols =
    Enum.map(symbols, fn symbol_name ->
      SQLiteHelpers.get_or_create_symbol(symbol_name, %{
        name: "#{symbol_name} Inc.",
        asset_class: :stock,
        current_price: Decimal.new("#{100 + :rand.uniform(200)}.00")
      })
    end)

  # Create test transactions using existing data
  # ... rest of test
end
```

### Pattern: PubSub Integration Testing

For testing real-time events and LiveView updates:

```elixir
test "PubSub event broadcasting" do
  # Use global data for consistency

  account = SQLiteHelpers.get_default_account()
  symbol = SQLiteHelpers.get_common_symbol("AAPL")

  # Subscribe to events
  Ashfolio.PubSub.subscribe("transactions")

  # Perform action that should broadcast
  {:ok, transaction_live, _html} = live(conn, ~p"/transactions")

  # Submit form with data that matches form options
  transaction_live
  |> form("#transaction-form", transaction: %{
    account_id: account.id,  # This ID will be in form's select options
    symbol_id: symbol.id,
    # ... other fields
  })
  |> render_submit()

  # Verify event was broadcast
  assert_receive {:transaction_saved, _transaction}, 1000
end
```

## Recent Fixes Applied (August 7, 2025)

### Fix: Performance Benchmarks Test

- Symbol creation conflicts with global test data
- Used `SQLiteHelpers.get_or_create_symbol()` instead of direct `Symbol.create()`
- `test/integration/performance_benchmarks_test.exs`

### Fix: Transaction PubSub Test

- Form validation errors due to account ID mismatch
- Used global test data helpers consistently
- `test/integration/transaction_pubsub_test.exs`

These fixes demonstrate the importance of the global test data strategy for integration tests.
