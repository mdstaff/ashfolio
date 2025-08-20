defmodule Ashfolio.FinancialManagement.NetWorthCalculator do
  @moduledoc """
  NetWorthCalculator calculates and manages net worth snapshots.

  Aggregates balances across all account types (investment, cash) to compute
  total net worth and creates historical snapshots for tracking progress.
  """

  alias Ashfolio.Portfolio.Account
  alias Ashfolio.FinancialManagement.NetWorthSnapshot

  @doc """
  Calculates current net worth from all accounts.

  Returns a map with:
  - total_assets: Sum of all account balances
  - total_liabilities: Always 0 for now (future: debt tracking)
  - net_worth: total_assets - total_liabilities
  - investment_value: Sum of investment account balances
  - cash_value: Sum of cash account balances
  - other_assets_value: Always 0 for now (future: real estate, etc.)
  """
  def calculate_current_net_worth do
    # Use account balances for both investment and cash accounts for net worth snapshots
    investment_total = calculate_investment_accounts_value()
    cash_total = calculate_cash_accounts_value()

    # Future: Add other assets and liabilities
    other_assets = Decimal.new(0)
    liabilities = Decimal.new(0)

    total_assets =
      investment_total
      |> Decimal.add(cash_total)
      |> Decimal.add(other_assets)

    net_worth = Decimal.sub(total_assets, liabilities)

    # Get breakdown data
    {:ok, breakdown} = calculate_account_breakdown()

    result = %{
      total_assets: total_assets,
      total_liabilities: liabilities,
      net_worth: net_worth,
      investment_value: investment_total,
      cash_value: cash_total,
      other_assets_value: other_assets,
      breakdown: breakdown
    }

    {:ok, result}
  end

  @doc """
  Creates a net worth snapshot for a specific date.

  If no date is provided, uses today's date.
  """
  def create_snapshot(snapshot_date \\ nil) do
    snapshot_date = snapshot_date || Date.utc_today()
    {:ok, calculation} = calculate_current_net_worth()

    # Remove breakdown field as it's not part of NetWorthSnapshot schema
    snapshot_data =
      calculation
      |> Map.delete(:breakdown)
      |> Map.merge(%{
        snapshot_date: snapshot_date,
        is_automated: true
      })

    NetWorthSnapshot.create(snapshot_data)
  end

  @doc """
  Calculates total cash balances across all cash accounts.

  Returns the sum of balances for checking, savings, money market, and CD accounts.
  """
  def calculate_total_cash_balances do
    total = calculate_cash_accounts_value()
    {:ok, total}
  end

  @doc """
  Provides detailed breakdown by account type.

  Returns a map with accounts grouped by investment vs cash, plus totals.
  """
  def calculate_account_breakdown do
    require Ash.Query

    # Get all non-excluded accounts
    accounts =
      Account
      |> Ash.Query.filter(is_excluded == false)
      |> Ash.read!()

    # Separate investment and cash accounts
    investment_accounts = Enum.filter(accounts, &(&1.account_type == :investment))
    cash_account_types = [:checking, :savings, :money_market, :cd]
    cash_accounts = Enum.filter(accounts, &(&1.account_type in cash_account_types))

    # Calculate totals
    investment_total =
      investment_accounts
      |> Enum.map(& &1.balance)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    cash_total =
      cash_accounts
      |> Enum.map(& &1.balance)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    # Calculate cash breakdown by type
    cash_by_type =
      cash_accounts
      |> Enum.group_by(& &1.account_type)
      |> Enum.map(fn {type, accts} ->
        total =
          accts
          |> Enum.map(& &1.balance)
          |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        {type, total}
      end)
      |> Enum.into(%{})

    breakdown = %{
      investment_accounts: investment_accounts,
      cash_accounts: cash_accounts,
      totals_by_type: %{
        investment: investment_total,
        cash: cash_total,
        cash_by_type: cash_by_type
      }
    }

    {:ok, breakdown}
  end

  # Private helper functions

  defp calculate_investment_accounts_value do
    require Ash.Query

    Account
    |> Ash.Query.filter(account_type == :investment)
    |> Ash.Query.filter(is_excluded == false)
    |> Ash.read!()
    |> Enum.map(& &1.balance)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end

  defp calculate_cash_accounts_value do
    require Ash.Query

    cash_account_types = [:checking, :savings, :money_market, :cd]

    Account
    |> Ash.Query.filter(account_type in ^cash_account_types)
    |> Ash.Query.filter(is_excluded == false)
    |> Ash.read!()
    |> Enum.map(& &1.balance)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end
end
