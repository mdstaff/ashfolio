# Demo Mode TDD Specification

## Overview

This specification defines the test-driven development approach for implementing Ashfolio's demo mode feature. Future agents should implement features by first writing failing tests, then making them pass with minimal code.

## Design Principles

- Demo data should be clearly artificial
- Easy exit from demo mode
- Users explore at their own pace
- Exit to empty state with helpful prompts
- Instant value demonstration

## Test Structure

### 1. Core Demo Mode Tests

#### 1.1 Demo Mode Activation

```elixir
# test/ashfolio/demo_mode_test.exs
defmodule Ashfolio.DemoModeTest do
  use Ashfolio.DataCase, async: true

  alias Ashfolio.DemoMode
  alias Ashfolio.Portfolio.{User, Account, Transaction}

  describe "activate_demo_mode/1" do
    test "creates demo user with demo flag" do
      {:ok, demo_user} = DemoMode.activate_demo_mode()

      assert demo_user.is_demo == true
      assert demo_user.name == "Demo User"
      assert demo_user.currency == "USD"
      assert demo_user.locale == "en-US"
    end

    test "creates demo accounts with obviously fake data" do
      {:ok, demo_user} = DemoMode.activate_demo_mode()
      {:ok, accounts} = Account.accounts_for_user()

      assert length(accounts) == 3

      investment_account = Enum.find(accounts, &(&1.account_type == :investment))
      checking_account = Enum.find(accounts, &(&1.account_type == :checking))
      savings_account = Enum.find(accounts, &(&1.account_type == :savings))

      assert investment_account.name == "Demo Investment Account"
      assert Decimal.equal?(investment_account.balance, Decimal.new("54321.00"))

      assert checking_account.name == "Demo Checking"
      assert Decimal.equal?(checking_account.balance, Decimal.new("12345.67"))

      assert savings_account.name == "Demo Savings"
      assert Decimal.equal?(savings_account.balance, Decimal.new("98765.43"))
      assert Decimal.equal?(savings_account.interest_rate, Decimal.new("4.20"))
    end

    test "creates demo transactions with fake symbols" do
      {:ok, demo_user} = DemoMode.activate_demo_mode()

      assert length(transactions) >= 10

      demo_symbols = transactions |> Enum.map(& &1.symbol.symbol) |> Enum.uniq()

      assert "DEMO" in demo_symbols
      assert "FAKE" in demo_symbols
      assert "TEST" in demo_symbols

      # Verify demo transaction has realistic but fake data
      demo_transaction = Enum.find(transactions, &(&1.symbol.symbol == "DEMO"))
      assert demo_transaction.symbol.name == "Demo Stock Inc."
      assert demo_transaction.quantity |> Decimal.gt?(0)
      assert demo_transaction.price |> Decimal.gt?(0)
    end

    test "creates demo categories" do
      {:ok, demo_user} = DemoMode.activate_demo_mode()
      {:ok, categories} = TransactionCategory.categories_for_user()

      category_names = Enum.map(categories, & &1.name)

      assert "Demo Growth" in category_names
      assert "Demo Income" in category_names
      assert "Demo Speculative" in category_names
    end

    test "returns error when demo mode already active" do
      {:ok, _demo_user} = DemoMode.activate_demo_mode()

      assert {:error, :demo_already_active} = DemoMode.activate_demo_mode()
    end
  end

  describe "deactivate_demo_mode/0" do
    test "removes all demo data" do
      {:ok, demo_user} = DemoMode.activate_demo_mode()

      # Verify demo data exists
      {:ok, accounts} = Account.accounts_for_user()
      assert length(accounts) > 0

      # Deactivate demo mode
      :ok = DemoMode.deactivate_demo_mode()

      # Verify demo data is removed
      assert {:error, :user_not_found} = User.get_by_id()
    end

    test "returns ok when no demo mode active" do
      assert :ok = DemoMode.deactivate_demo_mode()
    end
  end

  describe "demo_mode_active?/0" do
    test "returns false when no demo mode" do
      refute DemoMode.demo_mode_active?()
    end

    test "returns true when demo mode active" do
      {:ok, _demo_user} = DemoMode.activate_demo_mode()

      assert DemoMode.demo_mode_active?()
    end
  end
end
```

