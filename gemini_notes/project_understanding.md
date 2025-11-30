# Project Understanding: Ashfolio

## Overview
Ashfolio is a personal financial management application designed for local-only use (privacy-focused). It tracks investments, cash accounts, and net worth without cloud dependencies, except for fetching market data (Yahoo Finance).

## Tech Stack
- **Language**: Elixir
- **Frameworks**: Phoenix LiveView, Ash Framework (3.0+)
- **Database**: SQLite (local file)
- **Styling**: Tailwind CSS
- **Data Layer**: `ash_sqlite`
- **Caching**: ETS (for price data)
- **Task Runner**: `just`

## Key Architecture
- **Single User**: No authentication required; defaults to a single local user.
- **Data Model**:
  - `User`: Singleton default user.
  - `Account`: Investment/Cash accounts.
  - `Symbol`: Securities (Stocks, ETFs, Crypto).
  - `Transaction`: Buy, Sell, Dividend, etc.
- **Market Data**:
  - `PriceManager` GenServer handles fetching (Yahoo Finance) and caching (ETS).
  - Updates are manual (user-initiated).
- **Calculations**:
  - `Calculator` & `HoldingsCalculator` modules.
  - FIFO cost basis.
  - Decimal precision for all financials.

## Current Status (v0.7.0 Complete / v0.8.0 Planning)
- **Current Version**: v0.7.0 "Advanced Portfolio Analytics" (Completed Sept 21, 2025).
- **Next Milestone**: v0.8.0 "Estate Planning & Advanced Tax Strategies" (Target: Q1 2026).
  - Focus: Beneficiary management, Step-up basis, Gift tax, Trust accounts, Multi-broker wash sales, AMT, Crypto tax.
  - Status: Planning Phase.
- **Recent Additions**: AI Integration (Natural Language Entry) added in v0.7.x.
- **Documentation Authority**: The `docs/` folder is the single source of truth. `.kiro/specs` is superseded.

## Architecture & Domain Expansion (ADR-002)
- **Shift**: From "Portfolio Only" to "Comprehensive Financial Management".
- **Domains**:
  - `Ashfolio.Portfolio`: UserSettings, Account, Symbol, Transaction.
  - `Ashfolio.FinancialManagement`: TransactionCategory, NetWorthCalculator, BalanceManager.
  - `Ashfolio.AI`: Dispatcher, Handlers, Model Abstraction (New in v0.7.x).
- **Database**: SQLite with WAL mode, optimized for time-series data.

## Testing Framework (`docs/testing/framework.md`)
- **Strategy**: Global Test Data (created once via `setup_global_test_data!`).
- **Concurrency**: **ALWAYS** use `async: false` for SQLite tests.
- **Commands**:
  - `just test`: Main suite.
  - `just test-fast`: Quick feedback (<100ms).
  - `just test-ash`: Business logic.
  - `just test-liveview`: UI.
- **Key Helper**: `Ashfolio.SQLiteHelpers` (provides `get_default_account`, `with_retry`, etc.).

## Key Development Rules
- **Precision**: Always use `Decimal`, never `Float`.
- **TDD**: Strict Test-Driven Development is required (write test -> fail -> implement).
- **Code GPS**: Use `mix code_gps` to understand codebase structure.

## Development Workflow
- **Setup**: `just dev`
- **Testing**: `just test`, `just test-fast`, `just test-safe` (includes DB health checks).
- **Database**: `just reset` to wipe/seed.

## Documentation
- **Specs**: `.kiro/specs/` contains the "steering documentation" (Requirements, Design, Tasks).
- **Guides**: `docs/` contains detailed dev guides. `docs/development/ai-agent-guide.md` is critical for AI agents.

## Questions / Notes
- **Version Discrepancy**: `README.md` lists v0.7.0, while `tasks.md` tracks progress towards v0.1.0. I will assume the project is further along than the initial specs might suggest, or the README is aspirational/updated separately.
- **Next Steps**: Phase 11 in `tasks.md` focuses on Documentation and Onboarding improvements.

## Gemini Folder
This folder (`gemini_notes`) will be used for my scratchpad and notes as requested.
