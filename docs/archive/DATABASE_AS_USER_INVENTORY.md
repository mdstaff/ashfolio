# Database-as-User Migration Inventory

## Analysis Results

### Overall Statistics

- 24 files
- 46 files
- 23 functions
- ~70 files

## Detailed Inventory

### 1. Production Code - Functions to Refactor

#### Calculator Modules (lib/ashfolio/portfolio/)

```elixir
# Files with user_id parameters that need removal:
calculator.ex
  - calculate_portfolio_value(user_id)
  - calculate_position_returns(user_id)
  - calculate_total_return(user_id)

holdings_calculator.ex
  - calculate_holding_values(user_id)
  - get_holdings_data(user_id)

calculator_optimized.ex
  - calculate_portfolio_value_optimized(user_id)
```

#### Financial Management Modules

```elixir
net_worth_calculator.ex
  - calculate_net_worth(user_id)
  - calculate_account_breakdown(user_id)

net_worth_calculator_optimized.ex
  - calculate_net_worth(user_id)
  - calculate_investment_value(user_id)
  - calculate_cash_value(user_id)
```

#### Context Module

```elixir
context.ex
  - get_user_dashboard_data(user_id)
  - get_portfolio_summary(user_id)
  - get_net_worth(user_id)
```

### 2. Production Code - Misleading Names

#### Account Module

```elixir
# Current -> Should Be
accounts_for_user() -> list_all_accounts()
active_for_user() -> list_active_accounts()
```

#### Transaction Module

```elixir
# Current -> Should Be
list_for_user() -> list_all()
list_for_user_by_category() -> list_by_category()
list_for_user_by_date_range() -> list_by_date_range()
```

### 3. LiveView Modules - Dead Code

#### Files with unused user_id fetching:

```
lib/ashfolio_web/live/dashboard_live.ex
lib/ashfolio_web/live/account_live/index.ex
lib/ashfolio_web/live/transaction_live/index.ex
lib/ashfolio_web/live/category_live/index.ex
```

All have pattern:

```elixir
_user_id = get_default_user_id()  # Fetched but never used
```

### 4. Test Files - Compatibility Layer Usage

#### Test Support Files to Remove:

```
test/support/user_compatibility.ex - Fake User module
test/support/sqlite_helpers.ex - Has user-related helpers
```

#### Test Files Using User.create():

- Over 40 test files contain `User.create()` calls
- Most have `setup` blocks creating users
- Many have `%{user: user}` pattern matches

### 5. Documentation Files

#### Architecture Documentation:

```
docs/development/architecture.md - Has User in ER diagrams
docs/TESTING_STRATEGY.md - References user setup patterns
docs/README.md - Shows multi-user examples
```

#### Migration Documentation:

```
docs/DATABASE_AS_USER_MIGRATION.md - Original plan (partially executed)
docs/DATABASE_AS_USER_ASSESSMENT.md - Current state analysis
docs/DATABASE_AS_USER_COMPLETION_PLAN.md - Completion strategy
```

## Function Signature Changes Needed

### Before and After Examples

```elixir
# Calculator Module
# Before:
def calculate_portfolio_value(user_id) when is_binary(user_id) do
def calculate_portfolio_value(_user_id \\ nil) do

# After:
def calculate_portfolio_value do

# Context Module
# Before:
def get_user_dashboard_data(user_id) do

# After:
def get_dashboard_data do

# Account Module
# Before:
def accounts_for_user(user_id) do

# After:
def list_all_accounts do
```

## Test Pattern Changes Needed

### Current Test Pattern (to remove):

```elixir
setup do
  {:ok, user} = User.create(%{name: "Test User"})
  {:ok, account} = Account.create(%{user_id: user.id})
  %{user: user, account: account}
end

test "does something", %{user: user} do
  # test using user
end
```

### New Test Pattern (to implement):

```elixir
setup do
  {:ok, account} = Account.create(%{name: "Test Account"})
  %{account: account}
end

test "does something", %{account: account} do
  # test without user concept
end
```

## PubSub Topics to Update

### Current (already mostly updated):

```elixir
"net_worth" # Good - no user reference
"portfolio_update" # Good - no user reference
"balance_changes" # Good - no user reference
```

### Any remaining user-specific topics:

- Need to grep for any remaining `"*:#{user.id}"` patterns
- Most have been cleaned up already

## Priority Order for Refactoring

### High Priority (Core Functions):

1. Calculator modules - remove user_id parameters
2. Context module - fix API functions
3. Account/Transaction - rename misleading functions

### Medium Priority (Clean Code):

4. LiveView modules - remove dead code
5. Test infrastructure - remove compatibility
6. Test files - update patterns

### Low Priority (Documentation):

7. Architecture docs - update diagrams
8. Code comments - fix references
9. README - update examples

## Estimated Line Changes

- ~500 lines
- ~2000 lines
- ~200 lines
- ~2700 lines of changes

## Risk Areas

### High Risk:

- Calculator modules (core business logic)
- Context API (used everywhere)
- Test infrastructure (could break all tests)

### Medium Risk:

- LiveView modules (UI might break)
- Account/Transaction queries

### Low Risk:

- Documentation updates
- Comment fixes
- Variable renames

## Validation Checklist

After refactoring, verify:

- [ ] No "User.create" in any test file
- [ ] No "user_id" parameters in any function
- [ ] No "user:" in test contexts
- [ ] No get_default_user_id() calls
- [ ] All tests pass
- [ ] Application runs correctly
- [ ] Documentation is accurate
