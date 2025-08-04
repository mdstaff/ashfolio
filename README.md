# Ashfolio

A simplified Phase 1 portfolio management application built with Phoenix LiveView and the Ash Framework. This is a single-user local application designed for personal portfolio tracking with manual price updates.

## Current Status (Phase 7: Portfolio Dashboard - 69% Complete)

**✅ What's Working Now:**

- **Complete Data Model**: All core Ash resources (User, Account, Symbol, Transaction) are implemented with validations and relationships.
- **Database Management**: SQLite database with migrations, performance indexes, and comprehensive seeding.
- **Market Data**: Yahoo Finance integration for price fetching, with a GenServer-based `PriceManager` for coordination and ETS caching.
- **Portfolio Calculation Engine**: A dual-calculator architecture (`Calculator` and `HoldingsCalculator`) provides a rich set of functions for portfolio analysis, including FIFO cost basis and P&L.
- **LiveView Dashboard**: A functional and responsive portfolio dashboard that displays real-time data, including portfolio value, returns, and a sortable holdings table.
- **Robust Testing**: **100% passing test suite** (192/192 tests) with optimized configuration and `just` command runner for easy execution.

**🔄 Next Steps:**

- Manual price refresh functionality from the UI.
- Account and transaction management interfaces.
- Basic charting and visualizations.

## Quick Start

### Prerequisites

- Elixir 1.14+ and Erlang/OTP 25+
- macOS (optimized for Apple Silicon)
- `just` command runner (`brew install just`)

### Installation

1.  **Install Elixir** (if not already installed):

    ```bash
    brew install elixir
    ```

2.  **Setup and start the project**:

    ```bash
    # The `just dev` command will install dependencies, set up the database, and start the server.
    just dev
    ```

3.  **Access the application**:
    - Open [`http://localhost:4000`](http://localhost:4000) in your browser.
    - The database comes pre-seeded with sample data.

## Tech Stack

- **Backend**: Elixir, Phoenix 1.7+, Ash Framework 3.0+
- **Database**: SQLite with `ecto_sqlite3` and `ash_sqlite`
- **Frontend**: Phoenix LiveView
- **Caching**: In-memory caching with ETS
- **HTTP Client**: `HTTPoison` for external API communication
- **Testing**: ExUnit, Mox, and Meck for comprehensive testing
- **Code Quality**: Credo for static analysis
- **Task Runner**: `just` for streamlined development commands

## Architecture

The application follows a standard Phoenix architecture, with the addition of the Ash Framework for the business logic layer.

- **`lib/ashfolio`**: Contains the core business logic, including Ash resources, portfolio calculators, and market data services.
- **`lib/ashfolio_web`**: Contains the Phoenix web interface, including LiveView components, routing, and templates.
- **`data/`**: The SQLite database file is stored here.
- **`.kiro/`**: Contains project specifications, design documents, and steering instructions for AI-driven development.

The system is designed to be modular and extensible, with a clear separation of concerns between the data, logic, and presentation layers.

## Development

### Running Tests

**Current Status: ✅ All 192 tests passing (optimized configuration)**

```bash
# Run all tests using the just command runner
just test

# Run tests with seeding tests included (slower)
just test --include seeding

# Other test commands
just test-file <path>      # Run specific test file
just test-coverage         # Run with coverage report
just test-watch           # Run in watch mode
```

### Development Commands

The project uses `just` to simplify common development tasks.

```bash
just              # Show all available commands
just dev          # Setup and start server
just test         # Run the full test suite
just test-file <path>  # Run a specific test file
just test-coverage     # Run tests with a coverage report
just reset        # Reset the database with fresh sample data
just console      # Start an interactive Elixir console
```
