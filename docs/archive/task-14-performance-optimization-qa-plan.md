# Task 14: Performance Optimization QA Testing Plan

## Overview

This comprehensive QA testing plan ensures that all performance optimizations in Task 14 are thoroughly validated while maintaining system stability and backward compatibility with v0.1.0 functionality.

Performance Targets:

- Database queries: 20-50% improvement
- Net worth calculation: Under 100ms
- Symbol search cache: 80%+ hit rate, <10ms cache hits
- Transaction filtering: Under 50ms for 1000+ transactions
- LiveView updates: Under 50ms latency

## Testing Framework Integration

### Existing Test Infrastructure

- Justfile Commands: Use `just test-performance`, `just test-slow`, `just test-integration`
- Test Tags: `@moduletag :performance`, `@moduletag :slow`, `@moduletag :benchmark`
- Performance Module: Leverage existing `Ashfolio.PerformanceMonitor`
- Cache Infrastructure: Build on existing `Ashfolio.Cache` and symbol search cache
- Database Setup: Use `SQLiteHelpers` for consistent test data

### Test Data Volumes

- Small: 10 accounts, 100 transactions, 20 symbols
- Medium: 50 accounts, 1000 transactions, 100 symbols
- Large: 100 accounts, 5000 transactions, 500 symbols

## Stage 1: Database Index Performance Analysis

### Test Cases

#### 1.1 Index Creation Validation

```elixir
@moduletag :performance
@moduletag :database
test "database indexes are created correctly" do
  # Verify indexes exist for account_type, category_id, symbol_id
  indexes = get_database_indexes()

  assert has_index?(indexes, "accounts", "account_type")
  assert has_index?(indexes, "transactions", "category_id")
  assert has_index?(indexes, "transactions", "symbol_id")
  assert has_index?(indexes, "transactions", "account_id")
end
```

#### 1.2 Query Performance with Indexes

```elixir
test "account type filtering shows performance improvement" do
  create_test_accounts(100) # Mixed investment/cash accounts

  # Measure pre-optimization baseline
  {baseline_time, _} = :timer.tc(fn ->
    Account.by_type(:investment)
  end)

  # Should be under 20ms with proper indexing
  assert baseline_time / 1000 < 20
end
```

#### 1.3 Transaction Filtering Performance

```elixir
test "category-based transaction filtering performs within targets" do
  create_test_transactions(1000)
  category = create_test_category()

  {filter_time, results} = :timer.tc(fn ->
    Transaction.by_category(category.id)
  end)

  time_ms = filter_time / 1000

  # Should filter 1000+ transactions under 50ms
  assert time_ms < 50
  assert length(results) > 0
end
```

### Acceptance Criteria

- [ ] All planned indexes are created and queryable
- [ ] Account type queries show 20-50% improvement over baseline
- [ ] Transaction filtering handles 1000+ records under 50ms
- [ ] No query regression on existing functionality

## Stage 2: Net Worth Calculation Batch Loading

### Test Cases

#### 2.1 Batch Loading Efficiency

```elixir
@moduletag :performance
test "net worth calculation uses batch loading for accounts" do
  user = create_user_with_accounts(20) # Mix of investment/cash
  create_test_holdings_for_user(user, 50)

  # Monitor query count to prevent N+1
  query_count = count_database_queries(fn ->
    {:ok, result} = NetWorthCalculator.calculate_net_worth()
    assert Decimal.compare(result.net_worth, 0) == :gt
  end)

  # Should use minimal queries regardless of account count
  assert query_count <= 5
end
```

#### 2.2 Performance Target Validation

```elixir
test "net worth calculation completes under 100ms" do
  user = create_complex_portfolio_user(50) # 50 accounts, 200 transactions

  {calc_time, {:ok, result}} = :timer.tc(fn ->
    NetWorthCalculator.calculate_net_worth()
  end)

  time_ms = calc_time / 1000

  # Must meet 100ms target
  assert time_ms < 100
  assert is_map(result.breakdown)
  assert Decimal.is_decimal(result.net_worth)
end
```

#### 2.3 Memory Efficiency

```elixir
test "net worth calculation maintains reasonable memory usage" do
  user = create_large_portfolio_user(100) # 100 accounts

  initial_memory = :erlang.memory(:total)

  {:ok, _result} = NetWorthCalculator.calculate_net_worth()

  :erlang.garbage_collect()
  final_memory = :erlang.memory(:total)

  memory_increase_mb = (final_memory - initial_memory) / (1024 * 1024)

  # Should not use excessive memory
  assert memory_increase_mb < 20
end
```

