# IMPLEMENTATION_PLAN.md | v0.5.0 "Your Money Ratios" Feature

## Overview

Implementation of Charles Farrell's "Your Money Ratios" methodology - a comprehensive financial health assessment framework using 8 key ratios tied to gross annual household income. This feature will provide age-based benchmarks and actionable insights for users to track their financial progress toward retirement readiness.

**Target Audience**: Users seeking structured financial health assessment
**Core Value**: Professional financial planning guidance with industry-standard benchmarks
**Integration**: Leverages existing net worth, expense, and portfolio data

---

## Stage 1: Financial Profile Foundation

**Objective**: Create user financial profile infrastructure with income and demographic data

**Deliverable**: `Ashfolio.FinancialManagement.FinancialProfile` Ash resource
**Impact**: Foundation for all ratio calculations with secure local storage
**Test cases**: Profile CRUD, validation, data integrity

**Files to Create**:
- `lib/ashfolio/financial_management/financial_profile.ex` - Ash resource with fields:
  - `gross_annual_income` (Decimal, required)
  - `birth_year` (Integer, required - single-user optimized)
  - `household_members` (Integer, default 1)
  - `primary_residence_value` (Decimal, optional)
  - `mortgage_balance` (Decimal, optional)
  - `student_loan_balance` (Decimal, optional)

**Database Migration**: Add `financial_profiles` table with appropriate indexes

**Validation Rules**:
- Income must be positive
- Birth year must be reasonable (1920-2010 range)
- All monetary values must be non-negative

**Single-User Age Optimization**:
- Store birth year only (e.g., 1985) for privacy and simplicity
- Auto-calculate current age: `Date.utc_today().year - birth_year`
- No manual age updates needed - auto-increments with calendar
- Set once during initial setup, forget forever

**TDD Workflow**:
1. **Test First**: Create `test/ashfolio/financial_management/financial_profile_test.exs`
   - Write failing tests for each validation rule
   - Test CRUD operations with invalid data
   - Test birth year validation and current age calculation
2. **Red**: Run `just test unit` - should fail  
3. **Green**: Implement minimal `FinancialProfile` resource to pass tests
4. **Refactor**: Clean up resource definition, add proper documentation

**Test Categories**:
- `@tag :unit` - Profile validation, birth year validation, age calculations (15 tests)
- `@tag :integration` - Database CRUD, Ash resource operations (10 tests)

**Status**: Not Started

---

## Stage 2: Money Ratios Calculator Module  

**Objective**: Core calculation engine for all 8 Farrell money ratios

**Deliverable**: `Ashfolio.Financial.MoneyRatios` calculator module
**Impact**: Professional financial health assessment with age-based benchmarks
**Test cases**: All 8 ratio calculations, edge cases, age-based thresholds

**Files to Create**:
- `lib/ashfolio/financial/money_ratios.ex` - Core calculator module

**Ratio Implementations**:

1. **Capital-to-Income Ratio** - `calculate_capital_ratio/3`
   - Input: Profile, net worth data (excluding primary residence)
   - Benchmark: Age-based targets (1.5x at 35, 12x at 65)
   - Output: {current_ratio, target_ratio, status}

2. **Savings Ratio** - `calculate_savings_ratio/2`  
   - Input: Profile, annual savings amount
   - Benchmark: 12% of gross income
   - Integration: May leverage expense tracking for savings calculation

3. **Mortgage-to-Income Ratio** - `calculate_mortgage_ratio/2`
   - Input: Profile with mortgage balance
   - Benchmark: Age-based targets (2x in 30s, 1x in 50s, 0x at retirement)

4. **Education-to-Income Ratio** - `calculate_education_ratio/2`
   - Input: Profile with student loan balance  
   - Benchmark: Debt ≤ annual income for first 10 years post-graduation

**Simplified Insurance Ratios** (Advisory only, no complex calculations):
5. **Disability Insurance** - Recommend 60-70% income coverage
6. **Life Insurance** - Needs-based calculation using capital gap analysis
7. **Long-term Care** - Asset-based self-insurance threshold ($2M+)

8. **Investment Health Check** - `assess_investment_allocation/2`
   - Integration: Portfolio composition analysis 
   - Benchmark: Age-appropriate risk allocation

