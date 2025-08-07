# Modular Testing Migration Guide

This guide provides systematic instructions for migrating existing test files to use the new modular testing filter strategy in Ashfolio.

## Overview

The modular testing strategy uses ExUnit tags to organize tests by:
- **Architectural layers** (ash_resources, liveview, calculations, market_data)
- **Performance characteristics** (fast, slow, unit, integration) 
- **Dependencies** (external_deps, mocked, genserver, ets_cache)
- **Development workflow** (smoke, regression, edge_cases, error_handling)

## Migration Process

### Step 1: Identify Test Characteristics

For each test file, determine its primary characteristics:

#### A. Architectural Layer
- Tests Ash Resources (User, Account, Symbol, Transaction) → `:ash_resources`
- Tests LiveView components and UI interactions → `:liveview` 
- Tests portfolio calculations and FIFO logic → `:calculations`
- Tests PriceManager, Yahoo Finance integration → `:market_data`
- Tests end-to-end workflows → `:integration`
- Tests UI/accessibility/responsive design → `:ui`
- Tests PubSub and real-time features → `:pubsub`

#### B. Performance Profile
- Quick tests (< 100ms, minimal setup) → `:fast`
- Slower tests (complex setup, GenServer operations) → `:slow`
- Isolated tests with minimal dependencies → `:unit`
- Multi-system workflow tests → `:integration`

#### C. Dependencies
- Requires external APIs (Yahoo Finance) → `:external_deps`
- Uses Mox mocking → `:mocked`
- Tests GenServer state and async operations → `:genserver`
- Uses ETS cache operations → `:ets_cache`
- Requires `async: false` for SQLite → `:async_false`

#### D. Test Purpose
- Critical functionality that must pass → `:smoke`
- Tests for previously fixed bugs → `:regression`
- Boundary conditions and unusual scenarios → `:edge_cases`
- Error conditions and recovery → `:error_handling`

### Step 2: Add Module Tags

Add `@moduletag` declarations at the top of each test module after the `use` statement:

```elixir
defmodule Ashfolio.Portfolio.CalculatorTest do
  use Ashfolio.DataCase, async: false

  # Add module tags here
  @moduletag [:calculations, :unit, :fast, :smoke]
  @moduletag :async_false  # For SQLite compatibility

  # ... rest of test file
end
```

### Step 3: Add Individual Test Tags

For specific tests within a module that have different characteristics:

```elixir
describe "edge cases" do
  @tag :edge_cases
  @tag :slow
  test "handles very large decimal amounts" do
    # ... test code
  end
end
```

## File-by-File Migration Map

### Core Business Logic Tests (`/test/ashfolio/`)

#### Portfolio Resource Tests
```elixir
# test/ashfolio/portfolio/account_test.exs
@moduletag [:ash_resources, :unit, :fast, :smoke]
@moduletag :async_false

# test/ashfolio/portfolio/calculator_test.exs  
@moduletag [:calculations, :unit, :fast, :smoke]
@moduletag :async_false

# test/ashfolio/portfolio/holdings_calculator_test.exs
@moduletag [:calculations, :unit, :fast]
@moduletag :async_false

# test/ashfolio/portfolio/symbol_test.exs
@moduletag [:ash_resources, :unit, :fast, :smoke]  
@moduletag :async_false

# test/ashfolio/portfolio/transaction_test.exs
@moduletag [:ash_resources, :unit, :fast, :smoke]
@moduletag :async_false

# test/ashfolio/portfolio/user_test.exs
@moduletag [:ash_resources, :unit, :fast, :smoke]
@moduletag :async_false
```

#### Market Data Tests
```elixir
# test/ashfolio/market_data/price_manager_test.exs
@moduletag [:market_data, :genserver, :slow, :mocked]
@moduletag :async_false

# test/ashfolio/market_data/yahoo_finance_test.exs
@moduletag [:market_data, :external_deps, :mocked, :unit]

# test/ashfolio/market_data/price_manager_simple_test.exs
@moduletag [:market_data, :genserver, :fast, :mocked]
@moduletag :async_false
```

#### Infrastructure Tests
```elixir
# test/ashfolio/cache_test.exs
@moduletag [:ets_cache, :unit, :fast]
@moduletag :async_false

# test/ashfolio/error_handler_test.exs
@moduletag [:error_handling, :unit, :fast]

# test/ashfolio/validation_test.exs
@moduletag [:ash_resources, :unit, :fast, :smoke]

# test/ashfolio/pubsub_test.exs  
@moduletag [:pubsub, :unit, :fast]
@moduletag :async_false

# test/ashfolio/seeding_test.exs
@moduletag [:seeding, :slow, :database]
# Note: Keep existing @moduletag :seeding
```

### LiveView and UI Tests (`/test/ashfolio_web/`)

