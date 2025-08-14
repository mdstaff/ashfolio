# Task 11: Net Worth Dashboard Integration - QA Testing Plan

## Executive Summary

This comprehensive QA testing plan covers the enhancement of DashboardLive with net worth integration functionality. The task involves adding net worth display alongside existing portfolio functionality, real-time updates via PubSub, investment vs cash breakdown visualization, account type breakdown display, and enhanced error handling.

## Scope & Objectives

### Primary Objectives
- Verify net worth data integration does not disrupt existing portfolio functionality
- Ensure real-time net worth updates work correctly via PubSub
- Validate investment vs cash breakdown visualization accuracy
- Confirm enhanced error handling maintains graceful degradation
- Verify performance requirements are met for combined data loading

### Testing Scope
- **In Scope**: DashboardLive enhancements, net worth display, PubSub integration, error handling, UI responsiveness
- **Out of Scope**: Historical net worth tracking, advanced visualizations, export functionality

## 1. Detailed Test Scenarios

### 1.1 Net Worth Data Integration

#### Scenario: Basic Net Worth Display
**Objective**: Verify net worth data loads and displays correctly alongside portfolio data

**Test Cases**:
- **TC-1.1.1**: Dashboard loads with both portfolio and net worth data
  - **Given**: User has investment and cash accounts with transactions
  - **When**: User navigates to dashboard
  - **Then**: Portfolio summary cards display existing data AND net worth summary cards show total net worth, investment value, cash value
  - **Expected Values**: Net worth = Investment value + Cash balance

- **TC-1.1.2**: Net worth calculation accuracy
  - **Given**: User has $10,000 in investments (10 shares @ $100 current price) and $5,000 cash
  - **When**: Dashboard loads
  - **Then**: Net worth displays $15,000, Investment value shows $10,000, Cash balance shows $5,000

- **TC-1.1.3**: Zero net worth handling
  - **Given**: User has no accounts or all accounts have zero balance
  - **When**: Dashboard loads
  - **Then**: All net worth cards display $0.00 formatted correctly

#### Scenario: Investment vs Cash Breakdown
**Objective**: Verify investment and cash breakdown visualization accuracy

**Test Cases**:
- **TC-1.2.1**: Investment-heavy portfolio breakdown
  - **Given**: User has $20,000 investments and $2,000 cash
  - **When**: Dashboard loads
  - **Then**: Breakdown shows 90% investments, 10% cash with correct visual representation

- **TC-1.2.2**: Cash-heavy portfolio breakdown
  - **Given**: User has $3,000 investments and $15,000 cash
  - **When**: Dashboard loads
  - **Then**: Breakdown shows 17% investments, 83% cash with correct visual representation

- **TC-1.2.3**: Equal investment and cash breakdown
  - **Given**: User has $10,000 investments and $10,000 cash
  - **When**: Dashboard loads
  - **Then**: Breakdown shows 50% investments, 50% cash

#### Scenario: Account Type Breakdown
**Objective**: Verify account type breakdown displays correctly

**Test Cases**:
- **TC-1.3.1**: Multiple cash account types
  - **Given**: User has checking ($2,000), savings ($8,000), money market ($5,000)
  - **When**: Dashboard loads
  - **Then**: Account breakdown shows 3 cash accounts, $15,000 total, with individual account type breakdowns

- **TC-1.3.2**: Mixed account types
  - **Given**: User has 2 investment accounts and 3 cash accounts
  - **When**: Dashboard loads
  - **Then**: Breakdown shows correct counts and totals for each account type

- **TC-1.3.3**: Single account type only
  - **Given**: User has only investment accounts (no cash) OR only cash accounts (no investments)
  - **When**: Dashboard loads
  - **Then**: Breakdown shows appropriate display for single account type scenario

### 1.2 Real-Time PubSub Updates

#### Scenario: Net Worth PubSub Subscription
**Objective**: Verify dashboard subscribes to net worth PubSub topic

