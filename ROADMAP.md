# Ashfolio Roadmap: v0.6.0 - v1.0 (Professional-Grade Financial Platform)

> Local-first, single-user, SQLite-based comprehensive financial management platform
>
> Updated: September 2025 | Based on CFP/CPA Professional Assessment

Transform Ashfolio from comprehensive personal finance tool to professional-grade platform meeting fiduciary and regulatory standards.

## Current State: v0.5.0 ✅ COMPLETED

### Delivered Features
- **Portfolio Management**: FIFO cost basis tracking with multi-account support
- **Tax Planning**: Capital gains analysis, tax-loss harvesting opportunities
- **Money Ratios**: Charles Farrell's 8-ratio financial health assessment
- **Retirement Planning**: 25x rule, 4% SWR, Monte Carlo projections
- **Expense Analytics**: Complete tracking with categorization and trends
- **Financial Goals**: Emergency fund, retirement, custom savings goals
- **Performance Analytics**: TWR/MWR calculations with benchmarking
- **Architecture**: 1,669 tests, Decimal precision, ETS caching, PubSub updates

### Professional Assessment Score: A- (Exceptional for v0.5)

## v0.6.0: Professional Standards & Tax Accuracy 🎯

*Q4 2025 - Q1 2026 (12 weeks)*  
*Priority: Features required for professional financial advisory use*

### Phase 1: Tax Accuracy & Compliance (Weeks 1-4) 🏆 HIGHEST PRIORITY

#### Corporate Actions Engine (Score: 94/100)
**Why Critical**: #1 source of tax reporting errors and amended returns

- **Stock Splits** - Forward/reverse with automatic basis adjustment
- **Dividends** - Cash/stock/special with qualified status tracking
- **Mergers & Acquisitions** - Symbol conversion, cash/stock consideration
- **Spin-offs** - Cost basis allocation per IRS guidelines
- **Return of Capital** - Basis reduction tracking
- **Capital Distributions** - Proper gain/loss recognition

**Acceptance Criteria**:
- All adjustments maintain FIFO ordering
- Historical transactions show adjustment notes
- Total portfolio value unchanged by splits
- Qualified dividend identification for tax rates

#### Tax Document Generation (Score: 92/100) 🆕
**Why Critical**: IRS compliance and audit defense

- **Schedule D Export** - Capital gains/losses in IRS format
- **Form 8949** - Detailed transaction reporting with adjustments
- **1099-B Reconciliation** - Match broker reported basis
- **State Tax Reports** - Multi-state capital gains allocation
- **Tax Loss Harvesting Report** - Wash sale adjusted opportunities
- **Estimated Tax Calculator** - Quarterly payment optimization

**Acceptance Criteria**:
- Export formats match IRS specifications
- Wash sale adjustments properly calculated
- State allocation based on residence dates
- PDF and CSV export options

### Phase 2: Fiduciary Compliance (Weeks 5-8)

#### Risk Analytics Suite (Score: 78/100)
**Why Critical**: Required for Investment Policy Statements and fiduciary duty

- **Sharpe Ratio** - Risk-adjusted return measurement
- **Sortino Ratio** - Downside deviation focus
- **Information Ratio** - Active management assessment
- **Maximum Drawdown** - Peak-to-trough analysis
- **Value at Risk (VaR)** - 95% confidence interval
- **Beta & Correlation** - Systematic risk measurement
- **Standard Deviation** - Volatility tracking

**Acceptance Criteria**:
- All calculations use daily returns
- Minimum 3-year history for validity
- Cache results for performance
- Export for IPS documentation

#### Portfolio Optimization Engine (Score: 76/100)
**Why Critical**: Professional portfolio management standard

- **Tax-Aware Rebalancing** - Minimize realized gains
- **Asset Location Optimizer** - Tax-efficient placement
- **Rebalancing Bands** - Threshold-based triggers
- **Trade Optimization** - Minimize transaction costs
- **Tax Budget Setting** - Annual gain/loss targets
- **Loss Harvesting Integration** - Coordinated tax strategy

**Acceptance Criteria**:
- Consider wash sale rules
- Account for transaction costs
- Generate rebalancing orders
- Estimate tax impact before execution

### Phase 3: Advanced Planning Tools (Weeks 9-12)

