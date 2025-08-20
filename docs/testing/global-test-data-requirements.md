# Global Test Data Requirements & Management

## Overview

**Global test data management** is critical to Ashfolio's testing architecture due to our **database-as-user pattern** and **SQLite concurrency limitations**. During v0.3.0 development, we identified critical issues with global test data management that caused test failures and inconsistent behavior.

This document establishes requirements and standards for managing global test data to ensure:

- **Reliable test execution** across all environments
- **Predictable test behavior** for developers and AI agents
- **Efficient SQLite usage** within concurrency constraints
- **Clear separation** between unit and integration test concerns

### **Architecture Context**

Ashfolio implements a single-user local application where the database itself represents the user's portfolio. This eliminates traditional user management complexity but requires careful test data coordination.

SQLite's single-writer limitation means tests cannot run in parallel with database writes. This drove our global test data strategy where common resources are created once and reused across tests.

Portfolio calculations depend on precise transaction sequences and account states. Global test data provides a predictable foundation while allowing tests to create additional complexity when needed.

Unlike traditional multi-tenant applications with user isolation, our tests must work within SQLite's concurrency constraints while maintaining the database-as-user pattern that drives our domain architecture.

## Issues Identified

### 1. **Account Balance Interference**

- Global test account with $10,000 balance affected net worth calculations
- Tests expected specific values but got inflated amounts due to global data
- Example: Test expected $1,500 investment value, got $11,500 (including global account)

### 2. **Inconsistent Data Isolation**

- Tests marked `async: false` but still interfered with each other
- No systematic reset of global account balances between tests
- Mix of transaction-based calculations vs. account balance calculations

### 3. **Unclear Test Dependencies**

- Tests assumed clean slate but inherited global test data
- Some tests relied on global data, others were hindered by it
- No clear documentation of what global data exists

## Requirements

### 1. **Global Test Data Must Be Predictable**

**Essential Global Data:**

- One test user account (for database-as-user architecture)
- Standard symbols (AAPL, GOOGL, MSFT, TSLA) with current prices
- One "Default Test Account" for basic functionality

**Global Data Constraints:**

- 🚫 Global accounts MUST have zero balances by default
- 🚫 Global accounts MUST NOT contain transactions unless explicitly needed
- Global data MUST be documented and visible in test output

### 2. **Test Isolation Requirements**

**Per-Test Setup:**

```elixir
setup do
  # Reset all account balances to zero
  Account.read!()
  |> Enum.each(fn account ->
    Account.update!(account, %{balance: Decimal.new("0")})
  end)

  :ok
end
```

**Test Categories:**

- Should not depend on global data
- May use global data but must reset state
- Should use dedicated test accounts

### 3. **Account Balance Management**

**Current Issue:**

```elixir
# NetWorthCalculator mixes two calculation methods:
# 1. HoldingsCalculator.aggregate_portfolio_value() (transaction-based)
# 2. Account balance summation (balance-based)
```

**Required Fix:**

- Use transaction-based calculations (HoldingsCalculator)
- Use account balance summation
- **Clear separation** between the two approaches

### 4. **Test Data Visibility**

**Current Global Test Data:**

- User: "Test User"
- Account: "Default Test Account" (investment, $10,000 balance)
- Symbols: 4 symbols with market prices
- Categories: Standard transaction categories

**Required Documentation:**

```elixir
# In each test file that uses global data:
@moduledoc """
Global Test Data Dependencies:
- Default Test Account: $0 balance (reset in setup)
- Standard symbols: AAPL, GOOGL, MSFT, TSLA
- Test user for database-as-user architecture
"""
```

## Implementation Plan

### Phase 1: Immediate Fixes

1.  Fix NetWorthCalculator to properly handle investment vs cash calculations
2.  Update tests to use correct account field names (`account_type` not `type`)
3.  Ensure global test account has zero balance by default

### Phase 2: Test Isolation

1. Add setup blocks to reset account balances in affected tests
2. Document global data dependencies in test modules
3. Create helper functions for test data management

### Phase 3: Long-term Improvements

1. Consider separate test databases for different test categories
2. Implement test data fixtures for consistent setup
3. Add test data validation in CI pipeline

## Success Criteria

### Test Reliability

- All tests pass consistently across multiple runs
- No unexpected account balance interference
- Clear separation between unit and integration tests

