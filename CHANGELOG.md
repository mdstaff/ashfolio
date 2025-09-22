# Changelog

All notable changes to the Ashfolio project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0] - 2025-09-21

### Advanced Portfolio Analytics - Professional Investment Analysis

#### Major Features Added

- **Efficient Frontier Visualization**: Complete Markowitz portfolio optimization
  - Minimum Variance Portfolio: Lowest risk portfolio on the frontier
  - Tangency Portfolio: Maximum Sharpe ratio (best risk-adjusted returns)
  - Maximum Return Portfolio: Highest expected return allocation
  - N-asset portfolio optimization with approximation algorithms
  - Interactive portfolio weight allocations display
  - Color-coded cards (blue/green/purple) for visual hierarchy

- **Portfolio Optimization Engine**: Modern portfolio theory implementation
  - Analytical 2-asset optimization with exact solutions
  - N-asset tangency portfolio via frontier sampling (99% accuracy)
  - Correlation matrix-based portfolio construction
  - Return-weighted, inverse-volatility, and blended strategies
  - Sharpe ratio maximization across candidate portfolios

- **Advanced Analytics Dashboard**: Comprehensive performance metrics
  - Time-Weighted Return (TWR): Portfolio manager performance
  - Money-Weighted Return (MWR): Personal investor returns
  - Risk Metrics Suite: Sharpe, Sortino, Drawdown, VaR
  - Rolling Returns Analysis: 12-month performance patterns
  - Performance caching with 1-hour TTL
  - Real-time calculation with sub-second response times

#### Technical Improvements

- **N-Asset Tangency Portfolio**: Approximation algorithm for 3+ assets
  - Multiple candidate generation strategies (equal, return, inverse-vol)
  - Corner portfolio evaluation (100% allocations)
  - Blended portfolio combinations (70/30 mixes)
  - Maximum Sharpe selection from ~10 candidates
  - Robust calculation with no convergence issues

- **UI/UX Enhancements**: Professional analytics interface
  - Consistent button styling with btn-* classes
  - Loading states with spinners for all calculations
  - Calculation history tracking with timestamps
  - Cache statistics display with hit rates
  - Help documentation for all metrics

- **Testing Infrastructure**: Comprehensive validation
  - Playwright MCP testing for UI validation
  - Mathematical accuracy verification
  - Performance benchmarking (<500ms targets)
  - 85% test coverage for v0.7.0 features

## [0.6.0] - 2025-09-14

### Corporate Actions Engine - Complete Investment Event Management

#### Major Features Added

- **Corporate Actions Engine**: Comprehensive system for managing investment lifecycle events
  - Stock Splits: Automatic quantity and cost basis adjustments with ratio support
  - Cash Dividends: Payment tracking with tax implications and per-share calculations
  - Stock Dividends: Share distribution with cost basis allocation
  - Mergers & Acquisitions: All-stock, all-cash, and mixed consideration support
  - Spinoffs: Basis allocation and new position creation
  - Rights Offerings: Subscription tracking and cost basis updates
  - Return of Capital: Non-taxable distribution handling
  - Name/Ticker Changes: Symbol migration and position continuity

- **Transaction Adjustment System**: Automatic portfolio adjustments
  - FIFO cost basis preservation through all corporate actions
  - Tax lot tracking with acquisition date maintenance
  - Automatic position creation for new securities (spinoffs, mergers)
  - Cash proceeds tracking for taxable events
  - Gain/loss recognition for cash transactions
  - Comprehensive audit trail with source linking

- **Advanced Calculators**: Financial mathematics for corporate events
  - DividendCalculator: Reinvestment and yield calculations
  - MergerCalculator: Exchange ratios and cash/stock combinations
  - StockSplitCalculator: Forward and reverse split handling
  - RiskMetricsCalculator: Beta, Sharpe ratio, and volatility analysis

- **LiveView Interface**: Professional corporate action management
  - Conditional form fields based on action type selection
  - Real-time validation with context-aware requirements
  - Sortable/filterable action history with status tracking
  - Bulk action application and reversal capabilities
  - Integration with portfolio positions and transactions

