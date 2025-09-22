# v0.7.0 Implementation Plan - Advanced Portfolio Analytics

> Status: 100% COMPLETE ✅ | Branch: feature/v0.7.0-portfolio-analytics
> Started: September 2025 | Completed: September 2025
>
> **Completed**: Stage 1 (Risk Metrics) ✅ | Stage 2 (Correlation/Covariance) ✅ | Stage 3 (Portfolio Optimization) ✅ | Stage 4 (Advanced Analytics LiveView) ✅

## Executive Summary

Build institutional-grade portfolio analytics suite extending the existing RiskMetricsCalculator foundation with comprehensive performance analysis, correlation matrices, portfolio optimization, and factor analysis. All development follows strict TDD methodology with performance benchmarks of <100ms for all calculations.

## Current Progress (September 16, 2025)

### ✅ Completed Components

#### Stage 1: Risk Metrics Suite
- **BetaCalculator** - Portfolio systematic risk (20 tests, <25ms)
- **DrawdownCalculator** - Maximum drawdown analysis (24 tests, <15ms)
- **Enhanced RiskMetricsCalculator** - Calmar & Sterling ratios (13 new tests)

#### Stage 2: Correlation & Covariance
- **CorrelationCalculator** - Pearson correlation, matrices, rolling windows (27 tests)
- **CovarianceCalculator** - Pairwise and matrix calculations (16 tests)

**Total Tests Added**: 100 new tests
**Performance**: All calculations meet <100ms requirement
**Code Quality**: Full Decimal precision, complete type specs

#### Stage 3: Portfolio Optimization
- **PortfolioOptimizer** - Two-asset analytical optimization with Markowitz formulas (12 tests, <100ms)
- **EfficientFrontier** - Complete frontier generator with analytical and simplified approaches (12 tests, <200ms)

#### Stage 4: Advanced Analytics LiveView Dashboard
- **Interactive UI** - Efficient frontier visualization with portfolio allocations
- **Real-time Integration** - Performance cache and PubSub updates
- **Professional Styling** - Color-coded portfolio cards and comprehensive help documentation

**Total Implementation**: All 4 stages complete with 124+ tests and comprehensive LiveView integration

## 🎯 Value-Driven Success Criteria

### Professional Quality Standards
- [x] **124+ new tests**, all passing with strict TDD red/green cycles
- [x] **<100ms response time** for standard portfolios (all calculations <500ms)
- [x] **Mathematical accuracy** validated with comprehensive test suite
- [x] **Professional documentation** with formulas, references, and performance characteristics

### User Experience Excellence
- [x] **Interactive visualizations** with color-coded portfolio cards
- [x] **Real-time updates** with calculation history tracking
- [ ] **Mobile-responsive** charts and analytics panels (partially tested)
- [x] **Error handling** with graceful degradation for edge cases

### Technical Integration
- [x] **Seamless integration** with existing AdvancedAnalyticsLive
- [x] **Code GPS validation** showing proper module integration
- [x] **Performance monitoring** with ETS caching for expensive operations
- [x] **Zero compilation warnings** and full Decimal precision

### Business Value Delivery
- [x] **Portfolio rebalancing recommendations** based on efficient frontier analysis
- [x] **Risk assessment dashboard** showing beta, drawdown, and correlation metrics
- [x] **Professional-grade analytics** suitable for CFP/CPA financial planning use
- [ ] **Export capabilities** for client reporting and compliance documentation (future)

---

## Stage 1: Complete Risk Metrics Suite [COMPLETE] ✅

**Deliverable**: Enhanced risk metrics beyond current Sharpe/Sortino implementation

**Pre-Implementation Setup**:
1. Create test file: `test/ashfolio/portfolio/calculators/beta_calculator_test.exs`
2. Create test file: `test/ashfolio/portfolio/calculators/drawdown_calculator_test.exs`
3. Create fixture file: `test/support/market_data_fixtures.ex` with S&P 500 sample data
4. Review existing: `lib/ashfolio/portfolio/calculators/risk_metrics_calculator.ex` for patterns

**TDD Test Specifications**:
```elixir
# Beta Calculation Tests
test "calculates beta of 1.0 for market portfolio" do
  market_returns = generate_market_returns()
  portfolio_returns = market_returns  # Identical to market

  {:ok, result} = BetaCalculator.calculate(portfolio_returns, market_returns)
  assert_in_delta(result.beta, 1.0, 0.01)
end

test "identifies high-beta growth stocks correctly" do
  market_returns = generate_market_returns(volatility: 0.15)
  portfolio_returns = generate_returns(volatility: 0.30, correlation: 0.8)

  {:ok, result} = BetaCalculator.calculate(portfolio_returns, market_returns)
  assert D.compare(result.beta, D.new("1.5")) == :gt
end

test "identifies defensive stocks with beta < 0.7" do
  market_returns = generate_market_returns()
  utility_returns = generate_defensive_returns()

  {:ok, result} = BetaCalculator.calculate(utility_returns, market_returns)
  assert D.compare(result.beta, D.new("0.7")) == :lt
end

# Enhanced Sharpe/Sortino Tests
test "returns negative Sharpe for underperforming portfolio" do
  losing_returns = Enum.map(1..12, fn _ -> D.new("-0.02") end)

  {:ok, result} = RiskMetricsCalculator.calculate_sharpe(losing_returns)
  assert D.compare(result.sharpe_ratio, D.new("0")) == :lt
end

test "Sortino exceeds Sharpe when upside volatility dominates" do
  growth_returns = [D.new("0.15"), D.new("-0.02"), D.new("0.20"), D.new("0.25")]

  {:ok, sharpe} = RiskMetricsCalculator.calculate_sharpe(growth_returns)
  {:ok, sortino} = RiskMetricsCalculator.calculate_sortino(growth_returns)
  assert D.compare(sortino.ratio, sharpe.ratio) == :gt
end

# Maximum Drawdown Analysis
test "calculates 2008 financial crisis drawdown accurately" do
  crisis_values = generate_2008_crisis_values()  # -55% peak to trough

  {:ok, result} = DrawdownCalculator.calculate(crisis_values)
  assert_in_delta(D.to_float(result.max_drawdown), 0.55, 0.02)
  assert result.recovery_months == 18
  assert result.drawdown_duration_months == 6
end
```