**Dependencies**: 
- Existing `NetWorthCalculator` for capital calculations
- New `FinancialProfile` resource
- `Ashfolio.Financial.DecimalHelpers` for precision

**TDD Workflow**:
1. **Test First**: Create `test/ashfolio/financial/money_ratios_test.exs`
   - Write failing tests for each ratio calculation function
   - Test edge cases (zero income, missing data, extreme values)
   - Mock dependencies (NetWorthCalculator, profile data)
2. **Red**: Run `just test unit` - should fail for all 8 ratios
3. **Green**: Implement minimal ratio functions to pass tests
4. **Refactor**: Extract common patterns, optimize calculations

**Test Categories**:
- `@tag :unit` - Pure ratio calculations, edge cases (40 tests)
- `@tag :integration` - Integration with NetWorthCalculator, real data (15 tests)

**Test Structure**:
```elixir
describe "calculate_capital_ratio/3" do
  @tag :unit
  test "calculates correct ratio for valid profile and net worth"
  
  @tag :unit  
  test "handles zero income gracefully"
  
  @tag :unit
  test "excludes primary residence from capital calculation"
end
```

**Status**: Not Started

---

## Stage 3: Age-Based Benchmark System

**Objective**: Dynamic benchmark calculation based on user age and life stage

**Deliverable**: `Ashfolio.Financial.MoneyRatios.Benchmarks` module  
**Impact**: Contextual financial targets that adapt to user demographics
**Test cases**: Age bracket calculations, benchmark accuracy, edge cases

**Files to Create**:
- `lib/ashfolio/financial/money_ratios/benchmarks.ex` - Benchmark calculation module

**Benchmark Functions**:
- `capital_target_for_age/1` - Returns multiplier for capital-to-income ratio
- `mortgage_target_for_age/1` - Returns maximum mortgage-to-income ratio  
- `life_stage_analysis/1` - Returns comprehensive life stage assessment
- `retirement_readiness_score/2` - Overall readiness percentage

**Age Brackets & Targets**:
```elixir
# Capital-to-Income Targets
25-30: 0.5x - 1.0x income
30-35: 1.0x - 2.0x income  
35-40: 2.0x - 3.0x income
40-45: 3.0x - 5.0x income
45-50: 5.0x - 7.0x income
50-55: 7.0x - 9.0x income
55-60: 9.0x - 11.0x income
60-65: 11.0x - 12.0x income
65+:   12.0x+ income (retirement ready)
```

**Advanced Features**:
- Catch-up recommendations for behind-benchmark users
- Accelerated timeline calculations for ahead-of-benchmark users
- Risk tolerance adjustments based on life stage

**Dependencies**: User age calculation from `FinancialProfile.birth_year` (simplified single-user approach)

**TDD Workflow**:
1. **Test First**: Create `test/ashfolio/financial/money_ratios/benchmarks_test.exs`
   - Write failing tests for age bracket calculations
   - Test boundary conditions (exactly 30, 35, 40, etc.)
   - Test invalid ages and edge cases
2. **Red**: Run `just test unit` - should fail for all benchmark functions
3. **Green**: Implement age-based lookup tables and calculation logic
4. **Refactor**: Optimize lookup performance, add comprehensive documentation

**Test Categories**:
- `@tag :unit` - Age bracket calculations, boundary conditions (25 tests)
- `@tag :integration` - Integration with real profile data (10 tests)

**Critical Test Cases**:
```elixir
describe "capital_target_for_age/1" do
  @tag :unit
  test "returns 1.0 for age 30" 
  
  @tag :unit
  test "returns 12.0 for age 65 and above"
  
  @tag :unit
  test "handles boundary ages correctly (29 vs 30)"
end
```

**Status**: Not Started

---

## Stage 4: Money Ratios LiveView Interface

**Objective**: Professional web interface for ratio analysis and recommendations

**Deliverable**: `AshfolioWeb.MoneyRatiosLive.Index` LiveView
**Impact**: User-friendly financial health dashboard with actionable insights  
**Test cases**: UI rendering, form handling, real-time calculations

