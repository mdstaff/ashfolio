# Ashfolio Implementation Plan - Simplified Phase 1

This implementation plan focuses on delivering core portfolio management functionality with high confidence and minimal complexity. Each task is designed to be straightforward and build incrementally toward a working portfolio tracker.

## Phase 1: Project Foundation (90% confidence)

- [x] 0. Set up development environment dependencies

  - Create installation script for Elixir/Erlang via Homebrew on macOS
  - Install Phoenix framework and hex package manager
  - Verify all required tools are properly installed
  - Create environment setup documentation
  - _Requirements: 19.1_

- [x] 1. Initialize Phoenix project with Ash Framework

  - Create new Phoenix 1.7+ project with LiveView support
  - Add Ash Framework 3.0+ dependencies (ash, ash_sqlite, ash_phoenix)
  - Configure basic project structure and dependencies in mix.exs
  - Set up standard development environment configuration
  - _Requirements: 10.1, 10.2_

- [x] 1.5. Optimize project directory structure

  - Remove redundant ashfolio/ashfolio/ nesting for better DX
  - Move Phoenix app to root level for cleaner structure
  - Reorganize .kiro/specs/ to remove redundant ashfolio subdirectory
  - Update setup scripts and documentation to reflect new structure
  - _Requirements: Developer Experience Optimization_

- [x] 2. Configure SQLite database with Ecto

  - Set up AshSqlite data layer configuration
  - Create database configuration for local SQLite file storage
  - Configure Ecto repository with SQLite adapter
  - Add database creation and migration support
  - Organize database files in data/ directory for cleaner structure
  - _Requirements: 10.4_

- [x] 3. Set up simple ETS caching

  - Create basic ETS table for price caching
  - Add simple cache initialization in application startup
  - Implement basic get/put functions for price data
  - _Requirements: 16.1_

- [x] 4. Implement basic error handling
  - Add simple error logging with Logger
  - Create basic error message display in LiveView
  - Add form validation error handling
  - _Requirements: 18.1, 18.2_

## Phase 2: Core Data Models (85% confidence)

- [x] 5. Implement User Ash resource

  - Create User resource with single default user support
  - Define basic user attributes (name, currency) with defaults
  - Add simple user actions (read, update)
  - Write basic unit tests for User resource
  - _Requirements: 1.3, 10.1_

- [x] 6. Implement Account Ash resource

  - Create Account resource with required attributes (name, platform, balance)
  - Define account relationships to user and transactions
  - Implement basic CRUD actions with validation
  - Write unit tests for Account resource
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 7. Implement Symbol Ash resource

  - Create Symbol resource with basic attributes (symbol, name, current_price)
  - Define symbol relationships to transactions
  - Add simple price update actions
  - Write unit tests for Symbol resource
  - _Requirements: 4.1_

- [x] 8. Implement Transaction Ash resource
  - Create Transaction resource with core transaction types (BUY, SELL, DIVIDEND, FEE)
  - Define transaction relationships and basic calculated fields
  - Implement transaction validation for required fields
  - Write unit tests for Transaction resource
  - _Requirements: 3.1, 3.2, 7.1_

## Phase 3: Database Setup (90% confidence)

- [x] 9. Create database migrations for core tables

  - Generate migrations for users, accounts, symbols, transactions
  - Add basic indexes for common queries
  - Configure foreign key constraints
  - Test migrations work correctly
  - _Requirements: 2.5, 10.4_

- [x] 10. Implement basic database seeding
  - Create seed data for default user
  - Add a few sample accounts for testing
  - Add common stock symbols (AAPL, MSFT, GOOGL)
  - Create simple seed script
  - _Requirements: 1.3_

### Critical Bug Fix (Unplanned - High Priority)

- [x] 10.1. Fix test suite date validation issue
  - Fixed runtime vs compile-time date evaluation in Transaction resource validation
  - Resolved 12 failing tests related to "Transaction date cannot be in the future"
  - Enhanced test commands with coverage, watch, failed, and verbose options
  - Achieved 100% test pass rate (118/118 tests passing)
  - Updated documentation and developer workflows

## Phase 4: Simple Market Data (80% confidence)

- [x] 11. Implement Yahoo Finance integration

  - Create simple YahooFinance module with HTTPoison
  - Add basic price fetching function for individual symbols
  - Implement simple JSON parsing for price data
  - Add basic error handling with logging
  - Write unit tests with mocked responses
  - _Requirements: 4.1, 6.1_

- [x] 11.1. Fix failing Yahoo Finance test

  - ✅ Fixed function export test failure in YahooFinance test suite
  - ✅ Ensured proper module function visibility and exports
  - ✅ Verified all 7 Yahoo Finance tests pass reliably
  - _Requirements: Test suite stability for Yahoo Finance module_
  - **Completed: 2025-08-02**

