# Ashfolio v0.4.x Implementation Plan

## Overview

This implementation plan addresses critical bugs found during E2E testing and completes the v0.4.x roadmap. Following TDD methodology, we'll fix production-blocking issues first, then implement missing v0.4.2 features.

**Current Status**: v0.4.1 Complete ✅, v0.4.2-v0.4.3 Bug fixes required
**Timeline**: 2 weeks to production readiness
**Methodology**: Test-driven development with E2E verification

## 🐛 Critical Bugs Found During E2E Testing

### Priority 1: Broken Features
1. **Goal Creation Form** - KeyError for `:recommended_target` prevents new goal creation
2. **Missing Navigation Links** - No access to Analytics (/expenses/analytics) and Net Worth (/net_worth)

### Priority 2: Chart Visualization Issues  
1. **Growth Rate Display** - Shows "0.07%" instead of "7%" in parameters
2. **Missing Initial Portfolio Value** - All charts start at $0 instead of initial value
3. **Scenario Comparison Chart** - Only displays 1 line instead of 3 scenarios
4. **Y-axis Formatting** - Shows "$2BGN" instead of proper formatting
5. **Wrong Chart Reuse** - Contribution Impact shows Scenario Comparison chart

### Priority 3: Missing Features
1. **v0.4.2 Retirement Planning UI** - No interface for 25x rule, 4% withdrawal calculations

## Phase 1: Critical Production Fixes (Week 1)

### Stage 1: Fix Goal Creation Form [URGENT - P0]
**Status**: [NOT STARTED]
**Impact**: Blocks all goal functionality
**Timeline**: Day 1 morning (2 hours)

### TDD Tests First:

```elixir
@tag :unit
test "calculate_recommended_target returns 6x monthly expenses for emergency fund" do
  monthly_expenses = Decimal.new("1000.00")
  expected = Decimal.new("6000.00")
  
  assert {:ok, result} = FinancialGoal.calculate_recommended_target(:emergency_fund, monthly_expenses)
  assert Decimal.equal?(result, expected)
end

@tag :liveview
test "goal creation form includes recommended_target field" do
  {:ok, view, _html} = live(conn, "/goals/new")
  
  assert has_element?(view, "#goal_recommended_target")
  assert html =~ "Recommended Target"
end
```

### Implementation Tasks:
1. Add `calculate_recommended_target/2` to FinancialGoal module
2. Update FinancialGoalLive.FormComponent with recommended_target field
3. Add expense-based calculations for emergency fund targets
4. Test form submission with all fields

**Files to modify:**
- `lib/ashfolio_web/live/financial_goal_live/form_component.ex`
- `lib/ashfolio/financial_management/financial_goal.ex`
- `test/ashfolio_web/live/financial_goal_live_test.exs`

### Stage 2: Fix Chart Data Issues [HIGH - P1] 
**Status**: [NOT STARTED]
**Impact**: User confusion, incorrect visualizations
**Timeline**: Day 2 (4 hours)

### TDD Tests First:

```elixir
@tag :unit
test "format_growth_rate converts decimal to percentage string" do
  assert "7%" = FormatHelper.format_growth_rate(Decimal.new("0.07"))
  assert "5%" = FormatHelper.format_growth_rate(Decimal.new("0.05"))
  assert "10%" = FormatHelper.format_growth_rate(Decimal.new("0.10"))
end

@tag :unit
test "projection chart data starts with initial portfolio value" do
  initial = Decimal.new("100000")
  data = ForecastCalculator.generate_chart_data(initial, [], 0.07, 30)
  
  assert [first | _] = data
  assert Decimal.equal?(first.value, initial)
  assert first.year == 0
end

@tag :unit
test "scenario comparison generates three distinct data series" do
  params = %{initial: 100000, contribution: 1000, years: 30}
  chart_data = ForecastCalculator.generate_scenario_chart(params)
  
  assert %{pessimistic: p_data, realistic: r_data, optimistic: o_data} = chart_data
  assert length(p_data) == 31  # 0 to 30 years
  assert length(r_data) == 31
  assert length(o_data) == 31
  refute p_data == r_data  # Ensure they're different
end
```

### Implementation Tasks:
1. Create FormatHelper module with percentage formatting
2. Update chart data generation to include year 0 with initial value
3. Fix multi-series chart rendering in Contex
4. Update all growth rate displays to use percentage format

**Files to modify:**
- `lib/ashfolio_web/live/forecast_live/index.ex`
- `lib/ashfolio/portfolio/forecast_calculator.ex`
- `lib/ashfolio_web/helpers/format_helper.ex` (create new)
- `test/ashfolio/portfolio/forecast_calculator_test.exs`

