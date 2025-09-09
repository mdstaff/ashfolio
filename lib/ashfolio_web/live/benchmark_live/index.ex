defmodule AshfolioWeb.BenchmarkLive.Index do
  @moduledoc """
  LiveView for portfolio benchmark analysis and comparison.

  Provides interactive interface for comparing portfolio performance against
  market benchmarks including S&P 500, total market, and international indices.
  Features real-time analysis with professional portfolio management insights.
  """

  use AshfolioWeb, :live_view

  alias Ashfolio.Financial.BenchmarkAnalyzer
  alias Ashfolio.Portfolio.Calculator
  alias AshfolioWeb.Live.ErrorHelpers

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Portfolio Benchmark Analysis")
      |> assign(:loading, false)
      |> assign(:errors, [])
      |> assign(:benchmark_data, nil)
      |> assign(:comparison_results, nil)
      |> assign(:selected_benchmark, :sp500)
      |> assign(:analysis_period, 365)
      |> assign(:portfolio_start_value, "")
      |> assign(:portfolio_end_value, "")
      |> load_portfolio_data()

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Page Header -->
      <div class="bg-white shadow">
        <div class="px-6 py-4">
          <div class="sm:flex sm:items-center">
            <div class="sm:flex-auto">
              <h1 class="text-2xl font-semibold text-gray-900">Portfolio Benchmark Analysis</h1>
              <p class="mt-2 text-sm text-gray-700">
                Compare your portfolio performance against market benchmarks and analyze relative returns.
              </p>
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <!-- Analysis Form -->
        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
              Benchmark Comparison Setup
            </h3>

            <.form
              for={%{}}
              as={:benchmark_form}
              phx-change="update_form"
              phx-submit="run_analysis"
              class="space-y-4"
            >
              <!-- Benchmark Selection -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Benchmark Index
                </label>
                <select
                  name="benchmark"
                  value={@selected_benchmark}
                  class="mt-1 block w-full rounded-md border-gray-300 py-2 pl-3 pr-10 text-base focus:border-blue-500 focus:outline-none focus:ring-blue-500 sm:text-sm"
                >
                  <option value="sp500">S&P 500 (SPY)</option>
                  <option value="total_market">Total Stock Market (VTI)</option>
                  <option value="international">International Markets (VTIAX)</option>
                </select>
              </div>
              
    <!-- Analysis Period -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Analysis Period
                </label>
                <select
                  name="period"
                  value={@analysis_period}
                  class="mt-1 block w-full rounded-md border-gray-300 py-2 pl-3 pr-10 text-base focus:border-blue-500 focus:outline-none focus:ring-blue-500 sm:text-sm"
                >
                  <option value="90">3 Months</option>
                  <option value="180">6 Months</option>
                  <option value="365">1 Year</option>
                  <option value="730">2 Years</option>
                  <option value="1095">3 Years</option>
                </select>
              </div>
              
    <!-- Portfolio Values -->
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Portfolio Start Value
                  </label>
                  <input
                    type="text"
                    name="start_value"
                    value={@portfolio_start_value}
                    placeholder="e.g., 100,000"
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Portfolio End Value
                  </label>
                  <input
                    type="text"
                    name="end_value"
                    value={@portfolio_end_value}
                    placeholder="e.g., 110,000"
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                  />
                </div>
              </div>
              
    <!-- Auto-populate from current portfolio -->
              <div class="pt-2">
                <button
                  type="button"
                  phx-click="use_current_portfolio"
                  class="text-sm text-blue-600 hover:text-blue-500"
                >
                  📊 Use Current Portfolio Values
                </button>
              </div>
              
    <!-- Submit Button -->
              <div class="pt-4">
                <button
                  type="submit"
                  disabled={@loading}
                  class={[
                    "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white",
                    if(@loading,
                      do: "bg-gray-400 cursor-not-allowed",
                      else:
                        "bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    )
                  ]}
                >
                  <%= if @loading do %>
                    <svg
                      class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                    >
                      <circle
                        class="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        stroke-width="4"
                      >
                      </circle>
                      <path
                        class="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      >
                      </path>
                    </svg>
                    Analyzing...
                  <% else %>
                    🎯 Run Benchmark Analysis
                  <% end %>
                </button>
              </div>
            </.form>
            
    <!-- Error Display -->
            <div :if={@errors != []} class="mt-4">
              <ErrorHelpers.error_list
                errors={@errors}
                title="Analysis Failed"
              />
            </div>
          </div>
        </div>
        
    <!-- Current Portfolio Summary -->
        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Current Portfolio</h3>

            <div :if={@portfolio_summary} class="space-y-3">
              <div class="flex justify-between">
                <span class="text-sm font-medium text-gray-500">Total Value:</span>
                <span class="text-sm text-gray-900 font-semibold">
                  {Ashfolio.Financial.Formatters.format_currency(@portfolio_summary.total_value)}
                </span>
              </div>

              <div class="flex justify-between">
                <span class="text-sm font-medium text-gray-500">Total Cost Basis:</span>
                <span class="text-sm text-gray-900">
                  {Ashfolio.Financial.Formatters.format_currency(@portfolio_summary.total_cost_basis)}
                </span>
              </div>

              <div class="flex justify-between">
                <span class="text-sm font-medium text-gray-500">Unrealized Gain/Loss:</span>
                <span class={[
                  "text-sm font-medium",
                  if(Decimal.compare(@portfolio_summary.total_gain_loss, Decimal.new("0")) == :lt,
                    do: "text-red-600",
                    else: "text-green-600"
                  )
                ]}>
                  {Ashfolio.Financial.Formatters.format_currency(@portfolio_summary.total_gain_loss)} ({Ashfolio.Financial.Formatters.format_percentage(
                    @portfolio_summary.percentage_gain_loss
                  )})
                </span>
              </div>

              <div class="pt-2 text-xs text-gray-500">
                Use these values for benchmark comparison, or enter custom values above.
              </div>
            </div>

            <div :if={!@portfolio_summary} class="text-sm text-gray-500">
              <p>No portfolio data available. Please add some holdings first.</p>
              <.link navigate={~p"/"} class="text-blue-600 hover:text-blue-500">
                → Go to Dashboard
              </.link>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Analysis Results -->
      <div :if={@comparison_results} class="bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900 mb-6">Benchmark Analysis Results</h3>

          <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
            <!-- Portfolio Return -->
            <div class="bg-gray-50 rounded-lg p-4">
              <dt class="text-sm font-medium text-gray-500">Portfolio Return</dt>
              <dd class={[
                "mt-1 text-3xl font-semibold",
                if(Decimal.compare(@comparison_results.portfolio_return, Decimal.new("0")) == :lt,
                  do: "text-red-900",
                  else: "text-gray-900"
                )
              ]}>
                {Ashfolio.Financial.Formatters.format_percentage(@comparison_results.portfolio_return)}
              </dd>
            </div>
            
    <!-- Benchmark Return -->
            <div class="bg-gray-50 rounded-lg p-4">
              <dt class="text-sm font-medium text-gray-500">
                {benchmark_name(@comparison_results.benchmark_symbol)} Return
              </dt>
              <dd class="mt-1 text-3xl font-semibold text-gray-900">
                {Ashfolio.Financial.Formatters.format_percentage(@comparison_results.benchmark_return)}
              </dd>
            </div>
            
    <!-- Alpha (Outperformance) -->
            <div class="bg-gray-50 rounded-lg p-4">
              <dt class="text-sm font-medium text-gray-500">Alpha (Outperformance)</dt>
              <dd class={[
                "mt-1 text-3xl font-semibold",
                if(@comparison_results.outperformed,
                  do: "text-green-600",
                  else: "text-red-600"
                )
              ]}>
                {if @comparison_results.outperformed, do: "+", else: ""}{@comparison_results.alpha}%
              </dd>
            </div>
            
    <!-- Performance Badge -->
            <div class="bg-gray-50 rounded-lg p-4">
              <dt class="text-sm font-medium text-gray-500">Performance</dt>
              <dd class="mt-1">
                <span class={[
                  "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                  if(@comparison_results.outperformed,
                    do: "bg-green-100 text-green-800",
                    else: "bg-red-100 text-red-800"
                  )
                ]}>
                  {if @comparison_results.outperformed, do: "✓ Outperformed", else: "✗ Underperformed"}
                </span>
                <div class="mt-2 text-xs text-gray-500">
                  vs {benchmark_name(@comparison_results.benchmark_symbol)}
                </div>
              </dd>
            </div>
          </div>
          
    <!-- Detailed Analysis -->
          <div class="mt-8 border-t border-gray-200 pt-6">
            <h4 class="text-md font-medium text-gray-900 mb-4">Analysis Summary</h4>
            <div class="prose prose-sm text-gray-700">
              <p>
                Over the {period_description(@comparison_results.period_days)} analysis period,
                your portfolio generated a return of
                <strong>
                  {Ashfolio.Financial.Formatters.format_percentage(
                    @comparison_results.portfolio_return
                  )}
                </strong>
                compared to {benchmark_name(@comparison_results.benchmark_symbol)}'s return of <strong><%= Ashfolio.Financial.Formatters.format_percentage(@comparison_results.benchmark_return) %></strong>.
              </p>

              <p>
                <%= if @comparison_results.outperformed do %>
                  🎉 <strong>Congratulations!</strong>
                  Your portfolio outperformed the benchmark by <strong><%= @comparison_results.alpha %>%</strong>, demonstrating strong investment selection
                  and portfolio management.
                <% else %>
                  📊 Your portfolio underperformed the benchmark by <strong><%= abs(Decimal.to_integer(@comparison_results.alpha)) %>%</strong>.
                  Consider reviewing your asset allocation and investment strategy to improve performance.
                <% end %>
              </p>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Benchmark Data -->
      <div :if={@benchmark_data} class="bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
            {benchmark_name(@benchmark_data.symbol)} Information
          </h3>

          <dl class="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
            <div>
              <dt class="text-sm font-medium text-gray-500">Symbol</dt>
              <dd class="mt-1 text-sm text-gray-900 font-mono">{@benchmark_data.symbol}</dd>
            </div>

            <div>
              <dt class="text-sm font-medium text-gray-500">Current Price</dt>
              <dd class="mt-1 text-sm text-gray-900">
                {Ashfolio.Financial.Formatters.format_currency(@benchmark_data.current_price)}
              </dd>
            </div>

            <div>
              <dt class="text-sm font-medium text-gray-500">Period Return</dt>
              <dd class="mt-1 text-sm text-gray-900">
                {Ashfolio.Financial.Formatters.format_percentage(@benchmark_data.period_return)}
              </dd>
            </div>

            <div>
              <dt class="text-sm font-medium text-gray-500">Last Updated</dt>
              <dd class="mt-1 text-sm text-gray-500">
                {Calendar.strftime(@benchmark_data.last_updated, "%B %d, %Y at %I:%M %p UTC")}
              </dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  @impl true
  def handle_event("update_form", params, socket) do
    socket =
      socket
      |> assign(:selected_benchmark, String.to_atom(params["benchmark"] || "sp500"))
      |> assign(:analysis_period, String.to_integer(params["period"] || "365"))
      |> assign(:portfolio_start_value, params["start_value"] || "")
      |> assign(:portfolio_end_value, params["end_value"] || "")

    {:noreply, socket}
  end

  @impl true
  def handle_event("use_current_portfolio", _params, socket) do
    case socket.assigns.portfolio_summary do
      nil ->
        socket = put_flash(socket, :error, "No portfolio data available")
        {:noreply, socket}

      portfolio ->
        # Use cost basis as start value and current value as end value
        socket =
          socket
          |> assign(:portfolio_start_value, Decimal.to_string(portfolio.total_cost_basis))
          |> assign(:portfolio_end_value, Decimal.to_string(portfolio.total_value))
          |> put_flash(:info, "Portfolio values updated from current holdings")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("run_analysis", params, socket) do
    socket = assign(socket, :loading, true)

    case parse_analysis_params(params) do
      {:ok, parsed_params} ->
        run_benchmark_analysis(socket, parsed_params)

      {:error, errors} ->
        socket =
          socket
          |> assign(:loading, false)
          |> assign(:errors, errors)
          |> assign(:comparison_results, nil)

        {:noreply, socket}
    end
  end

  # Private Helper Functions

  defp load_portfolio_data(socket) do
    case Calculator.calculate_portfolio_value() do
      {:ok, portfolio_value} ->
        assign(socket, :portfolio_summary, %{total_value: portfolio_value})

      {:error, _reason} ->
        assign(socket, :portfolio_summary, nil)
    end
  end

  defp parse_analysis_params(params) do
    errors = []

    # Parse start value
    {start_value, errors} = parse_currency_field(params["start_value"], "Start value", errors)

    # Parse end value
    {end_value, errors} = parse_currency_field(params["end_value"], "End value", errors)

    # Parse benchmark and period
    benchmark = String.to_atom(params["benchmark"] || "sp500")
    period = String.to_integer(params["period"] || "365")

    case errors do
      [] ->
        {:ok,
         %{
           start_value: start_value,
           end_value: end_value,
           benchmark: benchmark,
           period: period
         }}

      errors ->
        {:error, errors}
    end
  end

  defp parse_currency_field(value_str, field_name, errors) do
    case AshfolioWeb.FormHelpers.parse_decimal(value_str || "") do
      {:ok, nil} ->
        {nil, ["#{field_name} is required" | errors]}

      {:ok, decimal} ->
        if Decimal.compare(decimal, Decimal.new("0")) == :gt do
          {decimal, errors}
        else
          {nil, ["#{field_name} must be positive" | errors]}
        end

      {:error, _} ->
        {nil, ["#{field_name} must be a valid number" | errors]}
    end
  end

  defp run_benchmark_analysis(socket, params) do
    # Run benchmark analysis in a task to avoid blocking the UI
    task_pid = self()

    Task.start(fn ->
      result =
        BenchmarkAnalyzer.analyze_vs_benchmark(
          params.start_value,
          params.end_value,
          params.period,
          params.benchmark
        )

      # Also get benchmark data for display
      benchmark_result = BenchmarkAnalyzer.get_benchmark_data(params.benchmark, params.period)

      send(task_pid, {:analysis_complete, result, benchmark_result})
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:analysis_complete, analysis_result, benchmark_result}, socket) do
    case {analysis_result, benchmark_result} do
      {{:ok, comparison}, {:ok, benchmark_data}} ->
        socket =
          socket
          |> assign(:loading, false)
          |> assign(:errors, [])
          |> assign(:comparison_results, comparison)
          |> assign(:benchmark_data, benchmark_data)
          |> put_flash(:info, "Benchmark analysis completed successfully")

        {:noreply, socket}

      {{:error, reason}, _} ->
        socket =
          socket
          |> assign(:loading, false)
          |> assign(:errors, ["Analysis failed: #{format_error(reason)}"])
          |> assign(:comparison_results, nil)

        {:noreply, socket}

      {_, {:error, reason}} ->
        socket =
          socket
          |> assign(:loading, false)
          |> assign(:errors, ["Failed to fetch benchmark data: #{format_error(reason)}"])
          |> assign(:comparison_results, nil)

        {:noreply, socket}
    end
  end

  # Helper functions for display

  defp benchmark_name("SPY"), do: "S&P 500"
  defp benchmark_name("VTI"), do: "Total Stock Market"
  defp benchmark_name("VTIAX"), do: "International Markets"
  defp benchmark_name(symbol), do: symbol

  defp period_description(365), do: "1-year"
  defp period_description(730), do: "2-year"
  defp period_description(1095), do: "3-year"
  defp period_description(180), do: "6-month"
  defp period_description(90), do: "3-month"
  defp period_description(days), do: "#{days}-day"

  defp format_error(:invalid_start_value), do: "Invalid start value"
  defp format_error(:invalid_end_value), do: "Invalid end value"
  defp format_error(:invalid_days), do: "Invalid analysis period"
  defp format_error(:unsupported_benchmark), do: "Unsupported benchmark"
  defp format_error(:network_error), do: "Network error - please try again"
  defp format_error(:timeout), do: "Request timeout - please try again"
  defp format_error(reason), do: inspect(reason)
end
