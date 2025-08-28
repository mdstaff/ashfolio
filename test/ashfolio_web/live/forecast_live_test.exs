defmodule AshfolioWeb.ForecastLiveTest do
  use AshfolioWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag :liveview
  @moduletag :unit

  describe "Portfolio Forecast Page" do
    test "forecast page loads successfully", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/forecast")

      assert html =~ "Portfolio Forecast"
      assert html =~ "Project your portfolio growth with different scenarios"
    end

    test "displays forecast parameters form", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/forecast")

      # Check form fields are present
      assert html =~ "Current Portfolio Value"
      assert html =~ "Monthly Contribution"
      assert html =~ "Annual Growth Rate"
      assert html =~ "Time Horizon"
      assert html =~ "Calculate Projection"
    end

    test "has three forecast tabs", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/forecast")

      assert html =~ "Single Projection"
      assert html =~ "Scenario Comparison"
      assert html =~ "Contribution Impact"
    end

    test "growth rate dropdown has correct options", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/forecast")

      assert html =~ "5% (Conservative)"
      assert html =~ "7% (Realistic)"
      assert html =~ "10% (Optimistic)"
    end

    test "time horizon dropdown has correct options", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/forecast")

      assert html =~ "10 Years"
      assert html =~ "20 Years"
      assert html =~ "30 Years"
    end

    @tag :failing
    test "calculate projection button works without crashing", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/forecast")

      # Update form values
      view
      |> form("#forecast-form", %{
        "form" => %{
          "current_value" => "100000",
          "monthly_contribution" => "1000",
          "growth_rate" => "0.07",
          "years" => "30"
        }
      })
      |> render_change()

      # Click calculate button - should not crash
      view
      |> element("button", "Calculate Projection")
      |> render_click()

      # Should display results
      html = render(view)
      assert html =~ "Final Portfolio Value"
      refute html =~ "error"
    end

    @tag :failing
    test "scenario comparison shows multiple projections", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/forecast")

      # Click Scenario Comparison tab
      view
      |> element("button", "Scenario Comparison")
      |> render_click()

      # Should show multiple scenarios
      html = render(view)
      assert html =~ "Conservative (5%)"
      assert html =~ "Realistic (7%)"
      assert html =~ "Optimistic (10%)"

      # Calculate scenarios
      view
      |> element("button", "Compare Scenarios")
      |> render_click()

      # Should show comparison chart/results
      html = render(view)
      assert html =~ "Scenario Results"
    end

    @tag :failing
    test "contribution impact analysis works", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/forecast")

      # Click Contribution Impact tab
      view
      |> element("button", "Contribution Impact")
      |> render_click()

      html = render(view)
      assert html =~ "Contribution Analysis"

      # Click analyze contributions button
      view
      |> element("button", "Analyze Impact")
      |> render_click()

      # Should show contribution analysis results
      html = render(view)
      assert html =~ "Base Projection"
      assert html =~ "Contribution Impact Analysis"
    end
  end

  describe "Forecast Calculations" do
    @tag :failing
    test "single projection calculation is accurate", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/forecast")

      # Set specific values for testing
      view
      |> form("#forecast-form", %{
        "form" => %{
          "current_value" => "10000",
          "monthly_contribution" => "100",
          "growth_rate" => "0.07",
          "years" => "1"
        }
      })
      |> render_change()

      view
      |> element("button", "Calculate Projection")
      |> render_click()

      html = render(view)
      # With 7% annual growth and $100/month for 1 year:
      # Expected ~$11,900 (10,000 * 1.07 + 100 * 12)
      # Rough check
      assert html =~ "$11"
    end

    @tag :failing
    test "handles edge cases gracefully", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/forecast")

      # Test with zero values
      view
      |> form("#forecast-form", %{
        "form" => %{
          "current_value" => "0",
          "monthly_contribution" => "0",
          "growth_rate" => "0.07",
          "years" => "10"
        }
      })
      |> render_change()

      view
      |> element("button", "Calculate Projection")
      |> render_click()

      html = render(view)
      assert html =~ "$0.00"
      refute html =~ "error"
    end

    @tag :failing
    test "validates input values", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/forecast")

      # Test with invalid values
      view
      |> form("#forecast-form", %{
        "form" => %{
          "current_value" => "-1000",
          "monthly_contribution" => "abc",
          "growth_rate" => "0.07",
          "years" => "30"
        }
      })
      |> render_change()

      html = render(view)
      assert html =~ "must be a positive number" || html =~ "invalid"
    end
  end

  describe "Financial Independence Calculations" do
    @tag :failing
    test "calculates time to financial independence", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/forecast")

      # Should show FI timeline based on 4% rule
      view
      |> form("#forecast-form", %{
        "form" => %{
          "current_value" => "500000",
          "monthly_contribution" => "5000",
          "growth_rate" => "0.07",
          "years" => "30",
          # FI at $1M (25x)
          "annual_expenses" => "40000"
        }
      })
      |> render_change()

      view
      |> element("button", "Calculate Projection")
      |> render_click()

      html = render(view)
      assert html =~ "Financial Independence"
      assert html =~ "years"
    end
  end

  describe "Navigation and Integration" do
    test "has navigation links to other planning pages", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/forecast")

      assert html =~ ~p"/goals"
      assert html =~ "Goals"
      assert html =~ ~p"/"
      assert html =~ "Dashboard"
    end

    @tag :failing
    test "forecast page is accessible from main navigation", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      # Should have Forecast in main navigation
      assert html =~ ~p"/forecast"
      assert html =~ "Forecast"
    end
  end

  describe "Chart Visualization" do
    @tag :failing
    test "displays projection chart after calculation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/forecast")

      # Calculate projection
      view
      |> form("#forecast-form", %{
        "form" => %{
          "current_value" => "100000",
          "monthly_contribution" => "1000",
          "growth_rate" => "0.07",
          "years" => "20"
        }
      })
      |> render_change()

      view
      |> element("button", "Calculate Projection")
      |> render_click()

      html = render(view)
      # Should render SVG chart (using Contex)
      assert html =~ "<svg"
      assert html =~ "Portfolio Growth"
    end
  end
end
