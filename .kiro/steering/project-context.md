# Ashfolio Project Context

## Project Overview

**Ashfolio** is a simplified Phase 1 portfolio management application built with Elixir/Phoenix and the Ash Framework. This provides essential project context for all AI agents.

### Key Project Characteristics

- **Single-user local application** - No authentication, runs on localhost only
- **Simplified Phase 1 scope** - Core portfolio tracking with manual price updates
- **High confidence implementation** - Each task designed for 80-90% success rate
- **Incremental development** - Tasks build on each other systematically
- **macOS optimized** - Developed on macOS with Apple Silicon (M1 Pro), 16GB RAM

## Current Project Status

### Completed Foundation (28/29 tasks - 97% complete)

✅ **Development Environment:** Elixir/Phoenix/Ash Framework configured  
✅ **Project Structure:** Phoenix app with optimized directory structure  
✅ **Database:** SQLite configured with AshSqlite data layer  
✅ **ETS Caching:** Simple price caching system implemented  
✅ **Error Handling:** Centralized error handling with validation system  
✅ **User Resource:** Single default user Ash resource with validation  
✅ **Account Resource:** Investment account management with relationships  
✅ **Symbol Resource:** Financial symbols with market data support  
✅ **Transaction Resource:** Buy/sell/dividend/fee transaction management  
✅ **Database Migrations:** Core table migrations with performance indexes and management utilities  
✅ **Yahoo Finance Integration:** Market data fetching with comprehensive error handling  
✅ **Price Manager:** GenServer-based price coordination with dual storage  
✅ **Portfolio Calculator:** Complete calculation engine with financial precision  
✅ **Holdings Calculator:** Specialized holdings analysis with cost basis tracking  
✅ **LiveView Layout:** Responsive application layout with navigation system  
✅ **Simple Routing:** Basic Phoenix routing configuration with navigation  
✅ **Dashboard LiveView:** Functional portfolio dashboard with real-time data integration  
✅ **Holdings Table:** Complete holdings display with formatting and responsive design  
✅ **Manual Price Refresh:** User-initiated price updates with loading states and feedback  
✅ **Comprehensive Test Suite:** 301 tests passing with complete coverage across all application components
✅ **Account Management CRUD:** Complete account listing, creation, editing, deletion, and exclusion toggle functionality
✅ **Transaction Management CRUD:** Complete transaction entry, listing, editing, and deletion with all transaction types
✅ **Phase 10 Code Quality:** Production-ready codebase with clean compilation and resolved technical debt
✅ **PubSub Integration:** Complete real-time event system with dashboard updates for account and transaction changes
✅ **Code Simplification:** Simplified user creation logic using standard Ash patterns for better maintainability

### Currently Working On

🔄 **Phase 10:** Testing and Polish (Task 29 - Final integration testing and performance validation)

### Next Priority Tasks

📋 **Remaining Phase 10 Tasks:**

- **Task 29:** Final integration testing and performance validation (1 task remaining)

📋 **Remaining Phase 10 Tasks:**

- **Task 27:** Responsive styling and accessibility (WCAG AA compliance)
- **Task 28:** Complete comprehensive test suite (100% coverage)
- **Task 29:** Final integration testing and performance validation
- **Post-Phase 10:** Manual testing phase and v1.0 preparation

### Phase 7 Research Summary (2025-08-02)

**Holdings Table Implementation Research Complete:**

- ✅ **Data Structure**: HoldingsCalculator provides complete holding objects with all financial fields
- ✅ **Table Component**: Phoenix core_components.ex has production-ready table with sorting capabilities
- ✅ **Sorting Strategy**: Simple LiveView handle_event pattern identified for client-side sorting
- ✅ **Formatting Patterns**: Currency ($X,XXX.XX) and percentage (XX.XX%) formatting approaches defined
- ✅ **Integration Points**: Calculator modules tested and ready for LiveView integration
- ✅ **Color Coding**: Green/red color classes for gains/losses identified in existing CSS

