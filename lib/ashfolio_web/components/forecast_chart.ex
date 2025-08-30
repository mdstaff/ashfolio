defmodule AshfolioWeb.Components.ForecastChart do
  @moduledoc """
  Portfolio forecasting chart components using Contex.

  Provides specialized chart visualizations for financial forecasting data
  including single projections, scenario comparisons, and confidence bands.
  """

  use Phoenix.Component

  @doc """
  Renders financial forecast charts with multiple visualization types.

  ## Examples

      <ForecastChart.render
        id="projection-chart"
        data={%{years: [0, 10, 20], values: [100000, 200000, 400000]}}
        type={:single_projection}
        height={400}
        width={800} />

      <ForecastChart.render
        id="scenario-chart"
        data={%{
          years: [0, 10, 20],
          pessimistic: [100000, 150000, 225000],
          realistic: [100000, 170000, 290000],
          optimistic: [100000, 200000, 400000]
        }}
        type={:scenario_comparison}
        height={400}
        width={800} />
  """
  attr :id, :string, required: true, doc: "Unique identifier for the chart"
  attr :data, :map, required: true, doc: "Chart data structure"

  attr :type, :atom,
    required: true,
    doc: "Chart type (:single_projection, :scenario_comparison, etc.)"

  attr :height, :integer, default: 400, doc: "Chart height in pixels"
  attr :width, :integer, default: 800, doc: "Chart width in pixels"
  attr :responsive, :boolean, default: false, doc: "Enable responsive scaling"
  attr :mobile, :boolean, default: false, doc: "Mobile-optimized view"
  attr :interactive, :boolean, default: false, doc: "Enable hover tooltips"
  attr :zoomable, :boolean, default: false, doc: "Enable zoom controls"
  attr :clickable_scenarios, :boolean, default: false, doc: "Enable scenario clicking"
  attr :format, :atom, default: :currency, doc: "Value format (:currency, :percentage)"
  attr :title, :string, default: nil, doc: "Chart title"
  attr :description, :string, default: nil, doc: "Chart description for accessibility"
  attr :milestones, :list, default: [], doc: "List of milestone markers"
  attr :fi_target, :any, default: nil, doc: "Financial independence target"
  attr :fi_year, :integer, default: nil, doc: "Financial independence year"
  attr :show_today, :boolean, default: false, doc: "Show today marker"
  attr :today_year, :integer, default: 0, doc: "Current year position"
  attr :screen_reader_table, :boolean, default: false, doc: "Include screen reader table"

  def render(assigns) do
    cond do
      empty_data?(assigns.data) ->
        render_empty_state(assigns)

      has_invalid_data?(assigns.data) ->
        render_invalid_data_warning(assigns)

      true ->
        render_chart(assigns)
    end
  end

  defp render_empty_state(assigns) do
    ~H"""
    <div
      id={@id}
      class="chart-empty-state flex items-center justify-center h-64 bg-gray-50 rounded-lg border-2 border-dashed border-gray-300"
    >
      <div class="text-center">
        <svg
          class="mx-auto h-12 w-12 text-gray-400"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
          />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900">No projection data available</h3>
        <p class="mt-1 text-sm text-gray-500">Enter your portfolio details to generate projections</p>
      </div>
    </div>
    """
  end

  defp render_invalid_data_warning(assigns) do
    ~H"""
    <div id={@id} class="chart-container">
      {render_chart_svg(assigns)}
      <div class="data-warning mt-2 p-2 bg-yellow-50 border border-yellow-200 rounded">
        <p class="text-sm text-yellow-800">⚠️ Some data points could not be displayed</p>
      </div>
    </div>
    """
  end

  defp render_chart(assigns) do
    ~H"""
    <div id={@id} class={chart_container_class(assigns)}>
      <%= if assigns.title || assigns.description do %>
        <div class="chart-header mb-4">
          <%= if assigns.title do %>
            <h3 class="text-lg font-medium text-gray-900">{assigns.title}</h3>
          <% end %>
          <%= if assigns.description do %>
            <p class="text-sm text-gray-500">{assigns.description}</p>
          <% end %>
        </div>
      <% end %>

      {render_chart_svg(assigns)}

      <%= if assigns.zoomable do %>
        {render_zoom_controls(assigns)}
      <% end %>

      <%= if assigns.screen_reader_table do %>
        {render_screen_reader_table(assigns)}
      <% end %>
    </div>
    """
  end

  defp render_chart_svg(assigns) do
    assigns =
      assigns
      |> assign(:svg_attrs, build_svg_attributes(assigns))
      |> assign(:processed_chart_data, process_chart_data(assigns))

    ~H"""
    <svg
      {@svg_attrs}
      role="img"
      aria-label={@title || "Portfolio Forecast Chart"}
      aria-describedby={if @description, do: "#{@id}-desc"}
      data-chart-type={@type}
      data-chart-max={format_max_value(@processed_chart_data, @format)}
    >
      <%= if @description do %>
        <desc id={"#{@id}-desc"}>{@description}</desc>
      <% end %>

      {render_axes(assigns)}
      {render_chart_content(assigns)}
      {render_milestones(assigns)}
      {render_fi_markers(assigns)}
      {render_today_marker(assigns)}

      <%= if @interactive do %>
        {render_tooltip_elements(assigns)}
      <% end %>
    </svg>
    """
  end

  defp render_chart_content(%{type: :single_projection} = assigns) do
    assigns = assign(assigns, :chart_data, assigns.processed_chart_data)

    ~H"""
    <g class="chart-content">
      <path
        class="projection-line chart-line"
        d={build_line_path(@chart_data.years, @chart_data.values)}
        fill="none"
        stroke="#3b82f6"
        stroke-width="2"
      />

      <%= if @interactive do %>
        <%= for {year, value} <- Enum.zip(@chart_data.years, @chart_data.values) do %>
          <circle
            class="hover-target"
            cx={scale_x(year, @chart_data)}
            cy={scale_y(value, @chart_data)}
            r="5"
            fill="transparent"
            data-year={year}
            data-value={format_value(value, @format)}
          />
        <% end %>
      <% end %>
    </g>
    """
  end

  defp render_chart_content(%{type: :scenario_comparison} = assigns) do
    scenarios = [:pessimistic, :realistic, :optimistic]
    colors = ["#ef4444", "#3b82f6", "#10b981"]

    assigns =
      assigns
      |> assign(:chart_data, assigns.processed_chart_data)
      |> assign(:scenario_colors, Enum.zip(scenarios, colors))
      |> assign(:scenario_legend, Enum.with_index(Enum.zip(scenarios, colors)))

    ~H"""
    <g class="chart-content">
      <%= for {scenario, color} <- @scenario_colors do %>
        <%= if Map.has_key?(@chart_data, scenario) do %>
          <path
            class={"line-#{scenario}"}
            d={build_line_path(@chart_data.years, Map.get(@chart_data, scenario))}
            fill="none"
            stroke={color}
            stroke-width="2"
            style={if @clickable_scenarios, do: "cursor: pointer"}
            phx-click={if @clickable_scenarios, do: "select_scenario"}
            phx-value-scenario={scenario}
          />
        <% end %>
      <% end %>

      <g class="chart-legend">
        <%= for {{scenario, color}, index} <- @scenario_legend do %>
          <g transform={"translate(#{@width - 120}, #{20 + index * 20})"}>
            <line x1="0" y1="0" x2="15" y2="0" stroke={color} stroke-width="2" />
            <text x="20" y="5" class="text-xs fill-current text-gray-600">
              {format_scenario_name(scenario)}
            </text>
          </g>
        <% end %>
      </g>
    </g>
    """
  end

  defp render_chart_content(%{type: :confidence_band} = assigns) do
    assigns = assign(assigns, :chart_data, assigns.processed_chart_data)

    ~H"""
    <g class="chart-content">
      <path
        class="confidence-area"
        d={build_area_path(@chart_data.years, @chart_data.lower_bound, @chart_data.upper_bound)}
        fill="#3b82f6"
        fill-opacity="0.3"
      />

      <path
        class="median-line"
        d={build_line_path(@chart_data.years, @chart_data.median)}
        fill="none"
        stroke="#3b82f6"
        stroke-width="2"
        stroke-dasharray="5,5"
      />
    </g>
    """
  end

  defp render_chart_content(%{type: :stacked_breakdown} = assigns) do
    assigns = assign(assigns, :chart_data, assigns.processed_chart_data)

    ~H"""
    <g class="chart-content stacked-areas">
      <path
        class="area-principal"
        d={build_stacked_area_path(@chart_data.years, @chart_data.principal, 0)}
        fill="#6b7280"
      />

      <path
        class="area-contributions"
        d={
          build_stacked_area_path(@chart_data.years, @chart_data.contributions, @chart_data.principal)
        }
        fill="#3b82f6"
      />

      <path
        class="area-growth"
        d={
          build_stacked_area_path(
            @chart_data.years,
            @chart_data.growth,
            add_arrays(@chart_data.principal, @chart_data.contributions)
          )
        }
        fill="#10b981"
      />
    </g>
    """
  end

  defp render_chart_content(assigns) do
    # Default fallback for unknown chart types
    ~H"""
    <g class="chart-content">
      <!-- No chart content for unknown type -->
    </g>
    """
  end

  defp render_axes(assigns) do
    chart_data = assigns.processed_chart_data
    assigns = assign(assigns, :chart_data, chart_data)

    ~H"""
    <g class="x-axis">
      {render_x_axis_line(assigns)}
      {render_x_axis_labels(assigns)}
    </g>

    <g class="y-axis">
      {render_y_axis_line(assigns)}
      {render_y_axis_labels(assigns)}
    </g>
    """
  end

  defp render_x_axis_line(assigns) do
    margin = 60
    y_pos = assigns.height - margin

    assigns =
      assigns
      |> assign(:margin, margin)
      |> assign(:y_pos, y_pos)

    ~H"""
    <line
      x1={@margin}
      y1={@y_pos}
      x2={@width - @margin}
      y2={@y_pos}
      stroke="#e5e7eb"
      stroke-width="1"
    />
    """
  end

  defp render_x_axis_labels(assigns) do
    margin = 60
    y_pos = assigns.height - margin + 20
    years = assigns.chart_data.years
    # Show max 6 labels
    step = max(1, div(length(years), 6))

    assigns =
      assigns
      |> assign(:y_pos, y_pos)
      |> assign(
        :year_labels,
        years |> Enum.with_index() |> Enum.filter(fn {_year, index} -> rem(index, step) == 0 end)
      )

    ~H"""
    <%= for {year, _index} <- @year_labels do %>
      <text
        x={scale_x(year, @chart_data)}
        y={@y_pos}
        text-anchor="middle"
        class={axis_label_class(assigns)}
      >
        {year}
      </text>
    <% end %>
    """
  end

  defp render_y_axis_line(assigns) do
    margin = 60

    assigns = assign(assigns, :margin, margin)

    ~H"""
    <line
      x1={@margin}
      y1={@margin}
      x2={@margin}
      y2={@height - @margin}
      stroke="#e5e7eb"
      stroke-width="1"
    />
    """
  end

  defp render_y_axis_labels(assigns) do
    margin = 60
    x_pos = margin - 10
    max_value = get_max_value(assigns.chart_data)
    num_labels = 5

    label_values = Enum.map(0..(num_labels - 1), fn i -> max_value * i / (num_labels - 1) end)

    assigns =
      assigns
      |> assign(:x_pos, x_pos)
      |> assign(:label_values, label_values)

    ~H"""
    <%= for value <- @label_values do %>
      <text
        x={@x_pos}
        y={scale_y(value, @chart_data)}
        text-anchor="end"
        dominant-baseline="middle"
        class={axis_label_class(assigns)}
      >
        {format_axis_value(value, @format)}
      </text>
    <% end %>
    """
  end

  defp render_milestones(%{milestones: []} = assigns) do
    ~H"""
    <!-- no milestones -->
    """
  end

  defp render_milestones(%{milestones: milestones} = assigns) do
    assigns = assign(assigns, :milestones, milestones)

    ~H"""
    <%= for milestone <- @milestones do %>
      <g class="milestone">
        <line
          class="milestone-line"
          x1={scale_x(milestone.year, %{years: [0, 30]})}
          y1="60"
          x2={scale_x(milestone.year, %{years: [0, 30]})}
          y2={@height - 60}
          stroke="#f59e0b"
          stroke-width="1"
          stroke-dasharray="5,5"
        />

        <text
          x={scale_x(milestone.year, %{years: [0, 30]})}
          y="50"
          text-anchor="middle"
          class="text-xs fill-current text-yellow-600"
        >
          {milestone.label}
        </text>
      </g>
    <% end %>
    """
  end

  defp render_fi_markers(%{fi_target: nil} = assigns) do
    ~H"""
    <!-- no FI markers -->
    """
  end

  defp render_fi_markers(%{fi_target: fi_target, fi_year: fi_year} = assigns) when not is_nil(fi_year) do
    assigns =
      assigns
      |> assign(:fi_target, fi_target)
      |> assign(:fi_year, fi_year)

    ~H"""
    <g class="fi-marker">
      <circle
        class="fi-point"
        cx={scale_x(@fi_year, %{years: [0, 30]})}
        cy={scale_y(Decimal.to_float(@fi_target), %{values: [0, Decimal.to_float(@fi_target) * 1.2]})}
        r="6"
        fill="#10b981"
      />

      <text
        x={scale_x(@fi_year, %{years: [0, 30]})}
        y={
          scale_y(Decimal.to_float(@fi_target), %{values: [0, Decimal.to_float(@fi_target) * 1.2]}) -
            15
        }
        text-anchor="middle"
        class="text-xs fill-current text-green-600"
      >
        Financial Independence
      </text>
    </g>
    """
  end

  defp render_today_marker(%{show_today: false} = assigns) do
    ~H"""
    <!-- no today marker -->
    """
  end

  defp render_today_marker(%{show_today: true, today_year: today_year} = assigns) do
    assigns = assign(assigns, :today_year, today_year)

    ~H"""
    <g class="today-marker">
      <line
        class="today-line"
        x1={scale_x(@today_year, %{years: [-5, 30]})}
        y1="60"
        x2={scale_x(@today_year, %{years: [-5, 30]})}
        y2={@height - 60}
        stroke="#ef4444"
        stroke-width="2"
      />

      <text
        x={scale_x(@today_year, %{years: [-5, 30]})}
        y="50"
        text-anchor="middle"
        class="text-xs fill-current text-red-600 font-medium"
      >
        Today
      </text>
    </g>
    """
  end

  defp render_tooltip_elements(assigns) do
    ~H"""
    <g class="tooltip" style="display: none">
      <rect
        class="tooltip-bg"
        x="0"
        y="0"
        width="120"
        height="40"
        fill="black"
        fill-opacity="0.8"
        rx="4"
      />

      <text class="tooltip-text" x="10" y="20" fill="white" class="text-sm">
        Tooltip content
      </text>
    </g>
    """
  end

  defp render_zoom_controls(assigns) do
    ~H"""
    <div class="zoom-controls absolute top-4 right-4 flex space-x-1">
      <button class="zoom-in px-2 py-1 bg-white border rounded text-sm hover:bg-gray-50">+</button>
      <button class="zoom-out px-2 py-1 bg-white border rounded text-sm hover:bg-gray-50">-</button>
      <button class="zoom-reset px-2 py-1 bg-white border rounded text-sm hover:bg-gray-50">
        Reset
      </button>
    </div>
    """
  end

  defp render_screen_reader_table(assigns) do
    chart_data = process_chart_data(assigns)

    assigns = assign(assigns, :chart_data, chart_data)

    ~H"""
    <table class="sr-only">
      <caption>Chart data in tabular format</caption>
      <thead>
        <tr>
          <th>Year</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody>
        <%= if @type == :single_projection do %>
          <%= for {year, value} <- Enum.zip(@chart_data.years, @chart_data.values) do %>
            <tr>
              <td>{year}</td>
              <td>{format_value(value, @format)}</td>
            </tr>
          <% end %>
        <% end %>
      </tbody>
    </table>
    """
  end

  # Helper functions

  defp chart_container_class(assigns) do
    base_classes = ["chart-container", "relative"]

    mobile_classes = if assigns.mobile, do: ["mobile-view"], else: []
    responsive_classes = if assigns.responsive, do: ["w-full"], else: []

    Enum.join(base_classes ++ mobile_classes ++ responsive_classes, " ")
  end

  defp build_svg_attributes(assigns) do
    base_attrs = %{
      id: "#{assigns.id}-svg",
      class: "chart-svg"
    }

    if assigns.responsive do
      Map.merge(base_attrs, %{
        viewBox: "0 0 #{assigns.width} #{assigns.height}",
        preserveAspectRatio: "xMidYMid meet"
      })
    else
      Map.merge(base_attrs, %{
        width: assigns.width,
        height: assigns.height
      })
    end
  end

  defp process_chart_data(%{data: data, type: type}) do
    case type do
      :single_projection ->
        %{
          years: data.years || [],
          values: data.values || []
        }

      :scenario_comparison ->
        %{
          years: data.years || [],
          pessimistic: data.pessimistic || [],
          realistic: data.realistic || [],
          optimistic: data.optimistic || []
        }

      :confidence_band ->
        %{
          years: data.years || [],
          median: data.median || [],
          lower_bound: data.lower_bound || [],
          upper_bound: data.upper_bound || []
        }

      :stacked_breakdown ->
        %{
          years: data.years || [],
          principal: data.principal || [],
          contributions: data.contributions || [],
          growth: data.growth || []
        }

      _ ->
        data
    end
  end

  defp empty_data?(%{years: years, values: values}) when is_list(years) and is_list(values) do
    Enum.empty?(years) or Enum.empty?(values)
  end

  defp empty_data?(_data), do: false

  defp has_invalid_data?(%{values: values}) when is_list(values) do
    Enum.any?(values, &is_nil/1)
  end

  defp has_invalid_data?(_data), do: false

  defp build_line_path([], []), do: ""

  defp build_line_path(years, values) do
    points =
      years
      |> Enum.zip(values)
      |> Enum.map(fn {year, value} ->
        x = scale_x(year, %{years: years})
        y = scale_y(value, %{values: values})
        "#{x},#{y}"
      end)

    case points do
      [first | rest] ->
        "M #{first} " <> Enum.map_join(rest, " ", &"L #{&1}")

      [] ->
        ""
    end
  end

  defp build_area_path(_years, [], []), do: ""

  defp build_area_path(years, lower, upper) do
    # Build path that goes along lower bound, then back along upper bound
    lower_points =
      years
      |> Enum.zip(lower)
      |> Enum.map(fn {year, value} ->
        x = scale_x(year, %{years: years})
        y = scale_y(value, %{values: lower ++ upper})
        "#{x},#{y}"
      end)

    upper_points =
      years
      |> Enum.zip(upper)
      |> Enum.reverse()
      |> Enum.map(fn {year, value} ->
        x = scale_x(year, %{years: years})
        y = scale_y(value, %{values: lower ++ upper})
        "#{x},#{y}"
      end)

    case {lower_points, upper_points} do
      {[first | rest_lower], upper_points} ->
        lower_path = "M #{first} " <> Enum.map_join(rest_lower, " ", &"L #{&1}")
        upper_path = Enum.map_join(upper_points, " ", &"L #{&1}")
        lower_path <> " " <> upper_path <> " Z"

      _ ->
        ""
    end
  end

  defp build_stacked_area_path(years, values, base_values) do
    # Ensure base_values is a list
    normalized_base =
      cond do
        is_list(base_values) -> base_values
        is_number(base_values) -> List.duplicate(base_values, length(years))
        true -> List.duplicate(0, length(years))
      end

    # Build area from base_values to base_values + values
    combined_values =
      if is_list(normalized_base) and length(normalized_base) == length(values) do
        normalized_base |> Enum.zip(values) |> Enum.map(fn {base, val} -> add_values(base, val) end)
      else
        values
      end

    build_area_path(years, normalized_base, combined_values)
  end

  defp scale_x(value, %{years: years}) when is_list(years) and length(years) > 0 do
    margin = 60
    width = 800 - 2 * margin
    min_year = Enum.min(years)
    max_year = Enum.max(years)

    if max_year == min_year do
      margin + width / 2
    else
      margin + width * (value - min_year) / (max_year - min_year)
    end
  end

  defp scale_x(_value, _data), do: 60

  defp scale_y(value, %{values: values}) when is_list(values) and length(values) > 0 do
    margin = 60
    height = 400 - 2 * margin

    # Handle Decimal values
    numeric_values =
      Enum.map(values, fn val ->
        cond do
          is_struct(val, Decimal) -> Decimal.to_float(val)
          is_number(val) -> val
          true -> 0
        end
      end)

    min_value = Enum.min(numeric_values)
    max_value = Enum.max(numeric_values)

    numeric_value =
      cond do
        is_struct(value, Decimal) -> Decimal.to_float(value)
        is_number(value) -> value
        true -> 0
      end

    if max_value == min_value do
      margin + height / 2
    else
      margin + height - height * (numeric_value - min_value) / (max_value - min_value)
    end
  end

  defp scale_y(_value, _data), do: 200

  defp get_max_value(%{values: values}) when is_list(values) do
    values
    |> Enum.map(fn val ->
      cond do
        is_struct(val, Decimal) -> Decimal.to_float(val)
        is_number(val) -> val
        true -> 0
      end
    end)
    |> Enum.max(fn -> 0 end)
  end

  defp get_max_value(_data), do: 1_000_000

  defp format_max_value(chart_data, format) do
    max_val = get_max_value(chart_data)
    format_axis_value(max_val, format)
  end

  defp format_axis_value(value, :currency) when value >= 1_000_000 do
    float_value = ensure_float(value)
    "$#{:erlang.float_to_binary(float_value / 1_000_000, decimals: 0)}M"
  end

  defp format_axis_value(value, :currency) when value >= 1_000 do
    float_value = ensure_float(value)
    "$#{:erlang.float_to_binary(float_value / 1_000, decimals: 0)}K"
  end

  defp format_axis_value(value, :currency) do
    float_value = ensure_float(value)
    "$#{:erlang.float_to_binary(float_value, decimals: 0)}"
  end

  defp format_axis_value(value, :percentage) do
    float_value = ensure_float(value)
    "#{:erlang.float_to_binary(float_value * 100, decimals: 0)}%"
  end

  defp format_axis_value(value, _) do
    float_value = ensure_float(value)
    :erlang.float_to_binary(float_value, decimals: 0)
  end

  # Helper to ensure value is a float
  defp ensure_float(value) when is_float(value), do: value
  defp ensure_float(value) when is_integer(value), do: value * 1.0
  defp ensure_float(%Decimal{} = value), do: Decimal.to_float(value)
  defp ensure_float(_), do: 0.0

  defp format_value(value, format) do
    numeric_value =
      cond do
        is_struct(value, Decimal) -> Decimal.to_float(value)
        is_number(value) -> value
        true -> 0
      end

    format_axis_value(numeric_value, format)
  end

  defp axis_label_class(%{mobile: true}), do: "text-xs fill-current text-gray-600 axis-label-mobile"

  defp axis_label_class(_), do: "text-xs fill-current text-gray-600"

  defp format_scenario_name(:pessimistic), do: "Pessimistic (5%)"
  defp format_scenario_name(:realistic), do: "Realistic (7%)"
  defp format_scenario_name(:optimistic), do: "Optimistic (10%)"
  defp format_scenario_name(name), do: to_string(name)

  defp add_arrays(list1, list2) when is_list(list1) and is_list(list2) do
    list1 |> Enum.zip(list2) |> Enum.map(fn {a, b} -> add_values(a, b) end)
  end

  defp add_arrays(list, _) when is_list(list), do: list
  defp add_arrays(_, list) when is_list(list), do: list
  defp add_arrays(_, _), do: []

  # Helper to add values of different types
  defp add_values(a, b) when is_number(a) and is_number(b), do: a + b

  defp add_values(a, %Decimal{} = b) when is_number(a) do
    Decimal.add(Decimal.new(a), b)
  end

  defp add_values(%Decimal{} = a, b) when is_number(b) do
    Decimal.add(a, Decimal.new(b))
  end

  defp add_values(%Decimal{} = a, %Decimal{} = b) do
    Decimal.add(a, b)
  end

  defp add_values(a, b), do: a + b
end