- [x] 12. Create simple price manager

  - Implement PriceManager GenServer for coordinating price updates
  - Add manual price refresh function triggered by user
  - Implement basic ETS caching for fetched prices
  - Add simple error handling for failed API calls
  - Write unit tests for price manager functionality
  - _Requirements: 16.1, 16.2_

- [x] 12.1. Fix failing PriceManager tests

  - ✅ Fixed Mox setup and expectations for PriceManager comprehensive tests
  - ✅ Resolved database connection issues in test environment
  - ✅ Ensured proper test isolation and cleanup between tests
  - ✅ Updated test configuration for reliable mock behavior
  - ✅ Fixed test data setup issues (User, Account, Symbol, Transaction creation)
  - ✅ Fixed Ash resource return value handling (list vs single record)
  - ✅ Resolved GenServer singleton testing challenges with shared state
  - ✅ All 18 PriceManager tests now pass with proper mocking
  - _Requirements: Test suite stability for PriceManager functionality_
  - **Completed: 2025-08-02**

  **Key Learnings:**

  - **GenServer Testing**: Singleton GenServers require special handling in tests
  - **Shared State**: Tests must handle persistent state between runs gracefully
  - **Mox Configuration**: Use `set_mox_from_context` for cross-process mocking
  - **Ash Resources**: `find_by_symbol` returns list, not single record
  - **Timing Tests**: Avoid timing-dependent concurrent tests; focus on functionality

- [x] 13. Add price caching with ETS
  - ✅ ETS caching already implemented in Task 3 and integrated with PriceManager
  - ✅ Cache operations working with get/put functions
  - ✅ Timestamp tracking implemented for cache freshness
  - ✅ Cache cleanup integrated with test setup
  - ✅ Tests for cache operations passing
  - _Requirements: 16.1_
  - **Completed: Previously completed, verified in Task 12.1**

## Phase 5: Simple Portfolio Calculations (85% confidence)

> **🚨 HANDOFF NOTE FOR NEXT AGENT**
>
> **CRITICAL**: Before starting Phase 5, please review and verify the completion status of Phases 1-4:
>
> - **Phase 1**: ✅ Project Foundation (Tasks 0-4) - All completed
> - **Phase 2**: ✅ Data Model Setup (Tasks 5-10) - All completed
> - **Phase 3**: ✅ Database Management (Tasks covered in Phase 2)
> - **Phase 4**: ✅ Market Data Integration (Tasks 11-13) - All completed
>
> **Current Status**: 146/146 tests passing (100% pass rate)
>
> **Key Achievements**:
>
> - ✅ Ash Framework resources (User, Account, Symbol, Transaction)
> - ✅ Yahoo Finance API integration with comprehensive error handling
> - ✅ PriceManager GenServer with dual storage (ETS cache + database)
> - ✅ Comprehensive test suite with GenServer testing patterns
> - ✅ Database migrations and seeding system
>
> **🔧 IMPORTANT - USE JUST COMMANDS**:
>
> This project uses **Just** (modern task runner) instead of raw mix commands. Always use the trusted Just commands:
>
> - **Testing**: `just test` (full suite), `just test-file <path>` (specific file), `just test-coverage`, `just test-watch`
> - **Development**: `just dev` (setup + start server), `just compile`, `just format`, `just check` (format + compile + test)
> - **Database**: `just reset`, `just reseed`, `just backup`, `just db-status`
> - **Help**: `just` (shows all available commands)
>
> **Before proceeding**:
>
> 1. Run `just test` to verify all tests still pass
> 2. Review CHANGELOG.md for latest technical decisions
> 3. Check `.kiro/specs/design.md` for architectural patterns
> 4. Verify the application starts with `just dev`
>
> **Ready for Phase 5**: Portfolio calculations and basic LiveView interface

- [x] 14. Implement basic portfolio calculator

  - Create simple portfolio value calculation (sum of holdings)
  - Add basic return calculation: (current_value - cost_basis) / cost_basis \* 100
  - Implement individual position gain/loss calculations
  - Add simple total return tracking
  - Write unit tests for calculation functions
  - _Requirements: 5.1, 5.2_

- [ ] 15. Create holdings value calculator
  - Implement function to calculate current holding values
  - Add cost basis calculation from transaction history
  - Create simple profit/loss calculation per holding
  - Add portfolio total value aggregation
  - Write tests with sample transaction data
  - _Requirements: 5.3_

## Phase 6: Basic LiveView Setup (80% confidence)

