# Ashfolio Development Commands
# Run `just` to see all available commands

#   # Architectural focus
#   just test-ash           # Business logic tests 0 failures
#   just test-liveview      # UI tests  18 failures
#   just test-calculations  # Portfolio math tests 0 failures
#   just test-market-data   # Price system tests 0 failures
#   just test-mocked        # 0 Failures 2 Skipped

#   # Performance-based
#   just test-unit          # Isolated tests 0 failures
#   just test-fast          # Quick feedback loop 10 failures
#   just test-slow          # Comprehensive tests 18 failures

#   # Development workflow
#   just test-smoke         # Essential tests 0 failures
#   just test-regression    # Bug fix validation 0 tests run
#   just test-error-handling # Fault tolerance 0 tests run
#   just test-integration: Run end-to-end workflow tests
#   just test-ui: Run user interface tests
#
# Development:
#   - just dev: Setup and start development server (BLOCKING)
#   - just dev-bg: Setup and start development server (BACKGROUND)
#   - just server: Start Phoenix server (BLOCKING)
#   - just server-bg: Start Phoenix server (BACKGROUND)
#   - just server-check: Check for server startup warnings (NON-BLOCKING)
#   - just compile: Compile project (NON-BLOCKING)
#   - just compile-warnings: Check for compilation warnings (NON-BLOCKING)
#   - just format: Format code (NON-BLOCKING)
#   - just check: Run format + compile + test (NON-BLOCKING)
#
# Testing:
#   - just test: Run main test suite (excludes slow/seeding tests)
#   - just test-file <file>: Run specific test file
#   - just test-all: Run full test suite including seeding tests
#   - just test-coverage: Run tests with coverage report
#   - just test-coverage-clean: Run coverage analysis with minimal logs
#   - just test-coverage-summary: Show coverage summary table only
#   - just test-watch: Run tests in watch mode
#   - just test-failed: Run only failed tests
#   - just test-verbose: Run tests with detailed output
#
# Modular Testing (by Architecture Layer):
#   - just test-ash: Run Ash Resource business logic tests
#   - just test-liveview: Run Phoenix LiveView UI tests
#   - just test-calculations: Run portfolio calculation tests
#   - just test-market-data: Run market data system tests
#   - just test-context-api: Run Context API high-level interface tests
#   - just test-integration: Run end-to-end workflow tests
#   - just test-ui: Run user interface tests
#
# Modular Testing (by Performance/Dependencies):
#   - just test-fast: Run fast tests for development feedback
#   - just test-unit: Run isolated unit tests
#   - just test-slow: Run slower, comprehensive tests
#   - just test-external: Run tests requiring external APIs
#   - just test-mocked: Run tests with mocked dependencies
#
# Modular Testing (by Development Workflow):
#   - just test-smoke: Run essential tests that must always pass
#   - just test-regression: Run tests for previously fixed bugs
#   - just test-edge-cases: Run boundary condition tests
#   - just test-error-handling: Run error condition tests
#
# Database Management:
#   - just reset: Reset database with fresh sample data
#   - just reseed: Truncate tables and re-seed (preserves schema)
#   - just backup: Create timestamped database backup
#   - just restore <file>: Restore from backup file
#   - just db-status: Show table counts and database status
#
# Test Database Safeguards (NEW!):
#   - just test-health-check: Check test database health before running tests
#   - just test-safe: Run tests with automatic health check
#   - just test-db-validate: Validate test database state
#   - just test-db-reset: Safe test database reset procedure
#   - just test-db-emergency-reset: Emergency recovery for mass failures

# Show all available commands
default:
    @just --list

# Setup and start development server (like npm start)
dev: setup
    @echo "🚀 Starting Phoenix server..."
    @echo "📱 Open http://localhost:4000 in your browser"
    mix phx.server

# Setup and start development server in background
dev-bg: setup
    @echo "🚀 Starting Phoenix server in background..."
    @echo "📱 Open http://localhost:4000 in your browser"
    @nohup mix phx.server > phoenix.log 2>&1 &
    @echo "✅ Server started in background (logs in phoenix.log)"
    @echo "🛑 Use 'just stop' to stop the server"

# Install dependencies and setup database
setup:
    @echo "🔧 Setting up Ashfolio development environment..."
    mix setup

# Start Phoenix server only (foreground)
server:
    @echo "🚀 Starting Phoenix server..."
    mix phx.server

