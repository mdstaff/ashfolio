# PriceManager Implementation Research

## Overview

This document provides in-depth research and analysis for implementing Task 12: Create simple price manager. It addresses the missing requirements and design decisions identified during the task review, with pros/cons analysis and recommendations for each decision point.

## Research Questions and Analysis

### 1. Symbol Discovery Strategy

**Question**: How should PriceManager determine which symbols to refresh?

#### Option A: Refresh All Symbols in Database
**Implementation**: Query all Symbol records regardless of usage
```elixir
def refresh_all_symbols do
  symbols = Symbol.read!()
  refresh_prices(Enum.map(symbols, & &1.symbol))
end
```

**Pros**:
- Simple implementation
- Ensures all symbols have current prices
- Good for data completeness

**Cons**:
- Inefficient API usage for unused symbols
- Higher API rate limit consumption
- Slower refresh times
- Unnecessary network calls

#### Option B: Refresh Only Symbols with Active Holdings
**Implementation**: Query symbols that have transactions (active holdings)
```elixir
def refresh_active_symbols do
  # Query symbols that have transactions
  symbols = Symbol
    |> Ash.Query.filter(exists(transactions, true))
    |> Symbol.read!()
  refresh_prices(Enum.map(symbols, & &1.symbol))
end
```

**Pros**:
- Efficient API usage
- Faster refresh times
- Only updates relevant data
- Reduces API rate limit pressure

**Cons**:
- More complex query logic
- Symbols without current holdings won't be updated
- Need to handle edge cases (sold all shares)

#### Option C: Hybrid Approach with Parameters
**Implementation**: Support both strategies with optional parameters
```elixir
def refresh_prices(opts \\ []) do
  symbols = case Keyword.get(opts, :strategy, :active_only) do
    :all -> get_all_symbols()
    :active_only -> get_active_symbols()
    :specific -> Keyword.get(opts, :symbols, [])
  end
  
  do_refresh_prices(symbols)
end
```

**Pros**:
- Maximum flexibility
- Supports different use cases
- Easy to test with specific symbols
- Future-proof design

**Cons**:
- More complex API
- Additional code complexity
- Potential for misuse

**Recommendation**: **Option B (Active Holdings Only)** for Phase 1
- Aligns with "simplified Phase 1" philosophy
- Most efficient for typical usage
- Can be enhanced later if needed

### 2. Database Integration Strategy

**Question**: Should PriceManager update database records in addition to ETS cache?

#### Option A: ETS Cache Only
**Implementation**: Only update ETS cache, database updates handled separately
```elixir
defp store_price(symbol, price) do
  Cache.put_price(symbol, price)
end
```

**Pros**:
- Simple implementation
- Fast operations
- Clear separation of concerns
- Matches current task description

**Cons**:
- Data inconsistency between cache and database
- Manual database updates required elsewhere
- Portfolio calculations may use stale database data
- Cache and database can get out of sync

#### Option B: Database Only
**Implementation**: Update database, rely on database for price queries
```elixir
defp store_price(symbol, price) do
  Symbol.update_price!(symbol, %{
    current_price: price,
    price_updated_at: DateTime.utc_now()
  })
end
```

**Pros**:
- Single source of truth
- Data consistency guaranteed
- Persistent across application restarts
- Simpler data flow

**Cons**:
- Slower than ETS cache
- Database I/O for every price lookup
- Doesn't leverage existing cache infrastructure

#### Option C: Dual Update (Cache + Database)
**Implementation**: Update both ETS cache and database records
```elixir
defp store_price(symbol, price, updated_at) do
  # Update database for persistence
  Symbol.update_price!(symbol, %{
    current_price: price,
    price_updated_at: updated_at
  })
  
  # Update cache for fast access
  Cache.put_price(symbol, price, updated_at)
end
```

**Pros**:
- Best of both worlds: fast access + persistence
- Data consistency between cache and database
- Leverages existing infrastructure
- Matches design document expectations

**Cons**:
- More complex error handling
- Potential for partial failures
- Higher implementation complexity
- Transaction coordination needed

**Recommendation**: **Option C (Dual Update)** 
- Aligns with design document
- Provides both performance and consistency
- Essential for portfolio calculations
- Worth the additional complexity