**Technical Confidence**: Phase 7 confidence increased from 80% to 85% due to completed research

### Recently Completed

✅ **Task 26.5:** Phase 10 Critical Compilation Issues (Completed - 2025-08-06)

✅ **Task 26 (Phase 9):** Transaction CRUD implementation (Completed - 2025-08-05)

✅ **Task 25 (Phase 9):** Transaction listing functionality (Completed - 2025-08-05)

✅ **Task 24 (Phase 9):** Transaction entry form (Completed - 2025-08-05)

✅ **Task 10:** Account deletion functionality (Completed - 2025-08-05)

✅ **Task 9:** Account editing functionality (Completed - 2025-08-04)

✅ **Task 8:** Account creation functionality (Completed - 2025-08-04)

✅ **Task 7:** AccountLive.FormComponent for reusable forms (Completed - 2025-08-04)

✅ **Task 6:** Account exclusion toggle functionality (Completed - 2025-08-03)

✅ **Task 5:** Account detail view layout and transaction summary (Completed - 2025-08-03)

✅ **PriceManager Test Fix:** Updated test to handle new last_refresh return format (Completed - 2025-08-03)

✅ **Task 22:** Create account management LiveView (Completed - 2025-08-03)

✅ **Test Configuration Optimization:** Improved test suite performance (Completed - 2025-08-03)

✅ **Task 20:** Create holdings table (Completed - 2025-08-03)

✅ **Task 18:** Create basic dashboard LiveView (Completed - 2025-08-02)

✅ **Task 17:** Configure simple routing (Completed - 2025-08-02)

✅ **Task 16:** Basic LiveView layout (Completed - 2025-08-02)

✅ **Task 15:** Holdings value calculator (Completed - 2025-08-02)

✅ **Task 14:** Basic portfolio calculator (Completed - 2025-08-02)

✅ **Task 13:** ETS price caching integration (Completed - 2025-08-02)

✅ **Task 12:** Simple price manager GenServer (Completed - 2025-08-02)

✅ **Task 4:** Basic error handling system (Completed - 2025-01-28)

✅ **Task 3:** ETS caching system (Completed - 2025-01-28)  
✅ **Task 2:** SQLite database configuration (Completed)  
✅ **Task 1.5:** Project directory structure optimization (Completed)  
✅ **Task 1:** Phoenix project initialization (Completed)

## Key Technical Architecture

### Data Model Structure

- **User** - Single default user (no authentication)
- **Account** - Investment accounts (Schwab, Fidelity, etc.)
- **Symbol** - Stock/ETF symbols with market data
- **Transaction** - Buy/sell/dividend/fee records

### Technology Stack

- **Backend:** Phoenix 1.7+ with Ash Framework 3.0+
- **Database:** SQLite with AshSqlite adapter
- **Frontend:** Phoenix LiveView (no separate frontend)
- **Cache:** Simple ETS for price data
- **APIs:** Yahoo Finance (primary), CoinGecko (secondary)

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

**Included:** Manual price refresh, basic portfolio calculations, transaction entry, account management, holdings display, USD-only calculations

**Excluded:** Real-time updates, advanced analytics, CSV import/export, multi-currency, background jobs, complex charting

## Key Learnings & Technical Decisions

### Phase 10 Code Quality Discovery and Resolution (2025-08-06)

- **Critical Discovery**: Starting Phase 10 revealed 12+ compilation warnings/errors that had accumulated during rapid development
- **Production Readiness**: Difference between "working application" and "production-ready codebase" clearly demonstrated
- **Systematic Approach**: Breaking down compilation issues into categorized subtasks (PubSub, modules, Ash functions, components, code quality) enabled efficient resolution
- **Technical Debt Management**: Regular compilation cleanup should be part of development workflow, not just end-of-project activity
- **Ash Framework Evolution**: Some function calls and patterns changed between development phases, requiring updates to match current Ash 3.0+ API
- **Component Standards**: Phoenix components have strict attribute requirements - custom attributes need proper documentation or removal
- **Pattern Matching**: Erlang/OTP 27+ requires explicit `+0.0` vs `0.0` pattern matching for floating-point numbers
- **Module Organization**: Proper alias management prevents runtime surprises and improves code clarity
- **Error Handling**: Adding missing helper functions (format_date, format_quantity) was straightforward and improved application completeness
- **Test Preservation**: All 192+ tests continued passing throughout cleanup - good separation between functionality and code quality issues

