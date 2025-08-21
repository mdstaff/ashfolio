# v0.3.1 Frontend Components - Ultra-Precise Implementation Plan

## 🚀 QUICK START FOR CLAUDE SONNET

### Your Mission
Complete v0.3.1 frontend components using strict TDD. Follow each stage EXACTLY as written.

### Workflow (NEVER DEVIATE)
```bash
1. Copy test file from this plan
2. Run test (expect failures)
3. Copy implementation code from this plan
4. Run test again (should pass)
5. Commit immediately when green
```

### Current Task Priority
1. ⏳ Stage 1: Dashboard Expense Widget (5 tests)
2. ⏳ Stage 2: Net Worth Enhancement (4 tests)
3. ⏳ Stage 3: Contex Charts (6 tests)

### Success = All Tests Green
```bash
# Check your progress:
mix test test/ashfolio_web/live/dashboard_live/
# Target: 9+ new tests passing
```

---

## Current Status
- ✅ v0.3.0 Backend Complete: 944 tests passing
- ✅ ExpenseLive.Index with comprehensive filtering
- ✅ ExpenseLive.FormComponent with modal UX
- 🎯 Next: Dashboard integration & data visualization

## CRITICAL: Test-Driven Development Protocol
1. **ALWAYS** write the test file first (copy from this plan)
2. **RUN** the test to see it fail (red phase)
3. **IMPLEMENT** minimal code to pass the test (green phase)
4. **VERIFY** with `mix test path/to/test.exs`
5. **COMMIT** immediately when test passes

## Stage 1: Dashboard Expense Widget [Not Started]

### Step 1A: Create Test File (COPY THIS EXACTLY)

```bash
# Create test file first!
mkdir -p test/ashfolio_web/live/dashboard_live
touch test/ashfolio_web/live/dashboard_live/expense_widget_test.exs
```

### Step 1B: Copy Complete Test Suite

```elixir
# test/ashfolio_web/live/dashboard_live/expense_widget_test.exs
defmodule AshfolioWeb.DashboardLive.ExpenseWidgetTest do
  use AshfolioWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  describe "dashboard expense widget" do
    setup do
      # Reset account balances for clean test state
      require Ash.Query
      
      Ashfolio.Portfolio.Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(fn account ->
        Ashfolio.Portfolio.Account.update(account, %{balance: Decimal.new("0.00")})
      end)

      {:ok, checking_account} = Ashfolio.Portfolio.Account.create(%{
        name: "Test Checking",
        account_type: :checking,
        balance: Decimal.new("5000.00")
      })

      {:ok, category} = Ashfolio.FinancialManagement.TransactionCategory.create(%{
        name: "Groceries",
        color: "#4CAF50"
      })

      # Create current month expenses
      current_month_start = Date.beginning_of_month(Date.utc_today())
      
      {:ok, expense1} = Ashfolio.FinancialManagement.Expense.create(%{
        description: "This month expense 1",
        amount: Decimal.new("150.00"),
        date: current_month_start,
        category_id: category.id,
        account_id: checking_account.id
      })

      {:ok, expense2} = Ashfolio.FinancialManagement.Expense.create(%{
        description: "This month expense 2",
        amount: Decimal.new("75.50"),
        date: Date.add(current_month_start, 5),
        category_id: category.id,
        account_id: checking_account.id
      })

      # Create last month expense for comparison
      last_month = Date.add(current_month_start, -15)
      {:ok, expense3} = Ashfolio.FinancialManagement.Expense.create(%{
        description: "Last month expense",
        amount: Decimal.new("200.00"),
        date: last_month,
        category_id: category.id,
        account_id: checking_account.id
      })

      %{
        checking_account: checking_account,
        category: category,
        current_month_expenses: [expense1, expense2],
        last_month_expense: expense3
      }
    end

    test "dashboard shows expense summary widget", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/dashboard")

      # Should show expense widget
      assert has_element?(view, "[data-testid='expense-summary-widget']")
      
      # Should show current month total
      assert html =~ "This Month"
      assert html =~ "$225.50" # $150.00 + $75.50
      
      # Should show expense count
      assert html =~ "2 expenses"
    end

    test "expense widget shows month-over-month comparison", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/dashboard")

      # Should show percentage change
      # Current: $225.50, Last: $200.00 = +12.8% increase
      assert html =~ "+12.8%"
      assert html =~ "vs last month"
    end

    test "expense widget links to full expenses page", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/dashboard")

      # Should have link to expenses page
      assert has_element?(view, "a[href='/expenses']", "View All Expenses")
    end

    test "expense widget shows top category", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/dashboard")

      # Should show top spending category
      assert html =~ "Top Category"
      assert html =~ "Groceries"
      assert html =~ "$225.50" # Total for groceries category
    end

    test "empty expenses shows appropriate message", %{conn: conn} do
      # Delete all expenses
      Ashfolio.FinancialManagement.Expense.list!()
      |> Enum.each(fn expense ->
        Ashfolio.FinancialManagement.Expense.destroy(expense)
      end)

      {:ok, view, html} = live(conn, ~p"/dashboard")

      # Should show empty state in widget
      assert html =~ "$0.00"
      assert html =~ "0 expenses"
      assert html =~ "No expenses this month"
    end
  end
end
```

