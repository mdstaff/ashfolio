defmodule Ashfolio.FinancialManagement.ForecastCalculator do
  @moduledoc """
  Portfolio growth forecasting calculations using standardized AER methodology.

  All calculations use the Annual Equivalent Rate (AER) approach through integration
  with `Ashfolio.FinancialManagement.AERCalculator` to ensure consistent compound
  interest calculations across all portfolio projections.

  ## AER Standardization (v0.4.3+)

  **Current Implementation:**
  - All scenarios use consistent AER methodology via AERCalculator
  - Growth rates are interpreted as Annual Equivalent Rates
  - Monthly contributions are properly converted using AER-to-monthly conversion
  - Results are consistent across all functions and time periods

  ## Key Features

  - **Portfolio Projections**: Single and multi-period growth calculations
  - **Scenario Analysis**: Pessimistic, realistic, and optimistic projections
  - **Financial Independence**: 25x rule calculations and timeline analysis  
  - **Contribution Analysis**: Impact analysis and optimization calculations
  - **CAGR Analysis**: Compound Annual Growth Rate calculations for comparison

  ## Patterns

  This module follows patterns established in `lib/ashfolio/financial_management/retirement_calculator.ex`
  for error handling, logging, and Decimal arithmetic precision. All compound interest
  calculations are delegated to AERCalculator for consistency and accuracy.
  """

  alias Ashfolio.FinancialManagement.AERCalculator

  require Logger

  @doc """
  Projects portfolio growth using standardized Annual Equivalent Rate (AER) methodology.

  Delegates to AERCalculator.compound_with_aer/4 for consistent compound interest
  calculations across all portfolio projections. All growth rates are interpreted
  as Annual Equivalent Rates, with contributions handled via AER-to-monthly conversion.

  ## AER Methodology

  - Growth rates are treated as Annual Equivalent Rates (user expectation: 7% = 7% effective annually)
  - Monthly contributions use proper AER-to-monthly rate conversion
  - Results match user expectations for annual growth rates
  - Consistent across all time periods and scenario analysis

  ## Examples

      iex> ForecastCalculator.project_portfolio_growth(Decimal.new("100000"), Decimal.new("0"), 10, Decimal.new("0.07"))
      {:ok, Decimal.new("196715.14")}

      iex> ForecastCalculator.project_portfolio_growth(Decimal.new("100000"), Decimal.new("12000"), 10, Decimal.new("0.07"))
      {:ok, Decimal.new("235000.00")}

  ## Parameters

    - current_value: Decimal - Current portfolio value
    - annual_contribution: Decimal - Annual contribution amount
    - years: integer - Number of years to project
    - growth_rate: Decimal - Annual growth rate (e.g., 0.07 for 7%)

  ## Returns

    - {:ok, projected_value} - Decimal projected portfolio value
    - {:error, reason} - Error tuple with descriptive reason
  """
  def project_portfolio_growth(current_value, annual_contribution, years, growth_rate) do
    Logger.debug(
      "Projecting portfolio growth - current: #{current_value}, contribution: #{annual_contribution}, years: #{years}, rate: #{growth_rate}"
    )

    with :ok <- validate_current_value(current_value),
         :ok <- validate_annual_contribution(annual_contribution),
         :ok <- validate_years(years),
         :ok <- validate_growth_rate(growth_rate) do
      projected_value =
        calculate_compound_growth_with_contributions(
          current_value,
          annual_contribution,
          years,
          growth_rate
        )

      Logger.debug("Portfolio projection calculated: #{projected_value}")
      {:ok, projected_value}
    else
      {:error, reason} ->
        Logger.warning("Portfolio projection failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Projects portfolio growth over multiple time periods with detailed analysis.

  Calculates projections for multiple time horizons, includes yearly breakdown
  for the first 5 years, and provides CAGR analysis for each period.

  ## Examples

      iex> ForecastCalculator.project_multi_period_growth(Decimal.new("100000"), Decimal.new("12000"), Decimal.new("0.07"), [5, 10, 20])
      {:ok, %{year_5: Decimal.new("..."), year_10: Decimal.new("..."), yearly_breakdown: %{...}, cagr: %{...}}}

  ## Parameters

    - current_value: Decimal - Current portfolio value
    - annual_contribution: Decimal - Annual contribution amount
    - growth_rate: Decimal - Annual growth rate (e.g., 0.07 for 7%)
    - periods: List of integers - Years to project (e.g., [5, 10, 15, 20, 25, 30])

  ## Returns

    - {:ok, projections_map} - Map with period projections, yearly breakdown, and CAGR
    - {:error, reason} - Error tuple with descriptive reason

  ## Return Structure

      %{
        year_5: Decimal.new("..."),
        year_10: Decimal.new("..."),
        yearly_breakdown: %{
          year_1: %{portfolio_value: Decimal, total_contributions: Decimal, growth_amount: Decimal},
          ...
        },
        cagr: %{
          year_5: Decimal.new("..."), # CAGR as percentage
          year_10: Decimal.new("..."),
          ...
        }
      }
  """
  def project_multi_period_growth(current_value, annual_contribution, growth_rate, periods) do
    Logger.debug(
      "Projecting multi-period growth for #{length(periods)} periods - current: #{current_value}, contribution: #{annual_contribution}, rate: #{growth_rate}"
    )

    with :ok <- validate_current_value(current_value),
         :ok <- validate_annual_contribution(annual_contribution),
         :ok <- validate_growth_rate(growth_rate),
         :ok <- validate_periods_list(periods) do
      # Sort periods for consistent processing
      sorted_periods = Enum.sort(periods)

      # Calculate projections for each period
      period_projections =
        calculate_all_period_projections(
          current_value,
          annual_contribution,
          growth_rate,
          sorted_periods
        )

      # Generate yearly breakdown (first 5 years)
      yearly_breakdown =
        calculate_yearly_breakdown(
          current_value,
          annual_contribution,
          growth_rate
        )

      # Calculate CAGR for each period
      cagr_analysis =
        calculate_cagr_analysis(
          current_value,
          period_projections,
          sorted_periods
        )

      # Combine results
      results =
        Map.merge(period_projections, %{
          yearly_breakdown: yearly_breakdown,
          cagr: cagr_analysis
        })

      Logger.debug("Multi-period projections calculated for #{length(sorted_periods)} periods")
      {:ok, results}
    else
      {:error, reason} ->
        Logger.warning("Multi-period projection failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private validation functions following RetirementCalculator patterns

  defp validate_current_value(%Decimal{} = current_value) do
    case Decimal.compare(current_value, Decimal.new("0")) do
      :lt -> {:error, :negative_current_value}
      _ -> :ok
    end
  end

  defp validate_current_value(_), do: {:error, :invalid_input}

  defp validate_annual_contribution(%Decimal{} = annual_contribution) do
    case Decimal.compare(annual_contribution, Decimal.new("0")) do
      :lt -> {:error, :negative_contribution}
      _ -> :ok
    end
  end

  defp validate_annual_contribution(_), do: {:error, :invalid_input}

  defp validate_years(years) when is_integer(years) and years >= 0, do: :ok
  defp validate_years(_), do: {:error, :invalid_years}

  defp validate_growth_rate(%Decimal{} = growth_rate) do
    cond do
      Decimal.compare(growth_rate, Decimal.new("0.5")) == :gt ->
        # > 50% is unrealistic
        {:error, :unrealistic_growth}

      Decimal.compare(growth_rate, Decimal.new("-0.5")) == :lt ->
        # < -50% is unrealistic
        {:error, :unrealistic_growth}

      true ->
        :ok
    end
  end

  defp validate_growth_rate(_), do: {:error, :invalid_input}

  # Private calculation functions

  defp calculate_compound_growth_with_contributions(current_value, annual_contribution, years, growth_rate) do
    # Delegate to AERCalculator for standardized compound interest methodology
    # Convert annual contribution to monthly for AERCalculator API
    monthly_contribution = Decimal.div(annual_contribution, Decimal.new("12"))

    # Use AERCalculator.compound_with_aer/4 for consistent calculations
    result =
      AERCalculator.compound_with_aer(
        current_value,
        growth_rate,
        years,
        monthly_contribution
      )

    # For scenarios with contributions, round to 2 decimal places for backward compatibility
    # For growth-only scenarios, maintain AERCalculator precision for exact UI interpretation
    if Decimal.equal?(annual_contribution, Decimal.new("0")) do
      result
    else
      Decimal.round(result, 2)
    end
  end

  # Multi-period validation and calculation helpers

  defp validate_periods_list(periods) when is_list(periods) do
    if Enum.all?(periods, &is_integer/1) and Enum.all?(periods, &(&1 >= 0)) do
      :ok
    else
      {:error, :invalid_periods}
    end
  end

  defp validate_periods_list(_), do: {:error, :invalid_periods}

  defp calculate_all_period_projections(current_value, annual_contribution, growth_rate, periods) do
    Enum.reduce(periods, %{}, fn years, acc ->
      case project_portfolio_growth(current_value, annual_contribution, years, growth_rate) do
        {:ok, projected_value} ->
          period_key = String.to_atom("year_#{years}")
          Map.put(acc, period_key, projected_value)

        {:error, _reason} ->
          # Skip invalid periods but continue processing others
          acc
      end
    end)
  end

  defp calculate_yearly_breakdown(current_value, annual_contribution, growth_rate) do
    # Calculate detailed breakdown for first 5 years
    Enum.reduce(1..5, %{}, fn year, acc ->
      case project_portfolio_growth(current_value, annual_contribution, year, growth_rate) do
        {:ok, portfolio_value} ->
          # Calculate components
          total_contributions = Decimal.mult(annual_contribution, Decimal.new(to_string(year)))
          # Growth amount = final value - initial - contributions
          growth_amount =
            portfolio_value
            |> Decimal.sub(current_value)
            |> Decimal.sub(total_contributions)
            |> Decimal.round(2)

          year_data = %{
            portfolio_value: portfolio_value,
            total_contributions: total_contributions,
            growth_amount: growth_amount
          }

          period_key = String.to_atom("year_#{year}")
          Map.put(acc, period_key, year_data)

        {:error, _reason} ->
          # Skip invalid years
          acc
      end
    end)
  end

  defp calculate_cagr_analysis(current_value, period_projections, periods) do
    Enum.reduce(periods, %{}, fn years, acc ->
      period_key = String.to_atom("year_#{years}")

      case Map.get(period_projections, period_key) do
        nil ->
          # No projection available for this period
          acc

        final_value ->
          cagr_percentage = calculate_cagr(current_value, final_value, years)
          Map.put(acc, period_key, cagr_percentage)
      end
    end)
  end

  defp calculate_cagr(initial_value, final_value, years) do
    cond do
      years == 0 ->
        # No time has passed, no growth rate
        Decimal.new("0.00")

      Decimal.equal?(initial_value, Decimal.new("0")) ->
        # Can't calculate CAGR with zero initial value
        Decimal.new("0.00")

      true ->
        # CAGR = (Final/Initial)^(1/years) - 1
        # Convert to percentage for user-friendly display
        ratio = Decimal.div(final_value, initial_value)

        # For simplicity, use approximation for fractional powers
        # This is accurate enough for financial planning purposes
        approximate_cagr = calculate_approximate_cagr(ratio, years)

        # Convert to percentage and round to 2 decimal places
        approximate_cagr
        |> Decimal.mult(Decimal.new("100"))
        |> Decimal.round(2)
    end
  end

  defp calculate_approximate_cagr(ratio, years) do
    # For CAGR calculation, we need the nth root: ratio^(1/years) - 1
    # Use iterative approximation for better accuracy
    if Decimal.equal?(ratio, Decimal.new("1")) do
      Decimal.new("0")
    else
      # Use binary search to find the nth root
      nth_root = calculate_nth_root(ratio, years)
      Decimal.sub(nth_root, Decimal.new("1"))
    end
  end

  defp calculate_nth_root(value, n) do
    # Binary search approximation for nth root
    # For typical investment scenarios, this provides sufficient accuracy
    decimal_n = Decimal.new(to_string(n))

    # Initial bounds: between 0.5 and 2.0 covers most financial scenarios
    low = Decimal.new("0.5")
    high = Decimal.new("2.0")

    # Perform binary search iterations
    # 20 iterations for precision
    binary_search_nth_root(value, decimal_n, low, high, 20)
  end

  defp binary_search_nth_root(target, n, low, high, iterations_left) do
    if iterations_left <= 0 do
      # Return midpoint as final approximation
      low |> Decimal.add(high) |> Decimal.div(Decimal.new("2"))
    else
      mid = low |> Decimal.add(high) |> Decimal.div(Decimal.new("2"))
      mid_power_n = power(mid, Decimal.to_integer(n))

      case Decimal.compare(mid_power_n, target) do
        :lt ->
          # mid^n < target, need higher value
          binary_search_nth_root(target, n, mid, high, iterations_left - 1)

        :gt ->
          # mid^n > target, need lower value
          binary_search_nth_root(target, n, low, mid, iterations_left - 1)

        :eq ->
          # Perfect match found
          mid
      end
    end
  end

  @doc """
  Calculates scenario projections using standard growth rates for comparison.

  Provides three standard scenarios (pessimistic 5%, realistic 7%, optimistic 10%)
  along with probability-weighted outcomes for comprehensive financial planning.

  ## Examples

      iex> ForecastCalculator.calculate_scenario_projections(Decimal.new("100000"), Decimal.new("12000"), 30)
      {:ok, %{pessimistic: %{...}, realistic: %{...}, optimistic: %{...}, weighted_average: %{...}}}

  ## Parameters

    - current_value: Decimal - Current portfolio value
    - annual_contribution: Decimal - Annual contribution amount
    - years: integer - Number of years to project

  ## Returns

    - {:ok, scenarios_map} - Map with scenario projections
    - {:error, reason} - Error tuple with descriptive reason

  ## Return Structure

      %{
        pessimistic: %{growth_rate: Decimal.new("0.05"), portfolio_value: Decimal},
        realistic: %{growth_rate: Decimal.new("0.07"), portfolio_value: Decimal},
        optimistic: %{growth_rate: Decimal.new("0.10"), portfolio_value: Decimal},
        weighted_average: %{portfolio_value: Decimal, weights: %{...}}
      }
  """
  def calculate_scenario_projections(current_value, annual_contribution, years) do
    Logger.debug(
      "Calculating scenario projections - current: #{current_value}, contribution: #{annual_contribution}, years: #{years}"
    )

    # Use standard scenario rates
    standard_scenarios = [
      %{name: :pessimistic, rate: Decimal.new("0.05")},
      %{name: :realistic, rate: Decimal.new("0.07")},
      %{name: :optimistic, rate: Decimal.new("0.10")}
    ]

    with :ok <- validate_current_value(current_value),
         :ok <- validate_annual_contribution(annual_contribution),
         :ok <- validate_years(years) do
      # Calculate each standard scenario
      scenario_results =
        calculate_all_scenarios(current_value, annual_contribution, years, standard_scenarios)

      # Calculate weighted average (20% pessimistic, 60% realistic, 20% optimistic)
      weighted_average = calculate_weighted_average_scenario(scenario_results)

      results = Map.put(scenario_results, :weighted_average, weighted_average)

      Logger.debug("Scenario projections calculated for #{length(standard_scenarios)} scenarios")
      {:ok, results}
    else
      {:error, reason} ->
        Logger.warning("Scenario projection failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculates custom scenario projections with user-defined growth rates.

  Allows comparison of portfolio growth under custom assumptions for
  specialized financial planning scenarios.

  ## Examples

      custom_scenarios = [
        %{name: :conservative, rate: Decimal.new("0.04")},
        %{name: :aggressive, rate: Decimal.new("0.12")}
      ]

      iex> ForecastCalculator.calculate_custom_scenarios(Decimal.new("100000"), Decimal.new("12000"), 20, custom_scenarios)
      {:ok, %{conservative: %{...}, aggressive: %{...}}}

  ## Parameters

    - current_value: Decimal - Current portfolio value
    - annual_contribution: Decimal - Annual contribution amount
    - years: integer - Number of years to project
    - scenarios: List of maps - Each with :name and :rate keys

  ## Returns

    - {:ok, scenarios_map} - Map with custom scenario projections
    - {:error, reason} - Error tuple with descriptive reason
  """
  def calculate_custom_scenarios(current_value, annual_contribution, years, scenarios) do
    Logger.debug(
      "Calculating custom scenarios - current: #{current_value}, contribution: #{annual_contribution}, years: #{years}, scenarios: #{length(scenarios)}"
    )

    with :ok <- validate_current_value(current_value),
         :ok <- validate_annual_contribution(annual_contribution),
         :ok <- validate_years(years),
         :ok <- validate_custom_scenarios(scenarios) do
      results = calculate_all_scenarios(current_value, annual_contribution, years, scenarios)

      Logger.debug("Custom scenarios calculated for #{length(scenarios)} scenarios")
      {:ok, results}
    else
      {:error, reason} ->
        Logger.warning("Custom scenario calculation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculates financial independence timeline using the 25x expenses rule.

  Uses the 4% safe withdrawal rate principle to determine when portfolio
  value will support target annual expenses. Includes scenario analysis
  for comprehensive FI planning.

  ## Examples

      iex> ForecastCalculator.calculate_fi_timeline(Decimal.new("100000"), Decimal.new("12000"), Decimal.new("50000"), Decimal.new("0.07"))
      {:ok, %{years_to_fi: 15, fi_target_amount: Decimal.new("1250000"), scenario_analysis: %{...}}}

  ## Parameters

    - current_value: Decimal - Current portfolio value
    - annual_contribution: Decimal - Annual contribution amount
    - annual_expenses: Decimal - Target annual expenses in retirement
    - growth_rate: Decimal - Expected growth rate

  ## Returns

    - {:ok, fi_analysis} - Map with FI timeline analysis
    - {:error, reason} - Error tuple with descriptive reason

  ## Return Structure

      %{
        years_to_fi: integer,
        fi_target_amount: Decimal,
        fi_portfolio_value: Decimal,
        safe_withdrawal_rate: Decimal,
        scenario_analysis: %{
          pessimistic: %{years_to_fi: integer, fi_portfolio_value: Decimal},
          realistic: %{years_to_fi: integer, fi_portfolio_value: Decimal},
          optimistic: %{years_to_fi: integer, fi_portfolio_value: Decimal}
        }
      }
  """
  def calculate_fi_timeline(current_value, annual_contribution, annual_expenses, growth_rate) do
    Logger.debug(
      "Calculating FI timeline - current: #{current_value}, contribution: #{annual_contribution}, expenses: #{annual_expenses}, rate: #{growth_rate}"
    )

    with :ok <- validate_current_value(current_value),
         :ok <- validate_annual_contribution(annual_contribution),
         :ok <- validate_annual_expenses(annual_expenses),
         :ok <- validate_growth_rate(growth_rate) do
      # Calculate 25x target using 4% safe withdrawal rate
      fi_target_amount = Decimal.mult(annual_expenses, Decimal.new("25"))
      safe_withdrawal_rate = Decimal.new("0.04")

      # Check if already financially independent
      if Decimal.compare(current_value, fi_target_amount) == :lt do
        # Calculate years to reach FI target
        years_to_fi =
          calculate_years_to_target(
            current_value,
            annual_contribution,
            fi_target_amount,
            growth_rate
          )

        # Calculate FI portfolio value (should meet or exceed target)
        case project_portfolio_growth(
               current_value,
               annual_contribution,
               years_to_fi,
               growth_rate
             ) do
          {:ok, fi_portfolio_value} ->
            # Calculate scenario analysis for FI planning
            scenario_analysis =
              calculate_fi_scenario_analysis(
                current_value,
                annual_contribution,
                fi_target_amount
              )

            results = %{
              years_to_fi: years_to_fi,
              fi_target_amount: fi_target_amount,
              fi_portfolio_value: fi_portfolio_value,
              safe_withdrawal_rate: safe_withdrawal_rate,
              scenario_analysis: scenario_analysis
            }

            Logger.debug("FI timeline calculated: #{years_to_fi} years to reach #{fi_target_amount}")

            {:ok, results}

          {:error, reason} ->
            Logger.warning("FI portfolio value calculation failed: #{inspect(reason)}")
            {:error, reason}
        end
      else
        # Already FI
        results = %{
          years_to_fi: 0,
          fi_target_amount: fi_target_amount,
          fi_portfolio_value: current_value,
          safe_withdrawal_rate: safe_withdrawal_rate,
          scenario_analysis: %{
            pessimistic: %{years_to_fi: 0, fi_portfolio_value: current_value},
            realistic: %{years_to_fi: 0, fi_portfolio_value: current_value},
            optimistic: %{years_to_fi: 0, fi_portfolio_value: current_value}
          }
        }

        Logger.debug("Already financially independent with #{current_value}")
        {:ok, results}
      end
    else
      {:error, reason} ->
        Logger.warning("FI timeline calculation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private scenario calculation helpers

  defp calculate_all_scenarios(current_value, annual_contribution, years, scenarios) do
    Enum.reduce(scenarios, %{}, fn scenario, acc ->
      %{name: name, rate: rate} = scenario

      case project_portfolio_growth(current_value, annual_contribution, years, rate) do
        {:ok, portfolio_value} ->
          scenario_result = %{
            growth_rate: rate,
            portfolio_value: portfolio_value
          }

          Map.put(acc, name, scenario_result)

        {:error, _reason} ->
          # Skip invalid scenarios but continue processing others
          acc
      end
    end)
  end

  defp calculate_weighted_average_scenario(scenario_results) do
    # Standard weighting: 20% pessimistic, 60% realistic, 20% optimistic
    weights = %{
      pessimistic: Decimal.new("0.20"),
      realistic: Decimal.new("0.60"),
      optimistic: Decimal.new("0.20")
    }

    # Calculate weighted portfolio value
    weighted_value =
      weights
      |> Enum.reduce(Decimal.new("0"), fn {scenario_name, weight}, acc ->
        case Map.get(scenario_results, scenario_name) do
          nil ->
            acc

          scenario ->
            weighted_contribution = Decimal.mult(scenario.portfolio_value, weight)
            Decimal.add(acc, weighted_contribution)
        end
      end)
      |> Decimal.round(2)

    %{
      portfolio_value: weighted_value,
      weights: weights
    }
  end

  defp validate_custom_scenarios(scenarios) when is_list(scenarios) do
    cond do
      not Enum.all?(scenarios, &valid_custom_scenario?/1) ->
        {:error, :invalid_scenario}

      find_unrealistic_growth_rate_scenario(scenarios) ->
        {:error, :unrealistic_growth}

      true ->
        :ok
    end
  end

  defp validate_custom_scenarios(_), do: {:error, :invalid_scenario}

  defp find_unrealistic_growth_rate_scenario(scenarios) do
    Enum.find(scenarios, fn scenario ->
      case validate_growth_rate(scenario.rate) do
        {:error, :unrealistic_growth} -> true
        _ -> false
      end
    end)
  end

  defp valid_custom_scenario?(%{name: name, rate: %Decimal{}} = _scenario) when is_atom(name), do: true

  defp valid_custom_scenario?(_), do: false

  defp validate_annual_expenses(%Decimal{} = annual_expenses) do
    cond do
      Decimal.compare(annual_expenses, Decimal.new("0")) != :gt ->
        {:error, :invalid_input}

      Decimal.compare(annual_expenses, Decimal.new("1000000")) == :gt ->
        # > $1M annually is unrealistic
        {:error, :unrealistic_expenses}

      true ->
        :ok
    end
  end

  defp validate_annual_expenses(_), do: {:error, :invalid_input}

  defp calculate_years_to_target(current_value, annual_contribution, target_amount, growth_rate) do
    # Use iterative approach to find years needed to reach target
    # Start with reasonable bounds and binary search
    find_years_to_target(current_value, annual_contribution, target_amount, growth_rate, 0, 50)
  end

  defp find_years_to_target(current_value, annual_contribution, target_amount, growth_rate, min_years, max_years) do
    if max_years - min_years <= 1 do
      # Close enough, return the higher bound to ensure we meet target
      max_years
    else
      perform_binary_search_for_target_years(
        current_value,
        annual_contribution,
        target_amount,
        growth_rate,
        min_years,
        max_years
      )
    end
  end

  defp perform_binary_search_for_target_years(
         current_value,
         annual_contribution,
         target_amount,
         growth_rate,
         min_years,
         max_years
       ) do
    mid_years = div(min_years + max_years, 2)

    case project_portfolio_growth(current_value, annual_contribution, mid_years, growth_rate) do
      {:ok, projected_value} ->
        if Decimal.compare(projected_value, target_amount) == :lt do
          # Need more years
          find_years_to_target(
            current_value,
            annual_contribution,
            target_amount,
            growth_rate,
            mid_years,
            max_years
          )
        else
          # We've reached the target, try fewer years
          find_years_to_target(
            current_value,
            annual_contribution,
            target_amount,
            growth_rate,
            min_years,
            mid_years
          )
        end

      {:error, _reason} ->
        # Default to max years if calculation fails
        max_years
    end
  end

  defp calculate_fi_scenario_analysis(current_value, annual_contribution, fi_target_amount) do
    # Standard FI scenario rates
    fi_scenarios = [
      {:pessimistic, Decimal.new("0.05")},
      {:realistic, Decimal.new("0.07")},
      {:optimistic, Decimal.new("0.10")}
    ]

    Enum.reduce(fi_scenarios, %{}, fn {scenario_name, rate}, acc ->
      years_to_fi =
        calculate_years_to_target(current_value, annual_contribution, fi_target_amount, rate)

      case project_portfolio_growth(current_value, annual_contribution, years_to_fi, rate) do
        {:ok, fi_portfolio_value} ->
          scenario_result = %{
            years_to_fi: years_to_fi,
            fi_portfolio_value: fi_portfolio_value
          }

          Map.put(acc, scenario_name, scenario_result)

        {:error, _reason} ->
          # Skip failed scenarios
          acc
      end
    end)
  end

  @doc """
  Analyzes the impact of different contribution levels on portfolio growth.

  Shows how changing monthly contributions by various amounts affects
  the final portfolio value over a specified time period.

  ## Examples

      iex> ForecastCalculator.analyze_contribution_impact(Decimal.new("100000"), Decimal.new("1000"), 20, Decimal.new("0.07"))
      {:ok, %{base_projection: Decimal.new("..."), contribution_variations: [%{...}]}}

  ## Parameters

    - current_value: Decimal - Current portfolio value
    - base_monthly_contribution: Decimal - Base monthly contribution amount
    - years: integer - Number of years to project
    - growth_rate: Decimal - Annual growth rate

  ## Returns

    - {:ok, analysis_map} - Map with base projection and contribution variations
    - {:error, reason} - Error tuple with descriptive reason

  ## Return Structure

      %{
        base_projection: Decimal,
        contribution_variations: [
          %{monthly_change: Decimal, annual_change: Decimal, portfolio_value: Decimal, value_difference: Decimal},
          ...
        ]
      }
  """
  def analyze_contribution_impact(current_value, base_monthly_contribution, years, growth_rate) do
    Logger.debug(
      "Analyzing contribution impact - current: #{current_value}, base monthly: #{base_monthly_contribution}, years: #{years}, rate: #{growth_rate}"
    )

    # Convert monthly to annual for existing functions
    base_annual_contribution = Decimal.mult(base_monthly_contribution, Decimal.new("12"))

    with :ok <- validate_current_value(current_value),
         :ok <- validate_annual_contribution(base_annual_contribution),
         :ok <- validate_years(years),
         :ok <- validate_growth_rate(growth_rate) do
      # Calculate base projection
      case project_portfolio_growth(current_value, base_annual_contribution, years, growth_rate) do
        {:ok, base_projection} ->
          # Define contribution variations to analyze
          monthly_variations = [
            Decimal.new("-1000"),
            Decimal.new("-500"),
            Decimal.new("-100"),
            Decimal.new("100"),
            Decimal.new("500"),
            Decimal.new("1000")
          ]

          # Calculate impact of each variation
          contribution_variations =
            calculate_contribution_variations(
              current_value,
              base_monthly_contribution,
              base_projection,
              years,
              growth_rate,
              monthly_variations
            )

          results = %{
            base_projection: base_projection,
            contribution_variations: contribution_variations
          }

          Logger.debug("Contribution impact analysis completed with #{length(contribution_variations)} variations")

          {:ok, results}

        {:error, reason} ->
          Logger.warning("Base projection calculation failed: #{inspect(reason)}")
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.warning("Contribution impact analysis failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Optimizes monthly contribution amount to reach a target portfolio value.

  Calculates the required monthly contribution to reach a specific goal
  within a given timeframe, considering current portfolio value and growth rate.

  ## Examples

      iex> ForecastCalculator.optimize_contribution_for_goal(Decimal.new("100000"), Decimal.new("1250000"), 15, Decimal.new("0.07"))
      {:ok, %{required_monthly_contribution: Decimal.new("..."), probability_of_success: Decimal.new("...")}}

  ## Parameters

    - current_value: Decimal - Current portfolio value
    - target_value: Decimal - Target portfolio value to reach
    - target_years: integer - Number of years to reach the goal
    - growth_rate: Decimal - Expected annual growth rate

  ## Returns

    - {:ok, optimization_map} - Map with required contribution and analysis
    - {:error, reason} - Error tuple with descriptive reason

  ## Return Structure

      %{
        required_monthly_contribution: Decimal,
        required_annual_contribution: Decimal,
        probability_of_success: Decimal,
        scenario_analysis: %{
          pessimistic: %{required_monthly: Decimal, achievable: boolean},
          realistic: %{required_monthly: Decimal, achievable: boolean},
          optimistic: %{required_monthly: Decimal, achievable: boolean}
        }
      }
  """
  def optimize_contribution_for_goal(current_value, target_value, target_years, growth_rate) do
    Logger.debug(
      "Optimizing contribution for goal - current: #{current_value}, target: #{target_value}, years: #{target_years}, rate: #{growth_rate}"
    )

    with :ok <- validate_current_value(current_value),
         :ok <- validate_target_value(target_value),
         :ok <- validate_years(target_years),
         :ok <- validate_growth_rate(growth_rate) do
      # Check if already at target
      if Decimal.compare(current_value, target_value) == :lt do
        # Calculate required contribution for main scenario
        case calculate_required_contribution(
               current_value,
               target_value,
               target_years,
               growth_rate
             ) do
          {:ok, required_annual_contribution} ->
            required_monthly_contribution =
              required_annual_contribution
              |> Decimal.div(Decimal.new("12"))
              |> Decimal.round(2)

            # Calculate scenario analysis for different growth rates
            scenario_analysis =
              calculate_contribution_scenario_analysis(
                current_value,
                target_value,
                target_years
              )

            # Calculate probability of success based on scenario feasibility
            probability_of_success = calculate_success_probability(scenario_analysis)

            results = %{
              required_monthly_contribution: required_monthly_contribution,
              required_annual_contribution: required_annual_contribution,
              probability_of_success: probability_of_success,
              scenario_analysis: scenario_analysis
            }

            Logger.debug("Contribution optimization completed - required monthly: #{required_monthly_contribution}")

            {:ok, results}

          {:error, reason} ->
            Logger.warning("Required contribution calculation failed: #{inspect(reason)}")
            {:error, reason}
        end
      else
        # Already at or above target
        results = %{
          required_monthly_contribution: Decimal.new("0"),
          required_annual_contribution: Decimal.new("0"),
          probability_of_success: Decimal.new("100.00"),
          scenario_analysis: %{
            pessimistic: %{required_monthly: Decimal.new("0"), achievable: true},
            realistic: %{required_monthly: Decimal.new("0"), achievable: true},
            optimistic: %{required_monthly: Decimal.new("0"), achievable: true}
          }
        }

        Logger.debug("Already at target value: #{target_value}")
        {:ok, results}
      end
    else
      {:error, reason} ->
        Logger.warning("Contribution optimization failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private helper functions for contribution analysis

  defp calculate_contribution_variations(
         current_value,
         base_monthly_contribution,
         base_projection,
         years,
         growth_rate,
         monthly_variations
       ) do
    monthly_variations
    |> Enum.map(fn monthly_change ->
      # Calculate new monthly contribution (ensure non-negative)
      new_monthly_contribution =
        base_monthly_contribution
        |> Decimal.add(monthly_change)
        |> Decimal.max(Decimal.new("0"))

      new_annual_contribution = Decimal.mult(new_monthly_contribution, Decimal.new("12"))

      case project_portfolio_growth(current_value, new_annual_contribution, years, growth_rate) do
        {:ok, new_portfolio_value} ->
          value_difference = Decimal.sub(new_portfolio_value, base_projection)
          annual_change = Decimal.mult(monthly_change, Decimal.new("12"))

          %{
            monthly_change: monthly_change,
            annual_change: annual_change,
            portfolio_value: new_portfolio_value,
            value_difference: value_difference
          }

        {:error, _reason} ->
          # Skip failed calculations
          nil
      end
    end)
    # Remove nil values
    |> Enum.filter(& &1)
  end

  defp validate_target_value(%Decimal{} = target_value) do
    cond do
      Decimal.compare(target_value, Decimal.new("0")) != :gt ->
        {:error, :invalid_input}

      Decimal.compare(target_value, Decimal.new("50000000")) == :gt ->
        # > $50M is unrealistic for personal finance
        {:error, :unrealistic_target}

      true ->
        :ok
    end
  end

  defp validate_target_value(_), do: {:error, :invalid_input}

  defp calculate_required_contribution(current_value, target_value, target_years, growth_rate) do
    # We need to solve: target_value = FV_present + FV_annuity
    # Where FV_annuity = annual_contribution * [((1+r)^n - 1) / r]
    # Rearranging: annual_contribution = (target_value - FV_present) / annuity_factor

    case project_portfolio_growth(current_value, Decimal.new("0"), target_years, growth_rate) do
      {:ok, future_value_of_present} ->
        # Amount needed from contributions
        contribution_needed = Decimal.sub(target_value, future_value_of_present)

        if Decimal.compare(contribution_needed, Decimal.new("0")) == :gt do
          # Calculate annuity factor for the required annual contribution
          {:ok, annuity_factor} = calculate_annuity_factor(growth_rate, target_years)

          required_annual_contribution =
            contribution_needed
            |> Decimal.div(annuity_factor)
            |> Decimal.round(2)

          {:ok, required_annual_contribution}
        else
          # No additional contributions needed (growth alone reaches target)
          {:ok, Decimal.new("0")}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp calculate_annuity_factor(growth_rate, years) do
    if Decimal.equal?(growth_rate, Decimal.new("0")) do
      # No growth: annuity factor is just the number of years
      {:ok, Decimal.new(to_string(years))}
    else
      # Use AERCalculator to determine the annuity factor
      # Calculate what $1/month for N years would grow to, then derive factor
      unit_monthly_contribution = Decimal.new("1")

      future_value_of_unit_contributions =
        AERCalculator.compound_with_aer(
          # No initial principal 
          Decimal.new("0"),
          growth_rate,
          years,
          unit_monthly_contribution
        )

      # Annual annuity factor = FV of $1/month contributions * 12 (to convert to annual basis)
      # This gives us the factor to multiply annual contributions by
      annual_annuity_factor = Decimal.div(future_value_of_unit_contributions, Decimal.new("12"))

      {:ok, annual_annuity_factor}
    end
  end

  defp calculate_contribution_scenario_analysis(current_value, target_value, target_years) do
    # Analyze required contributions under different growth scenarios
    scenario_rates = [
      {:pessimistic, Decimal.new("0.05")},
      {:realistic, Decimal.new("0.07")},
      {:optimistic, Decimal.new("0.10")}
    ]

    Enum.reduce(scenario_rates, %{}, fn {scenario_name, rate}, acc ->
      case calculate_required_contribution(current_value, target_value, target_years, rate) do
        {:ok, required_annual} ->
          required_monthly =
            required_annual
            |> Decimal.div(Decimal.new("12"))
            |> Decimal.round(2)

          # Consider achievable if monthly contribution is reasonable (< $10k/month)
          achievable = Decimal.compare(required_monthly, Decimal.new("10000")) != :gt

          scenario_result = %{
            required_monthly: required_monthly,
            achievable: achievable
          }

          Map.put(acc, scenario_name, scenario_result)

        {:error, _reason} ->
          # Mark as not achievable if calculation fails
          scenario_result = %{
            required_monthly: Decimal.new("999999"),
            achievable: false
          }

          Map.put(acc, scenario_name, scenario_result)
      end
    end)
  end

  defp calculate_success_probability(scenario_analysis) do
    # Calculate probability based on scenario feasibility
    # 20% weight for pessimistic, 60% for realistic, 20% for optimistic
    weights = [
      {scenario_analysis[:pessimistic][:achievable], Decimal.new("20")},
      {scenario_analysis[:realistic][:achievable], Decimal.new("60")},
      {scenario_analysis[:optimistic][:achievable], Decimal.new("20")}
    ]

    probability =
      Enum.reduce(weights, Decimal.new("0"), fn {achievable, weight}, acc ->
        if achievable do
          Decimal.add(acc, weight)
        else
          acc
        end
      end)

    Decimal.round(probability, 2)
  end

  # Helper function for power calculations
  defp power(base, exponent) when is_integer(exponent) and exponent >= 0 do
    # Use float math for precision with large exponents
    base_float = Decimal.to_float(base)
    result_float = :math.pow(base_float, exponent)
    Decimal.from_float(result_float)
  end
end
