# Context API Implementation Plan

## Overview

This document provides a detailed implementation plan for the Context API architecture, including specific tasks that can be integrated into the existing comprehensive financial management spec.

## Implementation Tasks

### Task A: Core Context Module Implementation

**Estimated Effort:** 4-6 hours
**Priority:** High
**Dependencies:** Task 1 (Account enhancements) - ✅ Complete

**Subtasks:**

- A.1: Create `Ashfolio.Portfolio.Context` module structure
- A.2: Implement `get_user_dashboard_data/1` function
- A.3: Implement `get_account_with_transactions/2` function
- A.4: Implement `get_portfolio_summary/1` function
- A.5: Add helper functions for data aggregation
- A.6: Write comprehensive unit tests

**Acceptance Criteria:**

- Context module provides consistent API for common data operations
- All functions return standardized `{:ok, data}` or `{:error, reason}` tuples
- Functions compose existing Ash resource operations efficiently
- Comprehensive test coverage (>95%) for all Context functions
- Performance benchmarks show improved query efficiency vs individual calls

**Implementation Details:**

```elixir
# File: lib/ashfolio/portfolio/context.ex

defmodule Ashfolio.Portfolio.Context do
  @moduledoc """
  High-level API for portfolio operations - local-first design
  """

  alias Ashfolio.Portfolio.{User, Account, Transaction, Symbol}
  alias Ashfolio.Portfolio.{Calculator, HoldingsCalculator}

  @doc """
  Get comprehensive dashboard data for a user
  Returns user info, accounts (categorized), recent transactions, and summary
  """
  def get_user_dashboard_data(user_id \\ nil) do
    user_id = user_id || get_default_user_id()

    with {:ok, user} <- User.get_by_id(user_id),
         {:ok, accounts} <- Account.accounts_for_user(user_id),
         {:ok, recent_transactions} <- get_recent_transactions(user_id, 10) do

      categorized_accounts = categorize_accounts(accounts)
      summary = calculate_account_summary(accounts)

      {:ok, %{
        user: user,
        accounts: categorized_accounts,
        recent_transactions: recent_transactions,
        summary: summary,
        last_updated: DateTime.utc_now()
      }}
    end
  end

  @doc """
  Get account details with transaction history and balance progression
  """
  def get_account_with_transactions(account_id, limit \\ 50) do
    with {:ok, account} <- Account.get_by_id(account_id),
         {:ok, transactions} <- Transaction.for_account(account_id, limit: limit) do

      balance_history = calculate_balance_history(transactions)
      transaction_summary = calculate_transaction_summary(transactions)

      {:ok, %{
        account: account,
        transactions: transactions,
        balance_history: balance_history,
        summary: transaction_summary,
        last_updated: DateTime.utc_now()
      }}
    end
  end

  @doc """
  Get comprehensive portfolio summary with performance metrics
  """
  def get_portfolio_summary(user_id \\ nil) do
    user_id = user_id || get_default_user_id()

    with {:ok, accounts} <- Account.active_accounts_for_user(user_id),
         {:ok, holdings} <- HoldingsCalculator.get_holdings_summary(user_id),
         {:ok, performance} <- Calculator.calculate_total_return(user_id) do

      {:ok, %{
        total_value: performance.total_value,
        total_return: performance.total_return,
        accounts: accounts,
        holdings: holdings,
        performance: calculate_performance_metrics(user_id),
        last_updated: DateTime.utc_now()
      }}
    end
  end

  # Private helper functions
  defp get_default_user_id do
    case User.get_default_user() do
      {:ok, user} -> user.id
      _ -> nil
    end
  end

  defp categorize_accounts(accounts) do
    %{
      all: accounts,
      investment: Enum.filter(accounts, &(&1.account_type == :investment)),
      cash: Enum.filter(accounts, &(&1.account_type in [:checking, :savings, :money_market, :cd])),
      active: Enum.filter(accounts, &(!&1.is_excluded))
    }
  end

  defp calculate_account_summary(accounts) do
    total_balance = accounts
      |> Enum.map(& &1.balance)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    %{
      total_balance: total_balance,
      account_count: length(accounts),
      active_count: Enum.count(accounts, &(!&1.is_excluded)),
      cash_balance: calculate_cash_balance(accounts),
      investment_balance: calculate_investment_balance(accounts)
    }
  end
end
```