### Developer Experience

- Clear documentation of global test data
- Predictable test behavior
- Easy to add new tests without breaking existing ones

### Test Performance

- Fast test execution (global data doesn't slow down tests)
- Minimal test database setup overhead
- Parallel test execution where appropriate

## Template Examples

### **Template 1: Unit Test with Global Data**

```elixir
defmodule Ashfolio.Calculator.MyCalculatorTest do
  @moduledoc """
  Tests for MyCalculator functionality using global test data.

  Global Dependencies:
  - Default User: Available via get_default_user()
  - Default Account: Available via get_default_account()
  - Common Symbols: AAPL, MSFT, GOOGL, TSLA via get_common_symbol()
  """
  use Ashfolio.DataCase, async: false

  import Ashfolio.SQLiteHelpers
  alias Ashfolio.Calculator.MyCalculator

  describe "calculate_value/2" do
    test "calculates portfolio value with global data" do
      user = get_default_user()
      account = get_default_account()
      symbol = get_common_symbol("AAPL")

      # Test using existing global data - no database writes needed
      result = MyCalculator.calculate_value(user, account)
      assert %Decimal{} = result
    end

    test "handles empty portfolio gracefully" do
      user = get_default_user()

      # Test edge case
      result = MyCalculator.calculate_value(user, %{transactions: []})
      assert result == Decimal.new("0")
    end
  end
end
```

### **Template 2: Integration Test with Account Reset**

```elixir
defmodule Ashfolio.Integration.PortfolioWorkflowTest do
  @moduledoc """
  Integration tests for complete portfolio workflows.

  Critical: Resets global account balances in setup to ensure clean state.
  Uses global data foundation with test-specific transactions.
  """
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ashfolio.SQLiteHelpers

  setup do
    # CRITICAL: Reset global account balances for integration tests
    Account.read!()
    |> Enum.each(fn account ->
      Account.update!(account, %{balance: Decimal.new("0")})
    end)

    user = get_default_user()
    account = get_default_account()
    %{user: user, account: account}
  end

  describe "complete portfolio workflow" do
    test "user creates and manages portfolio", %{conn: conn, user: user, account: account} do
      # Step 1: Navigate to dashboard
      {:ok, view, _html} = live(conn, "/dashboard")

      # Step 2: Add investment transaction
      symbol = get_common_symbol("AAPL")
      transaction = create_test_transaction(user, account, symbol, %{
        type: :buy,
        quantity: Decimal.new("10"),
        price: Decimal.new("150.00")
      })

      # Step 3: Verify portfolio calculations
      portfolio_value = Calculator.calculate_portfolio_value(user)
      assert Decimal.eq?(portfolio_value, Decimal.new("1500.00"))
    end
  end
end
```

### **Template 3: LiveView Test with Custom Data**

```elixir
defmodule AshfolioWeb.AccountLive.FormTest do
  @moduledoc """
  Tests for AccountLive form component.

  Uses custom test accounts to verify form behavior without
  interfering with global test data.
  """
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ashfolio.SQLiteHelpers

  setup do
    user = get_default_user()

    # Create custom account for form testing
    test_account = get_or_create_account(%{
      name: "Form Test Account",
      balance: Decimal.new("25000.00"),
      platform: "Test Platform"
    })

    %{user: user, test_account: test_account}
  end

  describe "account form interactions" do
    test "updates account successfully", %{conn: conn, test_account: account} do
      {:ok, view, _html} = live(conn, "/accounts/#{account.id}/edit")

      # Test form submission
      view
      |> form("#account-form", account: %{name: "Updated Account Name"})
      |> render_submit()

      # Verify update
      updated_account = Account.get!(account.id)
      assert updated_account.name == "Updated Account Name"
    end
  end
end
```

### **Template 4: Complex Scenario with Multiple Resources**

```elixir
defmodule Ashfolio.Portfolio.ComplexScenarioTest do
  @moduledoc """
  Complex portfolio calculation tests requiring multiple accounts,
  symbols, and transaction sequences.

  Creates test-specific data while using global foundation.
  """
  use Ashfolio.DataCase, async: false

  import Ashfolio.SQLiteHelpers
  alias Ashfolio.Portfolio.Calculator

  describe "complex portfolio calculations" do
    test "calculates FIFO cost basis across multiple accounts" do
      user = get_default_user()

      # Create multiple accounts for scenario
      checking_account = get_or_create_account(%{
        name: "Checking Account",
        account_type: :cash,
        balance: Decimal.new("50000.00")
      })

      investment_account = get_or_create_account(%{
        name: "Investment Account",
        account_type: :investment,
        balance: Decimal.new("0.00")
      })

      # Create symbols with specific prices
      expensive_stock = get_or_create_symbol("EXPENSIVE", %{
        current_price: Decimal.new("2000.00"),
        asset_class: :stock
      })

      # Create complex transaction sequence
      transactions = [
        # Initial buy at high price
        create_test_transaction(user, investment_account, expensive_stock, %{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("1800.00"),
          date: ~D[2023-01-01]
        }),

        # Additional buy at higher price
        create_test_transaction(user, investment_account, expensive_stock, %{
          type: :buy,
          quantity: Decimal.new("5"),
          price: Decimal.new("2200.00"),
          date: ~D[2023-01-15]
        }),

        # Partial sell - should use FIFO
        create_test_transaction(user, investment_account, expensive_stock, %{
          type: :sell,
          quantity: Decimal.new("8"),
          price: Decimal.new("2100.00"),
          date: ~D[2023-02-01]
        })
      ]

      # Verify FIFO cost basis calculation
      # Remaining: 2 shares at $1800 + 5 shares at $2200 = $14,600
      remaining_cost_basis = Calculator.calculate_cost_basis(user, expensive_stock.symbol)
      expected_cost_basis = Decimal.new("14600.00")

      assert Decimal.eq?(remaining_cost_basis, expected_cost_basis)
    end
  end
end
```

## Integration with Testing Framework

### **Related Documentation**

This document works in conjunction with:

- **[Framework Guide](framework.md)** - Technical implementation details and SQLiteHelpers usage
- **[SQLite Patterns](patterns.md)** - Concurrency handling and retry logic patterns
- **[Testing Standards](standards.md)** - Code quality standards and test organization
- **[Testing Strategy](../TESTING_STRATEGY.md)** - Overall testing approach and categories

### **For New Developers**

1. **Read this document first** to understand global test data strategy
2. **Review [Framework Guide](framework.md)** for implementation patterns
3. **Check [Standards](standards.md)** for code organization requirements
4. **Use [SQLite Patterns](patterns.md)** when encountering concurrency issues

### **For AI Agents**

- `get_default_user()`, `get_default_account()`, `get_common_symbol(ticker)`
- `get_or_create_account()`, `create_test_transaction()` with built-in retry logic
- SQLite requires `async: false` for all tests
- Tests must work alongside existing global accounts/symbols

## Maintenance & Evolution

### **When to Update This Document**

This document should be updated when:

- **Global test data structure changes** (new default accounts, symbols, etc.)
- **SQLiteHelpers module functionality changes** (new helper functions, changed retry logic)
- **Testing patterns evolve** (new requirements discovered through development)
- **Architecture changes affect testing** (database schema changes, domain model updates)

### **Documentation Review Process**

1.  Developers should verify testing patterns still apply
2.  Update patterns if new SQLite concurrency issues are discovered
3.  Ensure global test data requirements remain valid
4.  Review if database-as-user pattern affects testing

### **Keeping Global Test Data Current**

Global test data in `test/support/sqlite_helpers.ex` should be reviewed:

- **When adding new domain entities** that should be globally available
- **When changing default account structures** that tests depend on
- **When symbol data requirements change** (new asset classes, price structures)
- **When database schema migrations affect** core test entities

### **Success Metrics for This Approach**

Track these metrics to validate the global test data strategy:

- Consistent pass rates across environments
- Time from test failure to resolution
- Time for new developers to contribute tests
- Quality of AI-generated tests following patterns

## Conclusion

Proper global test data management is critical for:

- **Reliable test suite** with predictable outcomes across SQLite's concurrency constraints
- **Developer productivity** with clear test requirements and helper patterns
- **Maintainable codebase** with isolated test concerns and architectural consistency
- **AI agent effectiveness** with well-defined patterns and global data expectations

This systematic approach established during v0.3.0 development ensures test reliability as the application scales toward v1.0, supporting both human developers and AI agents working on the codebase.