### Acceptance Criteria

- [ ] Net worth calculation consistently under 100ms
- [ ] Batch loading eliminates N+1 queries
- [ ] Memory usage remains under 20MB for large portfolios
- [ ] Calculation accuracy maintained across all account types

## Stage 3: Symbol Search ETS Cache Enhancement

### Test Cases

#### 3.1 Cache Hit Rate Validation

```elixir
@moduletag :performance
@moduletag :cache
test "symbol search achieves 80%+ cache hit rate" do
  # Prime cache with common searches
  common_symbols = ["AAPL", "MSFT", "GOOGL", "TSLA", "AMZN"]
  Enum.each(common_symbols, &SymbolSearch.search/1)

  # Perform 100 mixed searches (80% repeats, 20% new)
  searches = generate_mixed_search_queries(100, 0.8)

  {hit_count, total_count} = measure_cache_hits(searches)
  hit_rate = hit_count / total_count

  assert hit_rate >= 0.8
end
```

#### 3.2 Cache Performance Timing

```elixir
test "cache hits complete under 10ms" do
  query = "AAPL"

  # Prime cache
  SymbolSearch.search(query)

  # Measure cache hit time
  {hit_time, {:ok, _results}} = :timer.tc(fn ->
    SymbolSearch.search(query)
  end)

  time_ms = hit_time / 1000
  assert time_ms < 10
end
```

#### 3.3 LRU Eviction Testing

```elixir
test "LRU eviction maintains cache performance under memory pressure" do
  # Fill cache beyond capacity
  fill_cache_beyond_capacity()

  # Verify LRU eviction works
  assert cache_size_within_limits?()

  # Verify recent entries remain cached
  recent_query = "RECENT_SEARCH"
  SymbolSearch.search(recent_query)

  trigger_cache_pressure()

  assert SymbolSearch.cache_hit?(recent_query)
end
```

### Acceptance Criteria

- [ ] Cache hit rate consistently above 80%
- [ ] Cache hits complete under 10ms
- [ ] LRU eviction prevents unbounded memory growth
- [ ] Cache survives high-volume concurrent access

## Stage 4: Transaction Filtering Query Optimization

### Test Cases

#### 4.1 Large Dataset Filtering

```elixir
@moduletag :performance
test "transaction filtering handles 1000+ transactions efficiently" do
  account = create_account()
  transactions = create_test_transactions(1500, account.id)
  category = create_test_category()

  # Tag some transactions with category
  tag_transactions_with_category(transactions, category, 0.3)

  {filter_time, filtered} = :timer.tc(fn ->
    TransactionFiltering.filter_by_category(account.id, category.id)
  end)

  time_ms = filter_time / 1000

  assert time_ms < 50
  assert length(filtered) > 400  # ~30% of 1500
end
```

#### 4.2 Multi-Filter Performance

```elixir
test "complex filtering with multiple criteria performs efficiently" do
  setup_complex_transaction_dataset(2000)

  filters = %{
    date_range: {~D[2025-01-01], ~D[2025-12-31]},
    categories: [category1.id, category2.id],
    transaction_types: [:buy, :sell],
    amount_range: {Decimal.new("100"), Decimal.new("10000")}
  }

  {filter_time, results} = :timer.tc(fn ->
    TransactionFiltering.apply_filters(account.id, filters)
  end)

  time_ms = filter_time / 1000

  assert time_ms < 75  # Allow more time for complex filtering
  assert length(results) > 0
end
```

#### 4.3 Database Query Optimization

```elixir
test "transaction filtering uses optimized database queries" do
  create_test_transactions(1000)

  query_count = count_database_queries(fn ->
    TransactionFiltering.filter_by_multiple_criteria(filters)
  end)

  # Should use single optimized query, not multiple
  assert query_count <= 2
end
```

### Acceptance Criteria

- [ ] Filtering 1000+ transactions completes under 50ms
- [ ] Complex multi-criteria filtering under 75ms
- [ ] Database queries are properly optimized (≤2 queries)
- [ ] Filter accuracy maintained for all criteria combinations

## Stage 5: LiveView Update Performance

### Test Cases

#### 5.1 Selective DOM Update Testing

