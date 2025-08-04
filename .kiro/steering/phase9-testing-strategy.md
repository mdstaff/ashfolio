# Phase 9: Testing Strategy and Integration Guide

## Overview

This document outlines the testing strategy for Phase 9 of the Ashfolio project, focusing on comprehensive testing and final integration. Current test coverage shows 201/201 tests passing, with the need to expand coverage for new features and integration scenarios.

## 1. Test Coverage Requirements

### 1.1 Resource Testing (Task #28)

#### Ash Resources

- **User Resource**

  - Single user support validation
  - Default currency handling
  - Basic CRUD operations

- **Account Resource**

  - Relationship validation (user, transactions)
  - Balance tracking
  - Platform association
  - CRUD operations with validations

- **Symbol Resource**

  - Price update actions
  - Transaction relationships
  - Cache integration
  - Yahoo Finance integration

- **Transaction Resource**
  - Type validation (BUY, SELL, DIVIDEND, FEE)
  - Required field validation
  - Date validation (not in future)
  - Relationship integrity

#### Portfolio Calculations

- Cost basis calculations (FIFO)
- Return calculations
  - Simple returns
  - Position-level P&L
  - Portfolio-level aggregation
- Holdings calculations
  - Current values
  - Quantity aggregation
  - P&L calculations

#### LiveView Testing

- Dashboard display
- Account management interface
- Transaction forms
- Price refresh functionality
- Error state handling

#### Integration Points

- Yahoo Finance API
- ETS cache operations
- Price refresh workflow
- Database operations

### 1.2 Integration Testing (Task #29)

#### Core Workflows

1. Account Management Flow

   ```
   Create Account → Validate Fields → View in List → Edit → Delete
   ```

2. Transaction Flow

   ```
   Select Account → Enter Transaction → Validate → View in Portfolio → Edit/Delete
   ```

3. Portfolio View Flow
   ```
   View Dashboard → Refresh Prices → View Updates → Check Calculations
   ```

#### Critical Integration Points

- Price refresh functionality

  - Manual refresh
  - Cache updates
  - UI updates
  - Error handling

- Transaction impact

  - Portfolio recalculation
  - Holdings updates
  - Cost basis updates

- Error handling
  - API failures
  - Validation errors
  - Network timeouts
  - Cache misses

## 2. Testing Strategy

### 2.1 Test Organization

```elixir
test/
├── ash/                 # Ash resource tests
│   ├── user_test.exs
│   ├── account_test.exs
│   ├── symbol_test.exs
│   └── transaction_test.exs
├── portfolio/           # Portfolio calculation tests
│   ├── calculator_test.exs
│   └── holdings_calculator_test.exs
├── live/               # LiveView tests
│   ├── dashboard_test.exs
│   ├── account_test.exs
│   └── transaction_test.exs
└── integration/        # Integration tests
    ├── workflow_test.exs
    └── price_refresh_test.exs
```

### 2.2 Test Categories and Tags

```elixir
# Resource Tests
@tag :ash_resource
@tag :user
@tag :account
@tag :symbol
@tag :transaction

# Calculation Tests
@tag :portfolio
@tag :calculator
@tag :holdings

# Integration Tests
@tag :integration
@tag :workflow
@tag :price_refresh

# LiveView Tests
@tag :live_view
@tag :dashboard
@tag :forms
```

### 2.3 Test Commands

**Always use the project's justfile commands for testing:**

```bash
# Primary Commands (Use These)
just test                                    # Main test suite (excludes seeding)
just test-file <path>                       # Specific test file (preferred for focused testing)
just test-seeding                           # Seeding tests only
just test-coverage                          # Coverage report
just test-watch                             # Watch mode for development
just test-failed                            # Re-run failed tests only

# Full Test Suite (When Needed)
just test-all                               # All tests including seeding

# Debugging Only (Avoid for Regular Use)
just test-file-verbose <path>               # Verbose output for specific file
just test-verbose                           # Verbose main suite (avoid)
just test-all-verbose                       # Verbose all tests (avoid)
```

**Testing Best Practices:**

- Use `just test-file <path>` for individual test files during development
- Avoid verbose commands unless debugging specific failures
- Run `just test` for quick validation of main test suite
- Use `just test-seeding` separately when seeding functionality is modified

## 3. Implementation Guidelines

### 3.1 Test Helper Functions

```elixir
# test/support/fixtures.ex
defmodule Ashfolio.Fixtures do
  def valid_account_attrs do
    %{
      name: "Test Account",
      platform: "Test Platform",
      balance: Decimal.new("10000.00")
    }
  end

  def valid_transaction_attrs do
    %{
      type: "BUY",
      symbol: "AAPL",
      quantity: Decimal.new("10"),
      price: Decimal.new("150.00"),
      date: Date.utc_today()
    }
  end
end
```

### 3.2 Integration Test Setup

```elixir
# test/support/integration_case.ex
defmodule Ashfolio.IntegrationCase do
  use ExUnit.CaseTemplate

  setup do
    # Setup test database
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ashfolio.Repo)

    # Clear ETS cache
    :ets.delete_all_objects(:price_cache)

    # Setup mock for Yahoo Finance API
    Mox.stub_with(Ashfolio.YahooFinance.Mock, Ashfolio.YahooFinance.Behaviour)

    :ok
  end
end
```

## 4. Quality Gates

### 4.1 Required Coverage

- **Resource Tests**: 100% coverage
- **Calculation Tests**: 100% coverage
- **LiveView Tests**: 90% coverage
- **Integration Tests**: Key workflows covered

### 4.2 Performance Benchmarks

- Page load time: < 500ms
- Price refresh: < 2s
- Portfolio calculation: < 100ms

### 4.3 Error Handling Coverage

- API failures
- Validation errors
- Network timeouts
- Cache misses
- Database errors

## 5. Completion Criteria

✅ All existing 201 tests passing
✅ New integration tests added and passing
✅ All core workflows tested
✅ Error handling scenarios covered
✅ Performance benchmarks met

## 6. Resources

- [Ash Framework Testing Guide](https://ash-hq.org/docs/guides/ash/latest/testing)
- [Phoenix LiveView Testing](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html)
- [ExUnit Documentation](https://hexdocs.pm/ex_unit/ExUnit.html)
- [Mox Documentation](https://hexdocs.pm/mox/Mox.html)
