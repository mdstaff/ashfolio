# Database Management Guide

This guide covers database management operations for the Ashfolio application, including migrations, seeding, backups, and data replication strategies.

## Quick Reference

### Just Commands

```bash
# Database operations
just migrate          # Run pending migrations
just reset            # Reset database with Ecto (drops and recreates)
just reseed           # Truncate tables and re-seed with fresh sample data
just db-status        # Show table counts and database status

# Backup operations
just backup           # Create timestamped database backup
just backups          # List available backup files
just restore <file>   # Restore from backup file
```

## Database Migrations

### Current Migration Status

The application uses a database-as-user architecture with a single comprehensive migration:

1. **20250818052238_create_database_as_user_schema.exs** - Complete schema with all tables and relationships

### Running Migrations

```bash
# Run all pending migrations
just migrate

# Check migration status
mix ecto.migrations

# Generate new migration (if needed)
mix ecto.gen.migration migration_name
```

### Database Architecture

The database-as-user architecture eliminates traditional user tables in favor of user settings:

**Core Tables:**

- `user_settings` - Single-user configuration (currency, locale, preferences)
- `accounts` - Investment accounts with balances and metadata
- `symbols` - Financial instruments (stocks, ETFs, crypto)
- `transactions` - Transaction history with account/symbol relationships
- `transaction_categories` - Categorization system for transactions

**Key Relationships:**

- Transactions → Accounts (required foreign key)
- Transactions → Symbols (required foreign key)
- Transactions → Transaction Categories (optional foreign key)
- Transaction Categories → Parent Categories (hierarchical structure)

## Database Seeding

### Sample Data

The application includes comprehensive sample data for development:

**Default User Settings:**

- Name: "Local User"
- Currency: "USD"
- Locale: "en-US"

**Sample Accounts:**

- Schwab Brokerage ($50,000 balance)
- Fidelity 401k ($25,000 balance)
- Crypto Wallet ($5,000 balance)

**Sample Symbols:**

- AAPL (Apple Inc.) - Stock
- MSFT (Microsoft Corporation) - Stock
- GOOGL (Alphabet Inc.) - Stock
- SPY (SPDR S&P 500 ETF) - ETF
- VTI (Vanguard Total Stock Market ETF) - ETF
- BTC-USD (Bitcoin) - Crypto

**Sample Transactions:**

- 7 transactions across different accounts and symbols
- Mix of buy, sell, dividend, and fee transactions
- Realistic dates and amounts

### Seeding Commands

```bash
# Full database reset with Ecto (recommended for clean start)
just reset

# Truncate and re-seed only (preserves schema)
just reseed

# Check seeded data
just db-status
```

## Backup and Restore

### Creating Backups

```bash
# Create timestamped backup
just backup

# Example output:
# data/backups/ashfolio_backup_20250730T055228.795801Z.db
```

### Listing Backups

```bash
# List all available backups
just backups
```

### Restoring from Backup

```bash
# Restore from specific backup file
just restore data/backups/ashfolio_backup_20250730T055228.795801Z.db
```

**⚠️ Warning:** Restore operations will overwrite the current database!

### Backup Storage

- Backups are stored in `data/backups/`
- Filenames include ISO 8601 timestamps for easy identification
- Backups are complete SQLite database copies
- No automatic cleanup - manage backup retention manually

## Local Development Workflows

### Daily Development

```bash
# Start with fresh data
just reseed

# Run tests to ensure stability
just test

# Make changes to code/schema
# ... development work ...

# Run tests after changes
just test

# Create backup before major changes
just backup

# Check data status
just db-status
```

### Schema Changes

```bash
# Generate new migration
mix ecto.gen.migration add_new_feature

# Edit migration file
# ... add migration code ...

# Run migration
just migrate

# Update sample data if needed
# Edit lib/ashfolio/database_manager.ex
just reseed
```

### Testing Data Scenarios

```bash
# Create backup of current state
just backup

# Run tests to ensure current state is stable
just test

# Modify data for testing
# ... manual data changes ...

# Run specific tests
just test-file test/ashfolio/seeding_test.exs

# Restore to known state
just restore data/backups/backup_file.db

# Verify restoration with tests
just test
```

