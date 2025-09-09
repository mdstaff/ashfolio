defmodule AshfolioWeb.Components.HoldingsTable do
  @moduledoc """
  Component for displaying portfolio holdings in a sortable table format.

  Handles sorting, formatting, and display of investment holdings data.
  """
  use Phoenix.Component

  alias Ashfolio.Financial.Formatters

  @doc """
  Renders a sortable holdings table.

  ## Attributes

    * `:holdings` - List of holdings to display (required)
    * `:sort_by` - Current sort field (default: :total_value)
    * `:sort_order` - Sort order :asc or :desc (default: :desc)
  """
  attr :holdings, :list, required: true
  attr :sort_by, :atom, default: :total_value
  attr :sort_order, :atom, default: :desc

  def holdings_table(assigns) do
    assigns = assign(assigns, :sorted_holdings, sort_holdings(assigns.holdings, assigns.sort_by, assigns.sort_order))

    ~H"""
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th
              phx-click="sort_holdings"
              phx-value-field="symbol"
              class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
            >
              Symbol {sort_indicator("symbol", @sort_by, @sort_order)}
            </th>
            <th
              phx-click="sort_holdings"
              phx-value-field="quantity"
              class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
            >
              Quantity {sort_indicator("quantity", @sort_by, @sort_order)}
            </th>
            <th
              phx-click="sort_holdings"
              phx-value-field="current_price"
              class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
            >
              Price {sort_indicator("current_price", @sort_by, @sort_order)}
            </th>
            <th
              phx-click="sort_holdings"
              phx-value-field="avg_cost_basis"
              class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
            >
              Avg Cost {sort_indicator("avg_cost_basis", @sort_by, @sort_order)}
            </th>
            <th
              phx-click="sort_holdings"
              phx-value-field="total_value"
              class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
            >
              Total Value {sort_indicator("total_value", @sort_by, @sort_order)}
            </th>
            <th
              phx-click="sort_holdings"
              phx-value-field="total_gain_loss"
              class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
            >
              Gain/Loss {sort_indicator("total_gain_loss", @sort_by, @sort_order)}
            </th>
            <th
              phx-click="sort_holdings"
              phx-value-field="gain_loss_percentage"
              class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
            >
              % Change {sort_indicator("gain_loss_percentage", @sort_by, @sort_order)}
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <%= for holding <- @sorted_holdings do %>
            <tr class="hover:bg-gray-50">
              <td class="px-4 py-3 text-sm font-medium text-gray-900">
                {holding.symbol}
              </td>
              <td class="px-4 py-3 text-sm text-gray-500">
                {format_quantity(holding.quantity)}
              </td>
              <td class="px-4 py-3 text-sm text-gray-500">
                {Formatters.currency(holding.current_price)}
              </td>
              <td class="px-4 py-3 text-sm text-gray-500">
                {Formatters.currency(holding.avg_cost_basis)}
              </td>
              <td class="px-4 py-3 text-sm font-medium text-gray-900">
                {Formatters.currency(holding.total_value)}
              </td>
              <td class={"px-4 py-3 text-sm font-medium #{gain_loss_color(holding.total_gain_loss)}"}>
                {format_currency_with_sign(holding.total_gain_loss)}
              </td>
              <td class={"px-4 py-3 text-sm font-medium #{gain_loss_color(holding.gain_loss_percentage)}"}>
                {format_percentage(holding.gain_loss_percentage)}
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  # Sorting functions

  defp sort_holdings(holdings, sort_by, sort_order) do
    Enum.sort_by(holdings, &Map.get(&1, sort_by), sort_order)
  end

  defp sort_indicator(field, current_field, current_order) do
    if String.to_existing_atom(field) == current_field do
      if current_order == :asc do
        "↑"
      else
        "↓"
      end
    else
      ""
    end
  end

  # Formatting functions

  defp format_quantity(quantity) when is_struct(quantity, Decimal) do
    Decimal.to_string(quantity, :normal)
  end

  defp format_quantity(quantity), do: to_string(quantity)

  defp gain_loss_color(value) do
    cond do
      Decimal.compare(value, Decimal.new(0)) == :gt -> "text-green-600"
      Decimal.compare(value, Decimal.new(0)) == :lt -> "text-red-600"
      true -> "text-gray-600"
    end
  end

  defp format_currency_with_sign(value) do
    formatted = Formatters.currency(value)

    if Decimal.compare(value, Decimal.new(0)) == :gt do
      "+" <> formatted
    else
      formatted
    end
  end

  defp format_percentage(value) do
    value
    |> Decimal.mult(Decimal.new("100"))
    |> Decimal.round(2)
    |> Decimal.to_string()
    |> Kernel.<>("%")
  end
end