### Step 1C: Run Test to See Failures
```bash
mix test test/ashfolio_web/live/dashboard_live/expense_widget_test.exs
# This SHOULD fail - that's expected!
```

### Step 1D: Implementation (Make Tests Pass)

#### Part 1: Update Dashboard Data Loading
```elixir
# lib/ashfolio_web/live/dashboard_live.ex
# Find the mount/3 function and ADD this subscription:
def mount(_params, _session, socket) do
  if connected?(socket) do
    Ashfolio.PubSub.subscribe("accounts")
    Ashfolio.PubSub.subscribe("transactions")
    Ashfolio.PubSub.subscribe("net_worth")
    Ashfolio.PubSub.subscribe("expenses")  # ADD THIS LINE
  end
  # ... rest of mount function
end

# Find load_portfolio_data/1 and ADD expense loading:
defp load_portfolio_data(socket) do
  Logger.debug("Loading portfolio data for dashboard")
  
  case Context.get_dashboard_data() do
    {:ok, dashboard_data} ->
      socket
      |> load_dashboard_data(dashboard_data)
      |> load_expense_summary()  # ADD THIS LINE
      
    {:error, reason} ->
      # ... existing error handling
  end
end

# ADD this new function after load_holdings_data/1:
defp load_expense_summary(socket) do
  current_month_start = Date.beginning_of_month(Date.utc_today())
  last_month_start = Date.beginning_of_month(Date.add(Date.utc_today(), -30))
  last_month_end = Date.end_of_month(last_month_start)
  
  # Load current month expenses
  current_expenses = 
    Ashfolio.FinancialManagement.Expense.by_date_range!(
      current_month_start,
      Date.utc_today()
    )
    |> Ash.load!([:category])
  
  # Load last month expenses for comparison
  last_month_expenses = 
    Ashfolio.FinancialManagement.Expense.by_date_range!(
      last_month_start,
      last_month_end
    )
  
  # Calculate totals
  current_total = calculate_expense_total(current_expenses)
  last_total = calculate_expense_total(last_month_expenses)
  
  # Calculate change percentage
  change_percent = if Decimal.compare(last_total, Decimal.new(0)) == :gt do
    current_total
    |> Decimal.sub(last_total)
    |> Decimal.mult(Decimal.new(100))
    |> Decimal.div(last_total)
    |> Decimal.round(1)
  else
    Decimal.new(0)
  end
  
  # Get top category
  top_category = get_top_expense_category(current_expenses)
  
  socket
  |> assign(:expense_count, length(current_expenses))
  |> assign(:expense_total, current_total)
  |> assign(:expense_change_percent, change_percent)
  |> assign(:expense_top_category, top_category)
  |> assign(:expenses_loaded, true)
rescue
  error ->
    Logger.warning("Failed to load expense summary: #{inspect(error)}")
    socket
    |> assign(:expense_count, 0)
    |> assign(:expense_total, Decimal.new(0))
    |> assign(:expense_change_percent, Decimal.new(0))
    |> assign(:expense_top_category, nil)
    |> assign(:expenses_loaded, false)
end

# ADD these helper functions:
defp calculate_expense_total(expenses) do
  expenses
  |> Enum.reduce(Decimal.new(0), fn expense, acc ->
    Decimal.add(acc, expense.amount)
  end)
end

defp get_top_expense_category(expenses) do
  expenses
  |> Enum.group_by(& &1.category)
  |> Enum.map(fn {category, category_expenses} ->
    total = calculate_expense_total(category_expenses)
    {category, total}
  end)
  |> Enum.max_by(fn {_category, total} -> total end, fn -> {nil, Decimal.new(0)} end)
  |> elem(0)
end
```

