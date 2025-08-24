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
      |> assign(:all_expenses, [])
      |> assign(:category_data, [])
      |> assign(:total_expenses, Decimal.new(0))
      |> assign(:expense_count, 0)
      |> assign(:loading, true)
      |> assign(:date_range, "current_month")
      |> assign(:chart_svg, nil)
      |> assign(:year_over_year, nil)

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
  def handle_event("update_year_comparison", params, socket) do
    base_year = String.to_integer(params["base_year"] || "2024")
    compare_year = String.to_integer(params["compare_year"] || "2023")

    # Recalculate year-over-year with selected years
    year_over_year =
      calculate_custom_year_comparison(socket.assigns.all_expenses, base_year, compare_year)

    {:noreply, assign(socket, :year_over_year, year_over_year)}
  end

  @impl true
  def handle_event("apply_advanced_filters", params, socket) do
    # Extract filter parameters
    category_filter = params["category_filter"]
    amount_range = params["amount_range"]
    merchant_filter = params["merchant_filter"]

    # Apply filters to all expenses
    filtered_expenses =
      apply_filters(socket.assigns.all_expenses, category_filter, amount_range, merchant_filter)

    # Recalculate analytics data with filtered expenses
    category_data = calculate_category_data(filtered_expenses)
    total_expenses = Enum.reduce(filtered_expenses, Decimal.new(0), &Decimal.add(&2, &1.amount))
    expense_count = length(filtered_expenses)

    socket =
      assign(socket,
        expenses: filtered_expenses,
        category_data: category_data,
        total_expenses: total_expenses,
        expense_count: expense_count
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("apply_date_range", params, socket) do
    # Extract date parameters
    start_date_string = params["start_date"]
    end_date_string = params["end_date"]

    # Parse dates (skip if empty or invalid)
    with {:ok, start_date} <- Date.from_iso8601(start_date_string),
         {:ok, end_date} <- Date.from_iso8601(end_date_string) do
      # Filter expenses by custom date range
      filtered_expenses =
        socket.assigns.all_expenses
        |> Enum.filter(fn expense ->
          Date.compare(expense.date, start_date) != :lt and
            Date.compare(expense.date, end_date) != :gt
        end)

      # Recalculate analytics data with filtered expenses
      category_data = calculate_category_data(filtered_expenses)
      total_expenses = Enum.reduce(filtered_expenses, Decimal.new(0), &Decimal.add(&2, &1.amount))
      expense_count = length(filtered_expenses)

      socket =
        assign(socket,
          expenses: filtered_expenses,
          category_data: category_data,
          total_expenses: total_expenses,
          expense_count: expense_count
        )

      {:noreply, socket}
    else
      _ ->
        # Invalid date format, don't filter
        {:noreply, socket}
    end
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
      
    <!-- Year-over-Year Analysis -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Year-over-Year Analysis</h3>
          
    <!-- Year Selection Controls -->
          <.form for={%{}} phx-change="update_year_comparison" id="year-comparison-form" class="mb-4">
            <div class="flex gap-3">
              <div class="flex items-center gap-2">
                <label class="text-sm font-medium text-gray-700">Compare:</label>
                <select name="base_year" class="text-sm border-gray-300 rounded-md">
                  <%= for year <- get_available_years(@all_expenses) do %>
                    <option
                      value={year}
                      selected={year == (@year_over_year[:current_year] || Date.utc_today().year)}
                    >
                      {year}
                    </option>
                  <% end %>
                </select>
              </div>
              <div class="flex items-center gap-2">
                <label class="text-sm text-gray-500">vs</label>
                <select name="compare_year" class="text-sm border-gray-300 rounded-md">
                  <%= for year <- get_available_years(@all_expenses) do %>
                    <option
                      value={year}
                      selected={
                        year == (@year_over_year[:previous_year] || Date.utc_today().year - 1)
                      }
                    >
                      {year}
                    </option>
                  <% end %>
                </select>
              </div>
            </div>
          </.form>

          <%= if @year_over_year do %>
            <p class="text-sm text-gray-600">
              {@year_over_year.current_year} vs {@year_over_year.previous_year}
            </p>
            <%= if @year_over_year.percentage_change do %>
              <div class="mt-3">
                <div class="flex items-center space-x-2">
                  <span class={[
                    "text-lg font-semibold",
                    if(@year_over_year.trend == :increase, do: "text-green-600", else: "text-red-600")
                  ]}>
                    {if @year_over_year.trend == :increase, do: "+", else: ""}{@year_over_year.percentage_change}%
                  </span>
                  <span class="text-sm text-gray-500">
                    {if @year_over_year.trend == :increase,
                      do: "increase from last year",
                      else: "decrease from last year"}
                  </span>
                </div>
                
    <!-- Year Comparison Chart -->
                <div class="mt-4 chart-container responsive">
                  {generate_year_comparison_chart(@year_over_year)}
                </div>
              </div>
            <% end %>
          <% else %>
            <p class="text-sm text-gray-600">2024 vs 2023</p>
          <% end %>
        </div>
      </div>
      
    <!-- Spending Trends Analysis -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Spending Trends</h3>
          <p class="text-sm text-gray-600 mb-4">Monthly Trend Analysis</p>
          
    <!-- Trend Indicators -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="text-center p-4 border rounded-lg">
              <div class="trend-indicator">
                <span class="text-sm text-gray-500">Last 3 Months</span>
                <div class="text-lg font-semibold text-gray-600 mt-1">
                  Calculating...
                </div>
              </div>
            </div>
            <div class="text-center p-4 border rounded-lg">
              <div class="trend-indicator">
                <span class="text-sm text-gray-500">Last 6 Months</span>
                <div class="text-lg font-semibold text-gray-600 mt-1">
                  Calculating...
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Advanced Filters -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Advanced Filters</h3>

          <.form for={%{}} phx-change="apply_advanced_filters" id="advanced-filters" class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <!-- Category Filter -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Category</label>
                <select name="category_filter" class="w-full border-gray-300 rounded-md text-sm">
                  <option value="">All Categories</option>
                  <%= for category <- get_available_categories(@all_expenses) do %>
                    <option value={String.downcase(category)}>{category}</option>
                  <% end %>
                </select>
              </div>
              
    <!-- Amount Range Filter -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Amount Range</label>
                <select name="amount_range" class="w-full border-gray-300 rounded-md text-sm">
                  <option value="">All Amounts</option>
                  <option value="0-50">$0 - $50</option>
                  <option value="50-100">$50 - $100</option>
                  <option value="100-500">$100 - $500</option>
                  <option value="500+">$500+</option>
                </select>
              </div>
              
    <!-- Merchant Filter -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Merchant/Description
                </label>
                <input
                  type="text"
                  name="merchant_filter"
                  placeholder="Search merchant..."
                  class="w-full border-gray-300 rounded-md text-sm"
                />
              </div>
            </div>
          </.form>
        </div>
      </div>
      
    <!-- Custom Date Range -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Custom Date Range</h3>

          <.form for={%{}} phx-change="apply_date_range" id="date-range-form" class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Start Date</label>
                <input
                  type="date"
                  name="start_date"
                  class="w-full border-gray-300 rounded-md text-sm"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">End Date</label>
                <input
                  type="date"
                  name="end_date"
                  class="w-full border-gray-300 rounded-md text-sm"
                />
              </div>
            </div>
          </.form>
          
    <!-- Show filtered expenses summary -->
          <%= if @expenses != [] do %>
            <div class="mt-4 pt-4 border-t">
              <p class="text-sm text-gray-600 mb-2">
                Filtered Results ({length(@expenses)} expenses)
              </p>
              <div class="space-y-1">
                <%= for expense <- Enum.take(@expenses, 3) do %>
                  <div class="text-sm">
                    <span class="text-gray-900">{expense.description}</span>
                    <span class="text-gray-500 ml-2">${expense.amount}</span>
                  </div>
                <% end %>
                <%= if length(@expenses) > 3 do %>
                  <p class="text-xs text-gray-500">...and {length(@expenses) - 3} more</p>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
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

      # Calculate year-over-year comparison
      year_over_year = calculate_year_over_year(all_expenses)

      socket
      |> assign(:expenses, filtered_expenses)
      |> assign(:all_expenses, all_expenses)
      |> assign(:category_data, category_data)
      |> assign(:total_expenses, total_expenses)
      |> assign(:expense_count, expense_count)
      |> assign(:chart_svg, chart_svg)
      |> assign(:year_over_year, year_over_year)
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

  defp get_available_years(expenses) do
    expenses
    |> Enum.map(fn expense -> expense.date.year end)
    |> Enum.uniq()
    |> Enum.sort(:desc)
  end

  defp get_available_categories(expenses) do
    expenses
    |> Enum.map(fn expense ->
      if expense.category, do: expense.category.name, else: "Uncategorized"
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp calculate_custom_year_comparison(all_expenses, current_year, previous_year) do
    current_year_expenses =
      all_expenses
      |> Enum.filter(fn expense -> expense.date.year == current_year end)
      |> calculate_total_expenses()

    previous_year_expenses =
      all_expenses
      |> Enum.filter(fn expense -> expense.date.year == previous_year end)
      |> calculate_total_expenses()

    case Decimal.compare(previous_year_expenses, Decimal.new(0)) do
      :eq ->
        %{
          current_year: current_year,
          previous_year: previous_year,
          current_total: current_year_expenses,
          previous_total: previous_year_expenses,
          percentage_change: nil,
          trend: :no_data
        }

      _ ->
        # Calculate percentage change: ((current - previous) / previous) * 100
        difference = Decimal.sub(current_year_expenses, previous_year_expenses)

        percentage_change =
          difference
          |> Decimal.div(previous_year_expenses)
          |> Decimal.mult(Decimal.new(100))
          |> Decimal.round(1)

        trend =
          if Decimal.compare(percentage_change, Decimal.new(0)) == :gt,
            do: :increase,
            else: :decrease

        %{
          current_year: current_year,
          previous_year: previous_year,
          current_total: current_year_expenses,
          previous_total: previous_year_expenses,
          percentage_change: percentage_change,
          trend: trend
        }
    end
  end

  defp calculate_year_over_year(all_expenses) do
    # Get all years that have expenses, sorted in descending order
    years_with_data =
      all_expenses
      |> Enum.map(fn expense -> expense.date.year end)
      |> Enum.uniq()
      |> Enum.sort(:desc)

    case years_with_data do
      [current_year, previous_year | _] ->
        current_year_expenses =
          all_expenses
          |> Enum.filter(fn expense -> expense.date.year == current_year end)
          |> calculate_total_expenses()

        previous_year_expenses =
          all_expenses
          |> Enum.filter(fn expense -> expense.date.year == previous_year end)
          |> calculate_total_expenses()

        case Decimal.compare(previous_year_expenses, Decimal.new(0)) do
          :eq ->
            %{
              current_year: current_year,
              previous_year: previous_year,
              current_total: current_year_expenses,
              previous_total: previous_year_expenses,
              percentage_change: nil,
              trend: :no_data
            }

          _ ->
            # Calculate percentage change: ((current - previous) / previous) * 100
            difference = Decimal.sub(current_year_expenses, previous_year_expenses)

            percentage_change =
              difference
              |> Decimal.div(previous_year_expenses)
              |> Decimal.mult(Decimal.new(100))
              |> Decimal.round(1)

            trend =
              if Decimal.compare(percentage_change, Decimal.new(0)) == :gt,
                do: :increase,
                else: :decrease

            %{
              current_year: current_year,
              previous_year: previous_year,
              current_total: current_year_expenses,
              previous_total: previous_year_expenses,
              percentage_change: percentage_change,
              trend: trend
            }
        end

      _ ->
        # Not enough data for comparison
        %{
          current_year: nil,
          previous_year: nil,
          current_total: Decimal.new(0),
          previous_total: Decimal.new(0),
          percentage_change: nil,
          trend: :no_data
        }
    end
  end

  defp generate_year_comparison_chart(year_over_year) do
    case year_over_year do
      %{
        current_year: current_year,
        previous_year: previous_year,
        current_total: current_total,
        previous_total: previous_total
      }
      when not is_nil(current_year) and not is_nil(previous_year) ->
        # Convert Decimal to float for Contex
        current_amount = Decimal.to_float(current_total)
        previous_amount = Decimal.to_float(previous_total)

        # Generate simple SVG bar chart (chart_data available for future Contex integration)

        # Generate simple SVG bar chart
        """
        <svg class="year-comparison-chart" width="300" height="150" viewBox="0 0 300 150">
          <!-- Previous Year Bar -->
          <rect x="50" y="#{120 - previous_amount / 200}" width="60" height="#{previous_amount / 200}" fill="#94a3b8" />
          <text x="80" y="140" text-anchor="middle" class="text-xs">#{previous_year}</text>
          
          <!-- Current Year Bar -->
          <rect x="150" y="#{120 - current_amount / 200}" width="60" height="#{current_amount / 200}" fill="#3b82f6" />
          <text x="180" y="140" text-anchor="middle" class="text-xs">#{current_year}</text>
          
          <!-- Labels -->
          <text x="80" y="#{110 - previous_amount / 200}" text-anchor="middle" class="text-xs">$#{:erlang.float_to_binary(previous_amount, decimals: 0)}</text>
          <text x="180" y="#{110 - current_amount / 200}" text-anchor="middle" class="text-xs">$#{:erlang.float_to_binary(current_amount, decimals: 0)}</text>
        </svg>
        """
        |> Phoenix.HTML.raw()

      _ ->
        Phoenix.HTML.raw("""
        <div class="text-sm text-gray-500">
          Insufficient data for year comparison chart
        </div>
        """)
    end
  end

  defp apply_filters(expenses, category_filter, amount_range, merchant_filter) do
    expenses
    |> filter_by_category(category_filter)
    |> filter_by_amount_range(amount_range)
    |> filter_by_merchant(merchant_filter)
  end

  defp filter_by_category(expenses, nil), do: expenses
  defp filter_by_category(expenses, ""), do: expenses

  defp filter_by_category(expenses, category_filter) do
    Enum.filter(expenses, fn expense ->
      expense.category &&
        String.downcase(expense.category.name) == String.downcase(category_filter)
    end)
  end

  defp filter_by_amount_range(expenses, nil), do: expenses
  defp filter_by_amount_range(expenses, ""), do: expenses

  defp filter_by_amount_range(expenses, amount_range) do
    case amount_range do
      "0-50" ->
        Enum.filter(expenses, fn exp -> Decimal.compare(exp.amount, Decimal.new("50")) != :gt end)

      "50-100" ->
        Enum.filter(expenses, fn exp ->
          Decimal.compare(exp.amount, Decimal.new("50")) == :gt and
            Decimal.compare(exp.amount, Decimal.new("100")) != :gt
        end)

      "100-500" ->
        Enum.filter(expenses, fn exp ->
          Decimal.compare(exp.amount, Decimal.new("100")) == :gt and
            Decimal.compare(exp.amount, Decimal.new("500")) != :gt
        end)

      "500+" ->
        Enum.filter(expenses, fn exp -> Decimal.compare(exp.amount, Decimal.new("500")) == :gt end)

      _ ->
        expenses
    end
  end

  defp filter_by_merchant(expenses, nil), do: expenses
  defp filter_by_merchant(expenses, ""), do: expenses

  defp filter_by_merchant(expenses, merchant_filter) do
    search_term = String.downcase(merchant_filter)

    Enum.filter(expenses, fn expense ->
      description_match =
        expense.description && String.contains?(String.downcase(expense.description), search_term)

      merchant_match =
        expense.merchant && String.contains?(String.downcase(expense.merchant), search_term)

      description_match || merchant_match
    end)
  end
end