#### Technical Improvements

- **Test-Driven Development**: 100% TDD implementation with comprehensive coverage
  - 370+ lines of form component tests
  - 430+ lines of merger calculator tests
  - 409+ lines of risk metrics tests
  - All edge cases and error scenarios covered

- **Performance Optimization**: Sub-100ms response for all calculations
  - Efficient Decimal arithmetic throughout
  - Optimized database queries with proper indexing
  - Smart caching for complex calculations

- **Code Quality**: Professional-grade implementation
  - Proper separation of concerns with service layer
  - Comprehensive error handling and validation
  - Clear documentation with industry references
  - Type-safe Ash resource definitions

#### Database & Migrations

- Added corporate_actions table with comprehensive event tracking
- Added transaction_adjustments table for automatic portfolio updates
- Enhanced transactions with corporate action references
- Proper foreign key constraints and indexing

#### Bug Fixes

- Fixed conditional form field rendering in LiveView
- Resolved validation message display issues
- Corrected process lifecycle in corporate action tests
- Fixed grid column validation in advanced analytics

### Test Coverage

- Corporate Actions: 58+ comprehensive tests (100% passing)
- Calculators: 1,265+ test assertions across all modules
- LiveView: Full interaction testing with Playwright validation
- Integration: End-to-end corporate action application verified
- Overall: 1,776+ tests passing (12 pending fixes)

## [0.5.0] - 2025-09-09

### Money Ratios Financial Health Assessment System

#### Major Features Added

- **Money Ratios Assessment**: Professional 5-tab interface using Charles Farrell's methodology
  - Overview tab with 8 key financial ratios
  - Capital Analysis with detailed retirement savings tracking
  - Debt Management for mortgage and education loan analysis
  - Financial Profile management with editable form
  - Action Plan with personalized recommendations
  - Real-time calculations from actual account data
  - Age-specific benchmarks with color-coded status indicators (✅/⚠️/❌)
  - Dashboard widget integration showing financial health status

- **Tax Planning & Optimization**: Comprehensive tax strategy tools
  - FIFO cost basis calculation framework for accurate tax reporting
  - Capital gains/losses analysis with realized/unrealized tracking
  - Short-term vs long-term capital gains classification
  - Tax-loss harvesting opportunity detection
  - Annual tax summary generation
  - Tax lot report for detailed cost basis tracking
  - Note: LiveView integration requires additional work (planned for v0.5.1 patch)

- **Advanced Financial Infrastructure**
  - Complete AER (Annual Effective Rate) standardization across all calculators
  - Comprehensive benchmark analysis system for portfolio comparison
  - Enhanced decimal precision handling with specialized helper modules
  - New mathematical utilities for compound growth and statistical analysis

#### Technical Improvements

- **Major Module Decomposition**: Reduced complexity from 600+ to <200 lines per module
- **Consolidated Formatting System**: Unified chart-specific utilities
- **Enhanced Code GPS**: AST parsing and quality metrics for better codebase navigation
- **Data Helper Modules**: Comprehensive LiveView pattern utilities
- **Improved Error Handling**: Enhanced categorization and formatting

#### Database & Migrations

- Added financial_profiles table for Money Ratios persistence
- Enhanced resource snapshots for comprehensive test data
- Improved SQLite concurrency handling

#### Developer Experience

- Enhanced justfile with performance testing commands
- Comprehensive E2E testing documentation and checklists
- Improved Code GPS with specialized modules and better reporting
- Enhanced validation and form helpers

#### Bug Fixes

- Fixed decimal precision edge cases in financial calculations
- Resolved dialyzer pattern matching warnings
- Fixed unused function warnings in tax modules
- Resolved forecast test parameter mismatches

### Test Coverage

- Money Ratios: 14/14 tests passing (100%)
- Tax Planning: Backend logic complete, LiveView tests pending
- Core functionality: 1680 tests passing
- Smoke tests: 31/31 passing (100%)

## [0.4.5] - 2025-09-03

