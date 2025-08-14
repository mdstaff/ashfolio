defmodule AshfolioWeb.Components.TransactionStats do
  @moduledoc """
  Transaction statistics and analytics component.

  Provides comprehensive analytics for filtered transaction sets including
  volume calculations, type breakdowns, time period analysis, and category
  distribution. Supports multiple display modes and real-time updates.

  Features:
  - Transaction count and volume calculations
  - Transaction type breakdown (buy/sell/dividend/etc.)
  - Category distribution analysis
  - Time period and trend analysis
  - Average transaction size calculations
  - Responsive design with compact mode
  - Performance optimized for large datasets
  - Accessibility compliant display
  """

  use Phoenix.Component

  @doc """
  Renders comprehensive transaction statistics and analytics.

  ## Examples

      <.transaction_stats transactions={@filtered_transactions} />
      
      <.transaction_stats 
        transactions={@transactions}
        show_breakdown={true}
        show_categories={true}
        show_time_analysis={true}
        compact={true} />

  ## Attributes

  * `transactions` - List of transactions for analysis (required)
  * `show_breakdown` - Show transaction type breakdown (default: false)
  * `show_categories` - Show category breakdown (default: false)
  * `show_averages` - Show average calculations (default: false)
  * `show_time_analysis` - Show time period analysis (default: false)
  * `show_volume_calculation` - Show volume calculation details (default: false)
  * `compact` - Compact layout for smaller spaces (default: false)
  * `class` - Additional CSS classes
  """
  attr :transactions, :list, required: true, doc: "List of transactions to analyze"
  attr :show_breakdown, :boolean, default: false, doc: "Show transaction type breakdown"
  attr :show_categories, :boolean, default: false, doc: "Show category breakdown"
  attr :show_averages, :boolean, default: false, doc: "Show average calculations"
  attr :show_time_analysis, :boolean, default: false, doc: "Show time period analysis"
  attr :show_volume_calculation, :boolean, default: false, doc: "Show volume calculation details"
  attr :compact, :boolean, default: false, doc: "Compact layout mode"
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :rest, :global, doc: "Additional HTML attributes"

  def transaction_stats(assigns) do
    assigns = assign_computed_values(assigns)

    ~H"""
    <div
      class={[
        "bg-white rounded-lg shadow-sm border border-gray-200",
        (@compact && "p-3") || "p-4",
        @class
      ]}
      role="region"
      aria-label="Transaction statistics"
      {@rest}
    >
      <%= if @stats.total_count == 0 do %>
        <!-- Empty State -->
        <div class="text-center py-6">
          <div class="text-gray-400 mb-2">
            <svg class="w-12 h-12 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
              />
            </svg>
          </div>
          <h3 class={[(@compact && "text-sm") || "text-base", "font-medium text-gray-900 mb-1"]}>
            No transactions
          </h3>
          <p class="text-sm text-gray-500">
            No transactions available for analysis
          </p>
        </div>
      <% else %>
        <!-- Statistics Content -->
        <div class="space-y-4">
          <!-- Header -->
          <div class="flex items-center justify-between">
            <h3 class={[(@compact && "text-sm") || "text-base", "font-medium text-gray-900"]}>
              Transaction Analysis
            </h3>
            <span class={[(@compact && "text-xs") || "text-sm", "text-gray-500"]}>
              {@stats.total_count} transaction{if @stats.total_count != 1, do: "s"}
            </span>
          </div>
          
    <!-- Key Metrics Grid -->
          <div class={[
            "grid gap-4",
            (@compact && "grid-cols-2") || "grid-cols-2 md:grid-cols-4"
          ]}>
            <!-- Total Volume -->
            <div class="text-center">
              <div class={[(@compact && "text-lg") || "text-xl", "font-semibold text-gray-900"]}>
                {@stats.formatted_total_volume}
              </div>
              <div class={[(@compact && "text-xs") || "text-sm", "text-gray-500"]}>
                Total Volume
              </div>
            </div>
            
    <!-- Average Transaction -->
            <div :if={@show_averages} class="text-center">
              <div class={[(@compact && "text-lg") || "text-xl", "font-semibold text-gray-900"]}>
                {@stats.formatted_average_size}
              </div>
              <div class={[(@compact && "text-xs") || "text-sm", "text-gray-500"]}>
                Average Size
              </div>
            </div>
            
    <!-- Time Period -->
            <div :if={@show_time_analysis} class="text-center">
              <div class={[(@compact && "text-lg") || "text-xl", "font-semibold text-gray-900"]}>
                {@stats.time_span_display}
              </div>
              <div class={[(@compact && "text-xs") || "text-sm", "text-gray-500"]}>
                Time Period
              </div>
            </div>
            
    <!-- Most Active Type -->
            <div :if={@show_breakdown} class="text-center">
              <div class={[(@compact && "text-lg") || "text-xl", "font-semibold text-gray-900"]}>
                {@stats.most_common_type}
              </div>
              <div class={[(@compact && "text-xs") || "text-sm", "text-gray-500"]}>
                Most Common
              </div>
            </div>
          </div>
          
    <!-- Transaction Type Breakdown -->
          <div :if={@show_breakdown && length(@stats.type_breakdown) > 1} class="space-y-2">
            <h4 class={[(@compact && "text-xs") || "text-sm", "font-medium text-gray-700"]}>
              Transaction Types
            </h4>
            <div class="space-y-1">
              <%= for {type, data} <- @stats.type_breakdown do %>
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <span class={[
                      "inline-block w-2 h-2 rounded-full",
                      type_color_class(type)
                    ]}>
                    </span>
                    <span class={[(@compact && "text-xs") || "text-sm", "text-gray-700"]}>
                      {String.capitalize(Atom.to_string(type))}
                    </span>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class={[(@compact && "text-xs") || "text-sm", "text-gray-500"]}>
                      {data.count}
                    </span>
                    <span class={[(@compact && "text-xs") || "text-sm", "font-medium text-gray-900"]}>
                      {data.percentage}%
                    </span>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Category Breakdown -->
          <div :if={@show_categories && length(@stats.category_breakdown) > 0} class="space-y-2">
            <h4 class={[(@compact && "text-xs") || "text-sm", "font-medium text-gray-700"]}>
              Categories
            </h4>
            <div class="space-y-1">
              <%= for category_data <- @stats.category_breakdown do %>
                <div class="flex items-center justify-between">
                  <span class={[(@compact && "text-xs") || "text-sm", "text-gray-700"]}>
                    {category_data.name}
                  </span>
                  <div class="flex items-center gap-2">
                    <span class={[(@compact && "text-xs") || "text-sm", "text-gray-500"]}>
                      {category_data.count}
                    </span>
                    <span class={[(@compact && "text-xs") || "text-sm", "font-medium text-gray-900"]}>
                      {category_data.formatted_amount}
                    </span>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Time Analysis -->
          <div :if={@show_time_analysis && @stats.date_range} class="space-y-2">
            <h4 class={[(@compact && "text-xs") || "text-sm", "font-medium text-gray-700"]}>
              Time Period
            </h4>
            <div class="flex items-center justify-between">
              <span class={[(@compact && "text-xs") || "text-sm", "text-gray-700"]}>
                From: {@stats.date_range.start_date}
              </span>
              <span class={[(@compact && "text-xs") || "text-sm", "text-gray-700"]}>
                To: {@stats.date_range.end_date}
              </span>
            </div>
            <div class="text-center">
              <span class={[(@compact && "text-xs") || "text-sm", "text-gray-500"]}>
                {@stats.date_range.day_count} days
              </span>
            </div>
          </div>
          
    <!-- Volume Calculation Details -->
          <div :if={@show_volume_calculation} class="space-y-2">
            <h4 class={[(@compact && "text-xs") || "text-sm", "font-medium text-gray-700"]}>
              Volume Calculation
            </h4>
            <div class="bg-gray-50 rounded p-2">
              <div class="text-center">
                <span class={[(@compact && "text-sm") || "text-base", "font-mono text-gray-700"]}>
                  {@stats.formatted_total_volume}
                </span>
              </div>
              <div class={[(@compact && "text-xs") || "text-sm", "text-gray-500 text-center mt-1"]}>
                Sum of all transaction amounts
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Private helper functions

  defp assign_computed_values(assigns) do
    stats = calculate_stats(assigns.transactions)
    assign(assigns, :stats, stats)
  end

  defp calculate_stats(transactions) do
    total_count = length(transactions)

    if total_count == 0 do
      %{
        total_count: 0,
        total_volume: Decimal.new(0),
        formatted_total_volume: "$0.00",
        average_size: Decimal.new(0),
        formatted_average_size: "$0.00",
        type_breakdown: [],
        category_breakdown: [],
        most_common_type: "None",
        time_span_display: "None",
        date_range: nil
      }
    else
      total_volume = calculate_total_volume(transactions)
      average_size = Decimal.div(total_volume, Decimal.new(total_count))
      type_breakdown = calculate_type_breakdown(transactions)
      category_breakdown = calculate_category_breakdown(transactions)
      most_common_type = get_most_common_type(type_breakdown)
      date_range = calculate_date_range(transactions)
      time_span_display = format_time_span(date_range)

      %{
        total_count: total_count,
        total_volume: total_volume,
        formatted_total_volume: format_currency(total_volume),
        average_size: average_size,
        formatted_average_size: format_currency(average_size),
        type_breakdown: type_breakdown,
        category_breakdown: category_breakdown,
        most_common_type: most_common_type,
        time_span_display: time_span_display,
        date_range: date_range
      }
    end
  end

  defp calculate_total_volume(transactions) do
    transactions
    |> Enum.reduce(Decimal.new(0), fn tx, acc ->
      amount = get_transaction_amount(tx)
      Decimal.add(acc, Decimal.abs(amount))
    end)
  end

  defp calculate_type_breakdown(transactions) do
    total_count = length(transactions)

    transactions
    |> Enum.group_by(fn tx -> get_transaction_type(tx) end)
    |> Enum.map(fn {type, txs} ->
      count = length(txs)
      percentage = Float.round(count / total_count * 100, 1)
      {type, %{count: count, percentage: percentage}}
    end)
    |> Enum.sort_by(fn {_type, data} -> data.count end, :desc)
  end

  defp calculate_category_breakdown(transactions) do
    transactions
    |> Enum.group_by(fn tx -> get_transaction_category_name(tx) end)
    |> Enum.map(fn {category_name, txs} ->
      count = length(txs)

      total_amount =
        txs
        |> Enum.reduce(Decimal.new(0), fn tx, acc ->
          amount = get_transaction_amount(tx)
          Decimal.add(acc, Decimal.abs(amount))
        end)

      %{
        name: category_name,
        count: count,
        total_amount: total_amount,
        formatted_amount: format_currency(total_amount)
      }
    end)
    |> Enum.sort_by(& &1.count, :desc)
  end

  defp calculate_date_range(transactions) do
    dates = Enum.map(transactions, fn tx -> get_transaction_date(tx) end)

    case {Enum.min(dates), Enum.max(dates)} do
      {start_date, end_date} when start_date == end_date ->
        %{
          start_date: Date.to_iso8601(start_date),
          end_date: Date.to_iso8601(end_date),
          day_count: 1
        }

      {start_date, end_date} ->
        day_count = Date.diff(end_date, start_date) + 1

        %{
          start_date: Date.to_iso8601(start_date),
          end_date: Date.to_iso8601(end_date),
          day_count: day_count
        }
    end
  end

  defp get_most_common_type([]), do: "None"
  defp get_most_common_type([{type, _data} | _]), do: String.capitalize(Atom.to_string(type))

  defp format_time_span(nil), do: "None"
  defp format_time_span(%{day_count: 1}), do: "1 day"
  defp format_time_span(%{day_count: days}) when days <= 7, do: "#{days} days"
  defp format_time_span(%{day_count: days}) when days <= 31, do: "#{div(days, 7)} weeks"
  defp format_time_span(%{day_count: days}), do: "#{div(days, 30)} months"

  defp format_currency(amount) do
    # Convert Decimal to float for formatting, handling potential conversion issues
    float_amount =
      try do
        Decimal.to_float(amount)
      rescue
        _ -> 0.0
      end

    ("$" <> :erlang.float_to_binary(float_amount, decimals: 2)) |> add_commas()
  end

  defp add_commas(number_string) do
    # Simple comma formatting for thousands
    number_string
    |> String.split(".")
    |> case do
      [whole] ->
        format_whole_number(whole)

      [whole, decimal] ->
        format_whole_number(whole) <> "." <> decimal
    end
  end

  defp format_whole_number(whole) do
    whole
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp type_color_class(:buy), do: "bg-green-500"
  defp type_color_class(:sell), do: "bg-red-500"
  defp type_color_class(:dividend), do: "bg-blue-500"
  defp type_color_class(:split), do: "bg-yellow-500"
  defp type_color_class(:transfer), do: "bg-purple-500"
  defp type_color_class(_), do: "bg-gray-500"

  # Helper functions to extract data from transactions
  # These handle both map and struct formats

  defp get_transaction_amount(%{total_amount: amount}), do: amount
  defp get_transaction_amount(tx) when is_map(tx), do: Map.get(tx, :total_amount, Decimal.new(0))

  defp get_transaction_type(%{type: type}), do: type
  defp get_transaction_type(tx) when is_map(tx), do: Map.get(tx, :type, :unknown)

  defp get_transaction_date(%{date: date}), do: date
  defp get_transaction_date(tx) when is_map(tx), do: Map.get(tx, :date, Date.utc_today())

  defp get_transaction_category_name(%{category: %{name: name}}), do: name
  defp get_transaction_category_name(%{category: nil}), do: "Uncategorized"
  defp get_transaction_category_name(%{category_id: nil}), do: "Uncategorized"

  defp get_transaction_category_name(tx) when is_map(tx) do
    case Map.get(tx, :category) do
      %{name: name} -> name
      nil -> "Uncategorized"
      _ -> "Unknown Category"
    end
  end
end