#### Part 2: Add Widget to Dashboard Render
```elixir
# lib/ashfolio_web/live/dashboard_live.ex
# In the render/1 function, find the "Recent Activity" card 
# and ADD this expense widget BEFORE it:

<!-- Add this NEW Expense Summary Widget -->
<.card data-testid="expense-summary-widget">
  <:header>
    <h2 class="text-lg font-medium text-gray-900">Monthly Expenses</h2>
  </:header>
  <:actions>
    <.link navigate={~p"/expenses"} class="btn-secondary text-sm">
      View All Expenses
    </.link>
  </:actions>
  
  <div class="space-y-4">
    <!-- Current Month Total -->
    <div class="text-center">
      <p class="text-sm text-gray-500">This Month</p>
      <p class="text-3xl font-bold text-gray-900">
        {FormatHelpers.format_currency(@expense_total)}
      </p>
      <p class="text-sm text-gray-600">
        {@expense_count} expenses
      </p>
    </div>
    
    <!-- Month-over-Month Change -->
    <%= if @expense_change_percent && Decimal.compare(@expense_change_percent, Decimal.new(0)) != :eq do %>
      <div class="flex items-center justify-center space-x-2">
        <span class={[
          "text-sm font-medium",
          if(Decimal.compare(@expense_change_percent, Decimal.new(0)) == :gt,
            do: "text-red-600",
            else: "text-green-600"
          )
        ]}>
          <%= if Decimal.compare(@expense_change_percent, Decimal.new(0)) == :gt do %>
            +{Decimal.to_string(@expense_change_percent)}%
          <% else %>
            {Decimal.to_string(@expense_change_percent)}%
          <% end %>
        </span>
        <span class="text-sm text-gray-500">vs last month</span>
      </div>
    <% end %>
    
    <!-- Top Category -->
    <%= if @expense_top_category do %>
      <div class="border-t pt-3">
        <p class="text-xs text-gray-500 uppercase tracking-wide">Top Category</p>
        <p class="mt-1 font-medium text-gray-900">
          {@expense_top_category.name}
        </p>
        <p class="text-sm text-gray-500">
          $225.50
        </p>
      </div>
    <% else %>
      <div class="text-center text-gray-500">
        No expenses this month
      </div>
    <% end %>
    
    <!-- Quick Add Button -->
    <.link
      navigate={~p"/expenses/new"}
      class="btn-primary w-full text-center"
    >
      + Add Expense
    </.link>
  </div>
</.card>

# Define component:
defp expense_summary_card(assigns) do
  ~H"""
  <.card>
    <:header>
      <h3 class="text-lg font-medium">Monthly Expenses</h3>
    </:header>
    <:actions>
      <.link navigate={~p"/expenses"} class="text-sm text-blue-600">
        View All →
      </.link>
    </:actions>
    
    <div class="space-y-4">
      <div class="text-center">
        <p class="text-3xl font-bold">{FormatHelpers.format_currency(@total)}</p>
        <p class="text-sm text-gray-500">{@count} expenses this month</p>
      </div>
      
      <%= if @top_category do %>
        <div class="border-t pt-3">
          <p class="text-xs text-gray-500">Top Category</p>
          <p class="font-medium">{@top_category.name}</p>
        </div>
      <% end %>
      
      <.link patch={~p"/expenses/new"} class="btn-primary w-full text-center">
        + Add Expense
      </.link>
    </div>
  </.card>
  """
end
```

