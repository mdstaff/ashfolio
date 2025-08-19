# Changelog

All notable changes to the Ashfolio project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
