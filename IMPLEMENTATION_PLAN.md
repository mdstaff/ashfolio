# Task 14: Performance Optimizations Implementation Plan

## Goal

Implement comprehensive performance optimizations for the v0.2.0 feature set, targeting measurable improvements in database query performance, LiveView responsiveness, and overall application speed while maintaining architectural integrity.

## Success Criteria

- Database query performance improvements of 20-50% for critical paths
- LiveView update latency under 50ms for real-time features
- Symbol search cache hit rate above 80% for common queries
- Net worth calculation time under 100ms for realistic portfolios
- Zero performance regressions in existing v0.1.0 functionality

## Performance Metrics Baseline

- Portfolio calculation: ~80-120ms (target: <100ms)
- Net worth calculation: ~150-200ms (target: <100ms)
- Dashboard load: ~300-400ms (target: <300ms)
- Symbol search: ~50-80ms uncached (target: cache hits <10ms)
- Transaction filtering: ~100-150ms (target: <50ms)

---

## Stage 1: Database Index Performance Analysis and Testing

**Goal**: Establish comprehensive performance testing framework and optimize database indexes

**Success Criteria**:

- Performance test suite passes with measurable improvements
- Critical query performance improved by 20-30%
- Database index coverage analysis complete

**Tests**: Performance benchmark suite with before/after metrics

**Status**: Complete

### TDD Steps:

1. **Write failing performance test** for current query patterns:

   ```elixir
   # test/performance/database_performance_test.exs
   test "account type filtering performance under 20ms" do
     # Measure current Account.cash_accounts() performance
     # Assert baseline and improvement targets
   end
   ```

2. **Write failing test** for category-based transaction filtering:

   ```elixir
   test "category transaction filtering under 25ms with 1000+ transactions" do
     # Create 1000+ test transactions with categories
     # Measure TransactionFiltering.apply_filters performance
   end
   ```

3. **Implement database index analysis** to identify missing indexes

4. **Add strategic indexes** beyond existing v0.2.0 indexes:

   - Composite indexes for common query patterns
   - Covering indexes for frequently accessed columns

5. **Run performance benchmarks** to validate improvements

## Stage 2: Net Worth Calculation Batch Loading Optimization

**Goal**: Optimize net worth calculations through batch loading and query reduction

**Success Criteria**:

- Net worth calculation time under 100ms for realistic portfolios
- Query count reduced by 50% for net worth calculations
- Batch loading implemented for account data

**Tests**: NetWorthCalculator performance tests with realistic data volumes

**Status**: Complete

### TDD Steps:

1. **Write failing performance test** for current net worth calculation:

   ```elixir
   test "net worth calculation under 100ms with 20 accounts" do
     # Create realistic test data: 10 investment + 10 cash accounts
     # Measure NetWorthCalculator.calculate_net_worth performance
   end
   ```

2. **Write test for batch loading** account data:

   ```elixir
   test "batch loads all account data in single query" do
     # Test that calculate_account_breakdown uses batch loading
     # Verify SQL query count reduction
   end
   ```

3. **Implement batch loading** in NetWorthCalculator:

   - Replace individual account queries with batch operations
   - Add preloading for related data (transactions, symbols)

4. **Add query optimization** for account type filtering:

   - Use database views for complex calculations
   - Implement result caching for expensive operations

5. **Validate performance improvements** against baseline metrics

## Stage 3: Symbol Search ETS Cache Enhancement

**Goal**: Enhance symbol search performance through intelligent ETS caching strategies

**Success Criteria**:

- Symbol search cache hit rate above 80%
- Cache miss performance under 50ms
- Memory usage for cache under 10MB

**Tests**: SymbolSearch cache performance and memory tests

**Status**: Complete

### TDD Steps:

1. **Write failing test** for cache hit rate optimization:

   ```elixir
   test "symbol search achieves 80%+ cache hit rate with realistic usage" do
     # Simulate realistic search patterns
     # Measure cache hit/miss ratios
   end
   ```

2. **Write test for cache memory management**:

   ```elixir
   test "symbol search cache memory usage under 10MB" do
     # Fill cache with realistic data
     # Measure ETS memory consumption
   end
   ```

