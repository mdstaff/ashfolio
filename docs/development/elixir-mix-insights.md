# Elixir & Mix Development Insights

## Mix Environment Detection

### Key Discovery: `Mix.env()` vs `System.get_env("MIX_ENV")`

**TL;DR**: Use `Mix.env()` for runtime environment detection, not `System.get_env("MIX_ENV")`.

#### The Issue

When implementing logger filters that needed to detect test environment at runtime, we discovered an important difference between these two approaches:

```elixir
# ❌ INCORRECT - Returns nil during test runs
System.get_env("MIX_ENV")

# ✅ CORRECT - Returns :test during test runs  
Mix.env()
```

#### Investigation Results

During `mix test` execution:

```elixir
IO.puts("MIX_ENV: #{inspect(System.get_env("MIX_ENV"))}")    # => MIX_ENV: nil
IO.puts("Mix.env(): #{inspect(Mix.env())}")                   # => Mix.env(): :test
```

#### Why This Happens

From Mix source code (`Mix.State`):

```elixir
defmodule Mix.State do
  def init() do
    %{
      shell: Mix.Shell.IO,
      env: String.to_atom(System.get_env("MIX_ENV") || "dev"),  # Converts to atom and stores
      scm: [Mix.SCM.Git, Mix.SCM.Path]
    }
  end
end
```

- Mix reads `MIX_ENV` environment variable **once** during initialization
- Converts it to an atom and stores it in Mix's internal state
- The original environment variable may not be set or may be cleared
- `Mix.env()` accesses this cached value, which is reliable

#### Best Practices

1. **For Runtime Environment Detection**:
   ```elixir
   # ✅ CORRECT
   if Mix.env() == :test do
     # test-specific logic
   end
   ```

2. **For Logger Filters and Conditional Logic**:
   ```elixir
   # ✅ CORRECT - Safe runtime detection
   filter_enabled = 
     Mix.env() == :test and
     System.get_env("FEATURE_FLAG", "true") in ["true", "1"]
   ```

3. **For Configuration Files**:
   ```elixir
   # config/test.exs - Mix handles this automatically
   import Config
   
   config :logger, level: :warning
   ```

#### Testing Environment Detection

When writing tests that need to verify environment detection:

```elixir
test "environment detection works correctly" do
  # ✅ This assertion will pass
  assert Mix.env() == :test
  
  # ❌ This assertion would fail
  # assert System.get_env("MIX_ENV") == "test"
end
```

#### Lessons Learned

1. **Mix manages environment state internally** - don't assume the environment variable is always available
2. **Use Mix.env() for runtime detection** - it's the authoritative source
3. **Use environment variables for feature flags** - not for environment detection
4. **Test your environment detection logic** - the behavior differs between Mix.env() and System.get_env()

## Logger Filters

### Safe Error Suppression Pattern

When implementing logger filters to reduce test noise:

```elixir
def filter_function(%{level: level, msg: {:string, message}} = log_event) do
  # Multiple safety layers
  filter_enabled = 
    Mix.env() == :test and                                    # Only in test
    System.get_env("FILTER_ENABLED", "true") in ["true", "1"] # Configurable
    
  if filter_enabled and very_specific_pattern?(message) do
    :stop  # Suppress only very specific patterns
  else
    log_event  # Pass through everything else
  end
end

# Pass through all other log formats unchanged
def filter_function(log_event), do: log_event
```

**Safety Guidelines**:
1. Only filter in test environment
2. Make filters configurable via environment variables
3. Use very specific pattern matching
4. Comprehensive test coverage for filter logic
5. Document what's being filtered and why

## SQLite Connection Error Suppression

### Context

During test runs, especially concurrent performance tests, SQLite connection errors are commonly logged:

```
20:15:15.681 [error] Exqlite.Connection (#PID<0.345.0>) disconnected: ** (DBConnection.ConnectionError) client #PID<0.8771.0> exited
```

These errors occur due to:
- Concurrent test execution putting pressure on SQLite
- Connection pooling and cleanup during test isolation
- Expected SQLite "busy" states during concurrent operations

### Our Solution

We implement a **surgical logger filter** that suppresses only these specific infrastructure errors while preserving all application errors.

#### What Gets Suppressed

Only error messages that contain **ALL** of these terms:
- `"Exqlite.Connection"`
- `"disconnected:"`
- `"DBConnection.ConnectionError"`
- `"client"`
- `"exited"`
- `"#PID<"`

#### What Gets Preserved

- All application errors
- All other database errors
- Any Exqlite errors with different patterns
- Any DBConnection errors with different patterns
- All warnings, info, and debug messages

#### Configuration

```bash
# Enable filtering (default)
ASHFOLIO_FILTER_SQLITE_ERRORS=true mix test

# Disable filtering to see all errors
ASHFOLIO_FILTER_SQLITE_ERRORS=false mix test
```

#### Why This Is Safe

1. **Environment Restricted**: Only works in `Mix.env() == :test`
2. **Configurable**: Can be disabled via environment variable
3. **Highly Specific**: Very narrow pattern matching
4. **Comprehensive Testing**: Full test coverage of filter behavior
5. **Non-Breaking**: Legitimate errors still appear

#### When to Disable

Disable the filter when:
- Debugging SQLite connection issues
- Investigating test database problems
- Analyzing test concurrency behavior
- Troubleshooting performance test failures

### Example Usage

```elixir
# In test configuration (config/test.exs)
config :logger, :console,
  filters: [
    sqlite_connection_filter: {Ashfolio.Support.LoggerFilters, :filter_sqlite_connection_errors}
  ]
```

## Related Files

- `lib/ashfolio/support/logger_filters.ex` - Logger filter implementation with SQLite error suppression
- `config/test.exs` - Logger configuration with filters
- `test/support/logger_filters_test.exs` - Comprehensive filter testing including SQLite patterns
- `test/support/sqlite_concurrency_helpers.ex` - SQLite retry logic and concurrency handling