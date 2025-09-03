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

- Investment Portfolios: Stock, ETF, bond, and crypto position management with FIFO cost basis
- Cash Management: Checking, savings, money market, and CD account tracking
- Net Worth Analytics: Cross-account financial position analysis with trending
- Expense Tracking: Monthly spending analysis with interactive charts and advanced filtering
- Retirement Planning: 401k, IRA projections with industry-standard calculations
- Goal Tracking: Progress monitoring for emergency funds and financial independence
- Performance Analytics: Time-weighted returns, rolling performance, and benchmarking
- Real-time Pricing: Automatic price updates from Yahoo Finance
- Interactive Visualizations: Professional SVG charts with responsive design

### Setup

- Single command setup: `just dev`
- Local database with sample data
- No external dependencies or signups required

---

## Project Status

Current Version: v0.5.0-dev (In Development)

### Currently Available

#### Core Financial Management

- Investment Portfolio Tracking with FIFO cost basis calculations
- Net Worth Calculation with cross-account analysis and manual snapshots
- Cash Account Management for checking, savings, money market, and CD accounts
- Comprehensive Expense Tracking with interactive dashboard widgets
- Transaction Categories and organization
- Real-time Portfolio Calculations and performance analytics

#### Financial Planning

- Financial Goals with emergency fund calculator
- Retirement Planning using industry-standard 25x rule and 4% safe withdrawal rates
- Portfolio Forecasting with scenario planning (pessimistic/realistic/optimistic)
- Financial Independence timeline calculations
- Contribution Analysis and impact modeling

#### Advanced Analytics

- Time-Weighted Return (TWR) and Money-Weighted Return (MWR) calculations
- Rolling Returns and performance pattern analysis
- Interactive Visualizations powered by Contex SVG charts
- Enhanced Analytics Dashboard with year-over-year comparisons
- Professional financial notation and formatting
- Performance caching for complex calculations

### Coming Soon (v0.5.0)

- AER Standardization: Consistent Annual Equivalent Rate across all calculators
- Enhanced Benchmark System: S&P 500 and market index comparisons
- Asset Allocation Analysis: Portfolio composition and rebalancing tools
- Advanced Import/Export: Comprehensive data portability

### Development Roadmap

- ✅ v0.3.x & v0.4.x: Complete
- 🚧 v0.5.0: AER Standardization & Integration (In Development)
- 📋 v0.6.0: Performance Optimization & Scale
- 📋 v0.7.0: Tax Planning & Advanced Features
- 📋 v1.0.0: Production Release

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
