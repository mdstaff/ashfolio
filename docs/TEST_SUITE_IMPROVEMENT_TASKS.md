# Test Suite Improvement Tasks

## Overview

This document tracks the systematic improvement of the Ashfolio test suite based on the comprehensive review conducted by the elixir-test-specialist agent on August 7, 2025.

## Executive Summary

- **Current Compliance**: 70% with established testing standards
- **Foundation Quality**: Excellent infrastructure with `SQLiteHelpers` and comprehensive documentation  
- **Primary Issues**: SQLite async violations, inefficient data usage, missing GenServer permissions
- **Estimated Timeline**: 2-3 weeks for full compliance
- **Priority**: High - Some issues could cause test instability

## Critical Issues (Fix Immediately)

### Task 1: Fix SQLite Async Violations
- **Priority**: 🚨 **CRITICAL**
- **Status**: ✅ **COMPLETED** (August 7, 2025)
- **Estimated Effort**: 1 hour
- **Files Affected**: 
  - `test/ashfolio/portfolio/user_test.exs`
  - `test/ashfolio/portfolio/account_test.exs`
  - `test/ashfolio/portfolio/symbol_test.exs`
  - `test/ashfolio/portfolio/transaction_test.exs`
  - `test/ashfolio/cache_test.exs`
  - `test/ashfolio/pubsub_test.exs`
  - `test/integration/transaction_flow_test.exs`
  - `test/integration/critical_integration_points_test.exs`
  - `test/integration/simplified_transaction_flow_test.exs`
  - `test/integration/account_management_flow_test.exs`
  - `test/integration/simplified_portfolio_view_flow_test.exs`
  - `test/integration/performance_benchmarks_test.exs`
  - `test/integration/portfolio_view_flow_test.exs`
  - `test/ashfolio_web/live/account_live/form_component_test.exs`
  - `test/ashfolio_web/controllers/error_json_test.exs`
  - `test/ashfolio_web/controllers/error_html_test.exs`

**Issue**: Tests using `async: true` are incompatible with SQLite and can cause race conditions and database lock errors.

**Action Required**:
```elixir
# ❌ CURRENT (SQLite incompatible)
use Ashfolio.DataCase, async: true

# ✅ REQUIRED (SQLite safe)  
use Ashfolio.DataCase, async: false
```

**Acceptance Criteria**:
- [x] All test files use `async: false` (16 files updated)
- [x] No compilation warnings about async usage
- [x] All tests continue to pass after change

**Implementation Notes**:
- Fixed 16 test files with SQLite-incompatible `async: true` settings
- Left 4 pure unit test files with `async: true` (validation_test.exs, format_helpers_test.exs, error_helpers_test.exs, error_handler_test.exs) as they don't interact with database or shared state
- All database-interacting tests and integration tests now use `async: false`

---

### Task 2: Add Missing GenServer Database Permissions
- **Priority**: 🔴 **HIGH** 
- **Status**: ❌ **Not Started**
- **Estimated Effort**: 2-3 hours
- **Files Affected**:
  - `test/ashfolio/market_data/price_manager_test.exs`
  - Any integration tests calling PriceManager functions

**Issue**: Tests calling PriceManager GenServer functions fail intermittently due to missing database access permissions.

**Action Required**:
```elixir
# Add to setup block
setup do
  allow_price_manager_db_access()
  
  # Mock expectations
  expect(YahooFinanceMock, :fetch_price, fn _symbol ->
    {:ok, %{price: Decimal.new("150.00"), timestamp: DateTime.utc_now()}}
  end)
  
  :ok
end
```

**Acceptance Criteria**:
- [ ] All PriceManager tests have proper database permissions
- [ ] No intermittent test failures related to database access
- [ ] GenServer tests pass consistently

---

## Data Usage Standardization (Major Improvements)

