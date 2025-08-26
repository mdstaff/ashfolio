defmodule Ashfolio.FinancialManagement.EmergencyFundCalculator do
  @moduledoc """
  Emergency fund calculations for financial planning.

  Provides calculations for emergency fund targets based on monthly expenses,
  progress tracking, and timeline projections. Integrates with existing
  expense data to automatically calculate monthly spending averages.

  Key calculations:
  - Target emergency fund (3-12 months of expenses)
  - Current progress percentage
  - Monthly contribution needed to reach goal
  - Time to reach emergency fund target
  """

  alias Ashfolio.FinancialManagement.{Expense, FinancialGoal}
  require Logger

  @default_months_coverage 6
  @min_months_coverage 3
  @max_months_coverage 12

  @doc """
  Calculate average monthly expenses from the last N months of data.

  Returns the average monthly expense amount based on historical data.
  Defaults to last 12 months for accurate averaging.

  ## Examples

      iex> EmergencyFundCalculator.calculate_monthly_expenses()
      {:ok, Decimal.new("3500.00")}
  """
  def calculate_monthly_expenses(months_back \\ 12) do
    Logger.debug("Calculating average monthly expenses for last #{months_back} months")

    end_date = Date.utc_today()
    start_date = Date.add(end_date, -(months_back * 30))

    try do
      expenses = Expense.by_date_range!(start_date, end_date)

      case expenses do
        [] ->
          Logger.info("No expenses found for emergency fund calculation")
          {:ok, Decimal.new("0")}

        expenses ->
          # Group by month and calculate average
          monthly_totals =
            expenses
            |> Enum.group_by(fn expense ->
              {expense.date.year, expense.date.month}
            end)
            |> Enum.map(fn {_month, month_expenses} ->
              month_expenses
              |> Enum.map(& &1.amount)
              |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)
            end)

          months_with_data = length(monthly_totals)

          if months_with_data > 0 do
            total = Enum.reduce(monthly_totals, Decimal.new("0"), &Decimal.add/2)
            average = Decimal.div(total, Decimal.new(to_string(months_with_data)))

            Logger.debug(
              "Average monthly expenses: #{average} (#{months_with_data} months of data)"
            )

            {:ok, Decimal.round(average, 2)}
          else
            {:ok, Decimal.new("0")}
          end
      end
    rescue
      error ->
        Logger.error("Failed to calculate monthly expenses: #{inspect(error)}")
        {:error, "Failed to calculate monthly expenses"}
    end
  end

  @doc """
  Calculate emergency fund target based on monthly expenses.

  ## Parameters
  - monthly_expenses: Average monthly expense amount
  - months: Number of months to cover (default 6, range 3-12)

  ## Examples

      iex> EmergencyFundCalculator.calculate_target(Decimal.new("3500"), 6)
      {:ok, Decimal.new("21000.00")}
  """
  def calculate_target(monthly_expenses, months \\ @default_months_coverage) do
    cond do
      months < @min_months_coverage ->
        {:error, "Months coverage must be at least #{@min_months_coverage}"}

      months > @max_months_coverage ->
        {:error, "Months coverage cannot exceed #{@max_months_coverage}"}

      true ->
        target = Decimal.mult(monthly_expenses, Decimal.new(to_string(months)))
        {:ok, Decimal.round(target, 2)}
    end
  end

  @doc """
  Calculate or update emergency fund goal based on current expenses.

  Creates a new emergency fund goal or updates existing one with
  calculated target based on average monthly expenses.

  ## Options
  - months_coverage: Number of months to cover (default 6)
  - months_history: Number of months to analyze for average (default 12)
  """
  def setup_emergency_fund_goal(opts \\ []) do
    months_coverage = Keyword.get(opts, :months_coverage, @default_months_coverage)
    months_history = Keyword.get(opts, :months_history, 12)

    with {:ok, monthly_expenses} <- calculate_monthly_expenses(months_history),
         {:ok, target_amount} <- calculate_target(monthly_expenses, months_coverage) do
      # Check for existing emergency fund goal
      existing_goals = FinancialGoal.by_type!(:emergency_fund)

      case existing_goals do
        [] ->
          # Create new emergency fund goal
          Logger.info("Creating new emergency fund goal with target: #{target_amount}")

          FinancialGoal.create(%{
            name: "Emergency Fund (#{months_coverage} months)",
            target_amount: target_amount,
            goal_type: :emergency_fund,
            is_active: true
          })

        [goal | _] ->
          # Update existing goal
          Logger.info("Updating emergency fund goal target to: #{target_amount}")

          FinancialGoal.update(goal, %{
            target_amount: target_amount,
            name: "Emergency Fund (#{months_coverage} months)"
          })
      end
    end
  end

  @doc """
  Calculate monthly contribution needed to reach emergency fund goal by target date.

  ## Parameters
  - goal: Emergency fund goal with target_amount, current_amount, and target_date

  ## Examples

      iex> EmergencyFundCalculator.calculate_monthly_contribution_needed(goal)
      {:ok, Decimal.new("500.00")}
  """
  def calculate_monthly_contribution_needed(goal) do
    remaining = Decimal.sub(goal.target_amount, goal.current_amount)

    cond do
      Decimal.lte?(remaining, Decimal.new("0")) ->
        {:ok, Decimal.new("0")}

      is_nil(goal.target_date) ->
        {:error, "No target date set for goal"}

      true ->
        days_until = Date.diff(goal.target_date, Date.utc_today())

        if days_until <= 0 do
          {:error, "Target date has passed"}
        else
          months_until = max(1, div(days_until, 30))
          monthly_needed = Decimal.div(remaining, Decimal.new(to_string(months_until)))

          {:ok, Decimal.round(monthly_needed, 2)}
        end
    end
  end

  @doc """
  Analyze emergency fund readiness and provide recommendations.

  Returns a comprehensive analysis of emergency fund status including:
  - Current coverage in months
  - Progress percentage
  - Readiness status
  - Recommendations
  """
  def analyze_readiness do
    with {:ok, monthly_expenses} <- calculate_monthly_expenses() do
      goals = FinancialGoal.by_type!(:emergency_fund)

      case goals do
        [] ->
          {:ok,
           %{
             status: :no_goal,
             monthly_expenses: monthly_expenses,
             recommended_target: Decimal.mult(monthly_expenses, Decimal.new("6")),
             current_coverage_months: Decimal.new("0"),
             recommendation: "Create an emergency fund goal to get started"
           }}

        [goal | _] ->
          current_coverage =
            if Decimal.gt?(monthly_expenses, Decimal.new("0")) do
              Decimal.div(goal.current_amount, monthly_expenses)
            else
              Decimal.new("0")
            end

          progress_percentage =
            if Decimal.gt?(goal.target_amount, Decimal.new("0")) do
              Decimal.div(goal.current_amount, goal.target_amount)
              |> Decimal.mult(Decimal.new("100"))
            else
              Decimal.new("0")
            end

          {status, recommendation} =
            cond do
              Decimal.gte?(current_coverage, Decimal.new("6")) ->
                {:adequate, "Your emergency fund is fully funded!"}

              Decimal.gte?(current_coverage, Decimal.new("3")) ->
                {:partial, "Good progress! Continue building to 6 months coverage."}

              true ->
                {:insufficient, "Priority: Build emergency fund to at least 3 months expenses."}
            end

          {:ok,
           %{
             status: status,
             monthly_expenses: monthly_expenses,
             current_amount: goal.current_amount,
             target_amount: goal.target_amount,
             current_coverage_months: Decimal.round(current_coverage, 1),
             progress_percentage: Decimal.round(progress_percentage, 2),
             recommendation: recommendation,
             goal: goal
           }}
      end
    end
  end

  @doc """
  Project emergency fund growth based on monthly contributions.

  ## Parameters
  - goal: Current emergency fund goal
  - monthly_contribution: Planned monthly contribution amount
  - months_ahead: Number of months to project (default 12)

  Returns list of projections showing expected balance over time.
  """
  def project_growth(goal, monthly_contribution, months_ahead \\ 12) do
    current_amount = goal.current_amount

    projections =
      Enum.map(1..months_ahead, fn month ->
        projected_amount =
          Decimal.add(
            current_amount,
            Decimal.mult(monthly_contribution, Decimal.new(to_string(month)))
          )

        is_complete = Decimal.gte?(projected_amount, goal.target_amount)

        %{
          month: month,
          projected_amount: Decimal.min(projected_amount, goal.target_amount),
          progress_percentage:
            if Decimal.gt?(goal.target_amount, Decimal.new("0")) do
              Decimal.div(projected_amount, goal.target_amount)
              |> Decimal.mult(Decimal.new("100"))
              |> Decimal.min(Decimal.new("100"))
              |> Decimal.round(2)
            else
              Decimal.new("0")
            end,
          is_complete: is_complete
        }
      end)

    {:ok, projections}
  end
end