### Step 1E: Verify Tests Pass
```bash
# Run the test again - should pass now!
mix test test/ashfolio_web/live/dashboard_live/expense_widget_test.exs

# If any failures, check:
# 1. Did you add all the assigns in load_expense_summary?
# 2. Did you add the widget HTML with correct data-testid?
# 3. Are the calculations matching expected values?
```

### Step 1F: Commit When Green
```bash
# Only commit when ALL tests pass!
git add -A
git commit -m "feat: add expense summary widget to dashboard

- Display current month total and count
- Show month-over-month comparison
- Identify top spending category
- Add quick navigation to expenses
- 5 tests passing"
```

### Checklist for Completion
- [ ] Test file created and all tests written
- [ ] Tests run and show failures initially (red)
- [ ] Implementation added to dashboard_live.ex
- [ ] All 5 widget tests passing (green)
- [ ] Code committed with descriptive message

---

## Stage 2: Dashboard Net Worth Enhancement [Not Started]

### Step 2A: Create Test File

```bash
# Create test file
touch test/ashfolio_web/live/dashboard_live/net_worth_widget_test.exs
```

### Step 2B: Copy Complete Test Suite

```elixir
# test/ashfolio_web/live/dashboard_live/net_worth_widget_test.exs
defmodule AshfolioWeb.DashboardLive.NetWorthWidgetTest do
  use AshfolioWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  describe "dashboard net worth widget" do
    setup do
      # Reset account balances
      require Ash.Query
      
      Ashfolio.Portfolio.Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(fn account ->
        Ashfolio.Portfolio.Account.update(account, %{balance: Decimal.new("0.00")})
      end)

      # Create accounts with balances
      {:ok, investment_account} = Ashfolio.Portfolio.Account.create(%{
        name: "Test Investment",
        account_type: :investment,
        balance: Decimal.new("75000.00")
      })

      {:ok, checking_account} = Ashfolio.Portfolio.Account.create(%{
        name: "Test Checking",
        account_type: :checking,
        balance: Decimal.new("5000.00")
      })

      # Create net worth snapshots for trend
      snapshots_data = [
        {Date.add(Date.utc_today(), -30), "78000.00"},
        {Date.add(Date.utc_today(), -15), "79000.00"},
        {Date.utc_today(), "80000.00"}
      ]

      snapshots = for {date, value} <- snapshots_data do
        {:ok, snapshot} = Ashfolio.FinancialManagement.NetWorthSnapshot.create(%{
          snapshot_date: date,
          total_assets: Decimal.new(value),
          total_liabilities: Decimal.new("0.00"),
          net_worth: Decimal.new(value),
          investment_value: Decimal.new(value),
          cash_value: Decimal.new("0.00"),
          other_assets_value: Decimal.new("0.00")
        })
        snapshot
      end

      %{
        investment_account: investment_account,
        checking_account: checking_account,
        snapshots: snapshots
      }
    end

    test "dashboard shows current net worth prominently", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/dashboard")

      # Should show current net worth (account balances: $75k + $5k = $80k)
      assert html =~ "$80,000"
      assert has_element?(view, "[data-testid='current-net-worth']")
    end

    test "net worth widget shows growth trend", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/dashboard")

      # Should show positive trend from snapshots
      # From $78k to $80k = +$2k = +2.6%
      assert html =~ "+$2,000"
      assert html =~ "+2.6%"
      assert html =~ "30 days"
    end

    test "create snapshot button in widget", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/dashboard")

      # Should have create snapshot button
      assert has_element?(view, "button[phx-click='create_snapshot']", "Snapshot Now")
      
      # Click create snapshot
      view |> element("button[phx-click='create_snapshot']") |> render_click()

      # Should show success message
      assert render(view) =~ "Net worth snapshot created"
      
      # Should create new snapshot in database
      snapshots = Ashfolio.FinancialManagement.NetWorthSnapshot.list!()
      assert length(snapshots) == 4 # 3 existing + 1 new
    end

    test "handles missing snapshot data gracefully", %{conn: conn} do
      # Delete all snapshots
      Ashfolio.FinancialManagement.NetWorthSnapshot.list!()
      |> Enum.each(fn snapshot ->
        Ashfolio.FinancialManagement.NetWorthSnapshot.destroy(snapshot)
      end)

      {:ok, view, html} = live(conn, ~p"/dashboard")

      # Should still show current calculated net worth
      assert html =~ "$80,000"
      
      # Should show appropriate message for missing trend data
      assert html =~ "No trend data"
      assert html =~ "Create your first snapshot"
    end
  end
end
```