#### 1.2 Demo Data Generation Tests

```elixir
# test/ashfolio/demo_mode/data_generator_test.exs
defmodule Ashfolio.DemoMode.DataGeneratorTest do
  use Ashfolio.DataCase, async: true

  alias Ashfolio.DemoMode.DataGenerator
  alias Ashfolio.Portfolio.{Account, Transaction, Symbol}
  alias Ashfolio.FinancialManagement.TransactionCategory

  describe "generate_demo_accounts/1" do
    test "creates exactly 3 accounts with correct types" do
      user = create_test_user()

      {:ok, accounts} = DataGenerator.generate_demo_accounts()

      assert length(accounts) == 3
      assert Enum.any?(accounts, &(&1.account_type == :investment))
      assert Enum.any?(accounts, &(&1.account_type == :checking))
      assert Enum.any?(accounts, &(&1.account_type == :savings))
    end

    test "uses obviously fake account names" do
      user = create_test_user()

      {:ok, accounts} = DataGenerator.generate_demo_accounts()

      account_names = Enum.map(accounts, & &1.name)

      assert "Demo Investment Account" in account_names
      assert "Demo Checking" in account_names
      assert "Demo Savings" in account_names
    end

    test "uses fake but realistic balances" do
      user = create_test_user()

      {:ok, accounts} = DataGenerator.generate_demo_accounts()

      balances = accounts |> Enum.map(& &1.balance) |> Enum.map(&Decimal.to_string/1)

      # Should use obviously fake amounts like 12345.67
      assert "54321.00" in balances
      assert "12345.67" in balances
      assert "98765.43" in balances
    end
  end

  describe "generate_demo_symbols/0" do
    test "creates fake symbols with obvious names" do
      {:ok, symbols} = DataGenerator.generate_demo_symbols()

      assert length(symbols) >= 3

      symbol_tickers = Enum.map(symbols, & &1.symbol)
      symbol_names = Enum.map(symbols, & &1.name)

      assert "DEMO" in symbol_tickers
      assert "FAKE" in symbol_tickers
      assert "TEST" in symbol_tickers

      assert "Demo Stock Inc." in symbol_names
      assert "Fake ETF Holdings" in symbol_names
      assert "Test Corporation" in symbol_names
    end

    test "sets asset classes correctly" do
      {:ok, symbols} = DataGenerator.generate_demo_symbols()

      demo_stock = Enum.find(symbols, &(&1.symbol == "DEMO"))
      fake_etf = Enum.find(symbols, &(&1.symbol == "FAKE"))

      assert demo_stock.asset_class == :stock
      assert fake_etf.asset_class == :etf
    end

    test "uses fake but realistic prices" do
      {:ok, symbols} = DataGenerator.generate_demo_symbols()

      Enum.each(symbols, fn symbol ->
        assert Decimal.gt?(symbol.current_price, 0)
        assert Decimal.lt?(symbol.current_price, 1000)
        # Should end in .42 or similar obvious fake patterns
        price_string = Decimal.to_string(symbol.current_price)
        assert String.contains?(price_string, ["42", "69", "123"])
      end)
    end
  end

  describe "generate_demo_transactions/2" do
    test "creates realistic number of transactions" do
      user = create_test_user()
      {:ok, accounts} = DataGenerator.generate_demo_accounts()
      {:ok, symbols} = DataGenerator.generate_demo_symbols()
      {:ok, categories} = DataGenerator.generate_demo_categories()

      {:ok, transactions} = DataGenerator.generate_demo_transactions(%{
        accounts: accounts,
        symbols: symbols,
        categories: categories
      })

      assert length(transactions) >= 10
      assert length(transactions) <= 30
    end

    test "distributes transactions across accounts" do
      user = create_test_user()
      {:ok, accounts} = DataGenerator.generate_demo_accounts()
      {:ok, symbols} = DataGenerator.generate_demo_symbols()
      {:ok, categories} = DataGenerator.generate_demo_categories()

      {:ok, transactions} = DataGenerator.generate_demo_transactions(%{
        accounts: accounts,
        symbols: symbols,
        categories: categories
      })

      account_ids = Enum.map(accounts, & &1.id)
      transaction_account_ids = Enum.map(transactions, & &1.account_id) |> Enum.uniq()

      # Should use at least 2 of the 3 accounts
      assert length(transaction_account_ids) >= 2
      assert Enum.all?(transaction_account_ids, &(&1 in account_ids))
    end

    test "includes various transaction types" do
      user = create_test_user()
      {:ok, accounts} = DataGenerator.generate_demo_accounts()
      {:ok, symbols} = DataGenerator.generate_demo_symbols()
      {:ok, categories} = DataGenerator.generate_demo_categories()

      {:ok, transactions} = DataGenerator.generate_demo_transactions(%{
        accounts: accounts,
        symbols: symbols,
        categories: categories
      })

      transaction_types = Enum.map(transactions, & &1.type) |> Enum.uniq()

      assert :buy in transaction_types
      assert length(transaction_types) >= 2  # Should have at least buy + one other
    end

    test "assigns categories to transactions" do
      user = create_test_user()
      {:ok, accounts} = DataGenerator.generate_demo_accounts()
      {:ok, symbols} = DataGenerator.generate_demo_symbols()
      {:ok, categories} = DataGenerator.generate_demo_categories()

      {:ok, transactions} = DataGenerator.generate_demo_transactions(%{
        accounts: accounts,
        symbols: symbols,
        categories: categories
      })

      categorized_transactions = Enum.filter(transactions, &(!is_nil(&1.category_id)))

      # At least 80% should have categories
      assert length(categorized_transactions) >= length(transactions) * 0.8
    end
  end

  describe "generate_demo_categories/1" do
    test "creates demo categories with obvious names" do
      user = create_test_user()

      {:ok, categories} = DataGenerator.generate_demo_categories()

      category_names = Enum.map(categories, & &1.name)

      assert "Demo Growth" in category_names
      assert "Demo Income" in category_names
      assert "Demo Speculative" in category_names
      assert length(categories) >= 3
    end

    test "sets bright obvious colors" do
      user = create_test_user()

      {:ok, categories} = DataGenerator.generate_demo_categories()

      colors = Enum.map(categories, & &1.color)

      # Should use bright, obvious demo colors
      assert "#FF0000" in colors  # Red
      assert "#00FF00" in colors  # Green
      assert "#0000FF" in colors  # Blue
    end

    test "marks categories as system categories" do
      user = create_test_user()

      {:ok, categories} = DataGenerator.generate_demo_categories()

      assert Enum.all?(categories, & &1.is_system == true)
    end
  end
end
```