### Stage 3: Fix Chart Formatting [HIGH - P1]
**Status**: [NOT STARTED] 
**Impact**: Professional appearance, data readability
**Timeline**: Day 3 morning (3 hours)

### TDD Tests First:

```elixir
@tag :unit
test "format_chart_axis handles millions correctly" do
  assert "$1M" = ChartHelper.format_y_axis(1_000_000)
  assert "$2.5M" = ChartHelper.format_y_axis(2_500_000)
  assert "$500K" = ChartHelper.format_y_axis(500_000)
  assert "$1K" = ChartHelper.format_y_axis(1_000)
end

@tag :unit
test "contribution impact generates distinct chart from scenarios" do
  base_contribution = Decimal.new("1000")
  impact_data = ForecastCalculator.generate_contribution_impact(base_contribution, params)
  
  assert Enum.all?(impact_data, fn item ->
    Map.has_key?(item, :contribution_delta) and
    Map.has_key?(item, :final_value)
  end)
  
  assert length(impact_data) == 6  # -1000, -500, -100, +100, +500, +1000
end
```

### Implementation Tasks:
1. Implement ChartHelper with proper number formatting
2. Create separate chart component for contribution impact
3. Fix y-axis formatter in Contex configuration
4. Ensure each tab renders its own unique chart

**Files to modify:**
- `lib/ashfolio_web/helpers/chart_helper.ex` (create new)
- `lib/ashfolio_web/live/forecast_live/contribution_chart.ex` (create new)
- `lib/ashfolio_web/live/forecast_live/index.html.heex`

### Stage 4: Add Navigation Links [MEDIUM - P1]
**Status**: [NOT STARTED]
**Impact**: Feature discoverability
**Timeline**: Day 1 afternoon (1 hour)

### TDD Tests First:

```elixir
@tag :unit
test "navigation menu includes all major features" do
  {:ok, _view, html} = live(conn, "/")
  
  assert html =~ ~r{href="/expenses/analytics"}
  assert html =~ ~r{href="/net_worth"}
  assert html =~ "Analytics"
  assert html =~ "Net Worth"
end
```

### Implementation Tasks:
1. Update navigation component in layouts
2. Add Analytics and Net Worth links
3. Test navigation from all pages
4. Consider dropdown menu for sub-features

**Files to modify:**
- `lib/ashfolio_web/components/layouts/app.html.heex`
- `lib/ashfolio_web/components/top_bar.ex`
- `test/ashfolio_web/components/navigation_test.exs` (create new)

## Phase 2: Complete v0.4.2 Features (Week 2)

### Stage 5: Implement Retirement Planning UI [MEDIUM - P2]
**Status**: [NOT STARTED]
**Impact**: Missing core v0.4.2 functionality
**Timeline**: Day 4-5 (6 hours total)

### TDD Tests First:

```elixir
@tag :unit
test "calculate 25x retirement target from annual expenses" do
  annual_expenses = Decimal.new("50000")
  expected = Decimal.new("1250000")
  
  assert {:ok, result} = RetirementCalculator.calculate_25x_target(annual_expenses)
  assert Decimal.equal?(result, expected)
end

@tag :unit
test "calculate 4% safe withdrawal rate" do
  portfolio = Decimal.new("1000000")
  expected_annual = Decimal.new("40000")
  expected_monthly = Decimal.new("3333.33")
  
  assert {:ok, annual, monthly} = RetirementCalculator.safe_withdrawal_rate(portfolio)
  assert Decimal.equal?(annual, expected_annual)
  assert Decimal.round(monthly, 2) == expected_monthly
end

@tag :liveview
test "retirement planning UI displays calculations" do
  {:ok, view, _html} = live(conn, "/retirement")
  
  assert html =~ "25x Rule"
  assert html =~ "4% Withdrawal Rate"
  assert html =~ "Retirement Target"
end
```

### Implementation Tasks:
1. Create RetirementCalculator module if not exists
2. Create RetirementLive LiveView
3. Add retirement planning to navigation
4. Integrate with existing expense and portfolio data

**Files to create:**
- `lib/ashfolio/financial_management/retirement_calculator.ex`
- `lib/ashfolio_web/live/retirement_live/index.ex`
- `lib/ashfolio_web/live/retirement_live/index.html.heex`
- `test/ashfolio/financial_management/retirement_calculator_test.exs`
- `test/ashfolio_web/live/retirement_live_test.exs`

## Detailed Timeline

