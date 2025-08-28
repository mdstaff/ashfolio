# Ashfolio Financial Management Expansion Roadmap

1.0  
 2025-08-10  
 ⚠️ SUPERSEDED - Merged into [Unified Roadmap](v0.2-v0.5-roadmap.md)

> This document has been superseded by the unified roadmap at `v0.2-v0.5-roadmap.md` which combines comprehensive financial management expansion with key portfolio improvements. Please refer to the unified roadmap for current development plans.
>
> This document is preserved for historical reference and architectural context.

## 🎯 Strategic Vision

Transform Ashfolio from a focused portfolio tracker into a comprehensive personal financial management system while maintaining local-first, privacy-focused architecture. This expansion addresses real user needs for replacing spreadsheet-based wealth management workflows with a unified, secure application.

Target User Profile: Individuals managing comprehensive wealth across multiple account types, planning for retirement, and seeking to eliminate manual spreadsheet maintenance while maintaining complete data ownership.

## 📊 Current State Analysis

### What We Have Today (v0.1.0-rc)

- Multi-account tracking with FIFO cost basis
- Yahoo Finance integration with caching
- Buy/sell/dividend transactions with validation
- Portfolio value, returns, and basic performance metrics
- SQLite database, no cloud dependencies
- 383+ tests, comprehensive error handling

### What Users Need (Comprehensive Financial Management)

- 🔄 Checking, savings, money market accounts
- 🔄 Complete financial position across all account types
- 🔄 Monthly spending analysis and budget management
- 🔄 Real estate, vehicles, and other valuable assets
- 🔄 Goal setting, 25x rule calculations, withdrawal planning
- 🔄 Realized gains tracking, tax-loss harvesting optimization
- 🔄 Long-term projections and scenario planning

## 🗓️ Implementation Timeline

### Phase 1: Cash Management Foundation

4-6 weeks (August - September 2025)  
 v0.2.0  
 "Complete Account Management"

#### Core Objectives

Extend the current portfolio-focused architecture to support cash accounts and basic net worth calculation.

#### Feature Deliverables

1.1 Extended Account Types (Week 1-2)

- Extend `Ashfolio.Portfolio.Account` to support cash account types
- Add support for checking, savings, money market, CD accounts
- Institution tracking and account identification (last 4 digits)
- Interest rate tracking for savings accounts

  1.2 Cash Transaction Management (Week 2-3)

- Deposits, withdrawals, transfers between accounts
- Bill payment tracking and categorization
- Account balance reconciliation tools
- Transaction import/export capabilities

  1.3 Basic Net Worth Calculation (Week 3-4)

- Aggregate balance calculation across all account types
- Real-time net worth display on dashboard
- Simple assets minus liabilities calculation
- Month-over-month change indicators

  1.4 Enhanced Dashboard (Week 4-6)

- Integrated net worth display with portfolio metrics
- Cash vs investment allocation visualizations
- Account balance summaries and trends
- Responsive design for comprehensive financial data

#### Technical Implementation Details

```elixir
# Extended Account Resource
attribute :account_type, :atom do
  constraints(one_of: [:investment, :checking, :savings, :money_market, :cd])
end
attribute :institution, :string
attribute :interest_rate, :decimal
```

#### Success Criteria

- [ ] Users can track cash accounts alongside investment accounts
- [ ] Real-time net worth calculation from all accounts (<1 second)
- [ ] 100% backward compatibility with existing portfolio functionality
- [ ] Dashboard performance maintained with expanded data

#### Migration Strategy

- All existing v0.1.x investment accounts remain unchanged
- New cash account features are additive and optional
- Clear upgrade documentation for existing users

---

### Phase 2: Asset & Expense Tracking

6-8 weeks (October - November 2025)  
 v0.3.0  
 "Comprehensive Financial Picture"

#### Core Objectives

Add comprehensive asset management and expense tracking to provide complete financial visibility.

#### Feature Deliverables

2.1 Non-Investment Asset Management (Week 1-3)

- Real estate tracking with address and valuation methods
- Vehicle management with depreciation calculations
- Other assets (collectibles, jewelry, etc.)
- Manual and market-based valuation updates
- Asset value history and trending

  2.2 Expense Tracking System (Week 2-4)

- Expense categories and custom categorization
- Monthly expense entry and bulk import
- Recurring expense management and prediction
- Budget vs actual analysis and alerts
- Essential vs discretionary expense classification

  2.3 Historical Net Worth Analytics (Week 4-6)

- Monthly automated net worth snapshots
- Historical trending with year-over-year comparisons
- Asset allocation drift tracking and analysis
- Net worth composition breakdowns
- Export capabilities for tax preparation

  2.4 Financial Reporting Suite (Week 6-8)

- Monthly financial summary reports
- Expense category breakdown analysis
- Cash flow statements and projections
- Net worth composition and allocation reports
- Customizable reporting periods and filters

#### New Resource Architecture

