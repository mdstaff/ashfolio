defmodule AshfolioWeb.Components.TransactionFilter do
  @moduledoc """
  Comprehensive transaction filtering component with multiple filter types.

  Provides a unified interface for filtering transactions by category, type,
  date range, and amount range. Supports real-time filtering with debouncing,
  responsive design, and accessibility compliance.

  Features:
  - Category filtering with color-coded options
  - Transaction type filtering (buy, sell, dividend, etc.)
  - Date range filtering with calendar inputs
  - Amount range filtering with numeric inputs
  - Clear filters functionality
  - Filter summary and active filter indicators
  - Responsive design for mobile/desktop
  - WCAG 2.1 AA accessibility compliance
  - Debounced input handling for performance
  """

  use Phoenix.Component
  # import AshfolioWeb.CoreComponents

  @doc """
  Renders a comprehensive transaction filter form.

  ## Examples

      <.transaction_filter
        categories={@categories}
        filters={@filters}
        target={@myself} />

      <.transaction_filter
        categories={@categories}
        filters={@filters}
        target={@myself}
        debounce={300}
        show_filter_summary={true}
        class="custom-filter-styling" />

  ## Attributes

  * `categories` - List of category maps with id, name, and color (required)
  * `filters` - Current filter state map (required)
  * `target` - Phoenix LiveView target for events (required)
  * `debounce` - Debounce delay in milliseconds for text inputs (default: 300)
  * `show_filter_summary` - Whether to show active filter summary (default: true)
  * `class` - Additional CSS classes
  * `compact` - Compact layout for smaller spaces (default: false)
  """
  attr :categories, :list, required: true, doc: "List of categories for filtering"
  attr :filters, :map, required: true, doc: "Current filter state"
  attr :target, :any, default: nil, doc: "Phoenix LiveView target"
  attr :debounce, :integer, default: 300, doc: "Debounce delay for inputs"
  attr :show_filter_summary, :boolean, default: true, doc: "Show filter summary"
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :compact, :boolean, default: false, doc: "Compact layout mode"
  attr :rest, :global, doc: "Additional HTML attributes"

  def transaction_filter(assigns) do
    assigns = assign_computed_values(assigns)

    ~H"""
    <div
      class={[
        "bg-white rounded-lg shadow-sm border border-gray-200",
        (@compact && "p-3") || "p-4",
        @class
      ]}
      role="search"
      aria-label="Filter transactions"
      {@rest}
    >
      <!-- Filter Header with Summary -->
      <div :if={@show_filter_summary} class="flex items-center justify-between mb-4">
        <div class="flex items-center gap-2">
          <h3 class="text-sm font-medium text-gray-900">Filter Transactions</h3>
          <span
            :if={@active_filter_count > 0}
            class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
          >
            {@active_filter_count} active
          </span>
        </div>

        <button
          :if={@has_active_filters}
          type="button"
          phx-click="clear_filters"
          phx-target={@target && @target}
          class="text-sm text-gray-500 hover:text-gray-700 underline focus:outline-none focus:ring-2 focus:ring-blue-500 rounded"
          data-testid="clear-filters-btn"
        >
          Clear Filters
        </button>
      </div>
      
    <!-- Filter Form -->
      <form
        id="composite-filter-form"
        phx-change="apply_composite_filters"
        phx-target={@target && @target}
        class="space-y-4"
      >
        <div class={[
          "grid gap-4",
          (@compact && "grid-cols-1 md:grid-cols-2") || "grid-cols-1 md:grid-cols-2 lg:grid-cols-4"
        ]}>
          
    <!-- Category Filter -->
          <div class="space-y-2">
            <label for="category-filter" class="block text-sm font-medium text-gray-700">
              Category
            </label>
            <select
              id="category-filter"
              name="category_id"
              value={@filters[:category] || ""}
              class={[
                "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
                filter_active_class(@filters[:category])
              ]}
              aria-describedby="category-filter-help"
            >
              <option value="">All Categories</option>
              <option value="uncategorized" selected={@filters[:category] == :uncategorized}>
                Uncategorized
              </option>
              <%= for category <- @categories do %>
                <option value={category.id} selected={@filters[:category] == category.id}>
                  {category.name}
                </option>
              <% end %>
            </select>
            <p id="category-filter-help" class="text-xs text-gray-500">
              Filter by investment category
            </p>
          </div>
          
    <!-- Transaction Type Filter -->
          <div class="space-y-2">
            <label for="type-filter" class="block text-sm font-medium text-gray-700">
              Transaction Type
            </label>
            <select
              id="type-filter"
              name="transaction_type"
              value={@filters[:transaction_type] || ""}
              class={[
                "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
                filter_active_class(@filters[:transaction_type])
              ]}
              aria-describedby="type-filter-help"
            >
              <option value="">All Types</option>
              <option value="buy" selected={@filters[:transaction_type] == :buy}>Buy</option>
              <option value="sell" selected={@filters[:transaction_type] == :sell}>Sell</option>
              <option value="dividend" selected={@filters[:transaction_type] == :dividend}>
                Dividend
              </option>
              <option value="split" selected={@filters[:transaction_type] == :split}>Split</option>
              <option value="transfer" selected={@filters[:transaction_type] == :transfer}>
                Transfer
              </option>
            </select>
            <p id="type-filter-help" class="text-xs text-gray-500">
              Filter by transaction type
            </p>
          </div>
          
    <!-- Date Range Filters -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-700">Date Range</label>
            <div class="grid grid-cols-2 gap-2">
              <div>
                <input
                  type="date"
                  name="date_from"
                  value={format_date_for_input(@filters[:date_range], :from)}
                  phx-debounce={@debounce}
                  class={[
                    "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
                    filter_active_class(@filters[:date_range])
                  ]}
                  placeholder="From date"
                  aria-label="Filter from date"
                />
              </div>
              <div>
                <input
                  type="date"
                  name="date_to"
                  value={format_date_for_input(@filters[:date_range], :to)}
                  phx-debounce={@debounce}
                  class={[
                    "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
                    filter_active_class(@filters[:date_range])
                  ]}
                  placeholder="To date"
                  aria-label="Filter to date"
                />
              </div>
            </div>
            <p class="text-xs text-gray-500">Filter by date range</p>
          </div>
          
    <!-- Amount Range Filters -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-700">Amount Range</label>
            <div class="grid grid-cols-2 gap-2">
              <div>
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  name="amount_min"
                  value={format_amount_for_input(@filters[:amount_range], :min)}
                  phx-debounce={@debounce}
                  class={[
                    "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
                    filter_active_class(@filters[:amount_range])
                  ]}
                  placeholder="Min amount"
                  aria-label="Filter minimum amount"
                />
              </div>
              <div>
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  name="amount_max"
                  value={format_amount_for_input(@filters[:amount_range], :max)}
                  phx-debounce={@debounce}
                  class={[
                    "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
                    filter_active_class(@filters[:amount_range])
                  ]}
                  placeholder="Max amount"
                  aria-label="Filter maximum amount"
                />
              </div>
            </div>
            <p class="text-xs text-gray-500">Filter by amount range ($)</p>
          </div>
        </div>
        
    <!-- Active Filters Summary (Mobile) -->
        <div :if={@has_active_filters && @compact} class="mt-4 p-3 bg-blue-50 rounded-md md:hidden">
          <div class="flex items-center justify-between">
            <span class="text-sm text-blue-700">
              {@active_filter_count} filter{if @active_filter_count != 1, do: "s"} active
            </span>
            <button
              type="button"
              phx-click="clear_filters"
              phx-target={@target && @target}
              class="text-sm text-blue-600 hover:text-blue-800 underline"
            >
              Clear All
            </button>
          </div>
        </div>
      </form>
    </div>
    """
  end

  # Private helper functions

  defp assign_computed_values(assigns) do
    active_filter_count = count_active_filters(assigns.filters)
    has_active_filters = active_filter_count > 0

    assigns
    |> assign(:active_filter_count, active_filter_count)
    |> assign(:has_active_filters, has_active_filters)
  end

  defp count_active_filters(filters) do
    Enum.count(filters, fn {_key, value} ->
      case value do
        nil -> false
        :all -> false
        "" -> false
        [] -> false
        %{} when map_size(value) == 0 -> false
        _ -> true
      end
    end)
  end

  defp filter_active_class(value) do
    case value do
      nil -> ""
      :all -> ""
      "" -> ""
      [] -> ""
      %{} when map_size(value) == 0 -> ""
      _ -> "ring-2 ring-blue-500 border-blue-500"
    end
  end

  defp format_date_for_input(nil, _position), do: ""

  defp format_date_for_input({from_date, _to_date}, :from) when not is_nil(from_date) do
    Date.to_iso8601(from_date)
  end

  defp format_date_for_input({_from_date, to_date}, :to) when not is_nil(to_date) do
    Date.to_iso8601(to_date)
  end

  defp format_date_for_input(_, _), do: ""

  defp format_amount_for_input(nil, _position), do: ""

  defp format_amount_for_input({min_amount, _max_amount}, :min) when not is_nil(min_amount) do
    Decimal.to_string(min_amount)
  end

  defp format_amount_for_input({_min_amount, max_amount}, :max) when not is_nil(max_amount) do
    Decimal.to_string(max_amount)
  end

  defp format_amount_for_input(_, _), do: ""
end