#### Required Minimum Distributions (RMD) 🆕
**Why Critical**: SECURE Act 2.0 compliance, avoiding 50% penalty

- **RMD Calculator** - Age-based requirements
- **Inherited IRA Rules** - 10-year rule tracking
- **QCD Optimization** - Qualified Charitable Distributions
- **Multiple Account Aggregation** - Satisfy from any IRA
- **Roth Exclusion** - Proper account type handling
- **Penalty Tracker** - Missed RMD warnings

**Acceptance Criteria**:
- SECURE Act 2.0 rules (age 73+)
- Uniform lifetime table accuracy
- Multi-beneficiary calculations
- Year-end deadline alerts

#### Roth Conversion Optimizer 🆕
**Why Critical**: Multi-year tax planning optimization

- **Tax Bracket Analysis** - Fill lower brackets
- **IRMAA Cliff Awareness** - Medicare premium impacts
- **Multi-Year Planning** - 5-10 year optimization
- **State Tax Consideration** - Relocation planning
- **Recharacterization Tracking** - Undo conversions
- **Pro-Rata Rule** - IRA basis tracking

**Acceptance Criteria**:
- Current year tax projection
- Medicare surcharge thresholds
- State tax differential analysis
- Conversion ladder planning

## v0.7.0: Advanced Portfolio Analytics 🚧 IN PROGRESS

*Q4 2025 (8 weeks)*
*Focus: Professional-grade portfolio analytics and optimization*

### Status: 50% Complete
- **Stage 1**: Risk Metrics (Beta, Drawdown, Calmar, Sterling) ✅ Complete
- **Stage 2**: Correlation & Covariance Matrices ✅ Complete
- **Stage 3**: Portfolio Optimization (Efficient Frontier) 🚧 Next
- **Stage 4**: Advanced Analytics LiveView 📋 Planned

### Completed Features (September 2025)

#### Advanced Risk Metrics ✅
- **Beta Calculator** - Systematic risk vs market (20 tests passing)
- **Drawdown Calculator** - Maximum loss and recovery tracking (24 tests)
- **Enhanced Risk Metrics** - Added Calmar & Sterling ratios (13 new tests)
- Performance: All calculations < 100ms requirement met

#### Correlation & Covariance Analysis ✅
- **Correlation Calculator** - Pearson correlation, matrices, rolling windows (27 tests)
- **Covariance Calculator** - Pairwise and matrix calculations (16 tests)
- Full Decimal precision throughout
- Newton's method for square root calculations

### Remaining Work

#### Portfolio Optimization Engine
- **Efficient Frontier** - Mean-variance optimization
- **Monte Carlo Simulation** - Risk/return scenarios
- **Rebalancing Recommendations** - Tax-aware suggestions
- **Asset Allocation Analysis** - Optimal portfolio weights

#### Advanced Analytics LiveView
- **Interactive Dashboards** - Real-time analytics
- **Correlation Heatmaps** - Visual correlation matrices
- **Risk/Return Scatter** - Portfolio positioning
- **Historical Performance** - Time-series analysis

## v0.8.0: Estate & Advanced Tax Planning

*Q1 2026 (8 weeks)*
*Focus: Comprehensive wealth transfer and advanced tax strategies*

### Estate Planning Foundation 🆕
- **Beneficiary Management** - Primary/contingent tracking
- **Step-Up Basis Modeling** - Estate tax planning
- **Gift Tax Tracking** - Annual exclusion monitoring
- **Trust Account Support** - Revocable/irrevocable basics
- **Inherited Asset Tracking** - Basis and date tracking
- **Estate Tax Calculator** - Federal/state estimates

### Multi-Broker Risk Management 🆕
- **Cross-Broker Wash Sale Alerts** - Real-time violation prevention
- **Multi-Account Transaction Coordination** - Unified trading view
- **Consolidated Position Tracking** - Total exposure across brokers
- **Historical Data Recovery Tools** - Reconstruct lost basis from transfers

### Alternative Minimum Tax (AMT) 🆕
- **ISO Exercise Planning** - Minimize AMT exposure
- **AMT Credit Tracking** - Carryforward management
- **Preference Item Analysis** - Identify AMT triggers
- **Multi-Year AMT Planning** - Strategic timing

