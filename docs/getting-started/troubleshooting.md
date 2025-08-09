# Troubleshooting Guide

Common issues and solutions for getting Ashfolio running smoothly.

## Installation Issues

### Elixir/Erlang Installation Problems

**Error**: `elixir: command not found`
```bash
# Install via Homebrew (macOS)
brew install elixir

# Verify installation
elixir --version
# Should show: Elixir 1.14+ (compiled with Erlang/OTP 25+)
```

**Error**: Version mismatch or old Elixir
```bash
# Update Homebrew and Elixir
brew update
brew upgrade elixir

# If still issues, try clean install
brew uninstall elixir erlang
brew install elixir
```

### Just Task Runner Issues

**Error**: `just: command not found`
```bash
# Install Just
brew install just

# Verify installation
just --version
```

**Error**: Just commands fail
```bash
# Make sure you're in the project directory
cd path/to/ashfolio

# Check if justfile exists
ls -la justfile

# Try running commands manually if Just fails
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

## Database Issues

### Database Connection Problems

**Error**: `database "ashfolio_dev.db" does not exist`
```bash
# Create database
mix ecto.create

# Or use Just command
just setup
```

**Error**: Database locked or busy
```bash
# Stop any running servers
pkill -f "phx.server"

# Remove database locks
rm -f data/*.db-wal data/*.db-shm

# Reset database
just reset
```

### Migration Issues

**Error**: Migration fails or pending migrations
```bash
# Run pending migrations
mix ecto.migrate

# If migrations are corrupted, reset database
mix ecto.drop
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs
```

**Error**: Sample data missing
```bash
# Re-seed database
mix run priv/repo/seeds.exs

# Or full reset with sample data
just reset
```

## Server Issues

### Phoenix Server Problems

**Error**: `Port 4000 already in use`
```bash
# Find and kill process using port 4000
lsof -ti:4000 | xargs kill -9

# Or use a different port
PORT=4001 just server

# Or use Phoenix built-in port detection
mix phx.server
```

**Error**: Server crashes on startup
```bash
# Check for compilation errors
mix compile

# Check for missing dependencies
mix deps.get

# Check database is set up
just setup
```

### LiveView Issues

**Error**: LiveView socket errors or crashes
```bash
# Clear browser cache and refresh
# Check browser console for JavaScript errors

# Restart server with clean compile
mix clean
just dev
```

## Testing Issues

### Test Database Problems

**Error**: Mass test failures (100+ failing)
```bash
# Use emergency test database reset
just test-db-emergency-reset

# Or manual reset
MIX_ENV=test mix ecto.drop
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
MIX_ENV=test mix run -e "Ashfolio.SQLiteHelpers.setup_global_test_data!()"
```

**Error**: "Default user not found" in tests
```bash
# Set up global test data
MIX_ENV=test mix run -e "Ashfolio.SQLiteHelpers.setup_global_test_data!()"

# Verify test database health
just test-health-check
```

**Error**: "Database busy" errors in tests
```bash
# SQLite concurrency issue - reset test database
just test-db-reset

# Run health check
just test-health-check

# Try running tests with safeguards
just test-safe
```

### Test-Specific Issues

**Error**: Specific test file fails
```bash
# Run specific test with verbose output
just test-file-verbose path/to/test.exs

# Check test setup and database state
MIX_ENV=test iex -S mix
```

**Error**: Integration tests fail
```bash
# Integration tests are sensitive to database state
just test-db-emergency-reset

# Run just integration tests
just test-integration
```

## Development Issues

### Compilation Problems

**Error**: Mix compilation fails
```bash
# Clean and recompile
mix clean
mix compile

# Check for syntax errors
mix format --check-formatted

# Update dependencies
mix deps.get
mix deps.compile
```

**Error**: Ash Framework errors
```bash
# Common Ash issues:
# 1. Resource not in domain registry
# 2. Missing `require` statements
# 3. Invalid action definitions

# Check the specific error message and refer to:
# https://ash-hq.org/docs/guides/ash/latest/tutorials/get-started
```

### Dependencies Issues

**Error**: Dependency conflicts or missing
```bash
# Clean deps and reinstall
rm -rf _build deps
mix deps.get
mix deps.compile
```

**Error**: Asset compilation fails
```bash
# Check Node.js and npm are installed (for assets)
cd assets
npm install
cd ..

# Or skip assets and just run backend
mix phx.server --no-assets
```

## Performance Issues

### Slow Application Response

**Issues**: Dashboard takes long to load
```bash
# Check if database needs reset
just db-status

# Clear ETS cache
# Restart application - cache will rebuild
```

**Issues**: Price updates slow or failing
```bash
# Check Yahoo Finance connectivity
curl "https://query1.finance.yahoo.com/v8/finance/chart/AAPL"

# Clear price cache
# Restart server - cache will rebuild
```

### Memory Issues

**Issues**: High memory usage
```bash
# Check Observer
# In IEx: :observer.start()

# Or restart application
pkill -f "phx.server"
just server
```

## macOS-Specific Issues

### Apple Silicon (M1/M2) Issues

**Error**: Dependency compilation fails
```bash
# Some dependencies need x86_64 mode
arch -x86_64 brew install elixir
arch -x86_64 mix deps.get
```

**Error**: SQLite issues on Apple Silicon
```bash
# Reinstall SQLite
brew reinstall sqlite3

# If still issues, try native compilation
mix deps.compile --force
```

### File Permissions

**Error**: Permission denied errors
```bash
# Fix permissions on project directory
chmod -R 755 .
chmod -R 644 *.md *.ex *.exs

# Fix data directory permissions
mkdir -p data
chmod 755 data
```

## Getting More Help

### Debug Information to Collect

When asking for help, provide:

```bash
# System information
elixir --version
just --version
mix --version

# Project status
just db-status
just check

# Error logs
# Copy the full error message and stack trace
```

### Where to Get Help

1. **GitHub Issues**: [ashfolio/issues](https://github.com/mdstaff/ashfolio/issues)
2. **GitHub Discussions**: For questions and help
3. **Documentation**: Check other docs in this directory
4. **Elixir Community**: [Elixir Forum](https://elixirforum.com/)
5. **Phoenix Community**: [Phoenix Documentation](https://hexdocs.pm/phoenix/)

### Creating a Good Issue Report

Include:
- **Operating System**: macOS version, chip type (Intel/Apple Silicon)
- **Versions**: Elixir, Erlang, Phoenix versions
- **Steps to Reproduce**: Exact commands that cause the issue
- **Error Messages**: Complete error output with stack traces
- **Expected vs Actual**: What you expected vs what happened

---

**Still having issues?** Don't hesitate to [open an issue](https://github.com/mdstaff/ashfolio/issues/new) with the debug information above!