```elixir
# New Financial Management Domain
Ashfolio.FinancialManagement.Asset
Ashfolio.FinancialManagement.ExpenseCategory
Ashfolio.FinancialManagement.Expense
Ashfolio.FinancialManagement.NetWorthSnapshot
```

#### Success Criteria

- [ ] Track home equity, vehicle values, and major assets
- [ ] Categorize and analyze monthly expenses effectively
- [ ] Generate monthly net worth snapshots automatically
- [ ] Provide comprehensive expense vs income analysis
- [ ] Maintain SQLite performance with expanded data model

---

### Phase 3: Planning & Forecasting

8-10 weeks (December 2025 - February 2026)  
 v0.4.0  
 "Financial Planning & Retirement Readiness"

#### Core Objectives

Implement comprehensive financial planning tools for retirement readiness and long-term financial forecasting.

#### Feature Deliverables

3.1 Financial Goal Setting & Tracking (Week 1-3)

- Retirement savings targets using 25x annual expenses rule
- Emergency fund goals (3-6 months expenses)
- Custom savings goals with timelines and milestones
- Progress tracking with visual indicators
- Goal adjustment recommendations based on performance

  3.2 Growth Assumptions & Modeling (Week 2-4)

- Configurable growth rates by asset class
- Inflation assumption management and scenarios
- Conservative/moderate/aggressive projection models
- Monte Carlo simulation capabilities for risk assessment
- Sensitivity analysis for key financial assumptions

  3.3 Retirement Planning Tools (Week 4-6)

- 4% withdrawal rate calculations and scenarios
- Social Security income integration and planning
- Required minimum distribution (RMD) calculations
- Early retirement scenario planning and feasibility
- Healthcare cost planning and long-term care considerations

  3.4 Long-term Financial Forecasting (Week 6-8)

- Net worth projection charts (30+ year timelines)
- Retirement readiness assessments and gap analysis
- Timeline to financial independence calculations
- Multiple scenario planning (optimistic/realistic/pessimistic)
- Goal achievement probability analysis

  3.5 Enhanced Dividend & Income Analysis (Week 8-10)

- Forward-looking dividend income projections
- Dividend growth rate assumptions and modeling
- Income replacement calculations for retirement
- Dividend reinvestment impact analysis
- Early retirement income sufficiency assessments

#### Technical Implementation

- Background job processing for complex calculations (Oban)
- Statistical analysis libraries for Monte Carlo simulations
- Efficient time-series data storage and querying
- Caching strategies for expensive projection calculations

#### Success Criteria

- [ ] Calculate retirement readiness using 25x expenses rule
- [ ] Generate 30+ year net worth projections accurately
- [ ] Model multiple retirement scenarios effectively
- [ ] Project dividend income for early retirement planning
- [ ] Provide actionable financial planning insights

---

### Phase 4: Advanced Analytics & Tax Planning

10-12 weeks (March - May 2026)  
 v0.5.0  
 "Professional-Grade Financial Analysis"

#### Core Objectives

Implement professional-level financial analytics and tax optimization tools.

#### Feature Deliverables

4.1 Tax Planning & Optimization (Week 1-4)

- Realized capital gains and losses tracking
- Tax-loss harvesting opportunity identification
- Tax-efficient asset location recommendations
- Roth conversion planning and analysis
- Tax bracket optimization strategies

  4.2 Advanced Portfolio Analytics (Week 2-6)

- Asset class diversification analysis with pie charts
- Correlation matrix visualization and analysis
- Risk metrics calculation (Sharpe ratio, max drawdown)
- Performance attribution analysis by asset class
- Benchmark comparison and relative performance

  4.3 Rebalancing & Optimization Tools (Week 4-8)

- Target allocation vs current allocation analysis
- Rebalancing recommendations with tax considerations
- Dollar-cost averaging optimization strategies
- Asset allocation drift alerts and recommendations
- Tax-aware rebalancing to minimize tax impact

  4.4 Comprehensive Reporting Suite (Week 6-10)

- Annual tax summary reports for tax preparation
- Performance reports with multiple benchmark comparisons
- Financial health scorecards with actionable insights
- Comprehensive export capabilities (PDF, CSV, Excel)
- Custom report builder with filtering and grouping

  4.5 "Your Money Ratios" Integration (Week 8-12)

- Net Worth/Salary ratio analysis (Charles Farrell methodology)
- Expense/Income ratio tracking and optimization
- Emergency fund adequacy assessments
- Debt-to-income analysis and recommendations
- Age-based financial health benchmarking

#### Advanced Technical Components

- Statistical calculation engine for portfolio analytics
- PDF generation for comprehensive reports
- Advanced querying and aggregation for large datasets
- Real-time correlation and risk calculations

#### Success Criteria

- [ ] Provide comprehensive tax planning insights
- [ ] Generate professional-grade portfolio analytics
- [ ] Automate rebalancing recommendations effectively
- [ ] Calculate and track "Your Money Ratios" benchmarks
- [ ] Export professional-quality reports for advisors/taxes