**Test Cases**:
- **TC-2.1.1**: PubSub subscription on mount
  - **Given**: Dashboard is loading
  - **When**: Mount function executes
  - **Then**: Dashboard subscribes to "net_worth" topic alongside existing "accounts" and "transactions" topics

- **TC-2.1.2**: Multiple PubSub subscriptions coexist
  - **Given**: Dashboard has mounted
  - **When**: Account, transaction, and net worth events are broadcast
  - **Then**: Dashboard handles all event types without conflicts

#### Scenario: Real-Time Net Worth Updates
**Objective**: Verify net worth updates in real-time when underlying data changes

**Test Cases**:
- **TC-2.2.1**: Cash balance update triggers net worth refresh
  - **Given**: Dashboard is loaded showing current net worth
  - **When**: Cash account balance is updated via BalanceManager
  - **Then**: Net worth display updates within 100ms without page refresh

- **TC-2.2.2**: Investment value change triggers net worth refresh
  - **Given**: Dashboard shows current net worth with investment value
  - **When**: Stock price updates causing portfolio value change
  - **Then**: Net worth and breakdown percentages update automatically

- **TC-2.2.3**: Multiple simultaneous updates
  - **Given**: Dashboard is displaying current data
  - **When**: Both cash balance and investment values change simultaneously
  - **Then**: Net worth display updates once with combined changes

#### Scenario: PubSub Message Handling
**Objective**: Verify correct handling of net worth PubSub messages

**Test Cases**:
- **TC-2.3.1**: Valid net worth update message
  - **Given**: Dashboard is mounted and subscribed
  - **When**: `{:net_worth_updated, user_id, net_worth_data}` message received
  - **Then**: Dashboard assigns new net worth data and re-renders affected sections

- **TC-2.3.2**: Invalid net worth update message
  - **Given**: Dashboard is mounted and subscribed
  - **When**: Malformed net worth update message received
  - **Then**: Dashboard handles gracefully without crashing, logs error

- **TC-2.3.3**: Net worth update for different user
  - **Given**: Dashboard is mounted for user A
  - **When**: Net worth update message for user B received
  - **Then**: Dashboard ignores message (no update to display)

### 1.3 Error Handling & Edge Cases

#### Scenario: Net Worth Calculation Errors
**Objective**: Verify graceful handling of net worth calculation failures

**Test Cases**:
- **TC-3.1.1**: Net worth calculation failure with working portfolio
  - **Given**: Portfolio calculations work but net worth calculation fails
  - **When**: Dashboard loads
  - **Then**: Portfolio data displays normally, net worth cards show error state or default values, specific error message displayed

- **TC-3.1.2**: Partial net worth data available
  - **Given**: Investment value calculated successfully but cash balance calculation fails
  - **When**: Dashboard loads
  - **Then**: Investment portion displays, cash portion shows error/default, partial net worth calculated where possible

- **TC-3.1.3**: Complete net worth system failure
  - **Given**: All net worth related calculations fail
  - **When**: Dashboard loads
  - **Then**: Portfolio functionality unaffected, net worth section displays appropriate error state

#### Scenario: Data Consistency Issues
**Objective**: Verify handling of inconsistent data between portfolio and net worth

**Test Cases**:
- **TC-3.2.1**: Portfolio and net worth calculation discrepancies
  - **Given**: Portfolio calculator and net worth calculator return different investment values
  - **When**: Dashboard loads
  - **Then**: Error logged, user warned of data inconsistency, fallback display strategy used

- **TC-3.2.2**: Stale cached data scenarios
  - **Given**: Net worth data is cached but underlying account data has changed
  - **When**: Dashboard loads
  - **Then**: Fresh data is fetched, cache updated, accurate values displayed

#### Scenario: User Configuration Edge Cases
**Objective**: Verify handling of unusual user account configurations

**Test Cases**:
- **TC-3.3.1**: User with excluded accounts
  - **Given**: User has excluded accounts that should not count toward net worth
  - **When**: Dashboard loads
  - **Then**: Excluded accounts not included in net worth calculations or breakdowns

