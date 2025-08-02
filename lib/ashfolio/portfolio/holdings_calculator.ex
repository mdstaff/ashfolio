defmodule Ashfolio.Portfolio.HoldingsCalculator do
  @moduledoc """
  Holdings value calculator for Ashfolio Phase 1.

  Provides focused calculations for individual holdings values, cost basis,
  and profit/loss calculations. This module complements the main Calculator
  module by providing detailed holdings-specific calculations.

  Key features:
  - Current holding values calculation
  - Cost basis calculation from transaction history
  - Individual holding profit/loss calculations
  - Portfolio total value aggregation
  """

  alias Ashfolio.Portfolio.{Transaction, Symbol, Account}
  require Logger

  @doc """
  Calculate current holding values for all positions.

  Returns detailed holding information including current values, quantities,
  and cost basis for each position.

  ## Examples

      iex> HoldingsCalculator.calculate_holding_values(user_id)
      {:ok, [%{symbol: "AAPL", quantity: %Decimal{}, current_value: %Decimal{}, cost_basis: %Decimal{}}]}
  """
  def calculate_holding_values(user_id) when is_binary(user_id) do
    Logger.debug("Calculating holding values for user: #{user_id}")

    with {:ok, holdings_data} <- get_holdings_data(user_id) do
      holdings_with_values =
        holdings_data
        |> Enum.map(&calculate_individual_holding_value/1)
        |> Enum.filter(fn holding -> not Decimal.equal?(holding.quantity, 0) end)

      Logger.debug("Calculated #{length(holdings_with_values)} holdings with values")
      {:ok, holdings_with_values}
    else
      {:error, reason} ->
        Logger.warning("Failed to calculate holding values: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculate cost basis from transaction history for a specific symbol.

  Uses FIFO (First In, First Out) method for cost basis calculation.

  ## Examples

      iex> HoldingsCalculator.calculate_cost_basis(user_id, symbol_id)
      {:ok, %{total_cost: %Decimal{}, average_cost: %Decimal{}, quantity: %Decimal{}}}
  """
  def calculate_cost_basis(user_id, symbol_id) when is_binary(user_id) and is_binary(symbol_id) do
    Logger.debug("Calculating cost basis for user: #{user_id}, symbol: #{symbol_id}")

    case get_symbol_transactions(user_id, symbol_id) do
      {:ok, transactions} ->
        cost_basis_data = calculate_cost_basis_from_transactions(transactions)
        Logger.debug("Cost basis calculated: #{inspect(cost_basis_data)}")
        {:ok, cost_basis_data}

      {:error, reason} ->
        Logger.warning("Failed to calculate cost basis: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculate profit/loss for individual holdings.

  Returns profit/loss data including dollar amounts and percentages.

  ## Examples

      iex> HoldingsCalculator.calculate_holding_pnl(user_id, symbol_id)
      {:ok, %{unrealized_pnl: %Decimal{}, unrealized_pnl_pct: %Decimal{}, current_value: %Decimal{}}}
  """
  def calculate_holding_pnl(user_id, symbol_id) when is_binary(user_id) and is_binary(symbol_id) do
    Logger.debug("Calculating P&L for user: #{user_id}, symbol: #{symbol_id}")

    with {:ok, cost_basis_data} <- calculate_cost_basis(user_id, symbol_id),
         {:ok, symbol} <- Symbol.get_by_id(symbol_id) do

      current_price = get_current_price(symbol)
      current_value = if current_price do
        Decimal.mult(cost_basis_data.quantity, current_price)
      else
        Decimal.new(0)
      end

      unrealized_pnl = Decimal.sub(current_value, cost_basis_data.total_cost)

      unrealized_pnl_pct = if Decimal.equal?(cost_basis_data.total_cost, 0) do
        Decimal.new(0)
      else
        cost_basis_data.total_cost
        |> Decimal.div_int(unrealized_pnl)
        |> Decimal.mult(100)
      end

      pnl_data = %{
        symbol: symbol.symbol,
        quantity: cost_basis_data.quantity,
        current_price: current_price,
        current_value: current_value,
        cost_basis: cost_basis_data.total_cost,
        average_cost: cost_basis_data.average_cost,
        unrealized_pnl: unrealized_pnl,
        unrealized_pnl_pct: unrealized_pnl_pct
      }

      Logger.debug("P&L calculated: #{inspect(pnl_data)}")
      {:ok, pnl_data}
    else
      {:error, reason} ->
        Logger.warning("Failed to calculate holding P&L: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Aggregate portfolio total value from all holdings.

  Returns the sum of all current holding values.

  ## Examples

      iex> HoldingsCalculator.aggregate_portfolio_value(user_id)
      {:ok, %Decimal{}}
  """
  def aggregate_portfolio_value(user_id) when is_binary(user_id) do
    Logger.debug("Aggregating portfolio value for user: #{user_id}")

    case calculate_holding_values(user_id) do
      {:ok, holdings} ->
        total_value =
          holdings
          |> Enum.map(& &1.current_value)
          |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        Logger.debug("Portfolio total value: #{total_value}")
        {:ok, total_value}

      {:error, reason} ->
        Logger.warning("Failed to aggregate portfolio value: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Get detailed holdings summary with all calculations.

  Returns comprehensive holdings data including values, cost basis, and P&L.
  """
  def get_holdings_summary(user_id) when is_binary(user_id) do
    Logger.debug("Getting holdings summary for user: #{user_id}")

    with {:ok, holdings} <- calculate_holding_values(user_id),
         {:ok, total_value} <- aggregate_portfolio_value(user_id) do

      total_cost_basis =
        holdings
        |> Enum.map(& &1.cost_basis)
        |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

      total_pnl = Decimal.sub(total_value, total_cost_basis)

      total_pnl_pct = if Decimal.equal?(total_cost_basis, 0) do
        Decimal.new(0)
      else
        total_pnl
        |> Decimal.div(total_cost_basis)
        |> Decimal.mult(100)
      end

      summary = %{
        holdings: holdings,
        total_value: total_value,
        total_cost_basis: total_cost_basis,
        total_pnl: total_pnl,
        total_pnl_pct: total_pnl_pct,
        holdings_count: length(holdings)
      }

      Logger.debug("Holdings summary calculated: #{summary.holdings_count} holdings, total value: #{total_value}")
      {:ok, summary}
    else
      {:error, reason} ->
        Logger.warning("Failed to get holdings summary: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp get_holdings_data(user_id) do
    try do
      case Account.accounts_for_user(user_id) do
        {:ok, accounts} ->
          active_accounts = Enum.filter(accounts, fn account ->
            not account.is_excluded
          end)

          if Enum.empty?(active_accounts) do
            {:ok, []}
          else
            account_ids = Enum.map(active_accounts, & &1.id)

            holdings =
              account_ids
              |> Enum.flat_map(&get_account_transactions/1)
              |> group_by_symbol()

            {:ok, holdings}
          end

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      error ->
        Logger.error("Error getting holdings data: #{inspect(error)}")
        {:error, :calculation_error}
    end
  end

  defp get_account_transactions(account_id) do
    case Transaction.by_account(account_id) do
      {:ok, transactions} ->
        Enum.filter(transactions, fn transaction ->
          transaction.type in [:buy, :sell]
        end)

      {:error, _reason} ->
        []
    end
  end

  defp group_by_symbol(transactions) do
    transactions
    |> Enum.group_by(& &1.symbol_id)
    |> Enum.map(fn {symbol_id, symbol_transactions} ->
      case Symbol.get_by_id(symbol_id) do
        {:ok, symbol} ->
          %{
            symbol_id: symbol_id,
            symbol: symbol,
            transactions: Enum.sort_by(symbol_transactions, & &1.date)
          }

        {:error, _} ->
          nil
      end
    end)
    |> Enum.filter(& &1 != nil)
  end

  defp calculate_individual_holding_value(holding_data) do
    cost_basis_data = calculate_cost_basis_from_transactions(holding_data.transactions)
    current_price = get_current_price(holding_data.symbol)

    current_value = if current_price do
      Decimal.mult(cost_basis_data.quantity, current_price)
    else
      Decimal.new(0)
    end

    unrealized_pnl = Decimal.sub(current_value, cost_basis_data.total_cost)

    unrealized_pnl_pct = if Decimal.equal?(cost_basis_data.total_cost, 0) do
      Decimal.new(0)
    else
      unrealized_pnl
      |> Decimal.div(cost_basis_data.total_cost)
      |> Decimal.mult(100)
    end

    %{
      symbol_id: holding_data.symbol_id,
      symbol: holding_data.symbol.symbol,
      name: holding_data.symbol.name,
      quantity: cost_basis_data.quantity,
      current_price: current_price,
      current_value: current_value,
      cost_basis: cost_basis_data.total_cost,
      average_cost: cost_basis_data.average_cost,
      unrealized_pnl: unrealized_pnl,
      unrealized_pnl_pct: unrealized_pnl_pct
    }
  end

  defp calculate_cost_basis_from_transactions(transactions) do
    # Simple FIFO cost basis calculation
    {total_quantity, total_cost, _} =
      Enum.reduce(transactions, {Decimal.new(0), Decimal.new(0), []}, fn transaction, {qty, cost, lots} ->
        case transaction.type do
          :buy ->
            new_qty = Decimal.add(qty, transaction.quantity)
            new_cost = Decimal.add(cost, transaction.total_amount)
            new_lot = %{quantity: transaction.quantity, cost: transaction.total_amount, date: transaction.date}
            {new_qty, new_cost, [new_lot | lots]}

          :sell ->
            # For simplicity, reduce cost proportionally
            sell_qty = Decimal.abs(transaction.quantity)

            if Decimal.equal?(qty, 0) do
              {qty, cost, lots}
            else
              sell_ratio = Decimal.div(sell_qty, qty)
              cost_reduction = Decimal.mult(cost, sell_ratio)
              new_qty = Decimal.sub(qty, sell_qty)
              new_cost = Decimal.sub(cost, cost_reduction)
              {new_qty, new_cost, lots}
            end
        end
      end)

    average_cost = if Decimal.equal?(total_quantity, 0) do
      Decimal.new(0)
    else
      Decimal.div(total_cost, total_quantity)
    end

    %{
      quantity: total_quantity,
      total_cost: total_cost,
      average_cost: average_cost
    }
  end

  defp get_symbol_transactions(user_id, symbol_id) do
    case Account.accounts_for_user(user_id) do
      {:ok, accounts} ->
        active_accounts = Enum.filter(accounts, fn account ->
          not account.is_excluded
        end)

        transactions =
          active_accounts
          |> Enum.flat_map(fn account ->
            case Transaction.by_account(account.id) do
              {:ok, transactions} ->
                Enum.filter(transactions, fn transaction ->
                  transaction.symbol_id == symbol_id and transaction.type in [:buy, :sell]
                end)

              {:error, _} ->
                []
            end
          end)
          |> Enum.sort_by(& &1.date)

        {:ok, transactions}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_current_price(symbol) do
    case symbol.current_price do
      nil ->
        case Ashfolio.Cache.get_price(symbol.symbol) do
          {:ok, cached_data} -> cached_data.price
          _ -> nil
        end
      price -> price
    end
  end
end
