defmodule Ashfolio.FinancialManagement.EmergencyFundCalculator do
  @moduledoc """
  Emergency Fund Calculator for calculating emergency fund targets and tracking progress.

  Provides functions for:
  - Calculating emergency fund targets based on monthly expenses
  - Analyzing average monthly expenses from historical data  
  - Tracking emergency fund goal progress and timeline
  - Auto-creating emergency fund goals based on expense history

  Follows patterns from Expense.ex aggregation and Calculator.ex error handling.
  """

  require Logger
  alias Ashfolio.FinancialManagement.{Expense, FinancialGoal}

  @doc """
  Calculates emergency fund target amount.

  Follows the emergency fund best practice of 3-12 months of expenses,
  defaulting to 6 months as recommended by most financial advisors.

  ## Parameters
  - monthly_expenses: Decimal amount of monthly expenses
  - months: Number of months to cover (default: 6, range: 1-12)

  ## Examples

      iex> EmergencyFundCalculator.calculate_emergency_fund_target(Decimal.new("4000.00"))
      {:ok, #Decimal<24000.00>}

      iex> EmergencyFundCalculator.calculate_emergency_fund_target(Decimal.new("3500.00"), 3)
      {:ok, #Decimal<10500.00>}

  """
  def calculate_emergency_fund_target(monthly_expenses, months \\ 6) do
    Logger.debug("Calculating emergency fund target for #{monthly_expenses}, #{months} months")

    with :ok <- validate_monthly_expenses(monthly_expenses),
         :ok <- validate_months(months) do
      target = Decimal.mult(monthly_expenses, Decimal.new(to_string(months)))
      Logger.debug("Emergency fund target calculated: #{target}")

      {:ok, target}
    else
      {:error, reason} ->
        Logger.warning("Emergency fund target calculation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculates average monthly expenses from historical expense data.

  Uses expense aggregation patterns to analyze spending over a specified period
  and calculate monthly averages for emergency fund planning.

  ## Parameters
  - period_months: Number of months to analyze (default: 12)
  - end_date: End date for analysis (default: today)

  ## Examples

      iex> EmergencyFundCalculator.calculate_monthly_expenses_from_period(12)
      {:ok, #Decimal<3850.00>}

  """
  def calculate_monthly_expenses_from_period(period_months, end_date \\ Date.utc_today()) do
    Logger.debug(
      "Calculating monthly expenses from #{period_months} month period ending #{end_date}"
    )

    with :ok <- validate_period_months(period_months) do
      start_date = Date.add(end_date, -period_months * 30)

      expenses = get_expenses_for_period(start_date, end_date)
      total_amount = calculate_total_expenses(expenses)

      # Calculate monthly average 
      monthly_average =
        if Decimal.equal?(total_amount, Decimal.new("0.00")) do
          Decimal.new("0.00")
        else
          # Simple average: divide total by requested period months
          Decimal.div(total_amount, Decimal.new(to_string(period_months)))
        end

      Logger.debug(
        "Monthly expense average: #{monthly_average} from #{length(expenses)} expenses over #{period_months} months"
      )

      {:ok, monthly_average}
    else
      {:error, reason} ->
        Logger.warning("Monthly expense calculation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculates emergency fund status and progress tracking information.

  Returns comprehensive status including progress percentage, amount remaining,
  and timeline to goal completion based on monthly contributions.

  ## Parameters
  - target_amount: Target emergency fund amount
  - current_amount: Current saved amount toward goal
  - monthly_contribution: Planned monthly savings amount

  ## Returns
  Map containing:
  - target_amount: Target amount
  - current_amount: Current progress amount  
  - amount_remaining: Amount still needed
  - progress_percentage: Completion percentage
  - months_to_goal: Months to reach target (nil if no contribution)
  - goal_achieved: Boolean if goal is complete

  """
  def emergency_fund_status(target_amount, current_amount, monthly_contribution) do
    Logger.debug(
      "Calculating emergency fund status: target=#{target_amount}, current=#{current_amount}, contribution=#{monthly_contribution}"
    )

    amount_remaining = calculate_amount_remaining(target_amount, current_amount)
    progress_percentage = calculate_progress_percentage(target_amount, current_amount)
    {months_to_goal, goal_achieved} = calculate_timeline(amount_remaining, monthly_contribution)

    status = %{
      target_amount: target_amount,
      current_amount: current_amount,
      amount_remaining: amount_remaining,
      progress_percentage: progress_percentage,
      months_to_goal: months_to_goal,
      goal_achieved: goal_achieved
    }

    Logger.debug("Emergency fund status calculated: #{inspect(status)}")
    {:ok, status}
  end

  @doc """
  Auto-creates an emergency fund goal based on recent expense history.

  Analyzes the last 12 months of expenses to determine a target amount,
  then creates a FinancialGoal resource with appropriate defaults.

  ## Parameters
  - months: Number of months of expenses to target (default: 6)

  ## Examples

      iex> EmergencyFundCalculator.auto_create_emergency_fund_goal(6)
      {:ok, %FinancialGoal{name: "Emergency Fund", goal_type: :emergency_fund, ...}}

  """
  def auto_create_emergency_fund_goal(months \\ 6) do
    Logger.debug("Auto-creating emergency fund goal for #{months} months")

    with :ok <- validate_months(months),
         {:ok, monthly_expenses} <- calculate_monthly_expenses_from_period(12),
         {:ok, target_amount} <- calculate_emergency_fund_target(monthly_expenses, months) do
      goal_attrs = %{
        name: "Emergency Fund",
        target_amount: target_amount,
        current_amount: Decimal.new("0.00"),
        goal_type: :emergency_fund,
        monthly_contribution: calculate_suggested_contribution(target_amount),
        is_active: true
      }

      case FinancialGoal.create(goal_attrs) do
        {:ok, goal} ->
          Logger.info("Auto-created emergency fund goal: #{goal.id} with target #{target_amount}")
          {:ok, goal}

        {:error, reason} ->
          Logger.error("Failed to create emergency fund goal: #{inspect(reason)}")
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.warning("Auto-create emergency fund goal failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private helper functions

  defp validate_monthly_expenses(monthly_expenses) do
    if Decimal.negative?(monthly_expenses) do
      {:error, :negative_expenses}
    else
      :ok
    end
  end

  defp validate_months(months) when is_integer(months) and months > 0 and months <= 12 do
    :ok
  end

  defp validate_months(_months) do
    {:error, :invalid_months}
  end

  defp validate_period_months(period_months)
       when is_integer(period_months) and period_months > 0 do
    :ok
  end

  defp validate_period_months(_period_months) do
    {:error, :invalid_period}
  end

  defp get_expenses_for_period(start_date, end_date) do
    require Ash.Query

    Expense
    |> Ash.Query.filter(date >= ^start_date and date <= ^end_date)
    |> Ash.read!()
  end

  defp calculate_total_expenses(expenses) do
    expenses
    |> Enum.map(& &1.amount)
    |> Enum.reduce(Decimal.new("0.00"), &Decimal.add/2)
  end

  defp calculate_amount_remaining(target_amount, current_amount) do
    remaining = Decimal.sub(target_amount, current_amount)

    if Decimal.negative?(remaining) do
      Decimal.new("0.00")
    else
      remaining
    end
  end

  defp calculate_progress_percentage(target_amount, current_amount) do
    if Decimal.equal?(target_amount, Decimal.new("0.00")) do
      Decimal.new("100.00")
    else
      # Calculate percentage with 2 decimal places
      percentage =
        current_amount
        |> Decimal.div(target_amount)
        |> Decimal.mult(Decimal.new("100"))
        |> Decimal.round(2)

      # Cap at 100%
      if Decimal.gt?(percentage, Decimal.new("100.00")) do
        Decimal.new("100.00")
      else
        percentage
      end
    end
  end

  defp calculate_timeline(amount_remaining, monthly_contribution) do
    cond do
      Decimal.equal?(amount_remaining, Decimal.new("0.00")) ->
        # Goal already achieved
        {0, true}

      Decimal.equal?(monthly_contribution, Decimal.new("0.00")) ->
        # No contribution, timeline unknown
        {nil, false}

      true ->
        # Calculate months needed
        months =
          amount_remaining
          |> Decimal.div(monthly_contribution)
          |> Decimal.round(0, :up)
          |> Decimal.to_integer()

        {months, false}
    end
  end

  defp calculate_suggested_contribution(target_amount) do
    # Suggest contribution to reach goal in 24 months
    suggested_months = 24

    target_amount
    |> Decimal.div(Decimal.new(to_string(suggested_months)))
    |> Decimal.round(2)
  end
end
