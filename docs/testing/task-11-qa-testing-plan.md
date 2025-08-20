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

- DashboardLive enhancements, net worth display, PubSub integration, error handling, UI responsiveness
- Historical net worth tracking, advanced visualizations, export functionality

## 1. Detailed Test Scenarios

### 1.1 Net Worth Data Integration

#### Scenario: Basic Net Worth Display

Verify net worth data loads and displays correctly alongside portfolio data

- Dashboard loads with both portfolio and net worth data

- User has investment and cash accounts with transactions
- User navigates to dashboard
- Portfolio summary cards display existing data AND net worth summary cards show total net worth, investment value, cash value
- Net worth = Investment value + Cash balance

- Net worth calculation accuracy

- User has $10,000 in investments (10 shares @ $100 current price) and $5,000 cash
- Dashboard loads
- Net worth displays $15,000, Investment value shows $10,000, Cash balance shows $5,000

- Zero net worth handling
- User has no accounts or all accounts have zero balance
- Dashboard loads
- All net worth cards display $0.00 formatted correctly

#### Scenario: Investment vs Cash Breakdown

Verify investment and cash breakdown visualization accuracy

- Investment-heavy portfolio breakdown

- User has $20,000 investments and $2,000 cash
- Dashboard loads
- Breakdown shows 90% investments, 10% cash with correct visual representation

- Cash-heavy portfolio breakdown

- User has $3,000 investments and $15,000 cash
- Dashboard loads
- Breakdown shows 17% investments, 83% cash with correct visual representation

- Equal investment and cash breakdown
- User has $10,000 investments and $10,000 cash
- Dashboard loads
- Breakdown shows 50% investments, 50% cash

#### Scenario: Account Type Breakdown

Verify account type breakdown displays correctly

- Multiple cash account types

- User has checking ($2,000), savings ($8,000), money market ($5,000)
- Dashboard loads
- Account breakdown shows 3 cash accounts, $15,000 total, with individual account type breakdowns

- Mixed account types

- User has 2 investment accounts and 3 cash accounts
- Dashboard loads
- Breakdown shows correct counts and totals for each account type

- Single account type only
- User has only investment accounts (no cash) OR only cash accounts (no investments)
- Dashboard loads
- Breakdown shows appropriate display for single account type scenario

### 1.2 Real-Time PubSub Updates

#### Scenario: Net Worth PubSub Subscription

Verify dashboard subscribes to net worth PubSub topic

- PubSub subscription on mount

- Dashboard is loading
- Mount function executes
- Dashboard subscribes to "net_worth" topic alongside existing "accounts" and "transactions" topics

- Multiple PubSub subscriptions coexist
- Dashboard has mounted
- Account, transaction, and net worth events are broadcast
- Dashboard handles all event types without conflicts

#### Scenario: Real-Time Net Worth Updates

Verify net worth updates in real-time when underlying data changes

- Cash balance update triggers net worth refresh

- Dashboard is loaded showing current net worth
- Cash account balance is updated via BalanceManager
- Net worth display updates within 100ms without page refresh

- Investment value change triggers net worth refresh

- Dashboard shows current net worth with investment value
- Stock price updates causing portfolio value change
- Net worth and breakdown percentages update automatically

- Multiple simultaneous updates
- Dashboard is displaying current data
- Both cash balance and investment values change simultaneously
- Net worth display updates once with combined changes

#### Scenario: PubSub Message Handling

Verify correct handling of net worth PubSub messages

- Valid net worth update message

- Dashboard is mounted and subscribed
- `{:net_worth_updated, net_worth_data}` message received
- Dashboard assigns new net worth data and re-renders affected sections

- Invalid net worth update message

- Dashboard is mounted and subscribed
- Malformed net worth update message received
- Dashboard handles gracefully without crashing, logs error

- Net worth update for different user
- Dashboard is mounted for user A
- Net worth update message for user B received
- Dashboard ignores message (no update to display)

### 1.3 Error Handling & Edge Cases

#### Scenario: Net Worth Calculation Errors

Verify graceful handling of net worth calculation failures

- Net worth calculation failure with working portfolio

- Portfolio calculations work but net worth calculation fails
- Dashboard loads
- Portfolio data displays normally, net worth cards show error state or default values, specific error message displayed

- Partial net worth data available

- Investment value calculated successfully but cash balance calculation fails
- Dashboard loads
- Investment portion displays, cash portion shows error/default, partial net worth calculated where possible