### Task B: Mix Task CLI Wrappers

**Estimated Effort:** 2-3 hours
**Priority:** Medium
**Dependencies:** Task A (Context module)

**Subtasks:**

- B.1: Create `mix ashfolio.dashboard` task
- B.2: Create `mix ashfolio.accounts` task
- B.3: Create `mix ashfolio.portfolio` task
- B.4: Add CLI formatting and display helpers
- B.5: Write tests for mix tasks

**Implementation Details:**

```elixir
# File: lib/mix/tasks/ashfolio/dashboard.ex

defmodule Mix.Tasks.Ashfolio.Dashboard do
  use Mix.Task

  @shortdoc "Display portfolio dashboard data"
  @moduledoc """
  Display comprehensive dashboard information including:
  - User information
  - Account summary (investment vs cash)
  - Recent transactions
  - Portfolio totals

  ## Examples

      mix ashfolio.dashboard
      mix ashfolio.dashboard --user-id UUID
  """

  def run(args) do
    Mix.Task.run("app.start")

    {opts, _args, _invalid} = OptionParser.parse(args,
      strict: [user_id: :string],
      aliases: [u: :user_id]
    )

    user_id = opts[:user_id]

    case Ashfolio.Portfolio.Context.get_user_dashboard_data(user_id) do
      {:ok, data} -> display_dashboard(data)
      {:error, reason} -> display_error(reason)
    end
  end

  defp display_dashboard(data) do
    IO.puts("\n" <> IO.ANSI.blue() <> "=== Ashfolio Portfolio Dashboard ===" <> IO.ANSI.reset())
    IO.puts("User: #{data.user.name}")
    IO.puts("Last Updated: #{format_datetime(data.last_updated)}")

    display_account_summary(data.accounts, data.summary)
    display_recent_transactions(data.recent_transactions)
  end
end
```

### Task C: LiveView Helper Integration

**Estimated Effort:** 3-4 hours
**Priority:** Medium
**Dependencies:** Task A (Context module)

**Subtasks:**

- C.1: Create `AshfolioWeb.PortfolioHelpers` module
- C.2: Implement `assign_dashboard_data/2` helper
- C.3: Implement `assign_account_data/2` helper
- C.4: Refactor existing LiveView modules to use helpers
- C.5: Write tests for LiveView helpers

**Implementation Details:**

```elixir
# File: lib/ashfolio_web/portfolio_helpers.ex

defmodule AshfolioWeb.PortfolioHelpers do
  @moduledoc """
  Reusable helpers for LiveView components that use Context API
  """

  import Phoenix.LiveView
  alias Ashfolio.Portfolio.Context

  @doc """
  Assign dashboard data to LiveView socket
  Handles loading states and error cases gracefully
  """
  def assign_dashboard_data(socket, user_id \\ nil) do
    socket = assign(socket, :loading_dashboard, true)

    case Context.get_user_dashboard_data(user_id) do
      {:ok, data} ->
        socket
        |> assign(:user, data.user)
        |> assign(:accounts, data.accounts)
        |> assign(:recent_transactions, data.recent_transactions)
        |> assign(:summary, data.summary)
        |> assign(:dashboard_last_updated, data.last_updated)
        |> assign(:loading_dashboard, false)

      {:error, reason} ->
        socket
        |> put_flash(:error, format_error_message(reason))
        |> assign(:loading_dashboard, false)
    end
  end

  @doc """
  Assign account-specific data to LiveView socket
  """
  def assign_account_data(socket, account_id, transaction_limit \\ 50) do
    socket = assign(socket, :loading_account, true)

    case Context.get_account_with_transactions(account_id, transaction_limit) do
      {:ok, data} ->
        socket
        |> assign(:account, data.account)
        |> assign(:transactions, data.transactions)
        |> assign(:balance_history, data.balance_history)
        |> assign(:account_summary, data.summary)
        |> assign(:loading_account, false)

      {:error, reason} ->
        socket
        |> put_flash(:error, format_error_message(reason))
        |> assign(:loading_account, false)
    end
  end
end
```