**Detailed Implementation Tasks**:

1. **Create BetaCalculator Module** (`lib/ashfolio/portfolio/calculators/beta_calculator.ex`)
   ```elixir
   # Step 1: Write failing test for basic beta calculation
   # Step 2: Implement calculate/2 function with formula:
   #   Beta = Covariance(Portfolio, Market) / Variance(Market)
   # Step 3: Add error handling for insufficient data (<2 returns)
   # Step 4: Add calculate_rolling_beta/3 for time windows
   ```

2. **Enhance RiskMetricsCalculator** (`lib/ashfolio/portfolio/calculators/risk_metrics_calculator.ex`)
   ```elixir
   # Add to existing module:
   def calculate_calmar_ratio(returns, max_drawdown)
   def calculate_sterling_ratio(returns, average_drawdown)
   def calculate_treynor_ratio(returns, beta, risk_free_rate)
   ```

3. **Create DrawdownCalculator** (`lib/ashfolio/portfolio/calculators/drawdown_calculator.ex`)
   ```elixir
   # Core functions needed:
   def calculate_max_drawdown(values)  # Returns %{drawdown: Decimal, peak_date: Date, trough_date: Date}
   def calculate_drawdown_duration(values)  # Returns days from peak to trough
   def calculate_recovery_time(values)  # Returns days from trough to recovery
   def calculate_underwater_chart(values)  # Returns time series of drawdowns
   ```

4. **Create Market Data Fixtures** (`test/support/market_data_fixtures.ex`)
   ```elixir
   def sp500_2008_crisis_data() do
     # Oct 2007 peak: 1565.15
     # Mar 2009 trough: 676.53 (-56.8%)
     # Return actual daily values
   end

   def generate_market_returns(opts \\ []) do
     volatility = Keyword.get(opts, :volatility, 0.15)
     mean = Keyword.get(opts, :mean, 0.10)
     # Use Box-Muller transform for normal distribution
   end
   ```

**Assertions Strategy**:
- Use `assert_in_delta` for floating point comparisons with 0.01 tolerance
- Validate all edge cases: empty data returns `{:error, :insufficient_data}`
- Test with known historical events using exact values from Yahoo Finance
- Ensure all Decimal operations use `D.new()` for precision

---

## Stage 2: Correlation & Covariance Analysis [COMPLETE]

**Deliverable**: Full correlation matrix with visualization components

**Status**: Complete ✅
**Completion Date**: 2025-09-15

**Implementation Summary**:
Successfully implemented both CorrelationCalculator and CovarianceCalculator with comprehensive test coverage and excellent performance.

**Final Metrics**:
- **CorrelationCalculator** (`lib/ashfolio/portfolio/calculators/correlation_calculator.ex`):
  - 27 tests passing (22 unit + 5 doctests)
  - Performance: <100ms for 10x10 matrix, <10ms for 1000 data points
  - Features: Pairwise correlation, full matrix, rolling correlation windows
- **CovarianceCalculator** (`lib/ashfolio/portfolio/calculators/covariance_calculator.ex`):
  - 16 tests passing (13 unit + 3 doctests)
  - Performance: <100ms for 10x10 matrix, <10ms for 1000 data points
  - Features: Pairwise covariance, symmetric matrix generation

**Technical Achievements**:
- ✅ Full Decimal precision throughout (no Float usage)
- ✅ Complete type specifications for dialyzer
- ✅ Newton's method for square root calculations
- ✅ Symmetric matrix enforcement
- ✅ Comprehensive error handling (mismatched lengths, zero variance, etc.)
- ✅ Rolling correlation windows for time series analysis

**TDD Test Specifications**:
```elixir
# Correlation Matrix Tests
test "returns identity matrix for single asset" do
  returns = [generate_returns()]

  {:ok, matrix} = CorrelationCalculator.calculate_matrix(returns)
  assert matrix == [[D.new("1.0")]]
end

test "calculates perfect correlation for identical assets" do
  returns_a = generate_returns()
  returns_b = returns_a  # Identical

  {:ok, correlation} = CorrelationCalculator.calculate_pair(returns_a, returns_b)
  assert D.compare(correlation, D.new("1.0")) == :eq
end

test "identifies negative correlation for inverse ETFs" do
  spy_returns = generate_spy_returns()
  inverse_returns = Enum.map(spy_returns, &D.mult(&1, D.new("-1")))

  {:ok, correlation} = CorrelationCalculator.calculate_pair(spy_returns, inverse_returns)
  assert_in_delta(D.to_float(correlation), -1.0, 0.01)
end

test "ensures correlation matrix symmetry" do
  portfolio_returns = generate_multi_asset_returns(5)

  {:ok, matrix} = CorrelationCalculator.calculate_matrix(portfolio_returns)

  for i <- 0..4, j <- 0..4 do
    assert Enum.at(Enum.at(matrix, i), j) == Enum.at(Enum.at(matrix, j), i)
  end
end

# Visualization Tests
test "renders correlation heatmap with proper gradients" do
  {:ok, view, _html} = live(conn, ~p"/analytics/correlation")

  html = render(view)
  assert html =~ "correlation-heatmap"
  assert html =~ "data-min=\"-1\""
  assert html =~ "data-max=\"1\""
  assert html =~ "gradient-negative"  # Red for negative
  assert html =~ "gradient-positive"  # Green for positive
end
```

