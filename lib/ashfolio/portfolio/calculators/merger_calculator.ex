defmodule Ashfolio.Portfolio.Calculators.MergerCalculator do
  @moduledoc """
  Calculator for merger and acquisition adjustments following tax-deferred exchange principles.

  This module handles M&A transactions including:
  - Stock-for-stock mergers (tax-deferred)
  - Cash mergers (taxable events)
  - Mixed consideration (partial tax recognition)

  ## Formula

  Stock-for-stock merger:
  - New Quantity = Original Quantity × Exchange Ratio
  - New Basis = Original Basis (carried forward)
  - Original Purchase Date = Maintained (for tax holding periods)

  Cash merger:
  - Gain/Loss = Cash Received - Original Basis
  - Tax Basis = Fully recognized at closing

  Mixed consideration:
  - Recognized Gain = Cash Portion - (Cash Portion / Total Value) × Original Basis
  - Deferred Basis = Original Basis - Recognized Basis
  """

  alias Decimal, as: D

  @doc """
  Calculates adjustments for a stock-for-stock merger.

  Returns `{:ok, %{quantity: Decimal, basis_per_share: Decimal, gain_loss: Decimal}}`.
  """
  def calculate_stock_merger(original_quantity, original_basis_per_share, exchange_ratio) do
    with :ok <- validate_stock_merger_inputs(original_quantity, original_basis_per_share, exchange_ratio) do
      # Calculate new quantity
      new_quantity = D.mult(original_quantity, exchange_ratio)

      # Calculate total original basis
      total_original_basis = D.mult(original_quantity, original_basis_per_share)

      # Basis carries forward in stock-for-stock merger (tax-deferred)
      new_basis_per_share = D.div(total_original_basis, new_quantity)

      # No gain/loss recognized in stock-for-stock merger
      gain_loss = D.new("0")

      {:ok,
       %{
         quantity: new_quantity,
         basis_per_share: new_basis_per_share,
         gain_loss: gain_loss,
         tax_event: false
       }}
    end
  end

  @doc """
  Calculates adjustments for a cash merger.

  Returns `{:ok, %{cash_received: Decimal, gain_loss: Decimal}}`.
  """
  def calculate_cash_merger(original_quantity, original_basis_per_share, cash_per_share) do
    with :ok <- validate_cash_merger_inputs(original_quantity, original_basis_per_share, cash_per_share) do
      # Calculate totals
      total_basis = D.mult(original_quantity, original_basis_per_share)
      total_cash = D.mult(original_quantity, cash_per_share)

      # Calculate gain or loss
      gain_loss = D.sub(total_cash, total_basis)

      {:ok,
       %{
         cash_received: total_cash,
         original_basis: total_basis,
         gain_loss: gain_loss,
         tax_event: true,
         # Position closed
         quantity: D.new("0")
       }}
    end
  end

  @doc """
  Calculates adjustments for mixed consideration merger.

  Returns `{:ok, %{quantity: Decimal, basis_per_share: Decimal, cash_received: Decimal, recognized_gain_loss: Decimal}}`.
  """
  def calculate_mixed_merger(original_quantity, original_basis_per_share, exchange_ratio, cash_per_share) do
    with :ok <-
           validate_mixed_merger_inputs(
             original_quantity,
             original_basis_per_share,
             exchange_ratio,
             cash_per_share
           ) do
      # Calculate totals
      total_original_basis = D.mult(original_quantity, original_basis_per_share)
      total_cash_received = D.mult(original_quantity, cash_per_share)

      # Calculate new stock quantity
      new_quantity = D.mult(original_quantity, exchange_ratio)

      # Calculate stock value (assuming fair market value relationship)
      # In mixed deals, we need to allocate basis between cash and stock portions
      # Recognized gain on cash portion only (partial recognition)
      # Basis allocated to cash = (Cash / Total FMV) × Original Basis
      # For simplicity, we recognize gain only on the cash portion
      # Conservative: full cash as gain
      cash_basis_allocation = total_cash_received
      recognized_gain_loss = D.sub(total_cash_received, D.min(cash_basis_allocation, total_original_basis))

      # Remaining basis goes to new stock
      remaining_basis = D.sub(total_original_basis, D.min(cash_basis_allocation, total_original_basis))

      new_basis_per_share =
        if D.gt?(new_quantity, D.new("0")) do
          D.div(remaining_basis, new_quantity)
        else
          D.new("0")
        end

      {:ok,
       %{
         quantity: new_quantity,
         basis_per_share: new_basis_per_share,
         cash_received: total_cash_received,
         recognized_gain_loss: recognized_gain_loss,
         tax_event: true
       }}
    end
  end

  @doc """
  Calculates adjustments for a spinoff transaction.

  In a spinoff, shareholders receive shares of a new company while retaining their original shares.
  The original cost basis is allocated between the original and new shares based on fair market value.

  Returns `{:ok, %{original_basis_per_share: Decimal, spinoff_basis_per_share: Decimal, spinoff_quantity: Decimal}}`.
  """
  def calculate_spinoff(original_quantity, original_basis_per_share, spinoff_ratio, allocation_percentage) do
    with :ok <-
           validate_spinoff_inputs(
             original_quantity,
             original_basis_per_share,
             spinoff_ratio,
             allocation_percentage
           ) do
      # Calculate spinoff quantity (e.g., 1:1 means 1 spinoff share per 1 original share)
      spinoff_quantity = D.mult(original_quantity, spinoff_ratio)

      # Allocate original basis between original and spinoff shares
      total_original_basis = D.mult(original_quantity, original_basis_per_share)

      # Basis allocated to spinoff based on fair market value allocation
      spinoff_basis_allocation = D.mult(total_original_basis, D.div(allocation_percentage, D.new("100")))
      spinoff_basis_per_share = D.div(spinoff_basis_allocation, spinoff_quantity)

      # Remaining basis stays with original shares
      remaining_original_basis = D.sub(total_original_basis, spinoff_basis_allocation)
      new_original_basis_per_share = D.div(remaining_original_basis, original_quantity)

      {:ok,
       %{
         original_quantity: original_quantity,
         original_basis_per_share: new_original_basis_per_share,
         spinoff_quantity: spinoff_quantity,
         spinoff_basis_per_share: spinoff_basis_per_share,
         # Spinoffs are typically tax-deferred
         tax_event: false
       }}
    end
  end

  @doc """
  Batch applies merger calculations to multiple transactions.

  Returns a list of transaction adjustment attributes.
  """
  def batch_apply_merger(transactions, corporate_action) do
    case corporate_action.merger_type do
      :stock_for_stock ->
        batch_apply_stock_merger(transactions, corporate_action)

      :cash_for_stock ->
        batch_apply_cash_merger(transactions, corporate_action)

      :mixed_consideration ->
        batch_apply_mixed_merger(transactions, corporate_action)

      nil ->
        {:error, "Merger type is required"}

      unsupported ->
        {:error, "Unsupported merger type: #{unsupported}"}
    end
  end

  @doc """
  Batch applies spinoff calculations to multiple transactions.

  Returns a list of transaction adjustment attributes for both original and spinoff positions.
  """
  def batch_apply_spinoff(transactions, corporate_action) do
    # Validate required fields for spinoff
    if is_nil(corporate_action.new_symbol_id) do
      {:error, "New symbol is required for spinoff"}
    else
      # For spinoffs, we use exchange_ratio as spinoff ratio and default allocation
      # Default 1:1 ratio
      spinoff_ratio = corporate_action.exchange_ratio || D.new("1")
      # Default 20% to spinoff, 80% to original (typical)
      allocation_percentage = D.new("20")

      try do
        adjustments =
          Enum.flat_map(transactions, fn tx ->
            case calculate_spinoff(tx.quantity, tx.price, spinoff_ratio, allocation_percentage) do
              {:ok, calculation} ->
                # Create adjustment for original position (reduced basis)
                original_adjustment = %{
                  transaction_id: tx.id,
                  corporate_action_id: corporate_action.id,
                  adjustment_type: :spinoff_original,
                  original_quantity: tx.quantity,
                  adjusted_quantity: calculation.original_quantity,
                  original_price: tx.price,
                  adjusted_price: calculation.original_basis_per_share,
                  gain_loss_amount: D.new("0"),
                  reason: "Spinoff basis allocation - original shares",
                  applied_by: "merger_calculator"
                }

                # Create new transaction record for spinoff shares
                spinoff_adjustment = %{
                  # Will create new transaction
                  transaction_id: nil,
                  corporate_action_id: corporate_action.id,
                  adjustment_type: :spinoff_new_shares,
                  original_quantity: D.new("0"),
                  adjusted_quantity: calculation.spinoff_quantity,
                  original_price: D.new("0"),
                  adjusted_price: calculation.spinoff_basis_per_share,
                  gain_loss_amount: D.new("0"),
                  new_symbol_id: corporate_action.new_symbol_id,
                  reason: "Spinoff new shares - #{spinoff_ratio} ratio",
                  applied_by: "merger_calculator"
                }

                [original_adjustment, spinoff_adjustment]

              {:error, reason} ->
                throw({:spinoff_error, reason})
            end
          end)

        {:ok, adjustments}
      catch
        {:spinoff_error, reason} -> {:error, reason}
      end
    end
  end

  # Private functions

  defp batch_apply_stock_merger(transactions, corporate_action) do
    exchange_ratio = corporate_action.exchange_ratio

    if is_nil(exchange_ratio) do
      {:error, "Exchange ratio is required for stock-for-stock merger"}
    else
      adjustments =
        Enum.map(transactions, fn tx ->
          {:ok, calculation} = calculate_stock_merger(tx.quantity, tx.price, exchange_ratio)

          %{
            transaction_id: tx.id,
            corporate_action_id: corporate_action.id,
            adjustment_type: :merger_stock_for_stock,
            original_quantity: tx.quantity,
            adjusted_quantity: calculation.quantity,
            original_price: tx.price,
            adjusted_price: calculation.basis_per_share,
            gain_loss_amount: calculation.gain_loss,
            reason: "Stock-for-stock merger: #{exchange_ratio} exchange ratio",
            applied_by: "merger_calculator"
          }
        end)

      {:ok, adjustments}
    end
  end

  defp batch_apply_cash_merger(transactions, corporate_action) do
    cash_consideration = corporate_action.cash_consideration

    if is_nil(cash_consideration) do
      {:error, "Cash consideration is required for cash merger"}
    else
      adjustments =
        Enum.map(transactions, fn tx ->
          {:ok, calculation} = calculate_cash_merger(tx.quantity, tx.price, cash_consideration)

          %{
            transaction_id: tx.id,
            corporate_action_id: corporate_action.id,
            adjustment_type: :merger_cash_for_stock,
            original_quantity: tx.quantity,
            # Position closed
            adjusted_quantity: D.new("0"),
            original_price: tx.price,
            adjusted_price: D.new("0"),
            cash_received: calculation.cash_received,
            gain_loss_amount: calculation.gain_loss,
            reason: "Cash merger: $#{cash_consideration} per share",
            applied_by: "merger_calculator"
          }
        end)

      {:ok, adjustments}
    end
  end

  defp batch_apply_mixed_merger(transactions, corporate_action) do
    exchange_ratio = corporate_action.exchange_ratio
    cash_consideration = corporate_action.cash_consideration

    cond do
      is_nil(exchange_ratio) ->
        {:error, "Exchange ratio is required for mixed consideration merger"}

      is_nil(cash_consideration) ->
        {:error, "Cash consideration is required for mixed consideration merger"}

      true ->
        adjustments =
          Enum.map(transactions, fn tx ->
            {:ok, calculation} = calculate_mixed_merger(tx.quantity, tx.price, exchange_ratio, cash_consideration)

            %{
              transaction_id: tx.id,
              corporate_action_id: corporate_action.id,
              adjustment_type: :merger_mixed_consideration,
              original_quantity: tx.quantity,
              adjusted_quantity: calculation.quantity,
              original_price: tx.price,
              adjusted_price: calculation.basis_per_share,
              cash_received: calculation.cash_received,
              gain_loss_amount: calculation.recognized_gain_loss,
              reason: "Mixed merger: #{exchange_ratio} ratio + $#{cash_consideration} cash",
              applied_by: "merger_calculator"
            }
          end)

        {:ok, adjustments}
    end
  end

  # Validation functions

  defp validate_stock_merger_inputs(quantity, basis, exchange_ratio) do
    cond do
      not positive_decimal?(quantity) ->
        {:error, "Quantity must be positive"}

      not positive_decimal?(basis) ->
        {:error, "Basis per share must be positive"}

      not positive_decimal?(exchange_ratio) ->
        {:error, "Exchange ratio must be positive"}

      true ->
        :ok
    end
  end

  defp validate_cash_merger_inputs(quantity, basis, cash_per_share) do
    cond do
      not positive_decimal?(quantity) ->
        {:error, "Quantity must be positive"}

      not positive_decimal?(basis) ->
        {:error, "Basis per share must be positive"}

      not non_negative_decimal?(cash_per_share) ->
        {:error, "Cash per share cannot be negative"}

      true ->
        :ok
    end
  end

  defp validate_mixed_merger_inputs(quantity, basis, exchange_ratio, cash_per_share) do
    cond do
      not positive_decimal?(quantity) ->
        {:error, "Quantity must be positive"}

      not positive_decimal?(basis) ->
        {:error, "Basis per share must be positive"}

      not positive_decimal?(exchange_ratio) ->
        {:error, "Exchange ratio must be positive"}

      not non_negative_decimal?(cash_per_share) ->
        {:error, "Cash per share cannot be negative"}

      true ->
        :ok
    end
  end

  defp validate_spinoff_inputs(quantity, basis, spinoff_ratio, allocation_percentage) do
    cond do
      not positive_decimal?(quantity) ->
        {:error, "Quantity must be positive"}

      not positive_decimal?(basis) ->
        {:error, "Basis per share must be positive"}

      not positive_decimal?(spinoff_ratio) ->
        {:error, "Spinoff ratio must be positive"}

      not positive_decimal?(allocation_percentage) ->
        {:error, "Allocation percentage must be positive"}

      D.compare(allocation_percentage, D.new("100")) == :gt ->
        {:error, "Allocation percentage cannot exceed 100%"}

      true ->
        :ok
    end
  end

  # Helper functions for decimal validation
  defp positive_decimal?(nil), do: false

  defp positive_decimal?(value) when is_binary(value) do
    case D.parse(value) do
      {decimal, ""} -> D.compare(decimal, 0) == :gt
      _ -> false
    end
  end

  defp positive_decimal?(%D{} = value), do: D.compare(value, 0) == :gt
  defp positive_decimal?(_), do: false

  defp non_negative_decimal?(nil), do: false

  defp non_negative_decimal?(value) when is_binary(value) do
    case D.parse(value) do
      {decimal, ""} -> D.compare(decimal, 0) != :lt
      _ -> false
    end
  end

  defp non_negative_decimal?(%D{} = value), do: D.compare(value, 0) != :lt
  defp non_negative_decimal?(_), do: false
end