**Files to Create**:
- `lib/ashfolio_web/live/money_ratios_live/index.ex` - Main LiveView (estimated 600+ lines)
- `lib/ashfolio_web/live/money_ratios_live/form_component.ex` - Profile editing
- `lib/ashfolio_web/components/ratio_card.ex` - Individual ratio display component
- `lib/ashfolio_web/components/benchmark_chart.ex` - Visual progress charts

**LiveView Features**:

**Tab Structure**:
1. **Overview** - All 8 ratios with status indicators (✅❌⚠️)
2. **Capital Analysis** - Detailed capital-to-income breakdown
3. **Debt Management** - Mortgage and education debt analysis  
4. **Financial Profile** - Income and demographic management
5. **Action Plan** - Personalized recommendations

**Interactive Elements**:
- Financial profile form with real-time validation
- Scenario analysis ("What if I save 15% instead of 12%?")
- Progress tracking with visual charts
- Benchmark comparison tables

**Visual Design**:
- Traffic light color coding (green/yellow/red) for ratio status
- Progress bars showing current vs. target ratios
- Age-based timeline charts  
- Professional financial dashboard styling

**Real-time Features**:
- Live ratio recalculation on profile changes
- Dynamic benchmark updates based on age
- Instant feedback on profile modifications

**Dependencies**: 
- `MoneyRatios` calculator module
- `Benchmarks` module
- Existing `Contex` charts infrastructure
- `AshfolioWeb.FormHelpers` for form processing

**TDD Workflow**:
1. **Test First**: Create `test/ashfolio_web/live/money_ratios_live/index_test.exs`
   - Write failing tests for LiveView mount and rendering
   - Test form submissions and validations
   - Test real-time ratio calculations
   - Test tab switching and navigation
2. **Red**: Run `just test live` - should fail for all LiveView functionality
3. **Green**: Implement minimal LiveView to pass tests
4. **Refactor**: Extract components, optimize rendering, improve UX

**Test Categories**:
- `@tag :liveview` - UI rendering, user interactions (30 tests)
- `@tag :integration` - Form processing, data updates (15 tests)
- `@tag :unit` - Component rendering, helper functions (10 tests)

**Critical LiveView Tests**:
```elixir
describe "MoneyRatiosLive.Index" do
  @tag :liveview
  test "displays all 8 ratios on mount"
  
  @tag :liveview
  test "updates ratios in real-time when profile changes"
  
  @tag :liveview  
  test "shows proper status indicators (✅❌⚠️)"
  
  @tag :liveview
  test "handles tab switching between overview, capital, debt, profile"
end
```

**Status**: Not Started

---

## Stage 5: Dashboard Integration & Recommendations Engine

**Objective**: Integrate ratios into main dashboard with personalized recommendations

**Deliverable**: Dashboard widget + recommendation system
**Impact**: Proactive financial guidance integrated into daily workflow
**Test cases**: Widget rendering, recommendation accuracy, dashboard integration

**Files to Modify**:
- `lib/ashfolio_web/live/dashboard_live.ex` - Add money ratios widget
- `lib/ashfolio_web/components/dashboard_widgets.ex` - Money ratios summary widget

**Files to Create**:
- `lib/ashfolio/financial/money_ratios/recommendations.ex` - AI-like recommendation engine
- `lib/ashfolio_web/components/financial_health_widget.ex` - Dashboard widget

**Dashboard Widget Features**:
- Financial health score (0-100)
- Quick status overview of critical ratios
- "Action needed" alerts for ratios significantly off-target  
- Quick access to detailed Money Ratios page

**Recommendation Engine**:
- **Priority-based alerts**: Focus on most important ratio improvements
- **Actionable guidance**: Specific savings targets, debt payoff timelines
- **Integration opportunities**: Link to existing goals, forecasting tools
- **Lifecycle awareness**: Recommendations adapt to user's life stage

**Sample Recommendations**:
```
🎯 Priority Action: Increase savings rate from 8% to 12% to meet benchmark
💰 Capital Gap: Save additional $15,000 annually to reach age-appropriate target  
🏠 Mortgage Goal: Consider accelerated payments to reach debt-free by age 62
📊 Portfolio Check: Your allocation appears conservative for your age (35)
```