### Week 1: Production Readiness
**Goal**: Fix all critical bugs blocking v0.4.3 release

**Day 1: Critical Form & Navigation**
- Morning (2h): Stage 1 - Fix goal creation form `:recommended_target` error  
- Afternoon (1h): Stage 4 - Add missing navigation links
- End of day: Goal creation working, all features accessible

**Day 2: Chart Data Accuracy**
- Morning (2h): Stage 2A - Fix growth rate formatting (0.07% → 7%)
- Morning (1h): Stage 2B - Fix initial portfolio values (start from actual value)
- Afternoon (2h): Stage 2C - Fix scenario comparison (show all 3 lines)
- End of day: Charts display accurate data

**Day 3: Chart Visualization Polish**
- Morning (1h): Stage 3A - Fix Y-axis formatting ($2BGN → $2M)
- Morning (2h): Stage 3B - Create separate contribution impact chart
- Afternoon (1h): Integration testing and bug fixes
- End of day: Professional chart appearance

### Week 2: v0.4.2 Feature Completion
**Goal**: Complete retirement planning functionality

**Day 4: Retirement Calculator**
- Morning (3h): Stage 5A - RetirementCalculator module (25x rule, 4% withdrawal)
- Afternoon (2h): Stage 5B - Retirement calculations integration
- End of day: Backend calculations complete

**Day 5: Retirement UI & Polish**
- Morning (3h): Stage 5C - RetirementLive interface and templates
- Afternoon (2h): Stage 5D - Dashboard integration and testing
- End of day: Complete v0.4.2 retirement planning

### Success Milestones
- **End of Week 1**: All v0.4.1 bugs fixed, charts working correctly
- **End of Week 2**: v0.4.2 complete with retirement planning UI
- **Production Ready**: E2E tests passing, no critical bugs

## Success Criteria

- [ ] All goal creation forms work without errors
- [ ] Charts display correct initial values
- [ ] Growth rates show as percentages
- [ ] All three scenario lines visible
- [ ] Y-axis uses proper formatting
- [ ] Contribution impact has unique chart
- [ ] Navigation includes all features
- [ ] Retirement planning UI functional
- [ ] All tests passing
- [ ] E2E testing confirms all fixes

## Notes for AI Agent

### Context
- E2E testing completed on 2025-08-28
- v0.4.3 calculations work but UI has bugs
- v0.4.2 features missing from UI entirely
- Emergency fund calculator works but goal creation broken

### Priority Order
1. Fix broken features (goal creation)
2. Fix visualization bugs
3. Add missing navigation
4. Implement missing v0.4.2 UI

### Testing Strategy
- Write tests FIRST (TDD)
- Each fix must have unit + integration tests
- Run E2E tests after each stage
- Use Playwright for final verification

### Key Files Already Modified
- `lib/ashfolio/financial_management/financial_goal.ex` - Working
- `lib/ashfolio_web/live/forecast_live.ex` - Has bugs
- `lib/ashfolio/portfolio/forecast_calculator.ex` - Calculations work

### Dependencies
- Contex for charts
- Decimal for calculations
- Phoenix LiveView 0.20+

---

## 📋 Summary for Principal Architect

### Immediate Action Required

**E2E Testing Results**: Comprehensive testing on 2025-08-28 revealed critical bugs blocking v0.4.3 production readiness.

### Task Assignment for AI Agent

Please implement these fixes using strict TDD methodology:

1. **CRITICAL**: Fix goal creation form (blocks all goal functionality)
2. **HIGH**: Fix chart visualization bugs (affects user understanding)  
3. **MEDIUM**: Add missing navigation links (discoverability issue)
4. **MEDIUM**: Implement v0.4.2 retirement planning UI

### Success Definition
- [ ] All goal creation workflows functional
- [ ] Charts display accurate data with proper formatting
- [ ] All features accessible via navigation
- [ ] E2E tests pass for all v0.4.x features

### Testing Strategy
Each fix must follow red-green-refactor:
1. Write failing test
2. Implement minimal fix  
3. Refactor and verify

Use Playwright E2E tests to verify fixes before marking complete.

**Time Estimate**: 2 weeks following TDD approach

## Next Steps After Completion

Upon successful completion of this implementation plan:

1. **v0.4.3 Release**: Focus on forecasting engine polish and advanced scenarios
2. **v0.4.4-v0.4.5**: Advanced analytics (TWR, MWR, benchmarks) per consolidated roadmap
3. **v0.5.0**: Full platform integration and AER standardization

See `CONSOLIDATED_ROADMAP.md` for complete strategic context and long-term vision.