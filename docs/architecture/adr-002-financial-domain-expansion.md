# ADR-002: Financial Domain Expansion Architecture

**Status**: Accepted  
**Date**: 2025-01-10  
**Authors**: Development Team  
**Reviewers**: Project Architect, Technical Writing Agent

## Context

Ashfolio was initially designed as a focused portfolio management application for tracking investment accounts, transactions, and performance. User research has revealed a need for comprehensive personal financial management that includes cash accounts, expense tracking, net worth analysis, and retirement planning—essentially replacing spreadsheet-based wealth management workflows.

The current architecture uses Phoenix LiveView with the Ash Framework and SQLite for local-first portfolio management. This ADR addresses the decision to expand the architectural scope to encompass comprehensive financial management while maintaining the core local-first principles.

## Decision

**We will expand Ashfolio's architecture from portfolio-only management to comprehensive personal financial management.**

This expansion includes:

- Cash account management (checking, savings, money market)
- Non-investment asset tracking (real estate, vehicles, other assets)
- Expense tracking and categorization
- Net worth calculation and historical trending
- Retirement planning and financial forecasting
- Tax planning and optimization tools

## Architecture Strategy

### Domain Separation

We will implement domain separation using Ash Framework's domain structure:

```elixir
# Existing domain - focused on investments
Ashfolio.Portfolio
├── UserSettings (application preferences, database-as-user)
├── Account (investment and cash accounts)
├── Symbol
└── Transaction (investment transactions)

# New domain - comprehensive financial management
Ashfolio.FinancialManagement
├── TransactionCategory
├── NetWorthCalculator
├── BalanceManager
├── SymbolSearch
└── Future: Asset, Expense, FinancialGoal, TaxEvent
```

### Data Relationship Strategy

The expanded architecture will maintain clear relationships between domains:

```
User (1) → (*) Portfolio.Account
User (1) → (*) FinancialManagement.Asset
User (1) → (*) FinancialManagement.Expense
User (1) → (*) FinancialManagement.NetWorthSnapshot

Portfolio.Account (1) → (*) Portfolio.Transaction
Portfolio.Account (1) → (*) FinancialManagement.Expense (payment source)

FinancialManagement.Asset (1) → (*) AssetValueUpdate
```

### SQLite Optimization for Financial Data

Enhanced SQLite configuration for time-series financial data:

```elixir
config :ashfolio, Ashfolio.Repo,
  database: "ashfolio_data.db",
  pool_size: 8,
  pragma: [
    journal_mode: :wal,
    synchronous: :normal,
    temp_store: :memory,
    mmap_size: 536_870_912,  # 512MB for larger datasets
    cache_size: -128000,     # 128MB cache
    optimize: true,
    analysis_limit: 1000
  ]
```

Strategic indexing for time-series queries:

- Net worth snapshots indexed by user_id and date
- Expenses indexed by date, and category
- Asset value updates indexed by asset_id and date

## Implementation Phases

### Phase 1: Cash Management Foundation (4-6 weeks)

- Extend Portfolio.Account to support cash account types
- Add cash transaction management
- Implement basic net worth calculation
- Update dashboard with net worth display

### Phase 2: Asset & Expense Tracking (6-8 weeks)

- Implement FinancialManagement.Asset resource
- Add expense tracking and categorization
- Create NetWorthSnapshot time-series tracking
- Build comprehensive financial reporting

### Phase 3: Planning & Forecasting (8-10 weeks)

- Add financial goal setting and tracking
- Implement growth assumption modeling
- Build retirement planning calculations
- Create long-term projection capabilities

### Phase 4: Advanced Analytics (10-12 weeks)

- Add tax planning and optimization tools
- Implement advanced portfolio analytics
- Build rebalancing recommendations
- Create comprehensive reporting suite

## Rationale

### Advantages