### Task D: Comprehensive Testing

**Estimated Effort:** 4-5 hours
**Priority:** High
**Dependencies:** Tasks A, B, C

**Subtasks:**

- D.1: Write unit tests for Context module functions
- D.2: Write integration tests for Context with Ash resources
- D.3: Write tests for Mix tasks
- D.4: Write tests for LiveView helpers
- D.5: Add performance benchmarks
- D.6: Update existing tests to use Context where appropriate

**Test Coverage Requirements:**

- Context module: >95% line coverage
- Mix tasks: Test CLI output and error handling
- LiveView helpers: Test assign patterns and error states
- Integration tests: Test with realistic data volumes
- Performance tests: Benchmark against individual Ash calls

## Integration with Existing Tasks

### Current Task Status

- ✅ Task 1: Enhance Account resource for cash account types (Complete)
- 🔄 Tasks 2-15: Continue with existing implementation plan

### Proposed Integration Points

**Option 1: Insert as New Tasks**

- Insert Context API tasks between current Tasks 5-6
- Allows immediate benefit for remaining tasks
- Provides foundation for enhanced cash management features

**Option 2: Parallel Implementation**

- Implement Context API alongside existing tasks
- Refactor completed tasks to use Context API
- Gradual migration approach

**Option 3: Post-MVP Enhancement**

- Complete existing task list first
- Implement Context API as enhancement phase
- Lower risk but delayed benefits

### Recommended Approach: Option 1

Insert Context API tasks after Task 5 (Cash transaction types) to provide immediate benefits for remaining cash management features.

**Updated Task Sequence:**

1. ✅ Enhance Account resource for cash account types
2. Create Transaction resource enhancements for cash accounts
3. Implement cash account interest calculations
4. Create cash account management UI
5. Implement cash transaction types and validation
6. **NEW: Task A - Core Context Module Implementation**
7. **NEW: Task B - Mix Task CLI Wrappers**
8. **NEW: Task C - LiveView Helper Integration**
9. **NEW: Task D - Comprehensive Testing**
10. Continue with remaining cash management tasks (using Context API)

## Success Criteria

### Functional Requirements

- [ ] Context module provides all documented functions
- [ ] Mix tasks work correctly and provide useful output
- [ ] LiveView helpers integrate seamlessly with existing components
- [ ] All functions handle error cases gracefully
- [ ] Performance is equal or better than individual Ash calls

### Non-Functional Requirements

- [ ] > 95% test coverage for Context module
- [ ] Documentation is comprehensive and includes examples
- [ ] No breaking changes to existing functionality
- [ ] Performance benchmarks show improvement
- [ ] Code follows existing project patterns and standards

### User Experience

- [ ] Mix tasks provide immediate value for CLI operations
- [ ] LiveView components load faster with batched data
- [ ] Error messages are user-friendly and actionable
- [ ] Data structures are consistent across all interfaces

## Rollback Plan

If issues arise during implementation:

1. **Context Module Issues**: Revert to individual Ash calls
2. **Mix Task Issues**: Remove mix tasks, keep Context module
3. **LiveView Issues**: Revert LiveView changes, keep Context module
4. **Performance Issues**: Optimize queries or add caching layer

All changes are additive and non-breaking, making rollback straightforward.

## Future Enhancements

Once Context API is established:

1. **GraphQL Integration**: Use Context functions as GraphQL resolvers
2. **JSON API Endpoints**: Expose Context functions as REST endpoints
3. **Real-time Subscriptions**: Add PubSub integration to Context functions
4. **Advanced Caching**: Implement ETS caching layer for frequently accessed data
5. **Background Jobs**: Use Context functions in Oban job processing

## Conclusion

This implementation plan provides a structured approach to adding the Context API layer with clear tasks, acceptance criteria, and integration points. The modular approach allows for incremental implementation with immediate benefits and low risk of disruption to existing functionality.
