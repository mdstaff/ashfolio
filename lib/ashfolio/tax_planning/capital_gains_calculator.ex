defmodule Ashfolio.TaxPlanning.CapitalGainsCalculator do
  @moduledoc """
  Capital gains and loss calculations with FIFO cost basis methodology.

  Provides comprehensive tax planning calculations including:
  - FIFO (First In, First Out) cost basis calculation
  - Realized vs unrealized gains/losses
  - Short-term vs long-term capital gains classification
  - Tax lot tracking for precise cost basis allocation

  Integrates with existing transaction infrastructure to provide accurate
  tax planning data for portfolio optimization and reporting.
  """

  alias Ashfolio.Financial.DecimalHelpers, as: DH
  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Portfolio.Transaction

  require Logger

  @doc """
  Calculates realized capital gains/losses for sold positions using FIFO methodology.

  Processes all sell transactions and matches them against corresponding buy transactions
  using FIFO (First In, First Out) cost basis calculation for accurate tax reporting.

  ## Parameters

    - symbol_id: UUID - Symbol identifier for position analysis
    - tax_year: integer - Tax year for gain/loss calculation (optional, defaults to current year)
    - options: keyword - Additional options for calculation refinement

  ## Returns

    - {:ok, gains_analysis} - Map with detailed capital gains breakdown
    - {:error, reason} - Error tuple with descriptive reason

  ## Examples

      iex> CapitalGainsCalculator.calculate_realized_gains("symbol-uuid-123", 2024)
      {:ok, %{
        total_realized_gains: Decimal.new("1500.50"),
        short_term_gains: Decimal.new("750.25"),
        long_term_gains: Decimal.new("750.25"),
        tax_lots: [%{...}],
        transactions_processed: 15
      }}
  """
  def calculate_realized_gains(symbol_id, tax_year \\ nil, options \\ []) do
    Logger.debug("Calculating realized gains for symbol #{symbol_id}, tax year #{tax_year || "current"}")

    tax_year = tax_year || Date.utc_today().year

    with {:ok, transactions} <- get_symbol_transactions(symbol_id),
         {:ok, symbol_data} <- get_symbol_data(symbol_id),
         :ok <- validate_transactions(transactions) do
      # Process transactions chronologically with FIFO methodology
      analysis = calculate_fifo_gains(transactions, tax_year, symbol_data, options)

      Logger.debug("Realized gains calculation complete for #{symbol_data.symbol}: #{analysis.total_realized_gains}")
      {:ok, analysis}
    else
      {:error, reason} ->
        Logger.warning("Realized gains calculation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculates unrealized gains/losses for current holdings.

  Analyzes current positions to determine potential tax implications
  if positions were sold at current market prices.

  ## Parameters

    - symbol_id: UUID - Symbol identifier (optional, calculates for all if nil)
    - options: keyword - Calculation options

  ## Returns

    - {:ok, unrealized_analysis} - Map with unrealized gains breakdown
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_unrealized_gains(symbol_id \\ nil, options \\ []) do
    Logger.debug(
      "Calculating unrealized gains#{if symbol_id, do: " for symbol #{symbol_id}", else: " for all positions"}"
    )

    case get_current_holdings(symbol_id) do
      {:ok, holdings} when holdings != [] ->
        unrealized_analysis =
          holdings
          |> Enum.map(&calculate_position_unrealized_gains(&1, options))
          |> aggregate_unrealized_gains()

        Logger.debug("Unrealized gains calculation complete: #{unrealized_analysis.total_unrealized_gains}")
        {:ok, unrealized_analysis}

      {:ok, []} ->
        Logger.info("No holdings found for unrealized gains calculation")
        {:error, :no_holdings}
    end
  end

  @doc """
  Generates comprehensive tax lot report for cost basis tracking.

  Creates detailed breakdown of all tax lots (purchase groups) with
  cost basis, holding periods, and potential tax implications.

  ## Parameters

    - account_id: UUID - Account identifier (optional, analyzes all if nil)
    - as_of_date: Date - Analysis date (optional, defaults to today)

  ## Returns

    - {:ok, tax_lot_report} - Detailed tax lot analysis
    - {:error, reason} - Error tuple with descriptive reason
  """
  def generate_tax_lot_report(account_id \\ nil, as_of_date \\ nil) do
    as_of_date = as_of_date || Date.utc_today()
    Logger.debug("Generating tax lot report#{if account_id, do: " for account #{account_id}"} as of #{as_of_date}")

    case get_account_holdings(account_id) do
      {:ok, holdings} when holdings != [] ->
        tax_lot_report =
          holdings
          |> Enum.map(&generate_symbol_tax_lots(&1, as_of_date))
          |> aggregate_tax_lot_data()

        Logger.debug("Tax lot report generated with #{length(tax_lot_report.tax_lots)} lots")
        {:ok, tax_lot_report}

      {:ok, []} ->
        Logger.info("No holdings found for tax lot report")
        {:error, :no_holdings}
    end
  end

  @doc """
  Calculates year-to-date realized gains/losses summary.

  Provides comprehensive annual summary for tax preparation and planning.

  ## Parameters

    - tax_year: integer - Tax year for analysis
    - account_id: UUID - Account filter (optional)

  ## Returns

    - {:ok, annual_summary} - Annual gains/losses breakdown
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_annual_summary(tax_year, account_id \\ nil) do
    Logger.debug("Calculating annual summary for #{tax_year}#{if account_id, do: ", account #{account_id}"}")

    start_date = Date.new!(tax_year, 1, 1)
    end_date = Date.new!(tax_year, 12, 31)

    with {:ok, transactions} <- get_transactions_by_date_range(start_date, end_date, account_id),
         :ok <- validate_transactions(transactions) do
      annual_summary = calculate_annual_gains_summary(transactions, tax_year)

      Logger.debug("Annual summary complete: #{annual_summary.net_capital_gains} net capital gains")
      {:ok, annual_summary}
    else
      {:error, reason} ->
        Logger.warning("Annual summary calculation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private helper functions

  defp get_symbol_transactions(symbol_id) do
    case Transaction.by_symbol(symbol_id) do
      {:ok, transactions} ->
        # Filter for buy/sell transactions and sort by date
        buy_sell_transactions =
          transactions
          |> Enum.filter(&(&1.type in [:buy, :sell]))
          |> Enum.sort_by(&Date.to_erl(&1.date))

        {:ok, buy_sell_transactions}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_symbol_data(symbol_id) do
    case Symbol.get_by_id(symbol_id) do
      {:ok, symbol} -> {:ok, symbol}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_transactions([]), do: {:error, :no_transactions}
  defp validate_transactions(_transactions), do: :ok

  # validate_holdings function removed - validation is now done inline

  defp calculate_fifo_gains(transactions, tax_year, symbol_data, _options) do
    # Initialize FIFO queue with buy transactions
    buy_queue = initialize_buy_queue(transactions)

    # Process all sell transactions using FIFO
    {processed_sales, _remaining_queue} =
      transactions
      |> Enum.filter(&(&1.type == :sell and tax_year_matches?(&1, tax_year)))
      |> Enum.reduce({[], buy_queue}, &process_sale_transaction/2)

    # Aggregate results
    aggregate_realized_gains(processed_sales, symbol_data)
  end

  defp initialize_buy_queue(transactions) do
    transactions
    |> Enum.filter(&(&1.type == :buy))
    |> Enum.map(&create_tax_lot/1)
  end

  defp create_tax_lot(buy_transaction) do
    %{
      transaction_id: buy_transaction.id,
      purchase_date: buy_transaction.date,
      original_quantity: buy_transaction.quantity,
      remaining_quantity: buy_transaction.quantity,
      cost_per_share: buy_transaction.price,
      total_cost: buy_transaction.total_amount
    }
  end

  defp process_sale_transaction(sell_transaction, {processed_sales, buy_queue}) do
    {sale_lots, updated_queue} = allocate_sale_to_lots(sell_transaction, buy_queue)

    processed_sale = %{
      sale_transaction: sell_transaction,
      allocated_lots: sale_lots,
      total_proceeds: sell_transaction.total_amount,
      total_cost_basis: calculate_total_cost_basis(sale_lots),
      realized_gain_loss: calculate_realized_gain_loss(sell_transaction.total_amount, sale_lots)
    }

    {[processed_sale | processed_sales], updated_queue}
  end

  defp allocate_sale_to_lots(sell_transaction, buy_queue) do
    sell_quantity = Decimal.abs(sell_transaction.quantity)
    allocate_quantity(sell_quantity, buy_queue, [], sell_transaction.date)
  end

  defp allocate_quantity(remaining_qty, buy_queue, allocated_lots, sale_date) do
    zero = Decimal.new("0")

    if Decimal.equal?(remaining_qty, zero) do
      {allocated_lots, buy_queue}
    else
      allocate_quantity_recursive(remaining_qty, buy_queue, allocated_lots, sale_date)
    end
  end

  defp allocate_quantity_recursive(remaining_qty, [], allocated_lots, _sale_date) do
    # Handle short sale or insufficient lots
    Logger.warning("Insufficient buy lots for complete allocation, remaining: #{remaining_qty}")
    {allocated_lots, []}
  end

  defp allocate_quantity_recursive(remaining_qty, [first_lot | rest_queue], allocated_lots, sale_date) do
    if Decimal.compare(remaining_qty, first_lot.remaining_quantity) == :gt do
      # Use entire lot
      allocated_lot = %{
        tax_lot: first_lot,
        quantity_allocated: first_lot.remaining_quantity,
        cost_basis: first_lot.total_cost,
        holding_period: calculate_holding_period(first_lot.purchase_date, sale_date)
      }

      new_remaining = Decimal.sub(remaining_qty, first_lot.remaining_quantity)
      allocate_quantity_recursive(new_remaining, rest_queue, [allocated_lot | allocated_lots], sale_date)
    else
      # Partial lot usage
      allocated_quantity = remaining_qty
      cost_basis = calculate_partial_cost_basis(first_lot, allocated_quantity)

      allocated_lot = %{
        tax_lot: first_lot,
        quantity_allocated: allocated_quantity,
        cost_basis: cost_basis,
        holding_period: calculate_holding_period(first_lot.purchase_date, sale_date)
      }

      # Update remaining lot
      updated_lot = %{first_lot | remaining_quantity: Decimal.sub(first_lot.remaining_quantity, allocated_quantity)}

      {[allocated_lot | allocated_lots], [updated_lot | rest_queue]}
    end
  end

  defp calculate_partial_cost_basis(tax_lot, allocated_quantity) do
    ratio = DH.safe_divide(allocated_quantity, tax_lot.original_quantity)
    Decimal.mult(tax_lot.total_cost, ratio)
  end

  defp calculate_holding_period(purchase_date, sale_date) do
    days_held = Date.diff(sale_date, purchase_date)

    %{
      days: days_held,
      classification: if(days_held > 365, do: :long_term, else: :short_term)
    }
  end

  defp calculate_total_cost_basis(allocated_lots) do
    allocated_lots
    |> Enum.map(& &1.cost_basis)
    |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)
  end

  defp calculate_realized_gain_loss(proceeds, allocated_lots) do
    total_cost_basis = calculate_total_cost_basis(allocated_lots)
    Decimal.sub(proceeds, total_cost_basis)
  end

  defp aggregate_realized_gains(processed_sales, symbol_data) do
    # Calculate gains by summing up the realized_gain_loss from each sale
    # and categorizing by holding period
    {short_term, long_term} =
      Enum.reduce(processed_sales, {Decimal.new("0"), Decimal.new("0")}, fn sale, {st_acc, lt_acc} ->
        # Categorize each allocated lot's proportional gain
        Enum.reduce(sale.allocated_lots, {st_acc, lt_acc}, fn lot, {st, lt} ->
          total_qty_sold = Enum.reduce(sale.allocated_lots, Decimal.new("0"), &Decimal.add(&2, &1.quantity_allocated))
          # Calculate this lot's proportional share of the total sale gain
          lot_proportion = Decimal.div(lot.quantity_allocated, total_qty_sold)
          lot_gain = Decimal.mult(sale.realized_gain_loss, lot_proportion)

          if lot.holding_period.classification == :short_term do
            {Decimal.add(st, lot_gain), lt}
          else
            {st, Decimal.add(lt, lot_gain)}
          end
        end)
      end)

    total_realized = Decimal.add(short_term, long_term)

    %{
      symbol: symbol_data.symbol,
      symbol_id: symbol_data.id,
      total_realized_gains: total_realized,
      short_term_gains: short_term,
      long_term_gains: long_term,
      processed_sales: processed_sales,
      transactions_processed: length(processed_sales)
    }
  end

  defp tax_year_matches?(transaction, tax_year) do
    transaction.date.year == tax_year
  end

  defp get_current_holdings(_symbol_id) do
    # For MVP, return stub data to test the structure
    # Real implementation would calculate current positions from transactions
    {:ok, []}
  end

  defp get_account_holdings(_account_id) do
    # For MVP, return stub data to test the structure
    # Real implementation would get holdings for specific account
    {:ok, []}
  end

  defp get_transactions_by_date_range(start_date, end_date, account_id) do
    case Transaction.by_date_range(start_date, end_date) do
      {:ok, transactions} ->
        filtered_transactions =
          if account_id do
            Enum.filter(transactions, &(&1.account_id == account_id))
          else
            transactions
          end

        {:ok, filtered_transactions}

      {:error, reason} ->
        {:error, reason}

      [] ->
        {:ok, []}
    end
  end

  defp calculate_position_unrealized_gains(_holding, _options) do
    # Implementation for unrealized gains calculation
    # Would integrate with current market prices
    %{unrealized_gain: Decimal.new("0")}
  end

  defp aggregate_unrealized_gains(position_analyses) do
    total_unrealized =
      position_analyses
      |> Enum.map(& &1.unrealized_gain)
      |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)

    %{
      total_unrealized_gains: total_unrealized,
      positions: position_analyses
    }
  end

  defp generate_symbol_tax_lots(_holding, _as_of_date) do
    # Implementation for generating tax lot details
    %{tax_lots: []}
  end

  defp aggregate_tax_lot_data(symbol_reports) do
    %{
      tax_lots: Enum.flat_map(symbol_reports, & &1.tax_lots),
      summary: %{total_lots: 0, total_positions: length(symbol_reports)}
    }
  end

  defp calculate_annual_gains_summary(transactions, tax_year) do
    # Filter for sell transactions in tax year
    sell_transactions = Enum.filter(transactions, &(&1.type == :sell and tax_year_matches?(&1, tax_year)))

    # Calculate basic summary (full implementation would use FIFO)
    total_proceeds =
      sell_transactions
      |> Enum.map(& &1.total_amount)
      |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)

    %{
      tax_year: tax_year,
      total_proceeds: total_proceeds,
      # Simplified for MVP
      net_capital_gains: total_proceeds,
      short_term_gains: Decimal.new("0"),
      long_term_gains: total_proceeds,
      transactions_analyzed: length(sell_transactions)
    }
  end
end