## Data Replication (Future)

### Current Status

The application currently supports single-user local development only. Data replication features are planned for future implementation:

```elixir
# Placeholder functions in DatabaseManager
Ashfolio.DatabaseManager.replicate_prod_to_staging()  # Not implemented
Ashfolio.DatabaseManager.replicate_staging_to_dev()   # Not implemented
```

### Planned Replication Strategy

When production and staging environments are available:

1. **Production → Staging**

   - Automated daily replication
   - Sanitized data (remove PII)
   - Schema and data sync

2. **Staging → Development**

   - On-demand replication
   - Subset of data for performance
   - Developer-initiated sync

3. **Implementation Approach**
   - SQLite database file copying
   - Data transformation scripts
   - Backup verification
   - Rollback capabilities

### Future Commands (Planned)

```bash
# When implemented
just sync-from-staging    # Pull staging data to dev
just sync-from-prod       # Pull production data to staging
just sanitize-data        # Remove PII from copied data
```

## Database Schema

### Current Tables

```sql
-- User settings (single user configuration)
user_settings (id, name, currency, locale, timestamps)

-- Investment accounts
accounts (id, name, platform, currency, account_type, is_excluded, balance, 
          balance_updated_at, interest_rate, minimum_balance, timestamps)

-- Financial symbols
symbols (id, symbol, name, asset_class, currency, isin, sectors, countries,
         data_source, current_price, price_updated_at, timestamps)

-- Transaction categories
transaction_categories (id, name, color, is_system, parent_category_id, timestamps)

-- Transactions
transactions (id, account_id, symbol_id, category_id, type, quantity, price, 
              total_amount, fee, date, notes, timestamps)
```

### Relationships

- Accounts → Transactions (1:many)
- Symbols → Transactions (1:many)
- Transaction Categories → Transactions (1:many, optional)
- Transaction Categories → Parent Categories (self-referencing hierarchy)

## Testing and Validation

### Test Suite Status

The project maintains a **100% passing test suite** (383/383 tests) to ensure stability during development.

### Enhanced Test Commands

```bash
# Basic test commands
just test              # Run full test suite
just test-file <path>  # Run specific test file

# Advanced test commands
just test-coverage     # Run tests with coverage report
just test-watch        # Run tests in watch mode (re-runs on changes)
just test-failed       # Run only failed tests from last run
just test-verbose      # Run tests with detailed output
```

### Test-Driven Development Workflow

```bash
# Before making changes
just test              # Ensure starting from stable state

# During development
just test-watch        # Continuous testing during development

# After changes
just test              # Verify all tests still pass
just test-coverage     # Check test coverage

# For debugging failures
just test-failed       # Focus on failed tests
just test-verbose      # Get detailed output for debugging
```

## Troubleshooting

### Common Issues

**Migration Errors:**

```bash
# Check migration status
mix ecto.migrations

# Reset if needed
just reset
```

**Seeding Failures:**

```bash
# Check for constraint violations
just db-status

# Reset and try again
just reset
```

**Backup/Restore Issues:**

```bash
# Verify file exists
ls -la data/backups/

# Check file permissions
chmod 644 data/backups/*.db
```

### Development Environment Reset

If you encounter persistent issues:

```bash
# Nuclear option - complete reset
rm -rf data/ashfolio.db*
rm -rf data/backups/*
just reset
```

## Performance Considerations

### Query Optimization

- All common query patterns have dedicated indexes
- Use `EXPLAIN QUERY PLAN` for complex queries
- Monitor query performance in development

### Storage Management

- SQLite database grows with transaction history
- Regular backup cleanup recommended
- Consider archiving old transactions in production

### Memory Usage

- ETS cache separate from database storage
- Database file size typically < 100MB for normal usage
- Backup storage scales with retention policy

## Security Notes

### Local Development

- Database files stored in `data/` directory
- No encryption at rest (local development only)
- Backup files contain full data - secure storage recommended

### Future Production Considerations

- Database encryption for sensitive financial data
- Backup encryption and secure storage
- Access logging and audit trails
- Data retention and privacy compliance