- **TC-3.3.2**: User with zero-balance accounts
  - **Given**: User has accounts with zero balances
  - **When**: Dashboard loads
  - **Then**: Zero-balance accounts handled correctly in breakdown calculations

- **TC-3.3.3**: New user with no accounts
  - **Given**: New user with no accounts created yet
  - **When**: Dashboard loads
  - **Then**: Default values displayed, appropriate onboarding messages shown

### 1.4 Performance & Loading States

#### Scenario: Combined Data Loading Performance
**Objective**: Verify performance requirements for combined portfolio and net worth loading

**Test Cases**:
- **TC-4.1.1**: Combined loading time under 200ms
  - **Given**: User with typical data volume (5 accounts, 50 transactions)
  - **When**: Dashboard loads
  - **Then**: Combined portfolio + net worth data loads in under 200ms

- **TC-4.1.2**: Large dataset performance
  - **Given**: User with extensive data (20 accounts, 500+ transactions)
  - **When**: Dashboard loads
  - **Then**: Performance remains acceptable, loading states shown appropriately

- **TC-4.1.3**: Concurrent loading strategy
  - **Given**: Dashboard uses concurrent loading for portfolio and net worth
  - **When**: Dashboard loads
  - **Then**: Both datasets load in parallel, total time minimized

#### Scenario: Loading State Management
**Objective**: Verify proper loading state indicators during data fetching

**Test Cases**:
- **TC-4.2.1**: Initial loading state
  - **Given**: Dashboard is loading for first time
  - **When**: Mount function executes
  - **Then**: Loading indicators show for both portfolio and net worth sections

- **TC-4.2.2**: Incremental loading display
  - **Given**: Portfolio data loads faster than net worth data
  - **When**: Portfolio data becomes available first
  - **Then**: Portfolio section displays while net worth section continues loading

- **TC-4.2.3**: Loading state during refresh
  - **Given**: User triggers manual data refresh
  - **When**: Refresh process starts
  - **Then**: Appropriate loading indicators shown without disrupting current display

## 2. Specific Test Cases with Expected Behaviors

### 2.1 Automated Test Requirements

#### Unit Tests (lib/ashfolio_web/live/dashboard_live.ex)

```elixir
# Example test structure for new functionality
describe "net worth integration" do
  test "loads net worth data alongside portfolio data", %{conn: conn} do
    # Setup user with investment and cash accounts
    user = create_test_user()
    create_investment_account(user, balance: "5000.00")
    create_cash_account(user, :checking, balance: "2500.00")
    create_test_transactions(user)
    
    {:ok, view, html} = live(conn, "/")
    
    # Verify both portfolio and net worth data displayed
    assert html =~ "Portfolio Dashboard"
    assert html =~ "Net Worth"
    assert html =~ "$7,500.00"  # Combined total
    assert html =~ "Investment" 
    assert html =~ "Cash"
  end

  test "handles net worth calculation errors gracefully", %{conn: conn} do
    # Mock net worth calculation failure
    # Verify portfolio still works, error handling for net worth
  end

  test "subscribes to net worth PubSub topic on mount", %{conn: conn} do
    # Verify PubSub subscription includes "net_worth" topic
  end
end

describe "net worth PubSub handling" do
  test "handles net_worth_updated messages", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    
    # Send net worth update message
    net_worth_data = %{net_worth: Decimal.new("10000"), investment_value: Decimal.new("7000")}
    send(view.pid, {:net_worth_updated, "user_id", net_worth_data})
    
    # Verify display updates
    html = render(view)
    assert html =~ "$10,000.00"
    assert html =~ "$7,000.00"
  end
end
```

#### Integration Tests (test/integration/dashboard_net_worth_integration_test.exs)

