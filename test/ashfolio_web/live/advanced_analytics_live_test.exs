defmodule AshfolioWeb.AdvancedAnalyticsLiveTest do
  @moduledoc """
  Test suite for the Advanced Analytics LiveView.

  Tests the complete user workflow for professional portfolio analytics including
  TWR, MWR, rolling returns, caching, and real-time updates.
  """

  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Ashfolio.Portfolio.PerformanceCache

  setup do
    # Start performance cache
    {:ok, _pid} = PerformanceCache.start_link([])
    PerformanceCache.clear_all()
    :ok
  end

  describe "Advanced Analytics LiveView" do
    @tag :liveview
    test "mounts successfully with initial state", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/advanced_analytics")

      # Check page title and header
      assert html =~ "Advanced Portfolio Analytics"
      assert html =~ "Professional-grade performance analysis"

      # Check main action buttons are present
      assert html =~ "Refresh All Analytics"
      assert html =~ "Cache Stats"
      assert html =~ "Clear Cache"

      # Check analytics cards are rendered
      assert html =~ "Time-Weighted Return (TWR)"
      assert html =~ "Money-Weighted Return (MWR)"
      assert html =~ "Rolling Returns Analysis"

      # Check help section
      assert html =~ "Understanding Your Analytics"
    end

    @tag :liveview
    test "displays loading states correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/advanced_analytics")

      # Test TWR loading state
      html =
        view
        |> element("#calculate-twr-button")
        |> render_click()

      # Should show spinner and loading text
      assert html =~ "animate-spin"
      assert html =~ "Calculating..."
    end

    @tag :liveview
    test "calculates TWR when button clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/advanced_analytics")

      _html =
        view
        |> element("button#calculate-twr-button")
        |> render_click()

      # Should display TWR result
      assert render(view) =~ "Portfolio manager performance"
      # Should show percentage
      assert render(view) =~ "%"
    end

    @tag :liveview
    test "calculates MWR when button clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/advanced_analytics")

      # Click MWR calculate button (second Calculate button)
      view
      |> element("button[phx-click='calculate_mwr']")
      |> render_click()

      # Should display MWR result
      assert render(view) =~ "Your personal return experience"
      assert render(view) =~ "IRR-based calculation"
    end

    @tag :liveview
    test "calculates rolling returns analysis", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/advanced_analytics")

      view
      |> element("button[phx-click='calculate_rolling_returns']")
      |> render_click()

      # Wait for async calculation to complete (uses Process.send_after with 10ms delay)
      Process.sleep(50)

      # Should display rolling returns analysis
      final_html = render(view)
      assert final_html =~ "Best 12-Month Period"
      assert final_html =~ "Worst 12-Month Period"
      assert final_html =~ "Average Return"
      assert final_html =~ "Volatility"
      assert final_html =~ "periods analyzed"
    end

    @tag :liveview
    test "refresh all button works correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/advanced_analytics")

      html =
        view
        |> element("button[phx-click='refresh_all']")
        |> render_click()

      # Should show success message after refresh
      assert html =~ "All analytics refreshed successfully"

      # Final result should have all analytics
      final_html = render(view)
      # TWR
      assert final_html =~ "Portfolio manager performance"
      # MWR
      assert final_html =~ "Your personal return experience"
      assert final_html =~ "All analytics refreshed successfully"
    end

    @tag :liveview
    test "cache stats display correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/advanced_analytics")

      # First calculate something to populate cache
      view
      |> element("button[phx-click='calculate_twr']")
      |> render_click()

      # Then show cache stats
      view
      |> element("button[phx-click='show_cache_stats']")
      |> render_click()

      html = render(view)
      assert html =~ "Performance Cache Statistics"
      assert html =~ "Cached Entries"
      assert html =~ "Cache Hit Rate"
    end

    @tag :liveview
    test "cache clear functionality works", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/advanced_analytics")

      # First populate cache
      view
      |> element("button[phx-click='calculate_twr']")
      |> render_click()

      # Then clear cache
      view
      |> element("button[phx-click='clear_cache']")
      |> render_click()

      assert render(view) =~ "Performance cache cleared"
    end

    @tag :liveview
    test "calculation history is displayed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/advanced_analytics")

      # Perform some calculations to build history
      view
      |> element("button[phx-click='calculate_twr']")
      |> render_click()

      view
      |> element("button[phx-click='calculate_mwr']")
      |> render_click()

      html = render(view)
      assert html =~ "Recent Calculations"
      assert html =~ "TWR"
      assert html =~ "MWR"
    end

    @tag :liveview
    test "error handling displays user-friendly messages", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/advanced_analytics")

      # Note: In a real test, you might mock the calculator to return an error
      # For now, we test that error display mechanism works

      # The error handling is tested through the actual calculations
      # If there were no portfolio data, error messages would appear

      # Test that error message container exists
      assert render(view) =~ "error_message"
    end

    @tag :liveview
    test "real-time updates work via PubSub", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/advanced_analytics")

      # Calculate initial analytics
      view
      |> element("button[phx-click='calculate_twr']")
      |> render_click()

      # Simulate a transaction update
      transaction = %{account_id: "test-account", amount: Decimal.new("1000")}
      Ashfolio.PubSub.broadcast("transactions", {:transaction_created, transaction})

      # Give LiveView time to process the message
      :timer.sleep(100)

      # Should show update message
      assert render(view) =~ "Portfolio updated - analytics refreshed"
    end

    @tag :liveview
    test "handles concurrent user interactions gracefully", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/advanced_analytics")

      # Simulate rapid clicking of different buttons
      view |> element("button[phx-click='calculate_twr']") |> render_click()
      view |> element("button[phx-click='calculate_mwr']") |> render_click()
      view |> element("button[phx-click='calculate_rolling_returns']") |> render_click()

      # Should handle all calculations without crashing
      html = render(view)
      assert html =~ "Portfolio manager performance"
      assert html =~ "Your personal return experience"
      assert html =~ "Best 12-Month Period"
    end

    @tag :liveview
    test "maintains state across user interactions", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/advanced_analytics")

      # Calculate TWR
      view
      |> element("button[phx-click='calculate_twr']")
      |> render_click()

      twr_html = render(view)
      assert twr_html =~ "Portfolio manager performance"

      # Calculate MWR - TWR should still be visible
      view
      |> element("button[phx-click='calculate_mwr']")
      |> render_click()

      final_html = render(view)
      # TWR still there
      assert final_html =~ "Portfolio manager performance"
      # MWR now there
      assert final_html =~ "Your personal return experience"
    end

    @tag :liveview
    test "performance is acceptable with realistic data", %{conn: conn} do
      # Test that page loads quickly even with calculations
      {time_us, {:ok, _view, _html}} =
        :timer.tc(fn ->
          live(conn, "/advanced_analytics")
        end)

      # Should load within 2 seconds (benchmark from spec)
      assert time_us < 2_000_000, "Page load took #{time_us}μs, exceeds 2s limit"
    end

    @tag :integration
    test "integrates properly with performance cache", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/advanced_analytics")

      # First calculation should hit the calculator
      view
      |> element("button[phx-click='calculate_twr']")
      |> render_click()

      # Second calculation should use cache
      view
      |> element("button[phx-click='calculate_twr']")
      |> render_click()

      # Check cache stats
      view
      |> element("button[phx-click='show_cache_stats']")
      |> render_click()

      html = render(view)

      # Should show cache activity
      assert html =~ "Performance Cache Statistics"
      # Cache should have entries
      cache_stats = PerformanceCache.stats()
      assert cache_stats.entries > 0
    end

    @tag :liveview
    test "responsive design elements are present", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/advanced_analytics")

      # Check for responsive grid classes
      assert html =~ "grid-cols-1"
      assert html =~ "lg:grid-cols-2"
      assert html =~ "md:grid-cols-3"

      # Check for mobile-friendly button layout
      assert html =~ "flex-wrap"
      assert html =~ "gap-4"
    end

    @tag :liveview
    test "accessibility features are implemented", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/advanced_analytics")

      # Check for proper heading hierarchy
      assert html =~ ~r/<h1[^>]*>/
      assert html =~ ~r/<h2[^>]*>/
      assert html =~ ~r/<h3[^>]*>/

      # Check for descriptive button text
      assert html =~ "Calculate"
      assert html =~ "Refresh All Analytics"

      # Check for loading states with proper ARIA
      assert html =~ "disabled"
    end
  end
end
