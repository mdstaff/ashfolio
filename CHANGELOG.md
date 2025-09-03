# Changelog

All notable changes to the Ashfolio project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.5] - 2025-09-03

### Complete v0.4.x Series - Financial Planning Platform

#### Added Features
- **Financial Goals System**: Complete CRUD operations with emergency fund calculator
- **Retirement Planning UI**: Full LiveView interface for 25x rule and 4% withdrawal calculations
- **Portfolio Forecasting**: Scenario planning with pessimistic/realistic/optimistic projections
- **Advanced Analytics**: TWR/MWR calculations with performance caching
- **Professional Formatting**: FormatHelper module with $1M/$500K notation and proper percentages
- **Contribution Analysis**: Impact modeling for different savings rates
- **Financial Independence Timeline**: Multi-scenario analysis with weighted projections

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

## [Unreleased] - v0.2.0 Development

## [0.2.2] - 2025-01-20

### Changed

- Documentation: Comprehensive cleanup for professional appearance and consistency
- Documentation: Removed emojis and excessive formatting throughout all files
- Documentation: Consolidated redundant content across multiple documentation files
- Documentation: Archived completed migration documentation to reduce clutter
- Documentation: Updated README to focus on financial value rather than technical metrics
- Documentation: Fixed architecture diagrams to match database-as-user implementation
- Documentation: Simplified installation guide and removed outdated references
- Documentation: Adopted neutral, professional tone throughout project documentation

## [Unreleased] - v0.2.0 Development (Previous)

### Added

- NetWorthCalculator: Cross-account net worth calculation
- FinancialManagement Domain: New domain for financial features
- Enhanced Account Resource: Support for cash account types
- TransactionCategory Resource: Transaction categorization system
- BalanceManager: Manual cash balance updates with audit trail
- Cross-Domain Integration: Portfolio and FinancialManagement integration

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
