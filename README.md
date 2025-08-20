# Ashfolio

Personal financial management application for investment and cash account tracking.

Ashfolio manages financial data locally on your computer. Track investments, cash accounts, and net worth without cloud dependencies or data sharing.

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Quick Start

### Prerequisites

- Elixir 1.14+ and Erlang/OTP 25+
- macOS (optimized for Apple Silicon)
- `just` command runner (`brew install just`)

### Installation & Run

1.  Clone the repository:
    ```bash
    git clone https://github.com/mdstaff/ashfolio.git
    cd ashfolio
    ```
2.  Setup and start the project:
    ```bash
    just dev
    ```
3.  Access the application:
    - Open [`http://localhost:4000`](http://localhost:4000)
    - The database includes sample data for exploration

---

## Features

### Privacy

- Local-only data: Financial information stays on your computer
- No cloud dependencies: Works offline except for price updates
- Open source: Transparent data handling

### Financial Management

#### Wealth Tracking

- Investment Portfolios: Stock, ETF, bond, and crypto position management
- Cash Management: Checking, savings, and money market account tracking
- Asset Portfolio: Real estate, vehicles, and other assets
- Net Worth Analytics: Financial position with trending and analysis

#### Planning & Analysis

- Expense Tracking: Monthly spending analysis and budget management
- Retirement Planning: 401k, IRA, and retirement goal projections
- Dividend Income: Forward-looking dividend projections
- Tax Planning: Capital gains optimization strategies

#### Analytics

- FIFO Cost Basis: Profit/loss calculations using industry standards
- Real-time Pricing: Price updates from Yahoo Finance
- Responsive Design: Works on desktop, tablet, and mobile
- Goal Tracking: Progress monitoring for financial goals

### Setup

- Single command setup: `just dev`
- Local database with sample data
- No external dependencies or signups required

---

## Project Status

Current Version: v0.2.2-dev
Next Release: v0.3.0 (TBD)

### Currently Available (v0.1.0 + v0.2.0 Features)

- Investment Portfolio Tracking: Account and transaction management
- Net Worth Calculation: Cross-account financial position analysis
- Cash Account Management: Checking, savings, money market, and CD accounts
- Transaction Categories: Transaction organization and categorization
- Real-time Calculations: Portfolio value and performance analytics
- Price Integration: Yahoo Finance API with caching
- Responsive Interface: Multi-device support
- Reliable: Robust error handling

### Coming Soon

v0.2.0 (Q3 2025) - Remaining Features:

- Symbol Autocomplete: Symbol search in transaction forms (In Progress)
- Enhanced Dashboard: Net worth integration and cash account displays
- Balance Management UI: Cash balance update interfaces
- Category Management: UI for creating and managing transaction categories

Future Releases:

- Expense Tracking & Asset Management: Monthly spending analysis and real estate/vehicle tracking (v0.3.0)
- Retirement Planning & Advanced Analytics: 25x rule calculations and portfolio analysis (v0.4.0)
- Tax Planning & Feature Completeness: Tax optimization and reporting (v0.5.0)

### Development Roadmap

v0.2.0 (Q3 2025): Cash Management & Enhanced UX  
v0.3.0 (Q4 2025): Asset Tracking & Real-Time Features  
v0.4.0 (Q1 2026): Financial Planning & Advanced Analytics  
v0.5.0 (Q2 2026): Tax Planning & Feature Completeness

See [roadmap](docs/roadmap/v0.2-v0.5-roadmap.md) for detailed feature timelines.

---

## Architecture

Phoenix LiveView application with Ash Framework for business logic and SQLite for local data storage.

See [Architecture Overview](docs/development/architecture.md) for detailed information.

---

## Development

### Tech Stack

- Backend: Elixir, Phoenix 1.7+, Ash Framework 3.0+
- Database: SQLite with `ecto_sqlite3` and `ash_sqlite`
- Frontend: Phoenix LiveView
- Caching: In-memory caching with ETS
- HTTP Client: `HTTPoison` for external API communication
- Testing: ExUnit, Mox, and Meck
- Code Quality: Credo for static analysis
- Task Runner: `just` command runner

### Development Workflow

Ashfolio uses the `just` command runner for development tasks.

#### Essential Development Commands

- `just dev`: Sets up environment and starts the server
- `just test`: Runs the test suite
- `just test-file <path>`: Runs tests for a specific file
- `just reset`: Resets the database with sample data
- `just`: Lists all available commands

For complete development setup and testing details, see [Getting Started Guide](docs/getting-started/) and [Testing Strategy](docs/TESTING_STRATEGY.md).

### Contributing

See [Contributing Guide](CONTRIBUTING.md) and [First Contribution Guide](docs/getting-started/first-contribution.md).

---

## Documentation

### Getting Started

- [Installation Guide](docs/getting-started/installation.md)
- [Quick Start](docs/getting-started/quick-start.md)
- [First Contribution](docs/getting-started/first-contribution.md)
- [Troubleshooting](docs/getting-started/troubleshooting.md)

### Development

- [Architecture Overview](docs/development/architecture.md)
- [Database Management](docs/development/database-management.md)
- [AI Agent Guide](docs/development/ai-agent-guide.md)

### Testing

- [Testing Strategy](docs/TESTING_STRATEGY.md)
- [Troubleshooting Guide](docs/development/test-failure-troubleshooting-guide.md)
- [Framework Guide](docs/testing/framework.md)
- [SQLite Patterns](docs/testing/patterns.md)

### API Reference

- [REST API](docs/api/rest-api.md)
- [Endpoints](docs/api/endpoints.md)

---

## Support

- [Troubleshooting Guide](docs/getting-started/troubleshooting.md)
- [GitHub Issues](https://github.com/mdstaff/ashfolio/issues)
- [GitHub Discussions](https://github.com/mdstaff/ashfolio/discussions)

### Contributing

- Star this repository
- Report issues
- Suggest features
- Contribute code

---

License: MIT  
Privacy: Financial data stays on your computer.