### 2. Demo Mode UI Tests

#### 2.1 Demo Mode Banner Tests

```elixir
# test/ashfolio_web/live/demo_mode_banner_test.exs
defmodule AshfolioWeb.DemoModeBannerTest do
  use AshfolioWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "demo mode banner" do
    test "shows demo banner when in demo mode", %{conn: conn} do
      {:ok, demo_user} = Ashfolio.DemoMode.activate_demo_mode()

      {:ok, _view, html} = live(conn, ~p"/dashboard?demo=true")

      assert html =~ "Demo Mode"
      assert html =~ "Exit Demo"
      assert html =~ "This is fake data for demonstration"
    end

    test "does not show demo banner in normal mode", %{conn: conn} do
      create_user_and_sign_in(conn)

      {:ok, _view, html} = live(conn, ~p"/dashboard")

      refute html =~ "Demo Mode"
      refute html =~ "Exit Demo"
    end

    test "exit demo button redirects to clean state", %{conn: conn} do
      {:ok, _demo_user} = Ashfolio.DemoMode.activate_demo_mode()

      {:ok, view, _html} = live(conn, ~p"/dashboard?demo=true")

      # Click exit demo button
      view |> element("[data-testid=exit-demo]") |> render_click()

      # Should redirect to clean dashboard
      assert_redirect(view, ~p"/dashboard")

      # Demo mode should be deactivated
      refute Ashfolio.DemoMode.demo_mode_active?()
    end

    test "demo banner has correct styling classes", %{conn: conn} do
      {:ok, _demo_user} = Ashfolio.DemoMode.activate_demo_mode()

      {:ok, _view, html} = live(conn, ~p"/dashboard?demo=true")

      assert html =~ ~r/class="[^"]*demo-banner[^"]*"/
      assert html =~ ~r/class="[^"]*demo-gradient[^"]*"/
    end
  end
end
```

