# Currency Formatting Migration Plan

## Migration Overview

**Scope**: Replace `FormatHelpers.format_currency` usage across 14 files with our unified `Ashfolio.Financial.Formatters` API.

**Evidence**: 79 total usages concentrated in 14 files, all using the `FormatHelpers.format_currency` pattern.

## Migration Strategy

### Phase 1: Direct Replacement (Safe Approach)

Since all usage is `FormatHelpers.format_currency`, we can safely replace with our backward compatibility function `format_currency_with_cents` which provides identical behavior.

**Replacement Pattern**:
```elixir
# FROM:
alias AshfolioWeb.Live.FormatHelpers
FormatHelpers.format_currency(value)
FormatHelpers.format_currency(value, true) 
FormatHelpers.format_currency(value, false)

# TO:
alias Ashfolio.Financial.Formatters
Formatters.format_currency_with_cents(value)
Formatters.format_currency_with_cents(value, true)
Formatters.format_currency_with_cents(value, false)
```

### Files to Update (14 total):

1. `lib/ashfolio_web/live/account_live/balance_update_component.ex`
2. `lib/ashfolio_web/live/account_live/form_component.ex` 
3. `lib/ashfolio_web/live/account_live/index.ex`
4. `lib/ashfolio_web/live/account_live/show.ex`
5. `lib/ashfolio_web/live/dashboard_live.ex`
6. `lib/ashfolio_web/live/expense_live/analytics.ex`
7. `lib/ashfolio_web/live/expense_live/index.ex`
8. `lib/ashfolio_web/live/financial_goal_live/form_component.ex`
9. `lib/ashfolio_web/live/financial_goal_live/index.ex`
10. `lib/ashfolio_web/live/financial_planning_live/forecast.ex`
11. `lib/ashfolio_web/live/forecast_live.ex`
12. `lib/ashfolio_web/live/net_worth_live/index.ex`
13. `lib/ashfolio_web/live/transaction_live/index.ex`
14. `lib/ashfolio_web/components/transaction_group.ex`

### Migration Steps:

1. **Update imports**: Replace `FormatHelpers` alias with `Formatters` alias
2. **Replace function calls**: Update all `FormatHelpers.format_currency` calls
3. **Run tests**: Validate no regressions after each file
4. **Commit incrementally**: Small commits for easy rollback

### Validation Strategy:

- Run full test suite after each batch of files
- Visual UI testing for currency display components
- Backwards compatibility tests continue to pass

## Risk Assessment: LOW

- **Backward compatibility guaranteed** by our comprehensive test suite
- **Single pattern replacement** (only FormatHelpers.format_currency used)
- **Incremental approach** allows rollback at any step
- **No breaking changes** in function signatures

## Implementation Timeline:

- **Batch 1**: Account-related LiveViews (4 files) 
- **Batch 2**: Dashboard and financial views (5 files)
- **Batch 3**: Remaining views and components (5 files)
- **Cleanup**: Remove old FormatHelpers module

Each batch followed by test validation and commit.