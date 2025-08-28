# Comprehensive Financial Management v0.2.0 Design

## Overview

This design document outlines the technical architecture for Ashfolio v0.2.0, which extends the existing portfolio-only investment tracking system to comprehensive personal financial management. The design maintains 100% backward compatibility with existing v0.1.0 functionality while adding cash account management, net worth calculation, symbol autocomplete, and transaction categorization.

Portfolio-only investment tracking → Comprehensive financial management (investments + cash + net worth)

Extend existing Portfolio domain with new capabilities while introducing a focused FinancialManagement domain for cross-account features.

## Architecture

### Domain Structure

The system will use a dual-domain approach to maintain clear separation of concerns:

```
Ashfolio.Portfolio (Existing - Enhanced)
├── User (unchanged)
├── Account (enhanced for cash accounts)
├── Symbol (enhanced with autocomplete)
├── Transaction (enhanced with categories)
└── Calculator (unchanged)

Ashfolio.FinancialManagement (New Domain)
├── NetWorthCalculator
├── SymbolSearch
└── TransactionCategory
```

### Database Schema Extensions

#### Enhanced Account Resource

The existing `Account` resource will be extended to support cash account types:

```elixir
# New attributes added to existing Account resource
attribute :account_type, :atom do
  constraints(one_of: [:investment, :checking, :savings, :money_market, :cd])
  default(:investment)
  allow_nil?(false)
end

# Do not store bank routing numbers until further notice

attribute :interest_rate, :decimal do
  description("Annual interest rate for savings/CD accounts")
end

attribute :minimum_balance, :decimal do
  description("Minimum balance requirement")
end
```

#### Enhanced Transaction Resource

The existing `Transaction` resource will be extended to support investment categories:

```elixir
# Transaction types remain focused on investment transactions
attribute :type, :atom do
  constraints(one_of: [:buy, :sell, :dividend, :fee, :interest, :liability])
end

# New optional category relationship for investment organization
belongs_to :category, Ashfolio.FinancialManagement.TransactionCategory do
  allow_nil?(true)
end
```

#### New TransactionCategory Resource

```elixir
defmodule Ashfolio.FinancialManagement.TransactionCategory do
  attributes do
    uuid_primary_key(:id)
    attribute :name, :string, allow_nil?: false
    attribute :color, :string, default: "#3B82F6"
    attribute :is_system, :boolean, default: false
    attribute :parent_category_id, :uuid
    timestamps()
  end

  relationships do
    belongs_to :user, Ashfolio.Portfolio.User
    belongs_to :parent_category, __MODULE__
    has_many :child_categories, __MODULE__, destination_attribute: :parent_category_id
    has_many :transactions, Ashfolio.Portfolio.Transaction
  end
end
```

### Component Integration Patterns

#### LiveView Component Architecture

```
DashboardLive (Enhanced)
├── Portfolio Summary (existing)
├── Net Worth Summary (new)
├── Holdings Table (existing)
└── Recent Activity (enhanced with categories)

AccountLive (Enhanced)
├── Investment Accounts (existing)
├── Cash Accounts (new with manual balance management)
└── Account Form (enhanced for account types)

TransactionLive (Enhanced)
├── Transaction Form (enhanced with categories & autocomplete)
└── Transaction List (enhanced with filtering)
```

#### Symbol Autocomplete Integration

The symbol autocomplete will be implemented as a reusable LiveView component:

```elixir
defmodule AshfolioWeb.Components.SymbolAutocomplete do
  # Integrates with existing Symbol resource
  # Provides real-time search with local + external API
  # Automatically creates new Symbol resources when needed
end
```

## Components and Interfaces

### 1. Cash Account Management

#### Account Resource Extensions

Enhanced Actions:

- `create_cash_account` - Creates cash accounts with type-specific validation
- `list_by_type` - Filters accounts by investment vs cash types
- `calculate_cash_balance` - Real-time balance calculation from transactions

Validation Rules:

- Cash accounts require `account_type` in [:checking, :savings, :money_market, :cd]
- Investment accounts maintain existing validation (default :investment type)
- Interest rates must be non-negative decimals

#### LiveView Integration

Enhanced AccountLive.Index:

```elixir
# Tabbed interface: "Investment Accounts" | "Cash Accounts"
# Unified account listing with type indicators
# Account-specific metadata display (interest rate)
```

Enhanced AccountLive.FormComponent:

```elixir
# Dynamic form fields based on account_type selection
# Conditional validation for cash-specific fields
# Type-specific help text and examples
```

### 2. Simple Cash Balance Management

#### Manual Balance Adjustments

Balance Update System:

```elixir
defmodule Ashfolio.FinancialManagement.BalanceManager do
  def update_cash_balance(account_id, new_balance, notes \\ nil) do
    # Update Account.balance directly
    # Record balance change with timestamp and optional notes
    # Broadcast balance change via PubSub for net worth updates
  end
end
```

Balance History Tracking:

- Simple audit log of balance changes
- Timestamp and optional notes for each adjustment
- No complex transaction reconciliation required

### 3. Net Worth Calculation

#### NetWorthCalculator Module

