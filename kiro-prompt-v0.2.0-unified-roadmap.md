# Kiro AI Agent Prompt: v0.2.0 Unified Roadmap Implementation

## Context Summary

Ashfolio has evolved from a focused portfolio management application to a comprehensive personal financial management system while preserving key portfolio improvements. This prompt provides complete context for updating Kiro specifications to reflect the unified v0.2.0 roadmap.

## Strategic Evolution

**Original Scope**: Portfolio-only investment tracking  
**New Scope**: Comprehensive financial management (investments + cash + expenses + planning)  
**Architectural Approach**: Dual-domain expansion (Portfolio + FinancialManagement domains)  
**Core Principle**: Local-first, privacy-focused SQLite architecture maintained

## User Requirements Context

### Primary User Profile
Individual with comprehensive wealth management needs currently using spreadsheet-based approach:
- Monthly manual updates across 401k, checking, savings, IRA accounts
- Net worth tracking with YoY growth analysis
- Dividend income projections for early retirement planning
- Expense tracking for 25x retirement rule calculations
- Real estate equity and vehicle depreciation tracking
- Long-term forecasting (2017-2056 timeframe)

### Current Workflow to Replace
1. **Monthly Data Collection** (currently 45+ minutes):
   - Log into multiple financial portals
   - Copy/paste balances and positions
   - Update dividend amounts per security
   - Manual net worth calculation

2. **Key Analytics Required**:
   - Current net worth with historical trending
   - YoY change in net worth
   - Annual dividend income projections
   - Progress toward retirement goals (25x expenses)

## v0.2.0 Unified Scope

### Core Financial Management Features
- **Cash Account Management**: Checking, savings, money market, CD accounts
- **Extended Account Architecture**: Investment and cash accounts in unified system
- **Basic Net Worth Calculation**: Real-time calculation across all account types
- **Cash Transaction Management**: Deposits, withdrawals, transfers, bill payments

### Portfolio UX Improvements (Preserved from original roadmap)
- **Symbol Autocomplete**: Intelligent symbol search in transaction forms (.kiro spec exists)
- **Transaction Categories**: Custom tagging and categorization for all transaction types
- **Bulk Export**: Export all financial data to CSV/Excel formats
- **Enhanced Dashboard**: Net worth display with portfolio integration

### Technical Implementation Requirements
- Extend Portfolio.Account resource for cash account types
- Create FinancialManagement domain foundation
- Enhanced SQLite schema for comprehensive financial data
- Maintain 100% backward compatibility with v0.1.0

## Architecture Evolution

### Current State (v0.1.0)
```
Ashfolio.Portfolio
├── User
├── Account (investment only)
├── Symbol
└── Transaction (investment only)
```

### Target State (v0.2.0)
```
Ashfolio.Portfolio (existing - enhanced)
├── User
├── Account (extended for cash account types)
├── Symbol
└── Transaction (extended for cash transactions)

Ashfolio.FinancialManagement (new domain)
├── CashAccount (specialized cash management)
├── NetWorthSnapshot (time-series tracking)
└── [Foundation for future expense/asset resources]
```

### Key Architectural Decisions
- **ADR-002**: Financial Domain Expansion Architecture approved
- **Local-First Commitment**: All data remains in SQLite, no cloud dependencies
- **Single-User Model**: No authentication or multi-tenancy
- **Incremental Approach**: Build dual-domain foundation without disrupting existing features

## Updated Documentation References

### Primary Roadmap Document
- **File**: `/docs/roadmap/v0.2-v0.5-roadmap.md`
- **Status**: Unified roadmap combining comprehensive financial management with portfolio improvements
- **Timeline**: Q3 2025 - Q2 2026 (4 release phases)

### Architecture Documentation
- **ADR-002**: `/docs/architecture/adr-002-financial-domain-expansion.md`
- **Architecture Overview**: `/docs/development/architecture.md` (updated for dual-domain)

### User Experience Documentation
- **Migration Guide**: `/docs/user-guides/spreadsheet-migration-guide.md`
- **Monthly Workflow**: `/docs/user-guides/monthly-workflow-guide.md`
- **User Guides Framework**: `/docs/user-guides/README.md`

### Project Overview
- **README.md**: Updated with comprehensive scope and accurate feature status
- **Current vs Coming Soon**: Clear separation of implemented vs planned features

## Existing Kiro Specs to Integrate