**Advanced Features**:
- Monthly financial health tracking  
- Integration with financial goals system
- Personalized milestone celebrations
- Progress trend analysis

**Dependencies**: All previous stages, existing dashboard infrastructure

**TDD Workflow**:
1. **Test First**: Create test files for recommendations and dashboard integration
   - `test/ashfolio/financial/money_ratios/recommendations_test.exs`
   - `test/ashfolio_web/components/financial_health_widget_test.exs`
   - Update `test/ashfolio_web/live/dashboard_live_test.exs`
2. **Red**: Run `just test integration` - should fail for new functionality
3. **Green**: Implement minimal recommendation engine and dashboard widget
4. **Refactor**: Optimize recommendation logic, improve dashboard integration

**Test Categories**:
- `@tag :unit` - Recommendation logic, priority calculations (20 tests)
- `@tag :integration` - Dashboard integration, widget rendering (15 tests)
- `@tag :liveview` - Dashboard updates, user interactions (10 tests)

**Critical Tests**:
```elixir
describe "Recommendations.generate_priority_actions/2" do
  @tag :unit
  test "prioritizes capital ratio when significantly behind"
  
  @tag :unit
  test "recommends specific savings targets with dollar amounts"
end

describe "FinancialHealthWidget" do
  @tag :integration
  test "calculates health score from all ratios"
  
  @tag :liveview
  test "displays action needed alerts for critical ratios"
end
```

**Status**: Not Started

---

## Stage 6: Testing & Polish

**Objective**: Comprehensive testing and production readiness

**Deliverable**: Complete test suite with edge case coverage
**Impact**: Production-ready feature with reliability guarantees
**Test cases**: Unit, integration, LiveView, edge cases, performance

**Testing Strategy**:

**Unit Tests** (~150 tests total):
- `MoneyRatios` module: All 8 calculations with various scenarios
- `Benchmarks` module: Age-based targets and edge cases
- `Recommendations` module: Logic validation and priority ranking
- `FinancialProfile` resource: CRUD operations and validation

**Integration Tests** (~50 tests total):  
- Full ratio calculation workflow with real data
- Dashboard widget integration
- Cross-module data flow validation

**LiveView Tests** (~40 tests total):
- UI rendering for all tabs and components
- Form submission and validation
- Real-time updates and event handling
- Error states and edge cases

**Performance Tests**:
- Ratio calculations with large datasets
- LiveView responsiveness under load
- Database query optimization

**Edge Case Coverage**:
- Zero income scenarios
- Extreme age values (18, 100+)
- Missing financial data
- Invalid profile data

**Production Checklist**:
- [ ] All tests passing (>95% coverage target)
- [ ] Credo compliance (0 issues)
- [ ] Performance benchmarks met (<100ms calculations)
- [ ] Comprehensive error handling
- [ ] Professional UI/UX polish
- [ ] Integration with existing navigation
- [ ] Documentation complete

**Dependencies**: All previous stages complete

**TDD Workflow**:
1. **Test Completeness Audit**: Review all modules for missing test coverage
   - Run `mix test --cover` to identify gaps
   - Ensure >95% line coverage target
   - Add missing edge case tests
2. **Performance Testing**: Create comprehensive performance test suite
   - `@tag :performance` tests for large datasets
   - Memory usage and query optimization
   - LiveView responsiveness under load
3. **Integration Testing**: End-to-end workflow validation
   - Full user journey from profile creation to recommendations
   - Cross-module data consistency
   - Error handling and recovery
4. **Polish & Refactor**: Code quality and user experience improvements

**Test Organization**:
```bash
# Run different test categories during development
just test unit        # Fast feedback (150+ tests)
just test integration # Cross-module testing (50+ tests)  
just test live        # UI/UX testing (40+ tests)
just test perf        # Performance validation (10+ tests)
just test all         # Complete test suite (250+ tests)
```

**Status**: Not Started

---

## Development Timeline & Success Criteria

**Estimated Timeline**: 6-8 weeks total

**Phase Breakdown with TDD Focus**:
- **Week 1-2**: Stages 1-2 (Foundation + Calculator)
  - Daily: `just test unit` for rapid TDD cycles
  - End-of-week: `just test integration` for stage completion
