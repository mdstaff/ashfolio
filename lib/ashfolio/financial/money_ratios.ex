defmodule Ashfolio.Financial.MoneyRatios do
  @moduledoc """
  Implements Charles Farrell's "Your Money Ratios" methodology for financial health assessment.

  Calculates 8 key financial ratios tied to gross annual household income:
  1. Capital-to-Income Ratio - Retirement savings vs income
  2. Savings Ratio - Annual savings rate
  3. Mortgage-to-Income Ratio - Mortgage debt vs income
  4. Education-to-Income Ratio - Student loan debt vs income
  5-8. Insurance assessments (simplified advisory)
  """

  @doc """
  Calculate the capital-to-income ratio.
  Compares total invested capital (excluding primary residence) to annual income.
  """
  def calculate_capital_ratio(profile, net_worth, opts \\ []) do
    exclude_residence = Keyword.get(opts, :exclude_residence, true)

    income = profile.gross_annual_income

    # Check for zero income
    if Decimal.equal?(income, Decimal.new("0")) do
      {:error, :zero_income}
    else
      # Calculate capital (net worth minus residence if requested)
      capital =
        if exclude_residence and Map.has_key?(profile, :primary_residence_value) and profile.primary_residence_value do
          Decimal.sub(net_worth, profile.primary_residence_value)
        else
          net_worth
        end

      current_ratio = Decimal.div(capital, income)
      target_ratio = get_capital_target_for_age(calculate_age(profile))

      status = determine_status(current_ratio, target_ratio)

      {:ok,
       %{
         current_ratio: current_ratio,
         target_ratio: target_ratio,
         status: status
       }}
    end
  end

  @doc """
  Calculate the savings ratio.
  Compares annual savings to gross annual income.
  """
  def calculate_savings_ratio(profile, annual_savings) do
    income = profile.gross_annual_income

    if Decimal.equal?(income, Decimal.new("0")) do
      {:error, :zero_income}
    else
      current_ratio = Decimal.div(annual_savings, income)
      # 12% target
      target_ratio = Decimal.new("0.12")

      status =
        if Decimal.compare(current_ratio, target_ratio) == :lt do
          :behind
        else
          :on_track
        end

      {:ok,
       %{
         current_ratio: current_ratio,
         target_ratio: target_ratio,
         status: status
       }}
    end
  end

  @doc """
  Calculate the mortgage-to-income ratio.
  Compares mortgage balance to gross annual income.
  """
  def calculate_mortgage_ratio(profile) do
    income = profile.gross_annual_income
    mortgage = Map.get(profile, :mortgage_balance) || Decimal.new("0")

    if Decimal.equal?(income, Decimal.new("0")) do
      {:error, :zero_income}
    else
      current_ratio =
        if mortgage && !Decimal.equal?(mortgage, Decimal.new("0")) do
          Decimal.div(mortgage, income)
        else
          Decimal.new("0")
        end

      target_ratio = get_mortgage_target_for_age(calculate_age(profile))

      status = determine_status(current_ratio, target_ratio, :lower_is_better)

      {:ok,
       %{
         current_ratio: current_ratio,
         target_ratio: target_ratio,
         status: status
       }}
    end
  end

  @doc """
  Calculate the education debt ratio.
  Compares student loan balance to gross annual income.
  """
  def calculate_education_ratio(profile) do
    income = profile.gross_annual_income
    student_loans = Map.get(profile, :student_loan_balance) || Decimal.new("0")

    if Decimal.equal?(income, Decimal.new("0")) do
      {:error, :zero_income}
    else
      current_ratio =
        if student_loans && !Decimal.equal?(student_loans, Decimal.new("0")) do
          Decimal.div(student_loans, income)
        else
          Decimal.new("0")
        end

      # Should not exceed annual income
      target_ratio = Decimal.new("1.0")

      status =
        if Decimal.compare(current_ratio, target_ratio) == :gt do
          :behind
        else
          :on_track
        end

      {:ok,
       %{
         current_ratio: current_ratio,
         target_ratio: target_ratio,
         status: status
       }}
    end
  end

  @doc """
  Calculate all ratios for a comprehensive assessment.
  """
  def calculate_all_ratios(profile, net_worth, annual_savings) do
    with {:ok, capital} <- calculate_capital_ratio(profile, net_worth),
         {:ok, savings} <- calculate_savings_ratio(profile, annual_savings),
         {:ok, mortgage} <- calculate_mortgage_ratio(profile),
         {:ok, education} <- calculate_education_ratio(profile) do
      overall_status =
        determine_overall_status([
          capital.status,
          savings.status,
          mortgage.status,
          education.status
        ])

      {:ok,
       %{
         capital_ratio: capital,
         savings_ratio: savings,
         mortgage_ratio: mortgage,
         education_ratio: education,
         overall_status: overall_status
       }}
    end
  end

  @doc """
  Get recommendations based on ratio analysis.
  """
  def get_recommendations(ratios) do
    recommendations = []

    # Check capital ratio
    recommendations =
      if Map.get(ratios, :capital_ratio) && ratios.capital_ratio.status == :behind do
        ["Increase retirement savings to reach capital-to-income target" | recommendations]
      else
        recommendations
      end

    # Check savings ratio
    recommendations =
      if Map.get(ratios, :savings_ratio) && ratios.savings_ratio.status == :behind do
        ["Boost annual savings rate to meet 12% target" | recommendations]
      else
        recommendations
      end

    # Check mortgage ratio
    recommendations =
      if Map.get(ratios, :mortgage_ratio) && ratios.mortgage_ratio.status == :behind do
        ["Consider accelerating mortgage payments" | recommendations]
      else
        recommendations
      end

    # Check education ratio
    recommendations =
      if Map.get(ratios, :education_ratio) && ratios.education_ratio.status == :behind do
        ["Focus on paying down student loans" | recommendations]
      else
        recommendations
      end

    # If all on track
    if Enum.empty?(recommendations) do
      ["Excellent work! All ratios are on track. Continue your current financial strategy."]
    else
      recommendations
    end
  end

  # Private helper functions

  defp calculate_age(profile) do
    if Map.has_key?(profile, :birth_year) && profile.birth_year do
      Date.utc_today().year - profile.birth_year
    else
      # Default age if not provided
      40
    end
  end

  defp get_capital_target_for_age(age) do
    cond do
      age < 30 -> Decimal.new("1.0")
      age < 35 -> Decimal.new("2.0")
      # Changed to <= to include age 40
      age <= 40 -> Decimal.new("3.0")
      age < 45 -> Decimal.new("4.0")
      age < 50 -> Decimal.new("6.0")
      age < 55 -> Decimal.new("8.0")
      age < 60 -> Decimal.new("10.0")
      age < 65 -> Decimal.new("12.0")
      true -> Decimal.new("12.0")
    end
  end

  defp get_mortgage_target_for_age(age) do
    cond do
      age < 30 -> Decimal.new("2.0")
      # Changed to <= to include age 40
      age <= 40 -> Decimal.new("1.5")
      age < 50 -> Decimal.new("1.0")
      age < 60 -> Decimal.new("0.5")
      true -> Decimal.new("0")
    end
  end

  defp determine_status(current, target, mode \\ :higher_is_better) do
    comparison = Decimal.compare(current, target)

    case mode do
      :higher_is_better ->
        case comparison do
          :gt -> :ahead
          :eq -> :on_track
          :lt -> :behind
        end

      :lower_is_better ->
        case comparison do
          :lt -> :on_track
          :eq -> :on_track
          :gt -> :behind
        end
    end
  end

  defp determine_overall_status(statuses) do
    behind_count = Enum.count(statuses, &(&1 == :behind))

    cond do
      behind_count == 0 -> :excellent
      behind_count == 1 -> :on_track
      behind_count == 2 -> :needs_attention
      true -> :critical
    end
  end
end