**Detailed Implementation Tasks**:

1. **Create CorrelationCalculator** (`lib/ashfolio/portfolio/analytics/correlation_calculator.ex`)
   ```elixir
   defmodule Ashfolio.Portfolio.Analytics.CorrelationCalculator do
     alias Decimal, as: D

     # Core functions:
     def calculate_pair(returns_a, returns_b) do
       # Step 1: Calculate means
       # Step 2: Calculate covariance: Σ((x - mean_x)(y - mean_y)) / (n - 1)
       # Step 3: Calculate standard deviations
       # Step 4: Correlation = covariance / (std_dev_a * std_dev_b)
     end

     def calculate_matrix(asset_returns_list) do
       # Returns List of Lists for n x n correlation matrix
       # Ensure symmetry: matrix[i][j] == matrix[j][i]
     end

     def calculate_rolling_correlation(returns_a, returns_b, window_size) do
       # Returns time series of correlations
     end
   end
   ```

2. **Create Correlation Heatmap Component** (`lib/ashfolio_web/live/components/correlation_heatmap.ex`)
   ```elixir
   defmodule AshfolioWeb.Components.CorrelationHeatmap do
     use Phoenix.Component

     attr :matrix, :list, required: true
     attr :labels, :list, required: true

     def render(assigns) do
       ~H"""
       <div class="correlation-heatmap" data-min="-1" data-max="1">
         <svg viewBox="0 0 500 500">
           <%= for {row, i} <- Enum.with_index(@matrix) do %>
             <%= for {value, j} <- Enum.with_index(row) do %>
               <rect
                 x={j * 50}
                 y={i * 50}
                 width="50"
                 height="50"
                 fill={color_for_correlation(value)}
                 phx-hook="Tooltip"
                 data-tooltip={"#{@labels[i]} vs #{@labels[j]}: #{value}"}
               />
             <% end %>
           <% end %>
         </svg>
       </div>
       """
     end

     defp color_for_correlation(value) when value < 0, do: "gradient-negative"
     defp color_for_correlation(value) when value > 0, do: "gradient-positive"
     defp color_for_correlation(_), do: "white"
   end
   ```

3. **Integration with AdvancedAnalyticsLive** (`lib/ashfolio_web/live/advanced_analytics_live/index.ex`)
   ```elixir
   # Add to existing handle_event callbacks:
   def handle_event("calculate_correlation", params, socket) do
     positions = socket.assigns.positions
     correlation_matrix = CorrelationCalculator.calculate_matrix(positions)
     {:noreply, assign(socket, correlation_matrix: correlation_matrix)}
   end
   ```

**Mathematical Validation Points**:
- Pearson correlation formula: r = Σ((x - x̄)(y - ȳ)) / √(Σ(x - x̄)² * Σ(y - ȳ)²)
- Correlation bounds: -1 ≤ r ≤ 1
- Matrix diagonal must equal 1.0 (asset correlation with itself)
- Matrix must be symmetric: corr(A,B) = corr(B,A)

**Performance Optimization Notes**:
- Pre-calculate means to avoid redundant computation
- Use Enum.reduce for single-pass variance calculation
- Consider caching correlation matrices with ETS for large portfolios
- Target: <50ms for 50x50 matrix calculation

---

## Stage 3: Portfolio Optimization (Efficient Frontier) [REFINED TDD PLAN - ARCHITECT APPROVED]

**Deliverable**: Two-to-three asset analytical optimization with efficient frontier visualization
**Timeline**: 4 weeks (October-November 2025)
**Value Proposition**: Foundation for portfolio optimization with clear mathematical validation
**Scope Refinement**: Focus on analytical solutions for 2-3 assets, defer multi-asset to v0.8.0

### 🎯 Sprint 1: Core Mathematical Foundation (Week 1)

**Focus**: Build robust two-asset optimization with analytical solutions (no matrix operations)

#### Task 3.1: Two-Asset Portfolio Optimizer - Analytical Solution (3 days)

