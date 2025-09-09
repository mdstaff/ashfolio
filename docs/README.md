# Ashfolio Documentation

Welcome to Ashfolio - a comprehensive personal financial management platform with portfolio tracking, tax optimization, retirement planning, and financial health assessment.

## 🚀 Quick Start

- **Installation** → [getting-started/installation.md](getting-started/installation.md)
- **First Steps** → [getting-started/first-contribution.md](getting-started/first-contribution.md)
- **Troubleshooting** → [getting-started/troubleshooting.md](getting-started/troubleshooting.md)

## Development

- Architecture Overview → [development/architecture.md](development/architecture.md)
- Database Management → [development/database-management.md](development/database-management.md)
- Data Utilities Guide → [development/data-utilities-guide.md](development/data-utilities-guide.md)
- Elixir & Mix Insights → [development/elixir-mix-insights.md](development/elixir-mix-insights.md)
- AI Agent Development → [development/ai-agent-guide.md](development/ai-agent-guide.md)
- Code GPS Guide → [development/code-gps-guide.md](development/code-gps-guide.md)
- Phoenix LiveView Layouts → [development/phoenix-liveview-layouts.md](development/phoenix-liveview-layouts.md)
- SQLite Optimizations → [development/sqlite-optimizations.md](development/sqlite-optimizations.md)

## Testing

- Testing Strategy → [TESTING_STRATEGY.md](TESTING_STRATEGY.md)
- SQLite Testing Patterns → [testing/patterns.md](testing/patterns.md)

## API Reference

- REST API Guide → [api/rest-api.md](api/rest-api.md)
- API Endpoints → [api/endpoints.md](api/endpoints.md)

## 📚 User Guides

### Core Features
- **Portfolio Management** → [user-guides/portfolio-management.md](user-guides/portfolio-management.md)
- **Expense Tracking** → [user-guides/expense-tracking.md](user-guides/expense-tracking.md)

### Advanced Features (v0.5.0)
- **Money Ratios Assessment** → [user-guides/money-ratios-assessment.md](user-guides/money-ratios-assessment.md) 🆕
- **Tax Planning & Optimization** → [user-guides/tax-planning-optimization.md](user-guides/tax-planning-optimization.md) 🆕
- **Portfolio Analytics (TWR/MWR)** → [user-guides/portfolio-analytics-guide.md](user-guides/portfolio-analytics-guide.md) 🆕
- **Retirement Planning** → [user-guides/retirement-planning.md](user-guides/retirement-planning.md)

## 🎯 Current Status

### v0.5.0 Complete ✅
Ashfolio has reached feature completeness with:
- **1,680+ comprehensive tests** passing
- **Money Ratios** financial health assessment (Charles Farrell methodology)
- **Tax Planning** with FIFO cost basis and loss harvesting
- **Advanced Analytics** including TWR and MWR calculations
- **Performance Optimized** (<100ms portfolio calculations)

## Roadmap & Planning

- **v0.5.0 COMPLETE** → [Consolidated Archive](archive/v0.1-v0.5-consolidated-archive.md)
- **v0.6.0 Planning** → [Financial Expansion Roadmap](roadmap/financial-expansion-roadmap.md)
- **UI/UX Improvements** → [roadmap/ui-ux-improvements.md](roadmap/ui-ux-improvements.md)
- **Architecture Decisions** → [architecture/](architecture/)

## 📋 Feature Overview

### Portfolio Management
- Multi-account tracking (brokerage, retirement, cash)
- FIFO cost basis with tax lot tracking
- Real-time position updates with PubSub
- Transaction import and categorization
- Dividend and split tracking

### Financial Analytics
- Time-Weighted Returns (TWR)
- Money-Weighted Returns (MWR/XIRR)
- Risk metrics (Sharpe, Sortino, Max Drawdown)
- Benchmark comparisons
- Performance attribution

### Tax Optimization
- Capital gains/loss tracking
- Tax loss harvesting opportunities
- Wash sale rule compliance
- Tax-efficient rebalancing
- Year-end tax planning tools

### Financial Planning
- Money Ratios assessment (savings, debt, capital)
- Retirement readiness analysis
- 25x rule and 4% withdrawal modeling
- FIRE calculations
- Monte Carlo simulations

### Expense Management
- Automatic categorization
- Trend analysis and budgeting
- Custom categories
- Spending insights
- Monthly/annual reports

---

_For quick development setup: `just dev`_
_For comprehensive project guidelines: [../CONTRIBUTING.md](../CONTRIBUTING.md)_
_Stack: Phoenix LiveView 1.7.14 + Ash 3.4 + SQLite_
