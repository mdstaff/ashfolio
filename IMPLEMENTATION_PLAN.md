# v0.4.3 Forecasting Engine Implementation Plan

## Overview
Implement comprehensive portfolio forecasting and growth projection capabilities for long-term financial planning. Build on existing calculator patterns and integrate with retirement planning from v0.4.2.

## Stage 1: ForecastCalculator Foundation [Not Started]

**Deliverable**: Core ForecastCalculator module with basic compound growth calculations

### Tasks:
1. **TDD: Unit Tests for Basic Compound Growth** (30 min)
   - Test simple compound growth without contributions
   - Test compound growth with regular monthly contributions
   - Test edge cases (0 growth, 0 contributions, negative values)
   - Test decimal precision handling

2. **Implement ForecastCalculator Module** (45 min)
   - Follow RetirementCalculator patterns for structure
   - Implement `project_portfolio_growth/4` with compound interest formula
   - Add proper error handling and Logger.debug calls
   - Use Decimal throughout for precision

3. **TDD: Integration Tests** (30 min)
   - Test with realistic portfolio values
   - Verify calculations match financial standards
   - Test error handling paths

**Test Cases**:
```elixir
# Basic compound growth
assert {:ok, result} = ForecastCalculator.project_portfolio_growth(
  Decimal.new("100000"), # current_value
  Decimal.new("12000"),  # annual_contribution
  10,                     # years
  Decimal.new("0.07")    # 7% growth rate
)
# Expected: ~$235,000 after 10 years

# Zero growth scenario
assert {:ok, result} = ForecastCalculator.project_portfolio_growth(
  Decimal.new("100000"),
  Decimal.new("0"),
  10,
  Decimal.new("0")
)
assert Decimal.equal?(result, Decimal.new("100000"))

# Edge case validations
assert {:error, :negative_value} = ForecastCalculator.project_portfolio_growth(
  Decimal.new("-100000"),
  Decimal.new("12000"),
  10,
  Decimal.new("0.07")
)
```

**Success Criteria**:
- [ ] All unit tests passing
- [ ] Compound growth formula accurate
- [ ] Error handling comprehensive
- [ ] Decimal precision maintained

## Stage 2: Multi-Period Projections [Not Started]

**Deliverable**: Project portfolio growth over multiple time horizons (5, 10, 15, 20, 25, 30 years)

### Tasks:
1. **TDD: Multi-Period Tests** (30 min)
   - Test projection for standard periods
   - Test result structure and data format
   - Test performance with multiple calculations

2. **Implement Multi-Period Projection** (45 min)
   - Create `project_multi_period_growth/4` function
   - Return map with projections for each period
   - Include yearly breakdowns for first 5 years
   - Add compound annual growth rate (CAGR) calculation

3. **Performance Optimization** (30 min)
   - Implement memoization for repeated calculations
   - Optimize loops using Stream where appropriate
   - Add performance tests

**Test Cases**:
```elixir
# Multi-period projections
assert {:ok, projections} = ForecastCalculator.project_multi_period_growth(
  Decimal.new("100000"),
  Decimal.new("12000"),
  Decimal.new("0.07"),
  [5, 10, 15, 20, 25, 30]
)

assert Map.has_key?(projections, :year_5)
assert Map.has_key?(projections, :year_30)
assert Map.has_key?(projections, :yearly_breakdown)
assert Map.has_key?(projections, :cagr)

# Performance test
assert {time_us, {:ok, _}} = :timer.tc(fn ->
  ForecastCalculator.project_multi_period_growth(
    Decimal.new("100000"),
    Decimal.new("12000"),
    Decimal.new("0.07"),
    [5, 10, 15, 20, 25, 30]
  )
end)
assert time_us < 100_000  # Should complete in < 100ms
```

**Success Criteria**:
- [ ] Multi-period calculations working
- [ ] Performance < 100ms for 6 periods
- [ ] CAGR calculation accurate
- [ ] Yearly breakdown included