### Test Configuration Optimization (2025-08-03)

- **Performance Improvements**: Disabled trace mode (`trace: false`) for faster test execution and cleaner output
- **Log Management**: Enabled log capture (`capture_log: true`) to prevent test logs from cluttering console output
- **Selective Testing**: Added `:seeding` tag exclusion to skip slow seeding tests by default while maintaining ability to run them with `--include seeding`
- **Developer Experience**: Optimized configuration for development workflow with faster test feedback cycles
- **Stability Maintained**: All 201 tests continue to pass with improved execution speed and cleaner output
- **Configuration Balance**: Maintained comprehensive test coverage while improving performance for daily development use

### Task 18: Dashboard LiveView Implementation (2025-08-02)

- **Portfolio Data Integration**: Successfully integrated Calculator.calculate_total_return/1 and HoldingsCalculator.get_holdings_summary/1 for real-time portfolio data display
- **Error Handling Strategy**: Implemented graceful degradation with default values when portfolio calculations fail, ensuring dashboard always renders
- **Test Coverage Approach**: Created comprehensive test suite with 157 test cases covering no-data scenarios, seeded data scenarios, error handling, and formatting validation
- **ETS Cache Integration**: Successfully integrated last price update timestamps from ETS cache for user feedback on data freshness
- **Loading State Management**: Added loading state infrastructure for future price refresh functionality with proper UI feedback
- **Format Helper Integration**: Leveraged existing FormatHelpers module for consistent currency and percentage formatting across the dashboard
- **User Experience**: Dashboard provides immediate value even with no data, showing clear calls-to-action for adding first transactions
- **Data Flow Architecture**: Established clean data flow from Ash resources → Calculator modules → LiveView assigns → UI components
- **Test Data Patterns**: Developed reusable test data setup patterns for creating realistic portfolio scenarios in tests

### Task 16: Basic LiveView Layout (2025-08-02)

- **Responsive Navigation**: Mobile-first approach with hamburger menu for small screens using Tailwind CSS breakpoints
- **Navigation State Management**: Use `assign_current_page/2` helper in AshfolioWeb to manage active navigation states
- **Component Architecture**: Modular approach with `nav_link/1`, `mobile_nav_link/1`, and utility components for reusability
- **CSS Organization**: Tailwind CSS with custom component classes in `assets/css/app.css` for consistent styling
- **Accessibility**: Proper ARIA labels, focus management, and semantic HTML structure for screen readers
- **Integration**: Seamless integration with existing flash message system and error handling components
- **Professional Design**: Clean, modern layout with blue accent colors and proper typography hierarchy
- **Mobile UX**: Touch-friendly navigation with proper spacing and visual feedback for mobile users

### Critical Test Suite Fix (2025-08-02)

- **Runtime vs Compile-Time Evaluation**: Ash resource validations using `Date.utc_today()` are evaluated at compile time, not runtime, causing validation to use stale dates
- **Custom Validation Functions**: For date validations that need current date, use custom validation functions with `fn changeset, _context ->` to ensure runtime evaluation
- **Test Suite Stability**: Maintaining a passing test suite is critical before implementing new features - 12 failing tests were blocking development progress
- **Date Validation Pattern**: Use `Date.compare(date, Date.utc_today()) == :gt` in custom validation functions for proper runtime date comparison
- **Developer Workflow**: Enhanced test commands (`test-coverage`, `test-watch`, `test-failed`, `test-verbose`) improve development experience and debugging capabilities
- **Documentation Consistency**: Test command enhancements require updates to justfile, README.md, and project documentation for developer onboarding

