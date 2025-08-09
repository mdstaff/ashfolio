# CLAUDE.md

# Development Guidelines

## Philosophy

### Core Beliefs

- **Incremental progress over big bangs** - Small changes that compile and pass tests
- **Learning from existing code** - Study and plan before implementing
- **Pragmatic over dogmatic** - Adapt to project reality
- **Clear intent over clever code** - Be boring and obvious

### Simplicity Means

- Single responsibility per function/class
- Avoid premature abstractions
- No clever tricks - choose the boring solution
- If you need to explain it, it's too complex

## Process

### 1. Planning & Staging

Break complex work into 3-5 stages. Document in `IMPLEMENTATION_PLAN.md`:

```markdown
## Stage N: [Name]

**Goal**: [Specific deliverable]
**Success Criteria**: [Testable outcomes]
**Tests**: [Specific test cases]
**Status**: [Not Started|In Progress|Complete]
```

- Update status as you progress
- Remove file when all stages are done

### 2. Implementation Flow

1. **Understand** - Study existing patterns in codebase
2. **Test** - Write test first (red)
3. **Implement** - Minimal code to pass (green)
4. **Refactor** - Clean up with tests passing
5. **Commit** - With clear message linking to plan

### 3. When Stuck (After 3 Attempts)

**CRITICAL**: Maximum 3 attempts per issue, then STOP.

1. **Document what failed**:

   - What you tried
   - Specific error messages
   - Why you think it failed

2. **Research alternatives**:

   - Find 2-3 similar implementations
   - Note different approaches used

3. **Question fundamentals**:

   - Is this the right abstraction level?
   - Can this be split into smaller problems?
   - Is there a simpler approach entirely?

4. **Try different angle**:
   - Different library/framework feature?
   - Different architectural pattern?
   - Remove abstraction instead of adding?

## Technical Standards

### Architecture Principles

- **Composition over inheritance** - Use dependency injection
- **Interfaces over singletons** - Enable testing and flexibility
- **Explicit over implicit** - Clear data flow and dependencies
- **Test-driven when possible** - Never disable tests, fix them

### Code Quality

- **Every commit must**:

  - Compile successfully
  - Pass all existing tests
  - Include tests for new functionality
  - Follow project formatting/linting

- **Before committing**:
  - Run formatters/linters
  - Self-review changes
  - Ensure commit message explains "why"

### Error Handling

- Fail fast with descriptive messages
- Include context for debugging
- Handle errors at appropriate level
- Never silently swallow exceptions

## Decision Framework

When multiple valid approaches exist, choose based on:

1. **Testability** - Can I easily test this?
2. **Readability** - Will someone understand this in 6 months?
3. **Consistency** - Does this match project patterns?
4. **Simplicity** - Is this the simplest solution that works?
5. **Reversibility** - How hard to change later?

## Project Integration

### Learning the Codebase

- Find 3 similar features/components
- Identify common patterns and conventions
- Use same libraries/utilities when possible
- Follow existing test patterns

### Tooling

- Use project's existing build system
- Use project's test framework
- Use project's formatter/linter settings
- Don't introduce new tools without strong justification

## Quality Gates

### Definition of Done

- [ ] Tests written and passing
- [ ] Code follows project conventions
- [ ] No linter/formatter warnings
- [ ] Commit messages are clear
- [ ] Implementation matches plan
- [ ] No TODOs without issue numbers

### Test Guidelines

- Test behavior, not implementation
- One assertion per test when possible
- Clear test names describing scenario
- Use existing test utilities/helpers
- Tests should be deterministic

## Important Reminders

**NEVER**:

- Use `--no-verify` to bypass commit hooks
- Disable tests instead of fixing them
- Commit code that doesn't compile
- Make assumptions - verify with existing code

**ALWAYS**:

- Commit working code incrementally
- Update plan documentation as you go
- Learn from existing implementations
- Stop after 3 failed attempts and reassess

# Project Guidelines

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

## 🛡️ **NEW: Test Database Safeguards**

**IMPORTANT**: We've implemented comprehensive safeguards after experiencing mass test failures (253 → 0). These tools prevent database issues and provide instant recovery.

### **🚀 Quick Start - Use These First!**

```bash
# ALWAYS start with health check when debugging tests
just test-health-check          # ← START HERE for any test issues

# Run tests with automatic safeguards
just test-safe                  # ← Use this instead of regular 'just test'

# Emergency recovery (fixes 99% of test database issues)
just test-db-emergency-reset    # ← Nuclear option that actually works
```

### **Why These Safeguards Exist**

During development, we experienced a catastrophic test failure where **253 tests suddenly failed** due to test database contamination. The root cause was stale data from previous test runs that corrupted the baseline state.

These safeguards **prevent this from happening again** and provide **instant recovery** when it does.

### Test Database Management

#### Understanding Test Database Architecture

- **Separation**: Test database (`data/ashfolio_test.db`) is completely separate from development database (`data/ashfolio_dev.db`)
- **Global Test Data Pattern**: Uses a global setup pattern where baseline test data is created once in `test_helper.exs`
- **Required Baseline Data**: All tests expect a default user, default account, and common symbols to exist

#### Test Database Reset Procedures

**For Test Database Issues (Stale Data, Failures):**

```bash
# Complete test database reset (recommended approach)
MIX_ENV=test mix ecto.drop && MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate

# Restore required global test data
MIX_ENV=test mix run -e "Ashfolio.SQLiteHelpers.setup_global_test_data!()"

# Verify tests are working
just test-fast
```

**Alternative Reset (includes sample transactions):**

```bash
# This creates more data than tests typically need
MIX_ENV=test mix ecto.reset
```

