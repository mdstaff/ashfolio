defmodule Ashfolio.Financial.MoneyRatios.Benchmarks do
  @moduledoc """
  Advanced benchmark calculations for Charles Farrell's "Your Money Ratios" methodology.

  Provides age-based financial targets, life stage analysis, and retirement readiness scoring
  with personalized recommendations for different life stages and financial scenarios.

  Features:
  - Dynamic benchmark calculations based on user age
  - Life stage identification with targeted advice
  - Retirement readiness scoring
  - Catch-up recommendations for behind-target scenarios
  - Accelerated timeline calculations for ahead-of-target scenarios
  """

  @doc """
  Calculate capital-to-income ratio target based on age.

  Based on Charles Farrell's refined age brackets with more granular targets.

  ## Examples
      
      iex> Benchmarks.capital_target_for_age(30)
      Decimal.new("1.0")
      
      iex> Benchmarks.capital_target_for_age(45)
      Decimal.new("5.0")
  """
  def capital_target_for_age(age) when is_integer(age) do
    cond do
      age < 30 -> Decimal.new("0.5")
      age < 35 -> Decimal.new("1.0")
      age < 40 -> Decimal.new("2.0")
      age < 45 -> Decimal.new("3.0")
      age < 50 -> Decimal.new("5.0")
      age < 55 -> Decimal.new("7.0")
      age < 60 -> Decimal.new("9.0")
      age < 65 -> Decimal.new("11.0")
      # Retirement ready
      true -> Decimal.new("12.0")
    end
  end

  @doc """
  Calculate mortgage-to-income ratio target based on age.

  Encourages debt reduction as retirement approaches.
  """
  def mortgage_target_for_age(age) when is_integer(age) do
    cond do
      age < 30 -> Decimal.new("2.5")
      age < 40 -> Decimal.new("2.0")
      age < 50 -> Decimal.new("1.5")
      age < 60 -> Decimal.new("1.0")
      age < 65 -> Decimal.new("0.5")
      # Debt-free in retirement
      true -> Decimal.new("0")
    end
  end

  @doc """
  Analyze life stage and provide contextual financial guidance.

  Returns a map with life stage, focus areas, and priority ratios.
  """
  def life_stage_analysis(age) when is_integer(age) do
    cond do
      age < 35 ->
        %{
          stage: :early_career,
          focus: "Building emergency fund and starting retirement savings",
          priority_ratios: [:savings_ratio, :capital_ratio]
        }

      age < 50 ->
        %{
          stage: :mid_career,
          focus: "Accelerating wealth accumulation and managing debt",
          priority_ratios: [:capital_ratio, :mortgage_ratio]
        }

      age < 65 ->
        %{
          stage: :pre_retirement,
          focus: "Maximizing retirement savings and reducing debt",
          priority_ratios: [:capital_ratio, :mortgage_ratio]
        }

      true ->
        %{
          stage: :retirement,
          focus: "Preserving wealth and managing withdrawals",
          priority_ratios: [:capital_ratio]
        }
    end
  end

  @doc """
  Calculate retirement readiness score based on age and current ratios.

  Returns a score from 0-100 with assessment and timeline information.
  """
  def retirement_readiness_score(profile, ratios) do
    current_age = calculate_age_from_profile(profile)
    years_to_retirement = max(65 - current_age, 0)

    capital_ratio = Map.get(ratios, :capital_ratio)

    if capital_ratio do
      current = capital_ratio.current_ratio
      target = capital_ratio.target_ratio

      # Calculate score based on current vs target performance
      ratio_performance =
        if Decimal.compare(target, Decimal.new("0")) == :gt do
          current
          |> Decimal.div(target)
          |> Decimal.mult(Decimal.new("100"))
          |> Decimal.to_float()
          |> min(100.0)
          |> max(0.0)
          |> round()
        else
          100
        end

      assessment =
        cond do
          ratio_performance >= 95 -> :on_track
          ratio_performance >= 70 -> :slightly_behind
          ratio_performance >= 30 -> :behind
          true -> :critical
        end

      %{
        score: ratio_performance,
        assessment: assessment,
        years_to_retirement: years_to_retirement
      }
    else
      %{
        score: 0,
        assessment: :insufficient_data,
        years_to_retirement: years_to_retirement
      }
    end
  end

  @doc """
  Generate catch-up recommendations for users behind their benchmarks.

  Provides specific, actionable advice based on which ratios are behind target.
  """
  def catch_up_recommendations(profile, ratios) do
    current_age = calculate_age_from_profile(profile)
    years_to_retirement = max(65 - current_age, 0)
    recommendations = []

    # Check capital ratio
    recommendations =
      if Map.get(ratios, :capital_ratio) && ratios.capital_ratio.status == :behind do
        current = ratios.capital_ratio.current_ratio
        target = ratios.capital_ratio.target_ratio
        gap = Decimal.sub(target, current)

        catch_up_advice =
          if years_to_retirement > 15 do
            "Increase retirement contributions by #{format_decimal(Decimal.mult(gap, Decimal.new("0.05")))}% of income annually to catch-up over #{years_to_retirement} years"
          else
            "Consider maximum catch-up contributions (age 50+ allows additional $7,500 to 401k) to bridge the #{format_decimal(gap)}x income gap"
          end

        [catch_up_advice | recommendations]
      else
        recommendations
      end

    # Check savings ratio
    recommendations =
      if Map.get(ratios, :savings_ratio) && ratios.savings_ratio.status == :behind do
        current_pct = Decimal.mult(ratios.savings_ratio.current_ratio, Decimal.new("100"))
        target_pct = Decimal.mult(ratios.savings_ratio.target_ratio, Decimal.new("100"))
        gap_pct = Decimal.sub(target_pct, current_pct)

        savings_advice =
          "Increase savings rate by #{format_decimal(gap_pct)}% to reach target of #{format_decimal(target_pct)}%"

        [savings_advice | recommendations]
      else
        recommendations
      end

    # Add general catch-up strategies if multiple ratios behind
    behind_count =
      Enum.count(Map.values(ratios), fn ratio ->
        Map.get(ratio, :status) == :behind
      end)

    if behind_count >= 2 do
      general_advice = [
        "Consider reducing expenses to increase savings available",
        "Look into side income opportunities to boost savings capacity",
        "Review investment allocation for appropriate risk level"
      ]

      recommendations ++ general_advice
    else
      recommendations
    end
  end

  @doc """
  Calculate accelerated timeline for users ahead of their benchmarks.

  Estimates potential for early retirement based on current performance.
  """
  def accelerated_timeline(profile, ratios) do
    current_age = calculate_age_from_profile(profile)
    capital_ratio = Map.get(ratios, :capital_ratio)

    if capital_ratio && capital_ratio.status == :ahead do
      current = capital_ratio.current_ratio
      target = capital_ratio.target_ratio

      # Calculate how far ahead (as a multiplier)
      ahead_factor = Decimal.div(current, target)

      # Estimate years ahead of schedule (simplified calculation)
      years_ahead =
        ahead_factor
        |> Decimal.sub(Decimal.new("1"))
        # Rough estimate: each 1x income = 5 years ahead
        |> Decimal.mult(Decimal.new("5"))
        |> Decimal.to_float()
        |> round()
        |> max(0)

      early_retirement_age = max(current_age + 10, 65 - years_ahead)

      %{
        early_retirement_age: early_retirement_age,
        years_ahead_of_schedule: years_ahead,
        financial_independence_potential: ahead_factor |> Decimal.to_float() |> Float.round(1)
      }
    else
      %{
        early_retirement_age: 65,
        years_ahead_of_schedule: 0,
        financial_independence_potential: 1.0
      }
    end
  end

  # Private helper functions

  defp calculate_age_from_profile(profile) do
    if Map.has_key?(profile, :birth_year) && profile.birth_year do
      Date.utc_today().year - profile.birth_year
    else
      # Default age if not provided
      40
    end
  end

  defp format_decimal(decimal) do
    decimal
    |> Decimal.round(1)
    |> Decimal.to_string()
  end
end
