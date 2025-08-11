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
  require Logger

  @doc """
  Calculate total net worth for a user across all account types.

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
  def calculate_net_worth(user_id) when is_binary(user_id) do
    Logger.debug("Calculating net worth for user: #{user_id}")

    with {:ok, investment_value} <- Calculator.calculate_portfolio_value(user_id),
         {:ok, cash_balances} <- calculate_total_cash_balances(user_id),
         {:ok, breakdown} <- calculate_account_breakdown(user_id) do

      net_worth = Decimal.add(investment_value, cash_balances)

      result = %{
        net_worth: net_worth,
        investment_value: investment_value,
        cash_value: cash_balances,
        breakdown: breakdown
      }

      Logger.debug("Net worth calculated: #{inspect(result)}")

      # Broadcast net worth update via PubSub
      broadcast_net_worth_update(user_id, result)

      {:ok, result}
    else
      {:error, reason} ->
        Logger.warning("Failed to calculate net worth: #{inspect(reason)}")
        {:error, reason}
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
  def calculate_total_cash_balances(user_id) when is_binary(user_id) do
    Logger.debug("Calculating total cash balances for user: #{user_id}")

    try do
      case Account.cash_accounts() do
        {:ok, all_cash_accounts} ->
          # Filter for user's accounts that are not excluded
          user_cash_accounts =
            all_cash_accounts
            |> Enum.filter(fn account ->
              account.user_id == user_id and not account.is_excluded
            end)

          total_cash =
            user_cash_accounts
            |> Enum.map(& &1.balance)
            |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

          Logger.debug("Total cash balances calculated: #{total_cash}")
          {:ok, total_cash}

        {:error, reason} ->
          Logger.warning("Failed to get cash accounts: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      error ->
        Logger.error("Error calculating cash balances: #{inspect(error)}")
        {:error, :calculation_error}
    end
  end

  @doc """
  Calculate detailed account breakdown by type for a user.

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
  def calculate_account_breakdown(user_id) when is_binary(user_id) do
    Logger.debug("Calculating account breakdown for user: #{user_id}")

    try do
      with {:ok, all_accounts} <- Account.accounts_for_user(user_id) do
        # Filter active accounts only
        active_accounts = Enum.filter(all_accounts, fn account -> not account.is_excluded end)

        # Separate by account type
        {investment_accounts, cash_accounts} =
          Enum.split_with(active_accounts, fn account ->
            account.account_type == :investment
          end)

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
        Logger.error("Error calculating account breakdown: #{inspect(error)}")
        {:error, :calculation_error}
    end
  end

  # Private helper functions

  defp calculate_investment_account_breakdown(investment_accounts) do
    Enum.map(investment_accounts, fn account ->
      # For investment accounts, we need to calculate the portfolio value
      # This is simplified - in a full implementation, we'd calculate per-account portfolio values
      %{
        id: account.id,
        name: account.name,
        type: account.account_type,
        platform: account.platform,
        balance: account.balance,
        value: account.balance, # Simplified - would need per-account portfolio calculation
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

  defp broadcast_net_worth_update(user_id, net_worth_data) do
    try do
      Phoenix.PubSub.broadcast(
        Ashfolio.PubSub,
        "net_worth:#{user_id}",
        {:net_worth_updated, net_worth_data}
      )

      # Also broadcast to general net worth topic for dashboard updates
      Phoenix.PubSub.broadcast(
        Ashfolio.PubSub,
        "net_worth",
        {:net_worth_updated, user_id, net_worth_data}
      )

      Logger.debug("Net worth update broadcasted for user: #{user_id}")
    rescue
      error ->
        Logger.warning("Failed to broadcast net worth update: #{inspect(error)}")
    end
  end
end