3. **Implement intelligent cache warming**:

   - Pre-populate cache with popular symbols
   - Add background cache refresh for frequently accessed symbols

4. **Add cache partitioning** for better memory management:

   - Separate caches for different search types
   - LRU eviction for memory-constrained environments

5. **Implement cache metrics** and monitoring for production insights

## Stage 4: Transaction Filtering Query Optimization

**Goal**: Optimize category-based transaction filtering for large datasets

**Success Criteria**:

- Transaction filtering under 50ms for 1000+ transactions
- Category-based queries use proper database indexes
- Filter state management optimized for LiveView updates

**Tests**: TransactionFiltering performance with large datasets

**Status**: Complete

### TDD Steps:

1. **Write failing test** for large dataset filtering performance:

   ```elixir
   test "transaction filtering under 50ms with 1000+ transactions" do
     # Create 1000+ transactions across multiple categories
     # Measure TransactionFiltering.apply_filters performance
   end
   ```

2. **Write test for database index utilization**:

   ```elixir
   test "category filtering uses database indexes efficiently" do
     # Verify query execution plans use category_id index
     # Test composite index effectiveness
   end
   ```

3. **Implement query optimization** in TransactionFiltering:

   - Use database-level filtering instead of Elixir filtering
   - Add composite indexes for common filter combinations

4. **Add result caching** for expensive filter operations:

   - Cache filtered results in ETS
   - Implement cache invalidation on data changes

5. **Optimize LiveView state updates** for filtered data changes

## Stage 5: LiveView Update Performance Optimization

**Goal**: Optimize LiveView update performance for real-time features

**Success Criteria**:

- LiveView updates under 50ms latency
- PubSub message processing optimized
- Selective DOM updates for large lists

**Tests**: LiveView performance tests with concurrent updates

**Status**: Complete

### TDD Steps:

1. **Write failing test** for LiveView update latency:

   ```elixir
   test "dashboard LiveView updates under 50ms for real-time changes" do
     # Simulate PubSub messages for net worth updates
     # Measure LiveView processing time
   end
   ```

2. **Write test for selective DOM updates**:

   ```elixir
   test "transaction list updates only changed elements" do
     # Test that adding one transaction doesn't re-render entire list
     # Use DOM diffing to verify selective updates
   end
   ```

3. **Implement selective assign updates**:

   - Use Phoenix.Component.assign_new for expensive calculations
   - Add conditional rendering for unchanged data

4. **Optimize PubSub message handling**:

   - Batch multiple rapid updates
   - Implement debouncing for high-frequency updates

5. **Add performance monitoring** for LiveView render times

---

## Stage 6: Critical Path Performance Benchmarks

**Goal**: Establish comprehensive performance benchmarking for all critical calculation paths

**Success Criteria**:

- All critical paths meet performance targets
- Automated performance regression detection
- Performance metrics integrated into CI/CD

**Tests**: Comprehensive performance benchmark suite

**Status**: Complete

### TDD Steps:

1. **Write comprehensive benchmark suite**:

   ```elixir
   test "portfolio calculation benchmark suite" do
     # Test all Calculator functions with realistic data
     # Establish performance baselines and targets
   end
   ```

2. **Write performance regression tests**:

   ```elixir
   test "no performance regressions in v0.1.0 functionality" do
     # Verify existing features maintain performance
     # Compare against baseline metrics
   end
   ```

3. **Implement automated benchmarking**:

   - Add Benchee integration for detailed performance analysis
   - Create performance comparison reports

4. **Add performance monitoring** infrastructure:

   - Integrate Telemetry for production metrics
   - Add performance alerts for degradation detection

5. **Document performance optimization strategies** and maintenance procedures

---

## Stage 7: Performance Validation and Documentation

**Goal**: Validate all performance improvements and document optimization strategies

**Success Criteria**:

- All performance targets achieved
- Performance optimization guide created
- Monitoring and alerting configured

**Tests**: End-to-end performance validation

**Status**: Complete

### TDD Steps:

1. **Write end-to-end performance validation**:

   ```elixir
   test "complete application performance meets all targets" do
     # Test full user workflows for performance
     # Validate all individual targets in integrated scenarios
   end
   ```

2. **Write performance monitoring tests**:

   ```elixir
   test "performance monitoring captures key metrics" do
     # Verify Telemetry events are properly emitted
     # Test alerting for performance degradation
   end
   ```

3. **Run complete performance benchmark suite** against all targets

4. **Create performance optimization documentation**:

   - Document all optimization techniques used
   - Provide maintenance guidelines for performance

5. **Configure production monitoring** for ongoing performance tracking

## Technical Specifications

### Performance Optimization Architecture

#### Database Index Strategy

```sql
-- Additional strategic indexes for v0.2.0 performance
CREATE INDEX CONCURRENTLY idx_transactions_user_category_date
  ON transactions (category_id, date DESC);

-- Covering index for transaction filtering
CREATE INDEX CONCURRENTLY idx_transactions_filtering_cover
  ON transactions (category_id, type, date DESC)
  INCLUDE (symbol_id, quantity, price, total_amount);

-- Composite index for account performance queries
CREATE INDEX CONCURRENTLY idx_accounts_performance
  ON accounts (account_type, is_excluded)
  WHERE is_excluded = false;
```

#### NetWorthCalculator Batch Loading

```elixir
defmodule Ashfolio.FinancialManagement.NetWorthCalculator do
  # Optimized batch loading approach
  def calculate_net_worth_optimized() do
    # Single query with preloading
    accounts_query =
      from a in Account,
        where: a.user_id == ^user_id and not a.is_excluded,
        preload: [transactions: [:symbol]]

    accounts = Repo.all(accounts_query)

    # Process in memory rather than separate queries
    {investment_accounts, cash_accounts} =
      Enum.split_with(accounts, &(&1.account_type == :investment))

    # Parallel calculation of investment and cash values
    [investment_task, cash_task] =
      Task.async_stream([
        fn -> calculate_investment_value(investment_accounts) end,
        fn -> calculate_cash_value(cash_accounts) end
      ], timeout: 5000) |> Enum.to_list()

    {:ok, %{
      net_worth: Decimal.add(investment_task.result, cash_task.result),
      investment_value: investment_task.result,
      cash_value: cash_task.result
    }}
  end
end
```

#### SymbolSearch ETS Cache Enhancement

```elixir
defmodule Ashfolio.FinancialManagement.SymbolSearch.Cache do
  # Enhanced ETS cache with intelligent warming and LRU eviction

  @cache_table :ashfolio_symbol_search_cache_v2
  @popular_symbols_table :ashfolio_popular_symbols
  @max_cache_size 10_000  # Limit cache size for memory management

  def start_link(_opts) do
    :ets.new(@cache_table, [:named_table, :public, :ordered_set])
    :ets.new(@popular_symbols_table, [:named_table, :public, :set])
    warm_popular_symbols()
    {:ok, self()}
  end

  # Cache with LRU eviction
  def get_or_compute(cache_key, compute_fn) do
    case :ets.lookup(@cache_table, cache_key) do
      [{^cache_key, result, _access_time}] ->
        # Update access time for LRU
        :ets.insert(@cache_table, {cache_key, result, System.monotonic_time()})
        {:hit, result}

      [] ->
        result = compute_fn.()
        maybe_evict_lru()
        :ets.insert(@cache_table, {cache_key, result, System.monotonic_time()})
        {:miss, result}
    end
  end

  defp warm_popular_symbols do
    # Pre-populate cache with popular symbols (FAANG, etc.)
    popular = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "META", "NVDA"]
    Enum.each(popular, fn symbol ->
      spawn(fn -> search_and_cache(symbol) end)
    end)
  end

  defp maybe_evict_lru do
    if :ets.info(@cache_table, :size) > @max_cache_size do
      # Remove oldest 10% of entries
      evict_count = div(@max_cache_size, 10)
      oldest_entries =
        :ets.tab2list(@cache_table)
        |> Enum.sort_by(&elem(&1, 2))  # Sort by access time
        |> Enum.take(evict_count)

      Enum.each(oldest_entries, fn {key, _, _} ->
        :ets.delete(@cache_table, key)
      end)
    end
  end
end
```