#### 2.2 Demo Mode Integration Tests

```elixir
# test/ashfolio_web/live/demo_mode_integration_test.exs
defmodule AshfolioWeb.DemoModeIntegrationTest do
  use AshfolioWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "demo mode dashboard integration" do
    test "dashboard shows demo data correctly", %{conn: conn} do
      {:ok, demo_user} = Ashfolio.DemoMode.activate_demo_mode()

      {:ok, _view, html} = live(conn, ~p"/dashboard?demo=true")

      # Should show demo net worth
      assert html =~ "$165,432.10"  # Sum of demo account balances

      # Should show demo account names
      assert html =~ "Demo Investment Account"
      assert html =~ "Demo Checking"
      assert html =~ "Demo Savings"

      # Should show demo transactions
      assert html =~ "DEMO"
      assert html =~ "Demo Stock Inc."
    end

    test "can navigate between pages in demo mode", %{conn: conn} do
      {:ok, _demo_user} = Ashfolio.DemoMode.activate_demo_mode()

      {:ok, view, _html} = live(conn, ~p"/dashboard?demo=true")

      # Navigate to accounts
      view |> element("a", "Accounts") |> render_click()

      assert_patch(view, ~p"/accounts?demo=true")

      # Should still show demo banner
      html = render(view)
      assert html =~ "Demo Mode"
      assert html =~ "Demo Investment Account"
    end

    test "demo transactions can be filtered by category", %{conn: conn} do
      {:ok, _demo_user} = Ashfolio.DemoMode.activate_demo_mode()

      {:ok, view, _html} = live(conn, ~p"/transactions?demo=true")

      # Apply category filter
      view
      |> form("#filter-form", %{category: "Demo Growth"})
      |> render_change()

      html = render(view)

      # Should show filtered results
      assert html =~ "Demo Growth"
      # Should not show other categories
      refute html =~ "Demo Income"
    end

    test "symbol search works with demo symbols", %{conn: conn} do
      {:ok, _demo_user} = Ashfolio.DemoMode.activate_demo_mode()

      {:ok, view, _html} = live(conn, ~p"/transactions/new?demo=true")

      # Type in symbol search
      view
      |> form("#transaction-form")
      |> render_change(%{symbol_search: "DEM"})

      html = render(view)

      # Should show demo symbols in autocomplete
      assert html =~ "DEMO"
      assert html =~ "Demo Stock Inc."
    end
  end

  describe "demo mode context API integration" do
    test "Context.get_user_dashboard_data works with demo user", %{conn: conn} do
      {:ok, demo_user} = Ashfolio.DemoMode.activate_demo_mode()

      {:ok, dashboard_data} = Ashfolio.Context.get_user_dashboard_data()

      assert dashboard_data.user.is_demo == true
      assert length(dashboard_data.accounts.all) == 3
      assert length(dashboard_data.accounts.investment) == 1
      assert length(dashboard_data.accounts.cash) == 2
      assert dashboard_data.summary.account_count == 3

      # Demo net worth should be sum of demo balances
      expected_total = Decimal.new("165432.10")
      assert Decimal.equal?(dashboard_data.summary.total_balance, expected_total)
    end

    test "Context.get_net_worth includes demo accounts", %{conn: conn} do
      {:ok, demo_user} = Ashfolio.DemoMode.activate_demo_mode()

      {:ok, net_worth} = Ashfolio.Context.get_net_worth()

      assert Decimal.gt?(net_worth.total_net_worth, 0)
      assert Decimal.gt?(net_worth.cash_balance, 0)
      assert Decimal.gt?(net_worth.investment_value, 0)

      assert net_worth.breakdown.cash_accounts == 2
      assert net_worth.breakdown.investment_accounts == 1
    end
  end
end
```

