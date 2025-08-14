# IMPLEMENTATION_PLAN.md | Task 11: Enhance DashboardLive with Net Worth Integration

## Overview
Enhance the existing DashboardLive to display comprehensive net worth information alongside the current portfolio functionality. This integrates the newly completed NetWorthCalculator, BalanceManager, and Context API capabilities into the dashboard for real-time financial management.

## Architecture Analysis
Based on codebase study:
- **Existing DashboardLive**: Well-established portfolio dashboard at `lib/ashfolio_web/live/dashboard_live.ex` with PubSub subscriptions, error handling, and comprehensive portfolio display
- **NetWorthCalculator**: Complete module at `lib/ashfolio/financial_management/net_worth_calculator.ex` with investment + cash calculation and PubSub broadcasting
- **Context API**: Enhanced `lib/ashfolio/context.ex` with `get_net_worth/1` function providing comprehensive breakdown
- **Testing Patterns**: Established LiveView testing patterns in `test/ashfolio_web/live/dashboard_live_test.exs` and PubSub testing in `test/ashfolio_web/live/dashboard_pubsub_test.exs`

## Technical Requirements (from v0.2.0 roadmap)
- Update DashboardLive to display net worth summary alongside portfolio summary
- Add investment vs cash breakdown visualization  
- Integrate real-time net worth updates via PubSub subscription
- Add account type breakdown display (investment accounts vs cash accounts)
- Update dashboard loading and error handling for net worth calculations
- Write LiveView tests for enhanced dashboard including net worth display and real-time updates

## Stage 1: Net Worth Data Integration
**Goal**: Add net worth data loading to existing DashboardLive without disrupting portfolio functionality
**Success Criteria**: 
- Net worth data loads alongside existing portfolio data
- Error handling maintains existing graceful degradation patterns
- No impact on existing portfolio display functionality
**Tests**:
- `test "loads net worth data alongside portfolio data"`
- `test "handles net worth calculation errors gracefully"`
- `test "maintains portfolio display when net worth unavailable"`
**Status**: Not Started

## Stage 2: Dashboard UI Enhancement
**Goal**: Add net worth summary cards and breakdown displays to dashboard template
**Success Criteria**:
- Net worth summary cards display total net worth, investment value, cash value
- Account type breakdown shows investment vs cash account counts and percentages
- Investment vs cash visualization clearly distinguishes account types
- Responsive design maintains existing dashboard layout patterns
**Tests**:
- `test "displays net worth summary cards with correct values"`
- `test "shows investment vs cash breakdown"`
- `test "displays account type breakdown correctly"`
- `test "maintains responsive design with new net worth sections"`
**Status**: Not Started

## Stage 3: PubSub Integration for Real-Time Updates  
**Goal**: Subscribe to net worth PubSub events and update dashboard in real-time
**Success Criteria**:
- Dashboard subscribes to "net_worth" topic on mount
- Handles `:net_worth_updated` messages and refreshes net worth display
- Real-time updates work alongside existing account/transaction PubSub subscriptions
- No conflicts with existing PubSub message handling
**Tests**:
- `test "subscribes to net worth PubSub topic on mount"`
- `test "handles net_worth_updated messages"`
- `test "updates net worth display in real-time"`
- `test "net worth PubSub works alongside existing subscriptions"`
**Status**: Not Started

## Stage 4: Loading States and Error Handling
**Goal**: Enhance dashboard loading and error handling for net worth calculations
**Success Criteria**:
- Loading states handle both portfolio and net worth calculations
- Error handling provides specific feedback for net worth vs portfolio issues
- Partial failure scenarios gracefully degrade (e.g., portfolio works but net worth fails)
- Loading indicators properly reflect net worth calculation progress
**Tests**:
- `test "shows loading state during net worth calculations"`
- `test "handles partial failure scenarios gracefully"`
- `test "provides specific error messages for net worth calculation failures"`
- `test "loading indicators work for combined portfolio and net worth loading"`
**Status**: Not Started

