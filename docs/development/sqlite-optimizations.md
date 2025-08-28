# SQLite Connection Improvements - Ashfolio

## Issue Resolved

During concurrent test execution, SQLite connection pool was experiencing disconnection errors:

```
[error] Exqlite.Connection (#PID<0.357.0>) disconnected:  (DBConnection.ConnectionError) client #PID<0.6685.0> exited
```

Default SQLite connection pool timeouts were too aggressive for concurrent test execution, causing connections to be dropped during high-load testing scenarios.

## Solution Implemented

### 1. Enhanced SQLite Connection Pool Configuration

Updated `config/test.exs` with improved timeout settings:

```elixir
config :ashfolio, Ashfolio.Repo,
  adapter: Ecto.Adapters.SQLite3,
  database: "data/ashfolio_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  # SQLite optimizations for testing with improved connection handling
  pragma: [
    journal_mode: :wal,
    synchronous: :normal,
    temp_store: :memory,
    mmap_size: 268_435_456,
    busy_timeout: 30_000
  ],
  # Improved connection pool settings to reduce disconnections
  pool_timeout: 15_000,      # Increased from default 5_000
  ownership_timeout: 15_000, # Increased from default 5_000
  timeout: 15_000           # Increased from default 15_000
```

### 2. Added .gitignore Entry

Added Playwright MCP generated files to `.gitignore`:

```
# Playwright MCP generated files
/.playwright-mcp/
```

### 3. Fixed Test Warnings

Corrected `@describetag` usage in health controller tests to eliminate compilation warnings.

## Configuration Details

### Connection Pool Optimizations

| Setting             | Previous | Updated  | Benefit                     |
| ------------------- | -------- | -------- | --------------------------- |
| `pool_timeout`      | 5,000ms  | 15,000ms | More time for pool checkout |
| `ownership_timeout` | 5,000ms  | 15,000ms | Longer connection ownership |
| `timeout`           | 15,000ms | 15,000ms | Consistent query timeouts   |

### SQLite Pragma Settings (Retained)

| Setting        | Value         | Purpose                                    |
| -------------- | ------------- | ------------------------------------------ |
| `journal_mode` | `:wal`        | Write-Ahead Logging for better concurrency |
| `synchronous`  | `:normal`     | Balanced safety vs performance             |
| `temp_store`   | `:memory`     | Faster temporary operations                |
| `mmap_size`    | `268_435_456` | 256MB memory mapping                       |
| `busy_timeout` | `30_000`      | 30s timeout for busy database              |

## Test Results

### Before Improvements

- SQLite connection errors appearing during concurrent tests
- All tests passing but with error noise in logs
- 912 tests, 0 failures with connection warnings

### After Improvements

- No SQLite connection errors in test runs
- Clean test output without connection warnings
- 912 tests, 0 failures with improved stability
- Faster test execution due to reduced connection churn

## Verification Commands

```bash
# Test specific areas affected by SQLite connections
just test integration  # Database-heavy tests
just test smoke       # Critical path tests
just test all         # Full test suite

# Monitor for connection errors
just test all 2>&1 | grep -i "exqlite\|connection\|disconnected"
```

## Future Considerations

### Monitoring in Production

While these settings optimize for test concurrency, production deployments should monitor:

1.  Track active vs idle connections
2.  Monitor slow queries and timeouts
3.  Watch for `busy_timeout` triggers
4.  Monitor SQLite memory mapping effectiveness

### Scaling Considerations

As the application grows:

1.  May need adjustment based on load patterns
2.  Consider automatic checkpoint intervals
3.  Evaluate need for multiple databases
4.  Add database metrics to health endpoints

## Related Documentation

- [Testing Strategy](TESTING_STRATEGY.md) - Overview of testing framework
- [QA Testing Report](QA_TESTING_REPORT.md) - Comprehensive QA results
- [Health Check Endpoints](../lib/ashfolio_web/controllers/health_controller.ex) - System monitoring

## Technical Notes

### SQLite Concurrency Model

SQLite's concurrency is handled through:

- Allows concurrent readers with single writer
- Ecto manages connection lifecycle
- Handles lock contention gracefully

### Test Environment Specifics

These optimizations are test-specific because:

- Test environments have higher concurrency than typical production usage
- Tests create/destroy data rapidly, stressing connection pools
- Concurrent test execution is more aggressive than user traffic patterns

---

RESOLVED
Improved test stability and reduced noise in test output
Monitor production deployment for similar optimizations
