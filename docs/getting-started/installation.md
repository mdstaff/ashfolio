# Ashfolio Development Environment Setup

Development environment setup for Ashfolio on macOS.

## Prerequisites

- macOS 12.0 (Monterey) or later
- Apple Silicon (M1/M2) or Intel Mac
- 16GB+ RAM recommended
- 10GB+ free disk space

## Quick Setup (Recommended)

Quick setup:

```bash
# Clone the repository (if not already done)
git clone <repository-url>
cd ashfolio

# Run the setup script
./scripts/setup-dev-env.sh
```

Installs dependencies and verifies installation.

## Manual Setup

Manual installation:

### 1. Install Homebrew

If you don't have Homebrew installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

For Apple Silicon Macs, add Homebrew to your PATH:

```zsh
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

### 2. Install Erlang and Elixir

```bash
# Update Homebrew
brew update

# Install Erlang and Elixir
brew install erlang elixir
```

Recommended Versions:

- Erlang/OTP: 26.0+
- Elixir: 1.15.0+

### 3. Install Hex Package Manager

```bash
mix local.hex --force
```

### 4. Install Phoenix Framework

```bash
mix archive.install hex phx_new --force
```

### 5. Install Additional Tools

```bash
# Node.js for asset compilation
brew install node

# SQLite for database
brew install sqlite

# Git (if not already installed)
brew install git
```

## Verification

After installation, verify all tools are working correctly:

```bash
# Check Erlang
erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell

# Check Elixir
elixir --version

# Check Hex
mix hex.info

# Check Phoenix
mix phx.new --version

# Check Node.js
node --version

# Check SQLite
sqlite3 --version
```

Expected output should show version numbers for all tools.

## Project Setup

Once the development environment is ready:

### 1. Install Project Dependencies

```bash
# Install Elixir dependencies
mix deps.get

# Install Node.js dependencies for assets
cd assets && npm install && cd ..
```

### 3. Set up Database

```bash
# Create and migrate database
mix ecto.setup
```

### 4. Start Development Server

```bash
# Start Phoenix server
mix phx.server
```

The application will be available at `http://localhost:4000`.

## Apple Silicon Optimizations

### BEAM VM Configuration

For optimal performance on Apple Silicon, add these environment variables to your shell profile (`~/.zshrc`):

```zsh
# Optimize for Apple Silicon (8 performance cores on M1 Pro)
export ERL_FLAGS="+S 8:8 +A 64"

# Memory optimization for 16GB systems
export ERL_MAX_PORTS=65536
export ERL_MAX_ETS_TABLES=32768
```

### SQLite Configuration

For better SQLite performance on Apple Silicon:

```zsh
# Add to your shell profile (~/.zshrc)
export SQLITE_TMPDIR=/tmp
export SQLITE_ENABLE_FTS5=1
```

## Development Tools (Optional)

### Recommended VS Code Extensions

If using Visual Studio Code:

- ElixirLS (Elixir language server)
- Phoenix Framework
- SQLite Viewer
- Tailwind CSS IntelliSense

### Recommended Terminal Setup

For better development experience:

```zsh
# Install Oh My Zsh (optional)
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install useful aliases
echo 'alias mps="mix phx.server"' >> ~/.zshrc
echo 'alias mdr="mix deps.get && mix ecto.reset"' >> ~/.zshrc
echo 'alias mt="mix test"' >> ~/.zshrc
```

## Troubleshooting

### Common Issues

#### 1. Homebrew Installation Issues

If Homebrew installation fails:

```bash
# Check if Xcode Command Line Tools are installed
xcode-select --install

# Retry Homebrew installation
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Erlang/Elixir Version Conflicts

If you have multiple versions installed:

```zsh
# Uninstall all versions
brew uninstall --ignore-dependencies erlang elixir

# Clean up
brew cleanup

# Reinstall
brew install erlang elixir
```

#### 3. Phoenix Installation Issues

If Phoenix installation fails:

```zsh
# Clear hex cache
mix local.hex --force

# Reinstall Phoenix
mix archive.install hex phx_new --force
```

#### 4. Node.js Issues

If Node.js installation or asset compilation fails:

```zsh
# Use Node Version Manager for better version control
brew install nvm

# Install latest LTS Node.js
nvm install --lts
nvm use --lts
```

#### 5. SQLite Issues

If SQLite database issues occur:

```zsh
# Ensure SQLite is properly installed
brew reinstall sqlite

# Check SQLite version (should be 3.36+)
sqlite3 --version
```

#### 6. Test Failures with SQLite Concurrency

If tests fail with database sandbox errors:

Symptoms:

- Tests fail with `{:badmatch, :already_shared}` errors
- Multiple tests failing with sandbox-related messages
- Intermittent test failures in CI/CD

Cause: SQLite has limited concurrent access compared to PostgreSQL

Resolution:

- The test infrastructure automatically handles these conflicts
- Tests should pass on retry
- For persistent issues, run individual test files: `just test-file path/to/test.exs`

```bash
# If encountering persistent sandbox issues
just test-file test/ashfolio_web/live/dashboard_pubsub_test.exs

# Reset test database if needed
MIX_ENV=test just reset
```

### Memory Issues on 16GB Systems

If you encounter memory issues during development:

```zsh
# Reduce BEAM VM memory usage
export ERL_FLAGS="+MBas aobf +MHas aobf +MBlmbcs 512 +MHlmbcs 512"

# Monitor memory usage
mix profile.memory
```

### Performance Monitoring

To monitor application performance during development:

```zsh
# Install system monitoring tools
brew install htop
brew install btop  # Modern alternative to htop

# Monitor Elixir processes
:observer.start()  # Run in IEx session
```

## Environment Variables

Create a `.env` file in the project root for local configuration:

```bash
# Database
DATABASE_PATH=./data/ashfolio_dev.db

# Market Data APIs
YAHOO_FINANCE_ENABLED=true
COINGECKO_ENABLED=true
COINGECKO_API_KEY=  # Optional - leave empty for free tier

# Application Settings
DEFAULT_CURRENCY=USD
DEFAULT_LOCALE=en-US
PORT=4000

# Development Settings
PHX_SERVER=true
MIX_ENV=dev
```

## Next Steps

After completing the setup:

1.  Review `docs/ARCHITECTURE.md` to understand the system design
2.  Start with `lib/ashfolio.ex` and `lib/ashfolio_web.ex`
3.  Execute `mix test` to ensure everything is working
4.  Begin with the first implementation task in the project plan

## Getting Help

If you encounter issues not covered in this guide:

1. Check the [Elixir Installation Guide](https://elixir-lang.org/install.html)
2. Review [Phoenix Installation Guide](https://hexdocs.pm/phoenix/installation.html)
3. Consult [Homebrew Documentation](https://docs.brew.sh/)
4. Check project issues and discussions

## Performance Benchmarks

Expected performance on Apple Silicon (M1 Pro, 16GB RAM):

- < 3 seconds
- < 10 seconds
- < 5 seconds
- < 2 seconds
- < 2 seconds

If your setup doesn't meet these benchmarks, review the optimization sections above.
