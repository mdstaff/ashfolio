defmodule AshfolioWeb.FinancialPlanningLive.ForecastTest do
  use AshfolioWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Ashfolio.FinancialManagement

  @moduletag :liveview

  describe "Forecast LiveView - Rendering" do
    @tag :liveview
    test "renders the forecast form with all required fields", %{conn: conn} do
      {:ok, view, html} = live(conn, "/financial-planning/forecast")

      # Page title and description
      assert html =~ "Portfolio Growth Projections"
      assert html =~ "Project your portfolio growth over time"

      # Form fields
      assert html =~ "Current Portfolio Value"
      assert html =~ "Annual Contribution"
      assert html =~ "Expected Growth Rate"
      assert html =~ "Projection Years"

      # Input elements with proper IDs and names
      assert element(view, "#forecast-form_current_value")
      assert element(view, "#forecast-form_annual_contribution")
      assert element(view, "#forecast-form_growth_rate")
      assert element(view, "#forecast-form_years")

      # Scenario selector
      assert html =~ "Scenario Analysis"
      assert element(view, "[data-scenario='pessimistic']")
      assert element(view, "[data-scenario='realistic']")
      assert element(view, "[data-scenario='optimistic']")

      # Submit button
      assert element(view, "button[type='submit']", "Calculate Projection")
    end

    @tag :liveview
    test "displays helpful tooltips and examples", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/financial-planning/forecast")

      # Helper text for each field
      assert html =~ "Enter your current portfolio balance"
      assert html =~ "Amount you plan to contribute annually"
      assert html =~ "Expected annual return (e.g., 7% = 0.07)"
      assert html =~ "How many years to project into the future"

      # Example scenarios
      assert html =~ "Conservative (5%)"
      assert html =~ "Moderate (7%)"
      assert html =~ "Aggressive (10%)"
    end

    @tag :liveview
    test "loads with sensible default values", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Check default form values
      assert has_element?(view, "#forecast-form_growth_rate[value='0.07']")
      assert has_element?(view, "#forecast-form_years[value='30']")
    end
  end

  describe "Forecast LiveView - Form Validation" do
    @tag :liveview
    test "validates required fields on submission", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Submit empty form
      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "",
          annual_contribution: "",
          growth_rate: "",
          years: ""
        }
      })
      |> render_submit()

      # Should show validation errors
      assert has_element?(view, ".invalid-feedback", "Current value is required")
      assert has_element?(view, ".invalid-feedback", "Growth rate is required")
      assert has_element?(view, ".invalid-feedback", "Years must be specified")
    end

    @tag :liveview
    test "validates positive values for monetary fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Submit with negative values
      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "-1000",
          annual_contribution: "-500",
          growth_rate: "0.07",
          years: "10"
        }
      })
      |> render_submit()

      assert has_element?(view, ".invalid-feedback", "Current value must be positive")
      assert has_element?(view, ".invalid-feedback", "Annual contribution cannot be negative")
    end

    @tag :liveview
    test "validates realistic growth rate bounds", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Test unrealistic growth rate (>50%)
      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "12000",
          growth_rate: "0.60",
          years: "10"
        }
      })
      |> render_submit()

      assert has_element?(view, ".invalid-feedback", "Growth rate must be between -50% and 50%")
    end

    @tag :liveview
    test "validates years within reasonable range", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Test too many years
      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "12000",
          growth_rate: "0.07",
          years: "100"
        }
      })
      |> render_submit()

      assert has_element?(view, ".invalid-feedback", "Years must be between 1 and 50")
    end
  end

  describe "Forecast LiveView - Calculation Results" do
    @tag :liveview
    test "displays projection results after valid submission", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Submit valid form
      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "12000",
          growth_rate: "0.07",
          years: "10"
        }
      })
      |> render_submit()

      # Should display results section
      assert has_element?(view, "#projection-results")
      assert has_element?(view, "[data-testid='projected-value']")
      assert has_element?(view, "[data-testid='total-contributions']")
      assert has_element?(view, "[data-testid='growth-amount']")

      # Should show formatted currency values
      html = render(view)
      # Currency formatting
      assert html =~ "$"
      # Approximate expected value for the test case
      assert html =~ "374,051"
    end

    @tag :liveview
    test "displays yearly breakdown for first 5 years", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "12000",
          growth_rate: "0.07",
          years: "10"
        }
      })
      |> render_submit()

      # Should show yearly breakdown table
      assert has_element?(view, "#yearly-breakdown")
      assert has_element?(view, "th", "Year")
      assert has_element?(view, "th", "Portfolio Value")
      assert has_element?(view, "th", "Contributions")
      assert has_element?(view, "th", "Growth")

      # Should have 5 rows of data
      for year <- 1..5 do
        assert has_element?(view, "[data-year='#{year}']")
      end
    end

    @tag :liveview
    test "calculates and displays CAGR", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "0",
          growth_rate: "0.07",
          years: "10"
        }
      })
      |> render_submit()

      # Should display CAGR
      assert has_element?(view, "[data-testid='cagr-value']")
      html = render(view)
      # Should show CAGR as percentage
      assert html =~ "7.00%"
    end
  end

  describe "Forecast LiveView - Scenario Analysis" do
    @tag :liveview
    test "displays all three standard scenarios", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "12000",
          growth_rate: "0.07",
          years: "20"
        }
      })
      |> render_submit()

      # Should show scenario comparison
      assert has_element?(view, "#scenario-comparison")
      assert has_element?(view, "[data-scenario-result='pessimistic']")
      assert has_element?(view, "[data-scenario-result='realistic']")
      assert has_element?(view, "[data-scenario-result='optimistic']")

      # Each scenario should show growth rate and final value
      html = render(view)
      # Pessimistic rate
      assert html =~ "5%"
      # Realistic rate
      assert html =~ "7%"
      # Optimistic rate
      assert html =~ "10%"
    end

    @tag :liveview
    test "switches between scenarios when clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Calculate initial projection
      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "12000",
          growth_rate: "0.07",
          years: "20"
        }
      })
      |> render_submit()

      # Click pessimistic scenario
      view
      |> element("[data-scenario='pessimistic']")
      |> render_click()

      # Growth rate should update to 5%
      assert has_element?(view, "#forecast-form_growth_rate[value='0.05']")

      # Results should recalculate
      refute has_element?(view, "[data-active-scenario='realistic']")
      assert has_element?(view, "[data-active-scenario='pessimistic']")
    end

    @tag :liveview
    test "shows weighted average projection", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "12000",
          growth_rate: "0.07",
          years: "20"
        }
      })
      |> render_submit()

      # Should display weighted average
      assert has_element?(view, "[data-testid='weighted-average']")
      html = render(view)
      assert html =~ "Probability-Weighted"
      assert html =~ "20% Pessimistic"
      assert html =~ "60% Realistic"
      assert html =~ "20% Optimistic"
    end
  end

  describe "Forecast LiveView - Financial Independence" do
    @tag :liveview
    test "displays FI timeline when expenses provided", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Enable FI calculation mode
      view
      |> element("#fi-mode-toggle")
      |> render_click()

      # Should show annual expenses field
      assert has_element?(view, "#forecast-form_annual_expenses")

      # Submit with expenses
      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "30000",
          growth_rate: "0.07",
          years: "30",
          annual_expenses: "50000"
        }
      })
      |> render_submit()

      # Should display FI results
      assert has_element?(view, "#fi-timeline")
      assert has_element?(view, "[data-testid='fi-target']")
      assert has_element?(view, "[data-testid='years-to-fi']")
      assert has_element?(view, "[data-testid='fi-date']")

      html = render(view)
      assert html =~ "Financial Independence"
      # 25x of $50k
      assert html =~ "$1,250,000"
    end

    @tag :liveview
    test "shows already FI when portfolio exceeds 25x expenses", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      view
      |> element("#fi-mode-toggle")
      |> render_click()

      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "2000000",
          annual_contribution: "0",
          growth_rate: "0.07",
          years: "30",
          annual_expenses: "50000"
        }
      })
      |> render_submit()

      assert has_element?(view, ".alert-success", "Already Financially Independent!")
      assert has_element?(view, "[data-testid='safe-withdrawal']", "$80,000")
    end
  end

  describe "Forecast LiveView - Chart Rendering" do
    @tag :liveview
    test "renders projection chart after calculation", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "12000",
          growth_rate: "0.07",
          years: "30"
        }
      })
      |> render_submit()

      # Should render chart container
      assert has_element?(view, "#projection-chart")
      assert has_element?(view, "[data-chart-type='forecast']")

      # Chart should have SVG elements (Contex renders as SVG)
      assert has_element?(view, "#projection-chart svg")
      assert has_element?(view, "#projection-chart .chart-line")
    end

    @tag :liveview
    test "updates chart when parameters change", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Initial calculation
      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "12000",
          growth_rate: "0.07",
          years: "30"
        }
      })
      |> render_submit()

      # Get initial chart data attribute
      initial_html = render(view)
      assert initial_html =~ "data-chart-max"

      # Update parameters
      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "200000",
          annual_contribution: "24000",
          growth_rate: "0.10",
          years: "30"
        }
      })
      |> render_submit()

      # Chart should update with new data
      updated_html = render(view)
      refute initial_html == updated_html
      assert updated_html =~ "data-chart-max"
    end

    @tag :liveview
    test "displays multi-scenario comparison chart", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Enable comparison mode
      view
      |> element("#comparison-mode-toggle")
      |> render_click()

      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "12000",
          growth_rate: "0.07",
          years: "30"
        }
      })
      |> render_submit()

      # Should show comparison chart with three lines
      assert has_element?(view, "#comparison-chart")
      assert has_element?(view, "[data-series='pessimistic']")
      assert has_element?(view, "[data-series='realistic']")
      assert has_element?(view, "[data-series='optimistic']")
    end
  end

  describe "Forecast LiveView - Real-time Updates" do
    @tag :liveview
    test "updates projections as user types with debouncing", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Enable real-time mode
      view
      |> element("#realtime-toggle")
      |> render_click()

      # Type in current value - should trigger calculation after debounce
      view
      |> element("#forecast-form_current_value")
      |> render_blur(%{value: "150000"})

      # Wait for debounce (simulated)
      Process.sleep(100)

      # Should show preview results
      assert has_element?(view, "#preview-results")
    end

    @tag :liveview
    test "handles portfolio value updates via PubSub", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Subscribe to PubSub updates
      Phoenix.PubSub.broadcast(
        Ashfolio.PubSub,
        "portfolio:updates",
        {:portfolio_value_changed, %{total_value: Decimal.new("150000")}}
      )

      # Should update current value field
      assert has_element?(view, "#forecast-form_current_value[value='150000']")
      assert has_element?(view, ".badge-info", "Portfolio value updated")
    end
  end

  describe "Forecast LiveView - Export and Sharing" do
    @tag :liveview
    test "allows exporting projection data as CSV", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Calculate projection
      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "12000",
          growth_rate: "0.07",
          years: "30"
        }
      })
      |> render_submit()

      # Export button should be available
      assert has_element?(view, "button[data-export='csv']", "Export to CSV")

      # Click export
      view
      |> element("button[data-export='csv']")
      |> render_click()

      # Should trigger download
      assert_push_event(view, "download", %{
        filename: filename,
        content: _content,
        mime_type: "text/csv"
      })

      assert filename =~ "forecast_projection"
      assert filename =~ ".csv"
    end

    @tag :liveview
    test "allows saving projection parameters", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Calculate projection
      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "12000",
          growth_rate: "0.07",
          years: "30"
        }
      })
      |> render_submit()

      # Save button should be available
      assert has_element?(view, "button[data-action='save']", "Save Projection")

      # Click save
      view
      |> element("button[data-action='save']")
      |> render_click()

      # Should show save dialog
      assert has_element?(view, "#save-projection-modal")
      assert has_element?(view, "input[name='projection_name']")

      # Save with name
      view
      |> form("#save-projection-form", %{
        projection: %{name: "Retirement Plan A"}
      })
      |> render_submit()

      assert has_element?(view, ".alert-success", "Projection saved")
    end
  end

  describe "Forecast LiveView - Mobile Responsiveness" do
    @tag :liveview
    test "adapts layout for mobile viewport", %{conn: conn} do
      # Simulate mobile viewport
      conn = put_req_header(conn, "user-agent", "Mobile")
      {:ok, view, html} = live(conn, "/financial-planning/forecast")

      # Should have mobile-optimized classes
      assert html =~ "mobile-view"
      assert has_element?(view, ".form-mobile")

      # Scenario buttons should be in dropdown on mobile
      assert has_element?(view, "#scenario-dropdown")
    end

    @tag :liveview
    test "chart is scrollable on mobile", %{conn: conn} do
      conn = put_req_header(conn, "user-agent", "Mobile")
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "100000",
          annual_contribution: "12000",
          growth_rate: "0.07",
          years: "30"
        }
      })
      |> render_submit()

      # Chart container should be scrollable
      assert has_element?(view, ".chart-scroll-container")
      assert has_element?(view, "[style*='overflow-x: auto']")
    end
  end

  describe "Forecast LiveView - Error Handling" do
    @tag :liveview
    test "handles calculation errors gracefully", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Submit form that would cause calculation error
      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "0",
          annual_contribution: "0",
          growth_rate: "0",
          years: "0"
        }
      })
      |> render_submit()

      # Should show user-friendly error
      assert has_element?(view, ".alert-warning", "Unable to calculate projection")
      refute has_element?(view, "#projection-results")
    end

    @tag :liveview
    test "handles network errors with retry option", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/financial-planning/forecast")

      # Simulate network error
      send(view.pid, {:error, :network_error})

      assert has_element?(view, ".alert-danger", "Connection error")
      assert has_element?(view, "button", "Retry")
    end
  end

  describe "Forecast LiveView - Integration with Goals" do
    @tag :liveview
    @tag :integration
    test "pre-fills values from selected financial goal", %{conn: conn} do
      # Create a financial goal
      {:ok, goal} =
        FinancialManagement.FinancialGoal.create(%{
          name: "Retirement Fund",
          target_amount: Decimal.new("1250000"),
          goal_type: :retirement
        })

      # Navigate with goal ID
      {:ok, view, _html} = live(conn, "/financial-planning/forecast?goal_id=#{goal.id}")

      # Should pre-fill based on goal
      assert has_element?(view, "#forecast-form_years[value='25']")
      assert has_element?(view, ".badge-primary", "Linked to: Retirement Fund")
    end

    @tag :liveview
    @tag :integration
    test "updates goal progress after projection", %{conn: conn} do
      {:ok, goal} =
        FinancialManagement.FinancialGoal.create(%{
          name: "House Down Payment",
          target_amount: Decimal.new("100000"),
          goal_type: :house_down_payment
        })

      {:ok, view, _html} = live(conn, "/financial-planning/forecast?goal_id=#{goal.id}")

      view
      |> form("#forecast-form", %{
        forecast: %{
          current_value: "50000",
          annual_contribution: "10000",
          growth_rate: "0.07",
          years: "5"
        }
      })
      |> render_submit()

      # Should show goal achievement timeline
      assert has_element?(view, "#goal-achievement")
      assert has_element?(view, "[data-testid='goal-completion-date']")
    end
  end
end