##### Task 3.1.1: Basic Two-Asset Optimization (Day 1)
**RED** → Write failing test for analytical two-asset solution
```elixir
test "two asset portfolio finds analytical optimum" do
  # Asset A: 12% return, 20% volatility
  # Asset B: 8% return, 15% volatility
  # Correlation: 0.3 (known academic example)

  assets = [
    %{symbol: "AAPL", expected_return: D.new("0.12"), volatility: D.new("0.20")},
    %{symbol: "TSLA", expected_return: D.new("0.08"), volatility: D.new("0.15")}
  ]
  correlation_matrix = [[D.new("1.0"), D.new("0.3")], [D.new("0.3"), D.new("1.0")]]

  {:ok, result} = PortfolioOptimizer.optimize_two_asset(assets, correlation_matrix)

  # Expected: 73% Asset A, 27% Asset B (from Markowitz equations)
  assert_in_delta(D.to_float(result.weights.aapl), 0.73, 0.02)
  assert_in_delta(D.to_float(result.weights.tsla), 0.27, 0.02)
  assert D.equal?(D.add(result.weights.aapl, result.weights.tsla), D.new("1.0"))
end
```

**GREEN** → Implement analytical solution (no quadratic programming needed)
```elixir
# Formula: w1 = (σ₂² - σ₁σ₂ρ) / (σ₁² + σ₂² - 2σ₁σ₂ρ)
def optimize_two_asset(assets, correlation_matrix) do
  # Direct analytical solution from Markowitz theory
end
```

#### Task 3.2: Minimum Variance Portfolio (2 days)
**RED** → Test minimum variance calculation
```elixir
test "finds global minimum variance portfolio" do
  # 3-asset portfolio with known minimum variance solution
  assets = load_three_asset_test_case()

  {:ok, min_var} = PortfolioOptimizer.find_minimum_variance(assets)

  # Should have lowest possible volatility
  assert D.compare(min_var.volatility, D.new("0.12")) == :eq  # Known result
  assert Enum.all?(min_var.weights, &(D.compare(&1, D.new("0")) != :lt))  # No shorts
end
```

**GREEN** → Implement using inverse covariance matrix method

#### Task 3.3: Target Return Optimizer (3 days)
**RED** → Test constrained optimization with target return
**GREEN** → Implement Lagrange multiplier solution
**REFACTOR** → Extract common matrix operations

### 🎯 Sprint 2: Efficient Frontier Engine (Week 2)

**Focus**: Generate complete efficient frontier curve with 50+ optimal portfolios

#### Task 3.4: Frontier Point Generator (3 days)
**RED** → Test frontier completeness and shape validation
```elixir
test "generates complete efficient frontier curve" do
  assets = load_diversified_test_portfolio(5)  # 5 different asset classes

  {:ok, frontier} = EfficientFrontier.generate(assets, points: 50)

  assert length(frontier.portfolios) == 50

  # Validate frontier shape (concave, upward sloping generally)
  sorted_by_risk = Enum.sort_by(frontier.portfolios, &D.to_float(&1.volatility))
  returns = Enum.map(sorted_by_risk, &D.to_float(&1.expected_return))

  # Check for general upward trend (allowing for some variation)
  upward_trends = count_upward_segments(returns)
  assert upward_trends > 40  # Most segments should trend upward
end
```

**GREEN** → Build frontier generator with validated academic test cases
**REFACTOR** → Optimize for 50x50 matrix performance

#### Task 3.5: Sharpe Ratio Maximizer (2 days)
**RED** → Test maximum Sharpe ratio identification
**GREEN** → Implement tangency portfolio finder
**REFACTOR** → Cache expensive covariance calculations

### 🎯 Sprint 3: Professional Visualizations & Integration (Week 3)

**Focus**: Interactive efficient frontier charts and portfolio analytics integration

#### Task 3.6: Efficient Frontier Chart Component (3 days)
**RED** → Test SVG chart rendering with real data
```elixir
test "renders professional efficient frontier chart" do
  frontier_data = generate_test_frontier()

  assigns = %{frontier: frontier_data, current_portfolio: test_portfolio()}
  html = rendered_to_string(EfficientFrontierChart.render(assigns))

  # Validate chart elements
  assert html =~ "efficient-frontier-curve"
  assert html =~ "current-portfolio-marker"
  assert html =~ "tangency-portfolio"
  assert html =~ "minimum-variance-portfolio"

  # Check axis labels and scales
  assert html =~ "Volatility (%)"
  assert html =~ "Expected Return (%)"
end
```

**GREEN** → Build interactive SVG component with hover tooltips
**REFACTOR** → Add professional styling and responsive design

#### Task 3.7: Advanced Analytics Integration (2 days)
**RED** → Test optimization recommendations in LiveView
**GREEN** → Integrate with existing AdvancedAnalyticsLive
**REFACTOR** → Add performance monitoring and error handling