## Stage 3: Scenario Planning Engine [Not Started]

**Deliverable**: Compare multiple growth scenarios (pessimistic, realistic, optimistic)

### Tasks:
1. **TDD: Scenario Comparison Tests** (30 min)
   - Test standard scenarios (5%, 7%, 10%)
   - Test custom scenario creation
   - Test scenario comparison structure

2. **Implement Scenario Planning** (1 hour)
   - Create `calculate_scenario_projections/3` with default scenarios
   - Support custom scenario definitions
   - Include probability-weighted outcomes
   - Add financial independence calculations

3. **Integration with Retirement Calculator** (30 min)
   - Link scenarios to retirement readiness
   - Calculate years to financial independence per scenario
   - Add safe withdrawal rate projections

**Test Cases**:
```elixir
# Standard scenarios
assert {:ok, scenarios} = ForecastCalculator.calculate_scenario_projections(
  Decimal.new("100000"),
  Decimal.new("12000"),
  30
)

assert Map.has_key?(scenarios, :pessimistic)  # 5% growth
assert Map.has_key?(scenarios, :realistic)    # 7% growth
assert Map.has_key?(scenarios, :optimistic)   # 10% growth

# Custom scenarios
custom_scenarios = [
  %{name: :conservative, rate: Decimal.new("0.04")},
  %{name: :aggressive, rate: Decimal.new("0.12")}
]

assert {:ok, results} = ForecastCalculator.calculate_custom_scenarios(
  Decimal.new("100000"),
  Decimal.new("12000"),
  30,
  custom_scenarios
)

# Financial independence calculation
assert {:ok, fi_analysis} = ForecastCalculator.calculate_fi_timeline(
  Decimal.new("100000"),
  Decimal.new("12000"),
  Decimal.new("50000"), # annual expenses
  Decimal.new("0.07")
)
assert Map.has_key?(fi_analysis, :years_to_fi)
assert Map.has_key?(fi_analysis, :fi_portfolio_value)
```

**Success Criteria**:
- [ ] Standard scenarios working (5%, 7%, 10%)
- [ ] Custom scenarios supported
- [ ] FI calculations integrated
- [ ] Comparison structure clear

## Stage 4: Contribution Impact Analysis [Not Started]

**Deliverable**: Analyze impact of different contribution levels on portfolio growth

### Tasks:
1. **TDD: Contribution Analysis Tests** (30 min)
   - Test contribution sensitivity analysis
   - Test incremental contribution impact
   - Test contribution vs growth rate comparison

2. **Implement Contribution Analysis** (45 min)
   - Create `analyze_contribution_impact/4`
   - Show impact of ±$100, ±$500, ±$1000 monthly changes
   - Calculate breakeven contribution for target
   - Add time-to-goal with different contributions

3. **Create Contribution Optimizer** (30 min)
   - Calculate minimum contribution for retirement goal
   - Show trade-offs between time and contribution amount
   - Integration with retirement planning

**Test Cases**:
```elixir
# Contribution sensitivity
assert {:ok, analysis} = ForecastCalculator.analyze_contribution_impact(
  Decimal.new("100000"),
  Decimal.new("1000"), # base monthly contribution
  20, # years
  Decimal.new("0.07")
)

assert Map.has_key?(analysis, :base_projection)
assert Map.has_key?(analysis, :contribution_variations)
assert length(analysis.contribution_variations) >= 5

# Optimizer for retirement goal
assert {:ok, optimization} = ForecastCalculator.optimize_contribution_for_goal(
  Decimal.new("100000"),  # current value
  Decimal.new("1250000"), # retirement target (25x * 50k expenses)
  15, # target years
  Decimal.new("0.07")
)
assert Map.has_key?(optimization, :required_monthly_contribution)
assert Map.has_key?(optimization, :probability_of_success)
```

