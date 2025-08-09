# Changelog

All notable changes to the Ashfolio project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

*This is the initial production-ready release of Ashfolio, providing a solid foundation for personal portfolio management.*