### 3. Supervision Tree Integration

**Question**: Where should PriceManager be placed in the supervision tree?

#### Current Application Structure Analysis
```elixir
# lib/ashfolio/application.ex
children = [
  AshfolioWeb.Telemetry,
  Ashfolio.Repo,
  {DNSCluster, query: Application.get_env(:ashfolio, :dns_cluster_query) || :ignore},
  {Phoenix.PubSub, name: Ashfolio.PubSub},
  {Finch, name: Ashfolio.Finch},
  # {Ashfolio.Worker, arg}, <- Placeholder for workers
  AshfolioWeb.Endpoint
]
```

#### Option A: Direct Child of Main Supervisor
**Implementation**: Add PriceManager directly to main children list
```elixir
children = [
  # ... existing children ...
  {Ashfolio.MarketData.PriceManager, []},
  AshfolioWeb.Endpoint
]
```

**Pros**:
- Simple implementation
- Direct supervision
- Easy to find and manage

**Cons**:
- Main supervisor becomes cluttered
- No logical grouping with related services
- Harder to manage multiple market data services

#### Option B: Market Data Supervisor
**Implementation**: Create dedicated supervisor for market data services
```elixir
# lib/ashfolio/market_data/supervisor.ex
defmodule Ashfolio.MarketData.Supervisor do
  use Supervisor
  
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  def init(_init_arg) do
    children = [
      {Ashfolio.MarketData.PriceManager, []}
      # Future: Rate limiter, circuit breaker, etc.
    ]
    
    Supervisor.init(children, strategy: :one_for_one)
  end
end

# In application.ex
children = [
  # ... existing children ...
  Ashfolio.MarketData.Supervisor,
  AshfolioWeb.Endpoint
]
```

**Pros**:
- Logical grouping of related services
- Better organization for future expansion
- Isolated restart strategies
- Cleaner main supervisor

**Cons**:
- Additional complexity for single service
- Over-engineering for Phase 1
- More files to maintain

**Recommendation**: **Option A (Direct Child)** for Phase 1
- Simpler implementation
- Matches "simplified Phase 1" philosophy
- Can be refactored later when adding more services

### 4. Public API Design

**Question**: What functions should PriceManager expose?

#### Core Functions Analysis

**Essential Functions**:
```elixir
# Primary function - refresh active symbols
def refresh_prices() :: {:ok, results} | {:error, reason}

# Get refresh status
def refresh_status() :: :idle | :refreshing | {:error, reason}

# Get last refresh information
def last_refresh() :: %{timestamp: DateTime.t(), symbol_count: integer(), success_count: integer()}
```

**Optional Functions**:
```elixir
# Refresh specific symbols
def refresh_symbols(symbols) :: {:ok, results} | {:error, reason}

# Force refresh all symbols (including inactive)
def refresh_all_symbols() :: {:ok, results} | {:error, reason}

# Get refresh statistics
def stats() :: %{total_refreshes: integer(), success_rate: float(), avg_duration: integer()}
```

#### API Complexity Analysis

**Minimal API (Phase 1)**:
- `refresh_prices/0` - refresh active symbols
- `refresh_status/0` - get current status
- `last_refresh/0` - get last refresh info

**Pros**:
- Simple to implement and test
- Clear single responsibility
- Easy to understand and use
- Matches Phase 1 simplicity goals

**Cons**:
- Limited flexibility
- Hard to test with specific symbols
- May need expansion soon

**Extended API**:
- All minimal functions plus
- `refresh_symbols/1` - refresh specific symbols
- `stats/0` - detailed statistics

**Pros**:
- More flexible for testing
- Better debugging capabilities
- Future-proof design
- Supports different use cases

**Cons**:
- More complex implementation
- More test cases needed
- Potential for API misuse

**Recommendation**: **Minimal API with one addition**
- `refresh_prices/0` - main function
- `refresh_symbols/1` - for testing and flexibility
- `refresh_status/0` - for UI feedback
- `last_refresh/0` - for UI display

### 5. Batch vs Individual Processing

**Question**: Should PriceManager use batch or individual API calls?

