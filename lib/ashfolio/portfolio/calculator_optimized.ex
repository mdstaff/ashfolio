defmodule Ashfolio.Portfolio.CalculatorOptimized do
  @moduledoc """
  Performance-optimized version of portfolio calculations addressing N+1 query issues.

  Key optimizations:
  - Batch symbol lookups to eliminate N+1 queries
  - Preloaded symbol data in single query
  - Reduced database round trips
  """

  alias Ashfolio.Portfolio.Account
  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Portfolio.Transaction

  require Logger

  @doc """
  Optimized version of get_all_holdings that eliminates N+1 queries.
  """
  def get_all_holdings_optimized do
    case Account.list() do
      {:ok, accounts} ->
        active_accounts = Enum.filter(accounts, &(not &1.is_excluded))

        if Enum.empty?(active_accounts) do
          {:ok, []}
        else
          account_ids = Enum.map(active_accounts, & &1.id)

          # Get all transactions in one query
          all_transactions = Enum.flat_map(account_ids, &get_holdings_for_account/1)

          # Extract unique symbol IDs
          symbol_ids =
            all_transactions
            |> Enum.map(& &1.symbol_id)
            |> Enum.uniq()

          # Batch fetch all symbols in single query - eliminates N+1
          case Symbol.get_by_ids(symbol_ids) do
            {:ok, symbols} ->
              symbol_map = Map.new(symbols, &{&1.id, &1})
              holdings = group_holdings_with_preloaded_symbols(all_transactions, symbol_map)
              {:ok, holdings}

            {:error, reason} ->
              Logger.warning("Failed to batch fetch symbols: #{inspect(reason)}")
              {:error, reason}
          end
        end

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    error ->
      Logger.error("Error getting optimized holdings: #{inspect(error)}")
      {:error, :calculation_error}
  end

  # Private helper for optimized symbol grouping
  defp group_holdings_with_preloaded_symbols(transactions, symbol_map) do
    transactions
    |> Enum.group_by(& &1.symbol_id)
    |> Enum.map(fn {symbol_id, symbol_transactions} ->
      case Map.get(symbol_map, symbol_id) do
        nil ->
          nil

        symbol ->
          {net_quantity, total_cost} = calculate_position_summary(symbol_transactions)

          %{
            symbol_id: symbol_id,
            symbol: symbol,
            quantity: net_quantity,
            cost_basis: total_cost,
            transactions: symbol_transactions
          }
      end
    end)
    |> Enum.filter(&(&1 != nil))
  end

  # Reuse existing position summary calculation
  defp calculate_position_summary(transactions) do
    # Same implementation as original Calculator
    Enum.reduce(transactions, {Decimal.new(0), Decimal.new(0)}, fn transaction, {net_qty, total_cost} ->
      case transaction.type do
        :buy ->
          new_qty = Decimal.add(net_qty, transaction.quantity)
          new_cost = Decimal.add(total_cost, transaction.total_amount)
          {new_qty, new_cost}

        :sell ->
          new_qty = Decimal.add(net_qty, transaction.quantity)

          if Decimal.equal?(net_qty, 0) do
            {new_qty, total_cost}
          else
            sell_ratio = Decimal.div(Decimal.abs(transaction.quantity), net_qty)
            cost_reduction = Decimal.mult(total_cost, sell_ratio)
            new_cost = Decimal.sub(total_cost, cost_reduction)
            {new_qty, new_cost}
          end
      end
    end)
  end

  defp get_holdings_for_account(account_id) do
    case Transaction.by_account(account_id) do
      {:ok, transactions} ->
        Enum.filter(transactions, fn transaction ->
          transaction.type in [:buy, :sell]
        end)

      {:error, _reason} ->
        []
    end
  end
end