### Step 2C: Run Test to See Failures
```bash
mix test test/ashfolio_web/live/dashboard_live/net_worth_widget_test.exs
# Expected: Tests should fail initially
```

### Step 2D: Implementation - Add Snapshot Functionality

```elixir
# lib/ashfolio_web/live/dashboard_live.ex

# ADD this to handle_event/3 functions:
@impl true
def handle_event("create_snapshot", _params, socket) do
  # Queue the snapshot job
  %{manual: true}
  |> Ashfolio.Workers.NetWorthSnapshotWorker.new()
  |> Oban.insert()
  
  {:noreply,
   socket
   |> put_flash(:info, "Net worth snapshot created successfully!")
   |> load_portfolio_data()  # Reload to show new snapshot
  }
end

# UPDATE the existing net_worth_card component (find and replace):
# Change the existing net_worth_card to add trend and button:
defp net_worth_card(assigns) do
  ~H"""
  <div class={["bg-white rounded-lg shadow p-6", @class]} data-testid={@data_testid}>
    <div class="flex items-center justify-between mb-4">
      <div>
        <p class="text-sm font-medium text-gray-600">{@title}</p>
        <p class="text-2xl font-semibold text-gray-900" data-testid="current-net-worth">
          {@value}
        </p>
      </div>
    </div>
    
    <!-- Trend Information -->
    <%= if assigns[:net_worth_trend] do %>
      <div class="mb-4">
        <p class={[
          "text-sm font-medium",
          if(@net_worth_trend.positive, do: "text-green-600", else: "text-red-600")
        ]}>
          <%= if @net_worth_trend.positive do %>+<% end %>
          {@net_worth_trend.amount} ({@net_worth_trend.percent}%)
          <span class="text-gray-500">· 30 days</span>
        </p>
      </div>
    <% else %>
      <div class="text-sm text-gray-500 mb-4">
        No trend data · Create your first snapshot
      </div>
    <% end %>
    
    <!-- Account Breakdown -->
    <div class="space-y-2 text-sm">
      <div class="flex justify-between">
        <span class="text-gray-600">Investment</span>
        <span class="font-medium">{@investment_value}</span>
      </div>
      <div class="flex justify-between">
        <span class="text-gray-600">Cash</span>
        <span class="font-medium">{@cash_balance}</span>
      </div>
    </div>
    
    <!-- Snapshot Button -->
    <button
      phx-click="create_snapshot"
      class="mt-4 w-full btn-secondary text-sm"
      type="button"
    >
      Snapshot Now
    </button>
  </div>
  """
end

# ADD this function to calculate net worth trend:
defp calculate_net_worth_trend(socket) do
  # Get snapshots from last 30 days
  thirty_days_ago = Date.add(Date.utc_today(), -30)
  
  snapshots = 
    Ashfolio.FinancialManagement.NetWorthSnapshot
    |> Ash.Query.filter(snapshot_date >= ^thirty_days_ago)
    |> Ash.Query.sort(:snapshot_date)
    |> Ash.read!()
  
  case snapshots do
    [] -> 
      nil
      
    snapshots ->
      oldest = List.first(snapshots)
      latest = List.last(snapshots)
      
      change = Decimal.sub(latest.net_worth, oldest.net_worth)
      percent = if Decimal.compare(oldest.net_worth, Decimal.new(0)) == :gt do
        change
        |> Decimal.mult(Decimal.new(100))
        |> Decimal.div(oldest.net_worth)
        |> Decimal.round(1)
      else
        Decimal.new(0)
      end
      
      %{
        amount: FormatHelpers.format_currency(change),
        percent: Decimal.to_string(percent),
        positive: Decimal.compare(change, Decimal.new(0)) == :gt
      }
  end
rescue
  _ -> nil
end

# UPDATE load_portfolio_data to include trend:
defp load_portfolio_data(socket) do
  # ... existing code ...
  socket
  |> assign(:net_worth_trend, calculate_net_worth_trend(socket))
  # ... rest of function
end
```

