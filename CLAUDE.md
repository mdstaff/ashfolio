# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ashfolio is a Phoenix LiveView portfolio management application built with the Ash Framework. It's designed for single-user local deployment with manual price updates via Yahoo Finance integration. The application uses SQLite for data persistence and ETS for price caching.

## Development Commands

This project uses `just` as the task runner. Key commands:

### Primary Development
- `just dev` - Setup and start development server (installs deps, migrates DB, starts Phoenix)
- `just setup` - Install dependencies and setup database only
- `just server` - Start Phoenix server (assumes setup already done)
- `just stop` - Stop Phoenix server

### Testing - Modular Testing Strategy

#### Basic Testing Commands
- `just test` - Run main test suite (excludes slow seeding tests)
- `just test-all` - Run full test suite including seeding tests
- `just test-file <path>` - Run specific test file
- `just test-verbose` - Run tests with detailed output and tracing
- `just test-coverage` - Run tests with coverage report
- `just test-watch` - Run tests in watch mode
- `just test-failed` - Re-run only failed tests

#### Architectural Layer Testing (NEW)
- `just test-ash` - Ash Resource business logic tests (User, Account, Symbol, Transaction)
- `just test-liveview` - Phoenix LiveView UI component and interaction tests
- `just test-calculations` - Portfolio calculation and FIFO cost basis tests
- `just test-market-data` - Price fetching, Yahoo Finance, and caching tests
- `just test-integration` - End-to-end workflow and system integration tests
- `just test-ui` - User interface, accessibility, and responsive design tests

#### Performance-Based Testing (NEW)
- `just test-fast` - Quick tests for development feedback loop (< 100ms)
- `just test-unit` - Isolated unit tests with minimal dependencies
- `just test-slow` - Slower comprehensive tests requiring more setup
- `just test-external` - Tests requiring external APIs (Yahoo Finance, etc.)
- `just test-mocked` - Tests using Mox for external service mocking

#### Development Workflow Testing (NEW)
- `just test-smoke` - Essential tests that must always pass
- `just test-regression` - Tests covering previously fixed bugs
- `just test-edge-cases` - Boundary condition and unusual scenario tests
- `just test-error-handling` - Error condition and fault tolerance tests

**Note**: All test commands support `-verbose` variants for detailed output (e.g., `just test-fast-verbose`)

### Database Management
- `just reset` - Reset database with fresh sample data (full reset)
- `just reseed` - Truncate and re-seed (preserves schema)
- `just migrate` - Run pending migrations
- `just backup` - Create timestamped database backup
- `just db-status` - Show table counts and database status

### Code Quality
- `just format` - Format Elixir code
- `just compile` - Compile project
- `just check` - Run format + compile + test

### Console Access
- `just console` - Start IEx console
- `just console-web` - Start IEx console with Phoenix server

## Architecture

### Core Technologies
- **Backend**: Elixir 1.14+, Phoenix 1.7+, Ash Framework 3.0+
- **Database**: SQLite with AshSqlite adapter
- **Frontend**: Phoenix LiveView with Tailwind CSS
- **Market Data**: Yahoo Finance API via HTTPoison
- **Caching**: ETS for price data
- **Testing**: ExUnit with Mox for mocking

### Key Modules

#### Ash Resources (Business Logic Layer)
- `Ashfolio.Portfolio.User` - User management
- `Ashfolio.Portfolio.Account` - Investment accounts
- `Ashfolio.Portfolio.Symbol` - Stock/asset symbols with price data
- `Ashfolio.Portfolio.Transaction` - All transaction types (BUY, SELL, DIVIDEND, etc.)

#### LiveView Pages
- `AshfolioWeb.DashboardLive` - Main portfolio dashboard
- `AshfolioWeb.AccountLive.Index` - Account management
- `AshfolioWeb.TransactionLive.Index` - Transaction management

#### Market Data System
- `Ashfolio.MarketData.PriceManager` - GenServer for price fetching and caching
- `Ashfolio.MarketData.YahooFinance` - Yahoo Finance API integration
- ETS cache for price data persistence

#### Portfolio Calculation
- `Ashfolio.Portfolio.Calculator` - Main portfolio calculations
- `Ashfolio.Portfolio.HoldingsCalculator` - Individual holdings calculations
- Both use FIFO cost basis methodology

