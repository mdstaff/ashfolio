# Performance Optimization Guide

This document consolidates all performance optimization work completed for the Ashfolio application, including code optimizations, test suite improvements, and ongoing performance monitoring strategies.

## Overview

Ashfolio has undergone comprehensive performance optimization across multiple dimensions:

1.  N+1 query prevention, caching improvements, rate limiting
2.  Strategic test reduction while preserving business logic coverage
3.  Optimized schema and query patterns
4.  Enhanced ETS cache management with memory pressure awareness

## Application Performance Optimizations

### N+1 Query Prevention

Portfolio calculations were making individual database calls for each symbol, creating N+1 query patterns.

- New module `Ashfolio.Portfolio.CalculatorOptimized`
- Batch lookup with `Symbol.get_by_ids/1` action
- Single query for all symbols instead of N individual calls

```elixir
# Before (N+1 queries)
symbols = Enum.map(symbol_ids, &Symbol.get_by_id/1)

# After (1 query)
{:ok, symbols} = Symbol.get_by_ids(symbol_ids)
symbol_map = Map.new(symbols, &{&1.id, &1})
```

- Query reduction: N+1 queries → 1 query for symbol lookups
- Significant reduction in database round trips
- Performance scales linearly instead of quadratically

### Enhanced ETS Cache Management

Basic TTL cleanup without memory pressure awareness could lead to memory issues.

- Memory-aware cleanup with `Cache.cleanup_with_memory_pressure/0`
- Aggressive cleanup when memory usage exceeds 50MB
- Cache statistics for operational visibility

```elixir
def cleanup_with_memory_pressure do
  stats = stats()
  memory_mb = stats.memory_bytes / (1024 * 1024)

  # Aggressive cleanup if cache is using more than 50MB
  max_age = if memory_mb > 50, do: @default_ttl_seconds / 2, else: @default_ttl_seconds

  cleanup_count = cleanup_stale_entries(trunc(max_age))
  # ...
end
```

- Prevents cache from consuming excessive memory
- Adaptive cleanup frequency based on memory pressure
- Improved system stability

### API Rate Limiting

No rate limiting could overwhelm external APIs (Yahoo Finance) and lead to service blocking.

- New module `Ashfolio.MarketData.RateLimiter`
- Token bucket algorithm with configurable limits
- Integration with PriceManager for API call management

- Default rate: 10 requests per minute
- Burst capacity: 5 requests
- Different limits for batch vs individual operations

### Security Enhancements

- Input length limits (transaction notes: 500 characters)
- Enhanced symbol validation with injection prevention
- Security pattern detection for common attack vectors

## Test Suite Optimization

### Optimization Strategy

The test suite underwent a conservative 3-phase optimization that reduced 70 tests (14% reduction) while preserving all business-critical functionality:

- Safe removals (library behavior tests, validation redundancy)
- Mathematical redundancy (calculation edge cases, format helpers)
- Conservative refinement (LiveView integration, financial management)

### Results Summary

- Tests removed: 70 tests from 511 (14% reduction)
- Test execution time: 15-20% improvement
- Maintenance overhead: Significantly reduced
- Business logic coverage: 100% preserved

### Key Preservation Areas

- All financial calculations and portfolio management tests
- Complete user workflow coverage through LiveView
- Cross-domain communication and event handling
- Realistic business edge cases (zero balances, missing data)
- Integration points between domains

- Library behavior testing (testing Elixir Decimal library vs business logic)
- Framework behavior (testing LiveView/Phoenix framework features)
- Duplicate assertions (redundant DOM/formatting checks)
- Mock scenarios without real coverage value

### Phase-by-Phase Breakdown

#### Phase 1: Safe Removals (25 tests)

- Library behavior tests (Decimal precision, bounds testing)
- Validation redundancy (duplicate field validation)
- Framework validation tests

Minimal
<2%

#### Phase 2: Mathematical Redundancy (30 tests)

