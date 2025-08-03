defmodule AshfolioWeb.DashboardLive do
  use AshfolioWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_current_page(:dashboard)
      |> assign(:page_title, "Dashboard")
      |> assign(:loading, false)
      |> assign(:portfolio_value, "$0.00")
      |> assign(:daily_change, "$0.00")
      |> assign(:daily_change_percent, "0.00%")
      |> assign(:total_return, "$0.00")
      |> assign(:total_return_percent, "0.00%")

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
        </div>
        <div class="flex space-x-3">
          <.button type="button" class="btn-secondary">
            <.icon name="hero-arrow-path" class="w-4 h-4 mr-2" />
            Refresh Prices
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
          change={@daily_change_percent}
          positive={true}
        />
        <.stat_card
          title="Daily Change"
          value={@daily_change}
          change={@daily_change_percent}
          positive={true}
        />
        <.stat_card
          title="Total Return"
          value={@total_return}
          change={@total_return_percent}
          positive={true}
        />
        <.stat_card
          title="Holdings"
          value="0"
          change="0 positions"
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
end
