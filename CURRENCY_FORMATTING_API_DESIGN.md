# Currency Formatting API Design | Task 2 Implementation

## Executive Summary

Design unified `Ashfolio.Financial.Formatters` API to consolidate 3 different `format_currency` implementations across 34 files, preserving all current features while creating consistent behavior.

**Evidence Base**: 3 implementations with different feature sets (show_cents, comma formatting, negative handling)
**Impact**: 34 files affected, HIGH priority consolidation opportunity
**Risk Level**: MEDIUM - different features need preservation

---

## Current Implementation Analysis

### Implementation A: `lib/ashfolio_web/helpers/format_helper.ex:116-131`
```elixir
def format_currency(value) when is_struct(value, Decimal)
def format_currency(value) when is_number(value) 
def format_currency(nil)
```
**Features**: Decimal-first, comma formatting, always 2 decimal places, handles nil

### Implementation B: `lib/ashfolio_web/live/format_helpers.ex:29-67`
```elixir
def format_currency(value, show_cents \\ true)
def format_currency(nil, _show_cents)
def format_currency(value, show_cents) when is_struct(value, Decimal)
def format_currency(value, show_cents) when is_integer(value)
def format_currency(value, show_cents) when is_float(value)
```
**Features**: Configurable decimals, negative value handling, comprehensive type support

### Implementation C: `lib/ashfolio_web/helpers/chart_helpers.ex:137-153`
```elixir
def format_currency(%Decimal{} = value)
def format_currency(value) when is_number(value)
def format_currency(_)
```
**Features**: Float-based, no comma formatting, minimal fallback

---

## Unified API Design

### New Module: `Ashfolio.Financial.Formatters`

```elixir
defmodule Ashfolio.Financial.Formatters do
  @moduledoc """
  Unified currency and financial value formatting for consistent display across Ashfolio.
  
  Consolidates all currency formatting logic from helpers, LiveViews, and components
  into a single, feature-complete API.
  """

  @doc """
  Formats currency values with comprehensive options support.
  
  ## Options
    * `:show_cents` - boolean, display cents (default: true)
    * `:comma_formatting` - boolean, add thousands separators (default: true)  
    * `:handle_negative` - boolean, format negative values with sign (default: true)
    * `:currency_symbol` - string, currency symbol (default: "$")
    * `:fallback` - string, value for nil/invalid inputs (default: "$0.00")
  
  ## Examples
      iex> Formatters.currency(Decimal.new("1234.56"))
      "$1,234.56"
      
      iex> Formatters.currency(Decimal.new("1234.56"), show_cents: false)
      "$1,235"
      
      iex> Formatters.currency(Decimal.new("-123.45"))
      "-$123.45"
      
      iex> Formatters.currency(nil)
      "$0.00"
  """
  def currency(value, opts \\ [])

  # Main implementation with full options support
  def currency(value, opts) when is_struct(value, Decimal) do
    options = build_options(opts)
    
    value
    |> handle_negative_value(options)
    |> format_decimal_value(options)
    |> add_currency_symbol(options)
  end

  def currency(value, opts) when is_number(value) do
    currency(Decimal.from_float(value * 1.0), opts)
  end

  def currency(nil, opts) do
    options = build_options(opts)
    options.fallback
  end

  def currency(_, opts) do
    currency(nil, opts)  # Fallback for invalid inputs
  end

  # Backward compatibility functions
  @doc """
  Backward compatibility for format_helper.ex usage pattern.
  Always shows cents with comma formatting.
  """  
  def format_currency_classic(value) do
    currency(value, show_cents: true, comma_formatting: true)
  end

  @doc """
  Backward compatibility for format_helpers.ex usage pattern.
  Supports show_cents parameter.
  """
  def format_currency_with_cents(value, show_cents \\ true) do
    currency(value, show_cents: show_cents, comma_formatting: true, handle_negative: true)
  end

  @doc """
  Backward compatibility for chart_helpers.ex usage pattern.  
  Minimal formatting without commas.
  """
  def format_currency_simple(value) do
    currency(value, show_cents: true, comma_formatting: false, handle_negative: false)
  end

  # Private implementation functions
  defp build_options(opts) do
    %{
      show_cents: Keyword.get(opts, :show_cents, true),
      comma_formatting: Keyword.get(opts, :comma_formatting, true),
      handle_negative: Keyword.get(opts, :handle_negative, true),
      currency_symbol: Keyword.get(opts, :currency_symbol, "$"),
      fallback: Keyword.get(opts, :fallback, "$0.00")
    }
  end

  defp handle_negative_value(value, %{handle_negative: true}) do
    if Decimal.negative?(value) do
      {"-", Decimal.abs(value)}
    else
      {"", value}
    end
  end

  defp handle_negative_value(value, %{handle_negative: false}) do
    {"", Decimal.abs(value)}
  end

  defp format_decimal_value({sign, value}, options) do
    formatted = 
      if options.show_cents do
        value
        |> Decimal.round(2)
        |> Decimal.to_string()
      else
        value
        |> Decimal.round(0)
        |> Decimal.to_string()
      end

    formatted_with_commas = 
      if options.comma_formatting do
        add_thousands_separator(formatted)
      else
        formatted
      end

    {sign, formatted_with_commas}
  end

  defp add_currency_symbol({sign, formatted}, options) do
    "#{sign}#{options.currency_symbol}#{formatted}"
  end

  defp add_thousands_separator(number_string) do
    # Extract decimal part if present
    case String.split(number_string, ".", parts: 2) do
      [whole] ->
        add_commas_to_whole(whole)
      [whole, decimal] ->
        "#{add_commas_to_whole(whole)}.#{decimal}"
    end
  end

  defp add_commas_to_whole(whole_part) do
    whole_part
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(",")
    |> String.reverse()
  end
end
```

