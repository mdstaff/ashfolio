defmodule AshfolioWeb.DashboardLive do
  use AshfolioWeb, :live_view

  alias Ashfolio.Portfolio.{Calculator, HoldingsCalculator, User}
  alias AshfolioWeb.Live.{ErrorHelpers, FormatHelpers}
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_current_page(:dashboard)
      |> assign(:page_title, "Dashboard")
      |> assign(:loading, false)
      |> load_portfolio_data()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Page Header -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Portfolio Dashboard</h1>
          <p class="text-gray-600">Overview of your investment portfolio</p>
          <p :if={@last_price_update} class="text-sm text-gray-500 mt-1">
            Last updated: {FormatHelpers.format_relative_time(@last_price_update)}
          </p>
        </div>
        <div class="flex space-x-3">
          <.button type="button" class="btn-secondary" disabled={@loading}>
            <.icon name="hero-arrow-path" class={if @loading, do: "w-4 h-4 mr-2 animate-spin", else: "w-4 h-4 mr-2"} />
            {if @loading, do: "Refreshing...", else: "Refresh Prices"}
          </.button>
          <.button type="button" class="btn-primary">
            <.icon name="hero-plus" class="w-4 h-4 mr-2" />
            Add Transaction
          </.button>
        </div>
      </div>

      <!-- Portfolio Summary Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <.stat_card
          title="Total Value"
          value={@portfolio_value}
          change={@total_return_percent}
          positive={FormatHelpers.is_positive?(@total_return_amount)}
        />
        <.stat_card
          title="Daily Change"
          value="N/A"
          change="Phase 2"
          positive={true}
        />
        <.stat_card
          title="Total Return"
          value={@total_return_amount}
          change={@total_return_percent}
          positive={FormatHelpers.is_positive?(@total_return_amount)}
        />
        <.stat_card
          title="Holdings"
          value={@holdings_count}
          change={"#{@holdings_count} positions"}
        />
      </div>

      <!-- Holdings Table -->
      <.card>
        <:header>
          <h2 class="text-lg font-medium text-gray-900">Current Holdings</h2>
        </:header>
        <:actions>
          <.button type="button" class="btn-secondary text-sm">
            View All
          </.button>
        </:actions>

        <div class="text-center py-12">
          <.icon name="hero-chart-bar" class="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 class="text-lg font-medium text-gray-900 mb-2">No holdings yet</h3>
          <p class="text-gray-600 mb-4">Start by adding your first transaction to see your portfolio here.</p>
          <.button type="button" class="btn-primary">
            Add First Transaction
          </.button>
        </div>
      </.card>

      <!-- Recent Activity -->
      <.card>
        <:header>
          <h2 class="text-lg font-medium text-gray-900">Recent Activity</h2>
        </:header>
        <:actions>
          <.button type="button" class="btn-secondary text-sm">
            View All
          </.button>
        </:actions>

        <div class="text-center py-8">
          <.icon name="hero-clock" class="w-8 h-8 text-gray-400 mx-auto mb-2" />
          <p class="text-gray-600">No recent transactions</p>
        </div>
      </.card>
    </div>
    """
  end

  # Private functions

  defp load_portfolio_data(socket) do
    Logger.debug("Loading portfolio data for dashboard")

    case get_default_user() do
      {:ok, user} ->
        load_user_portfolio_data(socket, user.id)

      {:error, reason} ->
        Logger.warning("Failed to get default user: #{inspect(reason)}")
        socket
        |> assign_default_values()
        |> ErrorHelpers.put_error_flash("Unable to load user data")
    end
  end

  defp load_user_portfolio_data(socket, user_id) do
    with {:ok, total_return_data} <- Calculator.calculate_total_return(user_id),
         {:ok, holdings_summary} <- HoldingsCalculator.get_holdings_summary(user_id) do

      socket
      |> assign(:portfolio_value, FormatHelpers.format_currency(total_return_data.total_value))
      |> assign(:total_return_amount, FormatHelpers.format_currency(total_return_data.dollar_return))
      |> assign(:total_return_percent, FormatHelpers.format_percentage(total_return_data.return_percentage))
      |> assign(:cost_basis, FormatHelpers.format_currency(total_return_data.cost_basis))
      |> assign(:holdings_count, to_string(holdings_summary.holdings_count))
      |> assign(:last_price_update, get_last_price_update())
      |> assign(:error, nil)

    else
      {:error, reason} ->
        Logger.warning("Failed to load portfolio data: #{inspect(reason)}")
        socket
        |> assign_default_values()
        |> ErrorHelpers.put_error_flash("Unable to load portfolio data")
    end
  end

  defp assign_default_values(socket) do
    socket
    |> assign(:portfolio_value, "$0.00")
    |> assign(:total_return_amount, "$0.00")
    |> assign(:total_return_percent, "0.00%")
    |> assign(:cost_basis, "$0.00")
    |> assign(:holdings_count, "0")
    |> assign(:last_price_update, nil)
    |> assign(:error, "Unable to load portfolio data")
  end

  defp get_default_user do
    case User.get_default_user() do
      {:ok, [user]} -> {:ok, user}
      {:ok, []} -> {:error, :no_user_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_last_price_update do
    try do
      # Get the most recent price update from cache
      case Ashfolio.Cache.get_all_prices() do
        [] ->
          nil

        prices ->
          prices
          |> Enum.map(fn {_symbol, price_data} -> price_data.updated_at end)
          |> Enum.max(DateTime)
      end
    rescue
      error ->
        Logger.warning("Failed to get last price update: #{inspect(error)}")
        nil
    end
  end
end
