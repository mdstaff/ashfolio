# IMPLEMENTATION_PLAN.md | Task 6: SymbolSearch Module

## Overview
Implement local-first symbol search with ETS caching, preparing foundation for external API integration. This task creates the SymbolSearch module within the FinancialManagement domain and integrates it with the Context API.

## Architecture Analysis
Based on codebase study:
- **Symbol Resource**: Already exists at `lib/ashfolio/portfolio/symbol.ex` with comprehensive attributes (symbol, name, asset_class, sectors, countries, current_price)
- **Context API**: Established pattern at `lib/ashfolio/context.ex` with ETS table, telemetry, and performance tracking
- **Domain Separation**: FinancialManagement domain is separate from Portfolio, requires cross-domain integration
- **Testing Patterns**: Comprehensive ExUnit tests with unique identifiers to avoid conflicts

## Stage 1: Core Search Logic Tests
**Goal**: Write comprehensive tests for symbol search functionality
**Success Criteria**: 
- Tests for case-insensitive ticker search
- Tests for company name search with partial matching
- Tests for result ranking by relevance (exact > starts with > contains)
- Tests for maximum 50 results limit
**Tests**:
- `test "searches symbols by ticker case-insensitive"`
- `test "searches symbols by company name partial match"`
- `test "ranks results by relevance (exact, starts with, contains)"`
- `test "limits results to maximum 50 symbols"`
- `test "returns empty list for no matches"`
**Status**: Not Started

## Stage 2: ETS Caching Tests
**Goal**: Write comprehensive tests for ETS caching with TTL
**Success Criteria**:
- Tests for cache hit/miss scenarios
- Tests for TTL expiration (default 5 minutes)
- Tests for ETS table lifecycle management
- Tests for cache key generation
**Tests**:
- `test "caches search results with TTL"`
- `test "returns cached results on subsequent searches"`
- `test "expires cache after TTL (5 minutes default)"`
- `test "handles ETS table creation and cleanup"`
- `test "generates consistent cache keys"`
**Status**: Not Started

## Stage 3: SymbolSearch Module Implementation
**Goal**: Implement the core SymbolSearch module with local search and ETS caching
**Success Criteria**:
- Module compiles and passes all tests
- Integrates with Portfolio.Symbol resource
- Implements relevance ranking algorithm
- ETS caching with configurable TTL
**Tests**: All tests from Stages 1 and 2 must pass
**Status**: Not Started

## Stage 4: Context API Integration
**Goal**: Add search_symbols/2 function to Context API with proper integration patterns
**Success Criteria**:
- Function follows established Context API patterns
- Includes telemetry tracking
- Handles errors gracefully
- Maintains performance characteristics
**Tests**: 
- `test "Context.search_symbols/2 delegates to SymbolSearch"`
- `test "Context.search_symbols/2 tracks telemetry"`
- `test "Context.search_symbols/2 handles errors gracefully"`
**Status**: Not Started

## Stage 5: Performance & Polish
**Goal**: Add telemetry, optimize performance, ensure quality gates
**Success Criteria**:
- Telemetry integration matches Context API patterns
- >85% test coverage
- All quality gates pass (compilation, tests, linting)
- Performance benchmarks meet expectations
**Tests**: All existing tests pass + performance integration tests
**Status**: Not Started

## Technical Specifications

### Module Structure
```elixir
defmodule Ashfolio.FinancialManagement.SymbolSearch do
  # Local symbol search with ETS caching
  # Integrates with Portfolio.Symbol resource
  # Implements relevance ranking
end
```

### Context API Integration
```elixir
# In lib/ashfolio/context.ex
def search_symbols(query, opts \\ []) do
  # Delegate to SymbolSearch with telemetry tracking
end
```

### Relevance Ranking Algorithm
1. **Exact ticker match** (highest priority)
2. **Ticker starts with query** (second priority) 
3. **Ticker contains query** (third priority)
4. **Company name starts with query** (fourth priority)
5. **Company name contains query** (lowest priority)

### ETS Caching Strategy
- **Cache Key**: `{:symbol_search, normalized_query}`
- **TTL**: 5 minutes default (configurable)
- **Table**: `:ashfolio_symbol_search_cache`
- **Options**: `[:named_table, :public, :set]`

### Performance Requirements
- Maximum 50 results per search
- Cache hit latency < 1ms
- Cache miss latency < 50ms for local Symbol queries
- Memory efficient result caching

## Dependencies
- Requires tasks 1-5 complete (✅)
- Portfolio.Symbol resource (✅)
- Context API patterns (✅)
- ETS caching infrastructure (✅)

## Out of Scope
- External API integration (Task 6a)
- Symbol creation functionality
- Real-time price data updates
- Advanced ranking algorithms beyond basic relevance