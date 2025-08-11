# Context API Architecture - Reusable Data Access Layer

## Overview

This document outlines the architectural approach for implementing a reusable Context API layer that provides common data access patterns for the Ashfolio wealth management platform. This addresses the need for more reusable approaches to common operations like getting user data and account lists.

## Problem Statement

Currently, common operations require:

- Multiple individual Ash resource calls
- Manual composition of related data
- Repetitive patterns across LiveView, mix tasks, and potential APIs
- Mix commands for basic data retrieval operations

## Solution: Phoenix Context Pattern with Local API Layer

Implement a high-level Context module that provides reusable functions for common data access patterns, optimized for our local-first, SQLite-based architecture.

## Architecture Design

### Core Context Module

```elixir
defmodule Ashfolio.Portfolio.Context do
  @moduledoc """
  High-level API for portfolio operations - local-first design
  Provides reusable functions for common data access patterns
  """

  alias Ashfolio.Portfolio.{User, Account, Transaction, Symbol}

  # Common pattern: Get user with all related data
  def get_user_dashboard_data(user_id \\ nil)

  # Reusable account operations
  def get_account_with_transactions(account_id, limit \\ 50)

  # Common portfolio queries
  def get_portfolio_summary(user_id \\ nil)

  # Account-specific operations
  def get_account_summary(user_id \\ nil)

  # Transaction operations
  def get_recent_transactions(user_id, limit \\ 10)
end
```

### Mix Task Integration

```elixir
# mix ashfolio.dashboard
defmodule Mix.Tasks.Ashfolio.Dashboard do
  use Mix.Task
  @shortdoc "Display portfolio dashboard data"

  def run(_args) do
    Mix.Task.run("app.start")

    case Ashfolio.Portfolio.Context.get_user_dashboard_data() do
      {:ok, data} -> display_dashboard(data)
      {:error, reason} -> IO.puts("Error: #{inspect(reason)}")
    end
  end
end
```

### LiveView Helper Integration

```elixir
defmodule AshfolioWeb.PortfolioHelpers do
  @moduledoc """
  Reusable helpers for LiveView components
  """

  def assign_dashboard_data(socket, user_id \\ nil)
  def assign_account_data(socket, account_id)
  def assign_portfolio_data(socket, user_id \\ nil)
end
```

## Implementation Phases

### Phase 1: Core Context Module (4-6 hours)

**Priority: High**
**Risk: Low**

**Deliverables:**

- `lib/ashfolio/portfolio/context.ex`
- Core functions: `get_user_dashboard_data/1`, `get_account_with_transactions/2`, `get_portfolio_summary/1`
- Basic test coverage
- Integration with existing Ash resources

**Implementation Details:**

- Thin wrappers around existing Ash code interfaces
- Leverage existing calculation modules (Calculator, HoldingsCalculator)
- No database schema changes required
- Compose existing functions rather than create new business logic

### Phase 2: Mix Task Wrappers (2-3 hours)

**Priority: Medium**
**Risk: Very Low**

**Deliverables:**

- `lib/mix/tasks/ashfolio/dashboard.ex`
- `lib/mix/tasks/ashfolio/accounts.ex`
- `lib/mix/tasks/ashfolio/portfolio.ex`
- CLI formatting and display logic

**Implementation Details:**

- CLI wrappers around Context functions
- Reuse existing FormatHelpers
- Simple display and formatting logic

### Phase 3: LiveView Integration Helpers (3-4 hours)

**Priority: Medium**
**Risk: Low**

**Deliverables:**

- `lib/ashfolio_web/portfolio_helpers.ex`
- Refactor existing LiveView modules to use helpers
- Standardized assign patterns

**Implementation Details:**

- Move existing assign logic into reusable functions
- Maintain existing LiveView functionality
- Improve code reuse across LiveView modules

### Phase 4: Testing & Documentation (4-5 hours)

**Priority: High**
**Risk: Low**

**Deliverables:**

- Comprehensive test coverage for Context module
- Mix task tests
- LiveView helper tests
- Integration tests
- Updated documentation

**Implementation Details:**

- Leverage existing test patterns and SQLiteHelpers
- Test both success and error scenarios
- Integration testing across multiple resources

## Technical Benefits

### 1. **Local-First Optimized**

- Single function calls replace multiple database queries
- SQLite-optimized with proper connection pooling
- Works completely offline
- Batched queries reduce SQLite round trips

### 2. **Ash Framework Native**

- Leverages Ash's built-in query optimization
- Uses Ash policies and calculations
- Maintains type safety and validation
- No breaking changes to existing Ash resources

