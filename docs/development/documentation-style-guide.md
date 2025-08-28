# Documentation Style Guide

## Overview

This guide establishes comprehensive standards for documenting Elixir code in the Ashfolio project. It ensures consistency, maintainability, and clarity across all modules, functions, and tests.

## Core Principles

1. Documentation is Code - Documentation should be maintained with the same rigor as code
2. Developer Experience First - Documentation should help developers understand intent and usage quickly
3. Examples Drive Understanding - Provide concrete examples for all public APIs
4. No Surprises - Document edge cases, error conditions, and performance characteristics
5. Consistency - Follow established patterns across the entire codebase

## Module Documentation (`@moduledoc`)

### Required Elements

Every module MUST have a `@moduledoc` that includes:

1. Purpose Statement - What this module does in 1-2 sentences
2. Key Features - Bullet list of main capabilities
3. Usage Context - When/how this module should be used
4. Performance Notes - If relevant to module design

### Template

```elixir
defmodule Ashfolio.Domain.ModuleName do
  @moduledoc """
  Brief description of what this module does and its primary purpose.

  This module provides [main functionality] for [specific use case]. It handles
  [key responsibilities] with focus on [important characteristics like performance, reliability, etc.].

  Key features:
  - Feature 1 with brief explanation
  - Feature 2 with brief explanation
  - Feature 3 with brief explanation

  ## Usage Context

  This module is primarily used for [specific scenarios]. It's designed for
  [performance/reliability/specific requirements] and integrates with [related systems].

  ## Performance Characteristics

  - Operation X: Expected performance under normal conditions
  - Operation Y: Scaling behavior and limitations
  - Memory usage: General memory profile

  ## Examples

      # Simple usage example
      {:ok, result} = ModuleName.primary_function(args)

      # More complex example showing configuration
      ModuleName.configured_function(args, opts: [key: value])
  """
```

### Real Example

```elixir
defmodule Ashfolio.FinancialManagement.NetWorthCalculatorOptimized do
  @moduledoc """
  Optimized net worth calculation module with batch loading for high-performance financial calculations.

  This module replaces the original NetWorthCalculator with performance optimizations targeting
  sub-100ms response times for realistic portfolios. It uses batch queries and efficient
  data processing to minimize database round trips.

  Key features:
  - Batch loading of accounts and related data
  - Single aggregate queries for cash balance calculations
  - Efficient preloading to prevent N+1 queries
  - In-memory processing for complex calculations

  ## Performance Characteristics

  - 50-70% reduction in query count vs original implementation
  - 40-60% improvement in calculation time
  - Target: <100ms for portfolios with 50+ accounts
  - Memory efficient through streaming and batching

  ## Usage Context

  Use this module for all net worth calculations in production. The original
  NetWorthCalculator is retained for comparison and fallback scenarios.

  ## Examples

      # Calculate complete net worth with breakdown
      {:ok, result} = NetWorthCalculatorOptimized.calculate_net_worth()
      %{
        net_worth: %Decimal{},
        investment_value: %Decimal{},
        cash_value: %Decimal{},
        breakdown: %{...}
      }

      # Calculate only cash balances (faster for specific use cases)
      {:ok, cash_total} = NetWorthCalculatorOptimized.calculate_total_cash_balances()
  """
```

## Function Documentation (`@doc`)

### Required for ALL Public Functions

Every public function MUST have `@doc` with:

1. Purpose - What the function does
2. Parameters - What each parameter expects
3. Return Values - All possible return patterns
4. Examples - Concrete usage examples
5. Error Conditions - When/how it fails

### Template

```elixir
@doc """
Brief description of what this function does.

Longer explanation if needed, covering the algorithm, approach, or important
implementation details that affect usage.

## Parameters

- `param1` - Description of first parameter and its expected type/format
- `param2` - Description of second parameter, including constraints
- `options` - Keyword list with supported options:
  - `:option1` - What this option controls (default: value)
  - `:option2` - Another option description

## Returns

- `{:ok, result}` - Success case with description of result structure
- `{:error, reason}` - Error case with possible reason values:
  - `:invalid_input` - When input validation fails
  - `:database_error` - When database operations fail
  - `:calculation_error` - When calculations cannot be completed

## Examples

    # Basic usage
    iex> ModuleName.function_name(valid_input)
    {:ok, expected_result}

    # Usage with options
    iex> ModuleName.function_name(input, timeout: 5000)
    {:ok, result_with_timeout}

    # Error case
    iex> ModuleName.function_name(invalid_input)
    {:error, :invalid_input}

## Performance Notes

Include any relevant performance characteristics, especially for functions
that might be called frequently or have notable time/memory complexity.
"""
def function_name(param1, param2, options \\ []) do
```