# Start Phoenix server in background
server-bg:
    @echo "🚀 Starting Phoenix server in background..."
    @nohup mix phx.server > phoenix.log 2>&1 &
    @echo "✅ Server started in background (logs in phoenix.log)"
    @echo "🛑 Use 'just stop' to stop the server"

# Stop Phoenix server
stop:
    @echo "🛑 Stopping Phoenix server..."
    @pkill -f "mix phx.server" || echo "No Phoenix server running"
    @pkill -f "beam.smp.*ashfolio" || echo "No Elixir processes found"
    @echo "✅ Server stopped"

# Run main test suite (silent by default)
test:
    @echo "🧪 Running main test suite..."
    @mix test --exclude seeding 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Tests failed - run 'just test-verbose' for details" && exit 1)

# Run seeding tests (silent by default)
test-seeding:
    @echo "🧪 Running seeding tests..."
    @mix test --only seeding 2>&1 | grep -E "(\.+|Finished|tests,|failures|excluded)" | grep -v "Creating\|Created\|Ready to start" || (echo "❌ Seeding tests failed - run 'just test-seeding-verbose' for details" && exit 1)

# Run full test suite (silent by default)
test-all:
    @echo "🧪 Running full test suite..."
    @mix test --include seeding 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Tests failed - run 'just test-all-verbose' for details" && exit 1)

# Run specific test file (silent by default)
test-file file:
    @echo "🧪 Running tests for {{file}}..."
    @mix test {{file}} 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Test file failed - run 'just test-file-verbose {{file}}' for details" && exit 1)

# Run tests with coverage report
test-coverage:
    @echo "🧪 Running test suite with coverage report..."
    mix test --cover --exclude seeding

# Run tests with clean coverage report (test summary + coverage table)
test-coverage-clean:
    @echo "🧪 Running coverage analysis (clean output)..."
    @mix test --cover --exclude seeding 2>/dev/null | grep -E "(Finished|tests,|failures|excluded|Percentage|---|\..*%|Total)" || echo "❌ Coverage analysis failed - run 'just test-coverage' for details"

# Show coverage summary table only
test-coverage-summary:
    @echo "📊 Test Coverage Summary:"
    @mix test --cover --exclude seeding 2>/dev/null | sed -n '/Percentage | Module/,/Total/p' || echo "❌ Coverage analysis failed - run 'just test-coverage' for details"

# Run tests in watch mode (re-runs on file changes)
test-watch:
    @echo "🧪 Running tests in watch mode..."
    mix test.watch --exclude seeding

# Run only failed tests from last run
test-failed:
    @echo "🧪 Running only failed tests..."
    mix test --failed

# VERBOSE VERSIONS (show full output)
# Run main test suite with full output
test-verbose:
    @echo "🧪 Running main test suite (verbose)..."
    mix test --exclude seeding --trace

# Run seeding tests with full output
test-seeding-verbose:
    @echo "🧪 Running seeding tests (verbose)..."
    mix test --only seeding --trace

# Run full test suite with full output
test-all-verbose:
    @echo "🧪 Running full test suite (verbose)..."
    mix test --include seeding --trace

# Run specific test file with full output
test-file-verbose file:
    @echo "🧪 Running tests for {{file}} (verbose)..."
    mix test {{file}} --trace

# LEGACY COMMANDS (for compatibility)
# Run tests with minimal output (summary only)
test-quiet:
    @echo "🧪 Running tests with minimal output..."
    mix test --exclude seeding --formatter ExUnit.CLIFormatter

# Run tests and show only summary
test-summary:
    @echo "🧪 Running test suite (summary only)..."
    @mix test --exclude seeding 2>/dev/null | tail -n 10 || echo "❌ Tests failed - run 'just test-failed' for details"

# Run PriceManager tests specifically
test-price-manager:
    @echo "🧪 Running PriceManager tests..."
    mix test test/ashfolio/market_data/price_manager_test.exs

# ============================================================================
# MODULAR TESTING COMMANDS - ARCHITECTURAL LAYER FILTERS
# ============================================================================

# Run Ash Resource business logic tests
test-ash:
    @echo "🧪 Running Ash Resource business logic tests..."
    @mix test --only ash_resources 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Ash Resource tests failed - run with --include ash_resources for details" && exit 1)