---

## Migration Strategy

### Phase 1: Create Unified Module (Week 1)
1. **Create** `lib/ashfolio/financial/formatters.ex` with unified implementation
2. **Write comprehensive tests** covering all current usage patterns
3. **Add documentation** with examples from all three implementations
4. **Validate** feature parity with existing implementations

### Phase 2: Gradual Migration (Week 2-3)  
1. **Add alias imports** to existing helper modules:
   ```elixir
   # In format_helper.ex
   defdelegate format_currency(value), to: Ashfolio.Financial.Formatters, as: :format_currency_classic
   
   # In format_helpers.ex  
   defdelegate format_currency(value, show_cents), to: Ashfolio.Financial.Formatters, as: :format_currency_with_cents
   
   # In chart_helpers.ex
   defdelegate format_currency(value), to: Ashfolio.Financial.Formatters, as: :format_currency_simple
   ```

2. **Test compatibility** - all existing tests should pass without changes
3. **Monitor for regressions** during deployment

### Phase 3: Direct Migration (Week 4)
1. **Update imports** across 34 files to use `Ashfolio.Financial.Formatters.currency/2`
2. **Remove old implementations** once all usages migrated
3. **Update documentation** to reference unified API

---

## Breaking Change Analysis

### Signature Changes
| Current | New | Breaking? | Mitigation |
|---------|-----|-----------|------------|
| `format_currency(value)` | `currency(value)` | **YES** | Provide `format_currency_classic/1` alias |
| `format_currency(value, show_cents)` | `currency(value, show_cents: show_cents)` | **YES** | Provide `format_currency_with_cents/2` alias |
| Different return formats | Consistent format | **MAYBE** | Test coverage ensures compatibility |

### Behavioral Changes
- **Comma formatting**: Chart helpers will gain comma formatting (may affect chart display)
- **Negative handling**: Simple formatters will gain negative sign handling  
- **Type handling**: More consistent type coercion across all uses

### Risk Mitigation
1. **Comprehensive test suite** validates all current behaviors
2. **Backward compatibility functions** prevent breaking changes during migration
3. **Gradual rollout** allows detection of issues before full migration
4. **Feature flags** could control new vs old behavior during transition

---

## Test Coverage Plan