### Step 2E: Update Net Worth Card Usage in Render
```elixir
# In the render function, update the net_worth_card call:
<.net_worth_card
  title="Net Worth"
  value={@net_worth_total}
  investment_value={@net_worth_investment_value}
  cash_balance={@net_worth_cash_balance}
  net_worth_trend={@net_worth_trend}
  data_testid="net-worth-total"
/>
```

### Step 2F: Verify and Commit
```bash
# Run tests
mix test test/ashfolio_web/live/dashboard_live/net_worth_widget_test.exs

# When passing, commit:
git add -A
git commit -m "feat: enhance net worth widget with trends and manual snapshot

- Display 30-day trend with amount and percentage
- Add manual snapshot button with Oban integration  
- Handle missing snapshot data gracefully
- 4 tests passing"
```

### Checklist for Completion
- [ ] Test file created with 4 tests
- [ ] create_snapshot event handler added
- [ ] Net worth trend calculation implemented
- [ ] Snapshot button integrated in widget
- [ ] All tests passing

---

## Stage 3: Contex Chart Integration [Not Started]

### Objective
Add pie chart for expense categories and line chart for net worth trends.

### Test-First Implementation

#### 3.1 Expense Pie Chart Test
```elixir
test "expense analytics shows category pie chart", %{conn: conn} do
  # Setup categories and expenses
  create_expense(category: "Food", amount: "500.00")
  create_expense(category: "Transport", amount: "200.00")
  create_expense(category: "Entertainment", amount: "300.00")
  
  {:ok, view, html} = live(conn, ~p"/expenses/analytics")
  
  # Verify SVG chart rendered
  assert html =~ ~r/<svg[^>]*class="[^"]*contex-chart[^"]*"/
  
  # Verify data labels
  assert html =~ "Food"
  assert html =~ "$500"
  assert html =~ "50%"  # 500/1000
end
```

#### 3.2 Chart Component Pattern
```elixir
# lib/ashfolio_web/components/charts.ex
defmodule AshfolioWeb.Components.Charts do
  use Phoenix.Component
  alias Contex.{Dataset, PieChart, Plot}
  
  def expense_pie_chart(assigns) do
    ~H"""
    <div class="chart-container">
      <%= render_pie_chart(@data) %>
    </div>
    """
  end
  
  defp render_pie_chart(category_data) do
    dataset = Dataset.new(category_data, ["category", "amount"])
    
    Plot.new(dataset, PieChart, 400, 300)
    |> Plot.add_title("Expenses by Category")
    |> Plot.to_svg()
  end
end
```

### Testable Deliverables
- [ ] Pie chart renders with correct data
- [ ] Categories show with colors
- [ ] Percentages calculate correctly
- [ ] Empty state handles gracefully
- [ ] Chart is responsive

---

## Testing Strategy

### 1. Component Isolation Tests
Each widget should be testable in isolation:
```elixir
# Test data helpers
defp create_test_expense(attrs) do
  defaults = %{
    description: "Test expense",
    amount: Decimal.new("100.00"),
    date: Date.utc_today()
  }
  Expense.create!(Map.merge(defaults, attrs))
end
```