**TDD Test Specifications**:
```elixir
# Mean-Variance Optimization Tests
test "finds optimal weights for two-asset portfolio" do
  # Classic example: Stock A (15% return, 20% vol), Stock B (10% return, 15% vol), correlation 0.3
  stock_a = %{expected_return: D.new("0.15"), volatility: D.new("0.20")}
  stock_b = %{expected_return: D.new("0.10"), volatility: D.new("0.15")}
  correlation = D.new("0.3")

  {:ok, weights} = PortfolioOptimizer.optimize([stock_a, stock_b], correlation)

  assert_in_delta(D.to_float(weights.stock_a), 0.65, 0.05)  # Known optimal
  assert_in_delta(D.to_float(weights.stock_b), 0.35, 0.05)
  assert D.compare(D.add(weights.stock_a, weights.stock_b), D.new("1.0")) == :eq
end

test "enforces no short-selling constraint" do
  assets = generate_test_assets(5)

  {:ok, weights} = PortfolioOptimizer.optimize(assets, constraints: [:no_short])

  Enum.each(weights, fn w ->
    assert D.compare(w, D.new("0")) in [:gt, :eq]
  end)
end

test "identifies minimum variance portfolio" do
  assets = generate_diverse_assets()

  {:ok, min_var} = PortfolioOptimizer.find_minimum_variance(assets)
  {:ok, random} = PortfolioOptimizer.random_portfolio(assets)

  assert D.compare(min_var.volatility, random.volatility) == :lt
end

# Efficient Frontier Tests
test "generates sufficient frontier points" do
  assets = generate_test_assets(10)

  {:ok, frontier} = EfficientFrontier.calculate(assets)

  assert length(frontier.points) >= 50

  # Frontier should be upward sloping (more risk = more return generally)
  sorted = Enum.sort_by(frontier.points, & &1.volatility)
  returns = Enum.map(sorted, & &1.expected_return)

  assert returns == Enum.sort(returns)
end

test "maximum Sharpe ratio portfolio on frontier" do
  assets = generate_test_assets(5)
  risk_free_rate = D.new("0.045")

  {:ok, max_sharpe} = PortfolioOptimizer.maximize_sharpe(assets, risk_free_rate)
  {:ok, frontier} = EfficientFrontier.calculate(assets)

  # Max Sharpe should be on the frontier
  on_frontier = Enum.any?(frontier.points, fn point ->
    D.compare(point.sharpe_ratio, max_sharpe.sharpe_ratio) == :eq
  end)

  assert on_frontier
end
```

**Detailed Implementation Tasks**:

1. **Portfolio Optimizer Core** (`lib/ashfolio/portfolio/optimization/portfolio_optimizer.ex`)
   ```elixir
   defmodule Ashfolio.Portfolio.Optimization.PortfolioOptimizer do
     alias Decimal, as: D

     @doc """
     Solves the Markowitz mean-variance optimization problem.
     Uses quadratic programming: minimize w'Σw subject to w'μ = target_return, w'1 = 1
     """
     def optimize(assets, opts \\ []) do
       # Step 1: Build covariance matrix Σ from asset returns
       # Step 2: Extract expected returns vector μ
       # Step 3: Set up constraint matrix A and vector b
       #   - Sum of weights = 1
       #   - No short selling (w_i >= 0) if specified
       #   - Position limits if specified
       # Step 4: Solve using Lagrange multipliers or simplex
       # Step 5: Return {:ok, %{weights: [...], expected_return: D, volatility: D}}
     end

     def find_minimum_variance(assets) do
       # Special case: minimize variance without return constraint
       # Analytical solution exists for unconstrained case
     end

     def maximize_sharpe(assets, risk_free_rate) do
       # Find portfolio with maximum (return - rf) / volatility
       # Iterate through return targets to find optimal
     end
   end
   ```

2. **Efficient Frontier Calculator** (`lib/ashfolio/portfolio/optimization/efficient_frontier.ex`)
   ```elixir
   defmodule Ashfolio.Portfolio.Optimization.EfficientFrontier do
     @doc """
     Generates 50+ points along the efficient frontier.
     Each point represents optimal portfolio for given return target.
     """
     def calculate(assets, opts \\ []) do
       points = Keyword.get(opts, :points, 50)

       # Step 1: Find minimum variance portfolio
       # Step 2: Find maximum return portfolio
       # Step 3: Create return targets between min and max
       # Step 4: For each target, optimize portfolio
       # Step 5: Return list of %{weights: [...], return: D, volatility: D, sharpe: D}
     end

     def find_tangency_portfolio(frontier, risk_free_rate) do
       # Portfolio where Capital Market Line is tangent to frontier
       # Has maximum Sharpe ratio
     end
   end
   ```

3. **Constraint Handler** (`lib/ashfolio/portfolio/optimization/constraint_handler.ex`)
   ```elixir
   defmodule Ashfolio.Portfolio.Optimization.ConstraintHandler do
     @doc "Validates and applies portfolio constraints"
     def apply_constraints(weights, constraints) do
       weights
       |> ensure_sum_to_one()
       |> apply_no_short_selling()
       |> apply_position_limits(constraints[:position_limits])
       |> apply_sector_constraints(constraints[:sector_limits])
     end

     defp ensure_sum_to_one(weights) do
       total = Enum.reduce(weights, D.new("0"), &D.add/2)
       if D.compare(total, D.new("1.0")) != :eq do
         # Normalize weights
         Enum.map(weights, &D.div(&1, total))
       else
         weights
       end
     end
   end
   ```

4. **Efficient Frontier Visualization** (`lib/ashfolio_web/live/components/efficient_frontier_chart.ex`)
   ```elixir
   def render(assigns) do
     ~H"""
     <div class="efficient-frontier-chart">
       <svg viewBox="0 0 600 400">
         <!-- Draw axes -->
         <line x1="50" y1="350" x2="550" y2="350" stroke="black" />
         <line x1="50" y1="50" x2="50" y2="350" stroke="black" />

         <!-- Plot frontier curve -->
         <polyline
           points={format_frontier_points(@frontier_data)}
           fill="none"
           stroke="blue"
           stroke-width="2"
         />

         <!-- Mark special portfolios -->
         <circle cx={@min_variance.x} cy={@min_variance.y} r="5" fill="green" />
         <circle cx={@max_sharpe.x} cy={@max_sharpe.y} r="5" fill="red" />

         <!-- Capital Market Line -->
         <line
           x1="50"
           y1={risk_free_y()}
           x2={@tangency.x}
           y2={@tangency.y}
           stroke="orange"
           stroke-dasharray="5,5"
         />
       </svg>
     </div>
     """
   end
   ```