### Cryptocurrency Tax Compliance 🆕
- **Crypto Cost Basis** - FIFO/LIFO/specific ID
- **Mining/Staking Income** - Ordinary income tracking
- **DeFi Transaction Import** - Yield farming, liquidity
- **NFT Gain/Loss** - Collectibles tax rate

## v0.9.0: Institutional Features

*Q2 2026 (8 weeks)*  
*Focus: Features for advisors managing multiple households*

### Multi-Entity Support
- **Business Accounts** - LLC, S-Corp, C-Corp
- **401(k)/403(b) Integration** - Employer plan tracking
- **Equity Compensation** - RSU, ISO, ESPP
- **Deferred Compensation** - 409A tracking

### Advanced Reporting
- **Client Presentation Mode** - Professional reports
- **Batch Report Generation** - Multiple time periods
- **Custom Report Builder** - Drag-and-drop fields
- **Audit Trail** - Complete change history

## v0.10.0: Integration & Automation

*Q3 2026 (6 weeks)*  
*Focus: Workflow automation and external integrations*

### Import/Export Ecosystem
- **TurboTax Integration** - Direct tax export
- **Quicken/Mint Import** - Migration tools
- **PDF Statement Parser** - OCR for statements
- **API Framework** - Read-only access

### Automation Features
- **Rule-Based Categorization** - ML-powered
- **Scheduled Reports** - Email delivery
- **Alert System** - Rebalancing, RMD, tax
- **Backup Automation** - Encrypted backups

## v1.0.0: Production Release

*Q1 2027 (4 weeks)*  
*Focus: Polish, performance, and production readiness*

### Release Criteria
- ✅ 2,000+ tests passing
- ✅ 100% critical path coverage
- ✅ Professional documentation
- ✅ Performance benchmarks met
- ✅ Security audit passed
- ✅ WCAG accessibility compliance
- ✅ Cross-platform testing complete

## Success Metrics

### Professional Adoption Metrics
- **CFP/CPA Validation**: Features meet professional standards
- **Regulatory Compliance**: IRS reporting accuracy 100%
- **Performance Standards**: All calculations <100ms
- **Accuracy Standards**: Decimal precision, no rounding errors
- **Security Standards**: Encrypted local storage

### Technical Excellence Metrics
- **Test Coverage**: >95% for financial calculations
- **Code Quality**: Zero Credo/Dialyzer warnings
- **Performance**: <500ms dashboard refresh
- **Reliability**: <0.1% error rate in production
- **Documentation**: 100% public API documented

## Development Principles

### Mandatory Requirements
- ✅ Test-Driven Development (Red-Green-Refactor)
- ✅ Decimal type for all financial calculations
- ✅ FIFO cost basis consistency
- ✅ Local-first architecture maintained
- ✅ No cloud dependencies added

### Quality Gates (Per Feature)
1. Comprehensive test suite written first
2. CFP/CPA review of calculations
3. Performance benchmarks verified
4. Documentation complete
5. Integration tests passing

## Risk Mitigation

### Regulatory Risks
- **Tax Law Changes**: Modular tax engine for easy updates
- **State Variations**: Configurable state tax rules
- **International**: US-focused initially, extensible design

### Technical Risks
- **SQLite Scaling**: Performance testing at 1M+ transactions
- **Calculation Complexity**: ETS caching for expensive operations
- **Data Migration**: Comprehensive backup/restore system

## Long-Term Vision (Post v1.0)

### Potential Expansions
- Multi-user/family support (major architecture change)
- Cloud sync option (optional, privacy-preserved)
- Mobile applications (iOS/Android)
- International tax support
- Institutional advisor platform

### Maintaining Core Values
- Local-first remains default
- Privacy always paramount
- No vendor lock-in
- Open source commitment
- Transparent calculations

---

*This roadmap incorporates professional CFP/CPA assessment feedback to ensure Ashfolio meets the highest standards for financial planning and tax compliance software.*

## Revision History

- **2025-09-16**: v0.7.0 50% complete - Risk metrics and correlation/covariance done
- **2025-09**: Reorganized roadmap to reflect v0.7.0 portfolio analytics focus
- **2025-09**: Added professional assessment features (Tax Docs, RMD, Roth)
- **2025-09**: Prioritized based on CFP/CPA scoring matrix
- **2025-08**: v0.5.0 completed with tax planning
- **2025-07**: v0.4.x delivered advanced analytics
- **2025-06**: Initial roadmap creation