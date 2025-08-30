# Ashfolio Consolidated Roadmap & Implementation Plan

Version: 3.1  
Date: 2025-08-30  
Current State: v0.4.2 Complete ✅, v0.4.3 In Development (Scenario Planning Complete)

## 🎯 Executive Summary

Ashfolio has successfully completed v0.4.2 (Financial Goals + Retirement Planning) and v0.4.3 core functionality (Scenario Planning). This consolidated plan addresses remaining bugs, test failures, and the implementation of v0.4.4-v0.5.0 features to complete the comprehensive financial planning platform.

## Current Status Assessment

### ✅ Completed Features
- **v0.4.1 Financial Goals System**: Complete with 30+ tests passing
  - FinancialGoal resource with Decimal calculations
  - Emergency fund calculator with expense integration  
  - Goal tracking UI with dashboard widgets
  - Real-time PubSub updates

- **v0.4.2 Retirement Planning**: Complete with UI (Released 2025-08-26)
  - RetirementCalculator with 25x expenses rule
  - 4% safe withdrawal rate analysis
  - Dividend income projections
  - Interactive RetirementLive UI with charts
  - ChartHelpers module for visualizations

- **v0.4.3 Forecasting Engine**: Core functionality complete (In Development)
  - Scenario Planning Engine (5%, 7%, 10% scenarios)
  - Custom scenario planning with user-defined rates
  - Financial Independence timeline calculations
  - Multi-scenario FI analysis
  - 32 comprehensive tests passing
  - Demo script for testing features

### 🐛 Known Issues (Actively Being Addressed)
- **✅ FIXED**: KeyError in PerformanceCalculator.calculate_period_returns (Fixed with Map.put)
- **Chart Visualization Bugs**: 
  - Growth rates display as "0.07%" instead of "7%"
  - Charts start at $0 instead of initial portfolio value
  - Scenario comparison showing 1 line instead of 3
- **Test Suite Failures**: ~46 test failures across 6 files
  - Advanced Analytics LiveView: 9 failures (UI/interaction issues)
  - Performance Calculator: 11 failures (simplified vs expected returns)
  - Forecast Chart Component: 10 failures (Decimal handling)
  - Other minor test failures in accessibility and forms

### 📊 Architecture Status
- Local-first SQLite architecture: ✅ Maintained
- 1058+ tests passing: ✅ Achieved  
- Phoenix LiveView with PubSub: ✅ Working
- Ash framework integration: ✅ Complete

## Immediate Action Plan (Next 2 Weeks)

### Phase 1: Critical Bug Fixes [URGENT]

**Week 1: Production Readiness**

#### Stage 1A: Goal Creation Form Fix
- **Priority**: P0 (Blocks all goal functionality)
- **Root Cause**: Missing `recommended_target` field in form component
- **Solution**: Add calculated field to FinancialGoalLive.FormComponent
- **Test Requirements**: Form submission with all goal types
- **Files**: `lib/ashfolio_web/live/financial_goal_live/form_component.ex`

#### Stage 1B: Chart Data Fixes  
- **Priority**: P1 (User confusion, incorrect data display)
- **Issues**: 
  - Growth rates show "0.07%" instead of "7%"
  - Charts start at $0 instead of initial portfolio value
  - Scenario comparison only shows 1 line instead of 3
- **Solution**: Create FormatHelper module, fix chart data generation
- **Files**: `lib/ashfolio_web/live/forecast_live/index.ex`, `lib/ashfolio/portfolio/forecast_calculator.ex`

#### Stage 1C: Navigation Links
- **Priority**: P1 (Feature discoverability)
- **Missing**: Analytics (/expenses/analytics) and Net Worth (/net_worth) links
- **Solution**: Update top navigation component
- **Files**: `lib/ashfolio_web/components/layouts/app.html.heex`

**Week 1 Success Criteria:**
- [ ] All goal creation forms work without errors
- [ ] Charts display correct data with proper formatting  
- [ ] All features accessible via navigation
- [ ] E2E tests pass for existing v0.4.1 functionality

### Phase 2: Polish v0.4.3 and Begin v0.4.4

**Week 2: Chart Fixes and Advanced Analytics Foundation**

#### Stage 2A: Complete Chart Visualization Fixes
- **Deliverable**: Properly formatted and functional charts
- **Fixes Required**:
  - Format growth rates correctly (7% not 0.07%)
  - Show initial portfolio values
  - Display all scenario lines in comparisons
- **Files**: ForecastChart component, ChartHelpers module

