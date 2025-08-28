defmodule AshfolioWeb.FinancialPlanningLive.Forecast do
  @moduledoc false
  use AshfolioWeb, :live_view

  alias Ashfolio.FinancialManagement.ContributionAnalyzer
  alias Ashfolio.FinancialManagement.FinancialGoal
  alias Ashfolio.FinancialManagement.ForecastCalculator
  alias AshfolioWeb.Components.ForecastChart
  alias AshfolioWeb.Live.ErrorHelpers
  alias AshfolioWeb.Live.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Ashfolio.PubSub.subscribe("financial_goals")
      Ashfolio.PubSub.subscribe("accounts")
    end

    socket =
      socket
      |> assign_current_page(:forecast)
      |> assign(:page_title, "Financial Forecasting")
      |> assign(:page_subtitle, "Plan your financial future with scenario analysis")
      |> assign(:loading, false)
      |> assign(:calculation_error, nil)
      |> assign(:show_advanced_settings, false)
      |> assign_default_form_values()
      |> assign_default_results()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("calculate_forecast", %{"forecast" => forecast_params}, socket) do
    socket = assign(socket, :loading, true)

    case build_forecast_request(forecast_params) do
      {:ok, request} ->
        socket =
          socket
          |> calculate_forecast(request)
          |> assign(:loading, false)

        {:noreply, socket}

      {:error, errors} ->
        socket =
          socket
          |> assign(:loading, false)
          |> assign(:calculation_error, format_validation_errors(errors))

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("switch_scenario", %{"scenario" => scenario}, socket) do
    scenario_atom = String.to_existing_atom(scenario)

    socket =
      socket
      |> assign(:active_scenario, scenario_atom)
      |> update_chart_data_for_scenario(scenario_atom)

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_advanced_settings", _params, socket) do
    {:noreply, assign(socket, :show_advanced_settings, !socket.assigns.show_advanced_settings)}
  end

  @impl true
  def handle_event("analyze_contribution", %{"contribution" => contribution_params}, socket) do
    socket = assign(socket, :loading, true)

    case build_contribution_request(contribution_params) do
      {:ok, request} ->
        socket =
          socket
          |> analyze_contribution_impact(request)
          |> assign(:loading, false)

        {:noreply, socket}

      {:error, errors} ->
        socket =
          socket
          |> assign(:loading, false)
          |> assign(:calculation_error, format_validation_errors(errors))

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("optimize_for_goal", %{"goal_id" => goal_id}, socket) do
    socket = assign(socket, :loading, true)

    case FinancialGoal.get_by_id(goal_id) do
      {:ok, goal} ->
        current_portfolio_value = get_current_portfolio_value()
        monthly_contribution = socket.assigns.form_data.monthly_contribution || Decimal.new("500")
        years_to_fi = socket.assigns.form_data.years_to_fi || 25

        case ContributionAnalyzer.optimize_contribution_for_goal(
               current_portfolio_value,
               goal.target_amount,
               years_to_fi,
               monthly_contribution
             ) do
          {:ok, optimization} ->
            socket =
              socket
              |> assign(:loading, false)
              |> assign(:optimization_result, optimization)
              |> ErrorHelpers.put_success_flash("Optimized contribution strategy for #{goal.name}")

            {:noreply, socket}

          {:error, reason} ->
            socket =
              socket
              |> assign(:loading, false)
              |> assign(:calculation_error, "Failed to optimize for goal: #{reason}")

            {:noreply, socket}
        end

      {:error, _} ->
        socket =
          socket
          |> assign(:loading, false)
          |> assign(:calculation_error, "Goal not found")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("clear_results", _params, socket) do
    {:noreply, assign_default_results(socket)}
  end

  @impl true
  def handle_event("export_forecast", %{"format" => format}, socket) do
    case export_forecast_data(socket.assigns.forecast_result, format) do
      {:error, reason} ->
        socket = assign(socket, :calculation_error, "Export failed: #{reason}")
        {:noreply, socket}
    end
  end

  # PubSub handlers
  @impl true
  def handle_info({:financial_goal_saved, _goal}, socket) do
    {:noreply, reload_goals(socket)}
  end

  @impl true
  def handle_info({:financial_goal_deleted, _goal_id}, socket) do
    {:noreply, reload_goals(socket)}
  end

  @impl true
  def handle_info({:account_updated, _account}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Page Header -->
      <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Financial Forecasting</h1>
          <p class="text-gray-600">Plan your financial future with scenario analysis</p>
        </div>
        <div class="flex gap-3">
          <button
            type="button"
            phx-click="clear_results"
            class="btn-secondary inline-flex items-center"
            disabled={is_nil(@forecast_result)}
          >
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
            Clear Results
          </button>
          <%= if @forecast_result do %>
            <button
              type="button"
              phx-click="export_forecast"
              phx-value-format="csv"
              class="btn-primary inline-flex items-center"
            >
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
              </svg>
              Export
            </button>
          <% end %>
        </div>
      </div>
      
    <!-- Error Message -->
      <%= if @calculation_error do %>
        <div class="bg-red-50 border border-red-200 rounded-lg p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-red-800">Calculation Error</h3>
              <p class="mt-1 text-sm text-red-700">{@calculation_error}</p>
            </div>
          </div>
        </div>
      <% end %>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Forecast Parameters Form -->
        <div class="lg:col-span-1">
          <.card>
            <:header>
              <h2 class="text-lg font-medium text-gray-900">Forecast Parameters</h2>
            </:header>

            <form phx-submit="calculate_forecast" class="space-y-4">
              <!-- Basic Parameters -->
              <div>
                <label
                  for="current_portfolio_value"
                  class="block text-sm font-medium leading-6 text-zinc-800"
                >
                  Current Portfolio Value
                </label>
                <div class="mt-2">
                  <.input
                    type="text"
                    name="forecast[current_portfolio_value]"
                    id="current_portfolio_value"
                    value={@form_data.current_portfolio_value}
                    placeholder="50000"
                    class="block w-full"
                  />
                </div>
              </div>

              <div>
                <label
                  for="monthly_contribution"
                  class="block text-sm font-medium leading-6 text-zinc-800"
                >
                  Monthly Contribution
                </label>
                <div class="mt-2">
                  <.input
                    type="text"
                    name="forecast[monthly_contribution]"
                    id="monthly_contribution"
                    value={@form_data.monthly_contribution}
                    placeholder="1000"
                    class="block w-full"
                  />
                </div>
              </div>

              <div>
                <label for="annual_return" class="block text-sm font-medium leading-6 text-zinc-800">
                  Expected Annual Return (%)
                </label>
                <div class="mt-2">
                  <.input
                    type="text"
                    name="forecast[annual_return]"
                    id="annual_return"
                    value={@form_data.annual_return}
                    placeholder="7.0"
                    class="block w-full"
                  />
                </div>
              </div>

              <div>
                <label for="years_to_fi" class="block text-sm font-medium leading-6 text-zinc-800">
                  Years to Financial Independence
                </label>
                <div class="mt-2">
                  <.input
                    type="text"
                    name="forecast[years_to_fi]"
                    id="years_to_fi"
                    value={@form_data.years_to_fi}
                    placeholder="25"
                    class="block w-full"
                  />
                </div>
              </div>
              
    <!-- Advanced Settings Toggle -->
              <div class="pt-2">
                <button
                  type="button"
                  phx-click="toggle_advanced_settings"
                  class="inline-flex items-center text-sm text-blue-600 hover:text-blue-800"
                >
                  <%= if @show_advanced_settings do %>
                    <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M5 15l7-7 7 7"
                      />
                    </svg>
                    Hide Advanced Settings
                  <% else %>
                    <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M19 9l-7 7-7-7"
                      />
                    </svg>
                    Show Advanced Settings
                  <% end %>
                </button>
              </div>
              
    <!-- Advanced Parameters -->
              <%= if @show_advanced_settings do %>
                <div class="space-y-4 border-t border-gray-200 pt-4">
                  <div>
                    <label
                      for="withdrawal_rate"
                      class="block text-sm font-medium leading-6 text-zinc-800"
                    >
                      Safe Withdrawal Rate (%)
                    </label>
                    <div class="mt-2">
                      <.input
                        type="text"
                        name="forecast[withdrawal_rate]"
                        id="withdrawal_rate"
                        value={@form_data.withdrawal_rate}
                        placeholder="4.0"
                        class="block w-full"
                      />
                    </div>
                  </div>

                  <div>
                    <label
                      for="inflation_rate"
                      class="block text-sm font-medium leading-6 text-zinc-800"
                    >
                      Annual Inflation Rate (%)
                    </label>
                    <div class="mt-2">
                      <.input
                        type="text"
                        name="forecast[inflation_rate]"
                        id="inflation_rate"
                        value={@form_data.inflation_rate}
                        placeholder="2.5"
                        class="block w-full"
                      />
                    </div>
                  </div>

                  <div>
                    <label for="tax_rate" class="block text-sm font-medium leading-6 text-zinc-800">
                      Tax Rate (%)
                    </label>
                    <div class="mt-2">
                      <.input
                        type="text"
                        name="forecast[tax_rate]"
                        id="tax_rate"
                        value={@form_data.tax_rate}
                        placeholder="22.0"
                        class="block w-full"
                      />
                    </div>
                  </div>
                </div>
              <% end %>

              <div class="pt-4">
                <button
                  type="submit"
                  class="btn-primary w-full flex items-center justify-center"
                  disabled={@loading}
                >
                  <%= if @loading do %>
                    <.loading_spinner class="w-4 h-4 mr-2" /> Calculating...
                  <% else %>
                    <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                      />
                    </svg>
                    Calculate Forecast
                  <% end %>
                </button>
              </div>
            </form>
          </.card>
          
    <!-- Goal Integration -->
          <%= if @available_goals && length(@available_goals) > 0 do %>
            <.card class="mt-6">
              <:header>
                <h3 class="text-lg font-medium text-gray-900">Goal Integration</h3>
              </:header>

              <div class="space-y-3">
                <p class="text-sm text-gray-600">
                  Optimize your contribution strategy for specific financial goals.
                </p>
                <%= for goal <- @available_goals do %>
                  <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                    <div>
                      <div class="text-sm font-medium text-gray-900">{goal.name}</div>
                      <div class="text-xs text-gray-500">
                        Target: {FormatHelpers.format_currency(goal.target_amount)}
                      </div>
                    </div>
                    <button
                      type="button"
                      phx-click="optimize_for_goal"
                      phx-value-goal_id={goal.id}
                      class="btn-secondary text-xs px-2 py-1"
                      disabled={@loading}
                    >
                      Optimize
                    </button>
                  </div>
                <% end %>
              </div>
            </.card>
          <% end %>
        </div>
        
    <!-- Results Section -->
        <div class="lg:col-span-2">
          <%= if @forecast_result do %>
            <!-- Chart Section -->
            <.card>
              <:header>
                <h2 class="text-lg font-medium text-gray-900">Projection Chart</h2>
              </:header>
              <:actions>
                <%= if @scenarios && length(@scenarios) > 1 do %>
                  <select
                    phx-change="switch_scenario"
                    name="scenario"
                    class="text-sm border-gray-300 rounded-md"
                  >
                    <%= for scenario <- @scenarios do %>
                      <option
                        value={scenario}
                        selected={scenario == @active_scenario}
                      >
                        {scenario_label(scenario)}
                      </option>
                    <% end %>
                  </select>
                <% end %>
              </:actions>

              <div class="mt-4">
                <ForecastChart.render
                  id="forecast-chart"
                  data={@chart_data}
                  type={@chart_type}
                  height={400}
                  responsive={true}
                />
              </div>
            </.card>
            
    <!-- Key Metrics -->
            <.card class="mt-6">
              <:header>
                <h3 class="text-lg font-medium text-gray-900">Key Metrics</h3>
              </:header>

              <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div class="text-center p-4 bg-blue-50 rounded-lg">
                  <div class="text-2xl font-bold text-blue-600">
                    {FormatHelpers.format_currency(@forecast_result.fi_amount)}
                  </div>
                  <div class="text-sm text-blue-800">FI Target Amount</div>
                </div>

                <div class="text-center p-4 bg-green-50 rounded-lg">
                  <div class="text-2xl font-bold text-green-600">
                    {format_years(@forecast_result.years_to_fi)}
                  </div>
                  <div class="text-sm text-green-800">Years to FI</div>
                </div>

                <div class="text-center p-4 bg-purple-50 rounded-lg">
                  <div class="text-2xl font-bold text-purple-600">
                    {FormatHelpers.format_currency(@forecast_result.monthly_fi_income)}
                  </div>
                  <div class="text-sm text-purple-800">Monthly FI Income</div>
                </div>
              </div>
            </.card>
            
    <!-- Detailed Analysis -->
            <%= if @forecast_result.analysis do %>
              <.card class="mt-6">
                <:header>
                  <h3 class="text-lg font-medium text-gray-900">Analysis & Recommendations</h3>
                </:header>

                <div class="space-y-4">
                  <%= for insight <- @forecast_result.analysis.insights do %>
                    <div class="flex items-start space-x-3">
                      <div class="flex-shrink-0">
                        <div class="w-2 h-2 bg-blue-400 rounded-full mt-2"></div>
                      </div>
                      <p class="text-sm text-gray-700">{insight}</p>
                    </div>
                  <% end %>
                </div>

                <%= if @forecast_result.analysis.recommendations do %>
                  <div class="mt-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                    <h4 class="text-sm font-medium text-yellow-800 mb-2">Recommendations</h4>
                    <ul class="space-y-1">
                      <%= for rec <- @forecast_result.analysis.recommendations do %>
                        <li class="text-sm text-yellow-700">• {rec}</li>
                      <% end %>
                    </ul>
                  </div>
                <% end %>
              </.card>
            <% end %>
            
    <!-- Optimization Results -->
            <%= if @optimization_result do %>
              <.card class="mt-6">
                <:header>
                  <h3 class="text-lg font-medium text-gray-900">Optimization Results</h3>
                </:header>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div class="p-4 bg-green-50 rounded-lg">
                    <div class="text-lg font-bold text-green-600">
                      {FormatHelpers.format_currency(
                        @optimization_result.optimal_monthly_contribution
                      )}
                    </div>
                    <div class="text-sm text-green-800">Optimal Monthly Contribution</div>
                  </div>

                  <div class="p-4 bg-blue-50 rounded-lg">
                    <div class="text-lg font-bold text-blue-600">
                      {format_years(@optimization_result.time_to_goal)}
                    </div>
                    <div class="text-sm text-blue-800">Time to Reach Goal</div>
                  </div>
                </div>

                <%= if @optimization_result.analysis && @optimization_result.analysis.recommendation do %>
                  <div class="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
                    <p class="text-sm text-blue-800">
                      {@optimization_result.analysis.recommendation}
                    </p>
                  </div>
                <% end %>
              </.card>
            <% end %>
          <% else %>
            <!-- Empty State -->
            <.card class="h-96 flex items-center justify-center">
              <div class="text-center">
                <div class="mx-auto h-16 w-16 text-gray-400 mb-4">
                  <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-full h-full">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="1.5"
                      d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                    />
                  </svg>
                </div>
                <h3 class="text-lg font-medium text-gray-900 mb-2">Ready to Forecast</h3>
                <p class="text-gray-600 mb-4 max-w-sm mx-auto">
                  Enter your financial parameters on the left to generate a comprehensive forecast of your journey to financial independence.
                </p>
              </div>
            </.card>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Private helper functions

  defp apply_action(socket, :index, _params) do
    reload_goals(socket)
  end

  defp assign_default_form_values(socket) do
    current_portfolio_value = get_current_portfolio_value()

    assign(socket, :form_data, %{
      current_portfolio_value: Decimal.to_string(current_portfolio_value),
      monthly_contribution: "1000",
      annual_return: "7.0",
      years_to_fi: "25",
      withdrawal_rate: "4.0",
      inflation_rate: "2.5",
      tax_rate: "22.0"
    })
  end

  defp assign_default_results(socket) do
    socket
    |> assign(:forecast_result, nil)
    |> assign(:chart_data, nil)
    |> assign(:chart_type, :single_projection)
    |> assign(:scenarios, [:conservative, :moderate, :aggressive])
    |> assign(:active_scenario, :moderate)
    |> assign(:optimization_result, nil)
  end

  defp build_forecast_request(params) do
    with {:ok, current_value} <- parse_decimal(params["current_portfolio_value"]),
         {:ok, monthly_contrib} <- parse_decimal(params["monthly_contribution"]),
         {:ok, annual_return} <- parse_percentage(params["annual_return"]),
         {:ok, years} <- parse_integer(params["years_to_fi"]),
         {:ok, withdrawal_rate} <- parse_percentage(params["withdrawal_rate"] || "4.0"),
         {:ok, inflation_rate} <- parse_percentage(params["inflation_rate"] || "2.5"),
         {:ok, tax_rate} <- parse_percentage(params["tax_rate"] || "22.0") do
      request = %{
        current_portfolio_value: current_value,
        monthly_contribution: monthly_contrib,
        annual_return: annual_return,
        years_to_fi: years,
        withdrawal_rate: withdrawal_rate,
        inflation_rate: inflation_rate,
        tax_rate: tax_rate
      }

      {:ok, request}
    else
      {:error, field, message} ->
        {:error, %{field => [message]}}
    end
  end

  defp build_contribution_request(params) do
    with {:ok, current_contrib} <- parse_decimal(params["current_contribution"]),
         {:ok, target_contrib} <- parse_decimal(params["target_contribution"]),
         {:ok, years} <- parse_integer(params["years"]) do
      request = %{
        current_contribution: current_contrib,
        target_contribution: target_contrib,
        years: years
      }

      {:ok, request}
    else
      {:error, field, message} ->
        {:error, %{field => [message]}}
    end
  end

  defp calculate_forecast(socket, request) do
    case ForecastCalculator.calculate_fi_timeline(
           request.current_portfolio_value,
           request.monthly_contribution,
           request.annual_expenses || Decimal.new("50000"),
           request.annual_return
         ) do
      {:ok, result} ->
        chart_data = build_chart_data(result)

        socket
        |> assign(:forecast_result, result)
        |> assign(:chart_data, chart_data)
        |> assign(:calculation_error, nil)

      {:error, reason} ->
        assign(socket, :calculation_error, "Calculation failed: #{reason}")
    end
  end

  defp analyze_contribution_impact(socket, request) do
    current_portfolio_value = get_current_portfolio_value()

    case ContributionAnalyzer.analyze_contribution_impact(
           current_portfolio_value,
           request.current_contribution,
           request.target_contribution,
           request.years
         ) do
      {:ok, analysis} ->
        socket
        |> assign(:contribution_analysis, analysis)
        |> assign(:calculation_error, nil)

      {:error, reason} ->
        assign(socket, :calculation_error, "Contribution analysis failed: #{reason}")
    end
  end

  defp build_chart_data(forecast_result) do
    # Transform forecast result into chart-compatible data structure
    years = Enum.to_list(0..forecast_result.years_to_fi)

    data_points =
      Enum.map(years, fn year ->
        portfolio_value = calculate_portfolio_value_at_year(forecast_result, year)

        %{
          year: year,
          portfolio_value: portfolio_value,
          contributions: Decimal.mult(forecast_result.monthly_contribution, Decimal.new(12 * year)),
          fi_target: forecast_result.fi_amount
        }
      end)

    %{
      data_points: data_points,
      labels: %{
        x_axis: "Years",
        y_axis: "Portfolio Value ($)",
        title: "Financial Independence Projection"
      }
    }
  end

  defp calculate_portfolio_value_at_year(forecast_result, year) do
    # Compound growth calculation
    annual_contribution = Decimal.mult(forecast_result.monthly_contribution, Decimal.new(12))
    growth_rate = Decimal.div(forecast_result.annual_return, Decimal.new(100))

    # Future value of current investment
    current_future_value =
      Decimal.mult(
        forecast_result.current_portfolio_value,
        pow_decimal(Decimal.add(Decimal.new(1), growth_rate), year)
      )

    # Future value of contributions (annuity)
    if year == 0 do
      forecast_result.current_portfolio_value
    else
      contribution_future_value =
        Decimal.mult(
          annual_contribution,
          Decimal.div(
            Decimal.sub(
              pow_decimal(Decimal.add(Decimal.new(1), growth_rate), year),
              Decimal.new(1)
            ),
            growth_rate
          )
        )

      Decimal.add(current_future_value, contribution_future_value)
    end
  end

  defp update_chart_data_for_scenario(socket, _scenario) do
    # This would modify chart data based on different scenarios (conservative, moderate, aggressive)
    # For now, we'll keep it simple and just change the active scenario
    socket
  end

  defp reload_goals(socket) do
    require Ash.Query

    goals =
      FinancialGoal
      |> Ash.Query.for_read(:read)
      |> Ash.Query.filter(is_active == true)
      |> Ash.read!()

    assign(socket, :available_goals, goals)
  rescue
    _error ->
      assign(socket, :available_goals, [])
  end

  defp get_current_portfolio_value do
    # This would get the current portfolio value from the dashboard
    # For now, return a default value
    Decimal.new("50000")
  end

  defp export_forecast_data(_forecast_result, _format) do
    # This would implement export functionality
    {:error, "Export functionality not yet implemented"}
  end

  defp parse_decimal(nil), do: {:error, :value, "is required"}
  defp parse_decimal(""), do: {:error, :value, "is required"}

  defp parse_decimal(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, ""} ->
        if Decimal.negative?(decimal) do
          {:error, :value, "must be positive"}
        else
          {:ok, decimal}
        end

      _ ->
        {:error, :value, "must be a valid number"}
    end
  end

  defp parse_percentage(value) when is_binary(value) do
    case parse_decimal(value) do
      {:ok, decimal} ->
        if Decimal.compare(decimal, Decimal.new(0)) == :lt or
             Decimal.compare(decimal, Decimal.new(100)) == :gt do
          {:error, :value, "must be between 0 and 100"}
        else
          {:ok, decimal}
        end

      error ->
        error
    end
  end

  defp parse_integer(nil), do: {:error, :value, "is required"}
  defp parse_integer(""), do: {:error, :value, "is required"}

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} ->
        if int > 0 do
          {:ok, int}
        else
          {:error, :value, "must be positive"}
        end

      _ ->
        {:error, :value, "must be a valid integer"}
    end
  end

  defp format_validation_errors(errors) do
    Enum.map_join(errors, "; ", fn {field, messages} ->
      "#{field}: #{Enum.join(messages, ", ")}"
    end)
  end

  defp format_years(decimal_years) do
    years = Decimal.to_integer(Decimal.round(decimal_years, 0))

    if years == 1 do
      "1 year"
    else
      "#{years} years"
    end
  end

  defp scenario_label(:conservative), do: "Conservative"
  defp scenario_label(:moderate), do: "Moderate"
  defp scenario_label(:aggressive), do: "Aggressive"

  defp pow_decimal(base, power) do
    base_float = Decimal.to_float(base)
    result_float = :math.pow(base_float, power)
    Decimal.from_float(result_float)
  end
end