- **Week 3-4**: Stages 3-4 (Benchmarks + LiveView)  
  - Daily: `just test unit` + specific LiveView tests
  - End-of-week: `just test live` for UI validation
- **Week 5-6**: Stage 5 (Dashboard Integration)
  - Daily: `just test integration` for cross-module testing
  - End-of-week: Full integration testing
- **Week 7-8**: Stage 6 (Testing & Polish)
  - Daily: `just test all` + performance optimization
  - Final: Complete test suite validation

**Success Criteria**:

**Functional Requirements**:
- [ ] All 8 Farrell money ratios implemented with accurate calculations
- [ ] Age-based benchmarking system with 9 life stage brackets  
- [ ] Professional LiveView interface with 5 tabs
- [ ] Dashboard integration with health score widget
- [ ] Recommendation engine with priority-based guidance

**Technical Requirements**:
- [ ] <100ms calculation performance for all ratios
- [ ] >95% test coverage across all modules
- [ ] 0 Credo/Dialyzer warnings
- [ ] Mobile-responsive UI design
- [ ] Secure local-first data storage (no external APIs)

**User Experience Requirements**:
- [ ] Intuitive financial profile setup (<5 minutes)
- [ ] Clear visual indicators for ratio status  
- [ ] Actionable recommendations with specific targets
- [ ] Seamless integration with existing Ashfolio workflow

**Quality Gates**:
- [ ] All existing tests continue passing
- [ ] No performance regressions on main dashboard
- [ ] Professional-grade financial calculations (precision to 2 decimal places)
- [ ] Comprehensive error handling and validation

---

## Architecture Integration

**Leverages Existing Infrastructure**:
- `Ashfolio.Financial.*` modules for calculations
- `AshfolioWeb.FormHelpers` for form processing  
- `Contex` charts for data visualization
- SQLite local storage for financial profiles
- Phoenix LiveView for real-time UI
- Existing navigation and styling patterns

**Maintains Architectural Principles**:
- Local-first data storage (no external APIs)
- Single-user design (no multi-tenancy)
- Comprehensive testing coverage
- Decimal precision for financial calculations
- Professional UI/UX standards

**Extension Points for Future Enhancements**:
- Goal setting integration (link ratios to financial goals)
- Historical ratio tracking over time
- Monte Carlo scenario modeling
- Tax planning integration (retirement account optimization)
- Export capabilities for financial advisors

---

## TDD Development Guidelines

### Daily TDD Workflow

**Red-Green-Refactor Cycle**:
```bash
# 1. RED: Write failing test
just test unit file_name_test.exs  # Should fail

# 2. GREEN: Write minimal code to pass  
just test unit file_name_test.exs  # Should pass

# 3. REFACTOR: Clean up while tests pass
just test unit                     # All unit tests should pass
```

### Test Categories & Commands

**Unit Tests** (`@tag :unit`):
- Pure functions, calculations, validations
- Fast feedback (< 1 second total)
- Use for TDD red-green-refactor cycles
- Command: `just test unit`

**Integration Tests** (`@tag :integration`):
- Database operations, Ash resources, cross-module
- Stage completion validation (2-5 seconds total)  
- Command: `just test integration`

**LiveView Tests** (`@tag :liveview`):
- UI rendering, user interactions, real-time updates
- End-to-end UI validation (5-15 seconds total)
- Command: `just test live`

**Performance Tests** (`@tag :performance`):
- Large datasets, optimization validation
- Non-blocking, run periodically
- Command: `just test perf`

### Stage Completion Criteria

Each stage requires:
1. **All unit tests passing** - `just test unit`
2. **All integration tests passing** - `just test integration`  
3. **Code quality compliance** - `just check` (format + credo + tests)
4. **Documentation complete** - All public functions documented

### TDD Success Metrics

- **Test Coverage**: >95% line coverage (`mix test --cover`)
- **Test Speed**: Unit tests <1s, Integration <5s, LiveView <15s
- **Test Organization**: Clear describe/test structure with appropriate tags
- **Edge Cases**: Comprehensive boundary condition testing
- **Mocking**: Proper dependency isolation for unit tests