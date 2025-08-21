defmodule AshfolioWeb.ExpenseLive.Index do
  use AshfolioWeb, :live_view

  alias Ashfolio.FinancialManagement.{Expense, TransactionCategory}
  alias AshfolioWeb.Live.{FormatHelpers, ErrorHelpers}
  alias AshfolioWeb.ExpenseLive.FormComponent

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
      |> assign(:show_form, false)
      |> assign(:form_action, nil)
      |> assign(:selected_expense, nil)
      |> assign(:search_query, "")
      |> assign(:filter_category_id, "")
      |> assign(:filter_date_from, "")
      |> assign(:filter_date_to, "")
      |> assign(:filter_amount_min, "")
      |> assign(:filter_amount_max, "")
      |> assign(:show_filters, false)
      |> assign(:categories, load_categories())

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
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> load_expenses()}
  end

  @impl true
  def handle_event("toggle_filters", _params, socket) do
    {:noreply, assign(socket, :show_filters, !socket.assigns.show_filters)}
  end

  @impl true
  def handle_event("filter", filters, socket) do
    {:noreply,
     socket
     |> assign(:filter_category_id, filters["category_id"] || "")
     |> assign(:filter_date_from, filters["date_from"] || "")
     |> assign(:filter_date_to, filters["date_to"] || "")
     |> assign(:filter_amount_min, filters["amount_min"] || "")
     |> assign(:filter_amount_max, filters["amount_max"] || "")
     |> load_expenses()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:search_query, "")
     |> assign(:filter_category_id, "")
     |> assign(:filter_date_from, "")
     |> assign(:filter_date_to, "")
     |> assign(:filter_amount_min, "")
     |> assign(:filter_amount_max, "")
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
      
    <!-- Search and Filters -->
      <div class="bg-white shadow rounded-lg">
        <div class="p-6">
          <!-- Search Bar -->
          <div class="flex flex-col sm:flex-row gap-4 mb-4">
            <div class="flex-1">
              <form phx-change="search" phx-submit="search">
                <input
                  type="text"
                  name="search[query]"
                  value={@search_query}
                  placeholder="Search expenses by description or merchant..."
                  class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400"
                />
              </form>
            </div>
            <button
              type="button"
              phx-click="toggle_filters"
              class={[
                "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium",
                if(@show_filters,
                  do: "bg-blue-50 text-blue-700 border-blue-300",
                  else: "bg-white text-gray-700 hover:bg-gray-50"
                )
              ]}
            >
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.707A1 1 0 013 7V4z"
                />
              </svg>
              Filters
              <%= if @show_filters do %>
                <svg class="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M5 15l7-7 7 7"
                  />
                </svg>
              <% else %>
                <svg class="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 9l-7 7-7-7"
                  />
                </svg>
              <% end %>
            </button>
          </div>
          
    <!-- Advanced Filters -->
          <%= if @show_filters do %>
            <div class="border-t border-gray-200 pt-4">
              <form phx-change="filter" phx-submit="filter">
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <!-- Category Filter -->
                  <div>
                    <label
                      for="filters_category_id"
                      class="block text-sm font-medium leading-6 text-zinc-800"
                    >
                      Category
                    </label>
                    <select
                      id="filters_category_id"
                      name="category_id"
                      value={@filter_category_id}
                      class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400"
                    >
                      <option value="">All Categories</option>
                      <%= for {name, id} <- @categories do %>
                        <option value={id} selected={id == @filter_category_id}>{name}</option>
                      <% end %>
                    </select>
                  </div>
                  
    <!-- Date Range -->
                  <div>
                    <label
                      for="filters_date_from"
                      class="block text-sm font-medium leading-6 text-zinc-800"
                    >
                      From Date
                    </label>
                    <input
                      type="date"
                      id="filters_date_from"
                      name="date_from"
                      value={@filter_date_from}
                      class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400"
                    />
                  </div>
                  <div>
                    <label
                      for="filters_date_to"
                      class="block text-sm font-medium leading-6 text-zinc-800"
                    >
                      To Date
                    </label>
                    <input
                      type="date"
                      id="filters_date_to"
                      name="date_to"
                      value={@filter_date_to}
                      class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400"
                    />
                  </div>
                  
    <!-- Amount Range -->
                  <div>
                    <label
                      for="filters_amount_min"
                      class="block text-sm font-medium leading-6 text-zinc-800"
                    >
                      Min Amount
                    </label>
                    <input
                      type="number"
                      id="filters_amount_min"
                      name="amount_min"
                      value={@filter_amount_min}
                      placeholder="0.00"
                      step="0.01"
                      min="0"
                      class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400"
                    />
                  </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mt-4">
                  <div>
                    <label
                      for="filters_amount_max"
                      class="block text-sm font-medium leading-6 text-zinc-800"
                    >
                      Max Amount
                    </label>
                    <input
                      type="number"
                      id="filters_amount_max"
                      name="amount_max"
                      value={@filter_amount_max}
                      placeholder="0.00"
                      step="0.01"
                      min="0"
                      class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400"
                    />
                  </div>
                  <div class="flex items-end">
                    <button
                      type="button"
                      phx-click="clear_filters"
                      class="w-full px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    >
                      Clear All
                    </button>
                  </div>
                </div>
              </form>
            </div>
          <% end %>
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

    <!-- Form Modal -->
    <.live_component
      :if={@show_form}
      module={FormComponent}
      id="expense-form"
      action={@form_action}
      expense={@selected_expense}
    />
    """
  end

  # Private functions

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:show_form, false)
    |> assign(:form_action, nil)
    |> assign(:selected_expense, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:show_form, true)
    |> assign(:form_action, :new)
    |> assign(:selected_expense, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    expense =
      case Enum.find(socket.assigns.expenses, &(&1.id == id)) do
        nil ->
          # Load expense if not in current list
          case Expense.get_by_id(id) do
            {:ok, expense} -> expense
            _ -> nil
          end

        expense ->
          expense
      end

    socket
    |> assign(:show_form, true)
    |> assign(:form_action, :edit)
    |> assign(:selected_expense, expense)
  end

  defp load_expenses(socket) do
    socket = assign(socket, :loading, true)

    try do
      # Load all expenses with category and account preloaded
      all_expenses =
        Expense
        |> Ash.Query.for_read(:read)
        |> Ash.Query.load([:category, :account])
        |> Ash.read!()

      # Apply client-side filters
      filtered_expenses = apply_client_filters(all_expenses, socket.assigns)

      # Apply sorting
      expenses = apply_sorting(filtered_expenses, socket.assigns.sort_by, socket.assigns.sort_dir)

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

  defp apply_client_filters(expenses, assigns) do
    expenses
    |> apply_search_filter(assigns.search_query)
    |> apply_category_filter(assigns.filter_category_id)
    |> apply_date_range_filter(assigns.filter_date_from, assigns.filter_date_to)
    |> apply_amount_range_filter(assigns.filter_amount_min, assigns.filter_amount_max)
  end

  defp apply_search_filter(expenses, "") do
    expenses
  end

  defp apply_search_filter(expenses, search_query) when is_binary(search_query) do
    search_term = String.trim(search_query) |> String.downcase()

    if search_term != "" do
      Enum.filter(expenses, fn expense ->
        description_match =
          (expense.description || "")
          |> String.downcase()
          |> String.contains?(search_term)

        merchant_match =
          (expense.merchant || "")
          |> String.downcase()
          |> String.contains?(search_term)

        description_match || merchant_match
      end)
    else
      expenses
    end
  end

  defp apply_category_filter(expenses, "") do
    expenses
  end

  defp apply_category_filter(expenses, category_id) when is_binary(category_id) do
    Enum.filter(expenses, fn expense ->
      expense.category_id == category_id
    end)
  end

  defp apply_date_range_filter(expenses, date_from, date_to) do
    expenses
    |> apply_date_from_filter(date_from)
    |> apply_date_to_filter(date_to)
  end

  defp apply_date_from_filter(expenses, "") do
    expenses
  end

  defp apply_date_from_filter(expenses, date_from) when is_binary(date_from) do
    case Date.from_iso8601(date_from) do
      {:ok, date} ->
        Enum.filter(expenses, fn expense ->
          Date.compare(expense.date, date) != :lt
        end)

      _ ->
        expenses
    end
  end

  defp apply_date_to_filter(expenses, "") do
    expenses
  end

  defp apply_date_to_filter(expenses, date_to) when is_binary(date_to) do
    case Date.from_iso8601(date_to) do
      {:ok, date} ->
        Enum.filter(expenses, fn expense ->
          Date.compare(expense.date, date) != :gt
        end)

      _ ->
        expenses
    end
  end

  defp apply_amount_range_filter(expenses, amount_min, amount_max) do
    expenses
    |> apply_amount_min_filter(amount_min)
    |> apply_amount_max_filter(amount_max)
  end

  defp apply_amount_min_filter(expenses, "") do
    expenses
  end

  defp apply_amount_min_filter(expenses, amount_min) when is_binary(amount_min) do
    case Decimal.parse(amount_min) do
      {decimal, ""} ->
        Enum.filter(expenses, fn expense ->
          Decimal.compare(expense.amount, decimal) != :lt
        end)

      _ ->
        expenses
    end
  end

  defp apply_amount_max_filter(expenses, "") do
    expenses
  end

  defp apply_amount_max_filter(expenses, amount_max) when is_binary(amount_max) do
    case Decimal.parse(amount_max) do
      {decimal, ""} ->
        Enum.filter(expenses, fn expense ->
          Decimal.compare(expense.amount, decimal) != :gt
        end)

      _ ->
        expenses
    end
  end

  defp apply_sorting(expenses, sort_by, sort_dir) do
    expenses
    |> Enum.sort_by(
      fn expense ->
        case sort_by do
          :date ->
            expense.date

          :amount ->
            expense.amount

          :description ->
            expense.description || ""

          :category ->
            if expense.category do
              expense.category.name
            else
              ""
            end

          _ ->
            expense.date
        end
      end,
      sort_dir
    )
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

  @impl true
  def handle_info({FormComponent, {:saved, expense}}, socket) do
    case socket.assigns.form_action do
      :new ->
        {:noreply,
         socket
         |> assign(:show_form, false)
         |> load_expenses()
         |> ErrorHelpers.put_success_flash(
           "Expense \"#{expense.description}\" created successfully"
         )
         |> push_patch(to: ~p"/expenses")}

      :edit ->
        {:noreply,
         socket
         |> assign(:show_form, false)
         |> load_expenses()
         |> ErrorHelpers.put_success_flash(
           "Expense \"#{expense.description}\" updated successfully"
         )
         |> push_patch(to: ~p"/expenses")}
    end
  end

  @impl true
  def handle_info({FormComponent, :cancelled}, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> push_patch(to: ~p"/expenses")}
  end

  defp load_categories do
    TransactionCategory
    |> Ash.Query.for_read(:read)
    |> Ash.Query.sort(:name)
    |> Ash.read!()
    |> Enum.map(&{&1.name, &1.id})
  end
end
