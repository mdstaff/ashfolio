defmodule Ashfolio.Portfolio.Calculators.StockSplitCalculator do
  @moduledoc """
  Calculator for stock split adjustments following FIFO cost basis principles.

  This module handles the mathematical calculations for adjusting share quantities
  and prices when a stock split occurs, ensuring total portfolio value is preserved.

  ## Formula

  For a split ratio of `from:to`:
  - New Quantity = Original Quantity × (to / from)
  - New Price = Original Price × (from / to)
  - Total Value = Quantity × Price (remains constant)

  ## Examples

  2:1 forward split (1 share becomes 2):
  - 100 shares @ $200 → 200 shares @ $100

  1:2 reverse split (2 shares become 1):
  - 200 shares @ $50 → 100 shares @ $100
  """

  alias Decimal, as: D

  @doc """
  Calculates adjusted quantity and price after a stock split.

  Returns `{:ok, %{quantity: Decimal, price: Decimal}}` or `{:error, reason}`.
  """
  def calculate_adjusted_values(original_quantity, original_price, {ratio_from, ratio_to}) do
    with :ok <- validate_inputs(original_quantity, original_price, ratio_from, ratio_to) do
      # Calculate split factor: to/from
      # For 2:1 split, factor is 2/1 = 2 (quantity doubles)
      # For 1:2 reverse, factor is 1/2 = 0.5 (quantity halves)
      split_factor = D.div(ratio_to, ratio_from)

      # New quantity = original × split factor
      new_quantity = D.mult(original_quantity, split_factor)

      # New price = original ÷ split factor (inverse relationship)
      new_price = D.div(original_price, split_factor)

      {:ok,
       %{
         quantity: new_quantity,
         price: new_price
       }}
    end
  end

  @doc """
  Creates adjustment attributes for a transaction based on corporate action.

  Returns attributes map ready to be passed to TransactionAdjustment.create/1.
  """
  def apply_to_transaction(transaction, corporate_action) do
    split_ratio = {
      corporate_action.split_ratio_from,
      corporate_action.split_ratio_to
    }

    case calculate_adjusted_values(transaction.quantity, transaction.price, split_ratio) do
      {:ok, adjusted} ->
        {:ok,
         %{
           transaction_id: transaction.id,
           corporate_action_id: corporate_action.id,
           adjustment_type: :quantity_price,
           reason: build_reason(corporate_action),
           original_quantity: transaction.quantity,
           original_price: transaction.price,
           adjusted_quantity: adjusted.quantity,
           adjusted_price: adjusted.price,
           created_by: "stock_split_calculator"
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Applies stock split to multiple transactions in batch.

  Preserves FIFO ordering by adding fifo_lot_order to adjustments.
  """
  def batch_apply(transactions, corporate_action) do
    # Sort by date to ensure FIFO ordering
    sorted_transactions = Enum.sort_by(transactions, & &1.date)

    adjustments =
      sorted_transactions
      |> Enum.with_index(1)
      |> Enum.map(fn {tx, index} ->
        case apply_to_transaction(tx, corporate_action) do
          {:ok, adjustment} ->
            Map.put(adjustment, :fifo_lot_order, index)

          {:error, _reason} = error ->
            error
        end
      end)

    # Check if any failed
    errors = Enum.filter(adjustments, &match?({:error, _}, &1))

    if Enum.empty?(errors) do
      {:ok, adjustments}
    else
      {:error, "Failed to apply split to some transactions"}
    end
  end

  # Private functions

  defp validate_inputs(quantity, price, ratio_from, ratio_to) do
    cond do
      D.compare(quantity, 0) != :gt ->
        {:error, "Quantity must be positive"}

      D.compare(price, 0) != :gt ->
        {:error, "Price must be positive"}

      D.compare(ratio_from, 0) != :gt || D.compare(ratio_to, 0) != :gt ->
        {:error, "Invalid split ratio - both values must be positive"}

      true ->
        :ok
    end
  end

  defp build_reason(corporate_action) do
    from = corporate_action.split_ratio_from
    to = corporate_action.split_ratio_to

    "#{to}:#{from} stock split - #{corporate_action.description}"
  end
end