```elixir
describe "dashboard net worth integration" do
  test "end-to-end net worth display with real data flow" do
    # Create complete user scenario
    # Verify data flows from database through calculators to display
    # Test real PubSub event flows
  end

  test "combined portfolio and net worth performance" do
    # Create large dataset
    # Measure combined loading performance
    # Verify under 200ms requirement
  end
end
```

### 2.2 Manual Testing Scenarios

#### Manual Test Case: MT-1 - Complete User Journey
1. **Setup**: Create fresh user account
2. **Step 1**: Navigate to dashboard (should show empty/default state)
3. **Step 2**: Add investment account with transactions
4. **Step 3**: Verify portfolio data appears, net worth shows investment value only
5. **Step 4**: Add cash accounts (checking, savings)
6. **Step 5**: Verify net worth updates to include cash, breakdown percentages correct
7. **Step 6**: Update account balance in real-time
8. **Step 7**: Verify dashboard updates without refresh

#### Manual Test Case: MT-2 - Error Recovery Testing
1. **Setup**: User with working portfolio
2. **Step 1**: Simulate net worth service failure
3. **Step 2**: Verify portfolio continues working
4. **Step 3**: Verify appropriate error messages
5. **Step 4**: Restore net worth service
6. **Step 5**: Verify recovery and full functionality

#### Manual Test Case: MT-3 - Responsive Design Validation
1. **Test on mobile device** (iOS Safari, Android Chrome)
2. **Test on tablet** (iPad, Android tablet)
3. **Test on desktop** (Chrome, Firefox, Safari)
4. **Verify**: All net worth sections responsive, readable, functional

### 2.3 Performance Testing Requirements

#### Load Testing Scenarios
- **P1**: 100 concurrent users loading dashboard
- **P2**: Single user with 1000+ transactions
- **P3**: Rapid successive PubSub updates (stress test)

#### Performance Acceptance Criteria
- **Initial Load**: Combined portfolio + net worth < 200ms
- **PubSub Updates**: Display refresh < 100ms after event
- **Memory Usage**: No memory leaks during extended usage
- **CPU Usage**: No sustained high CPU during normal operation

## 3. Error Handling and Edge Case Testing

### 3.1 Error Scenarios

#### Network/Service Errors
- **E1**: Database connection failure during net worth calculation
- **E2**: Context API timeout
- **E3**: PubSub service unavailable
- **E4**: Cache service failure

#### Data Integrity Errors
- **E5**: Corrupted account balance data
- **E6**: Missing transaction records affecting calculations
- **E7**: Decimal precision overflow scenarios
- **E8**: Invalid user ID scenarios

#### Concurrency Errors  
- **E9**: Multiple simultaneous PubSub updates
- **E10**: Race conditions between portfolio and net worth calculations
- **E11**: User account modifications during calculation

### 3.2 Edge Case Scenarios

#### Data Configuration Edge Cases
- **EC1**: User with 100+ accounts
- **EC2**: Accounts with extreme balance values (very large/small)
- **EC3**: International currency scenarios
- **EC4**: Accounts with null/undefined balances

#### User Behavior Edge Cases
- **EC5**: Rapid navigation away from and back to dashboard
- **EC6**: Browser refresh during loading
- **EC7**: Multiple browser tabs with same dashboard
- **EC8**: Extended period with dashboard open (memory leaks)

## 4. User Acceptance Criteria

### 4.1 Functional Acceptance Criteria

#### Core Functionality
- [ ] **UAC-F1**: Dashboard displays comprehensive net worth alongside portfolio data
- [ ] **UAC-F2**: Investment vs cash breakdown clearly visible and accurate
- [ ] **UAC-F3**: Account type breakdown shows appropriate detail
- [ ] **UAC-F4**: Real-time updates work without page refresh
- [ ] **UAC-F5**: Error handling maintains dashboard usability

#### Data Accuracy
- [ ] **UAC-D1**: Net worth calculation matches manual calculation
- [ ] **UAC-D2**: Investment value consistent between portfolio and net worth sections
- [ ] **UAC-D3**: Cash balance accurately reflects all active cash accounts
- [ ] **UAC-D4**: Excluded accounts properly omitted from calculations
- [ ] **UAC-D5**: Percentage breakdowns sum to 100%

