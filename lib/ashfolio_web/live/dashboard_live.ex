defmodule AshfolioWeb.DashboardLive do
  use AshfolioWeb, :live_view

  alias Ashfolio.Portfolio.HoldingsCalculator
  alias Ashfolio.MarketData.PriceManager
  alias Ashfolio.FinancialManagement.Expense
  alias Ashfolio.Context
  alias AshfolioWeb.Live.{ErrorHelpers, FormatHelpers}
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Ashfolio.PubSub.subscribe("accounts")
      Ashfolio.PubSub.subscribe("transactions")
      Ashfolio.PubSub.subscribe("net_worth")
      Ashfolio.PubSub.subscribe("expenses")
    end

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
  def handle_event("create_snapshot", _params, socket) do
    try do
      # Calculate current net worth from all accounts
      current_net_worth = calculate_current_net_worth()

      # Prepare snapshot data
      today = Date.utc_today()
      total_assets = current_net_worth
      total_liabilities = Decimal.new("0.00")
      net_worth = Decimal.sub(total_assets, total_liabilities)

      snapshot_data = %{
        snapshot_date: today,
        total_assets: total_assets,
        total_liabilities: total_liabilities,
        net_worth: net_worth,
        cash_value: calculate_total_cash(),
        investment_value: calculate_total_investments(),
        is_automated: false
      }

      # Try to create new snapshot, or update existing one for today
      case Ashfolio.FinancialManagement.NetWorthSnapshot.create(snapshot_data) do
        {:ok, _snapshot} ->
          socket =
            socket
            |> put_flash(:info, "Net worth snapshot created successfully!")
            |> load_portfolio_data()

          {:noreply, socket}

        {:error, _error} ->
          # If creation failed (likely due to date uniqueness), try to find existing snapshot for today
          case Ashfolio.FinancialManagement.NetWorthSnapshot.list!()
               |> Enum.filter(fn snapshot ->
                 Date.compare(snapshot.snapshot_date, today) == :eq
               end) do
            [existing_snapshot] ->
              case Ashfolio.FinancialManagement.NetWorthSnapshot.update(
                     existing_snapshot,
                     snapshot_data
                   ) do
                {:ok, _updated_snapshot} ->
                  socket =
                    socket
                    |> put_flash(:info, "Net worth snapshot updated for today!")
                    |> load_portfolio_data()

                  {:noreply, socket}

                {:error, update_error} ->
                  {:noreply,
                   put_flash(
                     socket,
                     :error,
                     "Failed to update snapshot: #{inspect(update_error)}"
                   )}
              end

            [] ->
              {:noreply, put_flash(socket, :error, "Failed to create snapshot: date conflict")}
          end
      end
    rescue
      error ->
        {:noreply, put_flash(socket, :error, "Failed to create snapshot: #{inspect(error)}")}
    end
  end

  @impl true
  def handle_info({:account_saved, _account}, socket) do
    {:noreply, load_portfolio_data(socket)}
  end

  @impl true
  def handle_info({:account_deleted, _account_id}, socket) do
    {:noreply, load_portfolio_data(socket)}
  end

  @impl true
  def handle_info({:account_updated, _account}, socket) do
    {:noreply, load_portfolio_data(socket)}
  end

  @impl true
  def handle_info({:transaction_deleted, _transaction_id}, socket) do
    {:noreply, load_portfolio_data(socket)}
  end

  @impl true
  def handle_info({:transaction_saved, _transaction}, socket) do
    {:noreply, load_portfolio_data(socket)}
  end

  @impl true
  def handle_info({:net_worth_updated, net_worth_data}, socket) do
    Logger.debug("Received net worth update via PubSub")
    {:noreply, assign_net_worth_data(socket, net_worth_data)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Page Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Portfolio Dashboard</h1>
          <p class="text-gray-600">Overview of your investment portfolio</p>
          <p :if={@last_price_update} class="text-sm text-gray-500 mt-1">
            Last updated: {FormatHelpers.format_relative_time(@last_price_update)}
          </p>
        </div>
        <div class="flex flex-col sm:flex-row gap-3 w-full sm:w-auto">
          <.button
            type="button"
            class="btn-secondary w-full sm:w-auto"
            disabled={@loading}
            phx-click="refresh_prices"
            data-testid="refresh-prices-button"
          >
            <%= if @loading do %>
              <.loading_spinner class="w-4 h-4 mr-2" data-testid="loading-spinner" />
            <% else %>
              <.icon name="hero-arrow-path" class="w-4 h-4 mr-2" />
            <% end %>
            {if @loading, do: "Refreshing...", else: "Refresh Prices"}
          </.button>
          <.link
            href={~p"/transactions"}
            class="btn-primary w-full sm:w-auto inline-flex items-center justify-center"
          >
            <.icon name="hero-plus" class="w-4 h-4 mr-2" /> Add Transaction
          </.link>
        </div>
      </div>
      
    <!-- Portfolio Summary Cards -->
      <div
        class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-6"
        data-testid="portfolio-summary"
      >
        <.stat_card
          title="Total Value"
          value={@portfolio_value}
          change={@total_return_percent}
          positive={FormatHelpers.is_positive?(@total_return_amount)}
          data_testid="total-value"
        />
        <.stat_card title="Daily Change" value="N/A" change="Phase 2" positive={true} />
        <.stat_card
          title="Total Return"
          value={@total_return_amount}
          change={@total_return_percent}
          positive={FormatHelpers.is_positive?(@total_return_amount)}
          data_testid="total-return"
        />
        <.stat_card
          title="Holdings"
          value={@holdings_count}
          change={"#{@holdings_count} positions"}
          data_testid="holdings-count"
        />
        <.net_worth_card
          title="Net Worth"
          value={@net_worth_total}
          investment_value={@net_worth_investment_value}
          cash_balance={@net_worth_cash_balance}
          data_testid="net-worth-total"
        />
        <.expense_widget
          total_expenses={@total_expenses}
          expense_count={@expense_count}
          current_month_expenses={@current_month_expenses}
        />
      </div>
      
    <!-- Investment vs Cash Breakdown -->
      <.card>
        <:header>
          <h2 class="text-lg font-medium text-gray-900">Investment vs Cash Breakdown</h2>
        </:header>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mt-4">
          <!-- Investment Accounts -->
          <div class="bg-blue-50 rounded-lg p-4">
            <div class="flex items-center justify-between mb-2">
              <h3 class="text-sm font-medium text-blue-900">Investment Accounts</h3>
              <span class="text-sm text-blue-600">
                {get_account_count(@net_worth_breakdown, :investment_accounts)} accounts
              </span>
            </div>
            <p class="text-2xl font-semibold text-blue-900">{@net_worth_investment_value}</p>
            <p class="text-sm text-blue-600 mt-1">Portfolio Value</p>
          </div>
          
    <!-- Cash Accounts -->
          <div class="bg-green-50 rounded-lg p-4">
            <div class="flex items-center justify-between mb-2">
              <h3 class="text-sm font-medium text-green-900">Cash Accounts</h3>
              <span class="text-sm text-green-600">
                {get_account_count(@net_worth_breakdown, :cash_accounts)} accounts
              </span>
            </div>
            <p class="text-2xl font-semibold text-green-900">{@net_worth_cash_balance}</p>
            <p class="text-sm text-green-600 mt-1">Available Cash</p>
          </div>
        </div>
      </.card>
      
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
            <p class="text-gray-600 mb-4">
              Start by adding your first transaction to see your portfolio here.
            </p>
            <.button type="button" class="btn-primary">
              Add First Transaction
            </.button>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table
              class="min-w-full mt-4"
              role="table"
              aria-label="Portfolio holdings"
              data-testid="holdings-table"
            >
              <thead class="text-sm text-left leading-6 text-zinc-500">
                <tr>
                  <th class="p-0 pb-4 pr-6 font-normal">
                    <button
                      phx-click="sort"
                      phx-value-column="symbol"
                      class="hover:text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-1 rounded"
                      aria-label="Sort by symbol"
                    >
                      Symbol {sort_indicator(@sort_by, @sort_order, :symbol)}
                    </button>
                  </th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Quantity</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Current Price</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">
                    <button
                      phx-click="sort"
                      phx-value-column="current_value"
                      class="hover:text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-1 rounded"
                      aria-label="Sort by current value"
                    >
                      Current Value {sort_indicator(@sort_by, @sort_order, :current_value)}
                    </button>
                  </th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Cost Basis</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">
                    <button
                      phx-click="sort"
                      phx-value-column="unrealized_pnl"
                      class="hover:text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-1 rounded"
                      aria-label="Sort by profit and loss"
                    >
                      P&L {sort_indicator(@sort_by, @sort_order, :unrealized_pnl)}
                    </button>
                  </th>
                </tr>
              </thead>
              <tbody class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700">
                <tr :for={holding <- @holdings} class="group hover:bg-zinc-50" role="row">
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
                      <span class="relative">
                        {FormatHelpers.format_currency(holding.current_price)}
                      </span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">
                        {FormatHelpers.format_currency(holding.current_value)}
                      </span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">
                        {FormatHelpers.format_currency(holding.cost_basis)}
                      </span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                      <span class={[
                        "relative",
                        FormatHelpers.value_color_class(holding.unrealized_pnl)
                      ]}>
                        <div>{FormatHelpers.format_currency(holding.unrealized_pnl)}</div>
                        <div class="text-sm">
                          ({FormatHelpers.format_percentage(holding.unrealized_pnl_pct)})
                        </div>
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
          <.link href={~p"/transactions"} class="btn-secondary text-sm">
            View All
          </.link>
        </:actions>

        <%= if Enum.empty?(@recent_transactions) do %>
          <div class="text-center py-8" data-testid="no-recent-transactions">
            <.icon name="hero-clock" class="w-8 h-8 text-gray-400 mx-auto mb-2" />
            <p class="text-gray-600">No recent transactions</p>
            <p class="text-sm text-gray-500 mt-1">
              Your latest investment activity will appear here
            </p>
          </div>
        <% else %>
          <div class="space-y-3" data-testid="recent-transactions-list">
            <%= for transaction <- @recent_transactions do %>
              <div
                class="flex items-center justify-between py-3 border-b border-gray-100 last:border-b-0"
                data-testid="recent-transaction-item"
              >
                <div class="flex items-start space-x-3">
                  <div class="flex-shrink-0">
                    <div class={[
                      "w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-medium",
                      transaction_type_color(transaction.type)
                    ]}>
                      {transaction_type_icon(transaction.type)}
                    </div>
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center space-x-2">
                      <p class="text-sm font-medium text-gray-900 truncate">
                        {get_transaction_symbol(transaction)}
                      </p>
                      <%= if get_transaction_category(transaction) do %>
                        <AshfolioWeb.Components.CategoryTag.category_tag
                          category={get_transaction_category(transaction)}
                          size={:small}
                        />
                      <% end %>
                    </div>
                    <div class="flex items-center space-x-2 mt-1">
                      <p class="text-xs text-gray-500">
                        {String.capitalize(Atom.to_string(transaction.type))}
                      </p>
                      <span class="text-gray-300">•</span>
                      <p class="text-xs text-gray-500">
                        {format_quantity(transaction.quantity)} shares
                      </p>
                      <span class="text-gray-300">•</span>
                      <p class="text-xs text-gray-500">
                        {FormatHelpers.format_relative_time(transaction.date)}
                      </p>
                    </div>
                  </div>
                </div>
                <div class="text-right">
                  <p class={[
                    "text-sm font-medium",
                    FormatHelpers.value_color_class(transaction.total_amount)
                  ]}>
                    {FormatHelpers.format_currency(transaction.total_amount)}
                  </p>
                  <p class="text-xs text-gray-500">
                    @ {FormatHelpers.format_currency(get_transaction_price(transaction))}
                  </p>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </.card>
    </div>
    """
  end

  # Private functions

  defp load_portfolio_data(socket) do
    Logger.debug("Loading portfolio data for dashboard")

    # Database-as-user architecture - load data directly without user lookup
    case Context.get_dashboard_data() do
      {:ok, dashboard_data} ->
        load_dashboard_data(socket, dashboard_data)

      {:error, reason} ->
        Logger.warning("Failed to load dashboard data: #{inspect(reason)}")

        socket
        |> assign_default_values()
        |> ErrorHelpers.put_error_flash("Unable to load portfolio data")
    end
  end

  # This function is no longer needed - replaced by load_dashboard_data

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
    |> assign(:recent_transactions, [])
    |> assign_default_net_worth_values()
    |> assign_default_expense_values()
  end

  # This function is now handled in load_holdings_and_net_worth

  # This function is now handled in load_dashboard_data via Context.get_dashboard_data

  defp assign_net_worth_data(socket, net_worth_data) do
    # Handle both Context.get_net_worth (returns :total_net_worth) and NetWorthCalculator.calculate_net_worth (returns :net_worth)
    net_worth_value = net_worth_data[:total_net_worth] || net_worth_data[:net_worth]

    socket
    |> assign(:net_worth_total, FormatHelpers.format_currency(net_worth_value))
    |> assign(
      :net_worth_investment_value,
      FormatHelpers.format_currency(net_worth_data.investment_value)
    )
    |> assign(
      :net_worth_cash_balance,
      FormatHelpers.format_currency(net_worth_data[:cash_balance] || net_worth_data[:cash_value])
    )
    |> assign(:net_worth_breakdown, net_worth_data.breakdown)
    |> assign(:net_worth_error, nil)
  end

  defp assign_default_net_worth_values(socket) do
    socket
    |> assign(:net_worth_total, "$0.00")
    |> assign(:net_worth_investment_value, "$0.00")
    |> assign(:net_worth_cash_balance, "$0.00")
    |> assign(:net_worth_breakdown, %{investment_accounts: [], cash_accounts: []})
    |> assign(:net_worth_error, "Unable to load net worth data")
  end

  # Load dashboard data from Context API (database-as-user architecture)
  defp load_dashboard_data(socket, dashboard_data) do
    %{
      user: user_settings,
      accounts: accounts,
      recent_transactions: transactions,
      summary: summary
    } = dashboard_data

    socket
    |> assign(:user_settings, user_settings)
    |> assign(:accounts, accounts.all)
    |> assign(:recent_transactions, transactions)
    |> assign(:account_summary, summary)
    |> load_holdings_and_net_worth()
    |> load_expense_data()
  end

  defp load_holdings_and_net_worth(socket) do
    # Load holdings and net worth without user_id
    case Context.get_net_worth() do
      {:ok, net_worth_data} ->
        socket
        |> assign_net_worth_data(net_worth_data)
        |> load_holdings_data()

      {:error, reason} ->
        Logger.warning("Failed to load net worth: #{inspect(reason)}")

        socket
        |> assign_default_values()
    end
  end

  defp load_holdings_data(socket) do
    case HoldingsCalculator.get_holdings_summary() do
      {:ok, holdings_data} ->
        socket
        |> assign(:holdings, holdings_data.holdings)
        |> assign(:portfolio_value, FormatHelpers.format_currency(holdings_data.total_value))
        |> assign(:portfolio_pnl, FormatHelpers.format_currency(holdings_data.total_pnl))
        |> assign(:total_return_amount, FormatHelpers.format_currency(holdings_data.total_pnl))
        |> assign(
          :total_return_percent,
          FormatHelpers.format_percentage(holdings_data.total_pnl_pct)
        )
        |> assign(:cost_basis, FormatHelpers.format_currency(holdings_data.total_cost_basis))
        |> assign(:holdings_count, to_string(holdings_data.holdings_count))
        |> assign(:sort_by, :symbol)
        |> assign(:sort_order, :asc)
        |> assign(:last_price_update, get_last_price_update())
        |> assign(:error, nil)

      {:error, reason} ->
        Logger.warning("Failed to load holdings: #{inspect(reason)}")

        socket
        |> assign(:holdings, [])
        |> assign(:portfolio_value, "$0.00")
        |> assign(:portfolio_pnl, "$0.00")
        |> assign(:total_return_amount, "$0.00")
        |> assign(:total_return_percent, "0.00%")
        |> assign(:cost_basis, "$0.00")
        |> assign(:holdings_count, "0")
        |> assign(:error, "Unable to load holdings data")
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

  # Helper function to safely get account count from breakdown
  defp get_account_count(breakdown, account_type) when is_map(breakdown) do
    case Map.get(breakdown, account_type) do
      accounts when is_list(accounts) -> length(accounts)
      _ -> 0
    end
  end

  defp get_account_count(_, _), do: 0

  # Helper functions for Recent Activity section

  defp transaction_type_color(:buy), do: "bg-green-500"
  defp transaction_type_color(:sell), do: "bg-red-500"
  defp transaction_type_color(:dividend), do: "bg-blue-500"
  defp transaction_type_color(:fee), do: "bg-yellow-500"
  defp transaction_type_color(:interest), do: "bg-purple-500"
  defp transaction_type_color(:liability), do: "bg-gray-500"
  defp transaction_type_color(_), do: "bg-gray-400"

  defp transaction_type_icon(:buy), do: "+"
  defp transaction_type_icon(:sell), do: "-"
  defp transaction_type_icon(:dividend), do: "$"
  defp transaction_type_icon(:fee), do: "F"
  defp transaction_type_icon(:interest), do: "I"
  defp transaction_type_icon(:liability), do: "L"
  defp transaction_type_icon(_), do: "?"

  defp get_transaction_symbol(%{symbol: %{symbol: symbol}}), do: symbol
  defp get_transaction_symbol(%{symbol: nil}), do: "N/A"
  defp get_transaction_symbol(_), do: "N/A"

  defp get_transaction_category(%{category: category}) when not is_nil(category), do: category
  defp get_transaction_category(_), do: nil

  defp get_transaction_price(%{price: price}) when not is_nil(price), do: price
  defp get_transaction_price(%{symbol: %{current_price: price}}) when not is_nil(price), do: price
  defp get_transaction_price(_), do: Decimal.new("0.00")

  # Expense functions

  defp assign_default_expense_values(socket) do
    socket
    |> assign(:total_expenses, FormatHelpers.format_currency(Decimal.new("0.00")))
    |> assign(:expense_count, 0)
    |> assign(:current_month_expenses, FormatHelpers.format_currency(Decimal.new("0.00")))
  end

  defp load_expense_data(socket) do
    try do
      # Load all expenses
      expenses =
        Expense
        |> Ash.Query.for_read(:read)
        |> Ash.read!()

      # Calculate totals
      total_expenses = calculate_total_expenses(expenses)
      expense_count = length(expenses)
      current_month_total = calculate_current_month_expenses(expenses)

      socket
      |> assign(:total_expenses, FormatHelpers.format_currency(total_expenses))
      |> assign(:expense_count, expense_count)
      |> assign(:current_month_expenses, FormatHelpers.format_currency(current_month_total))
    rescue
      _error ->
        assign_default_expense_values(socket)
    end
  end

  defp calculate_total_expenses(expenses) do
    expenses
    |> Enum.reduce(Decimal.new(0), fn expense, acc ->
      Decimal.add(acc, expense.amount)
    end)
  end

  defp calculate_current_net_worth do
    # Calculate from current account balances
    case Ashfolio.Portfolio.Account |> Ash.Query.for_read(:read) |> Ash.read!() do
      [] ->
        Decimal.new(0)

      accounts ->
        accounts
        |> Enum.reduce(Decimal.new(0), fn account, acc ->
          Decimal.add(acc, account.balance)
        end)
    end
  end

  defp calculate_total_cash do
    # Sum cash account balances
    case Ashfolio.Portfolio.Account.cash_accounts!() do
      [] ->
        Decimal.new(0)

      accounts ->
        accounts
        |> Enum.reduce(Decimal.new(0), fn account, acc ->
          Decimal.add(acc, account.balance)
        end)
    end
  end

  defp calculate_total_investments do
    # Sum investment account balances
    case Ashfolio.Portfolio.Account.investment_accounts!() do
      [] ->
        Decimal.new(0)

      accounts ->
        accounts
        |> Enum.reduce(Decimal.new(0), fn account, acc ->
          Decimal.add(acc, account.balance)
        end)
    end
  end

  defp calculate_current_month_expenses(expenses) do
    current_month = Date.beginning_of_month(Date.utc_today())

    expenses
    |> Enum.filter(fn expense ->
      Date.compare(expense.date, current_month) != :lt
    end)
    |> Enum.reduce(Decimal.new(0), fn expense, acc ->
      Decimal.add(acc, expense.amount)
    end)
  end
end
