# Ashfolio

A simplified Phase 1 portfolio management application built with Phoenix LiveView and the Ash Framework. Designed for single-user local deployment, Ashfolio helps you track your investments with manual price updates.

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

## ✨ Key Features

- **Comprehensive Data Model**: Manages Users, Accounts, Symbols, and Transactions with robust validations.
- **Portfolio Calculation Engine**: Advanced dual-calculator architecture for accurate portfolio analysis, including FIFO cost basis and P&L.
- **Intuitive Dashboard**: A responsive LiveView dashboard displaying real-time portfolio value, returns, and a sortable holdings table.
- **Transaction Management**: Full CRUD operations for investment transactions (BUY, SELL, DIVIDEND, FEE, INTEREST, LIABILITY).
- **Account Management**: Create, edit, delete, and exclude investment accounts from calculations.
- **Manual Price Updates**: User-initiated price refreshes via Yahoo Finance integration.
- **Robust Testing**: A high-coverage test suite ensures stability and reliability.

---

## 📊 Project Status

**Current Version**: v0.26.0 (Production-Ready Beta)  
**Overall Progress**: 86% Complete (25/29 tasks)  
**Phase Status**: Phase 10 - Testing and Polish

### ✅ Completed Features

- ✅ **Complete Portfolio Management**: All core CRUD operations for accounts and transactions
- ✅ **Real-time Dashboard**: Portfolio calculations with holdings table and P&L analysis
- ✅ **Manual Price Updates**: Yahoo Finance integration with user-initiated refresh
- ✅ **Professional UI**: Responsive Phoenix LiveView interface with mobile support
- ✅ **Production-Ready Code**: Clean compilation, comprehensive testing (192+ tests)

### 🔄 Current Focus

- **Responsive Design**: WCAG AA accessibility compliance and mobile optimization
- **Final Testing**: 100% test coverage and integration testing
- **v1.0 Preparation**: Manual testing and release preparation

### 🎯 Next Release

- **v1.0.0**: Production release with complete responsive design and final polish (estimated 2-4 days)

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

For a more detailed breakdown of the system architecture, including Ash Resource relationships and LiveView component flows, please refer to the [Architecture Documentation](docs/ARCHITECTURE.md).

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

Ashfolio uses the `just` command runner to simplify common development tasks.

- **`just dev`**: Sets up the environment, installs dependencies, and starts the Phoenix server.
- **`just test`**: Runs the main test suite (excluding slower seeding tests).
- **`just test-file <path>`**: Runs tests for a specific file.
- **`just reset`**: Resets the database with fresh sample data.
- **`just`**: Lists all available `just` commands with descriptions.

For a complete guide to setting up your development environment, including manual installation steps and troubleshooting, see [DEVELOPMENT_SETUP.md](docs/DEVELOPMENT_SETUP.md).

### Contributing

We welcome contributions to Ashfolio! Please see our [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to get started, coding standards, and the pull request process.

---

## 📚 Documentation

### API Documentation

- **[REST API Guide](docs/api/rest-api.md)**: Complete guide to the local REST API endpoints
- **[API Reference](docs/api/endpoints.md)**: Detailed technical specifications for all endpoints

### Testing Documentation

- **[Accessibility Testing](docs/testing/accessibility-checklist.md)**: WCAG AA compliance testing procedures

### Project Specifications

- **[Requirements](/.kiro/specs/requirements.md)**: Complete feature requirements and acceptance criteria
- **[Design Document](/.kiro/specs/design.md)**: Technical architecture and implementation details
- **[Implementation Tasks](/.kiro/specs/tasks.md)**: Detailed task breakdown and progress tracking

---

## ❓ Getting Help

If you encounter any issues or have questions:

- Check the [DEVELOPMENT_SETUP.md](docs/DEVELOPMENT_SETUP.md) for common troubleshooting steps.
- Review the [Elixir Installation Guide](https://elixir-lang.org/install.html) and [Phoenix Installation Guide](https://hexdocs.pm/phoenix/installation.html).
- Feel free to open an issue on the GitHub repository.
