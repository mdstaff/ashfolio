# Corporate Actions Engine v0.6.0

> **Status: COMPLETE** | **Test Coverage: 21 comprehensive tests + 8 integration tests**

## Overview

The Corporate Actions Engine provides comprehensive processing of corporate events that affect stock positions, maintaining FIFO cost basis integrity while ensuring accurate tax implications. This engine supports all major corporate action types with proper audit trails and compliance with IRS guidelines.

## Supported Corporate Actions

### ✅ Stock Splits (Forward & Reverse)
- **Forward splits**: 2:1, 3:1, 3:2, etc.
- **Reverse splits**: 1:2, 1:10, etc.
- **Fractional share handling**: Proper rounding and value preservation
- **Total value preservation**: Share count × price remains constant

**Example**: 2:1 forward split
- 100 shares @ $200 → 200 shares @ $100
- Total value maintained: $20,000

### ✅ Cash Dividends
- **Qualified dividends**: Preferential tax treatment
- **Ordinary dividends**: Regular income tax rates
- **Tax withholding**: Automatic calculation
- **Minimum holding period**: 61-day validation for qualified status

**Example**: $1.00 quarterly dividend
- 100 shares → $100.00 dividend income
- Tax treatment based on qualified/ordinary status

### ✅ Mergers & Acquisitions (NEW in v0.6.0)

#### Stock-for-Stock Mergers (Tax-Deferred)
- **Basis carryover**: Original cost basis maintained
- **Exchange ratio**: Flexible ratio support (e.g., 1.5:1)
- **Purchase date preservation**: For long-term capital gains

**Example**: 1.5:1 stock merger
- 100 shares @ $50 basis → 150 shares @ $33.33 basis
- No taxable event, basis carries forward

#### Cash Mergers (Taxable Event)
- **Full gain/loss recognition**: Immediate tax consequences
- **Position closure**: All shares converted to cash
- **Accurate basis calculation**: Precise gain/loss computation

**Example**: Cash merger @ $80/share
- 100 shares @ $50 basis → $8,000 cash
- Realized gain: $3,000 ($30 per share)

#### Mixed Consideration Mergers
- **Partial recognition**: Tax on cash portion only
- **Stock portion**: Deferred basis treatment
- **Proportional allocation**: IRS-compliant basis allocation

### ✅ Spinoffs (NEW in v0.6.0)
- **Basis allocation**: Between parent and spun-off company
- **New symbol creation**: Automatic handling
- **Tax-deferred treatment**: No immediate tax consequences
- **Flexible ratios**: Support for any spinoff ratio (1:1, 0.5:1, etc.)

**Example**: 1:1 spinoff with 20% allocation
- 100 shares @ $100 basis:
  - Original: 100 shares @ $80 basis (80% allocation)
  - Spinoff: 100 shares @ $20 basis (20% allocation)

## Architecture

### Core Components

```elixir
# Domain Resources
Ashfolio.Portfolio.CorporateAction        # 354 lines - Event storage
Ashfolio.Portfolio.TransactionAdjustment   # 176 lines - Audit trail

# Calculation Engines
Ashfolio.Portfolio.Calculators.StockSplitCalculator  # 166 lines
Ashfolio.Portfolio.Calculators.DividendCalculator    # 119 lines
Ashfolio.Portfolio.Calculators.MergerCalculator      # 450+ lines (NEW)

# Application Services
Ashfolio.Portfolio.Services.CorporateActionApplier   # 262 lines
```

### Data Flow

1. **Event Recording**: Corporate action details stored in database
2. **Transaction Discovery**: FIFO-ordered transactions identified
3. **Calculation**: Appropriate calculator determines adjustments
4. **Audit Trail**: TransactionAdjustment records created
5. **Status Update**: Corporate action marked as applied

### FIFO Integrity

The engine maintains FIFO (First-In, First-Out) cost basis methodology:

- **Chronological processing**: Oldest transactions adjusted first
- **Basis preservation**: Original purchase dates maintained
- **Tax lot tracking**: Separate adjustments per transaction
- **Audit compliance**: Complete transaction adjustment history

## Usage Examples

### Creating Corporate Actions