```elixir
defmodule Ashfolio.FinancialManagement.NetWorthCalculator do
  def calculate_net_worth() do
    with {:ok, investment_value} <- Portfolio.Calculator.calculate_portfolio_value(),
         {:ok, cash_balances} <- calculate_total_cash_balances() do

      net_worth = Decimal.add(investment_value, cash_balances)

      {:ok, %{
        net_worth: net_worth,
        investment_value: investment_value,
        cash_value: cash_balances,
        breakdown: calculate_account_breakdown()
      }}
    end
  end
end
```

#### Real-time Updates

PubSub Integration:

- Account balance changes trigger net worth recalculation
- Investment value changes trigger net worth recalculation
- Dashboard subscribes to "net_worth" topic for real-time updates

#### Dashboard Integration

Enhanced DashboardLive:

```elixir
# New net worth summary card
# Investment vs Cash breakdown visualization
# Real-time updates via PubSub subscription
```

### 4. Symbol Autocomplete

#### SymbolSearch Module

```elixir
defmodule Ashfolio.FinancialManagement.SymbolSearch do
  def search_symbols(query, opts \\ []) do
    # 1. Search local Symbol resources first
    # 2. If insufficient results, query Yahoo Finance API
    # 3. Cache external results for future searches
    # 4. Return unified results with metadata
  end

  def create_symbol_from_external(symbol_data) do
    # Create new Symbol resource from external API data
    # Populate name, sector, current_price from API
  end
end
```

#### LiveView Component

```elixir
defmodule AshfolioWeb.Components.SymbolAutocomplete do
  # Real-time search with 200ms debounce
  # Dropdown with symbol, name, and current price
  # Keyboard navigation support
  # Integration with existing transaction forms
end
```

#### Performance Optimization

Caching Strategy:

- Local symbol search results cached in ETS
- External API results cached for 1 hour
- Search queries debounced to prevent API spam
- Progressive loading: local first, then external

### 5. Transaction Categories

#### TransactionCategory Resource

System Categories (Pre-seeded):

- Growth (green)
- Income (blue)
- Speculative (orange)
- Index (purple)

Custom Categories:

- User-created categories with custom colors
- Optional parent-child relationships
- Soft delete to preserve transaction history

#### Category Integration

Enhanced Transaction Forms:

```elixir
# Optional category dropdown in transaction forms
# Color-coded category display
# Quick category creation from transaction form
```

Enhanced Transaction Lists:

```elixir
# Category filter dropdown
# Color-coded category tags
# Category-based transaction grouping
```

## Data Models

### Enhanced Account Model

```elixir
defmodule Ashfolio.Portfolio.Account do
  # Existing attributes maintained
  # New attributes added:

  attribute :account_type, :atom do
    constraints(one_of: [:investment, :checking, :savings, :money_market, :cd])
    default(:investment)
  end

  attribute :interest_rate, :decimal
  attribute :minimum_balance, :decimal

  # New actions:
  read :by_type do
    argument(:account_type, :atom, allow_nil?: false)
    filter(expr(account_type == ^arg(:account_type)))
  end

  read :cash_accounts do
    filter(expr(account_type in [:checking, :savings, :money_market, :cd]))
  end

  read :investment_accounts do
    filter(expr(account_type == :investment))
  end
end
```

### Enhanced Transaction Model

```elixir
defmodule Ashfolio.Portfolio.Transaction do
  # Existing attributes maintained
  # Transaction types remain investment-focused:

  attribute :type, :atom do
    constraints(one_of: [:buy, :sell, :dividend, :fee, :interest, :liability])
  end

  # New relationships for investment categorization:
  belongs_to :category, Ashfolio.FinancialManagement.TransactionCategory do
    allow_nil?(true)
  end
end
```

### New TransactionCategory Model

```elixir
defmodule Ashfolio.FinancialManagement.TransactionCategory do
  use Ash.Resource,
    domain: Ashfolio.FinancialManagement,
    data_layer: AshSqlite.DataLayer

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      constraints(max_length: 50)
    end

    attribute :color, :string do
      default("#3B82F6")
      constraints(match: ~r/^#[0-9A-Fa-f]{6}$/)
    end

    attribute :is_system, :boolean do
      default(false)
      description("System categories cannot be deleted")
    end

    timestamps()
  end

  relationships do
    belongs_to :user, Ashfolio.Portfolio.User do
      allow_nil?(false)
    end

    belongs_to :parent_category, __MODULE__ do
      allow_nil?(true)
    end

    has_many :child_categories, __MODULE__,
      destination_attribute: :parent_category_id

    has_many :transactions, Ashfolio.Portfolio.Transaction
  end
end
```

## Error Handling

### Enhanced Error Categories

Cash Account Errors:

- Invalid account type for operation
- Insufficient balance for withdrawal/transfer
- Negative interest rate

Transfer Errors:

- Source and destination accounts are the same
- Insufficient balance in source account
- Failed to create linked transaction
- Transfer amount validation errors

Symbol Search Errors:

- External API timeout/failure
- Invalid symbol format
- Symbol not found in any source
- Rate limiting exceeded

Category Errors:

- Duplicate category name for user
- Invalid color format
- Cannot delete system categories
- Cannot delete categories with transactions

### Error Handling Strategy

Graceful Degradation:

- Symbol autocomplete falls back to manual entry if API fails
- Net worth calculation continues with available data if some accounts fail
- Category features remain optional - transactions work without categories

User-Friendly Messages:

```elixir
defmodule Ashfolio.FinancialManagement.ErrorHandler do
  def handle_cash_transaction_error({:error, :insufficient_balance}) do
    "Insufficient balance in account for this transaction"
  end

  def handle_symbol_search_error({:error, :api_timeout}) do
    "Symbol search temporarily unavailable. Please enter symbol manually."
  end

  def handle_transfer_error({:error, :same_account}) do
    "Cannot transfer money to the same account"
  end
end
```

## Testing Strategy

### Unit Testing

Enhanced Resource Tests:

- Account resource with new cash account types
- Transaction resource with new transaction types and categories
- TransactionCategory resource CRUD operations
- NetWorthCalculator with mixed account types
- SymbolSearch with local and external sources

New Module Tests:

- `FinancialManagement.NetWorthCalculator`
- `FinancialManagement.SymbolSearch`
- `FinancialManagement.BalanceCalculator`
- `FinancialManagement.TransactionCategory`

### Integration Testing

Cross-Domain Integration:

- Net worth calculation across Portfolio and FinancialManagement domains
- Transfer transactions creating linked records
- Symbol autocomplete creating new Symbol resources
- Category assignment to existing transactions

LiveView Integration:

- Enhanced dashboard with net worth display
- Symbol autocomplete component in transaction forms
- Category filtering in transaction lists
- Cash account management workflows

### Performance Testing

Symbol Autocomplete:

- Local search response time < 50ms
- External API search response time < 200ms
- Concurrent search request handling
- Cache hit rate optimization

Net Worth Calculation:

- Large portfolio calculation performance
- Real-time update responsiveness
- Memory usage with many accounts/transactions

### Backward Compatibility Testing

Existing Functionality:

- All v0.1.0 investment features work unchanged
- Existing data migrations work correctly
- API compatibility maintained
- Test suite passes without modification

## Implementation Approach

### Phase 1: Foundation (Tasks 1-5)

1. Enhanced Account Resource - Add cash account support
2. Enhanced Transaction Resource - Add cash transaction types
3. TransactionCategory Resource - Create category system
4. Database Migrations - Schema extensions
5. Basic Tests - Unit tests for enhanced resources

### Phase 2: Core Features (Tasks 6-10)

6. Cash Transaction Management - Forms and validation
7. Transfer System - Linked transaction creation
8. NetWorthCalculator - Cross-account calculations
9. SymbolSearch Module - Local + external search
10. Enhanced Dashboard - Net worth integration

### Phase 3: UI Integration (Tasks 11-15)

11. Enhanced Account Management - Cash account UI
12. Symbol Autocomplete Component - Reusable component
13. Category Management UI - Category CRUD interface
14. Enhanced Transaction Forms - Categories + autocomplete
15. Transaction Filtering - Category-based filtering

### Phase 4: Polish & Testing (Tasks 16-20)

16. Performance Optimization - Caching and query optimization
17. Error Handling Enhancement - User-friendly error messages
18. Integration Testing - Cross-domain test coverage
19. Documentation Updates - API and user documentation
20. Backward Compatibility Validation - Ensure v0.1.0 compatibility

## Migration Strategy

### Database Migrations

Account Table Extensions:

```sql
ALTER TABLE accounts ADD COLUMN account_type TEXT DEFAULT 'investment';
ALTER TABLE accounts ADD COLUMN interest_rate DECIMAL;
ALTER TABLE accounts ADD COLUMN minimum_balance DECIMAL;
```

Transaction Table Extensions:

```sql
ALTER TABLE transactions ADD COLUMN linked_transaction_id UUID;
ALTER TABLE transactions ADD COLUMN category_id UUID;
-- Add foreign key constraints
```

New TransactionCategory Table:

```sql
CREATE TABLE transaction_categories (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  color TEXT DEFAULT '#3B82F6',
  is_system BOOLEAN DEFAULT FALSE,
  parent_category_id UUID REFERENCES transaction_categories(id),
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### Data Migration

System Category Seeding:

```elixir
defmodule Ashfolio.FinancialManagement.CategorySeeder do
  def seed_system_categories() do
    categories = [
      %{name: "Growth", color: "#10B981", is_system: true},
      %{name: "Income", color: "#3B82F6", is_system: true},
      %{name: "Speculative", color: "#F59E0B", is_system: true},
      %{name: "Index", color: "#8B5CF6", is_system: true}
    ]

    Enum.each(categories, &create_category(&1))
  end
end
```

Existing Account Migration:

```elixir
# All existing accounts default to :investment type
# No data loss or breaking changes
# New cash accounts can be created alongside existing ones
```

This design maintains the existing architecture's strengths while providing a clear path for comprehensive financial management features. The dual-domain approach ensures clean separation of concerns while the enhanced resources provide backward compatibility.
