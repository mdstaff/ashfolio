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

### Testing Framework

Tests organized by system layers with performance categorization and SQLite concurrency handling.

### Core Testing Categories

| Category | Purpose | Command |
|----------|---------|---------|
| **Fast Tests** | Development feedback loop | `just test-fast` |
| **Ash Resources** | Business logic validation | `just test-ash` |
| **LiveView** | UI components and interactions | `just test-liveview` |
| **Calculations** | Portfolio math and FIFO logic | `just test-calculations` |
| **Integration** | End-to-end system workflows | `just test-integration` |

## Documentation Structure

### Core Testing Documents

- **[Framework Guide](framework.md)** - Complete testing framework architecture and patterns
- **[SQLite Patterns](patterns.md)** - SQLite concurrency handling and database testing patterns  
- **[Standards](standards.md)** - Testing consistency standards and best practices
- **[AI Testing](ai-testing.md)** - AI-assisted testing patterns and guidelines

For detailed testing patterns and strategies, see [Testing Strategy](../TESTING_STRATEGY.md).

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

- **Current Test Count**: 300+ comprehensive tests
- **Pass Rate**: 100% (maintained through database safeguards)
- **Coverage Areas**: All architectural layers with comprehensive edge cases
- **Performance**: Fast development feedback with sub-100ms test categories

## Getting Help

- **Common Issues**: Check [SQLite Patterns](patterns.md) for database-related test failures
- **Standards**: Review [Testing Standards](standards.md) for consistency guidelines
- **AI Development**: See [AI Testing Guide](ai-testing.md) for AI-assisted development patterns

---

*Quick reference: `just test-health-check` for any test issues*