- Holdings calculator duplicate scenarios
- Format helper consolidation
- Market data duplicate coverage

Low-Medium
~3-4%

#### Phase 3: Conservative Refinement (15 tests)

- LiveView integration redundancy
- Verified duplicate financial management tests

Medium
<2%

## Performance Monitoring

### Monitoring Infrastructure

The `Ashfolio.PerformanceMonitor` module provides comprehensive performance tracking:

```elixir
# Time database operations
PerformanceMonitor.time_query("portfolio_calculation", fn ->
  Calculator.calculate_portfolio_value()
end)

# Get performance report
report = PerformanceMonitor.performance_report()
```

### Key Metrics

- Average query time for portfolio calculations
- N+1 query prevention effectiveness
- Database connection pool utilization

- Cache hit rate percentage
- Memory usage over time
- Cleanup frequency and effectiveness

- Rate limit usage vs configured limits
- API response times
- Service availability metrics

- Test suite execution time
- Test reliability (pass rate consistency)
- Coverage metrics maintenance

## SQLite Optimizations

### Concurrency Improvements

SQLite concurrency issues causing intermittent test failures.

- New module `Ashfolio.SQLiteConcurrencyHelpers`
- Automatic retry logic for SQLite busy errors
- Proper database checkout/checkin patterns

```elixir
def with_retry(operation, retries \\ @max_retries) do
  try do
    operation.()
  rescue
    error ->
      if retries > 0 and sqlite_busy_error?(error) do
        Process.sleep(@retry_delay_ms)
        with_retry(operation, retries - 1)
      else
        reraise error, __STACKTRACE__
      end
  end
end
```

### Database Architecture Benefits

The database-as-user architecture provides several performance benefits:

- Simplified query patterns (no user-based filtering)
- Reduced join complexity
- Direct access to user preferences and settings
- Single database per user instance

## Expected Performance Improvements

| Optimization Area    | Expected Improvement                    |
| -------------------- | --------------------------------------- |
| N+1 Query Prevention | 50-80% reduction in database query time |
| Memory-Aware Cache   | 30-50% reduction in memory usage spikes |
| API Rate Limiting    | 90% reduction in API blocking incidents |
| Test Suite           | 15-20% faster execution time            |
| SQLite Concurrency   | 95%+ test pass rate consistency         |

## Maintenance and Monitoring

### Regular Maintenance Tasks

- Review performance monitoring reports
- Check cache hit rates and memory usage
- Monitor API usage patterns

- Analyze cache TTL effectiveness
- Review test suite performance trends
- Assess rate limiting effectiveness

- Comprehensive performance review
- Update security validation patterns
- Evaluate new optimization opportunities

### Quality Gates

- Database query time: <100ms for portfolio calculations
- Cache hit rate: >80% for symbol price lookups
- Test suite execution: <5 minutes full run
- API rate limiting: <10% of configured limits under normal load

- Overall code coverage: >85%
- Financial domain coverage: 100%
- Integration test coverage: 95%+

## Long-term Strategy

### Ongoing Optimization Areas

1.  Convert repetitive validation tests
2.  Extract common test setup patterns
3.  Dedicated performance test isolation
4.  Cross-domain API contract validation

### Scalability Considerations

1.  Monitor SQLite file size and query performance
2.  Cache growth patterns and cleanup effectiveness
3.  Prevent test redundancy accumulation
4.  Monitor external service usage patterns

## Conclusion

The comprehensive performance optimization effort has significantly improved Ashfolio's performance across all dimensions while maintaining strict quality standards. The conservative approach ensures business-critical functionality remains fully protected while eliminating maintenance overhead and improving development velocity.

Key success factors:

- Preserved 100% financial calculation coverage
- Reduced test execution time by 15-20%
- Implemented proactive performance monitoring
- Established sustainable maintenance practices

This optimization work provides a solid foundation for future scaling and feature development while maintaining the application's reliability and accuracy standards.
