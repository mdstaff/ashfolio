defmodule Ashfolio.Portfolio.Calculator do
  @moduledoc """
  Simple portfolio calculations for Ashfolio Phase 1.

  Provides basic portfolio value calculations, return percentages, and individual
  position gains/losses using simple formulas suitable for Phase 1 scope.

  Key calculations:
  - Total portfolio value (sum of holdings)
  - Simple return percentage: (current_value - cost_basis) / cost_basis * 100
  - Individual position gains/losses
  - Cost basis calculation from transaction history
  """

  alias Ashfolio.Portfolio.{Transaction, Symbol, Account}
  require Logger

  @doc """
  Calculate the total portfolio value for the database-as-user architecture.

  Returns the sum of all current holdings values across all accounts.

  ## Examples

      iex> Calculator.calculate_portfolio_value()
      {:ok, %Decimal{}}
  """
  def calculate_portfolio_value(_user_id \\ nil) do
    Logger.debug("Calculating portfolio value")

    case get_all_holdings() do
      {:ok, holdings} ->
        total_value =
          holdings
          |> Enum.map(&calculate_holding_value/1)
          |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        Logger.debug("Total portfolio value calculated: #{total_value}")
        {:ok, total_value}

      {:error, reason} ->
        Logger.warning("Failed to calculate portfolio value: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculate simple return percentage using the formula:
  (current_value - cost_basis) / cost_basis * 100

  ## Examples

      iex> Calculator.calculate_simple_return(Decimal.new(1500), Decimal.new(1000))
      {:ok, Decimal.new(50.0)}

      iex> Calculator.calculate_simple_return(Decimal.new(800), Decimal.new(1000))
      {:ok, Decimal.new(-20.0)}
  """
  def calculate_simple_return(current_value, cost_basis) do
    cond do
      Decimal.equal?(cost_basis, 0) ->
        {:ok, Decimal.new(0)}

      true ->
        # (current_value - cost_basis) / cost_basis * 100
        difference = Decimal.sub(current_value, cost_basis)

        percentage =
          difference
          |> Decimal.div(cost_basis)
          |> Decimal.mult(100)

        {:ok, percentage}
    end
  end

  @doc """
  Calculate individual position gains/losses for all holdings.

  Returns a list of position data with current values, cost basis, and returns.

  ## Examples

      iex> Calculator.calculate_position_returns()
      {:ok, [%{symbol: "AAPL", current_value: %Decimal{}, cost_basis: %Decimal{}, return_pct: %Decimal{}}]}
  """
  def calculate_position_returns(_user_id \\ nil) do
    Logger.debug("Calculating position returns")

    case get_all_holdings() do
      {:ok, holdings} ->
        positions =
          holdings
          |> Enum.map(&calculate_position_data/1)
          |> Enum.filter(fn position -> position.quantity != Decimal.new(0) end)

        {:ok, positions}

      {:error, reason} ->
        Logger.warning("Failed to calculate position returns: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculate portfolio value for a specific account.

  Returns the total value of all holdings in the given account.
  For cash accounts, this should return the account balance.
  For investment accounts, this calculates the current market value of all holdings.

  ## Examples

      iex> Calculator.calculate_account_portfolio_value(account_id)
      {:ok, %Decimal{}}
  """
  def calculate_account_portfolio_value(account_id) when is_binary(account_id) do
    Logger.debug("Calculating portfolio value for account: #{account_id}")

    case get_holdings_for_account(account_id) do
      [] ->
        # No holdings in this account
        {:ok, Decimal.new(0)}

      transactions ->
        holdings = group_holdings_by_symbol(transactions)
        
        total_value =
          holdings
          |> Enum.map(&calculate_holding_value/1)
          |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        Logger.debug("Account #{account_id} portfolio value: #{total_value}")
        {:ok, total_value}
    end
  end

  @doc """
  Get total return tracking data for the portfolio.

  Returns portfolio summary with total value, cost basis, and return percentage.
  """
  def calculate_total_return(_user_id \\ nil) do
    Logger.debug("Calculating total return")

    with {:ok, portfolio_value} <- calculate_portfolio_value(),
         {:ok, total_cost_basis} <- calculate_total_cost_basis(),
         {:ok, return_percentage} <- calculate_simple_return(portfolio_value, total_cost_basis) do
      summary = %{
        total_value: portfolio_value,
        cost_basis: total_cost_basis,
        return_percentage: return_percentage,
        dollar_return: Decimal.sub(portfolio_value, total_cost_basis)
      }

      Logger.debug("Total return calculated: #{inspect(summary)}")
      {:ok, summary}
    else
      {:error, reason} ->
        Logger.warning("Failed to calculate total return: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp get_all_holdings() do
    try do
      # Get all accounts (excluding excluded accounts) - database-as-user architecture
      case Account.list() do
        {:ok, accounts} ->
          active_accounts =
            Enum.filter(accounts, fn account ->
              not account.is_excluded
            end)

          if Enum.empty?(active_accounts) do
            Logger.debug("No active accounts found")
            {:ok, []}
          else
            # Get all transactions for these accounts
            account_ids = Enum.map(active_accounts, & &1.id)

            holdings =
              account_ids
              |> Enum.flat_map(&get_holdings_for_account/1)
              |> group_holdings_by_symbol()

            {:ok, holdings}
          end

        {:error, reason} ->
          Logger.warning("Failed to get accounts: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      error ->
        Logger.error("Error getting holdings: #{inspect(error)}")
        {:error, :calculation_error}
    end
  end

  defp get_holdings_for_account(account_id) do
    # Get all buy/sell transactions for this account
    case Transaction.by_account(account_id) do
      {:ok, transactions} ->
        Enum.filter(transactions, fn transaction ->
          transaction.type in [:buy, :sell]
        end)

      {:error, _reason} ->
        []
    end
  end

  defp group_holdings_by_symbol(transactions) do
    transactions
    |> Enum.group_by(& &1.symbol_id)
    |> Enum.map(fn {symbol_id, symbol_transactions} ->
      # Calculate net quantity and weighted average cost
      {net_quantity, total_cost} = calculate_position_summary(symbol_transactions)

      # Get symbol data
      symbol =
        case Symbol.get_by_id(symbol_id) do
          {:ok, symbol} -> symbol
          _ -> nil
        end

      %{
        symbol_id: symbol_id,
        symbol: symbol,
        quantity: net_quantity,
        cost_basis: total_cost,
        transactions: symbol_transactions
      }
    end)
    |> Enum.filter(fn holding -> holding.symbol != nil end)
  end

  defp calculate_position_summary(transactions) do
    Enum.reduce(transactions, {Decimal.new(0), Decimal.new(0)}, fn transaction,
                                                                   {net_qty, total_cost} ->
      case transaction.type do
        :buy ->
          new_qty = Decimal.add(net_qty, transaction.quantity)
          new_cost = Decimal.add(total_cost, transaction.total_amount)
          {new_qty, new_cost}

        :sell ->
          # For sells, quantity is negative, so we add it (which subtracts)
          new_qty = Decimal.add(net_qty, transaction.quantity)
          # For cost basis, we need to reduce it proportionally
          # Guard against division by zero when net_qty is 0
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

  defp calculate_holding_value(holding) do
    current_price = get_current_price(holding.symbol)

    if current_price do
      Decimal.mult(holding.quantity, current_price)
    else
      Decimal.new(0)
    end
  end

  defp calculate_position_data(holding) do
    current_price = get_current_price(holding.symbol)

    current_value =
      if current_price do
        Decimal.mult(holding.quantity, current_price)
      else
        Decimal.new(0)
      end

    {:ok, return_pct} = calculate_simple_return(current_value, holding.cost_basis)

    %{
      symbol_id: holding.symbol_id,
      symbol: holding.symbol.symbol,
      name: holding.symbol.name,
      quantity: holding.quantity,
      current_price: current_price,
      current_value: current_value,
      cost_basis: holding.cost_basis,
      return_percentage: return_pct,
      dollar_return: Decimal.sub(current_value, holding.cost_basis)
    }
  end

  defp get_current_price(symbol) do
    case symbol.current_price do
      nil ->
        # Try to get from cache as fallback
        case Ashfolio.Cache.get_price(symbol.symbol) do
          {:ok, cached_data} -> cached_data.price
          _ -> nil
        end

      price ->
        price
    end
  end

  defp calculate_total_cost_basis() do
    case get_all_holdings() do
      {:ok, holdings} ->
        total_cost =
          holdings
          |> Enum.map(& &1.cost_basis)
          |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        {:ok, total_cost}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
