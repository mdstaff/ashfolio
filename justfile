# Ashfolio Development Commands (Simplified)
# Type 'just' to see available commands

# Default: show help
default:
    @just --list --unsorted

# ============================================================================
# DAILY WORKFLOW - Essential commands for development
# ============================================================================

# 🚀 Start development server
dev mode="":
    #!/usr/bin/env bash
    case "{{mode}}" in
        "")
            echo "🚀 Starting Phoenix server..."
            echo "📱 Open http://localhost:4000"
            mix setup && mix phx.server
            ;;
        bg|background)
            echo "🚀 Starting Phoenix server in background..."
            mix setup
            nohup mix phx.server > phoenix.log 2>&1 &
            echo "✅ Server started (logs in phoenix.log)"
            echo "💡 Use 'just server stop' to stop"
            ;;
        *)
            echo "Unknown mode: {{mode}}"
            echo "Available modes: (default), bg/background"
            ;;
    esac

# 🧪 Run tests (smart detection based on changes)
test filter="":
    #!/usr/bin/env bash
    if [ -z "{{filter}}" ]; then
        echo "🧪 Running standard test suite..."
        mix test --exclude performance --exclude slow --exclude integration --no-color
    elif [ "{{filter}}" = "all" ]; then
        echo "🧪 Running ALL tests..."
        mix test --no-color
    elif [ "{{filter}}" = "unit" ]; then
        echo "🧪 Running unit tests..."
        mix test --only unit --no-color
    elif [ "{{filter}}" = "integration" ]; then
        echo "🧪 Running integration tests..."
        mix test --only integration --no-color
    elif [ "{{filter}}" = "live" ]; then
        echo "🧪 Running LiveView tests..."
        mix test --only liveview --no-color
    elif [ "{{filter}}" = "perf" ]; then
        echo "🧪 Running performance tests..."
        mix test test/performance/ --trace --no-color
    elif [ "{{filter}}" = "failed" ]; then
        echo "🧪 Re-running failed tests..."
        mix test --failed --no-color
    elif [ "{{filter}}" = "smoke" ]; then
        echo "🧪 Running smoke tests..."
        mix test --only smoke --no-color
    elif [ -f "{{filter}}" ]; then
        echo "🧪 Testing {{filter}}..."
        mix test --no-color {{filter}} 
    else
        echo "🧪 Running tests matching '{{filter}}'..."
        mix test --only {{filter}} --no-color
    fi

# ✅ Run all checks (format, compile, credo, test)
check:
    @echo "✅ Running all checks..."
    @just format
    @just compile
    @just credo
    @just test smoke
    @echo "✅ All checks passed!"

# 🔧 Fix common issues automatically
fix:
    @echo "🔧 Fixing common issues..."
    @echo "  → Formatting code..."
    @mix format
    @echo "  → Cleaning build artifacts..."
    @mix clean
    @echo "  → Recompiling..."
    @mix compile
    @echo "  → Checking database..."
    @MIX_ENV=test mix run -e "Ashfolio.SQLiteHelpers.test_database_health_check!()" || just db test-reset
    @echo "✅ Issues fixed!"

# 🎯 Run Credo code quality checks
credo:
    @echo "🎯 Running Credo code quality analysis..."
    @mix credo --strict || true
    @echo "✅ Credo analysis complete"

# 📦 Pre-commit validation
commit:
    @echo "📦 Pre-commit validation..."
    @just format
    @just compile
    @just credo
    @just test unit
    @just test smoke
    @echo "✅ Ready to commit!"

# ============================================================================
# TESTING - Comprehensive test commands
# ============================================================================

# 👀 Run tests in watch mode
test-watch filter="":
    @echo "👀 Starting test watcher..."
    @if [ -z "{{filter}}" ]; then \
        mix test.watch; \
    else \
        mix test.watch {{filter}}; \
    fi

# 🔍 Run tests with debug output
test-debug filter="":
    @echo "🔍 Running tests with debug output..."
    @if [ -z "{{filter}}" ]; then \
        mix test --trace; \
    else \
        mix test {{filter}} --trace; \
    fi

# 🎯 Run tests with enhanced failure reporting
test-clear filter="":
    @echo "🎯 Running tests with enhanced failure reporting..."
    @if [ -z "{{filter}}" ]; then \
        mix test --formatter Ashfolio.ClearFailureFormatter; \
    else \
        mix test {{filter}} --formatter Ashfolio.ClearFailureFormatter; \
    fi

# 📊 Generate test coverage report
coverage:
    @echo "📊 Generating coverage report..."
    @mix test --cover