# Run Phoenix LiveView UI tests
test-liveview:
    @echo "🧪 Running Phoenix LiveView UI tests..."
    @mix test --only liveview 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ LiveView tests failed - run with --include liveview for details" && exit 1)

# Run portfolio calculation tests
test-calculations:
    @echo "🧪 Running portfolio calculation tests..."
    @mix test --only calculations 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Calculation tests failed - run with --include calculations for details" && exit 1)

# Run market data system tests
test-market-data:
    @echo "🧪 Running market data system tests..."
    @mix test --only market_data 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Market data tests failed - run with --include market_data for details" && exit 1)

# Run Context API tests
test-context-api:
    @echo "🧪 Running Context API tests..."
    @mix test --only context_api 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Context API tests failed - run with --include context_api for details" && exit 1)

# Run end-to-end workflow tests
test-integration:
    @echo "🧪 Running integration workflow tests..."
    @mix test --only integration 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Integration tests failed - run with --include integration for details" && exit 1)

# Run user interface tests
test-ui:
    @echo "🧪 Running user interface tests..."
    @mix test --only ui 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ UI tests failed - run with --include ui for details" && exit 1)

# ============================================================================
# MODULAR TESTING COMMANDS - PERFORMANCE/DEPENDENCY FILTERS
# ============================================================================

# Run fast tests for development feedback
test-fast:
    @echo "🧪 Running fast tests for development feedback..."
    @mix test --only fast 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Fast tests failed - run with --include fast for details" && exit 1)

# Run isolated unit tests
test-unit:
    @echo "🧪 Running isolated unit tests..."
    @mix test --only unit 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Unit tests failed - run with --include unit for details" && exit 1)

# Run slower, comprehensive tests
test-slow:
    @echo "🧪 Running slower, comprehensive tests..."
    @mix test --only slow 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Slow tests failed - run with --include slow for details" && exit 1)

# Run tests requiring external APIs
test-external:
    @echo "🧪 Running tests with external API dependencies..."
    @mix test --only external_deps 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ External dependency tests failed - run with --include external_deps for details" && exit 1)

# Run tests with mocked dependencies
test-mocked:
    @echo "🧪 Running tests with mocked dependencies..."
    @mix test --only mocked 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Mocked tests failed - run with --include mocked for details" && exit 1)

# ============================================================================
# MODULAR TESTING COMMANDS - DEVELOPMENT WORKFLOW FILTERS
# ============================================================================

# Run essential tests that must always pass
test-smoke:
    @echo "🧪 Running smoke tests (essential functionality)..."
    @mix test --only smoke 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Smoke tests failed - run with --include smoke for details" && exit 1)

# Run tests for previously fixed bugs
test-regression:
    @echo "🧪 Running regression tests..."
    @mix test --only regression 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Regression tests failed - run with --include regression for details" && exit 1)

# Run boundary condition tests
test-edge-cases:
    @echo "🧪 Running edge case tests..."
    @mix test --only edge_cases 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Edge case tests failed - run with --include edge_cases for details" && exit 1)

# Run error condition tests
test-error-handling:
    @echo "🧪 Running error handling tests..."
    @mix test --only error_handling 2>/dev/null | grep -E "(\.+|Finished|tests,|failures|excluded)" || (echo "❌ Error handling tests failed - run with --include error_handling for details" && exit 1)

# ============================================================================
# MODULAR TESTING COMMANDS - VERBOSE VARIANTS
# ============================================================================

# Run architectural layer tests with verbose output
test-ash-verbose:
    @echo "🧪 Running Ash Resource tests (verbose)..."
    mix test --only ash_resources --trace

test-liveview-verbose:
    @echo "🧪 Running LiveView tests (verbose)..."
    mix test --only liveview --trace

test-calculations-verbose:
    @echo "🧪 Running calculation tests (verbose)..."
    mix test --only calculations --trace

test-market-data-verbose:
    @echo "🧪 Running market data tests (verbose)..."
    mix test --only market_data --trace

test-context-api-verbose:
    @echo "🧪 Running Context API tests (verbose)..."
    mix test --only context_api --trace

test-integration-verbose:
    @echo "🧪 Running integration tests (verbose)..."
    mix test --only integration --trace

# Run performance/dependency tests with verbose output
test-fast-verbose:
    @echo "🧪 Running fast tests (verbose)..."
    mix test --only fast --trace

test-unit-verbose:
    @echo "🧪 Running unit tests (verbose)..."
    mix test --only unit --trace