### Task 3: Convert Tests to Use Global Data
- **Priority**: 🟡 **MEDIUM**
- **Status**: ❌ **Not Started** 
- **Estimated Effort**: 1-2 weeks
- **Impact**: Performance improvement and consistency

**Issue**: ~70% of tests create unnecessary custom users/accounts instead of using efficient global data helpers.

**Files to Update** (Priority Order):
1. `test/ashfolio/portfolio/account_test.exs`
2. `test/ashfolio/portfolio/transaction_test.exs`  
3. `test/ashfolio/portfolio/symbol_test.exs`
4. `test/ashfolio_web/live/dashboard_live_test.exs`
5. `test/ashfolio_web/live/account_live/index_test.exs`
6. `test/integration/account_management_flow_test.exs`
7. `test/integration/transaction_flow_test.exs`

**Pattern to Implement**:
```elixir
# ❌ INEFFICIENT - Creates unnecessary data
test "some functionality" do
  {:ok, user} = User.create(%{name: "Test User"})
  {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})
  # Test logic
end

# ✅ EFFICIENT - Uses global data  
test "some functionality" do
  user = get_default_user()           # No database write
  account = get_default_account(user) # No database write
  # Test logic
end

# ✅ EFFICIENT - Custom data when needed
test "special scenario" do
  user = get_default_user()
  
  special_account = get_or_create_account(user, %{
    balance: Decimal.new("100000.00")  # Uses retry logic
  })
  # Test logic
end
```

**Subtasks**:
- [ ] **Task 3.1**: Update unit tests (account, transaction, symbol)
- [ ] **Task 3.2**: Update LiveView tests  
- [ ] **Task 3.3**: Update integration tests
- [ ] **Task 3.4**: Verify performance improvements

---

### Task 4: Standardize Test Structure and Naming
- **Priority**: 🟡 **MEDIUM**
- **Status**: ❌ **Not Started**
- **Estimated Effort**: 1 week
- **Impact**: Consistency and maintainability

**Issues Found**:
- Inconsistent describe block organization
- Some tests have unclear names
- Missing error scenario coverage in some files

**Files Needing Structure Updates**:
- `test/ashfolio/portfolio/calculator_test.exs` - Add error scenarios
- `test/ashfolio/portfolio/holdings_calculator_test.exs` - Standardize naming
- `test/ashfolio_web/live/transaction_live/index_test.exs` - Add describe blocks

**Standard Pattern to Apply**:
```elixir
defmodule Ashfolio.ModuleTest do
  use Ashfolio.DataCase, async: false
  
  import Ashfolio.SQLiteHelpers
  alias Ashfolio.Module
  
  describe "primary_function/1" do
    test "handles valid input successfully" do
      # Success scenario
    end
    
    test "handles invalid input with proper error" do  
      # Error scenario
    end
  end
  
  describe "validation" do
    test "validates required fields" do
      # Validation testing
    end
  end
end
```

**Subtasks**:
- [ ] **Task 4.1**: Standardize describe block organization
- [ ] **Task 4.2**: Improve test naming clarity
- [ ] **Task 4.3**: Add missing error scenario coverage
- [ ] **Task 4.4**: Review assertion patterns

---

## Testing Infrastructure Improvements

### Task 5: Enhance SQLite Helper Coverage
- **Priority**: 🟢 **LOW**
- **Status**: ❌ **Not Started**
- **Estimated Effort**: 3-4 days
- **Impact**: Future development efficiency

**Potential Improvements**:
- Add more granular helper functions for common test scenarios
- Improve error messages in helper functions  
- Add performance monitoring to helpers
- Create specialized helpers for LiveView testing

**Subtasks**:
- [ ] **Task 5.1**: Analyze common test patterns not covered by helpers
- [ ] **Task 5.2**: Add new helper functions for identified patterns
- [ ] **Task 5.3**: Improve error handling in existing helpers
- [ ] **Task 5.4**: Add performance metrics to helpers

---