### Task 10: Enhanced Database Seeding (2025-08-02)

- **Seeding Consolidation**: Unified seeding implementations between `priv/repo/seeds.exs` and `DatabaseManager` to ensure consistency and avoid data discrepancies
- **Comprehensive Sample Data**: Enhanced symbols with current prices, sectors, countries, and realistic metadata for better testing and development experience
- **Idempotent Seeding**: Implemented proper existence checks to ensure seeding can be run multiple times without creating duplicates
- **User Experience**: Added emoji indicators and detailed progress reporting to make seeding output more informative and user-friendly
- **Test Coverage**: Created comprehensive test suite for seeding functionality to ensure reliability and catch regressions
- **Symbol Expansion**: Added TSLA and NVDA to provide more diverse portfolio testing scenarios across different sectors
- **Price Data**: All symbols now include current prices and timestamps, enabling immediate portfolio calculations without requiring API calls
- **Transaction Variety**: Enhanced sample transactions to include more realistic scenarios with proper fees, dividends, and different account types
- **Error Handling**: Improved error messages and exit codes for better debugging and user experience during seeding failures

### Task 9: Database Migrations and Management (2025-01-30)

- **Ash Auto-Generated Migrations**: Ash automatically creates migrations when resources are defined - use `mix ash_sqlite.generate_migrations` to create them
- **Performance Indexes**: Add indexes for common query patterns (foreign keys, date fields, enum fields) to improve query performance
- **Database Management Utilities**: Create centralized database management functions for truncation, seeding, and environment replication
- **Development Workflows**: Implement safe database reset and re-seeding functions for local development with confirmation prompts
- **Environment Data Flow**: Plan for Prod → Staging → Dev data replication workflows even when Prod doesn't exist yet
- **SQLite Optimization**: Use SQLite-specific optimizations like WAL mode and proper indexing strategies
- **Documentation**: Create comprehensive database management documentation for team onboarding and operational procedures
- **Safety Mechanisms**: Always include confirmation prompts and backups before destructive database operations
- **Monitoring Functions**: Implement database health checks and statistics functions for operational visibility

### Task 8: Transaction Ash Resource (2025-01-29)

- **Type-Specific Validation**: Use conditional validation based on transaction type (buy: positive quantity, sell: negative quantity, fee: non-negative)
- **Multiple Relationships**: Transaction belongs_to User, Account, and Symbol - all required relationships with proper foreign key constraints
- **Financial Precision**: Use Decimal types for all monetary fields (quantity, price, total_amount, fee) to maintain precision
- **Date Validation**: Prevent future-dated transactions using date comparison validation
- **Specialized Actions**: Create domain-specific read actions for portfolio calculations (by_account, by_symbol, by_type, by_date_range, recent, holdings)
- **Integration Testing**: Run full test suite to ensure new resource integrates properly with existing resources
- **Database Migration**: Ash automatically generates migrations - verify they exist and are applied correctly
- **Code Interface**: Provide comprehensive code interface functions for all CRUD operations and specialized queries
- **Test Coverage**: Write tests for all transaction types, validations, relationships, and specialized actions

### Task 7: Symbol Ash Resource (2025-01-29)

- **Advanced Actions**: Implement specialized read actions with arguments using `argument` and `prepare` functions
- **Query Preparation**: Use `Ash.Query.get_argument/2` to access arguments in prepare functions, require `Ash.Query` for filter macro
- **Constraint Validation**: Use `constraints: [one_of: [...]]` for atom attributes to restrict valid values
- **Array Attributes**: Use `{:array, :string}` type with `default: []` for list attributes like sectors and countries
- **Conditional Validation**: Use `where: present(:field)` to apply validations only when field has a value
- **Regex Validation**: Use `match/2` validator for format validation (symbol format, currency constraints)
- **Test Error Handling**: Ash errors use changeset structure - check `changeset.errors` and use `Enum.any?/2` to find specific field errors
- **DateTime Testing**: Use `DateTime.diff/3` with tolerance for timestamp comparisons instead of exact equality
- **Code Interface Arguments**: Use positional arguments in code interface for actions with arguments
- **Database Seeding**: Check for existing records before seeding to prevent duplicates, use realistic sample data