#### Transaction Filtering Query Optimization

```elixir
defmodule Ashfolio.FinancialManagement.TransactionFiltering do
  # Optimized database-level filtering instead of Elixir-level

  def apply_filters_optimized(filters) do
    base_query =
      from t in Transaction,
        join: a in Account, on: t.account_id == a.id,
        left_join: c in TransactionCategory, on: t.category_id == c.id,
        preload: [account: a, category: c, symbol: :symbol]

    query =
      base_query
      |> filter_by_user(filters[:user_id])
      |> filter_by_category(filters[:category])
      |> filter_by_date_range(filters[:date_range])
      |> filter_by_type(filters[:type])
      |> order_by([t], desc: t.date, desc: t.inserted_at)

    # Use database for pagination and limiting
    transactions =
      query
      |> limit(^Map.get(filters, :limit, 1000))
      |> offset(^Map.get(filters, :offset, 0))
      |> Repo.all()

    {:ok, transactions}
  end

  # Database-level filtering functions
  defp filter_by_category(query, nil), do: query
  defp filter_by_category(query, :all), do: query
  defp filter_by_category(query, category_id) when is_binary(category_id) do
    from [t, a, c] in query,
      where: t.category_id == ^category_id
  end

  defp filter_by_date_range(query, nil), do: query
  defp filter_by_date_range(query, %{start_date: start_date, end_date: end_date}) do
    from [t, a, c] in query,
      where: t.date >= ^start_date and t.date <= ^end_date
  end
end
```

#### LiveView Performance Optimization

```elixir
defmodule AshfolioWeb.DashboardLive do
  # Optimized LiveView with selective updates and debouncing

  def handle_info({:net_worth_updated, _net_worth_data}, socket) do
    # Debounce rapid updates
    if socket.assigns[:update_timer] do
      Process.cancel_timer(socket.assigns.update_timer)
    end

    timer = Process.send_after(self(), {:apply_net_worth_update, net_worth_data}, 100)

    {:noreply, assign(socket, :update_timer, timer)}
  end

  def handle_info({:apply_net_worth_update, net_worth_data}, socket) do
    # Only update changed values to minimize DOM updates
    socket =
      socket
      |> assign_if_changed(:net_worth_total, format_currency(net_worth_data.total_net_worth))
      |> assign_if_changed(:net_worth_investment_value, format_currency(net_worth_data.investment_value))
      |> assign_if_changed(:net_worth_cash_balance, format_currency(net_worth_data.cash_balance))
      |> assign(:update_timer, nil)

    {:noreply, socket}
  end

  defp assign_if_changed(socket, key, new_value) do
    if Map.get(socket.assigns, key) != new_value do
      assign(socket, key, new_value)
    else
      socket
    end
  end
end
```

## Integration Points with Existing Code

### 1. Database Performance Integration

- **Extend existing migrations**: Add new performance indexes to migration files
- **SQLite optimization**: Leverage existing SQLite WAL mode and pragma settings
- **Index compatibility**: Ensure new indexes work with existing query patterns
- **Migration safety**: Use `CREATE INDEX CONCURRENTLY` patterns for zero-downtime updates

### 2. ETS Cache Integration

- **Extend SymbolSearch**: Enhance existing ETS cache in `SymbolSearch` module
- **Cache lifecycle**: Integrate with Application supervision tree
- **Memory management**: Add cache size monitoring to existing monitoring infrastructure
- **Cache invalidation**: Hook into existing PubSub patterns for data changes

### 3. Performance Testing Integration

- **Extend existing performance tests**: Build on `performance_benchmarks_test.exs`
- **Use existing test data**: Leverage SQLiteHelpers for consistent test data setup
- **Benchmark integration**: Add Benchee integration to existing test infrastructure
- **CI/CD integration**: Add performance regression detection to existing test workflows

## Performance Flow Architecture

### 1. Optimized Query Pipeline