```elixir
# Stock Split
{:ok, split} = CorporateAction.create(%{
  action_type: :stock_split,
  symbol_id: symbol.id,
  ex_date: ~D[2024-06-01],
  description: "2:1 stock split",
  split_ratio_from: Decimal.new("1"),
  split_ratio_to: Decimal.new("2")
})

# Stock-for-Stock Merger
{:ok, merger} = CorporateAction.create(%{
  action_type: :merger,
  symbol_id: symbol.id,
  ex_date: ~D[2024-06-01],
  description: "Acquisition by ACQUIRER",
  merger_type: :stock_for_stock,
  exchange_ratio: Decimal.new("1.5")
})

# Spinoff
{:ok, spinoff} = CorporateAction.create(%{
  action_type: :spinoff,
  symbol_id: parent_symbol.id,
  new_symbol_id: spinoff_symbol.id,
  ex_date: ~D[2024-06-01],
  description: "Spinoff of subsidiary",
  exchange_ratio: Decimal.new("1")  # 1:1 ratio
})
```

### Applying Corporate Actions

```elixir
# Apply single action
{:ok, result} = CorporateActionApplier.apply_corporate_action(corporate_action)
# Returns: %{corporate_action_id: id, adjustments_created: 2, status: :applied}

# Batch apply pending actions for a symbol
{:ok, results} = CorporateActionApplier.batch_apply_pending(symbol_id)
# Returns: %{actions_processed: 3, total_adjustments: 6}

# Preview impact before applying
{:ok, preview} = CorporateActionApplier.preview_application(corporate_action)
# Returns: %{affected_transactions: 2, estimated_adjustments: 2, ...}
```

### Querying Applied Actions

```elixir
# Find actions by symbol
{:ok, actions} = CorporateAction.by_symbol(symbol_id)

# Find pending actions
{:ok, pending} = CorporateAction.pending()

# Get adjustment details
{:ok, adjustments} = TransactionAdjustment.by_corporate_action(action_id)
```

## UI Integration

### LiveView Interface
- **Modal forms**: User-friendly corporate action creation
- **Real-time validation**: Immediate feedback on form inputs
- **Conditional fields**: Dynamic form based on action type
- **Action management**: Apply, preview, reverse actions

### Form Validation
- **Required fields**: Enforced based on action type
- **Business rules**: Split ratios, dividend amounts, etc.
- **Date validation**: Ex-date constraints and logic
- **Symbol relationships**: Parent/child symbol validation

## Tax Compliance

### IRS Alignment
- **Publication 550**: Investment Income and Expenses
- **Form 8949**: Sales and Other Dispositions
- **Schedule D**: Capital Gains and Losses
- **Qualified dividend rules**: 61-day holding period

### Audit Trail
- **Complete history**: Every adjustment tracked
- **Reversal capability**: Undo applied actions
- **Applied by tracking**: User/system attribution
- **Timestamps**: Precise application timing

## Performance Characteristics

- **Calculator performance**: <100ms for complex calculations
- **Bulk processing**: Efficient batch operations
- **Memory usage**: Optimized for large portfolios
- **Database queries**: Minimal query count per operation

## Test Coverage

### Unit Tests (21 comprehensive tests)
- **MergerCalculator**: All merger types and edge cases
- **Stock/cash/mixed mergers**: Comprehensive validation
- **Spinoff calculations**: Basis allocation scenarios
- **Error handling**: Input validation and edge cases

### Integration Tests (8 tests)
- **CorporateActionApplier**: End-to-end processing
- **Database persistence**: Transaction creation
- **Status management**: Applied/pending/reversed states
- **FIFO preservation**: Order integrity validation

### Test Scenarios
```elixir
# Example test cases covered:
test "2:1 forward split doubles shares, halves price"
test "cash merger with gain recognition"
test "mixed merger with partial tax recognition"
test "spinoff maintains total basis allocation"
test "FIFO order preserved across adjustments"
test "reversal restores original state"
```

## Future Enhancements

### Planned Features (Post v0.6.0)
- **Stock dividends**: Share-based dividend payments
- **Return of capital**: Basis reduction scenarios
- **Rights offerings**: Subscription right handling
- **International actions**: Cross-border tax considerations

### API Extensions
- **Bulk import**: CSV/Excel file processing
- **External data**: Integration with data providers
- **Notification system**: Alert for pending actions
- **Reporting**: Tax-ready reports and exports

## Migration Guide

### From v0.5.0
The Corporate Actions Engine is completely new in v0.6.0. No migration required for existing data.

### Database Schema
New tables:
- `corporate_actions`: Event storage
- `transaction_adjustments`: Audit trail

### Breaking Changes
None - this is a new feature addition.

---

*This documentation reflects the v0.6.0 implementation as of completion. For implementation details, see the comprehensive test suite and source code documentation.*