### 3. Demo Mode Entry Point Tests

#### 3.1 Landing Page Demo Option Tests

```elixir
# test/ashfolio_web/live/landing_page_test.exs
defmodule AshfolioWeb.LandingPageTest do
  use AshfolioWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "landing page demo options" do
    test "shows demo mode option for new users", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Try Demo Mode"
      assert html =~ "Start with Real Data"
      assert html =~ "See Ashfolio in action with sample data"
    end

    test "clicking 'Try Demo Mode' activates demo and redirects", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("[data-testid=try-demo-mode]") |> render_click()

      # Should activate demo mode
      assert Ashfolio.DemoMode.demo_mode_active?()

      # Should redirect to dashboard with demo flag
      assert_redirect(view, ~p"/dashboard?demo=true")
    end

    test "clicking 'Start with Real Data' goes to normal signup", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("[data-testid=start-real-data]") |> render_click()

      # Should not activate demo mode
      refute Ashfolio.DemoMode.demo_mode_active?()

      # Should redirect to normal flow
      assert_redirect(view, ~p"/dashboard")
    end
  end
end
```

#### 3.2 Empty State Demo Prompt Tests

```elixir
# test/ashfolio_web/live/empty_state_demo_test.exs
defmodule AshfolioWeb.EmptyStateDemoTest do
  use AshfolioWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "empty state demo prompt" do
    test "shows demo prompt when user has no data", %{conn: conn} do
      user = create_user_and_sign_in(conn)

      {:ok, _view, html} = live(conn, ~p"/dashboard")

      assert html =~ "Want to see how Ashfolio works?"
      assert html =~ "Load Demo Data"
      assert html =~ "Start Fresh"
    end

    test "does not show demo prompt when user has accounts", %{conn: conn} do
      user = create_user_and_sign_in(conn)
      create_account_for_user(user)

      {:ok, _view, html} = live(conn, ~p"/dashboard")

      refute html =~ "Load Demo Data"
      refute html =~ "Want to see how Ashfolio works?"
    end

    test "clicking 'Load Demo Data' activates demo mode", %{conn: conn} do
      user = create_user_and_sign_in(conn)

      {:ok, view, _html} = live(conn, ~p"/dashboard")

      view |> element("[data-testid=load-demo-data]") |> render_click()

      # Should activate demo mode
      assert Ashfolio.DemoMode.demo_mode_active?()

      # Should refresh page with demo data
      html = render(view)
      assert html =~ "Demo Mode"
      assert html =~ "Demo Investment Account"
    end
  end
end
```

### 4. Performance Tests for Demo Mode

#### 4.1 Demo Data Generation Performance

