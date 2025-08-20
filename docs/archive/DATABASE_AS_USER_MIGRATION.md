# Database-as-User Migration Plan

## Overview

Transform Ashfolio from user-centric to database-centric architecture where each SQLite database file represents a single user's complete portfolio.

## Benefits

- Each database file = one user's data
- Copy .db file = backup/share portfolio
- Complete data isolation by default
- No user_id foreign keys needed
- Perfect alignment with local-first principles

## Current State Analysis

### Tables with user_id references:

- `accounts` table: `user_id` column (FK to users)
- No direct user_id in transactions (uses account.user_id)

### Resources with user_id dependencies:

1.  belongs_to :user, user_id FK
2.  queries via account.user_id
3.  All take user_id parameters
4.  All functions take user_id parameters

## Migration Strategy

### Phase 1: Create UserSettings Resource

Replace User table with singleton UserSettings for preferences:

```elixir
defmodule Ashfolio.Portfolio.UserSettings do
  # Singleton table with user preferences
  # Always exactly one row
  attributes do
    uuid_primary_key(:id)
    attribute :name, :string, default: "Local User"
    attribute :currency, :string, default: "USD"
    attribute :locale, :string, default: "en-US"
    timestamps()
  end

  # Singleton enforcement
  def get_settings() # Always returns single row
  def update_settings(attrs) # Updates the single row
end
```

### Phase 2: Database Migration

```sql
-- Create new user_settings table
CREATE TABLE user_settings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT 'Local User',
  currency TEXT NOT NULL DEFAULT 'USD',
  locale TEXT NOT NULL DEFAULT 'en-US',
  inserted_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);

-- Migrate existing user data to settings
INSERT INTO user_settings (id, name, currency, locale, inserted_at, updated_at)
SELECT id, name, currency, locale, inserted_at, updated_at
FROM users LIMIT 1;

-- Remove user_id from accounts
ALTER TABLE accounts DROP COLUMN user_id;

-- Drop users table
DROP TABLE users;
```

### Phase 3: Update Account Resource

```elixir
defmodule Ashfolio.Portfolio.Account do
  # Remove user relationship completely
  # relationships do
  #   belongs_to :user, Ashfolio.Portfolio.User # REMOVE
  # end

  # Remove user_id from create action
  create :create do
    accept([:name, :platform, :currency, :is_excluded, :balance, :account_type])
    # Remove :user_id
  end

  # Remove user filtering actions
  # read :by_user # REMOVE

  # New simplified actions
  read :all do
    description("Returns all accounts in this database")
  end

  read :active do
    description("Returns only active accounts")
    filter(expr(is_excluded == false))
  end
end
```

### Phase 4: Update Transaction Resource

```elixir
defmodule Ashfolio.Portfolio.Transaction do
  # Remove all user_id filtering since account.user_id doesn't exist

  # Simplify all read actions
  read :by_category do
    argument(:category_id, :uuid)
    filter(expr(category_id == ^arg(:category_id)))
    # Remove user_id filtering
  end

  read :by_date_range do
    argument(:start_date, :date)
    argument(:end_date, :date)
    filter(expr(date >= ^arg(:start_date) and date <= ^arg(:end_date)))
    # Remove user_id filtering
  end
end
```

### Phase 5: Update Calculator Modules

```elixir
defmodule Ashfolio.Portfolio.Calculator do
  # Remove user_id parameters from all functions

  # Before:
  # def calculate_portfolio_value()
  # After:
  def calculate_portfolio_value() do
    case get_all_holdings() do
      # No user filtering needed
    end
  end

  # Before:
  # defp get_all_holdings()
  # After:
  defp get_all_holdings() do
    case Account.all() do # No user filtering
      # All accounts in this database belong to "the user"
    end
  end
end
```

### Phase 6: Update Context API

```elixir
defmodule Ashfolio.Context do
  # Remove user_id parameters from all functions

  # Before:
  # def get_user_dashboard_data()
  # After:
  def get_dashboard_data() do
    # No user_id needed - all data in DB belongs to "the user"
  end

  # Before:
  # def get_net_worth()
  # After:
  def get_net_worth() do
    # Calculate across all accounts in this database
  end
end
```

### Phase 7: Update LiveView Modules

```elixir
defmodule AshfolioWeb.DashboardLive do
  # Remove all get_default_user_id() calls
  # Remove user_id assigns

  # Before:
  # user_id = get_default_user_id()
  # Context.get_user_dashboard_data()

  # After:
  # Context.get_dashboard_data()
end
```

### Phase 8: Update FormComponents

```elixir
defmodule AshfolioWeb.AccountLive.FormComponent do
  # Remove user_id handling completely
  # Account creation automatically belongs to this database

  def update(assigns, socket) do
    form = AshPhoenix.Form.for_create(Account, :create)
    # No user_id needed!
  end
end
```

## Implementation Files to Modify

### 1. Database Migration

- Create: `priv/repo/migrations/YYYYMMDD_database_as_user_migration.exs`

### 2. New Resource

- Create: `lib/ashfolio/portfolio/user_settings.ex`

### 3. Update Resources

- Modify: `lib/ashfolio/portfolio/account.ex`
- Modify: `lib/ashfolio/portfolio/transaction.ex`
- Remove: `lib/ashfolio/portfolio/user.ex`

### 4. Update Calculators

- Modify: `lib/ashfolio/portfolio/calculator.ex`
- Modify: `lib/ashfolio/portfolio/holdings_calculator.ex`
- Modify: `lib/ashfolio/portfolio/calculator_optimized.ex`

### 5. Update Context API

- Modify: `lib/ashfolio/context.ex`

### 6. Update LiveViews

- Modify: `lib/ashfolio_web/live/dashboard_live.ex`
- Modify: `lib/ashfolio_web/live/account_live/index.ex`
- Modify: `lib/ashfolio_web/live/account_live/form_component.ex`
- And all other LiveViews that reference user_id

### 7. Update Tests

- Update all test files to remove user_id references

## Rollback Strategy

If issues arise:

1. Keep backup of current database structure
2. Migration can be reversed by re-adding user_id columns
3. Re-create User resource
4. Migrate UserSettings back to User table

## Benefits After Migration

1.  No user_id parameters anywhere
2.  Database file = user's portfolio
3.  Copy .db file
4.  User can have multiple .db files
5.  Remove ~50+ user_id references

## Risks & Considerations

1.  Major API changes throughout
2.  Need comprehensive test updates
3.  Multi-phase database changes
4.  Existing databases need migration

## Next Steps

1. Create UserSettings resource
2. Write migration script
3. Update Account resource first (smallest change)
4. Gradually update other modules
5. Update all tests
6. Comprehensive testing

This migration will result in a much cleaner, simpler architecture that truly embodies the "database as user" concept!