test-slow-verbose:
    @echo "🧪 Running slow tests (verbose)..."
    mix test --only slow --trace

# Run database migrations
migrate:
    @echo "🗃️  Running database migrations..."
    mix ecto.migrate

# Reset database with fresh sample data
reset:
    @echo "🗃️  Resetting database with fresh sample data..."
    mix ecto.reset

# Truncate tables and re-seed with fresh data (development only)
reseed:
    @echo "🌱 Truncating tables and re-seeding with fresh data..."
    @echo "⚠️  WARNING: This will delete ALL data!"
    mix run -e "Ashfolio.DatabaseManager.reset_and_reseed!()"

# Create database backup
backup:
    @echo "💾 Creating database backup..."
    mix run -e "Ashfolio.DatabaseManager.create_backup() |> IO.puts()"

# List available database backups
backups:
    @echo "📋 Available database backups:"
    mix run -e "Ashfolio.DatabaseManager.list_backups() |> Enum.each(&IO.puts/1)"

# Restore database from backup (requires backup file path)
restore backup_file:
    @echo "🔄 Restoring database from {{backup_file}}..."
    @echo "⚠️  WARNING: This will overwrite current database!"
    mix run -e "Ashfolio.DatabaseManager.restore_backup(\"{{backup_file}}\")"

# Show database status and table counts
db-status:
    @echo "📊 Database status:"
    @mix run -e "alias Ashfolio.Repo; IO.puts(\"Users: #{Repo.aggregate(Ashfolio.Portfolio.User, :count)}\"); IO.puts(\"Accounts: #{Repo.aggregate(Ashfolio.Portfolio.Account, :count)}\"); IO.puts(\"Symbols: #{Repo.aggregate(Ashfolio.Portfolio.Symbol, :count)}\"); IO.puts(\"Transactions: #{Repo.aggregate(Ashfolio.Portfolio.Transaction, :count)}\");"

# === TEST DATABASE SAFEGUARDS ===

# Check test database health before running tests
test-health-check:
    @echo "🛡️  Checking test database health..."
    @MIX_ENV=test mix run -e "Ashfolio.SQLiteHelpers.test_database_health_check!()"

# Emergency test database recovery (our proven fix for mass test failures)
test-db-emergency-reset:
    @echo "🚨 EMERGENCY: Resetting test database..."
    @echo "⚠️  This will completely reset the test database!"
    @echo "Press Enter to continue or Ctrl+C to abort..."
    @read
    @MIX_ENV=test mix run -e "Ashfolio.SQLiteHelpers.emergency_test_db_reset!()"

# Complete test database reset (safe version for regular use)
test-db-reset:
    @echo "🔄 Resetting test database (safe procedure)..."
    @MIX_ENV=test mix ecto.drop && MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate
    @MIX_ENV=test mix run -e "Ashfolio.SQLiteHelpers.setup_global_test_data!()"
    @echo "✅ Test database reset complete"

# Validate test database state
test-db-validate:
    @echo "🔍 Validating test database state..."
    @MIX_ENV=test mix run -e "Ashfolio.SQLiteHelpers.validate_global_test_data!()"

# Enhanced test command with health check
test-safe: test-health-check test

# Clean build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    mix clean
    rm -rf _build deps

# Install/update dependencies
deps:
    @echo "📦 Installing dependencies..."
    mix deps.get

# Build assets
assets:
    @echo "🎨 Building assets..."
    mix assets.build

# Interactive Elixir console
console:
    @echo "💻 Starting interactive Elixir console..."
    iex -S mix

# Interactive console with Phoenix server
console-web:
    @echo "💻 Starting interactive console with Phoenix server..."
    iex -S mix phx.server

# Compile the project (check for compilation errors)
compile:
    @echo "🔨 Compiling project..."
    mix compile

# Check for compilation warnings
compile-warnings:
    @echo "⚠️  Checking for compilation warnings..."
    mix compile --force --warnings-as-errors 2>&1 || echo "✅ No compilation warnings found"

# Start server and check for warnings
server-check:
    @echo "🚀 Starting Phoenix server and checking for warnings..."
    @timeout 10s mix phx.server 2>&1 | head -20 | grep -i warning || echo "✅ No startup warnings found"

# Check code formatting
format:
    @echo "✨ Formatting code..."
    mix format

# Check for code issues
check: format compile test
    @echo "✅ All checks passed!"