- Complete net worth system failure
- All net worth related calculations fail
- Dashboard loads
- Portfolio functionality unaffected, net worth section displays appropriate error state

#### Scenario: Data Consistency Issues

Verify handling of inconsistent data between portfolio and net worth

- Portfolio and net worth calculation discrepancies

- Portfolio calculator and net worth calculator return different investment values
- Dashboard loads
- Error logged, user warned of data inconsistency, fallback display strategy used

- Stale cached data scenarios
- Net worth data is cached but underlying account data has changed
- Dashboard loads
- Fresh data is fetched, cache updated, accurate values displayed

#### Scenario: User Configuration Edge Cases

Verify handling of unusual user account configurations

- User with excluded accounts

- User has excluded accounts that should not count toward net worth
- Dashboard loads
- Excluded accounts not included in net worth calculations or breakdowns

- User with zero-balance accounts

- User has accounts with zero balances
- Dashboard loads
- Zero-balance accounts handled correctly in breakdown calculations

- New user with no accounts
- New user with no accounts created yet
- Dashboard loads
- Default values displayed, appropriate onboarding messages shown

### 1.4 Performance & Loading States

#### Scenario: Combined Data Loading Performance

Verify performance requirements for combined portfolio and net worth loading

- Combined loading time under 200ms

- User with typical data volume (5 accounts, 50 transactions)
- Dashboard loads
- Combined portfolio + net worth data loads in under 200ms

- Large dataset performance

- User with extensive data (20 accounts, 500+ transactions)
- Dashboard loads
- Performance remains acceptable, loading states shown appropriately

- Concurrent loading strategy
- Dashboard uses concurrent loading for portfolio and net worth
- Dashboard loads
- Both datasets load in parallel, total time minimized

#### Scenario: Loading State Management

Verify proper loading state indicators during data fetching

- Initial loading state

- Dashboard is loading for first time
- Mount function executes
- Loading indicators show for both portfolio and net worth sections

- Incremental loading display

- Portfolio data loads faster than net worth data
- Portfolio data becomes available first
- Portfolio section displays while net worth section continues loading

- Loading state during refresh
- User triggers manual data refresh
- Refresh process starts
- Appropriate loading indicators shown without disrupting current display

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

1.  Create fresh user account
2.  Navigate to dashboard (should show empty/default state)
3.  Add investment account with transactions
4.  Verify portfolio data appears, net worth shows investment value only
5.  Add cash accounts (checking, savings)
6.  Verify net worth updates to include cash, breakdown percentages correct
7.  Update account balance in real-time
8.  Verify dashboard updates without refresh

#### Manual Test Case: MT-2 - Error Recovery Testing

1.  User with working portfolio
2.  Simulate net worth service failure
3.  Verify portfolio continues working
4.  Verify appropriate error messages
5.  Restore net worth service
6.  Verify recovery and full functionality

#### Manual Test Case: MT-3 - Responsive Design Validation

1. **Test on mobile device** (iOS Safari, Android Chrome)
2. **Test on tablet** (iPad, Android tablet)
3. **Test on desktop** (Chrome, Firefox, Safari)
4. All net worth sections responsive, readable, functional

### 2.3 Performance Testing Requirements

#### Load Testing Scenarios

- 100 concurrent users loading dashboard
- Single user with 1000+ transactions
- Rapid successive PubSub updates (stress test)

#### Performance Acceptance Criteria

- Combined portfolio + net worth < 200ms
- Display refresh < 100ms after event
- No memory leaks during extended usage
- No sustained high CPU during normal operation

## 3. Error Handling and Edge Case Testing

### 3.1 Error Scenarios

#### Network/Service Errors

- Database connection failure during net worth calculation
- Context API timeout
- PubSub service unavailable
- Cache service failure

#### Data Integrity Errors

- Corrupted account balance data
- Missing transaction records affecting calculations
- Decimal precision overflow scenarios
- Invalid user ID scenarios

#### Concurrency Errors

- Multiple simultaneous PubSub updates
- Race conditions between portfolio and net worth calculations
- User account modifications during calculation

### 3.2 Edge Case Scenarios

#### Data Configuration Edge Cases

- User with 100+ accounts
- Accounts with extreme balance values (very large/small)
- International currency scenarios
- Accounts with null/undefined balances