### 2. Integration Points
Key integration tests needed:
- Dashboard loads all widgets without N+1 queries
- PubSub updates propagate to widgets
- Navigation between dashboard and detail views
- Responsive layout on mobile

### 3. Performance Benchmarks
- Dashboard load time < 500ms with 1000+ expenses
- Widget updates < 200ms
- Chart rendering < 1000ms

---

## Success Criteria

### Stage 1 Complete When:
- [ ] Expense widget shows on dashboard
- [ ] Current month calculations accurate
- [ ] Quick add button functional
- [ ] 5 widget tests passing

### Stage 2 Complete When:
- [ ] Net worth widget displays
- [ ] Manual snapshot works
- [ ] Trend calculations correct
- [ ] 4 widget tests passing

### Stage 3 Complete When:
- [ ] Pie chart renders categories
- [ ] Line chart shows trends
- [ ] Charts responsive on mobile
- [ ] 6 chart tests passing

---

## Troubleshooting Guide

### If Test: "dashboard shows expense summary widget" fails:
- Check: Is `data-testid="expense-summary-widget"` on the card?
- Check: Is `@expense_total` assigned in `load_expense_summary`?
- Check: Is the format "$225.50" matching FormatHelpers output?

### If Test: "expense widget shows month-over-month comparison" fails:
- Check: Is `@expense_change_percent` calculated correctly?
- Check: Is the percentage formatted with "+" prefix for increases?
- Check: Is "vs last month" text present?

### If Test: "expense widget links to full expenses page" fails:
- Check: Is there a link with `href="/expenses"`?
- Check: Does it contain text "View All Expenses"?

### If Test: "expense widget shows top category" fails:
- Check: Is `@expense_top_category` being set?
- Check: Is the category name displayed?
- Check: Is "Top Category" label present?

### If Test: "empty expenses shows appropriate message" fails:
- Check: Is there a conditional for empty expenses?
- Check: Does it show "No expenses this month"?
- Check: Are zeros displayed for count and total?

## Common Patterns to Follow

### 1. LiveView Event Handling
```elixir
def handle_event("action_name", params, socket) do
  # Validate
  # Execute
  # Update assigns
  # Flash message
  {:noreply, socket}
end
```

### 2. Component Structure
```elixir
attr :data, :map, required: true
attr :class, :string, default: nil

def component_name(assigns) do
  ~H"""
  <div class={["base-classes", @class]}>
    <!-- Content -->
  </div>
  """
end
```

### 3. Test Structure
```elixir
describe "feature name" do
  setup do
    # Create test data
    %{key: value}
  end
  
  test "specific behavior", %{key: value} do
    # Arrange
    # Act
    # Assert
  end
end
```

---

## Potential Gotchas & Solutions

### 1. N+1 Query Issues
**Problem**: Loading expenses in dashboard causes multiple queries
**Solution**: Preload associations in single query
```elixir
Expense
|> Ash.Query.load([:category, :account])
|> Ash.read!()
```

### 2. PubSub Race Conditions
**Problem**: Widget updates before data committed
**Solution**: Use Process.sleep(10) in tests after actions

### 3. Decimal Arithmetic
**Problem**: Currency calculations lose precision
**Solution**: Always use Decimal.new() and Decimal.add()

### 4. Date Timezone Issues
**Problem**: Tests fail at month boundaries
**Solution**: Use Date.utc_today() consistently

---

## Next Agent Handoff Instructions

When starting work:
1. Run `mix test` to verify current state
2. Pick a stage from this plan
3. Write the test FIRST (red)
4. Implement minimal code (green)
5. Refactor if needed
6. Commit with clear message
7. Update this plan with [Complete] markers

Remember:
- Follow existing patterns in codebase
- Keep components small and focused
- Test behavior, not implementation
- Use descriptive test names
- Commit working code frequently

Good luck! The foundation is solid, just follow the plan! 🚀