### Portfolio Improvements (Preserve and integrate)
- **Symbol Autocomplete**: .kiro spec exists - integrate with cash account transaction forms
- **Real-Time Price Lookup**: .kiro spec exists - defer to v0.3.0 per unified roadmap

## Specific Kiro Tasks Required

### 1. Requirements Specification Updates
- **Expand scope** from portfolio-only to comprehensive financial management
- **Integrate cash account requirements** with existing investment account patterns
- **Define net worth calculation requirements** including real-time updates
- **Specify backward compatibility requirements** for v0.1.0 users
- **Include symbol autocomplete requirements** for both investment and cash transactions

### 2. Design Document Revisions
- **Dual-domain architecture design** showing Portfolio and FinancialManagement separation
- **Account resource extension** for unified investment/cash account management
- **Dashboard redesign** integrating net worth with existing portfolio displays
- **Database schema evolution** maintaining existing tables while adding cash capabilities
- **User workflow design** for 30-minute monthly financial updates

### 3. Implementation Task Planning
- **Phase approach** ensuring existing portfolio functionality remains intact
- **Database migration strategy** for extending Account resource
- **Testing strategy** covering both new cash features and existing investment features
- **Performance considerations** for expanded data model and calculations
- **Documentation updates** required for expanded feature set

## Success Criteria

### Technical Requirements
- [ ] All existing v0.1.0 investment portfolio functionality preserved
- [ ] Cash accounts integrate seamlessly with investment accounts
- [ ] Net worth calculation performs in <1 second for comprehensive datasets
- [ ] Symbol autocomplete works for both investment and cash transaction forms
- [ ] Database migrations are reversible and safe

### User Experience Requirements
- [ ] Monthly financial updates complete in <30 minutes (vs. current spreadsheet workflow)
- [ ] Net worth calculation matches user's current spreadsheet accuracy
- [ ] Dashboard provides comprehensive financial overview at a glance
- [ ] Transaction entry is faster and more accurate than manual methods
- [ ] Export capabilities support both investment and cash account data

### Architectural Requirements
- [ ] Local-first principles maintained (no cloud dependencies except price data)
- [ ] SQLite performance maintained with expanded data model
- [ ] Clean domain separation between Portfolio and FinancialManagement
- [ ] Foundation established for v0.3.0 expense and asset tracking features
- [ ] Test coverage above 90% for all financial calculation logic

## Development Constraints

### Timeline Constraints
- **Target Release**: Q3 2025 (approximately 4-6 weeks from specification)
- **Parallel Development**: Integrate existing symbol autocomplete work
- **Risk Management**: Maintain existing functionality while expanding scope

### Technical Constraints
- **SQLite Only**: No external databases or cloud services
- **Phoenix LiveView**: UI framework constraint for real-time updates
- **Ash Framework**: Business logic and domain modeling framework
- **Existing Codebase**: Must integrate with current architecture patterns

### User Experience Constraints
- **No Learning Curve**: New features should be intuitive for existing users
- **Optional Adoption**: Cash account features should be optional for investment-only users
- **Performance**: No degradation of existing portfolio management performance

## Prompt for Kiro AI Agent

**Primary Task**: Update all Kiro specifications (.kiro files) to reflect the unified v0.2.0 roadmap combining comprehensive financial management (cash accounts, net worth calculation) with key portfolio improvements (symbol autocomplete, transaction categories).

**Key Requirements**:
1. **Preserve existing investment functionality** while expanding to cash management
2. **Integrate symbol autocomplete** across both investment and cash transaction forms
3. **Design dual-domain architecture** foundation for future expansion
4. **Ensure 30-minute monthly workflow** for comprehensive financial updates
5. **Maintain local-first, SQLite-based architecture** principles

**Reference Documents**:
- Primary Roadmap: `/docs/roadmap/v0.2-v0.5-roadmap.md`
- Architecture Decision: `/docs/architecture/adr-002-financial-domain-expansion.md`
- User Migration Path: `/docs/user-guides/spreadsheet-migration-guide.md`
- Updated Project Overview: `/README.md`

**Success Measurement**: Specifications enable development team to deliver v0.2.0 that replaces spreadsheet-based financial management workflow while preserving and enhancing existing portfolio management capabilities.

---

*This prompt synthesizes the complete strategic evolution from focused portfolio management to comprehensive personal financial management, providing all necessary context for accurate Kiro specification updates.*