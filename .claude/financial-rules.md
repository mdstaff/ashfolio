# Financial Software Development Rules
# For Ashfolio - Personal Financial Management Application

## Tax Calculation Documentation Requirements

### REQUIRED for All Tax Features

Every tax-related module MUST include:

1. **Regulatory Reference**
   ```elixir
   @doc """
   Implements FIFO cost basis per IRS Publication 550
   Reference: https://www.irs.gov/publications/p550
   """
   ```

2. **Calculation Examples**
   ```elixir
   # Example: 100 shares bought at $10, 50 sold at $15
   # Cost basis: $500 (50 * $10)
   # Proceeds: $750 (50 * $15)  
   # Gain: $250
   ```

3. **Edge Cases Documentation**
   - Wash sale rules (30-day rule)
   - Corporate actions (splits, dividends)
   - Multi-lot transactions
   - Negative cost basis handling

## Database Migration Rules for Financial Data

### Financial Data Migration Protocol
1. **NEVER modify historical transactions** - Create adjustment entries instead
2. **Preserve Audit Trail** - All financial changes must be traceable
3. **Test with Production-like Data** - Use 1000+ transaction datasets
4. **Rollback Plan Required** - Document exact rollback steps

### Migration Checklist
- [ ] Backup current database
- [ ] Test migration on copy with `just db test-migrate`
- [ ] Verify FIFO calculations remain consistent
- [ ] Validate net worth before/after
- [ ] Document any calculation changes

## LiveView Financial Update Patterns

### Real-time Financial Data Rules
1. **PubSub for Price Updates**: All price changes MUST broadcast via PubSub
2. **Debounce Calculations**: Portfolio recalculations debounced to 1s minimum
3. **Progressive Loading**: Large portfolios load in 100-position chunks
4. **Cache Invalidation**: Clear ETS cache on transaction changes

### LiveView Financial Components Pattern
```elixir
# ALWAYS use this pattern for financial displays
def update(assigns, socket) do
  # 1. Validate financial data
  # 2. Calculate with Decimal precision
  # 3. Format for display
  # 4. Assign to socket with validation
  
  validated_data = validate_financial_input(assigns.raw_data)
  calculated_value = calculate_with_decimal(validated_data)
  formatted_value = FormatHelper.format_currency(calculated_value)
  
  socket
  |> assign(:raw_value, calculated_value)
  |> assign(:formatted_value, formatted_value)
  |> assign(:percentage, FormatHelper.format_percentage(change))
  |> assign(:updated_at, DateTime.utc_now())
end
```

## Financial Accuracy Testing Scenarios

### MANDATORY Test Scenarios for Financial Features

```elixir
# Market Stress Tests
test "handles 2008 financial crisis scenario" do
  # 50% portfolio decline over 18 months
  # Verify calculations remain stable
end

test "handles dot-com crash scenario" do
  # 78% NASDAQ decline from 2000-2002
  # Test cost basis calculations
end

test "handles stagflation scenario" do
  # High inflation + stagnant growth (1970s)
  # Test retirement planning adjustments
end

# Edge Case Tests
test "handles division by zero in ratios" do
  # Zero income, zero assets scenarios
  # Must return appropriate error or default
end

test "handles negative interest rates" do
  # European/Japanese monetary policy scenarios
  # Ensure bond calculations work correctly
end

test "handles currency precision limits" do
  # Very large portfolios (>$100M)
  # Very small amounts (<$0.01)
  # Ensure Decimal precision maintained
end

# Regulatory Compliance Tests
test "FIFO cost basis matches IRS examples" do
  # Use actual IRS Publication 550 examples
  # Verify calculations match exactly
end

test "wash sale rule detection" do
  # Buy AAPL, sell at loss, buy within 30 days
  # Must properly adjust cost basis
end
```

## Code GPS Integration for Financial Features

### Before Starting Financial Development

```bash
# MANDATORY sequence for financial features
mix code_gps                          # Generate manifest
grep -i "calculator" .code-gps.yaml   # Find calculation patterns
grep -i "decimal" .code-gps.yaml      # Find precision patterns
grep -i "fifo" .code-gps.yaml         # Find tax patterns
just test unit                        # Verify baseline before changes
```

### Financial Pattern Detection

Code GPS should identify and track:
- Decimal calculation patterns and usage
- Tax calculation modules and dependencies
- FIFO cost basis implementations
- LiveView financial component patterns
- Performance-critical calculation paths

## Future Feature Development Guidelines

### When Adding New Financial Features (v0.6+)

1. **Incremental Delivery**: Break complex features into 3-5 testable stages
2. **Industry Standard First**: Research and implement standard calculations before customizations
3. **Local-First Always**: No cloud dependencies for core financial operations
4. **Privacy by Design**: Financial data never transmitted outside user's machine
5. **Performance Validated**: Sub-second response for standard operations

### Financial Feature Readiness Checklist

- [ ] Matches recognized industry standard implementation
- [ ] Includes comprehensive edge case test coverage
- [ ] Performance tested with 1000+ item datasets
- [ ] Documentation includes real financial examples
- [ ] LiveView UI updates provide real-time feedback
- [ ] Integrates properly with existing calculators
- [ ] Maintains FIFO cost basis consistency
- [ ] Includes regulatory compliance documentation
- [ ] Error handling provides user-friendly messages
- [ ] Decimal precision maintained throughout calculation chain

## Financial Software Error Handling

### Error Categories for Financial Operations

1. **User Input Errors**
   - Invalid dates, negative quantities where inappropriate
   - Return user-friendly messages with correction guidance

2. **Data Integrity Errors**
   - Missing cost basis, orphaned transactions
   - Log for debugging, provide fallback calculations

3. **Calculation Errors**
   - Division by zero, overflow scenarios
   - Fail fast with context, never return incorrect financial data

4. **Regulatory Compliance Errors**
   - Tax calculation inconsistencies, invalid wash sale handling
   - Must be treated as critical errors requiring immediate attention

### Financial Error Pattern

```elixir
# Standard error handling for financial calculations
def calculate_portfolio_value(positions) when is_list(positions) do
  with {:ok, validated_positions} <- validate_positions(positions),
       {:ok, current_prices} <- fetch_current_prices(validated_positions),
       {:ok, calculated_values} <- calculate_position_values(validated_positions, current_prices) do
    {:ok, sum_portfolio_value(calculated_values)}
  else
    {:error, :invalid_positions} = error ->
      Logger.error("Portfolio calculation failed: invalid positions", positions: positions)
      error
      
    {:error, :price_fetch_failed} = error ->
      Logger.warn("Price fetch failed, using last known prices")
      calculate_portfolio_value_with_last_prices(positions)
      
    {:error, reason} = error ->
      Logger.error("Portfolio calculation failed", reason: reason, positions: positions)
      error
  end
end
```

This ensures financial calculations are robust, traceable, and provide appropriate fallbacks for different error scenarios.