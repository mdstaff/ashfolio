# Ashfolio Project Overview - Core Context for AI Agents

> This file provides essential project context, architecture, and boundaries for AI agents working with Ashfolio.

## Project Overview

Ashfolio is a simplified Phase 1 portfolio management application built with Elixir/Phoenix and the Ash Framework. This provides essential project context for all AI agents.

### Key Project Characteristics

- Single-user local application - No authentication, runs on localhost only
- Simplified Phase 1 scope - Core portfolio tracking with manual price updates
- High confidence implementation - Each task designed for 80-90% success rate
- Incremental development - Tasks build on each other systematically
- macOS optimized - Developed on macOS with Apple Silicon (M1 Pro), 16GB RAM

## Current Project Status

### Completed Foundation (28/29 tasks - 97% complete)

Development Environment: Elixir/Phoenix/Ash Framework configured
Project Structure: Phoenix app with optimized directory structure
Database: SQLite configured with AshSqlite data layer
ETS Caching: Simple price caching system implemented
Error Handling: Centralized error handling with validation system
User Resource: Single default user Ash resource with validation
Account Resource: Investment account management with relationships
Symbol Resource: Financial symbols with market data support
Transaction Resource: Buy/sell/dividend/fee transaction management
Database Migrations: Core table migrations with performance indexes and management utilities
Yahoo Finance Integration: Market data fetching with comprehensive error handling
Price Manager: GenServer-based price coordination with dual storage
Portfolio Calculator: Complete calculation engine with financial precision
Holdings Calculator: Specialized holdings analysis with cost basis tracking
LiveView Layout: Responsive application layout with navigation system
Simple Routing: Basic Phoenix routing configuration with navigation
Dashboard LiveView: Functional portfolio dashboard with real-time data integration
Holdings Table: Complete holdings display with formatting and responsive design
Manual Price Refresh: User-initiated price updates with loading states and feedback
Test Suite Status: 383/383 tests passing (100% pass rate) - All critical stability issues resolved, including integration test fixes (Updated: August 7, 2025)
Account Management CRUD: Complete account listing, creation, editing, deletion, and exclusion toggle functionality
Transaction Management CRUD: Complete transaction entry, listing, editing, and deletion with all transaction types
Phase 10 Code Quality: Production-ready codebase with clean compilation and resolved technical debt
PubSub Integration: Complete real-time event system with dashboard updates for account and transaction changes
Code Simplification: Simplified user creation logic using standard Ash patterns for better maintainability

### Currently Working On

⚠️ Phase 10: Testing and Polish - CRITICAL TEST STABILITY ISSUES

### Current Priority Issues

RESOLVED: Test Suite Stability Crisis (August 7, 2025)

- ALL RESOLVED - 383/383 tests passing (100% pass rate)
- Database state pollution and symbol uniqueness constraint violations - FIXED
- Test isolation problems - RESOLVED with proper helper usage
- UNBLOCKED - Test suite is now production-ready

### Next Priority Tasks

Phase 10 Test Stability: COMPLETED (August 7, 2025)

- Final integration testing and performance validation
- All test stability issues resolved
- Database cleanup, test isolation, symbol uniqueness handling - ALL COMPLETED
- 100% test pass rate achieved (383/383 tests)
- v0.1.0 READY - Test suite is production-ready

📋 Next Development Focus:

- Continue with remaining Phase 10 tasks (code quality, documentation)
- Optional test suite optimizations (performance, coverage analysis)
- Feature development with stable test foundation

### Phase 7 Research Summary (2025-08-02)

Holdings Table Implementation Research Complete:

- HoldingsCalculator provides complete holding objects with all financial fields
- Phoenix core_components.ex has production-ready table with sorting capabilities
- Simple LiveView handle_event pattern identified for client-side sorting
- Currency ($X,XXX.XX) and percentage (XX.XX%) formatting approaches defined
- Calculator modules tested and ready for LiveView integration
- Green/red color classes for gains/losses identified in existing CSS

Phase 7 confidence increased from 80% to 85% due to completed research

### Recently Completed

Task 26.5: Phase 10 Critical Compilation Issues (Completed - 2025-08-06)

Task 26 (Phase 9): Transaction CRUD implementation (Completed - 2025-08-05)

Task 25 (Phase 9): Transaction listing functionality (Completed - 2025-08-05)

Task 24 (Phase 9): Transaction entry form (Completed - 2025-08-05)

