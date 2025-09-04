defmodule Ashfolio.FinancialManagement.RetirementCalculator do
  @moduledoc """
  Retirement planning calculations following industry-standard methodologies.

  Implements the 25x expenses rule (4% safe withdrawal rate) and provides
  comprehensive retirement readiness analysis for financial planning.

  This module follows patterns established in `lib/ashfolio/portfolio/calculator.ex`
  for error handling, logging, and Decimal arithmetic precision.
  """

  alias Ashfolio.FinancialManagement.AERCalculator
  alias Ashfolio.FinancialManagement.Expense

  require Logger

  @doc """
  Calculates retirement target using the 25x annual expenses rule.

  Based on the 4% safe withdrawal rate assumption, this calculation
  determines how much portfolio value is needed to safely withdraw
  4% annually to cover living expenses.

  ## Examples

      iex> RetirementCalculator.calculate_retirement_target(Decimal.new("50000"))
      {:ok, Decimal.new("1250000")}

      iex> RetirementCalculator.calculate_retirement_target(Decimal.new("0"))
      {:ok, Decimal.new("0")}

  ## Parameters

    - annual_expenses: Decimal - Expected annual expenses in retirement

  ## Returns

    - {:ok, target} - Decimal target portfolio value needed for retirement
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_retirement_target(annual_expenses) do
    Logger.debug("Calculating 25x retirement target for annual expenses: #{annual_expenses}")

    with :ok <- validate_input(annual_expenses),
         :ok <- validate_non_negative(annual_expenses) do
      # 25x rule: multiply annual expenses by 25 (based on 4% safe withdrawal rate)
      target = Decimal.mult(annual_expenses, Decimal.new("25"))

      Logger.debug("25x retirement target calculated: #{target}")
      {:ok, target}
    else
      {:error, reason} ->
        Logger.warning("25x calculation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculates annual expenses from the last 12 months of expense history.

  Uses existing expense aggregation patterns to determine typical annual spending
  for retirement planning calculations. Handles incomplete data by extrapolating
  from available months.

  ## Examples

      iex> RetirementCalculator.annual_expenses_from_history()
      {:ok, Decimal.new("48000.00")}

  ## Returns

    - {:ok, annual_expenses} - Decimal total annual expenses from history
    - {:error, reason} - Error tuple with descriptive reason
  """
  def annual_expenses_from_history do
    Logger.debug("Calculating annual expenses from expense history")

    try do
      require Ash.Query
      # Get last 12 months of expenses
      end_date = Date.utc_today()
      start_date = Date.add(end_date, -365)

      # Use expense aggregation pattern similar to category_totals!
      expenses =
        Expense
        |> Ash.Query.filter(date >= ^start_date and date <= ^end_date)
        |> Ash.read!()

      total_expenses =
        expenses
        |> Enum.map(& &1.amount)
        |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)

      # For retirement planning, we want the actual total over the period queried
      # If we have less than a full year, we can extrapolate, but let's be more conservative
      days_in_period = Date.diff(end_date, start_date) + 1

      annual_estimate =
        if days_in_period >= 365 do
          # We have a full year or more
          total_expenses
        else
          # Extrapolate based on days: (total / days) * 365
          daily_average = Decimal.div(total_expenses, Decimal.new(to_string(days_in_period)))
          Decimal.mult(daily_average, Decimal.new("365"))
        end

      Logger.debug("Annual expenses calculated from history: #{annual_estimate}")
      {:ok, annual_estimate}
    rescue
      error ->
        Logger.warning("Failed to calculate annual expenses: #{inspect(error)}")
        {:error, :calculation_failed}
    end
  end

  @doc """
  Calculates retirement target directly from expense history using 25x rule.

  Convenience function that combines `annual_expenses_from_history/0` with
  `calculate_retirement_target/1` to provide one-step retirement planning.

  ## Examples

      iex> RetirementCalculator.calculate_retirement_target_from_history()
      {:ok, Decimal.new("1200000.00")}

  ## Returns

    - {:ok, retirement_target} - Decimal retirement target from expense history
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_retirement_target_from_history do
    Logger.debug("Calculating retirement target from expense history")

    with {:ok, annual_expenses} <- annual_expenses_from_history(),
         {:ok, retirement_target} <- calculate_retirement_target(annual_expenses) do
      Logger.debug("Retirement target from history: #{retirement_target}")
      {:ok, retirement_target}
    else
      {:error, reason} ->
        Logger.warning("Failed to calculate retirement target from history: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculates retirement progress tracking metrics.

  Given annual expenses and current portfolio value, calculates progress toward
  the 25x retirement target including percentage complete and amount remaining.

  ## Examples

      iex> RetirementCalculator.calculate_retirement_progress(Decimal.new("50000"), Decimal.new("625000"))
      {:ok, %{target_amount: Decimal.new("1250000"), progress_percentage: Decimal.new("50.00"), ...}}

  ## Parameters

    - annual_expenses: Decimal - Expected annual expenses for 25x calculation
    - current_portfolio_value: Decimal - Current total portfolio value

  ## Returns

    - {:ok, progress_map} - Progress tracking data structure
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_retirement_progress(annual_expenses, current_portfolio_value) do
    Logger.debug("Calculating retirement progress - expenses: #{annual_expenses}, portfolio: #{current_portfolio_value}")

    with :ok <- validate_input(annual_expenses),
         :ok <- validate_non_negative(annual_expenses),
         :ok <- validate_portfolio_value(current_portfolio_value),
         {:ok, target_amount} <- calculate_retirement_target(annual_expenses) do
      # Calculate progress metrics
      progress_percentage = calculate_progress_percentage(current_portfolio_value, target_amount)
      amount_remaining = calculate_amount_remaining(current_portfolio_value, target_amount)

      progress = %{
        target_amount: target_amount,
        current_amount: current_portfolio_value,
        progress_percentage: progress_percentage,
        amount_remaining: amount_remaining,
        is_complete: Decimal.compare(current_portfolio_value, target_amount) != :lt
      }

      Logger.debug("Retirement progress calculated: #{progress_percentage}%")
      {:ok, progress}
    else
      {:error, reason} ->
        Logger.warning("Failed to calculate retirement progress: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Estimates time to retirement goal based on monthly savings rate.

  Calculates how long it will take to reach the 25x retirement target
  given current portfolio value and monthly savings contributions.

  ## Examples

      iex> RetirementCalculator.estimate_time_to_goal(Decimal.new("50000"), Decimal.new("500000"), Decimal.new("4000"))
      {:ok, %{months_to_goal: 188, years_to_goal: 15, feasible: true}}

  ## Parameters

    - annual_expenses: Decimal - Expected annual expenses
    - current_portfolio_value: Decimal - Current portfolio value
    - monthly_savings: Decimal - Monthly savings/contribution amount

  ## Returns

    - {:ok, time_estimate_map} - Time estimation data structure
    - {:error, reason} - Error tuple with descriptive reason
  """
  def estimate_time_to_goal(annual_expenses, current_portfolio_value, monthly_savings) do
    Logger.debug("Estimating time to goal - savings: #{monthly_savings}/month")

    case calculate_retirement_progress(annual_expenses, current_portfolio_value) do
      {:ok, progress} ->
        time_estimate =
          if progress.is_complete do
            # Goal already achieved
            %{
              months_to_goal: 0,
              years_to_goal: 0,
              monthly_savings_needed: monthly_savings,
              amount_remaining: Decimal.new("0"),
              feasible: true
            }
          else
            calculate_time_estimate(progress.amount_remaining, monthly_savings)
          end

        Logger.debug("Time to goal estimated: #{inspect(time_estimate)}")
        {:ok, time_estimate}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Calculates required monthly savings to reach retirement goal in target years.

  ## Examples

      iex> RetirementCalculator.calculate_required_monthly_savings(Decimal.new("50000"), Decimal.new("250000"), 10)
      {:ok, Decimal.new("8333.33")}

  ## Parameters

    - annual_expenses: Decimal - Expected annual expenses
    - current_portfolio_value: Decimal - Current portfolio value
    - target_years: integer - Desired years to retirement

  ## Returns

    - {:ok, monthly_savings_needed} - Required monthly savings amount
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_required_monthly_savings(annual_expenses, current_portfolio_value, target_years) do
    Logger.debug("Calculating required monthly savings for #{target_years} years")

    case calculate_retirement_progress(annual_expenses, current_portfolio_value) do
      {:ok, progress} ->
        if progress.is_complete do
          # Goal already achieved
          {:ok, Decimal.new("0")}
        else
          target_months = target_years * 12

          monthly_needed =
            Decimal.div(progress.amount_remaining, Decimal.new(to_string(target_months)))

          rounded = Decimal.round(monthly_needed, 2)

          Logger.debug("Required monthly savings: #{rounded}")
          {:ok, rounded}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Calculates retirement progress using expense history and portfolio value.

  Convenience function combining expense history calculation with progress tracking.

  ## Examples

      iex> RetirementCalculator.calculate_retirement_progress_from_history(Decimal.new("600000"))
      {:ok, %{target_amount: ..., progress_percentage: ..., ...}}

  ## Returns

    - {:ok, progress_map} - Complete progress analysis from historical data
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_retirement_progress_from_history(current_portfolio_value) do
    Logger.debug("Calculating retirement progress from expense history")

    with {:ok, annual_expenses} <- annual_expenses_from_history(),
         {:ok, progress} <-
           calculate_retirement_progress(annual_expenses, current_portfolio_value) do
      Logger.debug("Retirement progress from history calculated")
      {:ok, progress}
    end
  end

  @doc """
  Calculates retirement progress with manual expense override.

  Allows user to override historical expense data with custom retirement expenses.

  ## Examples

      iex> RetirementCalculator.calculate_retirement_progress_with_override(Decimal.new("40000"), Decimal.new("500000"))
      {:ok, %{target_amount: Decimal.new("1000000"), progress_percentage: Decimal.new("50.00"), ...}}

  ## Returns

    - {:ok, progress_map} - Progress analysis with manual override
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_retirement_progress_with_override(manual_annual_expenses, current_portfolio_value) do
    Logger.debug("Calculating retirement progress with manual override: #{manual_annual_expenses}")

    calculate_retirement_progress(manual_annual_expenses, current_portfolio_value)
  end

  # Private validation functions following calculator.ex patterns

  defp validate_input(%Decimal{} = _annual_expenses), do: :ok
  defp validate_input(_), do: {:error, :invalid_input}

  defp validate_non_negative(annual_expenses) do
    case Decimal.compare(annual_expenses, Decimal.new("0")) do
      :lt -> {:error, :negative_expenses}
      _ -> :ok
    end
  end

  defp validate_portfolio_value(%Decimal{} = portfolio_value) do
    case Decimal.compare(portfolio_value, Decimal.new("0")) do
      :lt -> {:error, :negative_portfolio_value}
      _ -> :ok
    end
  end

  defp validate_portfolio_value(_), do: {:error, :invalid_portfolio_value}

  # Private helper functions for progress calculations

  defp calculate_progress_percentage(current_amount, target_amount) do
    if Decimal.equal?(target_amount, Decimal.new("0")) do
      Decimal.new("0.00")
    else
      current_amount
      |> Decimal.div(target_amount)
      |> Decimal.mult(Decimal.new("100"))
      |> Decimal.round(2)
    end
  end

  defp calculate_amount_remaining(current_amount, target_amount) do
    difference = Decimal.sub(target_amount, current_amount)
    # Return 0 if already exceeded target (negative remaining)
    if Decimal.compare(difference, Decimal.new("0")) == :lt do
      Decimal.new("0")
    else
      difference
    end
  end

  defp calculate_time_estimate(amount_remaining, monthly_savings) do
    if Decimal.equal?(monthly_savings, Decimal.new("0")) do
      # Cannot reach goal with zero savings
      %{
        months_to_goal: nil,
        years_to_goal: nil,
        monthly_savings_needed: monthly_savings,
        amount_remaining: amount_remaining,
        feasible: false
      }
    else
      months =
        amount_remaining
        |> Decimal.div(monthly_savings)
        |> Decimal.to_integer()

      years = div(months, 12)

      %{
        months_to_goal: months,
        years_to_goal: years,
        monthly_savings_needed: monthly_savings,
        amount_remaining: amount_remaining,
        feasible: true
      }
    end
  end

  @doc """
  Calculates safe withdrawal amount using the 4% rule.

  Based on the Trinity Study and historical market data, 4% is considered
  a safe withdrawal rate that preserves portfolio value over 30+ years.

  ## Examples

      iex> RetirementCalculator.calculate_safe_withdrawal_amount(Decimal.new(\"1000000\"))
      {:ok, Decimal.new(\"40000.00\")}

  ## Parameters

    - portfolio_value: Decimal - Current total portfolio value

  ## Returns

    - {:ok, annual_withdrawal} - Safe annual withdrawal amount (4%)
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_safe_withdrawal_amount(portfolio_value) do
    Logger.debug("Calculating 4% safe withdrawal for portfolio: #{portfolio_value}")

    case validate_portfolio_value(portfolio_value) do
      :ok ->
        # 4% rule: multiply portfolio value by 0.04
        withdrawal_amount =
          portfolio_value
          |> Decimal.mult(Decimal.new("0.04"))
          |> Decimal.round(2)

        Logger.debug("4% safe withdrawal calculated: #{withdrawal_amount}")
        {:ok, withdrawal_amount}

      {:error, reason} ->
        Logger.warning("4% withdrawal calculation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Analyzes withdrawal sustainability and risk assessment.

  Evaluates whether a given withdrawal amount is sustainable long-term
  and provides risk categorization based on historical analysis.

  ## Examples

      iex> RetirementCalculator.calculate_withdrawal_sustainability(Decimal.new(\"1000000\"), Decimal.new(\"35000\"))
      {:ok, %{withdrawal_rate: Decimal.new(\"3.50\"), is_sustainable: true, risk_level: :low, ...}}

  ## Parameters

    - portfolio_value: Decimal - Current portfolio value
    - annual_withdrawal: Decimal - Desired annual withdrawal amount

  ## Returns

    - {:ok, sustainability_analysis} - Analysis with withdrawal rate and risk assessment
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_withdrawal_sustainability(portfolio_value, annual_withdrawal) do
    Logger.debug("Analyzing withdrawal sustainability - portfolio: #{portfolio_value}, withdrawal: #{annual_withdrawal}")

    with :ok <- validate_portfolio_value(portfolio_value),
         :ok <- validate_input(annual_withdrawal),
         :ok <- validate_non_negative(annual_withdrawal) do
      # Calculate withdrawal rate as percentage
      withdrawal_rate =
        if Decimal.equal?(portfolio_value, Decimal.new("0")) do
          Decimal.new("0.00")
        else
          annual_withdrawal
          |> Decimal.div(portfolio_value)
          |> Decimal.mult(Decimal.new("100"))
          |> Decimal.round(2)
        end

      # Determine sustainability and risk based on historical data
      {is_sustainable, risk_level, years_sustainable} = analyze_withdrawal_risk(withdrawal_rate)

      analysis = %{
        withdrawal_rate: withdrawal_rate,
        is_sustainable: is_sustainable,
        risk_level: risk_level,
        years_sustainable: years_sustainable
      }

      Logger.debug("Withdrawal sustainability analyzed: #{withdrawal_rate}% - #{risk_level}")
      {:ok, analysis}
    else
      {:error, reason} ->
        Logger.warning("Withdrawal sustainability analysis failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculates monthly withdrawal budget from portfolio value.

  Converts the 4% safe withdrawal rate into a monthly budget amount
  for practical spending planning.

  ## Examples

      iex> RetirementCalculator.calculate_monthly_withdrawal_budget(Decimal.new(\"1200000\"))
      {:ok, Decimal.new(\"4000.00\")}

  ## Parameters

    - portfolio_value: Decimal - Current portfolio value

  ## Returns

    - {:ok, monthly_budget} - Monthly withdrawal budget
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_monthly_withdrawal_budget(portfolio_value) do
    Logger.debug("Calculating monthly withdrawal budget for portfolio: #{portfolio_value}")

    case calculate_safe_withdrawal_amount(portfolio_value) do
      {:ok, annual_withdrawal} ->
        monthly_budget =
          annual_withdrawal
          |> Decimal.div(Decimal.new("12"))
          |> Decimal.round(2)

        Logger.debug("Monthly withdrawal budget calculated: #{monthly_budget}")
        {:ok, monthly_budget}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Calculates current annual dividend income from portfolio holdings.

  Takes a list of holdings with dividend yield information and calculates
  total expected annual dividend income for retirement planning.

  ## Examples

      iex> holdings = [%{symbol: "AAPL", shares: Decimal.new("100"), dividend_yield: Decimal.new("0.005"), price: Decimal.new("150")}]
      iex> RetirementCalculator.calculate_current_dividend_income(holdings)
      {:ok, Decimal.new("75.00")}

  ## Parameters

    - holdings: List of holding maps with :shares, :dividend_yield, :price

  ## Returns

    - {:ok, annual_dividend} - Total annual dividend income
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_current_dividend_income(holdings) when is_list(holdings) do
    Logger.debug("Calculating dividend income for #{length(holdings)} holdings")

    # Validate all holdings first
    case validate_all_holdings(holdings) do
      :ok ->
        try do
          total_dividend =
            holdings
            |> Enum.reduce(Decimal.new("0"), fn holding, acc ->
              # Annual dividend = shares * price * dividend_yield
              position_value = Decimal.mult(holding.shares, holding.price)
              dividend_income = Decimal.mult(position_value, holding.dividend_yield)
              Decimal.add(acc, dividend_income)
            end)
            |> Decimal.round(2)

          Logger.debug("Total annual dividend income calculated: #{total_dividend}")
          {:ok, total_dividend}
        rescue
          error ->
            Logger.warning("Failed to calculate dividend income: #{inspect(error)}")
            {:error, :calculation_failed}
        end

      {:error, reason} ->
        Logger.warning("Invalid holdings data: #{inspect(reason)}")
        {:error, :invalid_holding_data}
    end
  end

  def calculate_current_dividend_income(_), do: {:error, :invalid_holding_data}

  @doc """
  Projects dividend income growth over a specified time period.

  Uses compound growth calculation to project future dividend income
  based on historical dividend growth rates.

  ## Examples

      iex> RetirementCalculator.project_dividend_growth(Decimal.new("1000"), Decimal.new("0.03"), 10)
      {:ok, Decimal.new("1343.92")}

  ## Parameters

    - current_dividend: Decimal - Current annual dividend income
    - growth_rate: Decimal - Annual dividend growth rate (e.g., 0.03 for 3%)
    - years: integer - Number of years to project

  ## Returns

    - {:ok, projected_dividend} - Future dividend income after growth
    - {:error, reason} - Error tuple with descriptive reason
  """
  def project_dividend_growth(current_dividend, growth_rate, years) do
    Logger.debug("Projecting dividend growth: #{current_dividend} at #{growth_rate}% for #{years} years")

    case validate_dividend_projection_inputs(current_dividend, growth_rate, years) do
      :ok ->
        # Handle zero growth rate case
        projected_dividend =
          if Decimal.equal?(growth_rate, Decimal.new("0")) do
            current_dividend
          else
            # Use AER standardized compound growth calculation
            current_dividend
            |> AERCalculator.compound_with_aer(growth_rate, years)
            |> Decimal.round(2)
          end

        Logger.debug("Projected dividend income: #{projected_dividend}")
        {:ok, projected_dividend}

      {:error, reason} ->
        Logger.warning("Dividend projection failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculates monthly dividend income from annual amount.

  Converts annual dividend income to monthly for budget planning
  and expense coverage analysis.

  ## Examples

      iex> RetirementCalculator.calculate_monthly_dividend_income(Decimal.new("1200"))
      {:ok, Decimal.new("100.00")}

  ## Parameters

    - annual_dividend: Decimal - Annual dividend income

  ## Returns

    - {:ok, monthly_dividend} - Monthly dividend income
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_monthly_dividend_income(annual_dividend) do
    Logger.debug("Converting annual dividend to monthly: #{annual_dividend}")

    with :ok <- validate_input(annual_dividend),
         :ok <- validate_non_negative(annual_dividend) do
      monthly_dividend =
        annual_dividend
        |> Decimal.div(Decimal.new("12"))
        |> Decimal.round(2)

      Logger.debug("Monthly dividend income: #{monthly_dividend}")
      {:ok, monthly_dividend}
    else
      {:error, reason} ->
        Logger.warning("Monthly dividend calculation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Analyzes how well dividend income covers retirement expenses.

  Provides comprehensive analysis of dividend coverage including
  percentages, shortfalls, and sustainability assessment.

  ## Examples

      iex> RetirementCalculator.analyze_dividend_coverage(Decimal.new("18000"), Decimal.new("24000"))
      {:ok, %{coverage_percentage: Decimal.new("75.00"), is_fully_covered: false, ...}}

  ## Parameters

    - annual_dividend: Decimal - Annual dividend income
    - annual_expenses: Decimal - Annual retirement expenses

  ## Returns

    - {:ok, coverage_analysis} - Analysis with coverage metrics
    - {:error, reason} - Error tuple with descriptive reason
  """
  def analyze_dividend_coverage(annual_dividend, annual_expenses) do
    Logger.debug("Analyzing dividend coverage - dividend: #{annual_dividend}, expenses: #{annual_expenses}")

    with :ok <- validate_input(annual_dividend),
         :ok <- validate_non_negative(annual_dividend),
         :ok <- validate_input(annual_expenses),
         :ok <- validate_non_negative(annual_expenses) do
      # Calculate coverage percentage
      coverage_percentage =
        if Decimal.equal?(annual_expenses, Decimal.new("0")) do
          # No expenses means full coverage
          Decimal.new("100.00")
        else
          annual_dividend
          |> Decimal.div(annual_expenses)
          |> Decimal.mult(Decimal.new("100"))
          |> Decimal.round(2)
        end

      # Calculate monthly amounts
      monthly_dividend = annual_dividend |> Decimal.div(Decimal.new("12")) |> Decimal.round(2)
      monthly_expenses = annual_expenses |> Decimal.div(Decimal.new("12")) |> Decimal.round(2)

      # Calculate shortfall (0 if dividend exceeds expenses)
      monthly_shortfall =
        monthly_expenses
        |> Decimal.sub(monthly_dividend)
        |> Decimal.max(Decimal.new("0"))
        |> Decimal.round(2)

      # Determine if fully covered
      is_fully_covered = Decimal.compare(annual_dividend, annual_expenses) != :lt

      analysis = %{
        coverage_percentage: coverage_percentage,
        monthly_dividend: monthly_dividend,
        monthly_expenses: monthly_expenses,
        monthly_shortfall: monthly_shortfall,
        is_fully_covered: is_fully_covered
      }

      Logger.debug("Dividend coverage analysis: #{coverage_percentage}% coverage")
      {:ok, analysis}
    else
      {:error, reason} ->
        Logger.warning("Dividend coverage analysis failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private validation and helper functions for dividend calculations

  defp validate_holding_data(%{shares: shares, dividend_yield: yield, price: price})
       when is_struct(shares, Decimal) and is_struct(yield, Decimal) and is_struct(price, Decimal) do
    :ok
  end

  defp validate_holding_data(_), do: {:error, :invalid_holding_structure}

  defp validate_all_holdings([]), do: :ok

  defp validate_all_holdings(holdings) do
    case Enum.find(holdings, fn holding -> validate_holding_data(holding) != :ok end) do
      nil -> :ok
      _invalid_holding -> {:error, :invalid_holding_structure}
    end
  end

  defp validate_dividend_projection_inputs(current_dividend, growth_rate, years) do
    with :ok <- validate_input(current_dividend),
         :ok <- validate_non_negative_dividend(current_dividend),
         :ok <- validate_input(growth_rate),
         :ok <- validate_years(years) do
      validate_growth_rate(growth_rate)
    end
  end

  defp validate_non_negative_dividend(dividend) do
    case Decimal.compare(dividend, Decimal.new("0")) do
      :lt -> {:error, :negative_dividend}
      _ -> :ok
    end
  end

  defp validate_years(years) when is_integer(years) and years >= 0, do: :ok
  defp validate_years(_), do: {:error, :invalid_years}

  defp validate_growth_rate(growth_rate) do
    case Decimal.compare(growth_rate, Decimal.new("0.5")) do
      # > 50% is unrealistic
      :gt ->
        {:error, :unrealistic_growth}

      _ ->
        case Decimal.compare(growth_rate, Decimal.new("-0.2")) do
          # < -20% is also unrealistic
          :lt -> {:error, :unrealistic_growth}
          _ -> :ok
        end
    end
  end

  # Private helper function for withdrawal risk analysis
  defp analyze_withdrawal_risk(withdrawal_rate) do
    cond do
      Decimal.compare(withdrawal_rate, Decimal.new("4.0")) != :gt ->
        # <= 4%: Low risk, sustainable indefinitely
        {true, :low, :indefinite}

      Decimal.compare(withdrawal_rate, Decimal.new("5.0")) != :gt ->
        # 4.1% - 5%: Moderate risk, may last 20-30 years
        rate_diff = withdrawal_rate |> Decimal.sub(Decimal.new("4")) |> Decimal.round(0)
        years = 25 - Decimal.to_integer(rate_diff) * 3
        {false, :moderate, max(years, 15)}

      true ->
        # > 5%: High risk, likely to deplete portfolio
        years =
          case Decimal.compare(withdrawal_rate, Decimal.new("8.0")) do
            # Very high withdrawal rate
            :gt ->
              8

            _ ->
              rate_diff = withdrawal_rate |> Decimal.sub(Decimal.new("5")) |> Decimal.round(0)
              20 - Decimal.to_integer(rate_diff) * 2
          end

        {false, :high, max(years, 5)}
    end
  end
end
