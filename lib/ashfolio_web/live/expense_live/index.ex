defmodule AshfolioWeb.ExpenseLive.Index do
  use AshfolioWeb, :live_view

  alias Ashfolio.FinancialManagement.Expense
  alias AshfolioWeb.Live.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_current_page(:expenses)
      |> assign(:page_title, "Expenses")
      |> assign(:page_subtitle, "Track and categorize your expenses")
      |> assign(:expenses, [])
      |> assign(:total_expenses, Decimal.new(0))
      |> assign(:expense_count, 0)
      |> assign(:current_month_total, Decimal.new(0))
      |> assign(:sort_by, :date)
      |> assign(:sort_dir, :desc)
      |> assign(:loading, true)

    socket = load_expenses(socket)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("sort", %{"sort_by" => sort_by}, socket) do
    sort_by = String.to_existing_atom(sort_by)

    # Toggle direction if clicking same column
    sort_dir =
      if socket.assigns.sort_by == sort_by and socket.assigns.sort_dir == :asc do
        :desc
      else
        :asc
      end

    {:noreply,
     socket
     |> assign(:sort_by, sort_by)
     |> assign(:sort_dir, sort_dir)
     |> load_expenses()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header with Add Expense Button -->
      <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Expenses</h1>
          <p class="text-gray-600">Track and categorize your expenses</p>
        </div>
        <.link
          patch={~p"/expenses/new"}
          class="btn-primary inline-flex items-center"
        >
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Add Expense
        </.link>
      </div>
      
    <!-- Summary Stats -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4 bg-gray-50">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="text-center">
              <div class="text-2xl font-bold text-gray-900">
                {FormatHelpers.format_currency(@total_expenses)}
              </div>
              <div class="text-sm text-gray-500">Total Expenses</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-blue-600">
                {@expense_count} expenses
              </div>
              <div class="text-sm text-gray-500">All Time</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-green-600">
                {FormatHelpers.format_currency(@current_month_total)}
              </div>
              <div class="text-sm text-gray-500">This Month</div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Expenses Table -->
      <%= if @loading do %>
        <div class="bg-white shadow rounded-lg">
          <div class="text-center py-16 px-6">
            <.loading_spinner class="mx-auto w-8 h-8 text-blue-600 mb-4" />
            <p class="text-gray-500">Loading expenses...</p>
          </div>
        </div>
      <% else %>
        <%= if Enum.empty?(@expenses) do %>
          <!-- Empty State -->
          <div class="bg-white shadow rounded-lg">
            <div class="text-center py-16 px-6">
              <div class="mx-auto h-16 w-16 text-gray-400 mb-4">
                <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-full h-full">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M9 8h6m-5 0a3 3 0 110 6H9l3 3m-3-6h6m6 1a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </div>
              <h3 class="text-lg font-medium text-gray-900 mb-2">No expenses</h3>
              <p class="text-gray-500 mb-6 max-w-sm mx-auto">
                Start tracking your expenses to understand your spending patterns and improve your financial planning.
              </p>
              <.link
                patch={~p"/expenses/new"}
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
                Add Your First Expense
              </.link>
            </div>
          </div>
        <% else %>
          <!-- Expenses Table -->
          <div class="bg-white shadow rounded-lg overflow-hidden">
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th
                      data-sort="date"
                      phx-click="sort"
                      phx-value-sort_by="date"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    >
                      Date
                      <%= if @sort_by == :date do %>
                        <span class="ml-1">
                          {if @sort_dir == :asc, do: "↑", else: "↓"}
                        </span>
                      <% end %>
                    </th>
                    <th
                      data-sort="amount"
                      phx-click="sort"
                      phx-value-sort_by="amount"
                      class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    >
                      Amount
                      <%= if @sort_by == :amount do %>
                        <span class="ml-1">
                          {if @sort_dir == :asc, do: "↑", else: "↓"}
                        </span>
                      <% end %>
                    </th>
                    <th
                      data-sort="description"
                      phx-click="sort"
                      phx-value-sort_by="description"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    >
                      Description
                      <%= if @sort_by == :description do %>
                        <span class="ml-1">
                          {if @sort_dir == :asc, do: "↑", else: "↓"}
                        </span>
                      <% end %>
                    </th>
                    <th
                      data-sort="category"
                      phx-click="sort"
                      phx-value-sort_by="category"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    >
                      Category
                      <%= if @sort_by == :category do %>
                        <span class="ml-1">
                          {if @sort_dir == :asc, do: "↑", else: "↓"}
                        </span>
                      <% end %>
                    </th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for expense <- @expenses do %>
                    <tr class="hover:bg-gray-50">
                      <td class="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-900">
                        {FormatHelpers.format_date(expense.date)}
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm font-mono font-semibold text-right text-gray-900">
                        {FormatHelpers.format_currency(expense.amount)}
                      </td>
                      <td class="px-6 py-4 text-sm text-gray-900">
                        <div class="font-medium">{expense.description}</div>
                        <%= if expense.merchant do %>
                          <div class="text-gray-500">{expense.merchant}</div>
                        <% end %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm">
                        <%= if expense.category do %>
                          <span
                            class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                            style={"background-color: #{expense.category.color}1A; color: #{expense.category.color}"}
                          >
                            {expense.category.name}
                          </span>
                        <% else %>
                          <span class="text-gray-400">Uncategorized</span>
                        <% end %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
                        <.link
                          patch={~p"/expenses/#{expense.id}/edit"}
                          class="btn-secondary text-xs px-2 py-1 inline-flex items-center"
                          title="Edit expense"
                        >
                          <svg
                            class="w-3 h-3 mr-1"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                            />
                          </svg>
                          Edit
                        </.link>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  # Private functions

  defp apply_action(socket, :index, _params) do
    socket
  end

  defp apply_action(socket, :new, _params) do
    socket
  end

  defp apply_action(socket, :edit, %{"id" => _id}) do
    socket
  end

  defp load_expenses(socket) do
    socket = assign(socket, :loading, true)

    try do
      # Load expenses with category and account preloaded
      expenses =
        Expense
        |> Ash.Query.for_read(:read)
        |> Ash.Query.load([:category, :account])
        |> Ash.Query.sort({socket.assigns.sort_by, socket.assigns.sort_dir})
        |> Ash.read!()

      # Calculate statistics
      total_expenses = calculate_total_expenses(expenses)
      expense_count = length(expenses)
      current_month_total = calculate_current_month_total(expenses)

      socket
      |> assign(:expenses, expenses)
      |> assign(:total_expenses, total_expenses)
      |> assign(:expense_count, expense_count)
      |> assign(:current_month_total, current_month_total)
      |> assign(:loading, false)
    rescue
      error ->
        socket
        |> assign(:loading, false)
        |> put_flash(:error, "Failed to load expenses: #{inspect(error)}")
    end
  end

  defp calculate_total_expenses(expenses) do
    expenses
    |> Enum.reduce(Decimal.new(0), fn expense, acc ->
      Decimal.add(acc, expense.amount)
    end)
  end

  defp calculate_current_month_total(expenses) do
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