# 🤖 CI pipeline stages
ci stage="all":
    #!/usr/bin/env bash
    case "{{stage}}" in
        unit)
            echo "🤖 CI Stage 1: Unit Tests"
            mix test --only unit --only smoke --no-color
            ;;
        integration)
            echo "🤖 CI Stage 2: Integration Tests"
            mix test --only integration --no-color
            ;;
        e2e)
            echo "🤖 CI Stage 3: End-to-End Tests"
            mix test --only liveview --only ui --no-color
            ;;
        perf)
            echo "🤖 CI Stage 4: Performance Tests"
            mix test --no-color test/performance/
            ;;
        all)
            echo "🤖 Running full CI pipeline..."
            just ci unit
            just ci integration
            just ci e2e
            echo "✅ CI pipeline complete!"
            ;;
        *)
            echo "Unknown CI stage: {{stage}}"
            echo "Available stages: unit, integration, e2e, perf, all"
            exit 1
            ;;
    esac

# ============================================================================
# DATABASE - Database management
# ============================================================================

# 🗄️ Database operations
db action="status" force="":
    #!/usr/bin/env bash
    case "{{action}}" in
        status)
            echo "📊 Database status:"
            mix run -e "alias Ashfolio.Repo; IO.puts(\"Users: #{Repo.aggregate(Ashfolio.Portfolio.User, :count)}\"); IO.puts(\"Accounts: #{Repo.aggregate(Ashfolio.Portfolio.Account, :count)}\"); IO.puts(\"Symbols: #{Repo.aggregate(Ashfolio.Portfolio.Symbol, :count)}\"); IO.puts(\"Transactions: #{Repo.aggregate(Ashfolio.Portfolio.Transaction, :count)}\");"
            ;;
        reset)
            echo "🔄 Resetting database..."
            mix ecto.reset
            ;;
        setup)
            if [ "{{force}}" = "force" ] || [ "{{force}}" = "--force" ]; then
                echo "🔧 Force setting up database (will backup existing)..."
                mix run scripts/setup-database.exs -- --force
            else
                echo "🔧 Setting up database with database-as-user architecture..."
                mix run scripts/setup-database.exs
            fi
            ;;
        test-reset)
            echo "🔄 Resetting test database..."
            MIX_ENV=test mix ecto.drop
            MIX_ENV=test mix ecto.create
            MIX_ENV=test mix ecto.migrate
            MIX_ENV=test mix run -e "Ashfolio.SQLiteHelpers.setup_global_test_data!()"
            ;;
        backup)
            echo "💾 Creating database backup..."
            mix run -e "Ashfolio.DatabaseManager.create_backup() |> IO.puts()"
            ;;
        restore)
            echo "🔄 Restoring database..."
            echo "Usage: just db-restore <backup-file>"
            ;;
        fix)
            echo "🚨 Emergency database repair..."
            MIX_ENV=test mix run -e "Ashfolio.SQLiteHelpers.emergency_test_db_reset!()"
            ;;
        *)
            echo "Unknown action: {{action}}"
            echo "Available actions: status, reset, setup, test-reset, backup, restore, fix"
            echo ""
            echo "Setup usage:"
            echo "  just db setup        # Setup new database (fails if exists)"
            echo "  just db setup force  # Force setup (backs up existing)"
            ;;
    esac

# ============================================================================
# SERVER - Development server management
# ============================================================================

# 🚀 Server management
server mode="":
    #!/usr/bin/env bash
    case "{{mode}}" in
        "")
            echo "🚀 Starting Phoenix server..."
            mix phx.server
            ;;
        bg|background)
            echo "🚀 Starting Phoenix server in background..."
            nohup mix phx.server > phoenix.log 2>&1 &
            echo "✅ Server started (logs in phoenix.log)"
            echo "💡 Use 'just server stop' to stop"
            ;;
        stop)
            echo "🛑 Stopping Phoenix server..."
            pkill -f "mix phx.server" || echo "No server running"
            pkill -f "beam.smp.*ashfolio" || true
            echo "✅ Server stopped"
            ;;
        status)
            echo "📊 Server status check..."
            if pgrep -f "mix phx.server" > /dev/null; then
                echo "✅ Phoenix server is running"
                echo "📱 Available at: http://localhost:4000"
                
                # Check health endpoint for detailed status
                if health_response=$(curl -f -s http://localhost:4000/health 2>/dev/null); then
                    echo "🌐 Server is responding to requests"
                    echo "🏥 Health check endpoint: http://localhost:4000/health"
                    
                    # Parse health status if jq is available
                    if command -v jq > /dev/null 2>&1; then
                        health_status=$(echo "$health_response" | jq -r '.status // "unknown"')
                        db_status=$(echo "$health_response" | jq -r '.database.status // "unknown"')
                        uptime=$(echo "$health_response" | jq -r '.system.uptime_seconds // "unknown"')
                        memory=$(echo "$health_response" | jq -r '.system.memory.total_mb // "unknown"')
                        
                        echo "   Status: $health_status"
                        echo "   Database: $db_status"
                        echo "   Uptime: ${uptime}s"
                        echo "   Memory: ${memory}MB"
                    else
                        echo "   💡 Install 'jq' for detailed health info"
                    fi
                elif curl -f -s http://localhost:4000 > /dev/null 2>&1; then
                    echo "🌐 Server is responding but health endpoint unavailable"
                    echo "   (Health endpoint may not be implemented yet)"
                else
                    echo "⚠️  Server process running but not responding"
                fi
            else
                echo "❌ Phoenix server is not running"
                echo "💡 Use 'just server' or 'just dev' to start"
            fi
            ;;
        *)
            echo "Unknown mode: {{mode}}"
            echo "Available modes: (default), bg/background, stop, status"
            ;;
    esac