#### Option A: Pure Batch Processing
**Implementation**: Always use `YahooFinance.fetch_prices/1`
```elixir
defp do_refresh_prices(symbols) do
  case YahooFinance.fetch_prices(symbols) do
    {:ok, prices} -> 
      store_all_prices(prices)
      {:ok, prices}
    {:error, reason} -> 
      {:error, reason}
  end
end
```

**Pros**:
- Most efficient API usage
- Faster overall refresh
- Lower network overhead
- Simpler success case

**Cons**:
- All-or-nothing failure mode
- Harder to identify which symbols failed
- Less granular error handling
- May hit API limits with large batches

#### Option B: Pure Individual Processing
**Implementation**: Always use `YahooFinance.fetch_price/1`
```elixir
defp do_refresh_prices(symbols) do
  results = Enum.map(symbols, fn symbol ->
    case YahooFinance.fetch_price(symbol) do
      {:ok, price} -> 
        store_price(symbol, price)
        {symbol, {:ok, price}}
      {:error, reason} -> 
        {symbol, {:error, reason}}
    end
  end)
  
  {:ok, results}
end
```

**Pros**:
- Granular error handling
- Partial success support
- Easy to identify failed symbols
- Better error reporting

**Cons**:
- Less efficient API usage
- Slower overall refresh
- Higher network overhead
- More complex result handling

#### Option C: Hybrid Approach
**Implementation**: Try batch first, fall back to individual on failure
```elixir
defp do_refresh_prices(symbols) do
  case YahooFinance.fetch_prices(symbols) do
    {:ok, prices} -> 
      store_all_prices(prices)
      {:ok, prices}
    {:error, _reason} ->
      # Fall back to individual fetching
      Logger.info("Batch fetch failed, trying individual fetches")
      fetch_individually(symbols)
  end
end

defp fetch_individually(symbols) do
  # Individual processing logic
end
```

**Pros**:
- Best performance in success case
- Graceful degradation on failure
- Partial success support
- Good error recovery

**Cons**:
- Most complex implementation
- Potential for double API calls
- Complex error handling logic
- Harder to test all paths

**Recommendation**: **Option C (Hybrid Approach)**
- Maximizes efficiency while providing resilience
- Aligns with existing YahooFinance API design
- Good balance of performance and reliability

### 6. State Management

**Question**: What state should the GenServer maintain?

#### Minimal State
```elixir
defmodule State do
  defstruct [
    :last_refresh_at,
    :refreshing?
  ]
end
```

**Pros**:
- Simple to implement
- Easy to reason about
- Minimal memory usage

**Cons**:
- Limited debugging information
- No performance metrics
- Hard to troubleshoot issues

#### Comprehensive State
```elixir
defmodule State do
  defstruct [
    :last_refresh_at,
    :refreshing?,
    :current_refresh_start,
    :refresh_count,
    :success_count,
    :failure_count,
    :last_error,
    :refresh_duration_history
  ]
end
```

**Pros**:
- Rich debugging information
- Performance metrics available
- Good for monitoring and troubleshooting
- Supports statistics API

**Cons**:
- More complex state management
- Higher memory usage
- More complex serialization if needed

**Recommendation**: **Moderate State**
```elixir
defmodule State do
  defstruct [
    :last_refresh_at,
    :refreshing?,
    :last_refresh_results,  # %{success_count: int, failure_count: int, duration_ms: int}
    :refresh_count
  ]
end
```

### 7. Error Recovery Strategy

**Question**: How should PriceManager handle partial failures?

#### Analysis of Failure Scenarios

**Scenario 1**: Network timeout for all symbols
- **Strategy**: Return error, don't update anything
- **Rationale**: Complete failure, no partial data

**Scenario 2**: Some symbols not found (404)
- **Strategy**: Update successful symbols, log failures
- **Rationale**: Partial success is valuable

**Scenario 3**: API rate limit exceeded
- **Strategy**: Return error, suggest retry later
- **Rationale**: Temporary condition, don't cache partial data

**Scenario 4**: Individual symbol parsing errors
- **Strategy**: Update successful symbols, log parse errors
- **Rationale**: Other symbols are still valid

