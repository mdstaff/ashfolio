# Data Utilities Guide

This guide documents the data manipulation utilities and helper functions available in Ashfolio for common data processing patterns.

## Overview

Ashfolio provides a comprehensive set of data utilities through the `Ashfolio.DataHelpers` module. These utilities standardize common data processing patterns across LiveViews and reduce code duplication.

## Core Module: Ashfolio.DataHelpers

Located at: `lib/ashfolio/data_helpers.ex`

### Purpose

The DataHelpers module consolidates repetitive data processing patterns commonly used in LiveViews, including:

- Date range filtering
- Collection grouping and aggregation
- Status-based filtering
- Sorting operations
- Category filtering
- Filter chaining for complex queries

### Key Features

#### 1. Date Range Filtering

Filter collections by predefined or custom date ranges:

```elixir
# Filter by predefined period
DataHelpers.filter_by_date_range(transactions, "last_month")
DataHelpers.filter_by_date_range(expenses, "last_3_months")
DataHelpers.filter_by_date_range(records, "ytd")

# Supported periods:
# - "last_month", "last_3_months", "last_6_months"
# - "ytd" (year to date), "last_year"
# - "all" (no filtering)
```

#### 2. Grouping Operations

Group collections by various fields:

```elixir
# Group by account
grouped = DataHelpers.group_by_field(transactions, :account_id)

# Group by category
grouped = DataHelpers.group_by_field(expenses, :category_id)

# Group by custom field
grouped = DataHelpers.group_by_field(items, :custom_field)
```

#### 3. Status Filtering

Filter collections by status with support for multiple status representations:

```elixir
# Filter for active items
active = DataHelpers.filter_by_status(goals, "active", :status)

# Filter for paused items
paused = DataHelpers.filter_by_status(subscriptions, "paused", :status)

# Filter for completed items
completed = DataHelpers.filter_by_status(tasks, "completed", :status)
```

#### 4. Type Guards

The module provides type guard functions for common status checks:

```elixir
# Check if an item is active
DataHelpers.is_active?(%{is_active: true})  # => true
DataHelpers.is_active?(%{is_active: false}) # => false
DataHelpers.is_active?(%{status: :active})  # => false (requires is_active field)
```

#### 5. Aggregation Functions

Calculate sums with automatic Decimal handling:

```elixir
# Sum with field extraction
total = DataHelpers.sum_collection(transactions, :amount)

# Sum with custom extractor function
total = DataHelpers.sum_collection(items, fn item -> 
  Decimal.mult(item.quantity, item.price) 
end)
```

#### 6. Sorting

Sort collections with flexible field extraction:

```elixir
# Sort by field
sorted = DataHelpers.sort_collection(transactions, :date, :desc)
sorted = DataHelpers.sort_collection(accounts, :name, :asc)

# Sort with custom extractor
sorted = DataHelpers.sort_collection(items, 
  fn item -> item.priority end, :desc)
```

#### 7. Filter Chaining

Chain multiple filters for complex queries:

```elixir
result = DataHelpers.apply_filters(transactions, [
  {:date_range, "last_month"},
  {:status, "completed", :status},
  {:category, category_id, :category_id},
  {:sort, :amount, :desc}
])
```

## Usage Examples

### LiveView Integration

Here's how DataHelpers simplifies LiveView implementations:

#### Before (Duplicate Code)
```elixir
# In ExpenseLive.Analytics
defp filter_by_date_range(expenses, "last_month") do
  end_date = Date.utc_today()
  start_date = Date.add(end_date, -30)
  
  Enum.filter(expenses, fn expense ->
    case expense.date do
      nil -> false
      date ->
        Date.compare(date, start_date) != :lt &&
        Date.compare(date, end_date) != :gt
    end
  end)
end
```

#### After (Using DataHelpers)
```elixir
# In ExpenseLive.Analytics
defp apply_expense_filters(expenses, filters) do
  expenses
  |> DataHelpers.filter_by_date_range(filters["period"])
  |> DataHelpers.filter_by_category_id(filters["category"], :category_id)
end
```

### Common Patterns

#### Dashboard Calculations
```elixir
# Calculate totals for different account types
def calculate_account_totals(accounts) do
  accounts
  |> DataHelpers.filter_by_status("active", :status)
  |> DataHelpers.group_by_field(:account_type)
  |> Enum.map(fn {type, accounts} ->
    {type, DataHelpers.sum_collection(accounts, :current_value)}
  end)
  |> Map.new()
end
```

#### Transaction Analysis
```elixir
# Analyze recent transactions by category
def analyze_recent_transactions(transactions) do
  transactions
  |> DataHelpers.filter_by_date_range("last_3_months")
  |> DataHelpers.group_by_field(:category_id)
  |> Enum.map(fn {category_id, txns} ->
    %{
      category_id: category_id,
      total: DataHelpers.sum_collection(txns, :amount),
      count: length(txns),
      transactions: DataHelpers.sort_collection(txns, :date, :desc)
    }
  end)
end
```

#### Goal Tracking
```elixir
# Track active goals progress
def track_active_goals(goals) do
  goals
  |> Enum.filter(&DataHelpers.is_active?/1)
  |> DataHelpers.sort_collection(:target_date, :asc)
  |> Enum.map(fn goal ->
    Map.put(goal, :progress_percentage, 
      calculate_progress(goal.current_amount, goal.target_amount))
  end)
end
```

## Testing

The DataHelpers module includes comprehensive test coverage. Run tests with:

```bash
mix test test/ashfolio/data_helpers_test.exs
```

Key test areas:
- Date range filtering edge cases
- Grouping with various data types
- Sum calculations with Decimal precision
- Status filtering with different formats
- Filter chaining combinations

## Performance Considerations

1. **Lazy Evaluation**: When possible, use Stream operations for large datasets
2. **Indexed Fields**: Ensure database indexes exist for commonly filtered fields
3. **Caching**: Consider caching results for expensive grouping operations
4. **Decimal Operations**: All financial calculations use Decimal for precision

## Migration Guide

When refactoring existing code to use DataHelpers:

1. **Identify Patterns**: Look for repetitive filtering/grouping logic
2. **Test First**: Ensure existing tests pass before refactoring
3. **Incremental Changes**: Refactor one function at a time
4. **Verify Results**: Compare outputs to ensure identical behavior
5. **Remove Duplicates**: Delete the old implementation after verification

## Future Enhancements

Planned additions to DataHelpers:

- [ ] Pagination utilities
- [ ] Advanced date range builders (custom ranges)
- [ ] Memoization for expensive operations
- [ ] Parallel processing for large collections
- [ ] SQL query generation for common patterns

## Related Documentation

- [Architecture Overview](./architecture.md) - System architecture and data flow
- [Phoenix LiveView Layouts](./phoenix-liveview-layouts.md) - LiveView patterns and best practices
- [Testing Strategy](../TESTING_STRATEGY.md) - Testing approaches for data utilities