#### LiveView Components
```elixir
# test/ashfolio_web/live/dashboard_live_test.exs
@moduletag [:liveview, :integration, :slow, :mocked]
@moduletag :async_false

# test/ashfolio_web/live/account_live/index_test.exs
@moduletag [:liveview, :unit, :fast]
@moduletag :async_false

# test/ashfolio_web/live/account_live/show_test.exs
@moduletag [:liveview, :unit, :fast]
@moduletag :async_false

# test/ashfolio_web/live/account_live/form_component_test.exs
@moduletag [:liveview, :unit, :fast]
@moduletag :async_false

# test/ashfolio_web/live/transaction_live/index_test.exs
@moduletag [:liveview, :unit, :fast]
@moduletag :async_false
```

#### UI and Design Tests
```elixir
# test/ashfolio_web/accessibility_test.exs
@moduletag [:ui, :unit, :fast, :smoke]

# test/ashfolio_web/responsive_design_test.exs
@moduletag [:ui, :unit, :fast]

# test/ashfolio_web/live/navigation_test.exs
@moduletag [:ui, :unit, :fast, :smoke]

# test/ashfolio_web/live/format_helpers_test.exs
@moduletag [:ui, :unit, :fast]

# test/ashfolio_web/live/error_helpers_test.exs
@moduletag [:ui, :error_handling, :unit, :fast]
```

#### PubSub and Real-time Tests  
```elixir
# test/ashfolio_web/live/dashboard_pubsub_test.exs
@moduletag [:pubsub, :liveview, :integration, :slow]
@moduletag :async_false
```

#### Controller Tests
```elixir
# test/ashfolio_web/controllers/page_controller_test.exs
@moduletag [:ui, :unit, :fast, :smoke]

# test/ashfolio_web/controllers/error_html_test.exs
@moduletag [:ui, :error_handling, :unit, :fast]

# test/ashfolio_web/controllers/error_json_test.exs  
@moduletag [:ui, :error_handling, :unit, :fast]

# test/ashfolio_web/router_test.exs
@moduletag [:ui, :unit, :fast, :smoke]
```

### Integration Tests (`/test/integration/`)

```elixir
# test/integration/account_workflow_test.exs
@moduletag [:integration, :slow, :mocked]
@moduletag :async_false

# test/integration/account_management_flow_test.exs  
@moduletag [:integration, :slow, :liveview]
@moduletag :async_false

# test/integration/transaction_flow_test.exs
@moduletag [:integration, :slow, :liveview]
@moduletag :async_false

# test/integration/transaction_pubsub_test.exs
@moduletag [:integration, :pubsub, :slow]
@moduletag :async_false

# test/integration/portfolio_view_flow_test.exs
@moduletag [:integration, :liveview, :calculations, :slow]
@moduletag :async_false

# test/integration/critical_integration_points_test.exs
@moduletag [:integration, :smoke, :slow]
@moduletag :async_false

# test/integration/performance_benchmarks_test.exs
@moduletag [:integration, :slow, :external_deps]
@moduletag :async_false
```

## Special Considerations

### SQLite Concurrency
Always add `@moduletag :async_false` for tests that:
- Use `async: false` in their `use` statement
- Access GenServers (PriceManager)  
- Use ETS cache operations
- Require database transactions

### Individual Test Tagging
Add specific tags to individual tests when they differ from the module:

```elixir
describe "error handling" do
  @tag :error_handling
  @tag :edge_cases
  test "handles invalid user ID gracefully" do
    # ...
  end
end

describe "performance edge cases" do
  @tag :edge_cases
  @tag :slow
  test "handles extremely large positions" do
    # ...
  end
end
```

### Regression Test Tagging
When fixing bugs, add regression tags:

```elixir
describe "SQLite concurrency fixes" do
  @tag :regression
  test "handles sandbox conflicts gracefully" do
    # Test for previously fixed SQLite issues
  end
end
```

## Validation Commands

After migration, validate the tagging with these commands:

```bash
# Test each architectural layer works
just test-ash
just test-calculations  
just test-liveview
just test-market-data
just test-integration

# Test performance profiles work
just test-fast
just test-unit
just test-slow

# Test dependency filters work  
just test-mocked
just test-external

# Test workflow filters work
just test-smoke
just test-edge-cases
just test-error-handling
```

## Rollout Strategy

1. **Phase 1**: Tag core business logic tests (`/test/ashfolio/portfolio/`)
2. **Phase 2**: Tag market data tests (`/test/ashfolio/market_data/`)
3. **Phase 3**: Tag LiveView tests (`/test/ashfolio_web/live/`)
4. **Phase 4**: Tag integration tests (`/test/integration/`)
5. **Phase 5**: Tag remaining UI and controller tests
6. **Phase 6**: Add specific test-level tags for edge cases and error handling

## Best Practices

1. **Be Conservative**: Start with basic tags, add more specific ones as needed
2. **Test Early**: Run filter commands after each batch of changes  
3. **Document Changes**: Update this guide as patterns emerge
4. **Maintain SQLite Compatibility**: Always include `:async_false` where needed
5. **Keep Existing Tags**: Don't remove existing tags like `:seeding`

This systematic approach ensures comprehensive coverage while maintaining the existing SQLite concurrency patterns.