#### Recommended Error Recovery Strategy
```elixir
defp handle_refresh_results(results) do
  {successes, failures} = partition_results(results)
  
  # Always update successful prices
  Enum.each(successes, fn {symbol, price} ->
    store_price(symbol, price)
  end)
  
  # Log failures for debugging
  Enum.each(failures, fn {symbol, error} ->
    Logger.warning("Failed to refresh #{symbol}: #{inspect(error)}")
  end)
  
  # Return summary
  {:ok, %{
    success_count: length(successes),
    failure_count: length(failures),
    successes: successes,
    failures: failures
  }}
end
```

### 8. Integration with Ash Resources

**Question**: How should PriceManager interact with Ash Symbol resources?

#### Symbol Query Strategy
```elixir
# Get symbols with active holdings
defp get_active_symbols do
  Symbol
  |> Ash.Query.filter(exists(transactions, true))
  |> Ash.Query.select([:symbol, :id])
  |> Symbol.read!()
end
```

#### Database Update Strategy
```elixir
# Update symbol with new price
defp update_symbol_price(symbol_string, price, updated_at) do
  case Symbol.by_symbol!(symbol_string) do
    symbol when not is_nil(symbol) ->
      Symbol.update_price!(symbol, %{
        current_price: price,
        price_updated_at: updated_at
      })
    nil ->
      Logger.warning("Symbol not found in database: #{symbol_string}")
      {:error, :symbol_not_found}
  end
end
```

### 9. Concurrency Handling

**Question**: How should PriceManager handle concurrent refresh requests?

#### Option A: Queue Requests
**Implementation**: Queue subsequent requests while one is in progress
```elixir
def handle_call(:refresh_prices, from, %{refreshing?: true} = state) do
  # Add to queue
  {:noreply, %{state | queue: [from | state.queue]}}
end
```

**Pros**:
- No lost requests
- Fair handling of multiple callers
- Predictable behavior

**Cons**:
- More complex state management
- Potential for queue buildup
- Memory usage for queued requests

#### Option B: Reject Concurrent Requests
**Implementation**: Return "busy" status for concurrent requests
```elixir
def handle_call(:refresh_prices, _from, %{refreshing?: true} = state) do
  {:reply, {:error, :refresh_in_progress}, state}
end
```

**Pros**:
- Simple implementation
- Prevents resource contention
- Clear error handling

**Cons**:
- Lost requests
- Caller must handle retry logic
- Less user-friendly

#### Option C: Return Current Refresh Status
**Implementation**: Return the ongoing refresh process
```elixir
def handle_call(:refresh_prices, _from, %{refreshing?: true, current_task: task} = state) do
  {:reply, {:ok, :refresh_in_progress, task}, state}
end
```

**Pros**:
- Informative response
- Allows caller to wait or check status
- No lost information

**Cons**:
- Complex return value handling
- Caller needs to understand async operations