Task 10: Account deletion functionality (Completed - 2025-08-05)

Task 9: Account editing functionality (Completed - 2025-08-04)

Task 8: Account creation functionality (Completed - 2025-08-04)

Task 7: AccountLive.FormComponent for reusable forms (Completed - 2025-08-04)

Task 6: Account exclusion toggle functionality (Completed - 2025-08-03)

Task 5: Account detail view layout and transaction summary (Completed - 2025-08-03)

PriceManager Test Fix: Updated test to handle new last_refresh return format (Completed - 2025-08-03)

Task 22: Create account management LiveView (Completed - 2025-08-03)

Test Configuration Optimization: Improved test suite performance (Completed - 2025-08-03)

Task 20: Create holdings table (Completed - 2025-08-03)

Task 18: Create basic dashboard LiveView (Completed - 2025-08-02)

Task 17: Configure simple routing (Completed - 2025-08-02)

Task 16: Basic LiveView layout (Completed - 2025-08-02)

Task 15: Holdings value calculator (Completed - 2025-08-02)

Task 14: Basic portfolio calculator (Completed - 2025-08-02)

Task 13: ETS price caching integration (Completed - 2025-08-02)

Task 12: Simple price manager GenServer (Completed - 2025-08-02)

Task 4: Basic error handling system (Completed - 2025-01-28)

Task 3: ETS caching system (Completed - 2025-01-28)
Task 2: SQLite database configuration (Completed)
Task 1.5: Project directory structure optimization (Completed)
Task 1: Phoenix project initialization (Completed)

## Key Technical Architecture

### Data Model Structure

- User - Single default user (no authentication)
- Account - Investment accounts (Schwab, Fidelity, etc.)
- Symbol - Stock/ETF symbols with market data
- Transaction - Buy/sell/dividend/fee records

### Technology Stack

- Backend: Phoenix 1.7+ with Ash Framework 3.0+
- Database: SQLite with AshSqlite adapter
- Frontend: Phoenix LiveView (no separate frontend)
- Cache: Simple ETS for price data
- APIs: Yahoo Finance (primary), CoinGecko (secondary)

### Project Structure

```
ashfolio/
├── lib/ashfolio/           # Business logic (Ash resources)
├── lib/ashfolio_web/       # Web layer (LiveView)
├── data/                   # SQLite database files
├── .kiro/specs/           # Project specifications
└── test/                  # Test files
```

## Critical Implementation Guidelines

### What TO Do

- Use Ash Framework for all business logic
- Implement manual price refresh (user-initiated)
- Use Decimal types for financial calculations
- Keep everything in USD currency
- Write tests for all new functionality
- Handle errors gracefully with user-friendly messages

### What NOT To Do

- Don't add authentication (single-user app)
- Don't implement real-time price updates
- Don't add complex background jobs
- Don't support multiple currencies
- Don't over-engineer solutions
- Don't skip error handling

## Phase 1 Scope Boundaries

Included: Manual price refresh, basic portfolio calculations, transaction entry, account management, holdings display, USD-only calculations

Excluded: Real-time updates, advanced analytics, CSV import/export, multi-currency, background jobs, complex charting

## Key Learnings & Technical Decisions

### Phase 10 Code Quality Discovery and Resolution (2025-08-06)

- Starting Phase 10 revealed 12+ compilation warnings/errors that had accumulated during rapid development
- Difference between "working application" and "production-ready codebase" clearly demonstrated
- Breaking down compilation issues into categorized subtasks (PubSub, modules, Ash functions, components, code quality) enabled efficient resolution
- Regular compilation cleanup should be part of development workflow, not just end-of-project activity
- Some function calls and patterns changed between development phases, requiring updates to match current Ash 3.0+ API
- Phoenix components have strict attribute requirements - custom attributes need proper documentation or removal
- Erlang/OTP 27+ requires explicit `+0.0` vs `0.0` pattern matching for floating-point numbers
- Proper alias management prevents runtime surprises and improves code clarity
- Adding missing helper functions (format_date, format_quantity) was straightforward and improved application completeness
- All 192+ tests continued passing throughout cleanup - good separation between functionality and code quality issues

### Test Configuration Optimization (2025-08-03)