### 4.2 Performance Acceptance Criteria

#### Response Times
- [ ] **UAC-P1**: Initial dashboard load < 200ms for typical user
- [ ] **UAC-P2**: PubSub updates visible < 100ms after trigger
- [ ] **UAC-P3**: No noticeable performance regression vs current dashboard
- [ ] **UAC-P4**: Concurrent loading strategy improves perceived performance

#### Reliability
- [ ] **UAC-R1**: Dashboard maintains 99.9% uptime during testing
- [ ] **UAC-R2**: Error scenarios result in graceful degradation, not crashes
- [ ] **UAC-R3**: Data consistency maintained across all scenarios
- [ ] **UAC-R4**: Memory usage remains stable during extended use

### 4.3 User Experience Acceptance Criteria

#### Usability
- [ ] **UAC-U1**: Net worth information is immediately understandable
- [ ] **UAC-U2**: Visual hierarchy clearly distinguishes portfolio vs net worth data
- [ ] **UAC-U3**: Responsive design works seamlessly across devices
- [ ] **UAC-U4**: Loading states provide appropriate feedback
- [ ] **UAC-U5**: Error messages are helpful and actionable

#### Accessibility
- [ ] **UAC-A1**: All new elements meet WCAG 2.1 AA standards
- [ ] **UAC-A2**: Screen reader compatible
- [ ] **UAC-A3**: Keyboard navigation functional
- [ ] **UAC-A4**: Sufficient color contrast for all text/backgrounds
- [ ] **UAC-A5**: Focus indicators visible and logical

## 5. Test Data Requirements

### 5.1 Test User Profiles

#### Profile 1: Investment-Focused User
- 3 investment accounts (Schwab, Fidelity, Vanguard)
- Total investment value: $45,000
- 1 checking account: $2,500
- 1 savings account: $10,000
- 25 transactions across 8 different stocks

#### Profile 2: Cash-Heavy User
- 1 investment account: $8,000
- 3 checking accounts: $5,000, $2,000, $1,500
- 2 savings accounts: $25,000, $15,000
- 1 money market account: $12,000
- Minimal transactions (5 total)

#### Profile 3: Balanced Portfolio User
- 2 investment accounts: $22,000 total
- 2 cash accounts: $23,000 total
- Mixed transactions (30 total)
- Some excluded accounts for testing

#### Profile 4: Edge Case User
- 10+ accounts of various types
- Some zero-balance accounts
- Some excluded accounts
- Large transaction history (100+ transactions)

### 5.2 Test Data Generation

#### Automated Data Setup
```elixir
defmodule TestDataGenerator do
  def create_investment_focused_user do
    user = create_user()
    create_investment_accounts(user, count: 3, total_value: 45000)
    create_cash_accounts(user, checking: 2500, savings: 10000)
    create_transactions(user, count: 25)
    user
  end
  
  def create_cash_heavy_user do
    # Implementation for cash-heavy scenario
  end
end
```

### 5.3 Database State Management

#### Test Isolation
- Each test scenario uses clean database state
- Proper setup and teardown for all test data
- No data persistence between test runs
- Parallel test execution safety

## 6. Test Execution Strategy

### 6.1 Test Phases

#### Phase 1: Unit Testing (Days 1-2)
- NetWorthCalculator integration tests
- DashboardLive component tests
- PubSub message handling tests
- Error handling unit tests

#### Phase 2: Integration Testing (Days 3-4)
- End-to-end data flow tests
- Combined portfolio + net worth scenarios
- Real PubSub event testing
- Performance baseline establishment

#### Phase 3: Manual Testing (Days 5-6)
- User journey testing
- Cross-browser compatibility
- Responsive design validation
- Edge case exploration

#### Phase 4: Performance & Load Testing (Day 7)
- Load testing with concurrent users
- Stress testing with large datasets
- Memory leak detection
- Performance optimization validation