**Mathematical Implementation Notes**:
- Lagrange multiplier method for constrained optimization
- Matrix operations require careful Decimal handling
- Consider using NIFs for performance-critical matrix operations
- Validate against Excel Solver or Python cvxpy results

**Known Test Cases from Literature**:
- Markowitz (1952): Two-asset example with exact solutions
- CFA Level III curriculum: Three-asset optimization problems
- Validate frontier shape is concave (risk-return tradeoff)

---

## Stage 4: Advanced Analytics LiveView Dashboard [COMPLETE] ✅

**Deliverable**: Professional interactive analytics dashboard with real-time portfolio insights
**Timeline**: Completed September 21, 2025
**Value Proposition**: Transform complex analytics into actionable portfolio management interface

**Implementation Summary**:
Successfully integrated all portfolio analytics into a unified LiveView dashboard with:
- ✅ Efficient Frontier visualization with 3 portfolio cards (Min Variance, Tangency, Max Return)
- ✅ N-asset tangency portfolio via frontier sampling approximation (99% accuracy)
- ✅ Real-time TWR/MWR calculations with caching
- ✅ Risk Metrics Suite (Sharpe, Sortino, Drawdown, VaR)
- ✅ Rolling Returns Analysis (12-month periods)
- ✅ Performance Cache with statistics display
- ✅ Calculation history tracking
- ✅ Professional UI with consistent button styling
- ✅ Sub-second performance for all calculations

**Key Achievement**: Fixed missing Tangency Portfolio display by implementing approximation algorithm for N-asset portfolios using multiple candidate generation strategies.

### 🎯 Sprint 1: Interactive Dashboard Foundation (Week 1)

#### Task 4.1: Portfolio Analytics Live Integration (3 days)
**RED** → Test comprehensive analytics dashboard loading
```elixir
test "loads complete portfolio analytics dashboard" do
  {:ok, view, html} = live(conn, ~p"/analytics/portfolio")

  # Verify all analytics sections are present
  assert html =~ "risk-metrics-panel"
  assert html =~ "correlation-heatmap"
  assert html =~ "efficient-frontier-chart"
  assert html =~ "portfolio-composition"

  # Check real-time data loading
  assert view.assigns.portfolio_data
  assert view.assigns.risk_metrics
  assert length(view.assigns.correlation_matrix) > 0
end
```

**GREEN** → Integrate all Stage 1-3 calculators into unified dashboard
**REFACTOR** → Optimize data loading with async operations

#### Task 4.2: Real-Time Risk Monitoring (2 days)
**RED** → Test live risk metric updates
**GREEN** → Implement PubSub updates for portfolio changes
**REFACTOR** → Add performance caching for expensive calculations

### 🎯 Sprint 2: Advanced Visualizations (Week 2)

#### Task 4.3: Interactive Correlation Heatmap (3 days)
**RED** → Test dynamic correlation visualization
```elixir
test "renders interactive correlation heatmap" do
  portfolio = create_diversified_test_portfolio()

  {:ok, view, _} = live(conn, ~p"/analytics/correlation")

  html = element(view, "[data-test='correlation-heatmap']") |> render()

  # Validate heatmap structure
  assert html =~ "correlation-cell"
  assert html =~ "data-correlation="
  assert html =~ "tooltip-trigger"

  # Test interactivity
  html = element(view, "[data-symbol='AAPL'][data-symbol-y='TSLA']") |> render_hover()
  assert html =~ "Correlation: 0.65"
end
```

**GREEN** → Build professional SVG heatmap with hover interactions
**REFACTOR** → Add color scaling and responsive design

#### Task 4.4: Performance Attribution Widget (2 days)
**RED** → Test sector and asset attribution breakdown
**GREEN** → Implement attribution calculations and visualization
**REFACTOR** → Add drill-down capabilities

**TDD Test Specifications**:
```elixir
# Factor Analysis Tests (Fama-French Three-Factor Model)
test "identifies value factor loading for value stocks" do
  value_returns = generate_value_stock_returns()
  factors = load_fama_french_factors()

  {:ok, loadings} = FactorAnalysis.calculate_loadings(value_returns, factors)

  assert D.compare(loadings.hml, D.new("0.3")) == :gt  # High-minus-low (value factor)
  assert D.compare(loadings.smb, D.new("0")) == :gt   # Small-minus-big (size factor)
end

test "growth stocks show negative value loading" do
  growth_returns = generate_growth_stock_returns()
  factors = load_fama_french_factors()

  {:ok, loadings} = FactorAnalysis.calculate_loadings(growth_returns, factors)

  assert D.compare(loadings.hml, D.new("0")) == :lt  # Negative value loading
end

test "small-cap shows positive size factor" do
  small_cap_returns = generate_small_cap_returns()
  factors = load_fama_french_factors()

  {:ok, loadings} = FactorAnalysis.calculate_loadings(small_cap_returns, factors)

  assert D.compare(loadings.smb, D.new("0.5")) == :gt  # Strong size loading
end

# Performance Attribution Tests
test "attribution components sum to total return" do
  portfolio = generate_test_portfolio()
  benchmark = generate_benchmark_returns()

  {:ok, attribution} = PerformanceAttribution.calculate(portfolio, benchmark)

  components_sum = attribution
    |> Map.values()
    |> Enum.reduce(D.new("0"), &D.add/2)

  assert D.compare(components_sum, attribution.total_return) == :eq
end

test "sector attribution for diversified portfolio" do
  portfolio = generate_sector_diversified_portfolio()

  {:ok, attribution} = PerformanceAttribution.sector_attribution(portfolio)

  assert Map.has_key?(attribution, :technology)
  assert Map.has_key?(attribution, :healthcare)
  assert Map.has_key?(attribution, :financials)

  # Verify sector weights sum to 100%
  total_weight = attribution
    |> Map.values()
    |> Enum.map(& &1.weight)
    |> Enum.reduce(D.new("0"), &D.add/2)

  assert D.compare(total_weight, D.new("1.0")) == :eq
end
```