## Stage 5: Comprehensive LiveView Testing
**Goal**: Complete test suite for enhanced dashboard including net worth functionality and real-time updates
**Success Criteria**:
- Unit tests for all new net worth display components
- Integration tests for combined portfolio + net worth dashboard
- PubSub event handling tests for net worth updates
- Edge case testing for various account configurations
- >85% test coverage for enhanced dashboard functionality
**Tests**:
- Enhanced `dashboard_live_test.exs` with net worth scenarios
- Enhanced `dashboard_pubsub_test.exs` with net worth PubSub events
- Performance tests for combined portfolio + net worth calculations
- Edge case tests (no cash accounts, no investment accounts, etc.)
**Status**: Not Started

## Technical Specifications

### Enhanced DashboardLive Structure
```elixir
defmodule AshfolioWeb.DashboardLive do
  # Existing imports and aliases
  alias Ashfolio.FinancialManagement.NetWorthCalculator
  
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Existing subscriptions
      Ashfolio.PubSub.subscribe("accounts")
      Ashfolio.PubSub.subscribe("transactions")
      # New subscription for net worth updates
      Ashfolio.PubSub.subscribe("net_worth")
    end
    
    socket =
      socket
      |> assign_current_page(:dashboard)
      |> assign(:page_title, "Dashboard")
      |> assign(:loading, false)
      |> assign(:net_worth_loading, false)
      |> load_portfolio_data()
      |> load_net_worth_data()  # New function
  end
  
  # New PubSub handler for net worth updates
  def handle_info({:net_worth_updated, _user_id, net_worth_data}, socket) do
    {:noreply, assign_net_worth_data(socket, net_worth_data)}
  end
end
```

### Enhanced Dashboard Template Structure
```heex
<div class="space-y-6">
  <!-- Existing Page Header -->
  
  <!-- Enhanced Summary Cards (Portfolio + Net Worth) -->
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
    <!-- Existing Portfolio Cards (first 3) -->
    <.stat_card title="Total Value" value={@portfolio_value} ... />
    <.stat_card title="Total Return" value={@total_return_amount} ... />
    <.stat_card title="Holdings" value={@holdings_count} ... />
    
    <!-- New Net Worth Cards (last 2) -->
    <.stat_card 
      title="Net Worth" 
      value={@net_worth_total}
      change={@net_worth_change}
      data_testid="net-worth-total" />
    <.stat_card 
      title="Cash Balance" 
      value={@cash_balance}
      change={@cash_percentage}
      data_testid="cash-balance" />
  </div>
  
  <!-- New Net Worth Breakdown Section -->
  <.card>
    <:header>Net Worth Breakdown</:header>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <!-- Investment vs Cash Visualization -->
      <!-- Account Type Breakdown -->
    </div>
  </.card>
  
  <!-- Existing Holdings Table and Recent Activity -->
</div>
```

### Data Loading Strategy
```elixir
defp load_dashboard_data(socket) do
  user_id = get_default_user_id()
  
  # Load portfolio and net worth data concurrently using Task.async_stream
  tasks = [
    {:portfolio, fn -> load_portfolio_data_for_user(user_id) end},
    {:net_worth, fn -> load_net_worth_data_for_user(user_id) end}
  ]
  
  results = 
    tasks
    |> Task.async_stream(fn {key, fun} -> {key, fun.()} end, timeout: 5000)
    |> Enum.into(%{})
  
  socket
  |> assign_portfolio_data(results[:portfolio])
  |> assign_net_worth_data(results[:net_worth])
end
```

### Context API Integration
```elixir
# Use existing Context.get_net_worth/1 function
defp load_net_worth_data_for_user(user_id) do
  case Ashfolio.Context.get_net_worth(user_id) do
    {:ok, net_worth_data} -> 
      {:ok, net_worth_data}
    {:error, reason} -> 
      Logger.warning("Failed to load net worth data: #{inspect(reason)}")
      {:error, reason}
  end
end
```

## Integration Points with Existing Code

### 1. Context API Usage
- **Use existing**: `Ashfolio.Context.get_net_worth/1` function for comprehensive data
- **PubSub integration**: NetWorthCalculator already broadcasts to "net_worth" topic
- **Error handling**: Follow existing Context API error patterns

### 2. DashboardLive Enhancements
- **Mount function**: Add net worth PubSub subscription alongside existing ones  
- **Data loading**: Extend `load_portfolio_data/1` pattern for net worth
- **PubSub handlers**: Add net worth handlers alongside existing account/transaction handlers
- **Template**: Extend existing grid layout for net worth cards and breakdown section