```elixir
@moduletag :liveview
@moduletag :performance
test "dashboard updates only affect changed components" do
  {:ok, view, _html} = live(conn, "/")

  # Monitor DOM patches for selective updates
  initial_patches = get_dom_patch_count(view)

  # Trigger balance update
  BalanceManager.update_cash_balance(account.id, new_balance, "Test update")

  # Should only update net worth component, not entire page
  updated_patches = get_dom_patch_count(view) - initial_patches

  assert updated_patches < 5  # Minimal DOM changes
end
```

#### 5.2 Update Latency Validation

```elixir
test "liveview updates complete under 50ms" do
  {:ok, view, _html} = live(conn, "/dashboard")

  start_time = System.monotonic_time(:microsecond)

  # Trigger real-time update
  send_pubsub_update()

  # Wait for DOM update
  assert_receive({:live_patch, _}, 100)

  end_time = System.monotonic_time(:microsecond)
  latency_ms = (end_time - start_time) / 1000

  assert latency_ms < 50
end
```

#### 5.3 Debouncing Effectiveness

```elixir
test "rapid updates are properly debounced" do
  {:ok, view, _html} = live(conn, "/")

  # Send rapid updates
  for i <- 1..10 do
    send_rapid_update(i)
    :timer.sleep(10)  # 10ms intervals
  end

  # Should only process debounced updates
  processed_updates = count_processed_updates(view)

  assert processed_updates < 5  # Significantly fewer than sent
end
```

### Acceptance Criteria

- [ ] LiveView updates complete under 50ms latency
- [ ] Selective DOM updates minimize re-rendering
- [ ] Debouncing prevents update storms
- [ ] Real-time features remain responsive under load

## Stage 6: Critical Path Benchmarks

### Test Cases

#### 6.1 End-to-End Performance Benchmarks

```elixir
@moduletag :performance
@moduletag :integration
test "complete dashboard load performs within targets" do
  setup_realistic_portfolio_data()

  {total_time, {:ok, view, html}} = :timer.tc(fn ->
    live(conn, "/")
  end)

  time_ms = total_time / 1000

  # Complete dashboard load under 500ms
  assert time_ms < 500
  assert html =~ "Net Worth"
  assert has_element?(view, "[data-testid='portfolio-summary']")
end
```

#### 6.2 Transaction Creation Performance

```elixir
test "transaction creation with symbol autocomplete performs efficiently" do
  {:ok, view, _html} = live(conn, "/transactions/new")

  {form_time, _result} = :timer.tc(fn ->
    view
    |> form("#transaction-form", transaction: valid_transaction_attrs())
    |> render_submit()
  end)

  time_ms = form_time / 1000

  assert time_ms < 200  # Form submission under 200ms
end
```

#### 6.3 Portfolio Calculation Benchmarks

```elixir
test "portfolio calculations maintain performance across data sizes" do
  data_sizes = [10, 50, 100, 500]

  Enum.each(data_sizes, fn size ->
    user = create_user_with_portfolio(size)

    {calc_time, {:ok, _result}} = :timer.tc(fn ->
      Calculator.calculate_total_return()
    end)

    time_ms = calc_time / 1000

    # Linear scaling - should stay under 100ms even for large portfolios
    assert time_ms < 100, "Portfolio calculation for #{size} items took #{time_ms}ms"
  end)
end
```

### Acceptance Criteria

- [ ] Dashboard loads consistently under 500ms
- [ ] Transaction operations complete under 200ms
- [ ] Portfolio calculations scale linearly
- [ ] No performance regression under various data loads

## Stage 7: Performance Validation

### Test Cases

#### 7.1 Regression Testing

```elixir
@moduletag :regression
@moduletag :performance
test "performance optimizations don't break existing functionality" do
  # Run subset of v0.1.0 core functionality tests
  run_v0_1_0_regression_suite()

  # Verify all original features still work
  assert_v0_1_0_functionality_intact()
end
```

#### 7.2 Load Testing

```elixir
test "system handles concurrent user simulation" do
  # Simulate 10 concurrent users
  tasks = for i <- 1..10 do
    Task.async(fn ->
      user = create_test_user("user_#{i}")
      simulate_user_session(user)
    end)
  end

  results = Task.await_many(tasks, 30_000)

  # All concurrent sessions should complete successfully
  assert Enum.all?(results, &match?({:ok, _}, &1))
end
```

#### 7.3 Memory Leak Detection