### Data Flow Patterns

1. **LiveView → Ash Resource → Database**: Standard CRUD operations
2. **PriceManager → YahooFinance → ETS Cache**: Price fetching and caching
3. **Calculator modules**: Read from Ash Resources, perform calculations, return results
4. **Dual Calculator Architecture**: Main Calculator orchestrates, HoldingsCalculator handles per-symbol logic

## Development Practices

### Testing Strategy - Modular Architecture-Aligned Approach

#### Comprehensive Modular Testing Framework
- **Architecture-Aligned Organization**: Tests organized by architectural layers using ExUnit filters
- **Performance-Optimized Execution**: Separate fast/slow test categories for optimal development workflow
- **Dependency-Based Categorization**: Clear separation of tests requiring external services, mocks, or GenServers
- **Development Workflow Integration**: Specialized test suites for smoke tests, regression testing, and error handling

#### ExUnit Filter Categories
- **Architectural Layers**: `:ash_resources`, `:liveview`, `:market_data`, `:calculations`, `:ui`, `:pubsub`
- **Performance Groups**: `:fast`, `:slow`, `:unit`, `:integration`  
- **Dependency Types**: `:external_deps`, `:genserver`, `:ets_cache`, `:mocked`
- **Workflow Categories**: `:smoke`, `:regression`, `:edge_cases`, `:error_handling`

#### Test Execution Strategy
- **Development Loop**: `just test-fast` for quick feedback (< 100ms tests)
- **Layer-Specific**: `just test-ash`, `just test-liveview`, `just test-calculations` for focused development
- **Integration Testing**: `just test-integration` for end-to-end workflow validation
- **Comprehensive**: `just test-all` includes all categories including slow seeding tests

#### SQLite Testing Architecture
- **Concurrency Safety**: All tests use `async: false` for SQLite compatibility
- **Global Test Data Pattern**: Pre-created default user, accounts, and symbols reduce database contention
- **Retry Logic**: Built-in retry patterns for handling SQLite "Database busy" errors
- **Test Sandbox**: Proper database isolation using `DataCase.setup_sandbox/1`
- **GenServer Integration**: Special handling for PriceManager and other GenServer database access

#### Testing Documentation
- **Comprehensive Guides**: Complete documentation in `docs/` covering all testing patterns
- **AI Agent Support**: Specialized guides and templates for AI-assisted development
- **Migration Strategies**: Step-by-step guides for adopting modular testing patterns
- **Best Practices**: SQLite-specific patterns and performance optimization techniques

### Database Management
- Development uses seeded sample data for immediate productivity
- Database backups are timestamped and stored in `data/backups/`
- Migration files follow Phoenix conventions
- Use `just reset` frequently during development for clean state

### Code Organization
- Ash Resources define all business logic and validations
- LiveViews handle UI state and user interactions only
- Separate calculator modules for complex financial calculations
- Market data system is isolated and mockable for testing

### Phoenix LiveView Patterns
- Use LiveComponents for reusable UI elements (FormComponent)
- Handle async operations with `handle_info/2`
- Leverage Phoenix PubSub for real-time updates when needed
- Keep LiveView mount/handle_event functions focused and delegate to Ash Resources

## Common Development Workflows

### Adding New Ash Resource
1. Create resource module in `lib/ashfolio/portfolio/`
2. Define attributes, relationships, and actions
3. Create migration with `mix ash_sqlite.generate_migrations`
4. Update seeds if needed
5. Add comprehensive tests

### Adding New LiveView Page
1. Create LiveView module in `lib/ashfolio_web/live/`
2. Add route to `router.ex`
3. Create corresponding template if not using `~H` sigil
4. Add navigation links to `top_bar.ex` if needed
5. Test both unit and integration aspects

### Market Data Integration
- PriceManager is a GenServer - be careful with state management
- Always mock YahooFinance in tests using the behaviour
- ETS cache is process-based - consider supervision tree implications
- Price updates are manual only (no automatic refresh)

### Financial Calculations
- Both Calculator modules must stay in sync for accurate results
- FIFO cost basis is the standard methodology
- All monetary values use Decimal type for precision
- Transaction types: BUY, SELL, DIVIDEND, FEE, INTEREST, LIABILITY