**Success Criteria**:
- [ ] Sensitivity analysis working
- [ ] Multiple contribution scenarios
- [ ] Optimization calculations accurate
- [ ] Integration with retirement goals

## Stage 5: UI Integration & Charts [Not Started]

**Deliverable**: LiveView components with interactive Contex charts for forecasting

### Tasks:
1. **Create ForecastingLive Module** (1 hour)
   - Follow DashboardLive patterns
   - Add PubSub subscriptions
   - Implement form for inputs
   - Handle real-time updates

2. **Implement Contex Charts** (1.5 hours)
   - Line chart for growth projections
   - Area chart for scenario comparisons
   - Bar chart for contribution impact
   - Follow existing chart patterns from dashboard

3. **Add Dashboard Widget** (30 min)
   - Create forecast summary widget
   - Show key metrics (30-year projection, FI timeline)
   - Link to full forecasting page

**Test Cases**:
```elixir
# LiveView tests
@tag :liveview
test "forecasting page loads with default values", %{conn: conn} do
  {:ok, view, html} = live(conn, "/financial_planning/forecast")
  
  assert html =~ "Portfolio Growth Projections"
  assert html =~ "Scenario Planning"
  assert html =~ "Contribution Analysis"
end

@tag :liveview
test "updating inputs recalculates projections", %{conn: conn} do
  {:ok, view, _} = live(conn, "/financial_planning/forecast")
  
  view
  |> form("#forecast-form", %{
    current_value: "150000",
    monthly_contribution: "2000",
    growth_rate: "0.08"
  })
  |> render_change()
  
  assert render(view) =~ "30-Year Projection"
  assert render(view) =~ "$" # Updated value shown
end

# Widget integration
@tag :liveview
test "forecast widget appears on dashboard", %{conn: conn} do
  {:ok, view, html} = live(conn, "/dashboard")
  
  assert html =~ "Portfolio Forecast"
  assert html =~ "Projected in 30 years"
end
```

**Success Criteria**:
- [ ] LiveView page functional
- [ ] Charts rendering correctly
- [ ] Real-time updates working
- [ ] Dashboard widget integrated

## Timeline Summary

### Week 1 (Days 1-3)
- **Day 1**: Stage 1 - ForecastCalculator Foundation (2 hours)
- **Day 2**: Stage 2 - Multi-Period Projections (2 hours)
- **Day 3**: Stage 3 - Scenario Planning Engine (2 hours)

### Week 2 (Days 4-5)
- **Day 4**: Stage 4 - Contribution Impact Analysis (2 hours)
- **Day 5**: Stage 5 - UI Integration & Charts (3 hours)

**Total Estimated Time**: 11 hours across 5 days

## Risk Mitigation

### Technical Risks
1. **Complex compound interest calculations**: Validate against online calculators and Excel
2. **Performance with 30-year projections**: Use memoization and optimize calculations
3. **Chart rendering performance**: Limit data points, use sampling for long periods

### Mitigation Strategies
- Write comprehensive tests first (TDD)
- Validate calculations against multiple sources
- Profile and optimize performance bottlenecks
- Use existing patterns from RetirementCalculator

## Definition of Done

### Overall Completion
- [ ] All 5 stages complete
- [ ] 100% test coverage for ForecastCalculator
- [ ] Performance benchmarks met (<1 second for 30-year analysis)
- [ ] UI integrated with dashboard
- [ ] Documentation complete
- [ ] Credo warnings addressed
- [ ] Manual testing of all scenarios

### Quality Gates
- All unit tests passing
- All integration tests passing
- LiveView tests functional
- Performance tests meet benchmarks
- Code follows existing patterns
- Decimal precision maintained throughout

## Next Steps After v0.4.3

**v0.4.4** - Advanced Analytics:
- Time-weighted return (TWR)
- Money-weighted return (MWR)
- Rolling returns analysis
- Performance cache implementation

**v0.4.5** - Benchmark System:
- S&P 500 comparisons
- Asset allocation analysis
- Concentration risk metrics