```elixir
test "extended operation doesn't cause memory leaks" do
  initial_memory = :erlang.memory(:total)

  # Perform 1000 operations
  for _i <- 1..1000 do
    perform_portfolio_operation()

    # Periodic cleanup
    if rem(_i, 100) == 0 do
      :erlang.garbage_collect()
    end
  end

  :erlang.garbage_collect()
  final_memory = :erlang.memory(:total)

  memory_growth_mb = (final_memory - initial_memory) / (1024 * 1024)

  # Should not grow memory significantly
  assert memory_growth_mb < 50
end
```

### Acceptance Criteria

- [ ] All v0.1.0 regression tests pass
- [ ] System handles concurrent load without degradation
- [ ] No memory leaks detected during extended operation
- [ ] Performance metrics meet or exceed targets

## Test Execution Strategy

### Test Categories and Execution Order

1. Unit Performance Tests (`just test-performance`)

   - Individual component performance
   - Cache behavior validation
   - Query optimization verification

2. Integration Performance Tests (`just test-slow`)

   - End-to-end performance scenarios
   - Cross-component interaction testing
   - Real-world data volume testing

3. Regression Tests (`just test-regression`)

   - v0.1.0 functionality preservation
   - Backward compatibility validation
   - Data integrity verification

4. Load Tests (Manual execution)
   - Concurrent user simulation
   - System stress testing
   - Resource utilization monitoring

### Continuous Monitoring

```elixir
# Add to existing performance benchmark test
test "performance monitoring and alerting" do
  report = PerformanceMonitor.performance_report()

  # Verify key metrics
  assert report.cache.cache_size > 0
  assert report.cache.memory_mb < 100  # Cache memory limit
  assert report.system.process_count < 10000  # Process limit

  # Log performance baseline for regression detection
  log_performance_baseline(report)
end
```

### Load Testing Scenarios

#### Scenario 1: Heavy Dashboard Usage

- 10 concurrent users accessing dashboard
- Mixed portfolio sizes (10-500 transactions)
- Real-time updates active

#### Scenario 2: Symbol Search Stress Test

- 50 concurrent symbol searches
- Mix of cached and uncached queries
- Cache hit rate monitoring

#### Scenario 3: Transaction Creation Load

- 20 users creating transactions simultaneously
- Symbol autocomplete usage
- Category selection and filtering

## Success Metrics and Reporting

### Performance KPIs

- Database Query Time: 20-50% improvement over baseline
- Net Worth Calculation: <100ms consistently
- Symbol Search Cache Hit Rate: >80%
- Cache Response Time: <10ms for hits
- Transaction Filtering: <50ms for 1000+ records
- LiveView Update Latency: <50ms
- Dashboard Load Time: <500ms
- Memory Usage: No leaks, reasonable growth bounds

### Test Reporting

```bash
# Generate performance report
just test-performance 2>&1 | grep -E "(ms|MB|rate)" > performance_report.txt

# Generate coverage with performance focus
just test-coverage-clean | grep -A 10 "Performance"

# Memory usage monitoring
just test-slow 2>&1 | grep -E "(memory|Memory)" > memory_report.txt
```

### Automated Performance Validation

Create dedicated justfile commands for performance testing:

```bash
# Add to justfile
test-performance-stage STAGE:
    @echo "🚀 Testing performance optimizations for Stage {{STAGE}}..."
    @MIX_ENV=test mix test --only performance_stage_{{STAGE}}

test-performance-all:
    @echo "🚀 Running complete performance test suite..."
    @just test-performance
    @just test-slow
    @echo "📊 Performance validation complete!"

benchmark-critical-paths:
    @echo "📈 Benchmarking critical application paths..."
    @MIX_ENV=test mix test test/integration/performance_benchmarks_test.exs --trace
```

## Risk Mitigation

### Performance Regression Detection

- Establish baseline metrics before optimization
- Compare post-optimization metrics to baselines
- Alert on any performance degradation >10%

### Data Integrity Safeguards

- Run data validation tests after each optimization
- Verify calculation accuracy across all optimizations
- Test edge cases and boundary conditions

### Rollback Procedures

- Maintain feature flags for new optimizations
- Document rollback steps for each optimization stage
- Test rollback procedures in staging environment

This comprehensive QA testing plan ensures that Task 14's performance optimizations deliver measurable improvements while maintaining the rock-solid reliability that characterizes the Ashfolio project.