## Private Function Documentation

### Use `#` Comments for Private Functions

Private functions should use standard `#` comments above the function definition:

```elixir
# Single query to load all account data needed for net worth calculation.
# This replaces multiple individual queries with one efficient batch query
# that includes all necessary data and preloads.
#
# Returns {:ok, accounts_data} with grouped account information, or
# {:error, reason} if the batch load fails.
defp batch_load_account_data() do
```

### Multi-line Comment Standards

For complex private functions, use structured comments:

```elixir
# Calculate net worth from pre-loaded batch data.
#
# All data is already in memory, so this is pure computation
# without additional database queries. The calculation combines:
# - Investment values (passed as parameter)
# - Cash totals (from accounts_data)
# - Account breakdowns (built from loaded data)
#
# Performance: <10ms for typical portfolios since no DB queries.
defp calculate_net_worth_from_batch(accounts_data, investment_value) do
```

## Type Specifications (`@spec`)

### Required for Public Functions

All public functions SHOULD have `@spec` declarations:

```elixir
@spec calculate_portfolio_value(String.t()) ::
  {:ok, Decimal.t()} | {:error, atom()}
def calculate_portfolio_value() when is_binary() do
```

### Complex Type Specifications

For functions with complex return types, document the structure:

```elixir
@typedoc """
Net worth calculation result containing all financial totals and breakdowns.

- `net_worth` - Total net worth (investment + cash)
- `investment_value` - Total value of all investment accounts
- `cash_value` - Total value of all cash accounts
- `breakdown` - Detailed account-by-account breakdown
"""
@type net_worth_result :: %{
  net_worth: Decimal.t(),
  investment_value: Decimal.t(),
  cash_value: Decimal.t(),
  breakdown: account_breakdown()
}

@spec calculate_net_worth(String.t()) ::
  {:ok, net_worth_result()} | {:error, atom()}
```

## Inline Comments

### When to Use Inline Comments

Use `#` comments for:

1. Algorithm explanations - Complex logic that isn't obvious
2. Business rule clarifications - Why specific decisions are made
3. Performance notes - Optimization explanations
4. Temporary workarounds - With TODO and issue references

### Comment Style

```elixir
# Group accounts by type for efficient processing
# This avoids repeated filtering in downstream functions
{investment_accounts, cash_accounts} =
  Enum.split_with(accounts, fn account ->
    account.account_type == :investment
  end)

# Single aggregate query at database level instead of loading
# all accounts into memory - reduces memory usage by ~80%
cash_total =
  from(a in Account,
    where: a.user_id == ^user_id and a.account_type in @cash_types,
    select: sum(a.balance)
  )
  |> Repo.one()
```

## Test Documentation

### Test Module Documentation

All test modules should follow our testing strategy outlined in `docs/TESTING_STRATEGY.md`. Include appropriate tags and clear documentation:

```elixir
defmodule AshfolioWeb.Components.CategoryTagTest do
  @moduledoc """
  Tests for the CategoryTag component covering visual rendering, accessibility,
  and responsive behavior.

  This test suite ensures the CategoryTag component:
  - Renders with proper styling and colors
  - Meets accessibility standards (WCAG contrast ratios)
  - Adapts correctly to different screen sizes
  - Handles edge cases (long names, special characters)

  Test categorization: :unit (fast component tests)
  Performance target: All tests should complete in <50ms each.

  See docs/TESTING_STRATEGY.md for test organization and CI/CD pipeline integration.
  """

  @moduletag :unit
```

### Test Function Documentation

Use descriptive test names that serve as documentation and follow our testing strategy:

```elixir
# Good - test name explains the scenario and expectation
test "CategoryTag calculates proper color contrast for accessibility compliance" do

# Good - test name describes the specific behavior being tested
test "TransactionFilter component validates amount range inputs with user feedback" do

# Good - includes appropriate tags for test organization
@tag :integration
test "AccountLive displays filtered account data correctly" do

# Good - performance test with appropriate tag
@tag :performance
test "NetWorthCalculator handles 100+ accounts under 100ms" do

# Avoid - too generic
test "category tag works" do
```

## Documentation Quality Checklist

### Before Committing

- [ ] All public modules have complete `@moduledoc`
- [ ] All public functions have `@doc` with examples
- [ ] All public functions have `@spec` declarations
- [ ] Complex private functions have explanatory comments
- [ ] Performance characteristics are documented where relevant
- [ ] Error conditions and edge cases are explained
- [ ] Examples are tested and work correctly

### Review Guidelines

When reviewing code, check that:

- Documentation explains "why" not just "what"
- Examples cover common use cases
- Error conditions are clearly documented
- Performance implications are noted
- Documentation is consistent with existing patterns

## Examples of Good Documentation

### Well-Documented Module

```elixir
defmodule Ashfolio.Portfolio.Calculator do
  @moduledoc """
  Portfolio value calculations and performance metrics for investment tracking.

  Provides core portfolio calculations including total value, returns, and individual
  position performance. Designed for accuracy and performance with large portfolios.

  Key features:
  - Total portfolio value across all accounts
  - Simple and time-weighted return calculations
  - Individual position gains/losses
  - Cost basis calculation from transaction history

  ## Performance Characteristics

  - Portfolio value calculation: <20ms for 100+ positions
  - Return calculations: <10ms for typical portfolios
  - Memory usage: ~1MB per 1000 transactions processed

  ## Examples

      # Calculate total portfolio value
      {:ok, total_value} = Calculator.calculate_portfolio_value()

      # Get detailed performance metrics
      {:ok, metrics} = Calculator.calculate_returns(period: :ytd)
  """

  @typedoc "Portfolio performance metrics including returns and ratios"
  @type portfolio_metrics :: %{
    total_return: Decimal.t(),
    annualized_return: Decimal.t(),
    sharpe_ratio: Decimal.t()
  }

  @doc """
  Calculate total portfolio value for a user across all investment accounts.

  Sums current market values of all holdings, excluding cash accounts which
  are handled separately by the NetWorthCalculator.

  ## Parameters

  - `user_id` - User UUID string

  ## Returns

  - `{:ok, total_value}` - Success with Decimal total value
  - `{:error, :user_not_found}` - User ID doesn't exist
  - `{:error, :calculation_error}` - Database or calculation failure

  ## Examples

      iex> Calculator.calculate_portfolio_value("valid-uuid")
      {:ok, #Decimal<12500.00>}

      iex> Calculator.calculate_portfolio_value("invalid-id")
      {:error, :user_not_found}
  """
  @spec calculate_portfolio_value(String.t()) ::
    {:ok, Decimal.t()} | {:error, atom()}
  def calculate_portfolio_value() when is_binary() do
    # Implementation with proper inline comments
  end
```

## Integration with CLAUDE.md

This style guide extends the existing CLAUDE.md guidelines:

- Documentation is part of our "no linter/formatter warnings" standard
- Good documentation makes code more testable by clarifying expected behavior
- "Will someone understand this in 6 months?" applies especially to documentation
- Follow these patterns across all modules for consistency

## Tools and Enforcement

### ExDoc Integration

- Ensure all `@doc` and `@moduledoc` render correctly in generated docs
- Use `mix docs` to generate and review documentation locally
- Include code examples that are tested via doctests when possible

### Linting

- Credo rules should enforce module and function documentation
- Configure Credo to require `@doc` for all public functions
- Set up warnings for missing `@spec` on public functions

### CI/CD Integration

- Documentation generation should be part of the CI pipeline
- Consider adding documentation coverage metrics
- Ensure all examples in documentation are syntactically correct

This style guide ensures our code is not only functional but also maintainable and approachable for all team members and future contributors.
