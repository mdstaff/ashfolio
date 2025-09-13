defmodule Ashfolio.Portfolio.Calculators.DividendCalculator do
  @moduledoc """
  Calculator for cash dividend payments and tax classifications.

  This module handles dividend payment calculations, tax status determination,
  and creates the necessary adjustment records for dividend receipts.

  ## Tax Classifications

  - **Qualified**: Lower tax rates (0%, 15%, or 20% based on income)
  - **Ordinary**: Regular income tax rates (up to 37%)

  Qualified dividend requirements:
  - Must be paid by U.S. corporation or qualifying foreign corporation
  - Must be held for minimum period (61 days for common stock)
  - Cannot be certain types (REITs, MLPs, etc.)

  ## Formula

      Total Dividend = Shares Owned × Dividend Per Share
      Tax Withholding = Total Dividend × Withholding Rate
  """

  alias Decimal, as: D

  # Default withholding rates for tax estimation
  # 15% for qualified
  @qualified_dividend_rate D.new("0.15")
  # 24% for ordinary
  @ordinary_dividend_rate D.new("0.24")
  # Required for qualified status
  @min_holding_period_days 61

  @doc """
  Calculates dividend payment amount for given shares and rate.

  Options:
  - `round_to_penny`: Round result to nearest cent (default: false)

  Returns `{:ok, %{total_dividend: Decimal, shares_eligible: Decimal, dividend_per_share: Decimal}}`.
  """
  def calculate_dividend_payment(shares_owned, dividend_per_share, opts \\ []) do
    with :ok <- validate_dividend_inputs(shares_owned, dividend_per_share) do
      total_dividend = D.mult(shares_owned, dividend_per_share)

      # Round to penny if requested
      final_dividend =
        if opts[:round_to_penny] do
          D.round(total_dividend, 2)
        else
          total_dividend
        end

      {:ok,
       %{
         total_dividend: final_dividend,
         shares_eligible: shares_owned,
         dividend_per_share: dividend_per_share
       }}
    end
  end

  @doc """
  Classifies dividend for tax purposes based on corporate action and holding period.

  Returns `:qualified`, `:ordinary`, `:return_of_capital`, or `:capital_gain`.
  """
  def classify_dividend_tax_status(dividend_attrs, holding_period_days) do
    cond do
      # Check if explicitly marked as not qualified
      not dividend_attrs.qualified_dividend ->
        :ordinary

      # Check holding period requirement
      holding_period_days < @min_holding_period_days ->
        :ordinary

      # Default to qualified if conditions met
      true ->
        :qualified
    end
  end

  @doc """
  Creates dividend adjustment attributes for a position.

  Returns adjustment attributes ready for TransactionAdjustment.create/1.
  """
  def apply_to_position(position, corporate_action) do
    case calculate_dividend_payment(position.quantity, corporate_action.dividend_amount) do
      {:ok, payment} ->
        # Calculate holding period for tax classification
        holding_days = Date.diff(corporate_action.ex_date, position.purchase_date)
        tax_status = classify_dividend_tax_status(corporate_action, holding_days)

        {:ok,
         %{
           transaction_id: position.transaction_id,
           corporate_action_id: corporate_action.id,
           adjustment_type: :cash_receipt,
           reason: build_dividend_reason(corporate_action),
           dividend_per_share: corporate_action.dividend_amount,
           shares_eligible: payment.shares_eligible,
           total_dividend: payment.total_dividend,
           dividend_tax_status: tax_status,
           created_by: "dividend_calculator"
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Applies dividend to multiple positions in batch with FIFO ordering.
  """
  def batch_apply_dividends(positions, corporate_action) do
    # Sort by purchase date to ensure FIFO ordering
    sorted_positions = Enum.sort_by(positions, & &1.purchase_date)

    adjustments =
      sorted_positions
      |> Enum.with_index(1)
      |> Enum.map(fn {position, index} ->
        case apply_to_position(position, corporate_action) do
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
      {:error, "Failed to apply dividend to some positions"}
    end
  end

  @doc """
  Calculates estimated tax withholding for dividend payment.

  Options:
  - `withholding_rate`: Custom rate (overrides default rates)

  Returns withholding amount as Decimal.
  """
  def calculate_tax_withholding(total_dividend, tax_status, opts \\ []) do
    rate =
      case opts[:withholding_rate] do
        nil -> default_withholding_rate(tax_status)
        custom_rate -> custom_rate
      end

    D.mult(total_dividend, rate)
  end

  # Private functions

  defp validate_dividend_inputs(shares_owned, dividend_per_share) do
    cond do
      D.compare(shares_owned, 0) == :lt ->
        {:error, "Shares must be positive or zero"}

      D.compare(dividend_per_share, 0) == :lt ->
        {:error, "Dividend per share must be positive or zero"}

      true ->
        :ok
    end
  end

  defp default_withholding_rate(:qualified), do: @qualified_dividend_rate
  defp default_withholding_rate(:ordinary), do: @ordinary_dividend_rate
  defp default_withholding_rate(:return_of_capital), do: D.new("0")
  defp default_withholding_rate(_), do: @ordinary_dividend_rate

  defp build_dividend_reason(corporate_action) do
    amount_str = corporate_action.dividend_amount
    currency = corporate_action.dividend_currency || "USD"

    "#{currency} #{amount_str} dividend - #{corporate_action.description}"
  end
end