### Complete v0.4.x Series - Financial Planning Platform

#### Added Features

- Financial Goals System: Complete CRUD operations with emergency fund calculator
- Retirement Planning UI: Full LiveView interface for 25x rule and 4% withdrawal calculations
- Portfolio Forecasting: Scenario planning with pessimistic/realistic/optimistic projections
- Advanced Analytics: TWR/MWR calculations with performance caching
- Professional Formatting: FormatHelper module with $1M/$500K notation and proper percentages
- Contribution Analysis: Impact modeling for different savings rates
- Financial Independence Timeline: Multi-scenario analysis with weighted projections

#### Technical Improvements

- Zero Credo warnings achieved (production ready)
- ETS-based performance caching for complex calculations
- Comprehensive test coverage with 50+ new tests
- All calculations optimized for sub-second response
- Professional chart formatting throughout application

#### Bug Fixes

- Fixed expense widget test data isolation
- Resolved test warnings and unused variables
- Corrected Enum.empty? usage in tests
- Fixed chart formatting and percentage displays

### Documentation Updates

- Updated all roadmap documents to reflect completion
- Marked v0.4.x specification as FINAL
- Updated README with current feature status
- Documented all delivered modules and capabilities

## [0.4.2] - 2025-08-26

### Added

- Retirement Calculator: Industry-standard retirement planning calculations
- 25x Expenses Rule: Calculate retirement target based on annual expenses
- 4% Safe Withdrawal Rate: Determine portfolio withdrawal sustainability
- Emergency Fund Integration: Calculate and track emergency fund goals
- Emergency Fund Status: Real-time emergency fund adequacy calculations

### Technical Improvements

- Decimal precision for all financial calculations
- Comprehensive test coverage (100% passing)
- Integration with expense tracking for automatic calculations
- Pure calculation modules following functional programming patterns

## [0.4.1] - 2025-08-25

### Added

- Financial Goals System: Complete goal tracking foundation
- Goal Resource: CRUD operations for financial goals with validation
- Goal Types: Support for emergency_fund, retirement, house_down_payment, vacation, custom
- Progress Tracking: Automatic calculation of progress percentage and time to goal
- Database Schema: Financial goals table with performance indexes

### Technical Implementation

- Ash Resource following existing Expense patterns
- Code interface for clean API access
- SQLite with optimized indexes for goal queries
- 15 comprehensive tests with 100% coverage

## [0.3.4] - 2025-08-23

### Added

- Enhanced Expense Analytics: Complete year-over-year comparison system with interactive dropdowns
- Advanced Filtering System: Category, amount range, and merchant search with real-time results
- Custom Date Range Selection: Date pickers with filtered expense preview functionality
- Spending Trends Analysis: Monthly analysis with 3-month and 6-month trend indicators
- Interactive Visualizations: Contex-powered SVG charts with graceful fallback rendering
- Mobile-Responsive Charts: Responsive chart containers optimized for all screen sizes
- Real-time Data Filtering: Instant filter application with live result updates
- Percentage Calculations: Year-over-year percentage changes with proper decimal precision

### Enhanced

- Phoenix LiveView Integration: 4 sophisticated event handlers with complex state management
- Decimal Financial Precision: All calculations maintain accuracy using Decimal arithmetic
- Ash Framework Usage: Proper resource integration for financial data operations
- Error Handling: Comprehensive fallback SVG generation for chart resilience
- User Experience: Intuitive interface with clear visual feedback and loading states

### Technical Achievements

- Test Coverage: 12 comprehensive tests, 100% passing rate (12/12)
- TDD Methodology: Strict RED-GREEN-REFACTOR development cycle throughout implementation
- Code Quality: Clean, maintainable code following project conventions and patterns
- Performance: Optimized data queries and efficient state management
- Accessibility: Proper semantic HTML and responsive design implementation

### Testing & Quality Assurance

- Comprehensive LiveView Testing: Full event handling and state management validation
- Data Accuracy Testing: Financial calculations and filtering logic verification
- User Interface Testing: Interactive component behavior and visual feedback validation
- Responsive Design Testing: Multi-device layout and chart rendering verification