```elixir
# test/performance/demo_mode_performance_test.exs
defmodule Ashfolio.Performance.DemoModePerformanceTest do
  use Ashfolio.DataCase, async: false

  @moduletag :performance

  describe "demo mode performance" do
    test "demo mode activation completes within 500ms" do
      {time_us, {:ok, _demo_user}} = :timer.tc(fn ->
        Ashfolio.DemoMode.activate_demo_mode()
      end)

      time_ms = time_us / 1000

      assert time_ms < 500, "Demo mode activation took #{time_ms}ms, expected < 500ms"
    end

    test "demo data generation scales appropriately" do
      measurements = for _i <- 1..5 do
        # Clean up between runs
        Ashfolio.DemoMode.deactivate_demo_mode()

        {time_us, {:ok, _}} = :timer.tc(fn ->
          Ashfolio.DemoMode.activate_demo_mode()
        end)

        time_us / 1000
      end

      avg_time = Enum.sum(measurements) / length(measurements)
      max_time = Enum.max(measurements)

      assert avg_time < 300, "Average demo activation: #{avg_time}ms, expected < 300ms"
      assert max_time < 500, "Max demo activation: #{max_time}ms, expected < 500ms"
    end

    test "demo dashboard loading performs well" do
      {:ok, demo_user} = Ashfolio.DemoMode.activate_demo_mode()

      {time_us, {:ok, _dashboard_data}} = :timer.tc(fn ->
        Ashfolio.Context.get_user_dashboard_data()
      end)

      time_ms = time_us / 1000

      # Should be even faster than normal since it's known static data
      assert time_ms < 50, "Demo dashboard loading took #{time_ms}ms, expected < 50ms"
    end

    test "demo mode cleanup is efficient" do
      {:ok, _demo_user} = Ashfolio.DemoMode.activate_demo_mode()

      {time_us, :ok} = :timer.tc(fn ->
        Ashfolio.DemoMode.deactivate_demo_mode()
      end)

      time_ms = time_us / 1000

      assert time_ms < 100, "Demo cleanup took #{time_ms}ms, expected < 100ms"
    end
  end
end
```

### 5. Browser Automation Tests (Playwright Integration)

#### 5.1 Demo Mode E2E Tests

```javascript
// test/e2e/demo_mode.spec.js
const { test, expect } = require("@playwright/test");

test.describe("Demo Mode End-to-End", () => {
  test("complete demo mode user journey", async ({ page }) => {
    // Start from landing page
    await page.goto("http://localhost:4000");

    // Should see demo option
    await expect(page.locator("[data-testid=try-demo-mode]")).toBeVisible();
    await expect(page.locator("text=Try Demo Mode")).toBeVisible();

    // Click demo mode
    await page.click("[data-testid=try-demo-mode]");

    // Should be redirected to dashboard with demo data
    await expect(page).toHaveURL(/\/dashboard\?demo=true/);

    // Should see demo banner
    await expect(page.locator(".demo-banner")).toBeVisible();
    await expect(page.locator("text=Demo Mode")).toBeVisible();
    await expect(page.locator("[data-testid=exit-demo]")).toBeVisible();

    // Should see demo data
    await expect(page.locator("text=Demo Investment Account")).toBeVisible();
    await expect(page.locator("text=$165,432.10")).toBeVisible(); // Demo net worth

    // Navigate to accounts
    await page.click("text=Accounts");
    await expect(page).toHaveURL(/\/accounts\?demo=true/);

    // Should still see demo banner
    await expect(page.locator(".demo-banner")).toBeVisible();

    // Should see all demo accounts
    await expect(page.locator("text=Demo Investment Account")).toBeVisible();
    await expect(page.locator("text=Demo Checking")).toBeVisible();
    await expect(page.locator("text=Demo Savings")).toBeVisible();

    // Test demo transaction creation
    await page.click("text=Transactions");
    await page.click("text=Add Transaction");

    // Should see demo symbols in search
    await page.fill("[data-testid=symbol-search]", "DEM");
    await expect(page.locator("text=DEMO - Demo Stock Inc.")).toBeVisible();

    // Exit demo mode
    await page.click("[data-testid=exit-demo]");

    // Should be redirected to clean dashboard
    await expect(page).toHaveURL("/dashboard");
    await expect(page.locator(".demo-banner")).not.toBeVisible();

    // Should see empty state
    await expect(
      page.locator("text=Ready to add your first account?")
    ).toBeVisible();
  });

  test("demo mode visual consistency", async ({ page }) => {
    await page.goto("http://localhost:4000");
    await page.click("[data-testid=try-demo-mode]");

    // Take screenshots for visual regression testing
    await page.screenshot({
      path: "test-results/demo-dashboard.png",
      fullPage: true,
    });

    await page.click("text=Accounts");
    await page.screenshot({
      path: "test-results/demo-accounts.png",
      fullPage: true,
    });

    await page.click("text=Transactions");
    await page.screenshot({
      path: "test-results/demo-transactions.png",
      fullPage: true,
    });
  });

  test("demo mode performance", async ({ page }) => {
    const startTime = Date.now();

    await page.goto("http://localhost:4000");
    await page.click("[data-testid=try-demo-mode]");

    // Wait for demo data to load
    await page.waitForSelector("text=Demo Investment Account");

    const loadTime = Date.now() - startTime;

    // Demo mode should load quickly
    expect(loadTime).toBeLessThan(2000);
  });

  test("demo banner accessibility", async ({ page }) => {
    await page.goto("http://localhost:4000");
    await page.click("[data-testid=try-demo-mode]");

    // Test keyboard navigation
    await page.keyboard.press("Tab");
    await expect(page.locator("[data-testid=exit-demo]:focus")).toBeVisible();

    // Test screen reader announcements
    const banner = page.locator(".demo-banner");
    await expect(banner).toHaveAttribute("role", "banner");
    await expect(banner).toHaveAttribute("aria-label", /demo mode/i);
  });
});
```

