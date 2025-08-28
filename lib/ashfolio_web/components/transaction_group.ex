defmodule AshfolioWeb.Components.TransactionGroup do
  @moduledoc """
  Transaction grouping and summary views component.

  Provides organized views of transactions grouped by various criteria
  including date, category, type, and symbol. Supports collapsible
  sections, summary statistics, and responsive layouts.

  Features:
  - Group by date (daily, weekly, monthly)
  - Group by category with color coding
  - Group by transaction type
  - Group by symbol/security
  - Collapsible group sections
  - Group-level statistics and totals
  - Responsive table layouts
  - Accessibility compliant navigation
  """

  use Phoenix.Component

  import AshfolioWeb.Components.CategoryTag

  @doc """
  Renders transactions organized into collapsible groups.

  ## Examples

      <.transaction_group
        transactions={@filtered_transactions}
        group_by={:category} />

      <.transaction_group
        transactions={@transactions}
        group_by={:date}
        date_grouping={:monthly}
        show_group_stats={true}
        collapsible={true} />

  ## Attributes

  * `transactions` - List of transactions to group (required)
  * `group_by` - Grouping criteria: :category, :date, :type, :symbol (default: :category)
  * `date_grouping` - For date grouping: :daily, :weekly, :monthly (default: :monthly)
  * `show_group_stats` - Show statistics for each group (default: true)
  * `collapsible` - Make groups collapsible (default: true)
  * `compact` - Compact layout mode (default: false)
  * `class` - Additional CSS classes
  """
  attr :transactions, :list, required: true, doc: "List of transactions to group"

  attr :group_by, :atom,
    default: :category,
    values: [:category, :date, :type, :symbol],
    doc: "Grouping criteria"

  attr :date_grouping, :atom,
    default: :monthly,
    values: [:daily, :weekly, :monthly],
    doc: "Date grouping level"

  attr :show_group_stats, :boolean, default: true, doc: "Show group statistics"
  attr :collapsible, :boolean, default: true, doc: "Make groups collapsible"
  attr :compact, :boolean, default: false, doc: "Compact layout mode"
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :rest, :global, doc: "Additional HTML attributes"

  def transaction_group(assigns) do
    assigns = assign_computed_values(assigns)

    ~H"""
    <div
      class={[
        "bg-white rounded-lg shadow-sm border border-gray-200",
        (@compact && "p-3") || "p-4",
        @class
      ]}
      role="region"
      aria-label="Grouped transactions"
      {@rest}
    >
      <%= if @grouped_data == [] do %>
        <!-- Empty State -->
        <div class="text-center py-6">
          <div class="text-gray-400 mb-2">
            <svg class="w-12 h-12 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 9a2 2 0 00-2 2v6a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2M5 9V7a2 2 0 012-2h10a2 2 0 012 2v2M7 7V5a2 2 0 012-2h6a2 2 0 012 2v2"
              />
            </svg>
          </div>
          <h3 class={[(@compact && "text-sm") || "text-base", "font-medium text-gray-900 mb-1"]}>
            No transactions to group
          </h3>
          <p class="text-sm text-gray-500">
            Add some transactions to see them organized by {@group_by}
          </p>
        </div>
      <% else %>
        <!-- Grouped Transactions -->
        <div class="space-y-4">
          <!-- Header -->
          <div class="flex items-center justify-between">
            <h3 class={[(@compact && "text-sm") || "text-base", "font-medium text-gray-900"]}>
              Transactions by {String.capitalize(Atom.to_string(@group_by))}
            </h3>
            <span class={[(@compact && "text-xs") || "text-sm", "text-gray-500"]}>
              {length(@grouped_data)} group{if length(@grouped_data) != 1, do: "s"}
            </span>
          </div>
          
    <!-- Groups -->
          <div class="space-y-3">
            <%= for group <- @grouped_data do %>
              <div class="border border-gray-200 rounded-lg overflow-hidden">
                <!-- Group Header -->
                <div
                  class={[
                    "flex items-center justify-between p-3 bg-gray-50",
                    @collapsible && "cursor-pointer hover:bg-gray-100"
                  ]}
                  phx-click={@collapsible && "toggle_group"}
                  phx-value-group-id={group.id}
                >
                  <div class="flex items-center gap-3">
                    <!-- Collapse Icon -->
                    <div :if={@collapsible} class="text-gray-400">
                      <svg
                        class="w-4 h-4 transform transition-transform"
                        class={(group.expanded && "rotate-90") || ""}
                      >
                        <path
                          fill="currentColor"
                          d="M8.59 16.58L13.17 12 8.59 7.41 10 6l6 6-6 6-1.41-1.42z"
                        />
                      </svg>
                    </div>
                    
    <!-- Group Icon/Indicator -->
                    <%= case @group_by do %>
                      <% :category -> %>
                        <.category_tag :if={group.category} category={group.category} size={:small} />
                        <span :if={!group.category} class="text-sm font-medium text-gray-700">
                          Uncategorized
                        </span>
                      <% :type -> %>
                        <span class={[
                          "inline-block w-3 h-3 rounded-full",
                          transaction_type_color(group.key)
                        ]}>
                        </span>
                      <% _ -> %>
                        <span class="text-sm font-medium text-gray-700">
                          {group.display_name}
                        </span>
                    <% end %>

                    <div>
                      <h4 class={[(@compact && "text-sm") || "text-base", "font-medium text-gray-900"]}>
                        {group.display_name}
                      </h4>
                      <p class={[(@compact && "text-xs") || "text-sm", "text-gray-500"]}>
                        {group.transaction_count} transaction{if group.transaction_count != 1, do: "s"}
                      </p>
                    </div>
                  </div>
                  
    <!-- Group Stats -->
                  <div :if={@show_group_stats} class="text-right">
                    <div class={[
                      (@compact && "text-sm") || "text-base",
                      "font-semibold text-gray-900"
                    ]}>
                      {group.formatted_total}
                    </div>
                    <div class={[(@compact && "text-xs") || "text-sm", "text-gray-500"]}>
                      Total Value
                    </div>
                  </div>
                </div>
                
    <!-- Group Content (Transactions) -->
                <div class={[
                  "transition-all duration-200",
                  !@collapsible || (group.expanded && "block") || "hidden"
                ]}>
                  <div class="overflow-x-auto">
                    <table class="min-w-full">
                      <thead class="bg-gray-50 border-t border-gray-200">
                        <tr>
                          <th class={[
                            (@compact && "px-2 py-1 text-xs") || "px-3 py-2 text-sm",
                            "text-left font-medium text-gray-500"
                          ]}>
                            Date
                          </th>
                          <th class={[
                            (@compact && "px-2 py-1 text-xs") || "px-3 py-2 text-sm",
                            "text-left font-medium text-gray-500"
                          ]}>
                            Type
                          </th>
                          <th class={[
                            (@compact && "px-2 py-1 text-xs") || "px-3 py-2 text-sm",
                            "text-left font-medium text-gray-500"
                          ]}>
                            Symbol
                          </th>
                          <th class={[
                            (@compact && "px-2 py-1 text-xs") || "px-3 py-2 text-sm",
                            "text-right font-medium text-gray-500"
                          ]}>
                            Amount
                          </th>
                        </tr>
                      </thead>
                      <tbody class="divide-y divide-gray-200">
                        <%= for transaction <- group.transactions do %>
                          <tr class="hover:bg-gray-50">
                            <td class={[
                              (@compact && "px-2 py-1 text-xs") || "px-3 py-2 text-sm",
                              "text-gray-900"
                            ]}>
                              {format_transaction_date(transaction)}
                            </td>
                            <td class={[
                              (@compact && "px-2 py-1 text-xs") || "px-3 py-2 text-sm",
                              "text-gray-700"
                            ]}>
                              {format_transaction_type(transaction)}
                            </td>
                            <td class={[
                              (@compact && "px-2 py-1 text-xs") || "px-3 py-2 text-sm",
                              "text-gray-700"
                            ]}>
                              {get_transaction_symbol(transaction)}
                            </td>
                            <td class={[
                              (@compact && "px-2 py-1 text-xs") || "px-3 py-2 text-sm",
                              "text-right font-medium text-gray-900"
                            ]}>
                              {format_transaction_amount(transaction)}
                            </td>
                          </tr>
                        <% end %>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Private helper functions

  defp assign_computed_values(assigns) do
    grouped_data =
      group_transactions(assigns.transactions, assigns.group_by, assigns.date_grouping)

    assign(assigns, :grouped_data, grouped_data)
  end

  defp group_transactions(transactions, group_by, date_grouping) do
    transactions
    |> Enum.group_by(&get_grouping_key(&1, group_by, date_grouping))
    |> Enum.map(fn {key, group_transactions} ->
      create_group_data(key, group_transactions, group_by)
    end)
    |> Enum.sort_by(& &1.sort_key)
  end

  defp get_grouping_key(transaction, :category, _) do
    case get_transaction_category(transaction) do
      %{id: id} -> {:category, id}
      nil -> {:category, :uncategorized}
      _ -> {:category, :unknown}
    end
  end

  defp get_grouping_key(transaction, :type, _) do
    {:type, get_transaction_type(transaction)}
  end

  defp get_grouping_key(transaction, :symbol, _) do
    {:symbol, get_transaction_symbol(transaction)}
  end

  defp get_grouping_key(transaction, :date, date_grouping) do
    date = get_transaction_date(transaction)
    {:date, group_date(date, date_grouping)}
  end

  defp create_group_data({:category, category_id}, transactions, :category) do
    category = get_transaction_category(List.first(transactions))
    total_amount = calculate_group_total(transactions)

    %{
      id: "category-#{category_id}",
      key: category_id,
      category: category,
      display_name: get_category_display_name(category),
      transactions: transactions,
      transaction_count: length(transactions),
      total_amount: total_amount,
      formatted_total: format_currency_simple(total_amount),
      sort_key: get_category_display_name(category),
      expanded: false
    }
  end

  defp create_group_data({:type, type}, transactions, :type) do
    total_amount = calculate_group_total(transactions)

    %{
      id: "type-#{type}",
      key: type,
      category: nil,
      display_name: String.capitalize(Atom.to_string(type)),
      transactions: transactions,
      transaction_count: length(transactions),
      total_amount: total_amount,
      formatted_total: format_currency_simple(total_amount),
      sort_key: type,
      expanded: false
    }
  end

  defp create_group_data({:symbol, symbol}, transactions, :symbol) do
    total_amount = calculate_group_total(transactions)

    %{
      id: "symbol-#{symbol}",
      key: symbol,
      category: nil,
      display_name: symbol,
      transactions: transactions,
      transaction_count: length(transactions),
      total_amount: total_amount,
      formatted_total: format_currency_simple(total_amount),
      sort_key: symbol,
      expanded: false
    }
  end

  defp create_group_data({:date, date_key}, transactions, :date) do
    total_amount = calculate_group_total(transactions)

    %{
      id: "date-#{date_key}",
      key: date_key,
      category: nil,
      display_name: format_date_group(date_key),
      transactions: transactions,
      transaction_count: length(transactions),
      total_amount: total_amount,
      formatted_total: format_currency_simple(total_amount),
      sort_key: date_key,
      expanded: false
    }
  end

  defp calculate_group_total(transactions) do
    Enum.reduce(transactions, Decimal.new(0), fn tx, acc ->
      amount = get_transaction_amount(tx)
      Decimal.add(acc, Decimal.abs(amount))
    end)
  end

  defp group_date(date, :daily), do: Date.to_iso8601(date)

  defp group_date(date, :weekly) do
    start_of_week = Date.beginning_of_week(date)
    Date.to_iso8601(start_of_week)
  end

  defp group_date(date, :monthly) do
    "#{date.year}-#{String.pad_leading(Integer.to_string(date.month), 2, "0")}"
  end

  defp format_date_group(date_string) when is_binary(date_string) do
    case String.length(date_string) do
      # Daily format (2024-01-15)
      10 -> date_string
      # Monthly
      7 -> (date_string <> "-01") |> Date.from_iso8601!() |> Calendar.strftime("%B %Y")
      _ -> date_string
    end
  end

  defp transaction_type_color(:buy), do: "bg-green-500"
  defp transaction_type_color(:sell), do: "bg-red-500"
  defp transaction_type_color(:dividend), do: "bg-blue-500"
  defp transaction_type_color(_), do: "bg-gray-500"

  defp format_currency_simple(amount) do
    float_amount = Decimal.to_float(amount)
    "$" <> :erlang.float_to_binary(float_amount, decimals: 2)
  rescue
    _ -> "$0.00"
  end

  # Transaction data extraction helpers
  defp get_transaction_category(%{category: category}), do: category
  defp get_transaction_category(_), do: nil

  defp get_transaction_type(%{type: type}), do: type
  defp get_transaction_type(_), do: :unknown

  defp get_transaction_symbol(%{symbol: %{symbol: symbol}}), do: symbol
  defp get_transaction_symbol(%{symbol: symbol}) when is_binary(symbol), do: symbol
  defp get_transaction_symbol(_), do: "Unknown"

  defp get_transaction_date(%{date: date}), do: date
  defp get_transaction_date(_), do: Date.utc_today()

  defp get_transaction_amount(%{total_amount: amount}), do: amount
  defp get_transaction_amount(_), do: Decimal.new(0)

  defp get_category_display_name(%{name: name}), do: name
  defp get_category_display_name(nil), do: "Uncategorized"
  defp get_category_display_name(_), do: "Unknown Category"

  defp format_transaction_date(transaction) do
    transaction |> get_transaction_date() |> Date.to_iso8601()
  end

  defp format_transaction_type(transaction) do
    transaction |> get_transaction_type() |> Atom.to_string() |> String.capitalize()
  end

  defp format_transaction_amount(transaction) do
    transaction |> get_transaction_amount() |> format_currency_simple()
  end
end