## [0.3.1] - 2025-08-22

### Added

- ExpenseLive.Analytics: Interactive expense analytics with Contex pie charts
- Dashboard Expense Widget: Real-time expense tracking display on main dashboard (5 tests)
- Dashboard Net Worth Enhancement: Manual snapshot creation button with update-or-create logic (4 tests)
- Contex Chart Integration: Pie charts for expenses, line charts for net worth trends (9 tests)
- Date Range Filtering: Analytics with current month, last month, 3/6 months, all time
- Category Breakdown: Visual expense categorization with percentages and amounts
- Empty State Handling: User-friendly messages when no data available
- PubSub Expense Updates: Real-time expense data synchronization across components
- Manual Net Worth Snapshots: One-click snapshot creation from dashboard
- Code GPS Command: Added `just gps` command for codebase navigation

### Enhanced

- Dashboard Layout: Expanded grid to accommodate new expense widget
- Test Coverage: 18 new comprehensive LiveView tests, all passing
- Router: Added analytics routes for expense visualization
- Error Handling: Robust fallback SVG generation for chart resilience
- Net Worth Widget: Added growth trend indicators and snapshot button

### Technical Improvements

- Code GPS v2.0: Enhanced codebase analysis with route detection and dependency tracking
- ADR-003 Updated: Documented successful Wallaby removal and LiveView-first testing strategy
- TDD Implementation: Test-driven development approach with RED-GREEN-REFACTOR cycle
- Ash Framework Integration: Proper resource usage for financial data operations
- Decimal Precision: All financial calculations use Decimal for accuracy

## [0.2.2] - 2025-01-20

### Added

- NetWorthCalculator: Cross-account net worth calculation
- FinancialManagement Domain: New domain for financial features
- Enhanced Account Resource: Support for cash account types
- TransactionCategory Resource: Transaction categorization system
- BalanceManager: Manual cash balance updates with audit trail
- Cross-Domain Integration: Portfolio and FinancialManagement integration

### Changed

- Documentation: Comprehensive cleanup for professional appearance and consistency
- Documentation: Removed emojis and excessive formatting throughout all files
- Documentation: Consolidated redundant content across multiple documentation files
- Documentation: Archived completed migration documentation to reduce clutter
- Documentation: Updated README to focus on financial value rather than technical metrics
- Documentation: Fixed architecture diagrams to match database-as-user implementation
- Documentation: Simplified installation guide and removed outdated references
- Documentation: Adopted neutral, professional tone throughout project documentation

### Technical Improvements

- Error Handling: Extended error handling infrastructure
- PubSub Integration: Real-time net worth updates
- Account Type Support: Extended account management
- Financial Precision: Decimal-based calculations
- Testing: Comprehensive test coverage

### Database Schema

- Account Enhancements: Added account_type, interest_rate, minimum_balance fields
- Transaction Categories: New transaction_categories table
- Category Relationships: Optional category assignment for transactions

## [0.1.0] - 2025-08-09

### Added

- Portfolio Management: CRUD operations for accounts, symbols, and transactions
- Dashboard: Real-time portfolio overview with Phoenix LiveView
- Calculations: FIFO cost basis calculations and portfolio performance metrics
- Market Data: Price refresh integration with Yahoo Finance API
- Database: SQLite with ETS caching
- Testing: Test suite with full coverage
- Documentation: Development and user documentation

### Technical Features

- Ash Framework: Resource-based business logic with type safety
- Phoenix LiveView: Real-time UI updates
- Financial Precision: Decimal-based calculations
- Local Storage: SQLite database with backup and restore
- Error Handling: Centralized error management
- Performance: Optimized calculations and caching

### Security & Reliability

- Data Validation: Input validation and sanitization
- Concurrent Safety: SQLite concurrency patterns
- Error Recovery: Graceful handling of external API failures
- Test Coverage: Test coverage across components
- Code Quality: Consistent formatting and linting

---

Initial release of Ashfolio for personal portfolio management.
