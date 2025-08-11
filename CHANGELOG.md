# Changelog

All notable changes to the Ashfolio project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - v0.2.0 Development

### Added - Comprehensive Financial Management Foundation

- **NetWorthCalculator**: Cross-account net worth calculation combining investment and cash values
- **FinancialManagement Domain**: New domain for comprehensive financial features
- **Enhanced Account Resource**: Support for cash account types (checking, savings, money market, CD)
- **TransactionCategory Resource**: Investment transaction categorization system
- **BalanceManager**: Manual cash balance updates with audit trail
- **Cross-Domain Integration**: Seamless integration between Portfolio and FinancialManagement domains

### Technical Improvements

- **PubSub Integration**: Real-time net worth updates across the application
- **Account Type Support**: Extended account management for investment and cash accounts
- **Financial Precision**: Decimal-based calculations for accurate monetary operations
- **Comprehensive Testing**: 16+ unit tests and integration tests for new features

### Database Schema

- **Account Enhancements**: Added account_type, interest_rate, minimum_balance fields
- **Transaction Categories**: New transaction_categories table with user relationships
- **Category Relationships**: Optional category assignment for investment transactions

## [0.1.0] - 2025-08-09

### Added

- **Portfolio Management**: Complete CRUD operations for accounts, symbols, and transactions
- **Dashboard**: Real-time portfolio overview with Phoenix LiveView
- **Calculations**: FIFO cost basis calculations and portfolio performance metrics
- **Market Data**: Manual price refresh integration with Yahoo Finance API
- **Database**: SQLite with ETS caching for local-first architecture
- **Testing**: Comprehensive test suite with 383+ passing tests
- **Documentation**: Complete development and user documentation

### Technical Features

- **Ash Framework**: Resource-based business logic with type safety
- **Phoenix LiveView**: Real-time UI updates without JavaScript
- **Financial Precision**: Decimal-based calculations for accuracy
- **Local Storage**: SQLite database with backup and restore capabilities
- **Error Handling**: Centralized error management and user feedback
- **Performance**: Optimized calculations and caching strategies

### Security & Reliability

- **Data Validation**: Comprehensive input validation and sanitization
- **Concurrent Safety**: SQLite concurrency patterns and helpers
- **Error Recovery**: Graceful handling of external API failures
- **Test Coverage**: Extensive test coverage across all components
- **Code Quality**: Consistent formatting, linting, and architectural patterns

---

_This is the initial production-ready release of Ashfolio, providing a solid foundation for personal portfolio management._