- [ ] 16. Set up basic LiveView layout

  - Create simple application layout with navigation
  - Add basic CSS styling for clean appearance
  - Implement simple navigation between main sections
  - Create basic error message display components
  - _Requirements: 12.1, 15.1_

- [ ] 17. Configure simple routing
  - Set up Phoenix router for basic pages (dashboard, accounts, transactions)
  - Remove authentication requirements (single-user app)
  - Add simple route helpers
  - Test basic navigation works
  - _Requirements: 1.1, 1.2_

## Phase 7: Portfolio Dashboard (80% confidence)

- [ ] 18. Create basic dashboard LiveView

  - Create DashboardLive module with simple mount/3 function
  - Display total portfolio value using simple calculation
  - Add basic template with portfolio summary
  - Show last updated timestamp
  - _Requirements: 13.1_

- [ ] 19. Add portfolio value display

  - Implement total portfolio value calculation and display
  - Add currency formatting ($1,234.56 format)
  - Show simple total return percentage
  - Add color coding (green for gains, red for losses)
  - _Requirements: 13.1, 13.2_

- [ ] 20. Create holdings table

  - Display current holdings in a simple HTML table
  - Show symbol, quantity, current price, and total value
  - Add basic sorting by value or symbol
  - Include individual position gains/losses
  - _Requirements: 13.3, 15.1_

- [ ] 21. Add manual price refresh
  - Create "Refresh Prices" button on dashboard
  - Implement price refresh functionality
  - Show loading state during price updates
  - Update portfolio values after price refresh
  - _Requirements: 6.1, 6.2_

## Phase 8: Account Management (85% confidence)

- [ ] 22. Create account management LiveView

  - Create AccountLive module for listing accounts
  - Add simple account creation form with validation
  - Implement basic account editing functionality
  - Show account balances and basic information
  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 23. Add account CRUD operations
  - Implement account creation with form validation
  - Add account editing and deletion functionality
  - Create simple account detail view
  - Add basic error handling for account operations
  - _Requirements: 2.4_

## Phase 9: Transaction Management (80% confidence)

- [ ] 24. Create transaction entry form

  - Create TransactionLive module with simple form
  - Add form fields for all transaction types (BUY, SELL, DIVIDEND, FEE)
  - Implement basic form validation
  - Add symbol selection (dropdown or text input)
  - _Requirements: 3.1, 3.2, 7.1_

- [ ] 25. Add transaction listing

  - Create simple transaction table showing all transactions
  - Add basic filtering by account or transaction type
  - Implement simple sorting by date or amount
  - Show transaction details in table format
  - _Requirements: 7.2_

- [ ] 26. Implement transaction CRUD
  - Add transaction creation with validation
  - Implement transaction editing functionality
  - Add transaction deletion with confirmation
  - Update portfolio calculations after transaction changes
  - _Requirements: 7.3, 7.4_

## Phase 10: Basic Testing and Polish (85% confidence)

- [ ] 27. Add basic responsive styling

  - Create simple CSS for clean, professional appearance
  - Add responsive design for desktop and tablet
  - Implement basic color coding (green/red for gains/losses)
  - Add simple loading states and error messages
  - _Requirements: 15.1, 15.2_

- [ ] 28. Create basic test suite

  - Write unit tests for Ash resources (User, Account, Symbol, Transaction)
  - Add tests for portfolio calculation functions
  - Create basic LiveView tests for main pages
  - Add tests for Yahoo Finance integration
  - _Requirements: 11.1_

- [ ] 29. Final integration and testing
  - Test complete workflow: create account → add transactions → view portfolio
  - Verify price refresh functionality works end-to-end
  - Test error handling for API failures
  - Ensure all basic features work together
  - _Requirements: All core requirements_

## Future Enhancement Phases

These features can be added in subsequent phases once the core application is working:

### Phase 2: Real-time Updates

- Add Phoenix PubSub for live price updates
- Implement WebSocket connections for real-time portfolio changes
- Add automatic price refresh every 5 minutes

### Phase 3: Advanced Analytics

- Implement ROAI (Return on Average Investment) calculations
- Add time-weighted returns for multiple periods
- Create portfolio composition analysis and charts

### Phase 4: Data Import/Export

- Add CSV import functionality for transactions
- Implement portfolio export in multiple formats
- Create bulk transaction processing

### Phase 5: macOS Optimization

- Add Apple Silicon specific optimizations
- Implement advanced memory management
- Add macOS native integrations

### Phase 6: Advanced Features

- Stock split and dividend adjustments
- Cost basis calculations (FIFO, LIFO, SpecID)
- Tax implications and reporting
- Corporate actions handling
