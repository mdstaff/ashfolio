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

Current Version: v0.4.5+ (Complete)
Previous Release: v0.3.4

### Currently Available (v0.1.0 - v0.4.5 Features)

#### Core Financial Management
- Investment Portfolio Tracking: Account and transaction management with FIFO cost basis
- Net Worth Calculation: Cross-account financial position analysis with manual snapshots
- Cash Account Management: Checking, savings, money market, and CD accounts
- Expense Tracking: Comprehensive expense analytics with interactive dashboard widgets
- Transaction Categories: Organization and categorization for all transactions
- Real-time Calculations: Portfolio value and performance analytics

#### Financial Planning (v0.4.x Complete)
- Financial Goals: Complete CRUD operations with emergency fund calculator
- Emergency Fund Calculator: Automatic expense aggregation with 3-12 month recommendations
- Retirement Planning: Industry-standard 25x rule and 4% safe withdrawal calculations
- Portfolio Forecasting: Scenario planning with pessimistic/realistic/optimistic projections
- Financial Independence: Timeline calculations with multi-scenario analysis
- Contribution Analysis: Impact modeling for different savings rates

#### Advanced Analytics (v0.4.4+ Complete)
- Time-Weighted Return (TWR): Industry-standard portfolio performance calculations
- Money-Weighted Return (MWR): IRR-based personal return analysis
- Rolling Returns: Performance pattern analysis over time
- Professional Formatting: Currency notation ($1M, $500K) and percentage display
- Performance Caching: ETS-based optimization for complex calculations

#### Visualization & UX
- Interactive Visualizations: Contex-powered SVG charts for all analytics
- Enhanced Analytics Dashboard: Year-over-year comparisons with advanced filtering
- Responsive Interface: Multi-device support with mobile-optimized charts
- Professional Chart Formatting: Proper financial notation throughout

### Coming Soon (v0.5.0+)

#### v0.5.0: Platform Integration & Standardization
- AER Standardization: Consistent Annual Equivalent Rate across all calculators
- Enhanced Benchmark System: S&P 500 and market index comparisons
- Asset Allocation Analysis: Portfolio composition and rebalancing tools
- Advanced Import/Export: Comprehensive data portability

#### Future Enhancements
- Monte Carlo Simulations: Advanced probability modeling
- Tax Planning Tools: Capital gains optimization
- Multi-currency Support: International portfolio management
- Enhanced Mobile Experience: Native mobile optimizations

### Development Roadmap

✅ v0.4.1-v0.4.5: Complete Financial Planning Platform (COMPLETE)
- v0.5.0: AER Standardization & Integration (Next)
- v0.6.0: Performance Optimization & Scale
- v0.7.0: Tax Planning & Advanced Features
- v1.0.0: Production Release

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
