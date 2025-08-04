defmodule AshfolioWeb.DashboardLive do
  use AshfolioWeb, :live_view

  alias Ashfolio.Portfolio.{Calculator, HoldingsCalculator, User}
  alias Ashfolio.MarketData.PriceManager
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
  def handle_event("refresh_prices", _params, socket) do
    Logger.info("Manual price refresh requested")

    # Set loading state
    socket = assign(socket, :loading, true)

    # Perform price refresh
    case PriceManager.refresh_prices() do
      {:ok, results} ->
        Logger.info("Price refresh successful: #{results.success_count} symbols updated")

        # Reload portfolio data with updated prices
        socket =
          socket
          |> assign(:loading, false)
          |> load_portfolio_data()
          |> ErrorHelpers.put_success_flash(
            "Prices refreshed successfully! Updated #{results.success_count} symbols in #{results.duration_ms}ms."
          )

        {:noreply, socket}

      {:error, :refresh_in_progress} ->
        Logger.info("Price refresh already in progress")

        socket =
          socket
          |> assign(:loading, false)
          |> ErrorHelpers.put_error_flash("Price refresh is already in progress. Please wait.")

        {:noreply, socket}

      {:error, reason} ->
        Logger.error("Price refresh failed: #{inspect(reason)}")

        socket =
          socket
          |> assign(:loading, false)
          |> ErrorHelpers.put_error_flash("Failed to refresh prices. Please try again.")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("sort", %{"column" => column}, socket) do
    {sort_by, sort_order} = toggle_sort(socket.assigns.sort_by, socket.assigns.sort_order, column)
    holdings = sort_holdings(socket.assigns.holdings, sort_by, sort_order)

    socket =
      socket
      |> assign(:sort_by, sort_by)
      |> assign(:sort_order, sort_order)
      |> assign(:holdings, holdings)

    {:noreply, socket}
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
          <.button type="button" class="btn-secondary" disabled={@loading} phx-click="refresh_prices">
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

        <%= if Enum.empty?(@holdings) do %>
          <div class="text-center py-12">
            <.icon name="hero-chart-bar" class="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-900 mb-2">No holdings yet</h3>
            <p class="text-gray-600 mb-4">Start by adding your first transaction to see your portfolio here.</p>
            <.button type="button" class="btn-primary">
              Add First Transaction
            </.button>
          </div>
        <% else %>
          <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
            <table class="w-[40rem] mt-11 sm:w-full">
              <thead class="text-sm text-left leading-6 text-zinc-500">
                <tr>
                  <th class="p-0 pb-4 pr-6 font-normal">
                    <button phx-click="sort" phx-value-column="symbol" class="hover:text-zinc-700">
                      Symbol {sort_indicator(@sort_by, @sort_order, :symbol)}
                    </button>
                  </th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Quantity</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Current Price</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">
                    <button phx-click="sort" phx-value-column="current_value" class="hover:text-zinc-700">
                      Current Value {sort_indicator(@sort_by, @sort_order, :current_value)}
                    </button>
                  </th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Cost Basis</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">
                    <button phx-click="sort" phx-value-column="unrealized_pnl" class="hover:text-zinc-700">
                      P&L {sort_indicator(@sort_by, @sort_order, :unrealized_pnl)}
                    </button>
                  </th>
                </tr>
              </thead>
              <tbody class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700">
                <tr :for={holding <- @holdings} class="group hover:bg-zinc-50">
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                      <span class="relative font-semibold text-zinc-900">
                        <div class="font-semibold text-gray-900">{holding.symbol}</div>
                        <div class="text-sm text-gray-500">{holding.name}</div>
                      </span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">{format_quantity(holding.quantity)}</span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">{FormatHelpers.format_currency(holding.current_price)}</span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">{FormatHelpers.format_currency(holding.current_value)}</span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">{FormatHelpers.format_currency(holding.cost_basis)}</span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                      <span class={["relative", FormatHelpers.value_color_class(holding.unrealized_pnl)]}>
                        <div>{FormatHelpers.format_currency(holding.unrealized_pnl)}</div>
                        <div class="text-sm">({FormatHelpers.format_percentage(holding.unrealized_pnl_pct)})</div>
                      </span>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        <% end %>
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
      |> assign(:holdings, holdings_summary.holdings)
      |> assign(:sort_by, :symbol)
      |> assign(:sort_order, :asc)
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
    |> assign(:holdings, [])
    |> assign(:sort_by, :symbol)
    |> assign(:sort_order, :asc)
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

  # Helper functions for holdings table

  defp format_quantity(decimal_value) do
    decimal_value
    |> Decimal.round(6)
    |> Decimal.to_string()
    |> String.replace(~r/\.?0+$/, "")
  end

  defp sort_holdings(holdings, sort_by, sort_order) do
    holdings
    |> Enum.sort_by(&Map.get(&1, sort_by), sort_order)
  end

  defp toggle_sort(current_sort, current_order, new_column) do
    new_column_atom = String.to_existing_atom(new_column)

    if current_sort == new_column_atom do
      {new_column_atom, toggle_order(current_order)}
    else
      {new_column_atom, :asc}
    end
  end

  defp toggle_order(:asc), do: :desc
  defp toggle_order(:desc), do: :asc

  defp sort_indicator(current_sort, current_order, column) do
    if current_sort == column do
      case current_order do
        :asc -> "↑"
        :desc -> "↓"
      end
    else
      ""
    end
  end
end