1. **Architectural Alignment**: The Ash/SQLite foundation scales naturally to comprehensive financial data
2. **User Value**: Addresses real user needs for holistic financial management
3. **Local-First Preservation**: Maintains privacy and data ownership principles
4. **Incremental Development**: Phased approach minimizes risk and maintains existing functionality
5. **Domain Separation**: Clean architectural boundaries prevent feature sprawl
6. **SQLite Performance**: Proven capable of handling comprehensive financial datasets

### Technical Feasibility

- **Ash Framework**: Resource and relationship patterns scale to financial management domain
- **SQLite Performance**: Current system handles 1000+ positions efficiently; financial data follows similar patterns
- **Calculation Precision**: Existing Decimal precision infrastructure extends naturally
- **Time-Series Data**: SQLite with proper indexing handles historical financial data effectively

## Alternatives Considered

### Alternative 1: Separate Application

Create a new application for comprehensive financial management.

**Rejected because:**

- Duplicates existing infrastructure and authentication
- Forces users to manage multiple applications
- Splits related financial data across systems
- Increases maintenance burden

### Alternative 2: Plugin Architecture

Build financial management as optional plugins/modules.

**Rejected because:**

- Adds architectural complexity without clear benefit
- Financial data relationships are too integrated for plugin isolation
- User experience fragmentation
- Complicates testing and deployment

### Alternative 3: External Service Integration

Integrate with existing personal finance services.

**Rejected because:**

- Violates local-first architectural commitment
- Introduces external dependencies and privacy risks
- Reduces user control over financial data
- Creates vendor lock-in scenarios

## Consequences

### Positive Consequences

1. **Comprehensive Solution**: Single application handles complete financial picture
2. **Architectural Consistency**: Maintains Ash/SQLite patterns throughout
3. **User Experience**: Unified interface for all financial management
4. **Privacy Preservation**: All financial data remains local
5. **Competitive Advantage**: Few local-first comprehensive financial management solutions exist

### Negative Consequences

1. **Increased Complexity**: More resources, relationships, and business logic to maintain
2. **Testing Overhead**: Comprehensive financial scenarios require extensive test coverage
3. **User Migration**: Existing users must understand expanded scope and capabilities
4. **Performance Monitoring**: Larger datasets require ongoing performance validation
5. **Support Complexity**: More features mean more potential user issues

### Risk Mitigation Strategies

1. **Incremental Development**: Four-phase rollout minimizes risk of feature disruption
2. **Backward Compatibility**: All v0.1.x functionality remains intact
3. **Comprehensive Testing**: Property-based testing for financial calculations
4. **Performance Monitoring**: Telemetry and benchmarking for SQLite performance
5. **User Feedback**: Validation at each phase before proceeding

## Compliance and Monitoring

### Architecture Validation Criteria

- [ ] All new resources follow Ash Framework patterns
- [ ] SQLite queries perform under 1 second for 10+ years of data
- [ ] Financial calculations maintain Decimal precision throughout
- [ ] Local-first principles preserved (no external service dependencies)
- [ ] Test coverage above 90% for financial calculation logic

### Success Metrics

- **Technical**: Sub-second performance for comprehensive financial calculations
- **User**: Monthly financial updates complete in <30 minutes
- **Data**: 100% backward compatibility with existing portfolio data
- **Features**: Full replacement of spreadsheet-based workflow capabilities

## References

- [ADR-001: Local-First Architecture](adr-001-local-first-architecture.md)
- [Ash Framework Documentation](https://ash-hq.org/)
- [SQLite Performance Best Practices](https://www.sqlite.org/optoverview.html)
- [Phoenix LiveView Patterns](https://hexdocs.pm/phoenix_live_view/)

## Approval

This ADR has been reviewed and approved by:

- Project Architect: Approved - Architecture scales naturally with minimal risk
- Technical Writing Agent: Approved - Documentation strategy aligns with expansion scope
- Development Team: Approved - Implementation phases provide clear development path

**Final Status**: Accepted  
**Implementation Start**: Immediate (Phase 1: Cash Management Foundation)
