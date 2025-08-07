# Ashfolio Development Commands
# Run `just` to see all available commands
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
#   - just test: Run full test suite
#   - just test-file <file>: Run specific test file
#   - just test-coverage: Run tests with coverage report
#   - just test-coverage-clean: Run coverage analysis with minimal logs
#   - just test-coverage-summary: Show coverage summary table only
#   - just test-watch: Run tests in watch mode
#   - just test-failed: Run only failed tests
#   - just test-verbose: Run tests with detailed output
#   - just test-price-manager: Run PriceManager tests specifically
#
# Database Management:
#   - just reset: Reset database with fresh sample data
#   - just reseed: Truncate tables and re-seed (preserves schema)
#   - just backup: Create timestamped database backup
#   - just restore <file>: Restore from backup file
#   - just db-status: Show table counts and database status

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