#### Common Test Database Issues & Solutions

**Error: "Default user not found"**

- **Cause**: Global test data missing from database
- **Solution**: Run `MIX_ENV=test mix run -e "Ashfolio.SQLiteHelpers.setup_global_test_data!()"`

**Error: Expected X accounts, got Y accounts**

- **Cause**: Stale test data contamination from previous runs
- **Solution**: Complete test database reset (see procedures above)

**Error: "Database busy" or "database is locked"**

- **Cause**: SQLite concurrency issues, test processes accessing database simultaneously
- **Solution**: Tests use `async: false` and retry logic, but reset database if persistent

**Mass Test Failures (200+ failures)**

- **Cause**: Usually test database contamination or missing global test data
- **Solution**: Complete test database reset procedure above

#### Test Data Isolation Strategy

- **Per-Test Setup**: Each test creates its own specific data in setup blocks
- **Global Baseline**: Common data (default user, default account, common symbols) created once
- **Database Sandbox**: Uses Ecto SQL Sandbox for test isolation
- **SQLite Constraints**: All tests run with `async: false` due to SQLite limitations

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

## Troubleshooting & Debugging

### Systematic Test Failure Debugging Process

When encountering test failures, follow this systematic approach:

#### 1. **Assess the Scope**

```bash
# Get overall test health
just test-fast

# Check specific test
just test-file path/to/failing_test.exs
```

#### 2. **Identify the Pattern**

- **Single test failure**: Likely code logic or test-specific issue
- **Mass failures (50+)**: Usually infrastructure issue (database, setup, dependencies)
- **Consistent failure location**: Focus on that specific assertion or setup

#### 3. **Check Test Database State**

```bash
# Verify test database exists and has proper setup
MIX_ENV=test mix run -e "
  {:ok, accounts} = Ashfolio.Portfolio.Account.list()
  IO.puts(\"Accounts: #{length(accounts)}\")

  {:ok, users} = Ashfolio.Portfolio.User.list()
  IO.puts(\"Users: #{length(users)}\")
"
```

#### 4. **Analyze Error Messages**

- **"Default user not found"** → Missing global test data
- **"Expected X, got Y"** → Stale data contamination
- **"Database busy/locked"** → SQLite concurrency issues
- **Protocol/Module errors** → Code syntax or compilation issues

#### 5. **Apply Targeted Fixes**

- **Database issues**: Use test database reset procedures (see Test Database Management section)
- **Logic issues**: Focus on the failing assertion and surrounding code
- **Setup issues**: Check test setup blocks and global test data

#### 6. **Verify the Fix**

```bash
# Test the specific failing test
just test-file path/to/test.exs

# Run broader test suite to ensure no regressions
just test-fast

# Full verification if needed
just test
```

### Integration Test Debugging Example

**Case Study**: Integration test `account_management_flow_test.exs` failing with account count mismatch

**Problem**: Expected 5 accounts, got 4 - account creation appeared to fail
**Root Cause**: Stale test database data from previous runs contaminated the baseline
**Solution**: Complete test database reset + global test data restoration
**Result**: Test passed consistently, 253 → 0 test failures across entire suite

**Key Learnings**:

- Integration tests are more sensitive to database state than unit tests
- Always verify test database baseline when debugging integration tests
- Mass test failures often indicate infrastructure issues, not code issues

### Quick Reference: Test Debugging Commands

```bash
# === ASSESSMENT & HEALTH CHECKS ===
just test-health-check              # 🛡️ Check test database health FIRST
just test-safe                      # Run tests with automatic health check
just test-fast                      # Quick health check (372 tests)
just test-file path/to/test.exs     # Run specific test file

# === TEST DATABASE SAFEGUARDS (NEW!) ===
just test-db-validate               # Validate test database state
just test-db-reset                  # Safe test database reset
just test-db-emergency-reset        # Emergency recovery (for mass failures)

# === TEST DATABASE RESET (Most Common Fix) ===
MIX_ENV=test mix ecto.drop && MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate
MIX_ENV=test mix run -e "Ashfolio.SQLiteHelpers.setup_global_test_data!()"
just test-fast                      # Verify fix

# === DEBUGGING SPECIFIC TESTS ===
just test-file-verbose path/to/test.exs    # Run with detailed output
just test-file path/to/test.exs --trace    # Run with execution trace

# === DATABASE STATE INSPECTION ===
MIX_ENV=test mix run -e "
  user_count = Ashfolio.Repo.aggregate(Ashfolio.Portfolio.User, :count)
  account_count = Ashfolio.Repo.aggregate(Ashfolio.Portfolio.Account, :count)
  symbol_count = Ashfolio.Repo.aggregate(Ashfolio.Portfolio.Symbol, :count)
  IO.puts(\"Users: #{user_count}, Accounts: #{account_count}, Symbols: #{symbol_count}\")
"

# === DEVELOPMENT DATABASE (SEPARATE) ===
just reset                          # Reset development database
just reseed                         # Re-seed development database
```

### 🛡️ **NEW SAFEGUARDS IMPLEMENTED**

After experiencing mass test failures (253 → 0), we've implemented several safeguards:

**Automatic Health Checks**: Built into `just test-safe`

- Database connectivity validation
- Baseline data verification (users, accounts, symbols)
- Clear error messages with fix instructions

**Emergency Recovery**: `just test-db-emergency-reset`

- Complete test database rebuild procedure
- Implements the exact fix that resolved our 253-failure crisis
- Includes confirmation prompts for safety

**Validation Functions**: `just test-db-validate`

- Validates global test data integrity
- Checks for expected baseline records
- Provides detailed validation output

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