```
User Request
  → Optimized database queries with strategic indexes
  → Batch loading with preloads for related data
  → ETS cache lookup for frequently accessed data
  → Parallel processing for independent calculations
  → Selective LiveView updates for changed data only
```

### 2. Cache-Optimized Symbol Search

```
Symbol Search Request
  → Check ETS cache (target: <10ms for cache hits)
  → Cache miss → Database query with indexes (target: <30ms)
  → External API fallback if needed (rate limited)
  → Cache result with LRU eviction
  → Return to user (total target: <50ms)
```

### 3. Batch-Optimized Net Worth Calculation

```
Net Worth Request
  → Single batch query for all user accounts (with preloads)
  → Parallel calculation of investment and cash values
  → In-memory processing instead of additional queries
  → Cache expensive calculations in ETS
  → PubSub broadcast with debouncing (target: <100ms total)
```

## Risk Assessment & Mitigation

### Risk 1: Database Index Maintenance Overhead

**Risk**: Additional indexes could slow down write operations and increase storage
**Mitigation**:

- Careful analysis of query patterns to identify only necessary indexes
- Use covering indexes to minimize index count while maximizing query performance
- Monitor SQLite database file size and query performance metrics

### Risk 2: ETS Cache Memory Consumption

**Risk**: Enhanced caching could consume excessive memory in production
**Mitigation**:

- Implement LRU eviction with configurable maximum cache sizes
- Monitor memory usage with Telemetry and add alerting
- Provide cache size tuning options for different deployment scenarios

### Risk 3: Performance Regression in Existing Features

**Risk**: Optimization changes could inadvertently slow down v0.1.0 functionality
**Mitigation**:

- Comprehensive performance regression testing for all existing features
- Maintain existing code paths as fallbacks during optimization rollout
- Automated performance benchmarking in CI/CD pipeline

### Risk 4: Complexity Increase from Optimization

**Risk**: Performance optimizations could make code harder to maintain
**Mitigation**:

- Focus on database-level optimizations before application-level complexity
- Document all optimization techniques and their trade-offs
- Maintain simple fallback paths for debugging and development

## Success Metrics

### Technical Performance Goals

1. **Database Query Performance**: 20-50% improvement in critical query response times
2. **Net Worth Calculation**: Under 100ms for realistic portfolios (20+ accounts)
3. **Symbol Search Cache**: 80%+ cache hit rate with <10ms response time for cache hits
4. **Transaction Filtering**: Under 50ms for 1000+ transactions with category filters
5. **LiveView Updates**: Under 50ms latency for real-time PubSub updates

### Memory and Resource Goals

1. **ETS Cache Memory**: Under 10MB memory usage for symbol search cache
2. **Database Size**: Minimal impact from additional indexes (<5% increase)
3. **Connection Efficiency**: Reduced database query count by 30-50% for complex operations
4. **CPU Usage**: No significant increase in baseline CPU utilization

### Reliability and Maintainability Goals

1. **Performance Regression**: Zero degradation in existing v0.1.0 functionality performance
2. **Test Coverage**: >95% coverage for performance-critical code paths
3. **Monitoring Integration**: Complete Telemetry coverage for all optimized operations
4. **Documentation**: Performance optimization guide and maintenance procedures

## Dependencies

### Completed (Tasks 1-13) ✅

- NetWorthCalculator with existing calculation logic
- SymbolSearch with basic ETS caching infrastructure
- TransactionFiltering with initial category support
- Database indexes from v0.2.0 implementation (basic coverage)
- Performance benchmarks test suite foundation

### Required for Task 14

- Enhanced database indexes for new query patterns
- Optimized NetWorthCalculator with batch loading
- Enhanced SymbolSearch ETS cache with LRU eviction
- Optimized TransactionFiltering with database-level filtering
- LiveView performance optimization for real-time features
- Comprehensive performance benchmarking and monitoring

## Out of Scope

- Database sharding or complex scaling strategies (v1.0+ feature)
- Advanced caching strategies beyond ETS (Redis, etc.)
- Database migration to PostgreSQL for performance (architectural decision)
- Complex query optimization beyond indexing (stored procedures, views)