#### User Behavior Edge Cases

- Rapid navigation away from and back to dashboard
- Browser refresh during loading
- Multiple browser tabs with same dashboard
- Extended period with dashboard open (memory leaks)

## 4. User Acceptance Criteria

### 4.1 Functional Acceptance Criteria

#### Core Functionality

- [ ] Dashboard displays comprehensive net worth alongside portfolio data
- [ ] Investment vs cash breakdown clearly visible and accurate
- [ ] Account type breakdown shows appropriate detail
- [ ] Real-time updates work without page refresh
- [ ] Error handling maintains dashboard usability

#### Data Accuracy

- [ ] Net worth calculation matches manual calculation
- [ ] Investment value consistent between portfolio and net worth sections
- [ ] Cash balance accurately reflects all active cash accounts
- [ ] Excluded accounts properly omitted from calculations
- [ ] Percentage breakdowns sum to 100%

### 4.2 Performance Acceptance Criteria

#### Response Times

- [ ] Initial dashboard load < 200ms for typical user
- [ ] PubSub updates visible < 100ms after trigger
- [ ] No noticeable performance regression vs current dashboard
- [ ] Concurrent loading strategy improves perceived performance

#### Reliability

- [ ] Dashboard maintains 99.9% uptime during testing
- [ ] Error scenarios result in graceful degradation, not crashes
- [ ] Data consistency maintained across all scenarios
- [ ] Memory usage remains stable during extended use

### 4.3 User Experience Acceptance Criteria

#### Usability

- [ ] Net worth information is immediately understandable
- [ ] Visual hierarchy clearly distinguishes portfolio vs net worth data
- [ ] Responsive design works seamlessly across devices
- [ ] Loading states provide appropriate feedback
- [ ] Error messages are helpful and actionable

#### Accessibility

- [ ] All new elements meet WCAG 2.1 AA standards
- [ ] Screen reader compatible
- [ ] Keyboard navigation functional
- [ ] Sufficient color contrast for all text/backgrounds
- [ ] Focus indicators visible and logical

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

1.  Code review with development team
2.  Feature walkthrough with product stakeholder
3.  Performance metrics validation
4.  UI/UX validation session

#### Sign-off Criteria

- All automated tests passing (>95% success rate)
- All UAC criteria met
- Performance benchmarks achieved
- No critical or high-severity defects
- User experience approval from stakeholder

## 7. Risk Assessment

### 7.1 Technical Risks

#### High Risk

- Performance degradation with combined data loading
- Concurrent loading strategy, performance monitoring
- PubSub message conflicts affecting existing functionality
- Separate topic namespaces, comprehensive integration testing

#### Medium Risk

- Data consistency issues between portfolio and net worth calculations
- Shared calculation dependencies, integration tests
- Browser compatibility issues with real-time updates
- Cross-browser testing, progressive enhancement

#### Low Risk

- UI layout issues on various screen sizes
- Responsive design testing, existing grid system
- Accessibility compliance for new elements
- Following existing patterns, accessibility testing

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

- > 90% test coverage for new functionality
- Code coverage reports from ExCoveralls
- All critical paths covered

#### Performance Metrics

- <200ms combined loading time
- Phoenix LiveDashboard timing metrics
- 95th percentile under target

#### Error Rate

- <0.1% error rate during normal operation
- Error monitoring and logging
- Graceful degradation in all error scenarios

### 8.2 User Experience Metrics

#### Usability Metrics

- Zero user confusion about net worth vs portfolio data
- User feedback and testing sessions
- Clear visual distinction and understanding

#### Response Time Perception

- Users perceive dashboard as responsive
- User testing feedback
- No complaints about loading times

### 8.3 Quality Metrics

#### Defect Density

- <2 defects per 100 lines of new code
- Defect tracking during testing
- All high/critical defects resolved

#### Code Quality

- Maintain existing code quality standards
- Static analysis tools, code review feedback
- No degradation in maintainability metrics

## Conclusion

This comprehensive QA testing plan ensures that Task 11's net worth integration enhancement maintains the high quality standards of the Ashfolio project while adding valuable new functionality. The plan covers all aspects from unit testing to user acceptance, with clear success criteria and risk mitigation strategies.

The testing approach balances thorough coverage with efficient execution, ensuring that the enhanced dashboard provides users with a complete financial picture while maintaining the reliability and performance of the existing portfolio functionality.