### Task 6: Account Ash Resource (2025-01-29)

- **Action Accept Lists**: Must explicitly define `accept` lists for create/update actions to specify which attributes can be modified
- **Relationship Setup**: Use `belongs_to` with `allow_nil?: false` for required relationships, update parent resources with `has_many`
- **Specialized Actions**: Create domain-specific actions like `active` (filtering), `by_user` (user-specific queries), `toggle_exclusion`, `update_balance`
- **Code Interface**: Define comprehensive code interface functions for all actions to provide convenient access patterns
- **Database Seeding**: Enhance seeds with realistic sample data, include existence checks to prevent duplicates
- **Validation Patterns**: Use `compare` validator for numeric constraints (non-negative balance), combine with regex for format validation
- **Test Coverage**: Write comprehensive tests covering CRUD, validations, relationships, specialized actions, and code interface
- **Migration Generation**: Use `mix ash_sqlite.generate_migrations --name description` for proper migration naming

### Task 5: User Ash Resource (2025-01-29)

- **Ash Resource Registration**: Always register new resources in `Ashfolio.Portfolio` domain
- **Database Migrations**: Use `mix ash_sqlite.generate_migrations` for Ash resources
- **Repo Compatibility**: Need `installed_extensions/0` function in Repo for AshSqlite
- **Test Database Setup**: Use `Ecto.Adapters.SQL.Sandbox.checkout/1` in test setup
- **Ash Error Handling**: Errors are structs with `.field` property, not tuples
- **Parameter Syntax**: Use `%{}` maps for Ash.create/update, not keyword lists
- **Code Interface**: Define both direct actions and code interface functions
- **Single User Design**: Default user created via seeding, no authentication needed

### Task 4: Error Handling (2025-01-28)

- **Centralized Processing**: `Ashfolio.ErrorHandler` for consistent error categorization
- **User-Friendly Messages**: Convert technical errors to readable messages
- **Validation Patterns**: Use `Ashfolio.Validation` for common validation functions
- **LiveView Integration**: `ErrorHelpers.put_error_flash/3` for UI error display

### Task 3: ETS Caching (2025-01-28)

- **Apple Silicon Optimization**: Use `:write_concurrency`, `:read_concurrency`, `:decentralized_counters`
- **Memory Management**: Configure TTL and cleanup for 16GB systems
- **Cache Structure**: Store price, timestamps, and metadata in structured format
- **Application Integration**: Initialize cache in application startup

### Task 2: Database Setup (2025-01-27)

- **SQLite Configuration**: AshSqlite data layer with local file storage
- **Directory Organization**: Database files in `data/` directory
- **Migration Support**: Ecto migrations work with AshSqlite adapter

### Task 1: Project Foundation (2025-01-26)

- **Directory Structure**: Avoid nested `ashfolio/ashfolio/` for better DX
- **Dependency Management**: Ash Framework 3.0+ with Phoenix 1.7+
- **Development Environment**: Homebrew-based Elixir/Erlang installation on macOS

## Key Reference Files

- **Requirements:** `.kiro/specs/requirements.md` - Complete feature requirements
- **Design:** `.kiro/specs/design.md` - Technical architecture details
- **Tasks:** `.kiro/specs/tasks.md` - Implementation plan (29 tasks)
- **Changelog:** `CHANGELOG.md` - **ALWAYS CHECK FIRST** - Detailed progress history and technical decisions

## Success Criteria

Project succeeds when users can: create accounts → enter transactions → view portfolio → refresh prices → see calculated gains/losses

---

**Current Phase:** Phase 8 - Account Management (22/29 tasks)  
**Next Milestone:** Account CRUD operations (Task 23)  
**Test Suite Status:** ✅ 100% passing (201/201 tests) - Optimized with silent output - Optimized configuration
