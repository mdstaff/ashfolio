# Ashfolio

Personal financial management application for investment and cash account tracking.

Ashfolio manages financial data locally on your computer. Track investments, cash accounts, and net worth without cloud dependencies or data sharing.

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Why Ashfolio?

**Privacy-First Financial Management** with professional-grade analytics and AI enhancements:

- **100% Local Data**: Your financial information never leaves your computer
- **AI-Enhanced Entry**: Parse transactions naturally while maintaining privacy
- **Professional Analytics**: Markowitz optimization, tax planning, risk metrics
- **Production Ready**: 2,200+ tests ensuring financial accuracy
- **Open Source**: Transparent calculations you can verify and customize

Built with Elixir/Phoenix for reliability and performance.

---

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
- AI-Powered Entry: Natural language transaction parsing with privacy-first local AI
- MCP Integration: AI assistant portfolio access with granular consent controls
- Privacy Management: Four privacy modes with GDPR-compliant consent infrastructure

### Setup

- Single command setup: `just dev`
- Local database with sample data
- No external dependencies or signups required

---

## Project Status

Current Version: v0.10.0 (Released November 30, 2025)

### Latest Features

#### v0.10.0 - MCP Phase 2 (November 2025)
- AI Settings page with privacy controls and consent management
- GDPR-compliant consent infrastructure with audit trails
- Natural language parsing for amounts and dates
- Tool discovery optimization (~85% token reduction)

#### v0.9.0 - MCP Integration (November 2025)
- Model Context Protocol server for AI assistants
- Privacy filtering system with four modes (strict/anonymized/standard/full)
- Secure portfolio data access for AI tools

#### v0.8.0 - AI Natural Language Entry (November 2025)
- Parse conversational transactions: "Bought 10 AAPL at $150 yesterday"
- Local AI with Ollama or cloud with OpenAI
- Human-in-the-loop validation before saving

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

### Completed in v0.7.0 ✅

- **Advanced Portfolio Analytics**: Complete Markowitz portfolio optimization
  - Efficient Frontier Visualization with minimum variance, tangency, and maximum return portfolios
  - N-asset portfolio optimization with approximation algorithms (99% accuracy)
  - Risk Metrics Suite: Sharpe, Sortino, Drawdown, VaR, Beta analysis
  - Correlation & Covariance Analysis with interactive matrices
  - Real-time TWR/MWR calculations with performance caching

- **Corporate Actions Engine**: Comprehensive investment event management
  - Stock splits, dividends, mergers, spinoffs with automatic FIFO cost basis adjustments
  - Transaction adjustment system with complete audit trail
  - Professional LiveView interface with conditional form fields

- **Previous Foundations**: Money Ratios Assessment, Tax Planning & Optimization, Enhanced Financial Infrastructure

#### AI-Enhanced Features

- Natural Language Transaction Entry with conversational parsing
- Multi-Provider AI Support (Ollama local-first, OpenAI cloud option)
- Model Context Protocol Server for AI assistant integration
- Privacy-Aware Data Filtering with four configurable modes
- GDPR-Compliant Consent Management with audit trails
- AI Settings Interface for granular privacy control

### Development Roadmap

- ✅ v0.1.0 - v0.10.0: Complete (AI integration, MCP, consent management)
- 🚧 v0.11.0: Additional AI enhancements and analytics
- 📋 v1.0.0: Production hardening and performance optimization

See [ROADMAP.md](ROADMAP.md) and [CHANGELOG.md](CHANGELOG.md) for complete version history.

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
- AI Integration: Multi-provider support (Ollama for local, OpenAI for cloud)
- MCP Server: Model Context Protocol for AI assistant integration
- Privacy & Consent: GDPR-compliant consent management infrastructure
- Testing: ExUnit, Mox, and Meck
- Code Quality: Credo for static analysis
- Task Runner: `just` command runner

### Development Workflow

Ashfolio uses the `just` command runner for development tasks.

#### Essential Development Commands

- `just dev`: Sets up environment and starts the server
- `just test`: Runs the test suite (2,200+ tests, 95%+ financial calculation coverage)
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

### AI Features

- [AI Natural Language Entry](docs/features/implemented/ai-natural-language-entry.md)
- [MCP Integration](docs/features/implemented/mcp-integration.md)
- [AI Agent Development Guide](docs/development/ai-agent-guide.md)

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