### 6.2 Test Environment Setup

#### Development Environment
- Local SQLite database with test data
- All services running locally
- Test data seeded via mix tasks
- PubSub system fully functional

#### Staging Environment
- Production-like data volumes
- External service integrations enabled
- Performance monitoring active
- Load testing infrastructure available

### 6.3 Acceptance Testing Process

#### Acceptance Test Sessions
1. **Technical Review**: Code review with development team
2. **Functional Review**: Feature walkthrough with product stakeholder
3. **Performance Review**: Performance metrics validation
4. **User Experience Review**: UI/UX validation session

#### Sign-off Criteria
- All automated tests passing (>95% success rate)
- All UAC criteria met
- Performance benchmarks achieved
- No critical or high-severity defects
- User experience approval from stakeholder

## 7. Risk Assessment

### 7.1 Technical Risks

#### High Risk
- **TR-H1**: Performance degradation with combined data loading
  - **Mitigation**: Concurrent loading strategy, performance monitoring
- **TR-H2**: PubSub message conflicts affecting existing functionality
  - **Mitigation**: Separate topic namespaces, comprehensive integration testing

#### Medium Risk  
- **TR-M1**: Data consistency issues between portfolio and net worth calculations
  - **Mitigation**: Shared calculation dependencies, integration tests
- **TR-M2**: Browser compatibility issues with real-time updates
  - **Mitigation**: Cross-browser testing, progressive enhancement

#### Low Risk
- **TR-L1**: UI layout issues on various screen sizes
  - **Mitigation**: Responsive design testing, existing grid system
- **TR-L2**: Accessibility compliance for new elements
  - **Mitigation**: Following existing patterns, accessibility testing

### 7.2 Schedule Risks

#### Potential Delays
- Complex PubSub integration testing may require additional time
- Performance optimization if initial implementation doesn't meet requirements
- Cross-browser compatibility issues requiring significant rework

#### Mitigation Strategies
- Buffer time allocated for integration testing
- Early performance testing to identify issues
- Progressive enhancement approach for browser compatibility

## 8. Success Metrics & KPIs

### 8.1 Technical Metrics

#### Automated Testing Coverage
- **Target**: >90% test coverage for new functionality
- **Measurement**: Code coverage reports from ExCoveralls
- **Success Criteria**: All critical paths covered

#### Performance Metrics
- **Target**: <200ms combined loading time
- **Measurement**: Phoenix LiveDashboard timing metrics
- **Success Criteria**: 95th percentile under target

#### Error Rate
- **Target**: <0.1% error rate during normal operation
- **Measurement**: Error monitoring and logging
- **Success Criteria**: Graceful degradation in all error scenarios

### 8.2 User Experience Metrics

#### Usability Metrics
- **Target**: Zero user confusion about net worth vs portfolio data
- **Measurement**: User feedback and testing sessions
- **Success Criteria**: Clear visual distinction and understanding

#### Response Time Perception
- **Target**: Users perceive dashboard as responsive
- **Measurement**: User testing feedback
- **Success Criteria**: No complaints about loading times

### 8.3 Quality Metrics

#### Defect Density
- **Target**: <2 defects per 100 lines of new code
- **Measurement**: Defect tracking during testing
- **Success Criteria**: All high/critical defects resolved

#### Code Quality
- **Target**: Maintain existing code quality standards
- **Measurement**: Static analysis tools, code review feedback
- **Success Criteria**: No degradation in maintainability metrics

## Conclusion

This comprehensive QA testing plan ensures that Task 11's net worth integration enhancement maintains the high quality standards of the Ashfolio project while adding valuable new functionality. The plan covers all aspects from unit testing to user acceptance, with clear success criteria and risk mitigation strategies.

The testing approach balances thorough coverage with efficient execution, ensuring that the enhanced dashboard provides users with a complete financial picture while maintaining the reliability and performance of the existing portfolio functionality.