# Testing Overview

Ashfolio testing overview and quick commands.

## Quick Start

```bash
# Run all tests (excludes slow seeding tests)
just test

# Run tests with specific focus areas
just test-fast          # Development feedback loop (< 100ms tests)
just test-ash           # Ash Resource business logic
just test-liveview      # Phoenix LiveView components
just test-calculations  # Portfolio calculations
just test-integration   # End-to-end workflows
```

## Testing Architecture

### Global Test Data Management 🆕

- [Global Test Data Requirements](./global-test-data-requirements.md) - Why global test data exists and how to manage it
- [Test Data Implementation Patterns](./test-data-implementation-patterns.md) - Concrete patterns for reliable test data management

### Core Testing Documentation

### Testing Framework

Tests organized by system layers with performance categorization and SQLite concurrency handling.

### Core Testing Categories

| Category      | Purpose                        | Command                  |
| ------------- | ------------------------------ | ------------------------ |
| Fast Tests    | Development feedback loop      | `just test-fast`         |
| Ash Resources | Business logic validation      | `just test-ash`          |
| LiveView      | UI components and interactions | `just test-liveview`     |
| Calculations  | Portfolio math and FIFO logic  | `just test-calculations` |
| Integration   | End-to-end system workflows    | `just test-integration`  |

## Documentation Structure

### Core Testing Documents

- [Framework Guide](framework.md) - Complete testing framework architecture and patterns
- [SQLite Patterns](patterns.md) - SQLite concurrency handling and database testing patterns
- [Standards](standards.md) - Testing consistency standards and best practices
- Global test data management and requirements
- [AI Testing](ai-testing.md) - AI-assisted testing patterns and guidelines

For detailed testing patterns and strategies, see [Testing Strategy](../TESTING_STRATEGY.md).

#### ⚠️ Critical for v0.3.0+

Global test data management is essential for reliable testing. See [Global Test Data Requirements](global-test-data-requirements.md) for:

- Why global test data exists in Ashfolio
- SQLite concurrency handling requirements
- Standards for test isolation and data management

## Test Database Management

### Health Checks & Safeguards

```bash
# NEW: Comprehensive test database safeguards
just test-health-check              # Validate test database health
just test-safe                      # Run tests with automatic health checks
just test-db-emergency-reset        # Emergency recovery for mass failures
```

### Database Reset Procedures

```bash
# Complete test database reset (most common fix)
MIX_ENV=test mix ecto.drop && MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate
MIX_ENV=test mix run -e "Ashfolio.SQLiteHelpers.setup_global_test_data!()"
just test-fast  # Verify fix
```

## Testing Statistics

- 300+ comprehensive tests
- 100% (maintained through database safeguards)
- All architectural layers with comprehensive edge cases
- Fast development feedback with sub-100ms test categories

## Getting Help

- Check [SQLite Patterns](patterns.md) for database-related test failures
- Review [Testing Standards](standards.md) for consistency guidelines
- See [AI Testing Guide](ai-testing.md) for AI-assisted development patterns

---

_Quick reference: `just test-health-check` for any test issues_