### Unit Tests for Unified API
```elixir
defmodule Ashfolio.Financial.FormattersTest do
  use ExUnit.Case
  alias Ashfolio.Financial.Formatters

  describe "currency/2" do
    test "formats decimal with default options" do
      assert Formatters.currency(Decimal.new("1234.56")) == "$1,234.56"
    end

    test "handles show_cents option" do
      assert Formatters.currency(Decimal.new("1234.56"), show_cents: false) == "$1,235"
      assert Formatters.currency(Decimal.new("1234.56"), show_cents: true) == "$1,234.56"
    end

    test "handles comma_formatting option" do
      assert Formatters.currency(Decimal.new("1234.56"), comma_formatting: false) == "$1234.56"
      assert Formatters.currency(Decimal.new("1234.56"), comma_formatting: true) == "$1,234.56"
    end

    test "handles negative values" do
      assert Formatters.currency(Decimal.new("-123.45")) == "-$123.45"
      assert Formatters.currency(Decimal.new("-123.45"), handle_negative: false) == "$123.45"
    end

    test "handles nil and invalid inputs" do
      assert Formatters.currency(nil) == "$0.00"
      assert Formatters.currency("invalid") == "$0.00"
      assert Formatters.currency(nil, fallback: "N/A") == "N/A"
    end
  end

  describe "backward compatibility functions" do
    test "format_currency_classic matches format_helper.ex behavior" do
      # Test against known outputs from current implementation
      assert Formatters.format_currency_classic(Decimal.new("1234.56")) == "$1,234.56"
      assert Formatters.format_currency_classic(nil) == "$0.00"
    end

    test "format_currency_with_cents matches format_helpers.ex behavior" do  
      assert Formatters.format_currency_with_cents(Decimal.new("1234.56"), true) == "$1,234.56"
      assert Formatters.format_currency_with_cents(Decimal.new("1234.56"), false) == "$1,235"
      assert Formatters.format_currency_with_cents(Decimal.new("-123.45"), true) == "-$123.45"
    end

    test "format_currency_simple matches chart_helpers.ex behavior" do
      assert Formatters.format_currency_simple(Decimal.new("1234.56")) == "$1234.56"
      assert Formatters.format_currency_simple(123.45) == "$123.45"
    end
  end
end
```

### Integration Tests
```elixir
defmodule Ashfolio.Financial.FormattersIntegrationTest do
  use ExUnit.Case
  
  test "maintains compatibility with existing helper modules" do
    # Import through old modules should still work
    alias AshfolioWeb.Helpers.FormatHelper
    alias AshfolioWeb.Live.FormatHelpers
    alias AshfolioWeb.Helpers.ChartHelpers
    
    # Test that aliased functions produce expected results
    assert FormatHelper.format_currency(Decimal.new("100.50")) == "$100.50"  
    assert FormatHelpers.format_currency(Decimal.new("100.50"), true) == "$100.50"
    assert ChartHelpers.format_currency(Decimal.new("100.50")) == "$100.50"
  end
end
```

---

## Impact Assessment

### Files Requiring Updates
**34 files confirmed using `format_currency`** - systematic update required across:
- LiveView modules (dashboard, accounts, transactions, etc.)
- Component modules (transaction_stats, transaction_group, etc.) 
- Helper modules (format_helper, format_helpers, chart_helpers)
- Test files

### Estimated Effort
- **API Design & Implementation**: 2-3 days
- **Comprehensive Test Suite**: 1-2 days  
- **Migration Scripting**: 1 day
- **File-by-file Migration**: 2-3 days
- **Validation & Cleanup**: 1 day

**Total: 7-10 days** for complete consolidation

### Benefits
- **Single source of truth** for currency formatting
- **Consistent behavior** across all components
- **Easier maintenance** - one place to update formatting logic
- **Better testing** - comprehensive test coverage in one place
- **Extensibility** - easy to add new formatting options

---

## Success Criteria

### Functional Requirements
- [ ] All current formatting behaviors preserved
- [ ] Comprehensive options API supports all existing features
- [ ] Backward compatibility functions prevent breaking changes
- [ ] 100% test coverage for new unified API

### Non-Functional Requirements  
- [ ] No performance degradation vs current implementations
- [ ] Migration completed without production issues
- [ ] Documentation provides clear migration guide
- [ ] All existing tests continue to pass

### Validation Requirements
- [ ] Manual testing of currency display across major UI components
- [ ] Automated regression testing during migration
- [ ] Code review validation of unified implementation
- [ ] Performance benchmarking of new vs old implementations

---

## Risk Mitigation Plan

### HIGH Risk: Behavioral Differences
**Mitigation**: Comprehensive test suite validates exact compatibility with current outputs

### MEDIUM Risk: Chart Display Changes  
**Mitigation**: Chart-specific formatting options maintain current behavior

### MEDIUM Risk: Migration Complexity
**Mitigation**: Gradual rollout with aliased functions allows safe transition

### LOW Risk: Performance Impact
**Mitigation**: Benchmark testing ensures no regression in formatting speed

---

## Next Steps

1. **Create unified module** with comprehensive implementation
2. **Build test suite** validating all current behaviors  
3. **Create migration tooling** for systematic file updates
4. **Execute gradual rollout** with monitoring and rollback capability

**This design provides feature parity while creating the foundation for consistent currency formatting across Ashfolio.**