### 6. Implementation Checklist

#### Phase 1: Core Demo Mode (Week 1)

- [ ] `DemoMode` context module with activate/deactivate functions
- [ ] `DataGenerator` module for creating fake data
- [ ] Demo user creation with `is_demo` flag
- [ ] Demo accounts with obvious fake names and balances
- [ ] Demo symbols (DEMO, FAKE, TEST) with fake company names
- [ ] Demo transactions distributed across accounts
- [ ] Demo categories with bright obvious colors
- [ ] Core demo mode tests passing

#### Phase 2: UI Integration (Week 1 continued)

- [ ] Demo banner component with exit button
- [ ] Landing page demo mode option
- [ ] Empty state demo prompt
- [ ] Demo mode URL parameter handling (?demo=true)
- [ ] Demo mode styling (gradient banner, obvious indicators)
- [ ] UI integration tests passing

#### Phase 3: Polish & Performance (Week 2)

- [ ] Performance optimizations for demo data generation
- [ ] Browser automation tests for visual consistency
- [ ] Accessibility improvements for demo mode
- [ ] Error handling for edge cases
- [ ] Documentation for demo mode features

### 7. Acceptance Criteria Summary

Demo Mode Must:

1.  Activate within 500ms
2.  Create obviously fake data (names like "Demo Stock Inc.")
3.  Show clear visual indicators (banner, "Demo Mode" text)
4.  Be dismissible with one click
5.  Work with all existing v0.2.0 features
6.  Transition cleanly to empty state
7.  Not interfere with real user data
8.  Perform well under load
9.  Be accessible (keyboard navigation, screen readers)
10. Pass all automated tests

Demo Mode Must Not:

1. ❌ Confuse users about what's real vs fake
2. ❌ Persist demo data after exit
3. ❌ Interfere with normal application functionality
4. ❌ Take longer than 2 seconds to load
5. ❌ Break existing user workflows
6. ❌ Require complex tutorial systems
7. ❌ Use real-looking company names or data

### 8. Future Agent Instructions

When implementing this specification:

1. Start with failing tests - Write each test first, see it fail, then implement
2. Keep it simple - Resist the urge to add complex features
3. Make it obviously fake - Use clear demo indicators throughout
4. Test in browsers - Use Playwright to verify visual consistency
5. Performance first - Demo mode should be faster than real mode
6. Accessibility matters - Ensure keyboard navigation and screen reader support
7. Document decisions - Update this spec with any changes or improvements

### 9. Success Metrics

Track these metrics to validate demo mode effectiveness:

- % of users who try demo mode
- % who explore multiple sections
- % who exit demo and add real data
- Seconds until user sees value in the app
- Which v0.2.0 features get discovered most

The goal is to create the fastest path to value while maintaining user trust through obvious fake data indicators.