**Recommendation**: **Option B (Reject Concurrent)** for Phase 1
- Simplest implementation
- Clear error semantics
- Matches manual refresh use case (user won't spam refresh button)

### 10. Configuration Options

**Question**: What should be configurable in PriceManager?

#### Essential Configuration
```elixir
# config/config.exs
config :ashfolio, Ashfolio.MarketData.PriceManager,
  refresh_timeout: 30_000,  # 30 seconds
  batch_size: 50,           # Max symbols per batch
  retry_attempts: 3,        # Retry failed requests
  retry_delay: 1_000        # 1 second between retries
```

#### Extended Configuration
```elixir
config :ashfolio, Ashfolio.MarketData.PriceManager,
  # Basic settings
  refresh_timeout: 30_000,
  batch_size: 50,
  
  # Retry settings
  retry_attempts: 3,
  retry_delay: 1_000,
  retry_backoff: :exponential,  # :linear, :exponential
  
  # Cache settings
  update_cache: true,
  update_database: true,
  
  # Monitoring
  enable_metrics: true,
  log_level: :info
```

**Recommendation**: **Essential Configuration Only** for Phase 1
- Keep it simple
- Focus on most important settings
- Can be expanded later

## Summary of Recommendations

Based on the research above, here are the recommended decisions for Task 12:

1. **Symbol Discovery**: Active holdings only (`Option B`)
2. **Database Integration**: Dual update - cache + database (`Option C`)
3. **Supervision**: Direct child of main supervisor (`Option A`)
4. **Public API**: Minimal API with testing support (4 functions)
5. **Processing Strategy**: Hybrid batch/individual (`Option C`)
6. **State Management**: Moderate state with key metrics
7. **Error Recovery**: Partial success with detailed logging
8. **Ash Integration**: Query active symbols, update via Ash actions
9. **Concurrency**: Reject concurrent requests (`Option B`)
10. **Configuration**: Essential settings only

## Implementation Priority

**Phase 1 (Task 12)**:
- Core PriceManager GenServer
- Active symbol discovery
- Dual cache/database updates
- Basic error handling
- Essential configuration

**Future Enhancements**:
- Advanced retry logic
- Detailed metrics and monitoring
- Market data supervisor
- Extended API functions
- Queue-based concurrency handling

This research provides a solid foundation for implementing a robust yet simple PriceManager that aligns with the Phase 1 philosophy while being extensible for future enhancements.
## Additi
onal Technical Research

### Ash Resource Integration Details

Based on analysis of the existing Symbol resource, here are the specific integration points:

#### Available Symbol Actions
- `Symbol.with_prices/0` - symbols that have current price data
- `Symbol.stale_prices/1` - symbols with outdated prices
- `Symbol.by_data_source/1` - symbols from specific data source (e.g., `:yahoo_finance`)
- `Symbol.update_price/2` - update current_price and price_updated_at
- `Symbol.find_by_symbol/1` - find symbol by ticker string

#### Query Strategy for Active Symbols
Since Symbol has `has_many :transactions`, we can query symbols with active holdings:

```elixir
# Option 1: Query symbols that have transactions
def get_active_symbols do
  Symbol
  |> Ash.Query.filter(exists(transactions, true))
  |> Symbol.read!()
end

# Option 2: Query symbols from Yahoo Finance data source only
def get_yahoo_symbols do
  Symbol.by_data_source!(:yahoo_finance)
end

# Option 3: Query symbols with stale prices (need refresh)
def get_stale_symbols do
  threshold = DateTime.utc_now() |> DateTime.add(-3600, :second)  # 1 hour
  Symbol.stale_prices!(threshold)
end
```

**Recommendation**: Use **Option 1** (symbols with transactions) as primary strategy, with **Option 3** (stale prices) as fallback for comprehensive refresh.

#### Database Update Implementation
```elixir
defp update_symbol_price(symbol_string, price, updated_at) do
  case Symbol.find_by_symbol(symbol_string) do
    {:ok, symbol} ->
      Symbol.update_price(symbol, %{
        current_price: price,
        price_updated_at: updated_at
      })
    {:error, _} ->
      Logger.warning("Symbol not found in database: #{symbol_string}")
      {:error, :symbol_not_found}
  end
end
```

### Error Handling Integration

#### Leveraging Existing Error Handler
The existing `Ashfolio.ErrorHandler` should be integrated:

```elixir
defp handle_api_error(symbol, error) do
  context = %{symbol: symbol, module: __MODULE__}
  user_message = ErrorHandler.handle_error(error, context)
  
  # Return both technical error and user-friendly message
  {:error, error, user_message}
end
```

#### Cache Integration Strategy
The existing `Ashfolio.Cache` module is well-designed and should be used directly:

```elixir
defp store_price_in_cache(symbol, price, updated_at) do
  Cache.put_price(symbol, price, updated_at)
end

defp get_cached_price(symbol) do
  case Cache.get_price(symbol) do
    {:ok, price_data} -> {:ok, price_data}
    {:error, :not_found} -> {:error, :not_cached}
    {:error, :stale} -> {:error, :cache_stale}
  end
end
```

### Configuration Research

#### Application Configuration Location
Based on existing patterns in the codebase, configuration should follow Phoenix conventions:

```elixir
# config/config.exs
config :ashfolio, Ashfolio.MarketData.PriceManager,
  # Refresh settings
  refresh_timeout: 30_000,
  batch_size: 50,
  
  # Error handling
  max_retries: 3,
  retry_delay: 1_000,
  
  # Data sources
  default_data_source: :yahoo_finance,
  fallback_to_cache: true
```

#### Environment-Specific Overrides
```elixir
# config/dev.exs
config :ashfolio, Ashfolio.MarketData.PriceManager,
  refresh_timeout: 10_000,  # Shorter timeout for development
  batch_size: 10            # Smaller batches for testing

# config/test.exs
config :ashfolio, Ashfolio.MarketData.PriceManager,
  refresh_timeout: 5_000,   # Fast tests
  batch_size: 5,
  max_retries: 1            # Don't retry in tests
```

### Performance Considerations

#### Memory Usage Analysis
Based on the existing ETS cache implementation and typical portfolio sizes:

- **Typical portfolio**: 10-50 symbols
- **Large portfolio**: 100-200 symbols
- **Memory per symbol**: ~100 bytes (symbol + price + timestamps)
- **Total memory impact**: < 20KB for large portfolios

**Conclusion**: Memory usage is negligible, no special optimization needed.

#### API Rate Limiting
Yahoo Finance unofficial API considerations:

- **Rate limit**: ~2000 requests/hour (estimated)
- **Batch size**: Up to 100 symbols per request
- **Typical usage**: 1-2 refreshes per hour
- **Risk level**: Very low for typical usage

**Conclusion**: Rate limiting is not a concern for Phase 1 usage patterns.

### Testing Strategy Details

#### Unit Test Structure
```elixir
defmodule Ashfolio.MarketData.PriceManagerTest do
  use ExUnit.Case, async: false  # GenServer tests need async: false
  
  setup do
    # Start PriceManager for testing
    start_supervised!(Ashfolio.MarketData.PriceManager)
    :ok
  end
  
  describe "refresh_prices/0" do
    test "refreshes active symbols successfully"
    test "handles API failures gracefully"
    test "updates both cache and database"
    test "returns proper error when already refreshing"
  end
  
  describe "refresh_symbols/1" do
    test "refreshes specific symbols"
    test "handles invalid symbols"
    test "supports empty symbol list"
  end
end
```

#### Integration Test Considerations
- Mock `YahooFinance` module for predictable testing
- Use test database with known symbols
- Test cache and database consistency
- Verify error handling with various failure scenarios

#### Test Data Setup
```elixir
# Use existing seeded symbols for testing
@test_symbols ["AAPL", "MSFT", "GOOGL"]
@invalid_symbols ["INVALID", "NOTFOUND"]
```

### Deployment Considerations

#### Application Startup
The PriceManager should start automatically but not perform initial refresh:

```elixir
def init(_args) do
  state = %State{
    last_refresh_at: nil,
    refreshing?: false,
    last_refresh_results: nil,
    refresh_count: 0
  }
  
  Logger.info("PriceManager started")
  {:ok, state}
end
```

#### Graceful Shutdown
Handle application shutdown gracefully:

```elixir
def terminate(reason, state) do
  if state.refreshing? do
    Logger.info("PriceManager shutting down during refresh")
  end
  
  Logger.info("PriceManager terminated: #{inspect(reason)}")
  :ok
end
```

## Final Implementation Recommendations

Based on this comprehensive research, here's the refined implementation plan for Task 12:

### Core Implementation
1. **GenServer Structure**: Simple state management with essential metrics
2. **Symbol Discovery**: Query symbols with transactions, fallback to all symbols
3. **API Integration**: Hybrid batch/individual processing using existing YahooFinance module
4. **Data Storage**: Dual update (ETS cache + database) with error handling
5. **Error Handling**: Partial success support with detailed logging

### Public API (Final)
```elixir
# Primary functions
def refresh_prices() :: {:ok, results} | {:error, reason}
def refresh_symbols(symbols) :: {:ok, results} | {:error, reason}

# Status functions  
def refresh_status() :: :idle | :refreshing
def last_refresh() :: %{timestamp: DateTime.t(), results: map()} | nil
```

### Configuration (Final)
```elixir
config :ashfolio, Ashfolio.MarketData.PriceManager,
  refresh_timeout: 30_000,
  batch_size: 50,
  max_retries: 3,
  retry_delay: 1_000
```

This research provides a solid foundation for implementing a robust, well-tested PriceManager that integrates seamlessly with the existing Ashfolio architecture while maintaining the Phase 1 simplicity philosophy.