### Task 6: Test Performance Optimization  
- **Priority**: 🟢 **LOW**
- **Status**: ❌ **Not Started**
- **Estimated Effort**: 1 week
- **Impact**: Faster development feedback

**Areas for Optimization**:
- Identify tests with unnecessary database operations
- Optimize setup blocks for expensive operations
- Review test execution patterns
- Minimize external API calls in tests

**Subtasks**:
- [ ] **Task 6.1**: Profile test execution times
- [ ] **Task 6.2**: Identify bottleneck tests
- [ ] **Task 6.3**: Optimize expensive operations
- [ ] **Task 6.4**: Measure performance improvements

---

## Quality Assurance

### Task 7: Comprehensive Test Review and Validation
- **Priority**: 🟡 **MEDIUM**
- **Status**: ❌ **Not Started**  
- **Estimated Effort**: 1 week
- **Impact**: Overall quality assurance

**Review Areas**:
- Test coverage gaps identification
- Edge case coverage assessment
- Integration test completeness
- Error handling comprehensiveness

**Subtasks**:
- [ ] **Task 7.1**: Run test coverage analysis
- [ ] **Task 7.2**: Identify coverage gaps
- [ ] **Task 7.3**: Add tests for uncovered scenarios
- [ ] **Task 7.4**: Validate error handling coverage

---

## Implementation Plan

### Phase 1: Critical Fixes (Week 1)
1. **Day 1**: Fix SQLite async violations (Task 1)
2. **Day 2-3**: Add GenServer database permissions (Task 2)
3. **Day 4-5**: Begin high-priority data usage conversions (Task 3.1)

### Phase 2: Data Standardization (Weeks 2-3)  
1. **Week 2**: Complete unit test conversions (Tasks 3.1-3.2)
2. **Week 3**: Complete integration test conversions (Task 3.3-3.4)

### Phase 3: Structure and Quality (Week 4)
1. **Days 1-3**: Standardize test structure (Task 4)
2. **Days 4-5**: Quality validation (Task 7)

### Phase 4: Optimization (Week 5 - Optional)
1. **Week 5**: Infrastructure improvements and performance optimization (Tasks 5-6)

## Success Metrics

### Immediate Success (Phase 1)
- [x] Zero SQLite async violations ✅ **COMPLETED**
- [ ] Zero intermittent GenServer test failures  
- [ ] All critical tests passing consistently

### Short-term Success (Phases 2-3)
- [ ] 90%+ tests using global data patterns
- [ ] Consistent test structure across all files
- [ ] Improved test execution speed (target: 20% faster)

### Long-term Success (Phase 4)  
- [ ] 95%+ compliance with testing standards
- [ ] Comprehensive test coverage (85%+ code coverage)
- [ ] Optimized test performance and infrastructure

## Best Practice Examples

### Excellent Test Examples to Reference
Based on the agent's analysis, these tests demonstrate best practices:

1. **`test/support/sqlite_helpers.ex`** - Excellent helper function design
2. **`test/ashfolio/cache_test.exs`** - Good structure and data usage
3. **`test/integration/performance_benchmarks_test.exs`** - Comprehensive integration testing

### Patterns to Replicate
- Global data usage with fallback to helpers
- Proper describe block organization
- Comprehensive error scenario coverage  
- Clear, descriptive test naming
- Efficient setup block usage

## Notes and Considerations

### SQLite-Specific Considerations
- All improvements must maintain SQLite compatibility
- Retry logic should be preserved and enhanced
- Database operations must remain single-threaded safe

### Performance Considerations  
- Prioritize changes that improve test execution speed
- Minimize database writes during test improvements
- Preserve existing performance optimizations

### Development Workflow
- Implement changes incrementally to avoid breaking existing functionality
- Run full test suite after each major change
- Update documentation as patterns evolve

---

**Last Updated**: August 7, 2025  
**Reviewed By**: elixir-test-specialist agent  
**Next Review**: After Phase 1 completion