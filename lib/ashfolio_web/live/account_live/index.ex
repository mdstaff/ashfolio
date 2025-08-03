defmodule AshfolioWeb.AccountLive.Index do
  use AshfolioWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_current_page(:accounts)
      |> assign(:page_title, "Accounts")
      |> assign(:accounts, [])

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Page Header -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Investment Accounts</h1>
          <p class="text-gray-600">Manage your investment accounts and balances</p>
        </div>
        <.button type="button" class="btn-primary">
          <.icon name="hero-plus" class="w-4 h-4 mr-2" />
          Add Account
        </.button>
      </div>

      <!-- Accounts List -->
      <.card>
        <:header>
          <h2 class="text-lg font-medium text-gray-900">Your Accounts</h2>
        </:header>

        <div class="text-center py-12">
          <.icon name="hero-building-library" class="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 class="text-lg font-medium text-gray-900 mb-2">No accounts yet</h3>
          <p class="text-gray-600 mb-4">Add your first investment account to start tracking your portfolio.</p>
          <.button type="button" class="btn-primary">
            Add First Account
          </.button>
        </div>
      </.card>
    </div>
    """
  end
end
