# Ashfolio 📊

**A modern, local-first portfolio management application for personal investment tracking.**

Built with Phoenix LiveView and the Ash Framework, Ashfolio provides a secure, privacy-focused solution for managing your investment portfolio on your own computer. No cloud dependencies, no data sharing—just powerful portfolio analysis at your fingertips.

[![Production Ready](https://img.shields.io/badge/Status-Production%20Ready-green)](https://github.com/mdstaff/ashfolio)
[![Test Coverage](https://img.shields.io/badge/Tests-383%20passing-brightgreen)](https://github.com/mdstaff/ashfolio)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 🚀 Quick Start

Get Ashfolio up and running in minutes!

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

### 💡 Powerful Features

- **📊 Real-time Dashboard**: Live portfolio value, returns, and performance analytics
- **💰 Multi-Account Support**: Track investments across brokerages (Schwab, Fidelity, etc.)
- **📈 FIFO Cost Basis**: Accurate profit/loss calculations using industry standards
- **💱 Price Integration**: Automatic price updates from Yahoo Finance
- **📱 Responsive Design**: Works beautifully on desktop, tablet, and mobile

### 🛠️ Developer Friendly

- **Modern Tech Stack**: Phoenix LiveView, Ash Framework, SQLite
- **Comprehensive Testing**: 383+ tests ensuring reliability
- **Easy Setup**: One command to get running (`just dev`)
- **Excellent Documentation**: Comprehensive guides for contributors

---

## 🎯 Project Status

**Current Version**: v0.1.0-rc(Production-Ready Beta)
**Stability**: All 383 tests passing  
**Release Target**: v0.1.0

### ✅ What's Working

- ✅ **Complete Portfolio Tracking**: Full account and transaction management
- ✅ **Real-time Calculations**: Live portfolio value and performance analytics
- ✅ **Price Integration**: Yahoo Finance API with caching
- ✅ **Responsive Interface**: Works on all devices
- ✅ **Production Quality**: Comprehensive testing and error handling

### 🚀 Ready for Use

Ashfolio is stable and ready for personal use. The core functionality is complete and well-tested.

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
