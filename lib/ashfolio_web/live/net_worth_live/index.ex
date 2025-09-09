defmodule AshfolioWeb.NetWorthLive.Index do
  @moduledoc false
  use AshfolioWeb, :live_view

  alias Ashfolio.DataHelpers
  alias Ashfolio.Financial.Formatters
  alias Ashfolio.FinancialManagement.NetWorthSnapshot
  alias Contex.Dataset
  alias Contex.LineChart
  alias Contex.Plot

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_current_page(:net_worth)
      |> assign(:page_title, "Net Worth Trends")
      |> assign(:page_subtitle, "Track your financial progress over time")
      |> assign(:snapshots, [])
      |> assign(:chart_data, [])
      |> assign(:current_net_worth, Decimal.new(0))
      |> assign(:net_worth_change, Decimal.new(0))
      |> assign(:loading, true)
      |> assign(:chart_svg, nil)
      |> assign(:date_range, "last_6_months")

    socket = load_net_worth_data(socket)

    {:ok, socket}
  end

  @impl true
  def handle_event("change_date_range", %{"range" => range}, socket) do
    {:noreply,
     socket
     |> assign(:date_range, range)
     |> load_net_worth_data()}
  end

  @impl true
  def handle_event("create_snapshot", _params, socket) do
    # Calculate current net worth from all accounts
    current_net_worth = calculate_current_net_worth()

    # Create new snapshot
    total_assets = current_net_worth
    total_liabilities = Decimal.new("0.00")
    net_worth = Decimal.sub(total_assets, total_liabilities)

    {:ok, _snapshot} =
      NetWorthSnapshot.create(%{
        snapshot_date: Date.utc_today(),
        total_assets: total_assets,
        total_liabilities: total_liabilities,
        net_worth: net_worth,
        cash_value: calculate_total_cash(),
        investment_value: calculate_total_investments(),
        is_automated: false
      })

    socket =
      socket
      |> put_flash(:info, "Net worth snapshot created successfully!")
      |> load_net_worth_data()

    {:noreply, socket}
  rescue
    error ->
      {:noreply, put_flash(socket, :error, "Failed to create snapshot: #{inspect(error)}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Net Worth Trends</h1>
          <p class="text-gray-600">Track your financial progress over time</p>
        </div>
        <div class="flex gap-3">
          <button
            phx-click="create_snapshot"
            class="btn-primary inline-flex items-center"
          >
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 4v16m8-8H4"
              />
            </svg>
            Create Snapshot
          </button>
          <.link
            navigate={~p"/"}
            class="btn-secondary inline-flex items-center"
          >
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M10 19l-7-7m0 0l7-7m-7 7h18"
              />
            </svg>
            Back to Dashboard
          </.link>
        </div>
      </div>
      
    <!-- Date Range Controls -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Time Period</h3>
          <div class="flex flex-wrap gap-2">
            <button
              phx-click="change_date_range"
              phx-value-range="last_month"
              class={[
                "px-4 py-2 text-sm font-medium rounded-md border",
                if(@date_range == "last_month",
                  do: "bg-blue-50 text-blue-700 border-blue-300",
                  else: "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                )
              ]}
            >
              Last Month
            </button>
            <button
              phx-click="change_date_range"
              phx-value-range="last_3_months"
              class={[
                "px-4 py-2 text-sm font-medium rounded-md border",
                if(@date_range == "last_3_months",
                  do: "bg-blue-50 text-blue-700 border-blue-300",
                  else: "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                )
              ]}
            >
              Last 3 Months
            </button>
            <button
              phx-click="change_date_range"
              phx-value-range="last_6_months"
              class={[
                "px-4 py-2 text-sm font-medium rounded-md border",
                if(@date_range == "last_6_months",
                  do: "bg-blue-50 text-blue-700 border-blue-300",
                  else: "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                )
              ]}
            >
              Last 6 Months
            </button>
            <button
              phx-click="change_date_range"
              phx-value-range="last_year"
              class={[
                "px-4 py-2 text-sm font-medium rounded-md border",
                if(@date_range == "last_year",
                  do: "bg-blue-50 text-blue-700 border-blue-300",
                  else: "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                )
              ]}
            >
              Last Year
            </button>
            <button
              phx-click="change_date_range"
              phx-value-range="all_time"
              class={[
                "px-4 py-2 text-sm font-medium rounded-md border",
                if(@date_range == "all_time",
                  do: "bg-blue-50 text-blue-700 border-blue-300",
                  else: "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                )
              ]}
            >
              All Time
            </button>
          </div>
        </div>
      </div>
      
    <!-- Summary Stats -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4 bg-gray-50">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="text-center">
              <div class="text-3xl font-bold text-gray-900">
                {Formatters.format_currency_with_cents(@current_net_worth)}
              </div>
              <div class="text-sm text-gray-500">Current Net Worth</div>
            </div>
            <div class="text-center">
              <div class={[
                "text-3xl font-bold",
                if(Decimal.positive?(@net_worth_change), do: "text-green-600", else: "text-red-600")
              ]}>
                {format_change(@net_worth_change)}
              </div>
              <div class="text-sm text-gray-500">{format_date_range(@date_range)} Change</div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Chart Section -->
      <%= if @loading do %>
        <div class="bg-white shadow rounded-lg">
          <div class="text-center py-16 px-6">
            <.loading_spinner class="mx-auto w-8 h-8 text-blue-600 mb-4" />
            <p class="text-gray-500">Loading net worth data...</p>
          </div>
        </div>
      <% else %>
        <%= if Enum.empty?(@chart_data) do %>
          <!-- Empty State -->
          <div class="bg-white shadow rounded-lg">
            <div class="text-center py-16 px-6">
              <div class="mx-auto h-16 w-16 text-gray-400 mb-4">
                <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-full h-full">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"
                  />
                </svg>
              </div>
              <h3 class="text-lg font-medium text-gray-900 mb-2">No net worth data to display</h3>
              <p class="text-gray-500 mb-6 max-w-sm mx-auto">
                Create your first net worth snapshot to start tracking your financial progress.
              </p>
              <button
                phx-click="create_snapshot"
                class="btn-primary inline-flex items-center"
              >
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                Create First Snapshot
              </button>
            </div>
          </div>
        <% else %>
          <!-- Trend Chart -->
          <div class="bg-white shadow rounded-lg">
            <div class="px-6 py-4 border-b border-gray-200">
              <h3 class="text-lg font-medium text-gray-900">Net Worth Trend</h3>
            </div>
            <div class="p-6">
              <%= if @chart_svg do %>
                <div class="flex justify-center">
                  {Phoenix.HTML.raw(@chart_svg)}
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  # Private functions

  defp load_net_worth_data(socket) do
    socket = assign(socket, :loading, true)

    try do
      # Load all snapshots
      all_snapshots =
        NetWorthSnapshot
        |> Ash.Query.for_read(:read)
        |> Ash.Query.sort(snapshot_date: :asc)
        |> Ash.read!()

      # Filter by date range
      filtered_snapshots = filter_by_date_range(all_snapshots, socket.assigns.date_range)

      # Prepare chart data
      chart_data = prepare_chart_data(filtered_snapshots)

      # Generate chart
      chart_svg = generate_trend_chart(chart_data)

      # Calculate current net worth and change
      current_net_worth = calculate_current_net_worth()
      net_worth_change = calculate_net_worth_change(filtered_snapshots)

      socket
      |> assign(:snapshots, filtered_snapshots)
      |> assign(:chart_data, chart_data)
      |> assign(:current_net_worth, current_net_worth)
      |> assign(:net_worth_change, net_worth_change)
      |> assign(:chart_svg, chart_svg)
      |> assign(:loading, false)
    rescue
      error ->
        socket
        |> assign(:loading, false)
        |> put_flash(:error, "Failed to load net worth data: #{inspect(error)}")
    end
  end

  defp filter_by_date_range(snapshots, range) do
    DataHelpers.filter_by_date_range(snapshots, range, :snapshot_date)
  end

  defp prepare_chart_data(snapshots) do
    Enum.map(snapshots, fn snapshot ->
      [Date.to_string(snapshot.snapshot_date), Decimal.to_float(snapshot.net_worth)]
    end)
  end

  defp generate_trend_chart([]), do: nil

  defp generate_trend_chart(chart_data) do
    # Create chart using Contex official API
    chart_data
    |> Dataset.new()
    |> Plot.new(LineChart, 800, 400)
    |> Plot.to_svg()
  rescue
    _error ->
      # Fallback to simple message if chart generation fails
      """
      <div class="text-center py-8 text-gray-500">
        <p>Chart visualization temporarily unavailable</p>
        <p class="text-sm mt-2">#{length(chart_data)} data points available</p>
      </div>
      """
  end

  defp calculate_current_net_worth do
    # This would calculate from current account balances
    # For now, return the latest snapshot or zero
    case NetWorthSnapshot
         |> Ash.Query.for_read(:read)
         |> Ash.Query.sort(snapshot_date: :desc)
         |> Ash.Query.limit(1)
         |> Ash.read!() do
      [latest_snapshot] -> latest_snapshot.net_worth
      [] -> Decimal.new(0)
    end
  end

  defp calculate_net_worth_change(snapshots) when length(snapshots) < 2, do: Decimal.new(0)

  defp calculate_net_worth_change(snapshots) do
    first_snapshot = List.first(snapshots)
    last_snapshot = List.last(snapshots)
    Decimal.sub(last_snapshot.net_worth, first_snapshot.net_worth)
  end

  defp calculate_total_cash do
    # Placeholder - would sum cash account balances
    Decimal.new("1000.00")
  end

  defp calculate_total_investments do
    # Placeholder - would sum investment account balances
    Decimal.new("5000.00")
  end

  defp format_change(change) do
    sign = if Decimal.positive?(change), do: "+", else: ""
    "#{sign}#{Formatters.format_currency_with_cents(change)}"
  end

  defp format_date_range("last_month"), do: "Last Month"
  defp format_date_range("last_3_months"), do: "Last 3 Months"
  defp format_date_range("last_6_months"), do: "Last 6 Months"
  defp format_date_range("last_year"), do: "Last Year"
  defp format_date_range("all_time"), do: "All Time"
  defp format_date_range(_), do: "Last 6 Months"
end