**Implementation Tasks**:
- [ ] Implement multi-factor regression analysis
- [ ] Create Fama-French factor loader
- [ ] Build Carhart four-factor model support
- [ ] Implement Brinson attribution model
- [ ] Add sector and asset class attribution
- [ ] Create attribution visualization components

**Assertions Strategy**:
- Validate factor loadings against academic research
- Ensure attribution completeness (sums to total)
- Test with known factor portfolios (value, growth, small-cap)
- Performance: <200ms for factor analysis

---

## Stage 5: Benchmark Comparison & Relative Performance [NOT STARTED]

**Deliverable**: Comprehensive benchmark comparison with tracking analytics

**TDD Test Specifications**:
```elixir
# Benchmark Integration Tests
test "S&P 500 historical return approximately 10%" do
  sp500_data = load_historical_sp500(years: 30)

  {:ok, metrics} = BenchmarkAnalyzer.analyze(sp500_data)

  assert_in_delta(D.to_float(metrics.annualized_return), 0.10, 0.02)
  assert_in_delta(D.to_float(metrics.volatility), 0.15, 0.03)
end

test "calculates tracking error for index fund" do
  index_fund_returns = generate_index_fund_returns()
  sp500_returns = generate_sp500_returns()

  {:ok, tracking} = BenchmarkComparison.tracking_error(index_fund_returns, sp500_returns)

  assert D.compare(tracking.error, D.new("0.02")) == :lt  # Less than 2%
  assert_in_delta(D.to_float(tracking.correlation), 0.99, 0.01)
end

# Relative Performance Tests
test "calculates information ratio for active management" do
  active_returns = generate_active_manager_returns()
  benchmark_returns = generate_benchmark_returns()

  {:ok, info_ratio} = RelativeMetrics.information_ratio(active_returns, benchmark_returns)

  # Good active managers have IR > 0.5
  assert D.compare(info_ratio.value, D.new("0.5")) == :gt
end

test "up/down capture ratios for outperforming fund" do
  fund_returns = generate_outperforming_returns()
  market_returns = generate_market_returns()

  {:ok, capture} = RelativeMetrics.capture_ratios(fund_returns, market_returns)

  assert D.compare(capture.up_capture, D.new("1.1")) == :gt    # Captures >110% of upside
  assert D.compare(capture.down_capture, D.new("0.9")) == :lt  # Captures <90% of downside

  # Capture ratio > 1 indicates outperformance
  capture_ratio = D.div(capture.up_capture, capture.down_capture)
  assert D.compare(capture_ratio, D.new("1.0")) == :gt
end

test "rolling window performance comparison" do
  portfolio = generate_portfolio_returns(days: 365)
  benchmark = generate_benchmark_returns(days: 365)

  {:ok, rolling} = RelativeMetrics.rolling_comparison(portfolio, benchmark, window: 30)

  assert length(rolling.periods) == 335  # 365 - 30
  assert Enum.all?(rolling.periods, & &1.excess_return)
end
```

**Implementation Tasks**:
- [ ] Create benchmark data integration (S&P 500, AGG, etc.)
- [ ] Implement tracking error and correlation analysis
- [ ] Build information ratio calculator
- [ ] Create up/down capture ratio analysis
- [ ] Add rolling performance windows
- [ ] Implement custom benchmark support

**Assertions Strategy**:
- Validate against published benchmark returns
- Test tracking error for known index funds
- Ensure capture ratios are mathematically consistent
- Performance: <100ms for year of daily data

---

## LiveView Integration Requirements

```elixir
# Advanced Analytics Live enhancements
test "displays all portfolio analytics sections" do
  {:ok, view, html} = live(conn, ~p"/analytics/portfolio")

  assert html =~ "Risk Metrics"
  assert html =~ "Correlation Matrix"
  assert html =~ "Efficient Frontier"
  assert html =~ "Factor Analysis"
  assert html =~ "Benchmark Comparison"
end

test "updates analytics on period change" do
  {:ok, view, _} = live(conn, ~p"/analytics/portfolio")

  html = render_change(view, :period_change, %{period: "YTD"})

  assert html =~ "Period: Year to Date"
  assert html =~ "data-period=\"YTD\""
end

test "exports analytics data as CSV" do
  {:ok, view, _} = live(conn, ~p"/analytics/portfolio")

  {:ok, csv} = render_click(view, :export, %{format: "csv"})

  assert csv =~ "Sharpe Ratio"
  assert csv =~ "Beta"
  assert csv =~ "Correlation Matrix"
end
```

---

## Performance Benchmarks

All calculations must meet these performance targets:

```elixir
test "risk metrics calculation under 100ms" do
  portfolio = generate_large_portfolio(positions: 1000)

  {time, {:ok, _result}} = :timer.tc(fn ->
    RiskMetricsCalculator.calculate_all(portfolio)
  end)

  assert time < 100_000  # microseconds
end

test "correlation matrix under 50ms for 50x50" do
  returns = generate_multi_asset_returns(50)

  {time, {:ok, _matrix}} = :timer.tc(fn ->
    CorrelationCalculator.calculate_matrix(returns)
  end)

  assert time < 50_000
end

test "portfolio optimization under 500ms" do
  assets = generate_test_assets(20)

  {time, {:ok, _weights}} = :timer.tc(fn ->
    PortfolioOptimizer.optimize(assets)
  end)

  assert time < 500_000
end
```

---

## Module Architecture

```
lib/ashfolio/portfolio/analytics/
├── calculators/
│   ├── beta_calculator.ex
│   ├── correlation_calculator.ex
│   ├── drawdown_calculator.ex
│   ├── factor_analysis.ex
│   └── performance_attribution.ex
├── optimization/
│   ├── portfolio_optimizer.ex
│   ├── efficient_frontier.ex
│   └── constraint_handler.ex
├── benchmarks/
│   ├── benchmark_analyzer.ex
│   ├── relative_metrics.ex
│   └── tracking_analytics.ex
└── services/
    └── analytics_aggregator.ex

lib/ashfolio_web/live/
└── advanced_analytics_live/
    ├── components/
    │   ├── correlation_heatmap.ex
    │   ├── efficient_frontier_chart.ex
    │   ├── factor_loading_chart.ex
    │   └── attribution_breakdown.ex
    └── index.ex (enhanced)
```

---

## Risk Mitigation Strategy

1. **Algorithm Complexity**: Start with simple metrics before optimization algorithms
2. **Validation**: Use well-known test cases from CFA curriculum and academic papers
3. **Cross-Validation**: Compare results with Python (numpy/pandas) implementations
4. **Performance**: Profile and optimize critical paths early
5. **Failure Recovery**: Maximum 3 attempts per algorithm implementation before reassessment

---

## Documentation Requirements

Each calculator must include:
- Mathematical formula in module documentation
- Academic references (papers, textbooks)
- Example calculations with expected outputs
- Edge case handling documentation
- Performance characteristics

---

## Completion Criteria

- [x] All 4 primary stages complete with tests passing (Stage 5 deferred to v0.8.0)
- [x] 124+ tests added, 100% passing
- [x] Performance benchmarks met (<500ms for all operations)
- [x] LiveView integration complete with visualizations
- [x] Documentation includes all formulas and references
- [x] Code GPS shows proper integration
- [x] Ready for v0.7.0 release ✅

---

## Common Pitfalls to Avoid

1. **Decimal Precision Issues**
   - NEVER use Float for financial calculations
   - Always use `Decimal.new()` for all numeric inputs
   - Be careful with division by zero in ratios

2. **Matrix Operation Errors**
   - Ensure matrix dimensions match before operations
   - Handle singular matrices (determinant = 0) gracefully
   - Test with small matrices first before scaling

3. **Performance Bottlenecks**
   - Profile matrix operations early
   - Consider caching correlation matrices
   - Use ETS for frequently accessed calculations

4. **Statistical Edge Cases**
   - Handle insufficient data (< 2 returns)
   - Check for zero variance (constant returns)
   - Validate date alignment for multi-asset comparisons

5. **LiveView Integration Issues**
   - Test with empty portfolios
   - Handle loading states for long calculations
   - Ensure proper error messages display

## Step-by-Step Implementation Order

1. **Week 1: Foundation**
   - Set up feature branch and test structure
   - Create MarketDataFixtures module
   - Implement BetaCalculator with basic tests
   - Ensure existing RiskMetricsCalculator still works

2. **Week 2: Correlation**
   - Build correlation pair calculation
   - Extend to correlation matrix
   - Create basic heatmap visualization
   - Integrate with AdvancedAnalyticsLive

3. **Week 3-4: Optimization**
   - Research/implement optimization algorithm
   - Start with 2-asset optimization
   - Build efficient frontier generator
   - Create frontier visualization

4. **Week 5: Factors & Benchmarks**
   - Implement factor loading calculations
   - Add benchmark comparison metrics
   - Create attribution breakdown

5. **Week 6: Polish & Performance**
   - Optimize slow calculations
   - Complete all visualizations
   - Documentation and examples
   - Performance testing

## Next Actions

1. [ ] Set up feature branch `feature/v0.7.0-portfolio-analytics`
2. [ ] Create `test/support/market_data_fixtures.ex` with S&P 500 sample data
3. [ ] Write first failing test in `beta_calculator_test.exs`
4. [ ] Implement minimal BetaCalculator to pass first test
5. [ ] Research Elixir matrix libraries (Matrex, Nx) for optimization

## Success Validation Checklist

Before marking any stage complete:
- [ ] All tests written first (TDD)
- [ ] Tests include edge cases
- [ ] Performance benchmarks met
- [ ] LiveView integration tested
- [ ] Documentation includes formulas
- [ ] Code GPS shows integration
- [ ] No compilation warnings
- [ ] Mix format applied

---

*This plan follows strict TDD methodology with comprehensive test specifications, clear assertion strategies, and detailed implementation guidance for each component.*