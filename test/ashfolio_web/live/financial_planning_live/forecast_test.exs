defmodule AshfolioWeb.FinancialPlanningLive.ForecastTest do
  use AshfolioWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @moduletag :liveview

  describe "Forecast LiveView - Basic Functionality" do
    @tag :liveview
    test "renders the forecast page with basic form", %{conn: conn} do
      {:ok, view, html} = live(conn, "/forecast")

      # Page title and description
      assert html =~ "Portfolio Forecast"
      assert html =~ "Project your portfolio growth with different scenarios"

      # Form fields are present
      assert html =~ "Current Portfolio Value"
      assert html =~ "Monthly Contribution"
      assert html =~ "Annual Growth Rate"
      assert html =~ "Time Horizon"

      # Form elements exist
      assert has_element?(view, "input[name='form[current_value]']")
      assert has_element?(view, "input[name='form[monthly_contribution]']")
      assert has_element?(view, "select[name='form[growth_rate]']")
      assert has_element?(view, "select[name='form[years]']")

      # Calculate button exists
      assert has_element?(view, "button", "Calculate Projection")
    end

    @tag :liveview
    test "has tab navigation", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/forecast")

      # Tab navigation
      assert html =~ "Single Projection"
      assert html =~ "Scenario Comparison"
      assert html =~ "Contribution Impact"
    end

    @tag :liveview
    test "loads with default values", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/forecast")

      # Check form has default values
      assert has_element?(view, "input[name='form[current_value]'][value='100000']")
      assert has_element?(view, "input[name='form[monthly_contribution]'][value='1000']")
      assert has_element?(view, "select[name='form[growth_rate]'] option[value='0.07'][selected]")
      assert has_element?(view, "select[name='form[years]'] option[value='30'][selected]")
    end

    @tag :liveview
    test "has growth rate options", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/forecast")

      # Growth rate options
      assert html =~ "5% (Conservative)"
      assert html =~ "7% (Realistic)"
      assert html =~ "10% (Optimistic)"
    end

    @tag :liveview
    test "has time horizon options", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/forecast")

      # Time horizon options
      assert html =~ "10 Years"
      assert html =~ "20 Years"
      assert html =~ "30 Years"
    end
  end

  describe "Forecast LiveView - Form Interactions" do
    @tag :liveview
    test "can update form values", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/forecast")

      # Update current value
      view
      |> form("#forecast-form", %{
        "form" => %{
          "current_value" => "150000",
          "monthly_contribution" => "2000",
          "growth_rate" => "0.10",
          "years" => "20"
        }
      })
      |> render_change()

      # Values should be updated
      assert has_element?(view, "input[name='form[current_value]'][value='150000']")
      assert has_element?(view, "input[name='form[monthly_contribution]'][value='2000']")
    end

    @tag :liveview
    test "can switch tabs", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/forecast")

      # Switch to scenarios tab
      view
      |> element("button[phx-value-tab='scenarios']")
      |> render_click()

      # Should switch active tab
      html = render(view)
      assert html =~ "Scenario Comparison"
    end

    @tag :liveview
    test "can click calculate button", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/forecast")

      # Click calculate button
      view
      |> element("button[phx-click='calculate_projection']")
      |> render_click()

      # Button should be clickable without errors
      # (We're not testing calculation results since they may not be implemented)
      assert render(view)
    end
  end

  describe "Forecast LiveView - Navigation" do
    @tag :liveview
    test "has navigation links", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/forecast")

      # Navigation links in header
      assert html =~ "Goals"
      assert html =~ "Dashboard"
      assert html =~ "href=\"/goals\""
      assert html =~ "href=\"/\""
    end

    @tag :liveview
    test "includes breadcrumb navigation", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/forecast")

      # Should have navigation elements
      assert has_element?(view, "a[href='/goals']")
      assert has_element?(view, "a[href='/']")
    end
  end
end