- Disabled trace mode (`trace: false`) for faster test execution and cleaner output
- Enabled log capture (`capture_log: true`) to prevent test logs from cluttering console output
- Added `:seeding` tag exclusion to skip slow seeding tests by default while maintaining ability to run them with `--include seeding`
- Optimized configuration for development workflow with faster test feedback cycles
- All 201 tests continue to pass with improved execution speed and cleaner output
- Maintained comprehensive test coverage while improving performance for daily development use

### Task 18: Dashboard LiveView Implementation (2025-08-02)

- Successfully integrated Calculator.calculate_total_return/1 and HoldingsCalculator.get_holdings_summary/1 for real-time portfolio data display
- Implemented graceful degradation with default values when portfolio calculations fail, ensuring dashboard always renders
- Created comprehensive test suite with 157 test cases covering no-data scenarios, seeded data scenarios, error handling, and formatting validation
- Successfully integrated last price update timestamps from ETS cache for user feedback on data freshness
- Added loading state infrastructure for future price refresh functionality with proper UI feedback
- Leveraged existing FormatHelpers module for consistent currency and percentage formatting across the dashboard
- Dashboard provides immediate value even with no data, showing clear calls-to-action for adding first transactions
- Established clean data flow from Ash resources → Calculator modules → LiveView assigns → UI components
- Developed reusable test data setup patterns for creating realistic portfolio scenarios in tests

### Task 16: Basic LiveView Layout (2025-08-02)

- Mobile-first approach with hamburger menu for small screens using Tailwind CSS breakpoints
- Use `assign_current_page/2` helper in AshfolioWeb to manage active navigation states
- Modular approach with `nav_link/1`, `mobile_nav_link/1`, and utility components for reusability
- Tailwind CSS with custom component classes in `assets/css/app.css` for consistent styling
- Proper ARIA labels, focus management, and semantic HTML structure for screen readers
- Seamless integration with existing flash message system and error handling components
- Clean, modern layout with blue accent colors and proper typography hierarchy
- Touch-friendly navigation with proper spacing and visual feedback for mobile users

### Critical Test Suite Fix (2025-08-02)

- Ash resource validations using `Date.utc_today()` are evaluated at compile time, not runtime, causing validation to use stale dates
- For date validations that need current date, use custom validation functions with `fn changeset, _context ->` to ensure runtime evaluation
- Maintaining a passing test suite is critical before implementing new features - 12 failing tests were blocking development progress
- Use `Date.compare(date, Date.utc_today()) == :gt` in custom validation functions for proper runtime date comparison
- Enhanced test commands (`test-coverage`, `test-watch`, `test-failed`, `test-verbose`) improve development experience and debugging capabilities
- Test command enhancements require updates to justfile, README.md, and project documentation for developer onboarding

### Task 10: Enhanced Database Seeding (2025-08-02)

- Unified seeding implementations between `priv/repo/seeds.exs` and `DatabaseManager` to ensure consistency and avoid data discrepancies
- Enhanced symbols with current prices, sectors, countries, and realistic metadata for better testing and development experience
- Implemented proper existence checks to ensure seeding can be run multiple times without creating duplicates
- Added emoji indicators and detailed progress reporting to make seeding output more informative and user-friendly
- Created comprehensive test suite for seeding functionality to ensure reliability and catch regressions
- Added TSLA and NVDA to provide more diverse portfolio testing scenarios across different sectors
- All symbols now include current prices and timestamps, enabling immediate portfolio calculations without requiring API calls
- Enhanced sample transactions to include more realistic scenarios with proper fees, dividends, and different account types
- Improved error messages and exit codes for better debugging and user experience during seeding failures

### Task 9: Database Migrations and Management (2025-01-30)

- Ash automatically creates migrations when resources are defined - use `mix ash_sqlite.generate_migrations` to create them
- Add indexes for common query patterns (foreign keys, date fields, enum fields) to improve query performance
- Create centralized database management functions for truncation, seeding, and environment replication
- Implement safe database reset and re-seeding functions for local development with confirmation prompts
- Plan for Prod → Staging → Dev data replication workflows even when Prod doesn't exist yet
- Use SQLite-specific optimizations like WAL mode and proper indexing strategies
- Create comprehensive database management documentation for team onboarding and operational procedures
- Always include confirmation prompts and backups before destructive database operations
- Implement database health checks and statistics functions for operational visibility

### Task 8: Transaction Ash Resource (2025-01-29)