---

## 🏗️ Architectural Evolution

### Domain Architecture Strategy

Single Portfolio Domain

```
Ashfolio.Portfolio
├── User
├── Account (investment only)
├── Symbol
└── Transaction (investment only)
```

Dual Domain Architecture

```
Ashfolio.Portfolio (investment-focused)
├── User
├── Account (investment accounts)
├── Symbol
└── Transaction (investment transactions)

Ashfolio.FinancialManagement (comprehensive financial)
├── Asset (non-investment assets)
├── CashAccount (cash management)
├── ExpenseCategory
├── Expense
├── NetWorthSnapshot
├── FinancialGoal
├── TaxEvent
└── PortfolioAnalytics
```

### Data Relationship Evolution

Basic relationships between domains

```
User (1) → (*) Portfolio.Account
User (1) → (*) FinancialManagement.CashAccount
```

Comprehensive cross-domain relationships

```
User (1) → (*) [Accounts, Assets, Expenses, Goals, Snapshots]
Account (1) → (*) [Transactions, Expenses]
Asset (1) → (*) ValueUpdates
NetWorthSnapshot → [calculated from all user accounts and assets]
```

### SQLite Performance Strategy

```elixir
config :ashfolio, Ashfolio.Repo,
  database: "ashfolio_comprehensive.db",
  pool_size: 8,  # Increased for concurrent calculations
  pragma: [
    journal_mode: :wal,
    synchronous: :normal,
    temp_store: :memory,
    mmap_size: 536_870_912,  # 512MB for comprehensive datasets
    cache_size: -128000,     # 128MB cache
    optimize: true
  ]
```

- Time-series indexes for net worth snapshots and historical data
- Compound indexes for user-date queries across all financial data
- Covering indexes for common aggregation queries

## 🎯 Success Metrics & Validation

### Technical Performance Metrics

- Sub-second response for comprehensive financial calculations
- 100% accuracy for net worth and financial projections
- Handle 10+ years of comprehensive financial data efficiently
- Maintain >90% coverage for all financial calculation logic

### User Experience Metrics

- Monthly financial updates in <30 minutes (vs. spreadsheet)
- Eliminate manual calculation errors through automation
- Comprehensive financial health visibility in single dashboard
- Clear retirement readiness and goal progress tracking

### Migration Success Metrics

- 100% v0.1.x functionality preserved
- Gradual adoption of new features without workflow disruption
- Seamless upgrade path for existing portfolio data
- Clear guides for each expansion phase

## 🔒 Privacy & Security Considerations

### Data Expansion Impact

- Financial data expands from investment-only to comprehensive
- Includes cash balances, expenses, assets, and planning data
- All data remains local in SQLite, no cloud transmission
- Users maintain complete ownership and control

### Privacy Enhancements

- Users can export all financial data at any time
- All new features are optional and can be disabled
- Clear policies for historical data management
- Transaction logs for all data modifications

## 📚 Documentation Evolution

### New Documentation Requirements

User Guides (NEW):

- Monthly financial management workflow
- Cash account management guide
- Expense tracking and budgeting
- Retirement planning walkthrough
- Tax planning and optimization

Technical Documentation (UPDATED):

- Financial domain architecture
- Time-series data patterns
- Calculation methodology documentation
- Performance optimization guides

API Documentation (EXPANDED):

- Comprehensive endpoint coverage
- Financial data export formats
- Integration patterns for financial data

## 🤝 Community & Feedback Strategy

### User Validation Process

- User validation at each development phase
- Early access for comprehensive workflow testing
- Extensive testing of upgrade paths
- Real user workflow testing before feature completion

### Community Engagement

- Regular community updates on development progress
- Structured process for community feature suggestions
- Community-contributed guides and best practices
- Enhanced support for expanded feature set

## 🎯 Risk Management

### Technical Risks & Mitigation

- Strict phase-based development with validation gates
- Comprehensive benchmarking and optimization
- Extensive testing with realistic data sets
- Clear phase boundaries and feature evaluation criteria

### User Experience Risks & Mitigation

- Progressive feature introduction and optional adoption
- Maintain all existing workflows throughout expansion
- Comprehensive documentation and guided onboarding
- Clear upgrade paths and data preservation guarantees

## 🚀 Get Involved

### For Users

- Share your current financial management workflows and pain points
- Join early access programs for new features
- Contribute real-world usage examples and guides

### For Developers

- Contribute to phase development based on your expertise
- Help build comprehensive test coverage for financial features
- Improve technical and user-facing documentation

---

This roadmap represents a strategic evolution of Ashfolio from focused portfolio management to comprehensive financial management while preserving the core principles of privacy, local-first architecture, and user data ownership.

_For detailed implementation specifications, see [ADR-002: Financial Domain Expansion Architecture](../architecture/adr-002-financial-domain-expansion.md)_