### 3. **Reusable Across Interfaces**

- Same functions work for LiveView, mix tasks, and future APIs
- Consistent data structure across all interfaces
- Easy to test and maintain
- Foundation for future API endpoints

### 4. **Performance Focused**

- ETS caching for frequently accessed data
- Concurrent processing where beneficial
- Optimized for SQLite concurrent access patterns

## Data Structures

### Dashboard Data Structure

```elixir
%{
  user: %User{},
  accounts: %{
    all: [%Account{}],
    investment: [%Account{}],
    cash: [%Account{}]
  },
  recent_transactions: [%Transaction{}],
  summary: %{
    total_balance: Decimal.t(),
    account_count: integer(),
    last_updated: DateTime.t()
  }
}
```

### Account Data Structure

```elixir
%{
  account: %Account{},
  transactions: [%Transaction{}],
  balance_history: [%{date: Date.t(), balance: Decimal.t()}],
  summary: %{
    transaction_count: integer(),
    total_inflow: Decimal.t(),
    total_outflow: Decimal.t()
  }
}
```

### Portfolio Summary Structure

```elixir
%{
  total_value: Decimal.t(),
  total_return: %{
    amount: Decimal.t(),
    percentage: Decimal.t()
  },
  accounts: [%Account{}],
  holdings: [%Holding{}],
  performance: %{
    daily_change: Decimal.t(),
    weekly_change: Decimal.t(),
    monthly_change: Decimal.t()
  },
  last_updated: DateTime.t()
}
```

## Error Handling Strategy

### Consistent Error Patterns

```elixir
# Success case
{:ok, data}

# Error cases
{:error, :user_not_found}
{:error, :account_not_found}
{:error, :insufficient_data}
{:error, {:validation_failed, changeset}}
```

### Graceful Degradation

- Return partial data when some operations fail
- Provide default values for missing data
- Log errors for debugging while maintaining user experience

## Testing Strategy

### Unit Tests

- Test each Context function independently
- Mock external dependencies
- Test both success and error scenarios
- Validate data structure consistency

### Integration Tests

- Test Context functions with real Ash resources
- Verify database interactions
- Test performance with realistic data volumes
- Validate SQLite concurrent access patterns

### Mix Task Tests

- Test CLI output formatting
- Verify error handling and user feedback
- Test with various data scenarios

## Performance Considerations

### SQLite Optimization

- Use prepared statements for repeated queries
- Batch related operations
- Leverage existing indexes
- Monitor query performance

### Memory Management

- Use streaming for large datasets
- Implement pagination for large result sets
- Cache frequently accessed data in ETS
- Monitor memory usage patterns

### Concurrent Access

- Leverage SQLite WAL mode
- Use connection pooling effectively
- Handle concurrent read/write scenarios
- Implement proper locking strategies

## Migration Strategy

### Backward Compatibility

- No breaking changes to existing APIs
- Existing LiveView and mix functionality preserved
- Gradual migration of existing code to use Context functions

### Implementation Order

1. Implement Context module with core functions
2. Add comprehensive test coverage
3. Create mix task wrappers
4. Refactor existing LiveView modules
5. Add LiveView helpers
6. Performance optimization and monitoring

## Success Metrics

### Developer Experience

- Reduced lines of code for common operations
- Faster development of new features
- Improved code reuse and maintainability
- Cleaner separation of concerns

### Performance Metrics

- Reduced database query count for common operations
- Improved response times for dashboard and account views
- Better SQLite connection utilization
- Reduced memory usage for data operations

### Code Quality

- Increased test coverage
- Reduced code duplication
- Improved error handling consistency
- Better documentation and examples

## Future Enhancements

### API Endpoints (Optional)

- JSON API endpoints using Context functions
- GraphQL schema for flexible queries
- Authentication and authorization layer
- Rate limiting and caching

### Advanced Features

- Real-time data subscriptions
- Background data synchronization
- Advanced caching strategies
- Performance monitoring and alerting

## Risk Assessment

### Low Risk Factors

- No breaking changes to existing APIs
- Can implement incrementally
- Existing test suite catches regressions
- All dependencies already in place
- Leverages existing, proven patterns

### Mitigation Strategies

- Implement incrementally with thorough testing
- Maintain backward compatibility throughout
- Monitor performance impact
- Provide rollback strategy if needed

## Conclusion

This Context API architecture provides a high-value, low-risk improvement that will:

- Immediately improve developer experience
- Provide foundation for future enhancements
- Maintain the local-first, SQLite-optimized design
- Enhance code reuse and maintainability

The implementation effort is manageable (13-18 hours total) with low risk and high return on investment.