- Use conditional validation based on transaction type (buy: positive quantity, sell: negative quantity, fee: non-negative)
- Transaction belongs_to User, Account, and Symbol - all required relationships with proper foreign key constraints
- Use Decimal types for all monetary fields (quantity, price, total_amount, fee) to maintain precision
- Prevent future-dated transactions using date comparison validation
- Create domain-specific read actions for portfolio calculations (by_account, by_symbol, by_type, by_date_range, recent, holdings)
- Run full test suite to ensure new resource integrates properly with existing resources
- Ash automatically generates migrations - verify they exist and are applied correctly
- Provide comprehensive code interface functions for all CRUD operations and specialized queries
- Write tests for all transaction types, validations, relationships, and specialized actions

### Task 7: Symbol Ash Resource (2025-01-29)

- Implement specialized read actions with arguments using `argument` and `prepare` functions
- Use `Ash.Query.get_argument/2` to access arguments in prepare functions, require `Ash.Query` for filter macro
- Use `constraints: [one_of: [...]]` for atom attributes to restrict valid values
- Use `{:array, :string}` type with `default: []` for list attributes like sectors and countries
- Use `where: present(:field)` to apply validations only when field has a value
- Use `match/2` validator for format validation (symbol format, currency constraints)
- Ash errors use changeset structure - check `changeset.errors` and use `Enum.any?/2` to find specific field errors
- Use `DateTime.diff/3` with tolerance for timestamp comparisons instead of exact equality
- Use positional arguments in code interface for actions with arguments
- Check for existing records before seeding to prevent duplicates, use realistic sample data

### Task 6: Account Ash Resource (2025-01-29)

- Must explicitly define `accept` lists for create/update actions to specify which attributes can be modified
- Use `belongs_to` with `allow_nil?: false` for required relationships, update parent resources with `has_many`
- Create domain-specific actions like `active` (filtering), `by_user` (user-specific queries), `toggle_exclusion`, `update_balance`
- Define comprehensive code interface functions for all actions to provide convenient access patterns
- Enhance seeds with realistic sample data, include existence checks to prevent duplicates
- Use `compare` validator for numeric constraints (non-negative balance), combine with regex for format validation
- Write comprehensive tests covering CRUD, validations, relationships, specialized actions, and code interface
- Use `mix ash_sqlite.generate_migrations --name description` for proper migration naming

### Task 5: User Ash Resource (2025-01-29)

- Always register new resources in `Ashfolio.Portfolio` domain
- Use `mix ash_sqlite.generate_migrations` for Ash resources
- Need `installed_extensions/0` function in Repo for AshSqlite
- Use `Ecto.Adapters.SQL.Sandbox.checkout/1` in test setup
- Errors are structs with `.field` property, not tuples
- Use `%{}` maps for Ash.create/update, not keyword lists
- Define both direct actions and code interface functions
- Default user created via seeding, no authentication needed

### Task 4: Error Handling (2025-01-28)

- `Ashfolio.ErrorHandler` for consistent error categorization
- Convert technical errors to readable messages
- Use `Ashfolio.Validation` for common validation functions
- `ErrorHelpers.put_error_flash/3` for UI error display

### Task 3: ETS Caching (2025-01-28)

- Use `:write_concurrency`, `:read_concurrency`, `:decentralized_counters`
- Configure TTL and cleanup for 16GB systems
- Store price, timestamps, and metadata in structured format
- Initialize cache in application startup

### Task 2: Database Setup (2025-01-27)

- AshSqlite data layer with local file storage
- Database files in `data/` directory
- Ecto migrations work with AshSqlite adapter

### Task 1: Project Foundation (2025-01-26)

- Avoid nested `ashfolio/ashfolio/` for better DX
- Ash Framework 3.0+ with Phoenix 1.7+
- Homebrew-based Elixir/Erlang installation on macOS

## Key Reference Files

- Requirements: `.kiro/specs/requirements.md` - Complete feature requirements
- Design: `.kiro/specs/design.md` - Technical architecture details
- Tasks: `.kiro/specs/tasks.md` - Implementation plan (29 tasks)
- Changelog: `CHANGELOG.md` - ALWAYS CHECK FIRST - Detailed progress history and technical decisions

## Success Criteria

Project succeeds when users can: create accounts → enter transactions → view portfolio → refresh prices → see calculated gains/losses

---

Current Phase: Phase 8 - Account Management (22/29 tasks)
Next Milestone: Account CRUD operations (Task 23)
Test Suite Status: 100% passing (383/383 tests) - Production-ready stability achieved (Updated: August 7, 2025)
