defmodule Ashfolio.FinancialManagement.ContributionAnalyzer do
  @moduledoc """
  Advanced contribution analysis for portfolio growth optimization.

  Provides sophisticated analysis of how different contribution levels,
  timing strategies, and optimization approaches impact portfolio growth
  and financial goal achievement.

  ## Core Functions

  - Contribution sensitivity analysis
  - Goal-based contribution optimization
  - Strategy comparison and efficiency analysis
  - Inflation breakeven calculations
  - Dollar cost averaging vs lump sum timing

  ## Patterns

  This module follows patterns established in `ForecastCalculator` and
  `RetirementCalculator` for error handling, logging, and Decimal precision.
  """

  alias Ashfolio.Financial.DecimalHelpers, as: DH
  alias Ashfolio.FinancialManagement.ForecastCalculator
  alias Ashfolio.FinancialManagement.SearchAlgorithms
  alias Ashfolio.FinancialManagement.ValidationHelpers

  require Decimal
  require Logger

  @doc """
  Analyzes impact of different contribution levels on portfolio growth.

  Performs sensitivity analysis showing how variations in monthly contributions
  affect final portfolio value over time. Useful for understanding the
  leverage effect of additional contributions.

  ## Parameters

    - current_value: Decimal - Current portfolio value
    - base_monthly_contribution: Decimal - Base monthly contribution amount
    - years: integer - Investment time horizon
    - growth_rate: Decimal - Expected annual growth rate
    - custom_variations: List of Decimal - Optional custom variation amounts

  ## Returns

    - {:ok, analysis} - Map with base projection and contribution variations
    - {:error, reason} - Error tuple with validation failure

  ## Example Analysis Structure

      %{
        base_projection: %{
          monthly_contribution: Decimal.new("1000"),
          annual_contribution: Decimal.new("12000"),
          final_value: Decimal.new("374051.23")
        },
        contribution_variations: [
          %{
            monthly_contribution: Decimal.new("500"),
            annual_contribution: Decimal.new("6000"),
            final_value: Decimal.new("298234.56"),
            difference_from_base: Decimal.new("-75816.67"),
            percentage_impact: Decimal.new("-20.25")
          }
          # ... more variations
        ]
      }
  """
  def analyze_contribution_impact(current_value, base_monthly_contribution, years, growth_rate, custom_variations \\ nil) do
    Logger.debug("Analyzing contribution impact - base: #{base_monthly_contribution}, years: #{years}")

    with :ok <- ValidationHelpers.validate_current_value(current_value),
         :ok <- ValidationHelpers.validate_monthly_contribution(base_monthly_contribution),
         :ok <- ValidationHelpers.validate_years(years),
         :ok <- ValidationHelpers.validate_growth_rate(growth_rate) do
      # Calculate base projection
      base_annual = DH.monthly_to_annual(base_monthly_contribution)

      case ForecastCalculator.project_portfolio_growth(
             current_value,
             base_annual,
             years,
             growth_rate
           ) do
        {:ok, base_final_value} ->
          base_projection = %{
            monthly_contribution: base_monthly_contribution,
            annual_contribution: base_annual,
            final_value: base_final_value
          }

          # Generate variation amounts
          variation_amounts =
            generate_variations(base_monthly_contribution, custom_variations)

          # Calculate variations
          variations =
            calculate_contribution_variations(
              current_value,
              base_monthly_contribution,
              base_final_value,
              years,
              growth_rate,
              variation_amounts
            )

          analysis = %{
            base_projection: base_projection,
            contribution_variations: variations
          }

          Logger.debug("Contribution analysis completed with #{length(variations)} variations")
          {:ok, analysis}

        {:error, reason} ->
          Logger.warning("Base projection calculation failed: #{inspect(reason)}")
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.warning("Contribution impact analysis validation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Optimizes contribution amount to achieve a specific financial goal.

  Uses iterative calculation to determine the minimum monthly contribution
  needed to reach a target portfolio value within a specified timeframe.
  Includes probability analysis across different market scenarios.

  ## Parameters

    - current_value: Decimal - Current portfolio value
    - target_amount: Decimal - Target portfolio value to achieve
    - years: integer - Years to achieve the target
    - growth_rate: Decimal - Expected annual growth rate

  ## Returns

    - {:ok, optimization} - Map with optimization results
    - {:error, reason} - Error tuple

  ## Example Results Structure

      %{
        required_monthly_contribution: Decimal.new("1847.23"),
        required_annual_contribution: Decimal.new("22166.76"),
        projected_final_value: Decimal.new("1000000.00"),
        goal_already_achieved: false,
        goal_feasibility: :achievable,
        probability_of_success: Decimal.new("73.2"),
        confidence_analysis: %{
          pessimistic: %{goal_met: true, final_value: Decimal.new("892456")},
          realistic: %{goal_met: true, final_value: Decimal.new("1000000")},
          optimistic: %{goal_met: true, final_value: Decimal.new("1124789")}
        }
      }
  """
  def optimize_contribution_for_goal(current_value, target_amount, years, growth_rate) do
    Logger.debug("Optimizing contribution for goal - target: #{target_amount}, years: #{years}")

    with :ok <- ValidationHelpers.validate_current_value(current_value),
         :ok <- validate_goal_target_amount(target_amount),
         :ok <- ValidationHelpers.validate_years(years),
         :ok <- ValidationHelpers.validate_growth_rate(growth_rate) do
      # Check if goal is already achieved
      if Decimal.compare(current_value, target_amount) == :lt do
        # Calculate required contribution using binary search
        case SearchAlgorithms.find_required_contribution(current_value, target_amount, years, growth_rate) do
          {:ok, required_annual} ->
            process_required_contribution(required_annual, current_value, target_amount, years, growth_rate)

          {:error, reason} ->
            Logger.warning("Required contribution calculation failed: #{inspect(reason)}")
            {:error, reason}
        end
      else
        results = %{
          required_monthly_contribution: DH.ensure_decimal("0"),
          required_annual_contribution: DH.ensure_decimal("0"),
          projected_final_value: current_value,
          goal_already_achieved: true,
          current_surplus: Decimal.sub(current_value, target_amount),
          confidence_analysis: build_already_achieved_analysis(current_value, growth_rate, years)
        }

        Logger.debug("Goal already achieved with surplus: #{results.current_surplus}")
        {:ok, results}
      end
    else
      {:error, reason} ->
        Logger.warning("Goal optimization validation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Placeholder implementations - will be implemented incrementally
  # Following TDD approach: minimal implementation to make tests pass

  @doc """
  Compares multiple contribution strategies for achieving a financial goal.

  Analyzes different monthly contribution amounts to determine their
  effectiveness in reaching a target portfolio value, including cost-benefit
  analysis and efficiency metrics.
  """
  def compare_contribution_strategies(current_value, target_amount, years, growth_rate, strategies) do
    Logger.debug("Comparing #{length(strategies)} contribution strategies")

    with :ok <- ValidationHelpers.validate_current_value(current_value),
         :ok <- ValidationHelpers.validate_target_amount(target_amount, current_value),
         :ok <- ValidationHelpers.validate_years(years),
         :ok <- ValidationHelpers.validate_growth_rate(growth_rate) do
      # Analyze each strategy
      analyzed_strategies =
        strategies
        |> Enum.map(&analyze_single_strategy(&1, current_value, target_amount, years, growth_rate))
        |> Enum.filter(&(!is_nil(&1)))

      # Find minimum required contribution
      case optimize_contribution_for_goal(current_value, target_amount, years, growth_rate) do
        {:ok, optimization} ->
          minimum_required = optimization.required_monthly_contribution

          # Determine recommendation
          recommended_strategy = find_recommended_strategy(analyzed_strategies, minimum_required)

          comparison = %{
            strategies: analyzed_strategies,
            recommended_strategy: recommended_strategy,
            minimum_required_contribution: minimum_required,
            efficiency_analysis: build_efficiency_analysis(analyzed_strategies)
          }

          {:ok, comparison}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Calculates minimum contribution needed to maintain purchasing power against inflation.
  """
  def calculate_contribution_breakeven(current_value, inflation_rate, growth_rate, years) do
    Logger.debug("Calculating contribution breakeven against #{inflation_rate} inflation")

    with :ok <- ValidationHelpers.validate_current_value(current_value),
         :ok <- ValidationHelpers.validate_growth_rate(growth_rate),
         :ok <- ValidationHelpers.validate_years(years) do
      real_return_rate = Decimal.sub(growth_rate, inflation_rate)

      # Calculate inflation-adjusted target value
      inflation_factor = calculate_inflation_factor(inflation_rate, years)
      inflation_adjusted_value = Decimal.mult(current_value, inflation_factor)

      # Find contribution needed to reach inflation-adjusted value
      case SearchAlgorithms.find_required_contribution(current_value, inflation_adjusted_value, years, growth_rate) do
        {:ok, required_annual} ->
          required_monthly = DH.annual_to_monthly(required_annual)

          breakeven = %{
            breakeven_monthly_contribution: required_monthly,
            real_return_rate: real_return_rate,
            inflation_adjusted_value: inflation_adjusted_value,
            purchasing_power_maintained: true,
            contribution_required_reason: determine_contribution_reason(real_return_rate)
          }

          {:ok, breakeven}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Analyzes lump sum vs dollar cost averaging timing strategies.
  """
  def analyze_contribution_timing(current_value, available_amount, years, growth_rate, volatility) do
    Logger.debug("Analyzing contribution timing with #{volatility} volatility")

    with :ok <- ValidationHelpers.validate_current_value(current_value),
         :ok <- ValidationHelpers.validate_growth_rate(growth_rate),
         :ok <- ValidationHelpers.validate_years(years) do
      # Calculate lump sum scenario
      lump_sum_total = Decimal.add(current_value, available_amount)

      case ForecastCalculator.project_portfolio_growth(
             lump_sum_total,
             DH.ensure_decimal("0"),
             years,
             growth_rate
           ) do
        {:ok, lump_sum_value} ->
          # Calculate DCA scenario
          monthly_dca = Decimal.div(available_amount, DH.ensure_decimal(to_string(years * 12)))

          case ForecastCalculator.project_portfolio_growth(
                 current_value,
                 DH.monthly_to_annual(monthly_dca),
                 years,
                 growth_rate
               ) do
            {:ok, dca_value} ->
              volatility_assessment = assess_volatility_level(volatility)

              timing_analysis = %{
                lump_sum: %{
                  expected_value: lump_sum_value,
                  best_case: calculate_best_case(lump_sum_value, volatility),
                  worst_case: calculate_worst_case(lump_sum_value, volatility),
                  volatility_impact: volatility
                },
                dollar_cost_averaging: %{
                  expected_value: dca_value,
                  monthly_amount: monthly_dca,
                  volatility_reduction: calculate_volatility_reduction(volatility),
                  opportunity_cost: Decimal.sub(lump_sum_value, dca_value)
                },
                recommendation: build_timing_recommendation(lump_sum_value, dca_value, volatility_assessment)
              }

              {:ok, timing_analysis}

            {:error, reason} ->
              {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Private helper functions

  defp generate_variations(base_monthly, custom_variations) do
    if custom_variations do
      # Use provided variations, ensuring no negative results
      custom_variations
      |> Enum.map(&Decimal.add(base_monthly, &1))
      |> Enum.filter(&(!DH.negative?(&1)))
    else
      # Standard variations: -$500, -$100, +$100, +$500, +$1000
      [
        DH.ensure_decimal("-500"),
        DH.ensure_decimal("-100"),
        DH.ensure_decimal("100"),
        DH.ensure_decimal("500"),
        DH.ensure_decimal("1000")
      ]
      |> Enum.map(&Decimal.add(base_monthly, &1))
      |> Enum.filter(&(!DH.negative?(&1)))
    end
  end

  defp calculate_contribution_variations(
         current_value,
         _base_monthly,
         base_final_value,
         years,
         growth_rate,
         variation_amounts
       ) do
    variation_amounts
    |> Enum.map(&calculate_single_variation(&1, current_value, base_final_value, years, growth_rate))
    |> Enum.filter(&(!is_nil(&1)))
  end

  # Helper function to reduce nesting depth
  defp calculate_single_variation(monthly_amount, current_value, base_final_value, years, growth_rate) do
    annual_amount = DH.monthly_to_annual(monthly_amount)

    case ForecastCalculator.project_portfolio_growth(current_value, annual_amount, years, growth_rate) do
      {:ok, final_value} ->
        build_variation_result(monthly_amount, annual_amount, final_value, base_final_value)

      {:error, _reason} ->
        nil
    end
  end

  # Helper function to reduce nesting depth
  defp process_required_contribution(required_annual, current_value, target_amount, years, growth_rate) do
    # Add buffer to ensure we meet target with AER precision
    required_annual = Decimal.mult(required_annual, DH.ensure_decimal("1.002"))
    required_monthly = DH.annual_to_monthly(required_annual)

    # Verify with final calculation
    case ForecastCalculator.project_portfolio_growth(current_value, required_annual, years, growth_rate) do
      {:ok, projected_final} ->
        build_optimization_results(
          required_monthly,
          required_annual,
          projected_final,
          current_value,
          target_amount,
          years,
          growth_rate
        )

      {:error, reason} ->
        Logger.warning("Final projection verification failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Helper function to reduce nesting depth
  defp build_optimization_results(
         required_monthly,
         required_annual,
         projected_final,
         current_value,
         target_amount,
         years,
         growth_rate
       ) do
    # Calculate confidence analysis
    confidence_analysis = build_confidence_analysis(current_value, required_annual, target_amount, years)
    probability = calculate_success_probability(confidence_analysis)

    results = %{
      required_monthly_contribution: required_monthly,
      required_annual_contribution: required_annual,
      projected_final_value: projected_final,
      goal_already_achieved: false,
      goal_feasibility: assess_goal_feasibility(required_monthly),
      probability_of_success: probability,
      confidence_analysis: confidence_analysis
    }

    # Add alternative timeline if goal is challenging
    results = add_alternative_timeline_if_challenging(results, current_value, target_amount, growth_rate)

    Logger.debug("Optimization complete - required monthly: #{required_monthly}")

    {:ok, results}
  end

  # Helper function to reduce nesting depth
  defp add_alternative_timeline_if_challenging(results, current_value, target_amount, growth_rate) do
    if results.goal_feasibility == :challenging do
      alternative = build_alternative_timeline(current_value, target_amount, growth_rate)

      results
      |> Map.put(:alternative_timeline, alternative)
      |> Map.put(:maximum_reasonable_contribution, alternative.suggested_monthly_contribution)
      |> Map.put(:achievable_with_max_contribution, alternative.achievable_with_max_contribution)
    else
      results
    end
  end

  # Helper function to reduce nesting depth
  defp build_variation_result(monthly_amount, annual_amount, final_value, base_final_value) do
    difference = Decimal.sub(final_value, base_final_value)

    percentage_impact =
      if DH.positive?(base_final_value) do
        difference
        |> Decimal.div(base_final_value)
        |> DH.to_percentage()
        |> DH.round_to(2)
      else
        DH.ensure_decimal("0.00")
      end

    %{
      monthly_contribution: monthly_amount,
      annual_contribution: annual_amount,
      final_value: final_value,
      difference_from_base: difference,
      percentage_impact: percentage_impact
    }
  end

  defp build_confidence_analysis(current_value, annual_contribution, target_amount, years) do
    scenarios = [
      {:pessimistic, DH.ensure_decimal("0.05")},
      {:realistic, DH.ensure_decimal("0.07")},
      {:optimistic, DH.ensure_decimal("0.10")}
    ]

    Enum.reduce(scenarios, %{}, fn {scenario_name, rate}, acc ->
      case ForecastCalculator.project_portfolio_growth(
             current_value,
             annual_contribution,
             years,
             rate
           ) do
        {:ok, final_value} ->
          goal_met = Decimal.compare(final_value, target_amount) != :lt

          scenario_result = %{
            goal_met: goal_met,
            final_value: final_value
          }

          Map.put(acc, scenario_name, scenario_result)

        {:error, _reason} ->
          # Skip failed scenarios
          acc
      end
    end)
  end

  defp build_already_achieved_analysis(current_value, _growth_rate, _years) do
    scenarios = [
      {:pessimistic, DH.ensure_decimal("0.05")},
      {:realistic, DH.ensure_decimal("0.07")},
      {:optimistic, DH.ensure_decimal("0.10")}
    ]

    Enum.reduce(scenarios, %{}, fn {scenario_name, _rate}, acc ->
      scenario_result = %{
        years_to_fi: 0,
        fi_portfolio_value: current_value
      }

      Map.put(acc, scenario_name, scenario_result)
    end)
  end

  defp calculate_success_probability(confidence_analysis) do
    # Calculate weighted probability based on scenario outcomes
    # Weights: 20% pessimistic, 60% realistic, 20% optimistic
    weights = %{
      pessimistic: DH.ensure_decimal("0.20"),
      realistic: DH.ensure_decimal("0.60"),
      optimistic: DH.ensure_decimal("0.20")
    }

    weighted_success =
      Enum.reduce(weights, DH.ensure_decimal("0"), fn {scenario_name, weight}, acc ->
        calculate_weighted_scenario_success(confidence_analysis, scenario_name, weight, acc)
      end)

    # Convert to percentage
    weighted_success
    |> DH.to_percentage()
    |> DH.round_to(1)
  end

  defp assess_goal_feasibility(required_monthly) do
    challenging_threshold = DH.ensure_decimal("5000")
    ambitious_threshold = DH.ensure_decimal("2500")

    cond do
      Decimal.compare(required_monthly, challenging_threshold) == :gt ->
        :challenging

      Decimal.compare(required_monthly, ambitious_threshold) == :gt ->
        :ambitious

      true ->
        :achievable
    end
  end

  defp build_alternative_timeline(current_value, target_amount, growth_rate) do
    # For challenging goals, suggest more realistic timeline
    max_reasonable_monthly = DH.ensure_decimal("3000")
    max_reasonable_annual = DH.monthly_to_annual(max_reasonable_monthly)

    # Find years needed with reasonable contribution
    years_needed =
      SearchAlgorithms.find_years_for_contribution(
        current_value,
        max_reasonable_annual,
        target_amount,
        growth_rate
      )

    # Check if achievable with max contribution
    case ForecastCalculator.project_portfolio_growth(
           current_value,
           max_reasonable_annual,
           years_needed,
           growth_rate
         ) do
      {:ok, projected_value} ->
        achievable = Decimal.compare(projected_value, target_amount) != :lt

        %{
          years_needed: years_needed,
          suggested_monthly_contribution: max_reasonable_monthly,
          maximum_reasonable_contribution: max_reasonable_monthly,
          achievable_with_max_contribution: achievable
        }

      {:error, _reason} ->
        %{
          years_needed: years_needed,
          suggested_monthly_contribution: max_reasonable_monthly,
          maximum_reasonable_contribution: max_reasonable_monthly,
          achievable_with_max_contribution: false
        }
    end
  end

  # Additional helper functions for new functionality

  defp analyze_single_strategy(strategy, current_value, target_amount, years, growth_rate) do
    %{name: name, monthly: monthly_contribution} = strategy
    annual_contribution = DH.monthly_to_annual(monthly_contribution)

    case ForecastCalculator.project_portfolio_growth(
           current_value,
           annual_contribution,
           years,
           growth_rate
         ) do
      {:ok, final_value} ->
        total_contributions = Decimal.mult(annual_contribution, DH.ensure_decimal(to_string(years)))
        goal_achieved = Decimal.compare(final_value, target_amount) != :lt
        surplus_or_shortfall = Decimal.sub(final_value, target_amount)

        # Calculate years to goal
        years_to_goal =
          if goal_achieved do
            SearchAlgorithms.find_years_for_contribution(
              current_value,
              annual_contribution,
              target_amount,
              growth_rate
            )
          else
            # For unachieved goals, use reasonable upper bound
            50
          end

        # Calculate efficiency metrics
        contribution_efficiency =
          calculate_contribution_efficiency(final_value, total_contributions)

        marginal_benefit = calculate_marginal_benefit(monthly_contribution, final_value)

        %{
          name: name,
          monthly_contribution: monthly_contribution,
          total_contributions: total_contributions,
          final_value: final_value,
          goal_achieved: goal_achieved,
          surplus_or_shortfall: surplus_or_shortfall,
          years_to_goal: years_to_goal,
          contribution_efficiency: contribution_efficiency,
          marginal_benefit: marginal_benefit
        }

      {:error, _reason} ->
        nil
    end
  end

  defp find_recommended_strategy(strategies, minimum_required) do
    # Find strategy closest to minimum required that achieves goal
    achieving_strategies = Enum.filter(strategies, & &1.goal_achieved)

    case achieving_strategies do
      [] ->
        # No strategy achieves goal, recommend highest contribution
        Enum.max_by(strategies, & &1.monthly_contribution).name

      _ ->
        # Find most efficient achieving strategy
        achieving_strategies
        |> Enum.filter(&(Decimal.compare(&1.monthly_contribution, minimum_required) != :lt))
        |> Enum.min_by(& &1.monthly_contribution, fn -> List.first(achieving_strategies) end)
        |> Map.get(:name)
    end
  end

  defp build_efficiency_analysis(strategies) do
    total_strategies = length(strategies)
    achieving_goals = Enum.count(strategies, & &1.goal_achieved)

    %{
      total_strategies_analyzed: total_strategies,
      strategies_achieving_goal: achieving_goals,
      success_rate:
        achieving_goals
        |> DH.ensure_decimal()
        |> Decimal.div(DH.ensure_decimal(total_strategies))
        |> DH.to_percentage()
        |> DH.round_to(1)
    }
  end

  defp calculate_contribution_efficiency(final_value, total_contributions) do
    if DH.positive?(total_contributions) do
      final_value |> Decimal.div(total_contributions) |> DH.round_to(2)
    else
      DH.ensure_decimal("1.0")
    end
  end

  defp calculate_marginal_benefit(monthly_contribution, _final_value) do
    # Marginal benefit per dollar contributed
    # For excessive contributions, this should be lower (diminishing returns)
    total_annual_contribution = DH.monthly_to_annual(monthly_contribution)

    if DH.positive?(total_annual_contribution) do
      # Simple diminishing returns model: higher contributions = lower marginal benefit
      very_high_threshold = DH.ensure_decimal("2500")
      high_threshold = DH.ensure_decimal("1500")

      cond do
        Decimal.compare(monthly_contribution, very_high_threshold) == :gt ->
          # Very high contributions have low marginal benefit
          DH.ensure_decimal("0.8")

        Decimal.compare(monthly_contribution, high_threshold) == :gt ->
          # High contributions have reduced benefit
          DH.ensure_decimal("0.9")

        true ->
          # Normal contributions have standard benefit
          DH.ensure_decimal("1.1")
      end
    else
      DH.ensure_decimal("1.0")
    end
  end

  defp calculate_inflation_factor(inflation_rate, years) do
    # (1 + inflation_rate)^years
    inflation_multiplier = Decimal.add(DH.ensure_decimal("1"), inflation_rate)

    Enum.reduce(1..years, DH.ensure_decimal("1"), fn _year, acc ->
      Decimal.mult(acc, inflation_multiplier)
    end)
  end

  defp determine_contribution_reason(real_return_rate) do
    if DH.negative?(real_return_rate) do
      :negative_real_returns
    else
      :maintain_purchasing_power
    end
  end

  defp assess_volatility_level(volatility) do
    high_threshold = DH.ensure_decimal("0.20")
    medium_threshold = DH.ensure_decimal("0.10")

    cond do
      Decimal.compare(volatility, high_threshold) == :gt -> :high
      Decimal.compare(volatility, medium_threshold) == :gt -> :medium
      true -> :low
    end
  end

  defp calculate_best_case(expected_value, volatility) do
    # Best case: expected + 2 standard deviations
    volatility_impact = Decimal.mult(expected_value, Decimal.mult(volatility, DH.ensure_decimal("2")))
    Decimal.add(expected_value, volatility_impact)
  end

  defp calculate_worst_case(expected_value, volatility) do
    # Worst case: expected - 2 standard deviations
    volatility_impact = Decimal.mult(expected_value, Decimal.mult(volatility, DH.ensure_decimal("2")))
    worst_case = Decimal.sub(expected_value, volatility_impact)
    # Ensure not negative
    if DH.negative?(worst_case) do
      DH.ensure_decimal("0")
    else
      worst_case
    end
  end

  defp calculate_volatility_reduction(volatility) do
    # DCA typically reduces effective volatility
    volatility |> Decimal.mult(DH.ensure_decimal("0.7")) |> DH.round_to(3)
  end

  defp build_timing_recommendation(lump_sum_value, dca_value, volatility_assessment) do
    strategy = determine_strategy(volatility_assessment, lump_sum_value, dca_value)
    reasoning = get_strategy_reasoning(strategy, volatility_assessment)

    %{
      strategy: strategy,
      volatility_assessment: volatility_assessment,
      reasoning: reasoning
    }
  end

  defp determine_strategy(:high, _lump, _dca), do: :dollar_cost_averaging
  defp determine_strategy(:low, _lump, _dca), do: :lump_sum

  defp determine_strategy(:medium, lump_sum_value, dca_value) do
    if Decimal.compare(lump_sum_value, dca_value) == :gt do
      :lump_sum
    else
      :dollar_cost_averaging
    end
  end

  defp get_strategy_reasoning(:lump_sum, :low), do: "Low volatility favors lump sum investment"
  defp get_strategy_reasoning(:dollar_cost_averaging, :high), do: "High volatility makes DCA less risky"
  defp get_strategy_reasoning(:lump_sum, :medium), do: "Lump sum provides higher expected returns"
  defp get_strategy_reasoning(:dollar_cost_averaging, :medium), do: "DCA provides better risk-adjusted returns"
  defp get_strategy_reasoning(_, _), do: "Hybrid approach may be optimal"

  defp calculate_weighted_scenario_success(confidence_analysis, scenario_name, weight, acc) do
    case Map.get(confidence_analysis, scenario_name) do
      nil -> acc
      scenario -> add_weighted_success(scenario, weight, acc)
    end
  end

  defp add_weighted_success(scenario, weight, acc) do
    success_value = if scenario.goal_met, do: DH.ensure_decimal("1"), else: DH.ensure_decimal("0")
    weighted_contribution = Decimal.mult(success_value, weight)
    Decimal.add(acc, weighted_contribution)
  end

  # Custom validation for goal optimization that allows already-achieved goals
  defp validate_goal_target_amount(target_amount) when is_struct(target_amount, Decimal) do
    if Decimal.compare(target_amount, Decimal.new("0")) == :gt do
      :ok
    else
      {:error, "Target amount must be positive"}
    end
  end

  defp validate_goal_target_amount(_), do: {:error, "Target amount must be a valid decimal"}
end
