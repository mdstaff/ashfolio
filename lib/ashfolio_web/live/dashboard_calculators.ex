defmodule AshfolioWeb.Live.DashboardCalculators do
  @moduledoc """
  Calculator functions for dashboard metrics and financial data.

  Provides pure functions for calculating net worth, expenses, and other
  financial metrics displayed on the dashboard.
  """

  alias Ashfolio.Portfolio.Account

  @doc """
  Calculates current net worth from portfolio accounts.
  """
  def calculate_current_net_worth do
    # Calculate from current account balances
    case Account |> Ash.Query.for_read(:read) |> Ash.read!() do
      [] ->
        Decimal.new(0)

      accounts ->
        Enum.reduce(accounts, Decimal.new(0), fn account, acc ->
          Decimal.add(acc, account.balance)
        end)
    end
  end

  @doc """
  Calculates total cash across all cash accounts.
  """
  def calculate_total_cash do
    # Sum cash account balances
    case Account.cash_accounts!() do
      [] ->
        Decimal.new(0)

      accounts ->
        Enum.reduce(accounts, Decimal.new(0), fn account, acc ->
          Decimal.add(acc, account.balance)
        end)
    end
  end

  @doc """
  Calculates total investment value across all investment accounts.
  """
  def calculate_total_investments do
    # Sum investment account balances
    case Account.investment_accounts!() do
      [] ->
        Decimal.new(0)

      accounts ->
        Enum.reduce(accounts, Decimal.new(0), fn account, acc ->
          Decimal.add(acc, account.balance)
        end)
    end
  end

  @doc """
  Calculates expenses for the current month.
  """
  def calculate_current_month_expenses(expenses) do
    now = Date.utc_today()
    start_of_month = Date.beginning_of_month(now)

    expenses
    |> Enum.filter(fn expense ->
      Date.compare(expense.date, start_of_month) in [:gt, :eq]
    end)
    |> calculate_total_expenses()
  end

  @doc """
  Calculates total expenses from a list of expenses.
  """
  def calculate_total_expenses(expenses) do
    Enum.reduce(expenses, Decimal.new("0"), fn expense, acc ->
      Decimal.add(acc, expense.amount || Decimal.new("0"))
    end)
  end

  @doc """
  Builds data for creating a net worth snapshot.
  """
  def build_snapshot_data do
    current_net_worth = calculate_current_net_worth()
    total_assets = current_net_worth
    total_liabilities = Decimal.new("0.00")
    net_worth = Decimal.sub(total_assets, total_liabilities)

    %{
      snapshot_date: Date.utc_today(),
      total_assets: total_assets,
      total_liabilities: total_liabilities,
      net_worth: net_worth,
      cash_value: calculate_total_cash(),
      investment_value: calculate_total_investments(),
      is_automated: false
    }
  end

  @doc """
  Calculates portfolio growth metrics.
  """
  def calculate_portfolio_growth(historical_snapshots) do
    case historical_snapshots do
      [] ->
        %{amount: Decimal.new("0"), percentage: Decimal.new("0")}

      [latest | _] ->
        current = calculate_current_net_worth()
        previous = latest.net_worth || Decimal.new("0")

        amount = Decimal.sub(current, previous)

        percentage =
          if Decimal.compare(previous, Decimal.new("0")) == :gt do
            amount
            |> Decimal.div(previous)
            |> Decimal.mult(Decimal.new("100"))
          else
            Decimal.new("0")
          end

        %{amount: amount, percentage: percentage}
    end
  end

  @doc """
  Groups holdings by account for display.
  """
  def group_holdings_by_account(holdings) do
    holdings
    |> Enum.group_by(& &1.account_id)
    |> Map.new(fn {account_id, account_holdings} ->
      total_value =
        Enum.reduce(account_holdings, Decimal.new("0"), fn holding, acc ->
          Decimal.add(acc, holding.total_value || Decimal.new("0"))
        end)

      {account_id, %{holdings: account_holdings, total_value: total_value}}
    end)
  end
end
