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

#### Advanced Analytics

- Enhanced Expense Analytics: Year-over-year comparisons with interactive charts
- Advanced Filtering: Category, amount range, and merchant search capabilities
- Custom Date Ranges: Flexible date pickers with filtered expense previews
- Spending Trends: Monthly analysis with 3/6-month trend indicators
- Interactive Visualizations: Contex-powered SVG charts with graceful fallbacks
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

Current Version: v0.4.3 (In Development)
Previous Release: v0.3.4

### Currently Available (v0.1.0 - v0.4.3 Features)

- Investment Portfolio Tracking: Account and transaction management
- Net Worth Calculation: Cross-account financial position analysis with manual snapshots
- Cash Account Management: Checking, savings, money market, and CD accounts
- Expense Tracking: Comprehensive expense analytics with interactive dashboard widgets
- Enhanced Analytics: Year-over-year comparisons, advanced filtering, custom date ranges
- Spending Trends: Monthly spending analysis with trend indicators and visual charts
- Transaction Categories: Transaction organization and categorization
- Real-time Calculations: Portfolio value and performance analytics
- Interactive Visualizations: Contex-powered SVG charts for expenses and net worth
- Price Integration: Yahoo Finance API with caching
- Responsive Interface: Multi-device support with mobile-optimized charts
- Reliable: Robust error handling with graceful fallbacks

### New in v0.4.x Development

- v0.4.1: Emergency Fund Calculator with expense-based targets
- v0.4.2: Retirement Planning with 25x rule and 4% safe withdrawal calculations
- v0.4.3: Portfolio Forecasting with scenario planning (5%/7%/10% growth rates)
- v0.4.3: Financial Independence timeline calculations with multi-scenario analysis
- v0.4.3: Custom scenario planning for specialized financial modeling

### Coming Soon

v0.4.3 Remaining (Current Sprint):

- Stage 4: Contribution Impact Analysis - Analyze portfolio growth with different contribution levels
- Stage 5: UI Integration - LiveView components with interactive Contex charts

v0.4.4: Advanced Portfolio Analytics

- Time-Weighted Return (TWR) calculations
- Money-Weighted Return (MWR) with IRR methodology
- Rolling returns analysis and volatility metrics

v0.4.5: Benchmark System

- S&P 500 and market index comparisons
- Performance tracking against benchmarks
- Asset allocation analysis

v0.5.0: Full Integration & AER Standardization

- Dashboard widget integration for all v0.4.x features
- Standardized Annual Equivalent Rate (AER) methodology
- Data import/export functionality

### Development Roadmap

- v0.4.3: Forecasting Engine (In Progress - Stage 3/5 Complete)
- v0.4.4: Advanced Analytics (Next Sprint)
- v0.4.5: Benchmark System
- v0.5.0: Integration & Import/Export
- v0.6.0: Performance Optimization
- v0.7.0: Feature Completeness

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
