defmodule AshfolioWeb.ExpenseLive.Analytics do
  use AshfolioWeb, :live_view

  alias Ashfolio.FinancialManagement.Expense
  alias AshfolioWeb.Live.FormatHelpers
  alias Contex.{Dataset, Plot, PieChart}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_current_page(:expenses)
      |> assign(:page_title, "Expense Analytics")
      |> assign(:page_subtitle, "Visualize your spending patterns")
      |> assign(:expenses, [])
      |> assign(:category_data, [])
      |> assign(:total_expenses, Decimal.new(0))
      |> assign(:expense_count, 0)
      |> assign(:loading, true)
      |> assign(:date_range, "current_month")
      |> assign(:chart_svg, nil)

    socket = load_analytics_data(socket)

    {:ok, socket}
  end

  @impl true
  def handle_event("change_date_range", %{"range" => range}, socket) do
    {:noreply,
     socket
     |> assign(:date_range, range)
     |> load_analytics_data()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Expense Analytics</h1>
          <p class="text-gray-600">Visualize your spending patterns</p>
        </div>
        <.link
          navigate={~p"/expenses"}
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
          Back to Expenses
        </.link>
      </div>
      
    <!-- Date Range Controls -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Time Period</h3>
          <div class="flex flex-wrap gap-2">
            <button
              phx-click="change_date_range"
              phx-value-range="current_month"
              class={[
                "px-4 py-2 text-sm font-medium rounded-md border",
                if(@date_range == "current_month",
                  do: "bg-blue-50 text-blue-700 border-blue-300",
                  else: "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                )
              ]}
            >
              This Month
            </button>
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
                {FormatHelpers.format_currency(@total_expenses)}
              </div>
              <div class="text-sm text-gray-500">Total Expenses</div>
            </div>
            <div class="text-center">
              <div class="text-3xl font-bold text-blue-600">
                {@expense_count} expenses
              </div>
              <div class="text-sm text-gray-500">{format_date_range(@date_range)}</div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Chart Section -->
      <%= if @loading do %>
        <div class="bg-white shadow rounded-lg">
          <div class="text-center py-16 px-6">
            <.loading_spinner class="mx-auto w-8 h-8 text-blue-600 mb-4" />
            <p class="text-gray-500">Loading analytics...</p>
          </div>
        </div>
      <% else %>
        <%= if Enum.empty?(@category_data) do %>
          <!-- Empty State -->
          <div class="bg-white shadow rounded-lg">
            <div class="text-center py-16 px-6">
              <div class="mx-auto h-16 w-16 text-gray-400 mb-4">
                <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-full h-full">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                  />
                </svg>
              </div>
              <h3 class="text-lg font-medium text-gray-900 mb-2">No expenses to display</h3>
              <p class="text-gray-500 mb-6 max-w-sm mx-auto">
                Add your first expense to see analytics and spending patterns.
              </p>
              <.link
                navigate={~p"/expenses/new"}
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
          <!-- Pie Chart -->
          <div class="bg-white shadow rounded-lg">
            <div class="px-6 py-4 border-b border-gray-200">
              <h3 class="text-lg font-medium text-gray-900">Expenses by Category</h3>
            </div>
            <div class="p-6">
              <div class="flex flex-col lg:flex-row gap-8">
                <!-- Chart -->
                <div class="flex-1">
                  <%= if @chart_svg do %>
                    <div class="flex justify-center">
                      {Phoenix.HTML.raw(@chart_svg)}
                    </div>
                  <% end %>
                </div>
                
    <!-- Legend -->
                <div class="lg:w-80">
                  <h4 class="text-sm font-medium text-gray-900 mb-3">Category Breakdown</h4>
                  <div class="space-y-3">
                    <%= for {category_name, amount, percentage, color} <- @category_data do %>
                      <div class="flex items-center justify-between">
                        <div class="flex items-center">
                          <div
                            class="w-3 h-3 rounded-full mr-3"
                            style={"background-color: #{color}"}
                          >
                          </div>
                          <span class="text-sm text-gray-900">{category_name}</span>
                        </div>
                        <div class="text-right">
                          <div class="text-sm font-medium text-gray-900">
                            {FormatHelpers.format_currency(amount)}
                          </div>
                          <div class="text-xs text-gray-500">
                            {Float.round(percentage, 1)}%
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  # Private functions

  defp load_analytics_data(socket) do
    socket = assign(socket, :loading, true)

    try do
      # Load all expenses with category preloaded
      all_expenses =
        Expense
        |> Ash.Query.for_read(:read)
        |> Ash.Query.load([:category])
        |> Ash.read!()

      # Filter by date range
      filtered_expenses = filter_by_date_range(all_expenses, socket.assigns.date_range)

      # Calculate category data
      category_data = calculate_category_data(filtered_expenses)

      # Generate chart
      chart_svg = generate_pie_chart(category_data)

      # Calculate statistics
      total_expenses = calculate_total_expenses(filtered_expenses)
      expense_count = length(filtered_expenses)

      socket
      |> assign(:expenses, filtered_expenses)
      |> assign(:category_data, category_data)
      |> assign(:total_expenses, total_expenses)
      |> assign(:expense_count, expense_count)
      |> assign(:chart_svg, chart_svg)
      |> assign(:loading, false)
    rescue
      error ->
        socket
        |> assign(:loading, false)
        |> put_flash(:error, "Failed to load analytics: #{inspect(error)}")
    end
  end

  defp filter_by_date_range(expenses, "current_month") do
    start_date = Date.beginning_of_month(Date.utc_today())
    Enum.filter(expenses, &(Date.compare(&1.date, start_date) != :lt))
  end

  defp filter_by_date_range(expenses, "last_month") do
    today = Date.utc_today()
    start_date = today |> Date.beginning_of_month() |> Date.add(-1) |> Date.beginning_of_month()
    end_date = Date.end_of_month(start_date)

    Enum.filter(expenses, fn expense ->
      Date.compare(expense.date, start_date) != :lt && Date.compare(expense.date, end_date) != :gt
    end)
  end

  defp filter_by_date_range(expenses, "last_3_months") do
    start_date = Date.utc_today() |> Date.add(-90)
    Enum.filter(expenses, &(Date.compare(&1.date, start_date) != :lt))
  end

  defp filter_by_date_range(expenses, "last_6_months") do
    start_date = Date.utc_today() |> Date.add(-180)
    Enum.filter(expenses, &(Date.compare(&1.date, start_date) != :lt))
  end

  defp filter_by_date_range(expenses, "all_time") do
    expenses
  end

  defp filter_by_date_range(expenses, _) do
    filter_by_date_range(expenses, "current_month")
  end

  defp calculate_category_data(expenses) do
    # Group by category and sum amounts
    category_totals =
      expenses
      |> Enum.group_by(fn expense ->
        if expense.category do
          {expense.category.name, expense.category.color}
        else
          {"Uncategorized", "#6B7280"}
        end
      end)
      |> Enum.map(fn {{name, color}, category_expenses} ->
        total = Enum.reduce(category_expenses, Decimal.new(0), &Decimal.add(&2, &1.amount))
        {name, total, color}
      end)
      |> Enum.sort_by(fn {_, total, _} -> Decimal.to_float(total) end, :desc)

    # Calculate total for percentages
    grand_total =
      category_totals
      |> Enum.reduce(Decimal.new(0), fn {_, total, _}, acc -> Decimal.add(acc, total) end)

    # Add percentages
    if Decimal.gt?(grand_total, 0) do
      Enum.map(category_totals, fn {name, amount, color} ->
        percentage = Decimal.div(amount, grand_total) |> Decimal.mult(100) |> Decimal.to_float()
        {name, amount, percentage, color}
      end)
    else
      []
    end
  end

  defp generate_pie_chart([]), do: nil

  defp generate_pie_chart(category_data) do
    # Convert data for Contex Dataset
    chart_data =
      Enum.map(category_data, fn {name, amount, _percentage, _color} ->
        [name, Decimal.to_float(amount)]
      end)

    # Extract colors in the same order (remove # prefix for Contex)
    colors =
      Enum.map(category_data, fn {_name, _amount, _percentage, color} ->
        String.replace(color, "#", "")
      end)

    try do
      # Create chart using Contex official API
      chart_data
      |> Dataset.new()
      |> Plot.new(PieChart, 400, 300)
      |> Plot.to_svg()
    rescue
      _error ->
        # Fallback to manual SVG if Contex fails
        total = Enum.reduce(chart_data, 0, fn [_, value], acc -> acc + value end)

        if total > 0 do
          generate_simple_pie_svg(chart_data, colors, total)
        else
          nil
        end
    end
  end

  defp generate_simple_pie_svg(data, colors, total) do
    radius = 150
    center_x = 200
    center_y = 150

    data_with_colors = Enum.zip(data, colors)

    {svg_slices, _} =
      Enum.reduce(data_with_colors, {"", 0}, fn {[_name, value], color}, {acc, current_angle} ->
        angle = value / total * 360
        end_angle = current_angle + angle

        # Simple pie slice path calculation
        start_x = center_x + radius * :math.cos(current_angle * :math.pi() / 180)
        start_y = center_y + radius * :math.sin(current_angle * :math.pi() / 180)
        end_x = center_x + radius * :math.cos(end_angle * :math.pi() / 180)
        end_y = center_y + radius * :math.sin(end_angle * :math.pi() / 180)

        large_arc = if angle > 180, do: 1, else: 0

        path =
          "M #{center_x} #{center_y} L #{start_x} #{start_y} A #{radius} #{radius} 0 #{large_arc} 1 #{end_x} #{end_y} Z"

        color_with_hash = if String.starts_with?(color, "#"), do: color, else: "##{color}"

        slice_svg = """
        <path d="#{path}" fill="#{color_with_hash}" stroke="white" stroke-width="2" />
        """

        {acc <> slice_svg, end_angle}
      end)

    """
    <svg class="contex-pie-chart" width="400" height="300" viewBox="0 0 400 300">
      #{svg_slices}
    </svg>
    """
  end

  defp calculate_total_expenses(expenses) do
    expenses
    |> Enum.reduce(Decimal.new(0), fn expense, acc ->
      Decimal.add(acc, expense.amount)
    end)
  end

  defp format_date_range("current_month"), do: "This Month"
  defp format_date_range("last_month"), do: "Last Month"
  defp format_date_range("last_3_months"), do: "Last 3 Months"
  defp format_date_range("last_6_months"), do: "Last 6 Months"
  defp format_date_range("all_time"), do: "All Time"
  defp format_date_range(_), do: "This Month"
end