# ============================================================================
# UTILITIES - Helper commands
# ============================================================================

# 💻 Interactive Elixir console
console:
    @echo "💻 Starting interactive console..."
    iex -S mix

# 🧹 Clean all build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    mix clean
    rm -rf _build deps
    @echo "✅ Clean complete"

# 🧭 Generate Code GPS manifest for codebase navigation
gps:
    @echo "🧭 Analyzing codebase structure..."
    @mix code_gps
    @echo "📍 Code GPS manifest generated: .code-gps.yaml"

# ❓ Show help for a specific topic
help topic="":
    #!/usr/bin/env bash
    if [ -z "{{topic}}" ]; then
        echo "📚 Ashfolio Development Guide"
        echo ""
        echo "Quick Start:"
        echo "  just dev        → Start development server"
        echo "  just test       → Run tests"
        echo "  just check      → Run all checks"
        echo "  just recompile  → Clean compile (fixes module warnings)"
        echo ""
        echo "Testing:"
        echo "  just test unit  → Run unit tests only"
        echo "  just test all   → Run all tests"
        echo "  just test-watch → Watch mode"
        echo ""
        echo "For more help: just help <topic>"
        echo "Topics: test, database, server, workflow"
    elif [ "{{topic}}" = "test" ]; then
        echo "🧪 Testing Guide"
        echo ""
        echo "Test Filters:"
        echo "  just test         → Standard tests (fast)"
        echo "  just test unit    → Unit tests only"
        echo "  just test integration → Integration tests"
        echo "  just test live    → LiveView tests"
        echo "  just test perf    → Performance tests"
        echo "  just test all     → All tests"
        echo "  just test failed  → Re-run failures"
        echo "  just test <file>  → Specific file"
        echo ""
        echo "Test Modes:"
        echo "  just test-watch   → Auto-run on changes"
        echo "  just test-debug   → Verbose output"
        echo "  just test-clear   → Enhanced failure reporting"
        echo "  just coverage     → Coverage report"
    elif [ "{{topic}}" = "database" ]; then
        echo "🗄️ Database Guide"
        echo ""
        echo "Commands:"
        echo "  just db          → Show status"
        echo "  just db reset    → Reset database"
        echo "  just db backup   → Create backup"
        echo "  just db fix      → Emergency repair"
    elif [ "{{topic}}" = "workflow" ]; then
        echo "🔄 Development Workflow"
        echo ""
        echo "1. Start development:"
        echo "   just dev"
        echo ""
        echo "2. Make changes and test:"
        echo "   just test        → Quick tests"
        echo "   just test-watch  → Continuous testing"
        echo ""
        echo "3. Before committing:"
        echo "   just commit      → Pre-commit checks"
        echo ""
        echo "4. Fix issues:"
        echo "   just fix         → Auto-fix common issues"
    else
        echo "Unknown topic: {{topic}}"
        echo "Available topics: test, database, server, workflow"
    fi

# ============================================================================
# SHORTCUTS - Single-letter aliases for common commands
# ============================================================================

alias t := test
alias d := dev
alias c := check
alias f := fix
alias s := server

# ============================================================================
# PRIVATE HELPERS - Not shown in list
# ============================================================================

# Format code
[private]
format:
    @echo "✨ Formatting code..."
    @mix format

# Compile project
[private]
compile:
    @echo "🔨 Compiling..."
    @mix compile

# 🔄 Clean compile (removes module redefinition warnings)
recompile:
    @echo "🔄 Clean recompile (eliminates module redefinition warnings)..."
    @mix clean
    @mix compile
    @echo "✅ Clean compile complete"