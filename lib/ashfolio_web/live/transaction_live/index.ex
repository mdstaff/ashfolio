defmodule AshfolioWeb.TransactionLive.Index do
  use AshfolioWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_current_page(:transactions)
      |> assign(:page_title, "Transactions")
      |> assign(:transactions, [])

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Page Header -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Transactions</h1>
          <p class="text-gray-600">View and manage your investment transactions</p>
        </div>
        <div class="flex space-x-3">
          <.button type="button" class="btn-secondary">
            <.icon name="hero-funnel" class="w-4 h-4 mr-2" />
            Filter
          </.button>
          <.button type="button" class="btn-primary">
            <.icon name="hero-plus" class="w-4 h-4 mr-2" />
            Add Transaction
          </.button>
        </div>
      </div>

      <!-- Transactions List -->
      <.card>
        <:header>
          <h2 class="text-lg font-medium text-gray-900">Transaction History</h2>
        </:header>

        <div class="text-center py-12">
          <.icon name="hero-arrow-right-left" class="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 class="text-lg font-medium text-gray-900 mb-2">No transactions yet</h3>
          <p class="text-gray-600 mb-4">Start by adding your first buy, sell, or dividend transaction.</p>
          <.button type="button" class="btn-primary">
            Add First Transaction
          </.button>
        </div>
      </.card>
    </div>
    """
  end
end
