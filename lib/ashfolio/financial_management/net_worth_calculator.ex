defmodule Ashfolio.FinancialManagement.NetWorthCalculator do
  @moduledoc """
  Net worth calculation module for comprehensive financial management.

  Combines investment portfolio values with cash account balances to provide
  complete net worth calculations across all account types.

  Key calculations:
  - Total net worth (investments + cash)
  - Investment vs cash breakdown
  - Account-level breakdown by type
  - Real-time updates via PubSub integration
  """

  alias Ashfolio.Portfolio.{Calculator, Account}
  alias Ashfolio.ErrorHandler
  require Logger

  @doc """
  Calculate total net worth for a user across all account types.

  Performance optimized: Uses database-level filtering instead of in-memory operations
  to achieve <100ms target performance. Database aggregation reduces query overhead.

  Combines investment portfolio value from Portfolio.Calculator with
  cash account balances to provide comprehensive net worth.

  ## Examples

      iex> NetWorthCalculator.calculate_net_worth(user_id)
      {:ok, %{
        net_worth: %Decimal{},
        investment_value: %Decimal{},
        cash_value: %Decimal{},
        breakdown: %{...}
      }}

      iex> NetWorthCalculator.calculate_net_worth("invalid-id")
      {:error, :user_not_found}
  """
  def calculate_net_worth(_user_id \\ nil) do
    Logger.debug("Calculating net worth")

    with {:ok, investment_value} <- Calculator.calculate_portfolio_value(nil),
         {:ok, cash_balances} <- calculate_total_cash_balances(),
         {:ok, breakdown} <- calculate_account_breakdown(nil) do
      net_worth = Decimal.add(investment_value, cash_balances)

      result = %{
        net_worth: net_worth,
        investment_value: investment_value,
        cash_value: cash_balances,
        breakdown: breakdown
      }

      Logger.debug("Net worth calculated: #{inspect(result)}")

      # Broadcast net worth update via PubSub (simplified for database-as-user)
      broadcast_net_worth_update(result)

      {:ok, result}
    else
      error ->
        ErrorHandler.handle_error(error, %{operation: :net_worth_calculation})
    end
  end

  @doc """
  Calculate total cash balances across all cash accounts for a user.

  Sums balances from checking, savings, money market, and CD accounts
  that are not excluded from calculations.

  ## Examples

      iex> NetWorthCalculator.calculate_total_cash_balances(user_id)
      {:ok, %Decimal{}}

      iex> NetWorthCalculator.calculate_total_cash_balances("invalid-id")
      {:error, :user_not_found}
  """
  def calculate_total_cash_balances(_user_id \\ nil) do
    Logger.debug("Calculating total cash balances")

    try do
      # Performance optimization: Use database-level filtering instead of in-memory
      # Combine cash account type filter with active (non-excluded) filter at the database level
      case get_active_cash_accounts() do
        {:ok, active_cash_accounts} ->
          total_cash =
            active_cash_accounts
            |> Enum.map(& &1.balance)
            |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

          Logger.debug("Total cash balances calculated: #{total_cash}")
          {:ok, total_cash}

        error ->
          ErrorHandler.handle_error(error, %{operation: :cash_balance_calculation})
      end
    rescue
      error ->
        ErrorHandler.handle_error({:error, :net_worth_calculation_failed}, %{
          operation: :cash_balance_calculation, 
          exception: error
        })
    end
  end

  @doc """
  Calculate detailed account breakdown by type for a user.

  TODO: Performance optimization - Consider batch loading with single query and 
  preloading to improve from current ~144ms to <75ms target (see Task 14 Stage 2)

  Provides breakdown of net worth by account type including:
  - Investment accounts (with portfolio value)
  - Cash accounts by type (checking, savings, etc.)
  - Account-level details

  ## Examples

      iex> NetWorthCalculator.calculate_account_breakdown(user_id)
      {:ok, %{
        investment_accounts: [...],
        cash_accounts: [...],
        totals_by_type: %{...}
      }}
  """
  def calculate_account_breakdown(_user_id) do
    Logger.debug("Calculating account breakdown")

    try do
      # Performance optimization: Use database-level filtering instead of loading all accounts
      with {:ok, investment_accounts} <- get_active_investment_accounts(),
           {:ok, cash_accounts} <- get_active_cash_accounts() do

        # Calculate investment account breakdown
        investment_breakdown = calculate_investment_account_breakdown(investment_accounts)

        # Calculate cash account breakdown
        cash_breakdown = calculate_cash_account_breakdown(cash_accounts)

        # Calculate totals by type
        totals_by_type = calculate_totals_by_type(investment_breakdown, cash_breakdown)

        breakdown = %{
          investment_accounts: investment_breakdown,
          cash_accounts: cash_breakdown,
          totals_by_type: totals_by_type
        }

        Logger.debug("Account breakdown calculated: #{inspect(breakdown)}")
        {:ok, breakdown}
      end
    rescue
      error ->
        ErrorHandler.handle_error({:error, :net_worth_calculation_failed}, %{
          operation: :account_breakdown_calculation,
          exception: error
        })
    end
  end

  # Private helper functions

  # Performance optimization: Database-level filtering for active cash accounts
  defp get_active_cash_accounts() do
    require Ash.Query
    
    # Combine both filters at database level: cash account types + not excluded
    query = 
      Account
      |> Ash.Query.filter(account_type in [:checking, :savings, :money_market, :cd])
      |> Ash.Query.filter(is_excluded == false)
    
    case Ash.read(query) do
      {:ok, accounts} -> {:ok, accounts}
      {:error, reason} -> {:error, reason}
    end
  end

  # Performance optimization: Database-level filtering for active investment accounts
  defp get_active_investment_accounts() do
    require Ash.Query
    
    # Combine both filters at database level: investment account type + not excluded
    query = 
      Account
      |> Ash.Query.filter(account_type == :investment)
      |> Ash.Query.filter(is_excluded == false)
    
    case Ash.read(query) do
      {:ok, accounts} -> {:ok, accounts}
      {:error, reason} -> {:error, reason}
    end
  end

  defp calculate_investment_account_breakdown(investment_accounts) do
    Enum.map(investment_accounts, fn account ->
      # Calculate actual portfolio value for investment accounts
      portfolio_value = 
        case Ashfolio.Portfolio.Calculator.calculate_account_portfolio_value(account.id) do
          {:ok, value} -> value
          _error -> account.balance  # Fallback to balance if calculation fails
        end

      %{
        id: account.id,
        name: account.name,
        type: account.account_type,
        platform: account.platform,
        balance: account.balance,
        value: portfolio_value,  # Now uses actual portfolio value
        updated_at: account.balance_updated_at
      }
    end)
  end

  defp calculate_cash_account_breakdown(cash_accounts) do
    Enum.map(cash_accounts, fn account ->
      %{
        id: account.id,
        name: account.name,
        type: account.account_type,
        platform: account.platform,
        balance: account.balance,
        value: account.balance,
        interest_rate: account.interest_rate,
        minimum_balance: account.minimum_balance,
        updated_at: account.balance_updated_at
      }
    end)
  end

  defp calculate_totals_by_type(investment_breakdown, cash_breakdown) do
    investment_total =
      investment_breakdown
      |> Enum.map(& &1.value)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    cash_totals_by_type =
      cash_breakdown
      |> Enum.group_by(& &1.type)
      |> Enum.map(fn {type, accounts} ->
        total =
          accounts
          |> Enum.map(& &1.value)
          |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        {type, total}
      end)
      |> Enum.into(%{})

    total_cash =
      cash_totals_by_type
      |> Map.values()
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    %{
      investment: investment_total,
      cash: total_cash,
      cash_by_type: cash_totals_by_type
    }
  end

  defp broadcast_net_worth_update(net_worth_data) do
    try do
      # Broadcast to general net worth topic for dashboard updates
      Phoenix.PubSub.broadcast(
        Ashfolio.PubSub,
        "net_worth",
        {:net_worth_updated, net_worth_data}
      )

      Logger.debug("Net worth update broadcasted")
    rescue
      error ->
        Logger.warning("Failed to broadcast net worth update: #{inspect(error)}")
    end
  end
end
