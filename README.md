# Ashfolio 📊

**A comprehensive, local-first personal financial management application for complete wealth tracking and planning.**

Built with Phoenix LiveView and the Ash Framework, Ashfolio provides a secure, privacy-focused solution for managing your complete financial picture on your own computer. Track investments, cash accounts, net worth, expenses, and plan for the future—all with no cloud dependencies and complete data ownership.

[![Production Ready](https://img.shields.io/badge/Status-Production%20Ready-green)](https://github.com/mdstaff/ashfolio)
[![Test Coverage](https://img.shields.io/badge/Tests-383%20passing-brightgreen)](https://github.com/mdstaff/ashfolio)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 🚀 Quick Start

Get Ashfolio up and running in minut`es!

### Prerequisites

- Elixir 1.14+ and Erlang/OTP 25+
- macOS (optimized for Apple Silicon)
- `just` command runner (`brew install just`)

### Installation & Run

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/mdstaff/ashfolio.git
    cd ashfolio
    ```
2.  **Setup and start the project**:
    ```bash
    # This command will install dependencies, set up the database, and start the Phoenix server.
    just dev
    ```
3.  **Access the application**:
    - Open [`http://localhost:4000`](http://localhost:4000) in your browser.
    - The database comes pre-seeded with sample data, so you'll see a populated portfolio immediately!

---

## ✨ Why Ashfolio?

### 🔒 Privacy First

- **Local-only data**: Your financial information never leaves your computer
- **No cloud dependencies**: Works entirely offline except for price updates
- **Open source**: Full transparency in how your data is handled

### 💡 Comprehensive Financial Features

#### 💰 Complete Wealth Tracking

- **Investment Portfolios**: Stock, ETF, bond, and crypto position management across brokerages
- **Cash Management**: Checking, savings, and money market account tracking
- **Asset Portfolio**: Real estate, vehicles, and other valuable assets
- **Net Worth Analytics**: Complete financial position with trending and year-over-year analysis

#### 📊 Financial Planning & Analysis

- **Expense Tracking**: Monthly spending analysis and budget management
- **Retirement Planning**: 401k, IRA, and retirement goal projections using 25x rule
- **Dividend Income**: Forward-looking dividend projections for early retirement planning
- **Tax Planning**: Capital gains optimization and tax-aware strategies

#### 🔧 Advanced Analytics

- **📈 FIFO Cost Basis**: Accurate profit/loss calculations using industry standards
- **💱 Real-time Pricing**: Automatic price updates from Yahoo Finance
- **📱 Responsive Design**: Works beautifully on desktop, tablet, and mobile
- **🎯 Goal Tracking**: Progress monitoring for financial independence and custom goals

### 🛠️ Developer Friendly

- **Modern Tech Stack**: Phoenix LiveView, Ash Framework, SQLite
- **Comprehensive Testing**: 383+ tests ensuring reliability
- **Easy Setup**: One command to get running (`just dev`)
- **Excellent Documentation**: Comprehensive guides for contributors

---

## 🎯 Project Status

**Current Version**: v0.2.0-dev (Comprehensive Financial Management)
**Stability**: All tests passing with new financial features  
**Next Release**: v0.2.0 (Cash Management & Net Worth - In Progress)

### ✅ Currently Available (v0.1.0 + v0.2.0 Features)

- ✅ **Investment Portfolio Tracking**: Complete account and transaction management
- ✅ **Net Worth Calculation**: Cross-account financial position analysis with NetWorthCalculator
- ✅ **Cash Account Management**: Support for checking, savings, money market, and CD accounts
- ✅ **Transaction Categories**: Investment transaction organization and categorization
- ✅ **Real-time Calculations**: Live portfolio value and performance analytics
- ✅ **Price Integration**: Yahoo Finance API with caching
- ✅ **Responsive Interface**: Works on all devices
- ✅ **Production Quality**: Comprehensive testing and error handling

### 🚧 Coming Soon (Enhanced UX & Additional Features)

**v0.2.0 (Q3 2025) - Remaining Cash Management & UX Features**:

- 🚧 **Symbol Autocomplete**: Intelligent symbol search in transaction forms (In Progress)
- 🚧 **Enhanced Dashboard**: Net worth integration and cash account displays
- 🚧 **Balance Management UI**: User-friendly cash balance update interfaces
- 🚧 **Category Management**: UI for creating and managing transaction categories

**Future Releases**:

- 🚧 **Expense Tracking & Asset Management**: Monthly spending analysis and real estate/vehicle tracking (v0.3.0)
- 🚧 **Retirement Planning & Advanced Analytics**: 25x rule calculations and professional portfolio analysis (v0.4.0)
- 🚧 **Tax Planning & Feature Completeness**: Tax optimization and comprehensive reporting (v0.5.0)

### 🎯 Development Roadmap

**v0.2.0 (Q3 2025)**: Cash Management & Enhanced UX  
**v0.3.0 (Q4 2025)**: Asset Tracking & Real-Time Features  
**v0.4.0 (Q1 2026)**: Financial Planning & Advanced Analytics  
**v0.5.0 (Q2 2026)**: Tax Planning & Feature Completeness

See our [unified roadmap](docs/roadmap/v0.2-v0.5-roadmap.md) for detailed feature timelines and technical specifications.

---

## 🏗️ Architecture Overview

Ashfolio follows a standard Phoenix architecture, enhanced by the Ash Framework for its business logic layer.

```mermaid
graph TD
    subgraph "Ashfolio Application"
        LV[Phoenix LiveView] --> BL[Business Logic Layer]
        BL --> DL[Data Layer]
        BL --> MS[Market Data Services]
        MS --> ETS[ETS Cache]
        MS --> EXT[External APIs (Yahoo Finance)]
    end

    subgraph "Business Logic Layer"
        AR[Ash Resources]
        PC[Portfolio Calculators]
    end

    subgraph "Data Layer"
        DB[(SQLite Database)]
    end

    LV -- "User Interaction" --> LV
    LV -- "Data Requests" --> AR
    AR -- "Data Storage" --> DB
    PC -- "Calculations" --> AR
    PC -- "Price Data" --> ETS
    ETS -- "Caching" --> DB
    EXT -- "Price Fetching" --> MS
```

For detailed architecture information, see our [comprehensive documentation](docs/).

---

## 🛠️ Development

### Tech Stack

- **Backend**: Elixir, Phoenix 1.7+, Ash Framework 3.0+
- **Database**: SQLite with `ecto_sqlite3` and `ash_sqlite`
- **Frontend**: Phoenix LiveView
- **Caching**: In-memory caching with ETS
- **HTTP Client**: `HTTPoison` for external API communication
- **Testing**: ExUnit, Mox, and Meck for comprehensive testing
- **Code Quality**: Credo for static analysis
- **Task Runner**: `just` for streamlined development commands

### Development Workflow

Ashfolio uses the `just` command runner with a comprehensive modular testing strategy.

#### Essential Development Commands

- **`just dev`**: Sets up the environment, installs dependencies, and starts the Phoenix server.
- **`just test`**: Runs the main test suite (excluding slower seeding tests).
- **`just test-file <path>`**: Runs tests for a specific file.
- **`just reset`**: Resets the database with fresh sample data.
- **`just`**: Lists all available `just` commands with descriptions.

#### Modular Testing Strategy (NEW)

Ashfolio implements architecture-aligned testing with ExUnit filters for optimal development workflow:

**Quick Development Feedback:**

- **`just test-fast`**: Quick tests for rapid development feedback (< 100ms)
- **`just test-smoke`**: Essential tests that must always pass

**Architectural Layer Testing:**

- **`just test-ash`**: Business logic tests (User, Account, Symbol, Transaction)
- **`just test-liveview`**: Phoenix LiveView UI component tests
- **`just test-calculations`**: Portfolio calculation and FIFO cost basis tests
- **`just test-market-data`**: Price fetching and Yahoo Finance integration tests

**Specialized Testing:**

- **`just test-unit`**: Isolated unit tests with minimal dependencies
- **`just test-integration`**: End-to-end workflow tests
- **`just test-regression`**: Tests for previously fixed bugs
- **`just test-error-handling`**: Error condition and fault tolerance tests

All commands support `-verbose` variants for detailed output (e.g., `just test-fast-verbose`).

For complete development setup, see our [Getting Started Guide](docs/getting-started/).

### 🤝 Contributing

We welcome contributions! Whether you're interested in:

- 🐛 **Bug fixes** - Help make Ashfolio more reliable
- ✨ **New features** - Add functionality you'd like to see
- 📚 **Documentation** - Improve guides and explanations
- 🧪 **Testing** - Strengthen our test coverage

Check out our [Contributing Guide](CONTRIBUTING.md) and [First Contribution Guide](docs/getting-started/first-contribution.md) to get started.

### 🌟 Recognition

Thanks to all contributors who help make Ashfolio better! Contributions of all sizes are appreciated.

---

## 📚 Documentation

### 🚀 Getting Started

- **[Installation Guide](docs/getting-started/installation.md)** - Set up Ashfolio in 5 minutes
- **[Quick Start](docs/getting-started/quick-start.md)** - Explore features immediately
- **[First Contribution](docs/getting-started/first-contribution.md)** - Make your first code contribution
- **[Troubleshooting](docs/getting-started/troubleshooting.md)** - Common issues and solutions

### 👩‍💻 Development

- **[Architecture Overview](docs/development/architecture.md)** - System design and patterns
- **[Database Management](docs/development/database-management.md)** - Working with SQLite
- **[AI Agent Guide](docs/development/ai-agent-guide.md)** - AI-assisted development

### 🧪 Testing

- **[Testing Overview](docs/testing/)** - Comprehensive testing framework
- **[Framework Guide](docs/testing/framework.md)** - Testing architecture and patterns
- **[SQLite Patterns](docs/testing/patterns.md)** - Database testing strategies

### 📡 API Reference

- **[REST API](docs/api/rest-api.md)** - Local API endpoints
- **[Endpoints](docs/api/endpoints.md)** - Technical specifications

---

## 💬 Community & Support

### 🔧 Need Help?

- **[Troubleshooting Guide](docs/getting-started/troubleshooting.md)** - Common solutions
- **[GitHub Issues](https://github.com/mdstaff/ashfolio/issues)** - Report bugs or request features
- **[GitHub Discussions](https://github.com/mdstaff/ashfolio/discussions)** - Ask questions and share ideas

### 🌟 Show Your Support

If Ashfolio helps manage your investments, consider:

- ⭐ **Star this repository** to show your support
- 🐛 **Report issues** to help improve the software
- 💡 **Suggest features** that would benefit other users
- 🤝 **Contribute code** to make Ashfolio even better

---

**License**: MIT - Feel free to use Ashfolio for personal or commercial projects.  
**Privacy**: Your financial data stays on your computer. Always.
