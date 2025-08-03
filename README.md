# Ashfolio

A simplified Phase 1 portfolio management application built with Phoenix LiveView and the Ash Framework. This is a single-user local application designed for personal portfolio tracking with manual price updates.

## Current Status (Phase 7: Portfolio Dashboard - 62% Complete)

**✅ What's Working Now:**

- Complete data model foundation (User, Account, Symbol, Transaction resources)
- Database migrations with performance indexes
- Enhanced database seeding with comprehensive sample data
- Database management utilities for development workflows
- SQLite database with sample data pre-loaded
- ETS price caching system
- Yahoo Finance API integration with error handling
- Complete portfolio calculation engine with financial precision
- Responsive LiveView layout with navigation
- Functional portfolio dashboard displaying real portfolio data
- Comprehensive error handling
- **100% passing test suite** (169/169 tests) with enhanced test commands

**🔄 Next Steps:**

- Holdings table with sorting and color coding
- Manual price refresh functionality
- Account and transaction management interfaces

## Quick Start

### Prerequisites

- Elixir 1.14+ and Erlang/OTP 25+
- macOS (optimized for Apple Silicon)

### Installation

1. **Install Elixir** (if not already installed):

   ```bash
   brew install elixir
   ```

2. **Setup and start the project**:

   ```bash
   # Using Just (recommended - install with: brew install just)
   just dev

   # Or traditional Mix commands
   mix setup && mix phx.server
   ```

3. **Access the application**:
   - Open [`http://localhost:4000`](http://localhost:4000) in your browser
   - The database comes pre-seeded with sample data

### What You Can Do Right Now

The application currently has a working foundation with sample data:

**Sample Data Included:**

- Default user (Local User)
- 3 sample accounts (Schwab Brokerage, Fidelity 401k, Crypto Wallet)
- 6 sample symbols (AAPL, MSFT, GOOGL, SPY, VTI, BTC-USD)

**Available via Elixir Console:**

```bash
# Start interactive console
iex -S mix

# Query sample data
iex> alias Ashfolio.Portfolio.{User, Account, Symbol}
iex> {:ok, user} = User.get_default_user()
iex> {:ok, accounts} = Account.accounts_for_user(user.id)
iex> {:ok, symbols} = Symbol.list()
```

## Technology Stack

- **Backend**: Phoenix 1.7+ with Ash Framework 3.0+
- **Database**: SQLite with AshSqlite adapter (files stored in `data/`)
- **Frontend**: Phoenix LiveView (UI coming in next phase)
- **Cache**: ETS for price data caching
- **Financial Data**: Decimal types for precise calculations, USD-only
- **APIs**: Yahoo Finance & CoinGecko (integration planned)

## Project Architecture

### Core Resources (Completed)

- **User**: Single default user for local application
- **Account**: Investment accounts (Schwab, Fidelity, etc.)
- **Symbol**: Financial instruments (stocks, ETFs, crypto)
- **Transaction**: Buy/sell/dividend records (next milestone)

### Key Features

- **Single-user local app** - No authentication required
- **Manual price updates** - User-initiated, no background jobs
- **USD-only calculations** - Simplified Phase 1 scope
- **SQLite storage** - Local file-based database
- **Comprehensive error handling** - User-friendly error messages
- **ETS caching** - Optimized for Apple Silicon performance

## Development

### Project Structure

```
ashfolio/
├── lib/ashfolio/           # Ash resources and business logic
├── lib/ashfolio_web/       # Phoenix web layer (LiveView)
├── config/                 # Application configuration
├── data/                   # SQLite database files
├── priv/repo/             # Migrations and seeds
├── test/                  # Comprehensive test suite
└── .kiro/specs/           # Project specifications
```

### Running Tests

**Current Status: ✅ All 169 tests passing**

```bash
# Run all tests
mix test

# Run specific test files
mix test test/ashfolio/portfolio/user_test.exs
mix test test/ashfolio/portfolio/account_test.exs
mix test test/ashfolio/portfolio/symbol_test.exs
mix test test/ashfolio/portfolio/transaction_test.exs
mix test test/ashfolio/seeding_test.exs
```

### Development Commands

**Using Just (recommended):**

```bash
just              # Show all available commands
just dev          # Setup and start server (like npm start)
just test         # Run test suite
just test-file <path>  # Run specific test file
just test-coverage     # Run tests with coverage report
just test-watch       # Run tests in watch mode
just test-failed      # Run only failed tests
just test-verbose     # Run tests with detailed output
just reset        # Reset database with fresh sample data
just console      # Interactive Elixir console
just format       # Format code
just check        # Format + test
```

**Using Mix directly:**

```bash
# Reset database with fresh sample data
mix ecto.reset

# Run migrations only
mix ecto.migrate

# Seed sample data
mix run priv/repo/seeds.exs

# Database management utilities
iex -S mix
iex> Ashfolio.DatabaseManager.reset_database()      # Reset with confirmation
iex> Ashfolio.DatabaseManager.truncate_all_tables() # Clear all data
iex> Ashfolio.DatabaseManager.database_stats()      # Show table statistics
```

## Phase 1 Scope

**✅ Completed (18/29 tasks):**

- Development environment setup
- Phoenix project with Ash Framework
- SQLite database configuration with migrations
- Database management utilities and documentation
- ETS price caching system
- Error handling framework
- User, Account, Symbol, and Transaction resources
- Yahoo Finance API integration
- Portfolio calculation engine (dual calculator architecture)
- Responsive LiveView layout with navigation
- Functional portfolio dashboard with real-time data

**🔄 Next Priority:**

- Holdings table implementation
- Manual price refresh functionality
- Account and transaction management interfaces

**Phase 1 Goals:**

- Manual portfolio entry and tracking
- Basic gain/loss calculations
- Simple account management
- Manual price refresh functionality

## Contributing

This is a personal portfolio management tool built incrementally. Each task is designed for 80-90% success rate with comprehensive testing and documentation.

For detailed project specifications, see:

- `.kiro/specs/requirements.md` - Complete feature requirements
- `.kiro/specs/design.md` - Technical architecture
- `.kiro/specs/tasks.md` - Implementation roadmap
- `CHANGELOG.md` - Detailed progress history