### 3. Testing Strategy
- **Extend existing tests**: Add net worth scenarios to `dashboard_live_test.exs`
- **PubSub testing**: Add net worth PubSub scenarios to `dashboard_pubsub_test.exs`
- **Follow patterns**: Use existing test setup patterns with user/account/transaction creation
- **Integration tests**: Ensure combined portfolio + net worth calculations work together

## Data Flow Architecture

### 1. Initial Load
```
DashboardLive.mount/3
  → get_default_user_id()
  → Context.get_portfolio_summary(user_id)  [existing]
  → Context.get_net_worth(user_id)          [new]
  → assign portfolio and net worth data to socket
  → render enhanced dashboard template
```

### 2. Real-Time Updates  
```
BalanceManager.update_cash_balance/3
  → NetWorthCalculator.calculate_net_worth/1  [triggered by Context call]
  → PubSub.broadcast("net_worth", {:net_worth_updated, user_id, data})
  → DashboardLive.handle_info/2 receives message
  → assign new net worth data to socket
  → LiveView automatically re-renders affected template sections
```

### 3. Error Recovery
```
Context.get_net_worth/1 fails
  → assign default/empty net worth values
  → display portfolio data normally
  → show specific error message for net worth section
  → allow manual refresh to retry net worth calculation
```

## Risk Assessment & Mitigation

### Risk 1: Performance Impact
**Risk**: Adding net worth calculations could slow dashboard loading
**Mitigation**: 
- Use concurrent loading with Task.async_stream for portfolio + net worth  
- Implement loading states for incremental display
- Cache net worth calculations in Context API/ETS as done for portfolio

### Risk 2: UI Layout Disruption
**Risk**: New net worth sections could break existing dashboard layout
**Mitigation**:
- Use responsive grid system that gracefully handles additional cards
- Test extensively on mobile/tablet breakpoints
- Maintain existing accessibility and testid patterns

### Risk 3: PubSub Message Conflicts
**Risk**: New net worth PubSub subscriptions could interfere with existing ones
**Mitigation**:
- Use separate "net_worth" topic namespace 
- Maintain existing message handling patterns
- Test all PubSub interactions thoroughly

### Risk 4: Data Consistency Issues
**Risk**: Portfolio and net worth calculations could show inconsistent data
**Mitigation**:
- Both calculations use same Context API patterns
- NetWorthCalculator uses Portfolio.Calculator for investment values
- Comprehensive integration tests verify data consistency

## Success Metrics

### Technical Goals
1. **Performance**: Combined portfolio + net worth loading under 200ms for typical data
2. **Reliability**: Dashboard loads successfully even if net worth calculation fails  
3. **Real-time**: Net worth updates appear in dashboard within 100ms of balance changes
4. **Compatibility**: All existing portfolio functionality preserved and unaffected

### User Experience Goals  
1. **Comprehensive View**: Dashboard shows complete financial picture (investments + cash)
2. **Real-time Updates**: Net worth changes immediately reflect in dashboard
3. **Clear Breakdown**: Investment vs cash distinction is obvious and helpful
4. **Responsive Design**: Works seamlessly across mobile, tablet, desktop

### Code Quality Goals
1. **Test Coverage**: >90% coverage for enhanced dashboard functionality
2. **Maintainability**: New code follows existing patterns and conventions
3. **Performance**: No regression in existing dashboard performance
4. **Documentation**: Clear inline documentation for new functionality

## Dependencies

### Completed (Tasks 1-10) ✅
- NetWorthCalculator module with investment + cash calculation
- BalanceManager with PubSub broadcasting  
- Context API with get_net_worth/1 function
- Account resource extended for cash account types
- PubSub infrastructure for real-time updates

### Required for Task 11
- Enhanced DashboardLive with net worth integration
- Updated dashboard template with net worth sections
- Comprehensive LiveView tests for combined functionality
- Documentation updates for enhanced dashboard

## Out of Scope
- Historical net worth tracking (for future versions)
- Advanced data visualizations/charts (v0.3.0 feature)
- Net worth goal setting and planning (v0.4.0 feature)
- Export functionality for net worth data (separate task)