defmodule AshfolioWeb.Components.ForecastChartTest do
  use AshfolioWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias AshfolioWeb.Components.ForecastChart

  @moduletag :unit
  @moduletag :component

  describe "ForecastChart Component - Rendering" do
    @tag :unit
    test "renders single projection line chart" do
      projection_data = %{
        years: Enum.to_list(0..30),
        values:
          Enum.map(0..30, fn year ->
            "100000"
            |> Decimal.new()
            |> Decimal.mult(Decimal.new(:math.pow(1.07, year)))
            |> Decimal.round(2)
          end)
      }

      assigns = %{
        id: "test-chart",
        data: projection_data,
        type: :single_projection,
        height: 400,
        width: 800
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
        />
        """)

      # Should render SVG chart
      assert html =~ ~s(<svg)
      assert html =~ ~s(id="test-chart")
      assert html =~ ~s(height="400")
      assert html =~ ~s(width="800")

      # Should have chart elements
      assert html =~ ~s(<g class="x-axis")
      assert html =~ ~s(<g class="y-axis")
      assert html =~ ~s(<path class="projection-line")
      assert html =~ ~s(<text class="chart-title")
    end

    @tag :unit
    test "renders multi-scenario comparison chart" do
      scenarios_data = %{
        years: Enum.to_list(0..30),
        pessimistic: generate_projection_values(Decimal.new("100000"), Decimal.new("0.05"), 30),
        realistic: generate_projection_values(Decimal.new("100000"), Decimal.new("0.07"), 30),
        optimistic: generate_projection_values(Decimal.new("100000"), Decimal.new("0.10"), 30)
      }

      assigns = %{
        id: "scenario-chart",
        data: scenarios_data,
        type: :scenario_comparison,
        height: 400,
        width: 800
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
        />
        """)

      # Should render three different lines
      assert html =~ ~s(class="line-pessimistic")
      assert html =~ ~s(class="line-realistic")
      assert html =~ ~s(class="line-optimistic")

      # Should have legend
      assert html =~ ~s(<g class="chart-legend")
      assert html =~ "Pessimistic (5%)"
      assert html =~ "Realistic (7%)"
      assert html =~ "Optimistic (10%)"
    end

    @tag :unit
    test "renders area chart for confidence bands" do
      confidence_data = %{
        years: Enum.to_list(0..30),
        median: generate_projection_values(Decimal.new("100000"), Decimal.new("0.07"), 30),
        lower_bound: generate_projection_values(Decimal.new("100000"), Decimal.new("0.05"), 30),
        upper_bound: generate_projection_values(Decimal.new("100000"), Decimal.new("0.09"), 30)
      }

      assigns = %{
        id: "confidence-chart",
        data: confidence_data,
        type: :confidence_band,
        height: 400,
        width: 800
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
        />
        """)

      # Should render area for confidence band
      assert html =~ ~s(<path class="confidence-area")
      assert html =~ ~s(fill-opacity="0.3")

      # Should render median line
      assert html =~ ~s(<path class="median-line")
      assert html =~ ~s(stroke-dasharray)
    end

    @tag :unit
    test "renders stacked area chart for contributions vs growth" do
      breakdown_data = %{
        years: Enum.to_list(0..30),
        principal: List.duplicate(Decimal.new("100000"), 31),
        contributions: Enum.map(0..30, &Decimal.mult(Decimal.new("12000"), Decimal.new(&1))),
        growth:
          Enum.map(0..30, fn year ->
            total = Decimal.mult(Decimal.new("100000"), Decimal.new(:math.pow(1.07, year)))
            contributions = Decimal.mult(Decimal.new("12000"), Decimal.new(year))

            total
            |> Decimal.sub(Decimal.add(Decimal.new("100000"), contributions))
            |> Decimal.round(2)
          end)
      }

      assigns = %{
        id: "breakdown-chart",
        data: breakdown_data,
        type: :stacked_breakdown,
        height: 400,
        width: 800
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
        />
        """)

      # Should render stacked areas
      assert html =~ ~s(<g class="stacked-areas")
      assert html =~ ~s(<path class="area-principal")
      assert html =~ ~s(<path class="area-contributions")
      assert html =~ ~s(<path class="area-growth")

      # Should have different colors for each stack
      assert html =~ ~s(fill="#)
    end
  end

  describe "ForecastChart Component - Interactivity" do
    @tag :unit
    test "includes hover tooltips for data points" do
      projection_data = %{
        years: [0, 10, 20, 30],
        values: [
          Decimal.new("100000"),
          Decimal.new("200000"),
          Decimal.new("400000"),
          Decimal.new("800000")
        ]
      }

      assigns = %{
        id: "interactive-chart",
        data: projection_data,
        type: :single_projection,
        height: 400,
        width: 800,
        interactive: true
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
          interactive={@interactive}
        />
        """)

      # Should have invisible hover targets
      assert html =~ ~s(<circle class="hover-target")
      assert html =~ ~s(r="5")
      assert html =~ ~s(fill="transparent")

      # Should have tooltip container
      assert html =~ ~s(<g class="tooltip" style="display: none")
      assert html =~ ~s(<rect class="tooltip-bg")
      assert html =~ ~s(<text class="tooltip-text")
    end

    @tag :unit
    test "includes zoom controls when enabled" do
      assigns = %{
        id: "zoomable-chart",
        data: %{years: [0], values: [Decimal.new("100000")]},
        type: :single_projection,
        height: 400,
        width: 800,
        zoomable: true
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
          zoomable={@zoomable}
        />
        """)

      # Should have zoom controls
      assert html =~ ~s(<g class="zoom-controls")
      assert html =~ ~s(<button class="zoom-in")
      assert html =~ ~s(<button class="zoom-out")
      assert html =~ ~s(<button class="zoom-reset")
    end

    @tag :unit
    test "includes click handlers for scenario selection" do
      scenarios_data = %{
        years: [0, 10, 20],
        pessimistic: [Decimal.new("100000"), Decimal.new("150000"), Decimal.new("225000")],
        realistic: [Decimal.new("100000"), Decimal.new("170000"), Decimal.new("290000")],
        optimistic: [Decimal.new("100000"), Decimal.new("200000"), Decimal.new("400000")]
      }

      assigns = %{
        id: "clickable-chart",
        data: scenarios_data,
        type: :scenario_comparison,
        height: 400,
        width: 800,
        clickable_scenarios: true
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
          clickable_scenarios={@clickable_scenarios}
        />
        """)

      # Each scenario line should be clickable
      assert html =~ ~s(phx-click="select_scenario")
      assert html =~ ~s(phx-value-scenario="pessimistic")
      assert html =~ ~s(phx-value-scenario="realistic")
      assert html =~ ~s(phx-value-scenario="optimistic")
      assert html =~ ~s(cursor: pointer)
    end
  end

  describe "ForecastChart Component - Responsive Design" do
    @tag :unit
    test "adapts to container width when responsive flag set" do
      assigns = %{
        id: "responsive-chart",
        data: %{years: [0], values: [Decimal.new("100000")]},
        type: :single_projection,
        responsive: true
      }

      html =
        rendered_to_string(~H"""
        <div class="chart-container" style="width: 100%;">
          <ForecastChart.render
            id={@id}
            data={@data}
            type={@type}
            responsive={@responsive}
          />
        </div>
        """)

      # Should have viewBox for responsive scaling
      assert html =~ ~s(viewBox="0 0)
      assert html =~ ~s(preserveAspectRatio="xMidYMid meet")
      refute html =~ ~s(width=")
      refute html =~ ~s(height=")
    end

    @tag :unit
    test "simplifies chart on mobile viewport" do
      assigns = %{
        id: "mobile-chart",
        data: %{
          years: Enum.to_list(0..30),
          values: Enum.to_list(0..30)
        },
        type: :single_projection,
        height: 300,
        width: 400,
        mobile: true
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
          mobile={@mobile}
        />
        """)

      # Should have simplified axis labels
      assert html =~ ~s(class="axis-label-mobile")

      # Should have larger touch targets
      # Larger than desktop r="5"
      assert html =~ ~s(r="10")
    end
  end

  describe "ForecastChart Component - Formatting" do
    @tag :unit
    test "formats currency values on y-axis" do
      assigns = %{
        id: "currency-chart",
        data: %{
          years: [0, 10, 20],
          values: [
            Decimal.new("100000"),
            Decimal.new("500000"),
            Decimal.new("1000000")
          ]
        },
        type: :single_projection,
        height: 400,
        width: 800,
        format: :currency
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
          format={@format}
        />
        """)

      # Y-axis labels should be formatted as currency
      assert html =~ "$100K"
      assert html =~ "$500K"
      assert html =~ "$1M"
    end

    @tag :unit
    test "formats percentage values for growth rates" do
      assigns = %{
        id: "percentage-chart",
        data: %{
          years: [0, 10, 20],
          rates: [
            Decimal.new("0.05"),
            Decimal.new("0.07"),
            Decimal.new("0.10")
          ]
        },
        type: :growth_rate,
        height: 400,
        width: 800,
        format: :percentage
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
          format={@format}
        />
        """)

      # Y-axis should show percentages
      assert html =~ "5%"
      assert html =~ "7%"
      assert html =~ "10%"
    end

    @tag :unit
    test "shows abbreviated large numbers" do
      assigns = %{
        id: "large-number-chart",
        data: %{
          years: [0, 30],
          values: [
            Decimal.new("100000"),
            Decimal.new("10000000")
          ]
        },
        type: :single_projection,
        height: 400,
        width: 800,
        format: :currency
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
          format={@format}
        />
        """)

      # Should abbreviate millions
      assert html =~ "$10M"
      refute html =~ "$10,000,000"
    end
  end

  describe "ForecastChart Component - Annotations" do
    @tag :unit
    test "displays milestone markers" do
      assigns = %{
        id: "milestone-chart",
        data: %{
          years: Enum.to_list(0..30),
          values: 0..30 |> Enum.to_list() |> Enum.map(&Decimal.new("#{&1 * 10_000}"))
        },
        type: :single_projection,
        height: 400,
        width: 800,
        milestones: [
          %{year: 10, label: "First $100k", value: Decimal.new("100000")},
          %{year: 20, label: "Retirement Target", value: Decimal.new("200000")}
        ]
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
          milestones={@milestones}
        />
        """)

      # Should have milestone markers
      assert html =~ ~s(<g class="milestone")
      assert html =~ "First $100k"
      assert html =~ "Retirement Target"

      # Should have vertical lines at milestones
      assert html =~ ~s(<line class="milestone-line")
      assert html =~ ~s(stroke-dasharray="5,5")
    end

    @tag :unit
    test "highlights FI achievement point" do
      assigns = %{
        id: "fi-chart",
        data: %{
          years: Enum.to_list(0..30),
          values: 0..30 |> Enum.to_list() |> Enum.map(&Decimal.mult(Decimal.new("50000"), Decimal.new(&1)))
        },
        type: :single_projection,
        height: 400,
        width: 800,
        fi_target: Decimal.new("1250000"),
        fi_year: 25
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
          fi_target={@fi_target}
          fi_year={@fi_year}
        />
        """)

      # Should have FI marker
      assert html =~ ~s(<g class="fi-marker")
      assert html =~ "Financial Independence"
      assert html =~ ~s(<circle class="fi-point")
      # Success color
      assert html =~ ~s(fill="#10b981")
    end

    @tag :unit
    test "shows today marker on timeline" do
      assigns = %{
        id: "today-chart",
        data: %{
          years: Enum.to_list(-5..30),
          values: -5..30 |> Enum.to_list() |> Enum.map(&Decimal.new("#{(&1 + 5) * 10_000}"))
        },
        type: :single_projection,
        height: 400,
        width: 800,
        show_today: true,
        today_year: 0
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
          show_today={@show_today}
          today_year={@today_year}
        />
        """)

      # Should have today marker
      assert html =~ ~s(<g class="today-marker")
      assert html =~ "Today"
      assert html =~ ~s(<line class="today-line")
      # Red color for current position
      assert html =~ ~s(stroke="#ef4444")
    end
  end

  describe "ForecastChart Component - Error States" do
    @tag :unit
    test "displays message when no data provided" do
      assigns = %{
        id: "empty-chart",
        data: %{years: [], values: []},
        type: :single_projection,
        height: 400,
        width: 800
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
        />
        """)

      # Should show no data message
      assert html =~ "No projection data available"
      assert html =~ ~s(class="chart-empty-state")
    end

    @tag :unit
    test "handles invalid data gracefully" do
      assigns = %{
        id: "invalid-chart",
        data: %{
          years: [0, 10, 20],
          values: [nil, Decimal.new("100000"), nil]
        },
        type: :single_projection,
        height: 400,
        width: 800
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
        />
        """)

      # Should filter out invalid points
      assert html =~ ~s(<path)
      # Should show warning about invalid data
      assert html =~ ~s(class="data-warning")
      assert html =~ "Some data points could not be displayed"
    end
  end

  describe "ForecastChart Component - Accessibility" do
    @tag :unit
    test "includes ARIA labels and descriptions" do
      assigns = %{
        id: "accessible-chart",
        data: %{
          years: [0, 10, 20],
          values: [Decimal.new("100000"), Decimal.new("200000"), Decimal.new("400000")]
        },
        type: :single_projection,
        height: 400,
        width: 800,
        title: "Portfolio Growth Projection",
        description: "Shows portfolio value over 20 years"
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
          title={@title}
          description={@description}
        />
        """)

      # Should have ARIA attributes
      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Portfolio Growth Projection")
      assert html =~ ~s(aria-describedby="accessible-chart-desc")

      # Should have description element
      assert html =~ ~s(<desc id="accessible-chart-desc")
      assert html =~ "Shows portfolio value over 20 years"
    end

    @tag :unit
    test "provides table alternative for screen readers" do
      assigns = %{
        id: "sr-chart",
        data: %{
          years: [0, 10, 20],
          values: [Decimal.new("100000"), Decimal.new("200000"), Decimal.new("400000")]
        },
        type: :single_projection,
        height: 400,
        width: 800,
        screen_reader_table: true
      }

      html =
        rendered_to_string(~H"""
        <ForecastChart.render
          id={@id}
          data={@data}
          type={@type}
          height={@height}
          width={@width}
          screen_reader_table={@screen_reader_table}
        />
        """)

      # Should have hidden table for screen readers
      assert html =~ ~s(<table class="sr-only")
      assert html =~ ~s(<caption>Chart data in tabular format</caption>)
      assert html =~ "<th>Year</th>"
      assert html =~ "<th>Value</th>"
      assert html =~ "<td>0</td>"
      assert html =~ "<td>$100,000</td>"
    end
  end

  # Helper function for generating test data
  defp generate_projection_values(initial, rate, years) do
    Enum.map(0..years, fn year ->
      growth_factor = :math.pow(1 + Decimal.to_float(rate), year)

      initial
      |> Decimal.mult(Decimal.from_float(growth_factor))
      |> Decimal.round(2)
    end)
  end
end