#### Stage 2B: Begin v0.4.4 Advanced Analytics
- **Deliverable**: Replace simplified TWR/MWR implementations
- **Features**:
  - Proper Time-Weighted Return with period breakdown
  - IRR-based Money-Weighted Return calculation
  - Begin rolling returns implementation
- **Files**: `lib/ashfolio/portfolio/performance_calculator.ex`

**Week 2 Success Criteria:**
- [ ] All chart visualizations display correctly
- [ ] Test failures reduced to <20
- [ ] TWR/MWR calculations return accurate values
- [ ] Foundation laid for v0.4.4 completion

## Strategic Roadmap (Next 6 Months)

### v0.4.3: Forecasting Engine (Month 1-2) 
**Status**: Core Complete, UI Polish Needed

- **Completed Features**: ✅
  - Scenario Planning Engine with weighted averages
  - Custom scenario modeling with user-defined rates
  - Financial Independence timeline calculations
  - Multi-scenario FI analysis
  - 32 comprehensive tests passing
  - Demo script: `scripts/test-scenario-planning.exs`

- **Remaining Work**: 
  - Fix chart visualization bugs (Week 1 priority)
  - Polish forecasting UI interactions
  - Improve scenario comparison displays

### v0.4.4: Advanced Analytics (Month 2-3) 
**Status**: Simplified version working, needs proper implementation

- **Time-Weighted Return (TWR)**: Industry-standard performance calculation
- **Money-Weighted Return (MWR)**: Dollar-weighted return with IRR
- **Rolling Returns**: 1-year, 3-year rolling performance analysis
- **Performance Caching**: ETS cache for expensive calculations

### v0.4.5: Benchmark System (Month 4-5)
**Status**: Not started

- **Benchmark Data Management**: S&P 500, Total Market indices
- **Performance Comparisons**: Outperformance/underperformance tracking  
- **Asset Class Analysis**: Portfolio composition breakdown

### v0.5.0: Production Polish (Month 6)
**Status**: Integration and optimization phase

- **Dashboard Integration**: All v0.4.x features integrated seamlessly
- **Performance Optimization**: Sub-second response times
- **AER Standardization**: Consistent Annual Equivalent Rate methodology
- **Test Suite Health**: 100% test coverage, all tests passing
- **Documentation**: Complete user and developer documentation

## Development Methodology

### TDD Approach (Red-Green-Refactor)
1. **Write failing test first** - Define expected behavior
2. **Implement minimal code** - Make test pass
3. **Refactor and improve** - Clean code while maintaining tests
4. **Verify with E2E testing** - Ensure user workflows work

### Quality Gates
- **Unit Tests**: 100% coverage for financial calculations
- **Integration Tests**: Database and PubSub operations
- **LiveView Tests**: Complete user workflows  
- **Performance Tests**: Meet benchmarks (TWR <500ms, Dashboard <2s)
- **E2E Testing**: Playwright verification of all user journeys

### Technical Standards
- **Decimal Arithmetic**: All financial calculations use Decimal type
- **Error Handling**: Proper {:ok, result} | {:error, reason} patterns
- **Logging**: Logger.debug for calculation monitoring
- **Caching**: ETS cache for expensive operations
- **Real-time Updates**: PubSub for live dashboard updates

## Success Metrics

### Immediate (2 Weeks)
- [ ] Zero production-blocking bugs
- [ ] All v0.4.1 and v0.4.2 features functional
- [ ] E2E test suite passes completely
- [ ] Dashboard loads in <2 seconds

### Short-term (6 Months)  
- [ ] Complete v0.4.x financial planning platform
- [ ] Professional-grade analytics (TWR, MWR, benchmarks)
- [ ] Performance benchmarks met across all features
- [ ] User workflows intuitive and efficient

### Strategic Vision
Transform Ashfolio from portfolio tracking to comprehensive financial planning platform while maintaining:
- **Local-first architecture** with SQLite
- **Single-user simplicity** without authentication complexity
- **Privacy-focused** with no external dependencies
- **Professional accuracy** matching industry standards

## Resource Allocation

### Immediate Focus (90% effort)
- Chart visualization bug fixes
- Test suite failure resolution
- v0.4.4 Advanced Analytics proper implementation
- Performance optimization

### Future Development (10% effort)  
- Architecture planning for v0.4.4-v0.4.5
- Performance optimization research
- User experience testing preparation

---

This consolidated roadmap balances immediate production needs with strategic feature development, ensuring Ashfolio delivers on its promise of comprehensive, local-first financial planning.