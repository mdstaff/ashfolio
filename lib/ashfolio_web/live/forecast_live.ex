defmodule AshfolioWeb.ForecastLive.Index do
  @moduledoc """
  LiveView for portfolio forecasting and scenario planning.

  Provides interactive forms for portfolio growth projections with:
  - Single projections with customizable parameters
  - Scenario comparisons (pessimistic, realistic, optimistic)
  - Contribution impact analysis
  - Goal optimization calculations
  """

  use AshfolioWeb, :live_view

  alias Ashfolio.FinancialManagement.ForecastCalculator
  alias AshfolioWeb.Components.ForecastChart
  alias AshfolioWeb.Live.ErrorHelpers
  alias AshfolioWeb.Live.FormatHelpers

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Ashfolio.PubSub.subscribe("accounts")
      Ashfolio.PubSub.subscribe("transactions")
    end

    # Get current portfolio value
    current_portfolio_value = get_current_portfolio_value()

    # Set default form values
    default_form_data = %{
      "current_value" => Decimal.to_string(current_portfolio_value),
      "monthly_contribution" => "1000",
      "growth_rate" => "0.07",
      "years" => "30"
    }

    socket =
      socket
      |> assign_current_page(:forecast)
      |> assign(:page_title, "Portfolio Forecast")
      |> assign(:form_data, default_form_data)
      |> assign(:current_portfolio_value, current_portfolio_value)
      |> assign(:projection_results, nil)
      |> assign(:scenario_results, nil)
      |> assign(:contribution_analysis, nil)
      |> assign(:active_tab, "projection")
      |> assign(:loading, false)
      |> assign(:chart_data, %{})

    {:ok, socket}
  end

  @impl true
  def handle_event("update_form", %{"form" => form_params}, socket) do
    socket = assign(socket, :form_data, form_params)
    {:noreply, socket}
  end

  @impl true
  def handle_event("calculate_projection", _params, socket) do
    socket = assign(socket, :loading, true)
    form_params = socket.assigns.form_data || %{}

    with {:ok, current_value} <- parse_decimal(form_params["current_value"]),
         {:ok, monthly_contribution} <- parse_decimal(form_params["monthly_contribution"]),
         {:ok, growth_rate} <- parse_decimal(form_params["growth_rate"]),
         {:ok, years} <- parse_integer(form_params["years"]) do
      annual_contribution = Decimal.mult(monthly_contribution, Decimal.new("12"))

      case ForecastCalculator.project_portfolio_growth(
             current_value,
             annual_contribution,
             years,
             growth_rate
           ) do
        {:ok, projected_value} ->
          # Also calculate multi-period projections for chart
          periods = generate_chart_periods(years)

          case ForecastCalculator.project_multi_period_growth(
                 current_value,
                 annual_contribution,
                 growth_rate,
                 periods
               ) do
            {:ok, multi_projections} ->
              projection_results = %{
                final_value: projected_value,
                periods: multi_projections,
                parameters: %{
                  current_value: current_value,
                  monthly_contribution: monthly_contribution,
                  annual_contribution: annual_contribution,
                  growth_rate: growth_rate,
                  years: years
                }
              }

              chart_data = build_projection_chart_data(multi_projections, periods)

              socket =
                socket
                |> assign(:projection_results, projection_results)
                |> assign(:chart_data, chart_data)
                |> assign(:loading, false)
                |> ErrorHelpers.put_success_flash("Projection calculated successfully!")

              {:noreply, socket}

            {:error, reason} ->
              handle_calculation_error(socket, reason)
          end

        {:error, reason} ->
          handle_calculation_error(socket, reason)
      end
    else
      {:error, reason} ->
        handle_validation_error(socket, reason)
    end
  end

  @impl true
  def handle_event("calculate_scenarios", _params, socket) do
    socket = assign(socket, :loading, true)
    form_params = socket.assigns.form_data

    with {:ok, current_value} <- parse_decimal(form_params["current_value"]),
         {:ok, monthly_contribution} <- parse_decimal(form_params["monthly_contribution"]),
         {:ok, years} <- parse_integer(form_params["years"]) do
      annual_contribution = Decimal.mult(monthly_contribution, Decimal.new("12"))

      case ForecastCalculator.calculate_scenario_projections(
             current_value,
             annual_contribution,
             years
           ) do
        {:ok, scenarios} ->
          scenario_results = %{
            scenarios: scenarios,
            parameters: %{
              current_value: current_value,
              monthly_contribution: monthly_contribution,
              annual_contribution: annual_contribution,
              years: years
            }
          }

          chart_data = build_scenario_chart_data(scenarios, years)

          socket =
            socket
            |> assign(:scenario_results, scenario_results)
            |> assign(:chart_data, chart_data)
            |> assign(:loading, false)
            |> ErrorHelpers.put_success_flash("Scenarios calculated successfully!")

          {:noreply, socket}

        {:error, reason} ->
          handle_calculation_error(socket, reason)
      end
    else
      {:error, reason} ->
        handle_validation_error(socket, reason)
    end
  end

  @impl true
  def handle_event("analyze_contributions", _params, socket) do
    socket = assign(socket, :loading, true)
    form_params = socket.assigns.form_data

    with {:ok, current_value} <- parse_decimal(form_params["current_value"]),
         {:ok, monthly_contribution} <- parse_decimal(form_params["monthly_contribution"]),
         {:ok, growth_rate} <- parse_decimal(form_params["growth_rate"]),
         {:ok, years} <- parse_integer(form_params["years"]) do
      case ForecastCalculator.analyze_contribution_impact(
             current_value,
             monthly_contribution,
             years,
             growth_rate
           ) do
        {:ok, analysis} ->
          contribution_analysis = %{
            analysis: analysis,
            parameters: %{
              current_value: current_value,
              monthly_contribution: monthly_contribution,
              growth_rate: growth_rate,
              years: years
            }
          }

          socket =
            socket
            |> assign(:contribution_analysis, contribution_analysis)
            |> assign(:loading, false)
            |> ErrorHelpers.put_success_flash("Contribution analysis completed!")

          {:noreply, socket}

        {:error, reason} ->
          handle_calculation_error(socket, reason)
      end
    else
      {:error, reason} ->
        handle_validation_error(socket, reason)
    end
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    socket = assign(socket, :active_tab, tab)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:account_updated, _account_id}, socket) do
    # Update current portfolio value when accounts change
    current_portfolio_value = get_current_portfolio_value()

    form_data =
      Map.put(
        socket.assigns.form_data,
        "current_value",
        Decimal.to_string(current_portfolio_value)
      )

    socket =
      socket
      |> assign(:current_portfolio_value, current_portfolio_value)
      |> assign(:form_data, form_data)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:transaction_created, _transaction_id}, socket) do
    # Update current portfolio value when transactions are added
    current_portfolio_value = get_current_portfolio_value()

    form_data =
      Map.put(
        socket.assigns.form_data,
        "current_value",
        Decimal.to_string(current_portfolio_value)
      )

    socket =
      socket
      |> assign(:current_portfolio_value, current_portfolio_value)
      |> assign(:form_data, form_data)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Page Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Portfolio Forecast</h1>
          <p class="text-gray-600">Project your portfolio growth with different scenarios</p>
        </div>
        <div class="flex gap-3">
          <.link href={~p"/goals"} class="btn-secondary">
            <.icon name="hero-flag" class="w-4 h-4 mr-2" /> Goals
          </.link>
          <.link href={~p"/"} class="btn-primary">
            <.icon name="hero-chart-bar" class="w-4 h-4 mr-2" /> Dashboard
          </.link>
        </div>
      </div>
      
    <!-- Tab Navigation -->
      <div class="border-b border-gray-200">
        <nav class="-mb-px flex space-x-8">
          <button
            phx-click="switch_tab"
            phx-value-tab="projection"
            class={tab_class(@active_tab == "projection")}
          >
            Single Projection
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="scenarios"
            class={tab_class(@active_tab == "scenarios")}
          >
            Scenario Comparison
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="contributions"
            class={tab_class(@active_tab == "contributions")}
          >
            Contribution Impact
          </button>
        </nav>
      </div>
      
    <!-- Content based on active tab -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Input Form -->
        <div class="lg:col-span-1">
          <div class="bg-white shadow rounded-lg p-6">
            <h2 class="text-lg font-medium text-gray-900 mb-4">Forecast Parameters</h2>

            <form id="forecast-form" phx-change="update_form">
              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Current Portfolio Value
                  </label>
                  <input
                    name="form[current_value]"
                    type="text"
                    value={@form_data["current_value"]}
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                    placeholder="100000"
                  />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Monthly Contribution ($)
                  </label>
                  <input
                    name="form[monthly_contribution]"
                    type="text"
                    value={@form_data["monthly_contribution"]}
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                    placeholder="1000"
                  />
                </div>

                <div :if={@active_tab in ["projection", "contributions"]}>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Annual Growth Rate
                  </label>
                  <select
                    name="form[growth_rate]"
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  >
                    <option value="0.05" selected={@form_data["growth_rate"] == "0.05"}>
                      5% (Conservative)
                    </option>
                    <option value="0.07" selected={@form_data["growth_rate"] == "0.07"}>
                      7% (Realistic)
                    </option>
                    <option value="0.10" selected={@form_data["growth_rate"] == "0.10"}>
                      10% (Optimistic)
                    </option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Time Horizon (Years)
                  </label>
                  <select
                    name="form[years]"
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  >
                    <option value="10" selected={@form_data["years"] == "10"}>10 Years</option>
                    <option value="20" selected={@form_data["years"] == "20"}>20 Years</option>
                    <option value="30" selected={@form_data["years"] == "30"}>30 Years</option>
                  </select>
                </div>
              </div>

              <div class="mt-6 space-y-3">
                <button
                  :if={@active_tab == "projection"}
                  type="button"
                  phx-click="calculate_projection"
                  disabled={@loading}
                  class="w-full btn-primary"
                >
                  {if @loading, do: "Calculating...", else: "Calculate Projection"}
                </button>

                <button
                  :if={@active_tab == "scenarios"}
                  type="button"
                  phx-click="calculate_scenarios"
                  disabled={@loading}
                  class="w-full btn-primary"
                >
                  {if @loading, do: "Calculating...", else: "Compare Scenarios"}
                </button>

                <button
                  :if={@active_tab == "contributions"}
                  type="button"
                  phx-click="analyze_contributions"
                  disabled={@loading}
                  class="w-full btn-primary"
                >
                  {if @loading, do: "Analyzing...", else: "Analyze Impact"}
                </button>
              </div>
            </form>
          </div>
        </div>
        
    <!-- Results Display -->
        <div class="lg:col-span-2">
          <%= if @active_tab == "projection" and @projection_results do %>
            {render_projection_results(assigns)}
          <% end %>

          <%= if @active_tab == "scenarios" do %>
            <%= if @scenario_results do %>
              {render_scenario_results(assigns)}
            <% else %>
              <div class="bg-white shadow rounded-lg p-6">
                <h3 class="text-lg font-medium text-gray-900 mb-4">Scenario Comparison</h3>
                <p class="text-gray-600 mb-4">
                  Compare your portfolio growth under different return scenarios:
                </p>
                <div class="space-y-3">
                  <div class="flex justify-between items-center p-3 bg-red-50 rounded-lg border border-red-200">
                    <span class="font-medium text-red-800">Conservative (5%)</span>
                    <span class="text-sm text-red-600">Lower risk, stable growth</span>
                  </div>
                  <div class="flex justify-between items-center p-3 bg-blue-50 rounded-lg border border-blue-200">
                    <span class="font-medium text-blue-800">Realistic (7%)</span>
                    <span class="text-sm text-blue-600">Market average returns</span>
                  </div>
                  <div class="flex justify-between items-center p-3 bg-green-50 rounded-lg border border-green-200">
                    <span class="font-medium text-green-800">Optimistic (10%)</span>
                    <span class="text-sm text-green-600">Higher risk, aggressive growth</span>
                  </div>
                </div>
                <p class="text-sm text-gray-500 mt-4">
                  Click "Compare Scenarios" to see projections for all three scenarios.
                </p>
              </div>
            <% end %>
          <% end %>

          <%= if @active_tab == "contributions" do %>
            <%= if @contribution_analysis do %>
              {render_contribution_analysis(assigns)}
            <% else %>
              <div class="bg-white shadow rounded-lg p-6">
                <h3 class="text-lg font-medium text-gray-900 mb-4">Contribution Analysis</h3>
                <p class="text-gray-600 mb-4">
                  Analyze how different contribution amounts affect your portfolio growth.
                </p>
                <p class="text-sm text-gray-500">
                  Click "Analyze Impact" to see how changing your monthly contributions affects your long-term results.
                </p>
              </div>
            <% end %>
          <% end %>

          <%= if Map.get(@chart_data, :type) do %>
            <div class="bg-white shadow rounded-lg p-6 mt-6">
              <h3 class="text-lg font-medium text-gray-900 mb-4">Projection Chart</h3>
              <ForecastChart.render
                id="forecast-chart"
                data={@chart_data.data}
                type={@chart_data.type}
                height={400}
                width={800}
                responsive={true}
                title={@chart_data.title}
              />
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Private helper functions

  defp get_current_portfolio_value do
    # For now, return a default value since we're focusing on the forecasting functionality
    # TODO: Integrate with actual portfolio calculation when available
    Decimal.new("100000")
  end

  defp parse_decimal(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, ""} -> {:ok, decimal}
      _ -> {:error, :invalid_decimal}
    end
  end

  defp parse_decimal(_), do: {:error, :invalid_input}

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> {:ok, int}
      _ -> {:error, :invalid_integer}
    end
  end

  defp parse_integer(_), do: {:error, :invalid_input}

  defp generate_chart_periods(max_years) when max_years <= 10, do: Enum.to_list(0..max_years)

  defp generate_chart_periods(max_years) when max_years <= 20, do: Enum.take_every(0..max_years, 2)

  defp generate_chart_periods(max_years), do: Enum.take_every(0..max_years, 5)

  defp build_projection_chart_data(multi_projections, periods) do
    years = periods

    values =
      Enum.map(periods, fn year ->
        period_key = String.to_atom("year_#{year}")

        case Map.get(multi_projections, period_key) do
          nil -> Decimal.new("0")
          value -> value
        end
      end)

    %{
      type: :single_projection,
      title: "Portfolio Growth Projection",
      data: %{
        years: years,
        values: values
      }
    }
  end

  defp build_scenario_chart_data(scenarios, years) do
    chart_years = Enum.take_every(0..years, max(1, div(years, 10)))

    # For simplicity, create linear projections between start and end values
    pessimistic_values =
      build_scenario_progression(scenarios.pessimistic.portfolio_value, years, chart_years)

    realistic_values =
      build_scenario_progression(scenarios.realistic.portfolio_value, years, chart_years)

    optimistic_values =
      build_scenario_progression(scenarios.optimistic.portfolio_value, years, chart_years)

    %{
      type: :scenario_comparison,
      title: "Scenario Comparison",
      data: %{
        years: Enum.to_list(chart_years),
        pessimistic: pessimistic_values,
        realistic: realistic_values,
        optimistic: optimistic_values
      }
    }
  end

  defp build_scenario_progression(final_value, total_years, chart_years) do
    # Simple linear progression for chart display
    Enum.map(chart_years, fn year ->
      if year == 0 do
        Decimal.new("0")
      else
        ratio = Decimal.div(Decimal.new(to_string(year)), Decimal.new(to_string(total_years)))
        Decimal.mult(final_value, ratio)
      end
    end)
  end

  defp handle_calculation_error(socket, reason) do
    error_message =
      case reason do
        :negative_current_value -> "Current portfolio value cannot be negative"
        :negative_contribution -> "Monthly contribution cannot be negative"
        :invalid_years -> "Please enter a valid number of years"
        :unrealistic_growth -> "Growth rate must be between -50% and 50%"
        _ -> "Calculation failed. Please check your inputs."
      end

    socket =
      socket
      |> assign(:loading, false)
      |> ErrorHelpers.put_error_flash(error_message)

    {:noreply, socket}
  end

  defp handle_validation_error(socket, reason) do
    error_message =
      case reason do
        :invalid_decimal -> "Please enter valid monetary amounts"
        :invalid_integer -> "Please enter valid whole numbers"
        _ -> "Please check your input values"
      end

    socket =
      socket
      |> assign(:loading, false)
      |> ErrorHelpers.put_error_flash(error_message)

    {:noreply, socket}
  end

  defp tab_class(true), do: "border-indigo-500 text-indigo-600 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm"

  defp tab_class(false),
    do:
      "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm"

  defp render_projection_results(assigns) do
    results = assigns.projection_results

    assigns = assign(assigns, :results, results)

    ~H"""
    <div class="bg-white shadow rounded-lg p-6">
      <h3 class="text-lg font-medium text-gray-900 mb-4">Projection Results</h3>

      <div class="grid grid-cols-2 gap-4 mb-6">
        <div class="text-center p-4 bg-blue-50 rounded-lg">
          <p class="text-sm text-gray-600">Final Portfolio Value</p>
          <p class="text-2xl font-bold text-blue-600">
            {FormatHelpers.format_currency(@results.final_value)}
          </p>
        </div>

        <div class="text-center p-4 bg-green-50 rounded-lg">
          <p class="text-sm text-gray-600">Total Growth</p>
          <p class="text-2xl font-bold text-green-600">
            {FormatHelpers.format_currency(
              Decimal.sub(@results.final_value, @results.parameters.current_value)
            )}
          </p>
        </div>
      </div>

      <div class="space-y-2 text-sm text-gray-600">
        <p><strong>Parameters:</strong></p>
        <p>
          • Monthly Contribution: {FormatHelpers.format_currency(
            @results.parameters.monthly_contribution
          )}
        </p>
        <p>
          • Annual Growth Rate: {FormatHelpers.format_percentage(@results.parameters.growth_rate)}
        </p>
        <p>• Time Horizon: {@results.parameters.years} years</p>
      </div>
    </div>
    """
  end

  defp render_scenario_results(assigns) do
    scenarios = assigns.scenario_results.scenarios

    assigns = assign(assigns, :scenarios, scenarios)

    ~H"""
    <div class="bg-white shadow rounded-lg p-6">
      <h3 class="text-lg font-medium text-gray-900 mb-4">Scenario Results</h3>

      <div class="space-y-4">
        <div class="flex justify-between items-center p-4 bg-red-50 rounded-lg">
          <div>
            <h4 class="font-medium text-red-800">Pessimistic (5%)</h4>
            <p class="text-red-600">
              {FormatHelpers.format_currency(@scenarios.pessimistic.portfolio_value)}
            </p>
          </div>
          <.icon name="hero-arrow-trending-down" class="w-8 h-8 text-red-500" />
        </div>

        <div class="flex justify-between items-center p-4 bg-blue-50 rounded-lg">
          <div>
            <h4 class="font-medium text-blue-800">Realistic (7%)</h4>
            <p class="text-blue-600">
              {FormatHelpers.format_currency(@scenarios.realistic.portfolio_value)}
            </p>
          </div>
          <.icon name="hero-arrow-trending-up" class="w-8 h-8 text-blue-500" />
        </div>

        <div class="flex justify-between items-center p-4 bg-green-50 rounded-lg">
          <div>
            <h4 class="font-medium text-green-800">Optimistic (10%)</h4>
            <p class="text-green-600">
              {FormatHelpers.format_currency(@scenarios.optimistic.portfolio_value)}
            </p>
          </div>
          <.icon name="hero-trending-up" class="w-8 h-8 text-green-500" />
        </div>

        <%= if @scenarios.weighted_average do %>
          <div class="flex justify-between items-center p-4 bg-purple-50 rounded-lg border-2 border-purple-200">
            <div>
              <h4 class="font-medium text-purple-800">Weighted Average</h4>
              <p class="text-purple-600">
                {FormatHelpers.format_currency(@scenarios.weighted_average.portfolio_value)}
              </p>
              <p class="text-xs text-purple-500 mt-1">
                20% Pessimistic, 60% Realistic, 20% Optimistic
              </p>
            </div>
            <.icon name="hero-chart-bar" class="w-8 h-8 text-purple-500" />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_contribution_analysis(assigns) do
    analysis = assigns.contribution_analysis.analysis

    assigns = assign(assigns, :analysis, analysis)

    ~H"""
    <div class="bg-white shadow rounded-lg p-6">
      <h3 class="text-lg font-medium text-gray-900 mb-4">Contribution Impact Analysis</h3>

      <div class="mb-6 text-center p-4 bg-gray-50 rounded-lg">
        <p class="text-sm text-gray-600">Base Projection</p>
        <p class="text-2xl font-bold text-gray-900">
          {FormatHelpers.format_currency(@analysis.base_projection)}
        </p>
      </div>

      <h4 class="font-medium text-gray-900 mb-3">Impact of Different Contribution Levels</h4>
      <div class="space-y-2">
        <%= for variation <- @analysis.contribution_variations do %>
          <div class="flex justify-between items-center p-3 bg-gray-50 rounded">
            <div>
              <span class="text-sm font-medium">
                {format_contribution_change(variation.monthly_change)}
              </span>
              <span class="text-xs text-gray-500 ml-2">
                ({format_contribution_change(variation.annual_change)} annually)
              </span>
            </div>
            <div class="text-right">
              <div class="text-sm font-medium">
                {FormatHelpers.format_currency(variation.portfolio_value)}
              </div>
              <div class={"text-xs #{if Decimal.compare(variation.value_difference, Decimal.new("0")) == :gt, do: "text-green-600", else: "text-red-600"}"}>
                {format_value_difference(variation.value_difference)}
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp format_contribution_change(%Decimal{} = change) do
    sign = if Decimal.compare(change, Decimal.new("0")) == :gt, do: "+", else: ""
    "#{sign}#{FormatHelpers.format_currency(change)}"
  end

  defp format_value_difference(%Decimal{} = diff) do
    sign = if Decimal.compare(diff, Decimal.new("0")) == :gt, do: "+", else: ""
    "#{sign}#{FormatHelpers.format_currency(diff)}"
  end
end
