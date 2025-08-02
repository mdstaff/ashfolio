# Ashfolio Development Commands
# Run `just` to see all available commands
#
# Development:
#   - just dev: Setup and start development server
#   - just compile: Compile project (check for errors)
#   - just format: Format code
#   - just check: Run format + compile + test
#
# Testing:
#   - just test: Run full test suite
#   - just test-file <file>: Run specific test file
#   - just test-coverage: Run tests with coverage report
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

# Run test suite
test:
    @echo "🧪 Running test suite..."
    mix test

# Run specific test file
test-file file:
    @echo "🧪 Running tests for {{file}}..."
    mix test {{file}}

# Run tests with coverage report
test-coverage:
    @echo "🧪 Running test suite with coverage report..."
    mix test --cover

# Run tests in watch mode (re-runs on file changes)
test-watch:
    @echo "🧪 Running tests in watch mode..."
    mix test.watch

# Run only failed tests from last run
test-failed:
    @echo "🧪 Running only failed tests..."
    mix test --failed

# Run tests with detailed output
test-verbose:
    @echo "🧪 Running tests with verbose output..."
    mix test --trace

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

# Check code formatting
format:
    @echo "✨ Formatting code..."
    mix format

# Check for code issues
check: format compile test
    @echo "✅ All checks passed!"
