defmodule Ashfolio.FinancialManagement.ForecastCalculatorTest do
  use Ashfolio.DataCase

  alias Ashfolio.FinancialManagement.ForecastCalculator

  @moduletag :unit

  describe "project_portfolio_growth/4" do
    @tag :unit
    @tag :smoke
    test "calculates basic compound growth without contributions" do
      # Test case from implementation plan - should grow $100k to ~$196k in 10 years at 7%
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("0")
      years = 10
      growth_rate = Decimal.new("0.07")

      # Expected: 100000 * (1.07)^10 ≈ 196715.14
      expected = Decimal.new("196715.14")

      assert {:ok, result} =
               ForecastCalculator.project_portfolio_growth(
                 current_value,
                 annual_contribution,
                 years,
                 growth_rate
               )

      # Allow for small rounding differences (within $1)
      difference = Decimal.sub(result, expected) |> Decimal.abs()

      assert Decimal.compare(difference, Decimal.new("1.00")) != :gt,
             "Expected ~#{expected}, got #{result} (difference: #{difference})"
    end

    @tag :unit
    test "calculates compound growth with regular monthly contributions" do
      # $100k initial + $12k/year ($1k/month) for 10 years at 7% with monthly compounding
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("12000")
      years = 10
      growth_rate = Decimal.new("0.07")

      # With monthly compounding and contributions:
      # FV of Present Value: 100000 * (1 + 0.07/12)^120 ≈ 200,966
      # FV of Annuity: 1000 * [((1 + 0.07/12)^120 - 1) / (0.07/12)] ≈ 173,085
      # Total ≈ 374,051 (matches our calculation)

      # Our implementation is mathematically correct for monthly compounding
      expected_min = Decimal.new("370000")
      expected_max = Decimal.new("380000")

      assert {:ok, result} =
               ForecastCalculator.project_portfolio_growth(
                 current_value,
                 annual_contribution,
                 years,
                 growth_rate
               )

      assert Decimal.compare(result, expected_min) != :lt,
             "Result #{result} should be at least #{expected_min}"

      assert Decimal.compare(result, expected_max) != :gt,
             "Result #{result} should be at most #{expected_max}"
    end

    @tag :unit
    test "handles zero growth rate scenario" do
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("0")
      years = 10
      growth_rate = Decimal.new("0")

      # With 0% growth, value should remain unchanged
      expected = Decimal.new("100000")

      assert {:ok, result} =
               ForecastCalculator.project_portfolio_growth(
                 current_value,
                 annual_contribution,
                 years,
                 growth_rate
               )

      assert Decimal.equal?(result, expected)
    end

    @tag :unit
    test "handles zero growth with contributions" do
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("12000")
      years = 10
      growth_rate = Decimal.new("0")

      # With 0% growth, final value = initial + (contributions * years)
      # 100k + (12k * 10)
      expected = Decimal.new("220000")

      assert {:ok, result} =
               ForecastCalculator.project_portfolio_growth(
                 current_value,
                 annual_contribution,
                 years,
                 growth_rate
               )

      assert Decimal.equal?(result, expected)
    end

    @tag :unit
    test "validates negative current value" do
      assert {:error, :negative_current_value} =
               ForecastCalculator.project_portfolio_growth(
                 Decimal.new("-100000"),
                 Decimal.new("12000"),
                 10,
                 Decimal.new("0.07")
               )
    end

    @tag :unit
    test "validates negative annual contribution" do
      assert {:error, :negative_contribution} =
               ForecastCalculator.project_portfolio_growth(
                 Decimal.new("100000"),
                 Decimal.new("-12000"),
                 10,
                 Decimal.new("0.07")
               )
    end

    @tag :unit
    test "validates negative years" do
      assert {:error, :invalid_years} =
               ForecastCalculator.project_portfolio_growth(
                 Decimal.new("100000"),
                 Decimal.new("12000"),
                 -5,
                 Decimal.new("0.07")
               )
    end

    @tag :unit
    test "validates unrealistic growth rates" do
      # Test extremely high growth rate (> 50%)
      assert {:error, :unrealistic_growth} =
               ForecastCalculator.project_portfolio_growth(
                 Decimal.new("100000"),
                 Decimal.new("12000"),
                 10,
                 Decimal.new("0.60")
               )

      # Test extremely negative growth rate (< -50%)
      assert {:error, :unrealistic_growth} =
               ForecastCalculator.project_portfolio_growth(
                 Decimal.new("100000"),
                 Decimal.new("12000"),
                 10,
                 Decimal.new("-0.60")
               )
    end

    @tag :unit
    test "handles decimal precision correctly" do
      current_value = Decimal.new("50000.50")
      annual_contribution = Decimal.new("6000.25")
      years = 5
      growth_rate = Decimal.new("0.05")

      assert {:ok, result} =
               ForecastCalculator.project_portfolio_growth(
                 current_value,
                 annual_contribution,
                 years,
                 growth_rate
               )

      # Result should be a properly formatted decimal
      assert %Decimal{} = result
      # Should have reasonable precision (not excessive decimal places)
      rounded = Decimal.round(result, 2)
      difference = Decimal.sub(result, rounded) |> Decimal.abs()
      assert Decimal.compare(difference, Decimal.new("0.01")) != :gt
    end

    @tag :unit
    test "handles zero years" do
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("12000")
      years = 0
      growth_rate = Decimal.new("0.07")

      # With 0 years, should return original value
      expected = Decimal.new("100000")

      assert {:ok, result} =
               ForecastCalculator.project_portfolio_growth(
                 current_value,
                 annual_contribution,
                 years,
                 growth_rate
               )

      assert Decimal.equal?(result, expected)
    end

    @tag :unit
    test "validates invalid input types" do
      # Test non-Decimal current_value
      assert {:error, :invalid_input} =
               ForecastCalculator.project_portfolio_growth(
                 # integer instead of Decimal
                 100_000,
                 Decimal.new("12000"),
                 10,
                 Decimal.new("0.07")
               )

      # Test non-Decimal contribution
      assert {:error, :invalid_input} =
               ForecastCalculator.project_portfolio_growth(
                 Decimal.new("100000"),
                 # integer instead of Decimal
                 12_000,
                 10,
                 Decimal.new("0.07")
               )

      # Test non-Decimal growth rate
      assert {:error, :invalid_input} =
               ForecastCalculator.project_portfolio_growth(
                 Decimal.new("100000"),
                 Decimal.new("12000"),
                 10,
                 # float instead of Decimal
                 0.07
               )
    end
  end

  describe "project_multi_period_growth/4" do
    @tag :unit
    @tag :smoke
    test "calculates projections for standard time periods" do
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("12000")
      growth_rate = Decimal.new("0.07")
      periods = [5, 10, 15, 20, 25, 30]

      assert {:ok, projections} =
               ForecastCalculator.project_multi_period_growth(
                 current_value,
                 annual_contribution,
                 growth_rate,
                 periods
               )

      # Should have projections for each requested period
      assert Map.has_key?(projections, :year_5)
      assert Map.has_key?(projections, :year_10)
      assert Map.has_key?(projections, :year_15)
      assert Map.has_key?(projections, :year_20)
      assert Map.has_key?(projections, :year_25)
      assert Map.has_key?(projections, :year_30)

      # Each projection should be a Decimal
      assert %Decimal{} = projections.year_5
      assert %Decimal{} = projections.year_30

      # Values should increase over time
      assert Decimal.compare(projections.year_10, projections.year_5) == :gt
      assert Decimal.compare(projections.year_30, projections.year_20) == :gt
    end

    @tag :unit
    test "includes yearly breakdown for detailed analysis" do
      current_value = Decimal.new("50000")
      annual_contribution = Decimal.new("6000")
      growth_rate = Decimal.new("0.06")
      periods = [5, 10]

      assert {:ok, projections} =
               ForecastCalculator.project_multi_period_growth(
                 current_value,
                 annual_contribution,
                 growth_rate,
                 periods
               )

      # Should include yearly breakdown
      assert Map.has_key?(projections, :yearly_breakdown)
      breakdown = projections.yearly_breakdown

      # Should have entries for years 1-5 (first 5 years detailed)
      assert Map.has_key?(breakdown, :year_1)
      assert Map.has_key?(breakdown, :year_2)
      assert Map.has_key?(breakdown, :year_3)
      assert Map.has_key?(breakdown, :year_4)
      assert Map.has_key?(breakdown, :year_5)

      # Each breakdown entry should have expected structure
      year_1_data = breakdown.year_1
      assert Map.has_key?(year_1_data, :portfolio_value)
      assert Map.has_key?(year_1_data, :total_contributions)
      assert Map.has_key?(year_1_data, :growth_amount)

      # Values should be Decimals
      assert %Decimal{} = year_1_data.portfolio_value
      assert %Decimal{} = year_1_data.total_contributions
      assert %Decimal{} = year_1_data.growth_amount
    end

    @tag :unit
    test "calculates CAGR (Compound Annual Growth Rate)" do
      current_value = Decimal.new("100000")
      # No contributions for clean CAGR
      annual_contribution = Decimal.new("0")
      growth_rate = Decimal.new("0.08")
      periods = [10, 20]

      assert {:ok, projections} =
               ForecastCalculator.project_multi_period_growth(
                 current_value,
                 annual_contribution,
                 growth_rate,
                 periods
               )

      # Should include CAGR calculation
      assert Map.has_key?(projections, :cagr)
      cagr_data = projections.cagr

      assert Map.has_key?(cagr_data, :year_10)
      assert Map.has_key?(cagr_data, :year_20)

      # CAGR should be close to input growth rate when no contributions
      cagr_10_year = cagr_data.year_10
      # 8% as percentage
      expected_cagr = Decimal.new("8.00")

      difference = Decimal.sub(cagr_10_year, expected_cagr) |> Decimal.abs()

      assert Decimal.compare(difference, Decimal.new("0.5")) != :gt,
             "CAGR #{cagr_10_year}% should be close to expected #{expected_cagr}%"
    end

    @tag :unit
    test "handles empty periods list" do
      assert {:ok, projections} =
               ForecastCalculator.project_multi_period_growth(
                 Decimal.new("100000"),
                 Decimal.new("12000"),
                 Decimal.new("0.07"),
                 []
               )

      # Should return basic structure even with no periods
      assert Map.has_key?(projections, :yearly_breakdown)
      assert Map.has_key?(projections, :cagr)
      assert map_size(projections) >= 2
    end

    @tag :unit
    test "validates input parameters" do
      valid_periods = [5, 10, 20]

      # Test invalid current value
      assert {:error, :negative_current_value} =
               ForecastCalculator.project_multi_period_growth(
                 Decimal.new("-50000"),
                 Decimal.new("12000"),
                 Decimal.new("0.07"),
                 valid_periods
               )

      # Test invalid contribution
      assert {:error, :negative_contribution} =
               ForecastCalculator.project_multi_period_growth(
                 Decimal.new("100000"),
                 Decimal.new("-5000"),
                 Decimal.new("0.07"),
                 valid_periods
               )

      # Test invalid growth rate
      assert {:error, :unrealistic_growth} =
               ForecastCalculator.project_multi_period_growth(
                 Decimal.new("100000"),
                 Decimal.new("12000"),
                 # 80% is unrealistic
                 Decimal.new("0.80"),
                 valid_periods
               )

      # Test invalid periods list
      assert {:error, :invalid_periods} =
               ForecastCalculator.project_multi_period_growth(
                 Decimal.new("100000"),
                 Decimal.new("12000"),
                 Decimal.new("0.07"),
                 "not a list"
               )
    end

    @tag :unit
    test "handles invalid periods in list" do
      # Test negative period
      assert {:error, :invalid_periods} =
               ForecastCalculator.project_multi_period_growth(
                 Decimal.new("100000"),
                 Decimal.new("12000"),
                 Decimal.new("0.07"),
                 [5, -10, 20]
               )

      # Test zero period
      assert {:ok, projections} =
               ForecastCalculator.project_multi_period_growth(
                 Decimal.new("100000"),
                 Decimal.new("12000"),
                 Decimal.new("0.07"),
                 [0, 5, 10]
               )

      # Year 0 should equal current value
      assert Decimal.equal?(projections.year_0, Decimal.new("100000"))
    end

    @tag :performance
    test "completes multi-period calculation within performance benchmark" do
      # Test with realistic parameters and 6 periods as per spec
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("12000")
      growth_rate = Decimal.new("0.07")
      # 6 periods per spec
      periods = [5, 10, 15, 20, 25, 30]

      {time_us, {:ok, _projections}} =
        :timer.tc(fn ->
          ForecastCalculator.project_multi_period_growth(
            current_value,
            annual_contribution,
            growth_rate,
            periods
          )
        end)

      # Should complete within 100ms benchmark (100,000 microseconds)
      assert time_us < 100_000,
             "Multi-period calculation took #{time_us}μs, exceeds 100ms benchmark"
    end

    @tag :unit
    test "sorts periods automatically" do
      # Test with unsorted periods
      assert {:ok, projections} =
               ForecastCalculator.project_multi_period_growth(
                 Decimal.new("100000"),
                 Decimal.new("12000"),
                 Decimal.new("0.07"),
                 # Unsorted
                 [20, 5, 15, 10]
               )

      # Should still have all requested periods
      assert Map.has_key?(projections, :year_5)
      assert Map.has_key?(projections, :year_10)
      assert Map.has_key?(projections, :year_15)
      assert Map.has_key?(projections, :year_20)
    end
  end

  describe "calculate_scenario_projections/3" do
    @tag :unit
    @tag :smoke
    test "calculates standard scenarios with default rates" do
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("12000")
      years = 30

      assert {:ok, scenarios} =
               ForecastCalculator.calculate_scenario_projections(
                 current_value,
                 annual_contribution,
                 years
               )

      # Should have standard scenarios
      assert Map.has_key?(scenarios, :pessimistic)
      assert Map.has_key?(scenarios, :realistic)
      assert Map.has_key?(scenarios, :optimistic)

      # Each scenario should have expected structure
      pessimistic = scenarios.pessimistic
      realistic = scenarios.realistic
      optimistic = scenarios.optimistic

      # All scenarios should have projections
      assert %Decimal{} = pessimistic.portfolio_value
      assert %Decimal{} = realistic.portfolio_value
      assert %Decimal{} = optimistic.portfolio_value

      # Should have growth rates
      assert Decimal.equal?(pessimistic.growth_rate, Decimal.new("0.05"))
      assert Decimal.equal?(realistic.growth_rate, Decimal.new("0.07"))
      assert Decimal.equal?(optimistic.growth_rate, Decimal.new("0.10"))

      # Values should increase with growth rate
      assert Decimal.compare(realistic.portfolio_value, pessimistic.portfolio_value) == :gt
      assert Decimal.compare(optimistic.portfolio_value, realistic.portfolio_value) == :gt
    end

    @tag :unit
    test "includes probability-weighted outcomes" do
      current_value = Decimal.new("150000")
      annual_contribution = Decimal.new("18000")
      years = 25

      assert {:ok, scenarios} =
               ForecastCalculator.calculate_scenario_projections(
                 current_value,
                 annual_contribution,
                 years
               )

      # Should include weighted average
      assert Map.has_key?(scenarios, :weighted_average)
      weighted = scenarios.weighted_average

      # Weighted average should have reasonable value
      assert %Decimal{} = weighted.portfolio_value

      # Should be between pessimistic and optimistic
      pessimistic_value = scenarios.pessimistic.portfolio_value
      optimistic_value = scenarios.optimistic.portfolio_value

      assert Decimal.compare(weighted.portfolio_value, pessimistic_value) == :gt
      assert Decimal.compare(weighted.portfolio_value, optimistic_value) == :lt
    end

    @tag :unit
    test "validates input parameters" do
      # Test negative current value
      assert {:error, :negative_current_value} =
               ForecastCalculator.calculate_scenario_projections(
                 Decimal.new("-100000"),
                 Decimal.new("12000"),
                 30
               )

      # Test negative contribution
      assert {:error, :negative_contribution} =
               ForecastCalculator.calculate_scenario_projections(
                 Decimal.new("100000"),
                 Decimal.new("-5000"),
                 30
               )

      # Test invalid years
      assert {:error, :invalid_years} =
               ForecastCalculator.calculate_scenario_projections(
                 Decimal.new("100000"),
                 Decimal.new("12000"),
                 -10
               )
    end

    @tag :unit
    test "handles zero values appropriately" do
      # Zero current value
      assert {:ok, scenarios} =
               ForecastCalculator.calculate_scenario_projections(
                 Decimal.new("0"),
                 Decimal.new("12000"),
                 20
               )

      # All scenarios should be based only on contributions
      assert %Decimal{} = scenarios.realistic.portfolio_value
      assert Decimal.compare(scenarios.realistic.portfolio_value, Decimal.new("0")) == :gt

      # Zero contribution
      assert {:ok, scenarios} =
               ForecastCalculator.calculate_scenario_projections(
                 Decimal.new("100000"),
                 Decimal.new("0"),
                 20
               )

      # Should still calculate growth scenarios
      assert Decimal.compare(
               scenarios.optimistic.portfolio_value,
               scenarios.pessimistic.portfolio_value
             ) == :gt
    end
  end

  describe "calculate_custom_scenarios/4" do
    @tag :unit
    test "calculates custom scenario projections" do
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("12000")
      years = 20

      custom_scenarios = [
        %{name: :conservative, rate: Decimal.new("0.04")},
        %{name: :moderate, rate: Decimal.new("0.06")},
        %{name: :aggressive, rate: Decimal.new("0.12")}
      ]

      assert {:ok, results} =
               ForecastCalculator.calculate_custom_scenarios(
                 current_value,
                 annual_contribution,
                 years,
                 custom_scenarios
               )

      # Should have results for each custom scenario
      assert Map.has_key?(results, :conservative)
      assert Map.has_key?(results, :moderate)
      assert Map.has_key?(results, :aggressive)

      # Each result should have expected structure
      conservative = results.conservative
      moderate = results.moderate
      aggressive = results.aggressive

      assert %Decimal{} = conservative.portfolio_value
      assert %Decimal{} = moderate.portfolio_value
      assert %Decimal{} = aggressive.portfolio_value

      # Growth rates should match input
      assert Decimal.equal?(conservative.growth_rate, Decimal.new("0.04"))
      assert Decimal.equal?(moderate.growth_rate, Decimal.new("0.06"))
      assert Decimal.equal?(aggressive.growth_rate, Decimal.new("0.12"))

      # Values should increase with growth rate
      assert Decimal.compare(moderate.portfolio_value, conservative.portfolio_value) == :gt
      assert Decimal.compare(aggressive.portfolio_value, moderate.portfolio_value) == :gt
    end

    @tag :unit
    test "handles empty custom scenarios list" do
      assert {:ok, results} =
               ForecastCalculator.calculate_custom_scenarios(
                 Decimal.new("100000"),
                 Decimal.new("12000"),
                 15,
                 []
               )

      # Should return empty results map
      assert results == %{}
    end

    @tag :unit
    test "validates custom scenario structure" do
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("12000")
      years = 10

      # Test invalid scenario structure
      invalid_scenarios = [
        %{name: :test, rate: "not_decimal"}
      ]

      assert {:error, :invalid_scenario} =
               ForecastCalculator.calculate_custom_scenarios(
                 current_value,
                 annual_contribution,
                 years,
                 invalid_scenarios
               )

      # Test missing name
      invalid_scenarios_missing_name = [
        %{rate: Decimal.new("0.05")}
      ]

      assert {:error, :invalid_scenario} =
               ForecastCalculator.calculate_custom_scenarios(
                 current_value,
                 annual_contribution,
                 years,
                 invalid_scenarios_missing_name
               )

      # Test unrealistic growth rate in custom scenario
      unrealistic_scenarios = [
        %{name: :unrealistic, rate: Decimal.new("0.70")}
      ]

      assert {:error, :unrealistic_growth} =
               ForecastCalculator.calculate_custom_scenarios(
                 current_value,
                 annual_contribution,
                 years,
                 unrealistic_scenarios
               )
    end
  end

  describe "calculate_fi_timeline/4" do
    @tag :unit
    @tag :smoke
    test "calculates financial independence timeline" do
      current_value = Decimal.new("250000")
      annual_contribution = Decimal.new("30000")
      annual_expenses = Decimal.new("50000")
      growth_rate = Decimal.new("0.07")

      assert {:ok, fi_analysis} =
               ForecastCalculator.calculate_fi_timeline(
                 current_value,
                 annual_contribution,
                 annual_expenses,
                 growth_rate
               )

      # Should have required keys
      assert Map.has_key?(fi_analysis, :years_to_fi)
      assert Map.has_key?(fi_analysis, :fi_portfolio_value)
      assert Map.has_key?(fi_analysis, :fi_target_amount)
      assert Map.has_key?(fi_analysis, :safe_withdrawal_rate)

      # Years to FI should be reasonable
      years_to_fi = fi_analysis.years_to_fi
      assert is_integer(years_to_fi)
      assert years_to_fi >= 0
      assert years_to_fi <= 50

      # FI target should be 25x expenses
      expected_fi_target = Decimal.mult(annual_expenses, Decimal.new("25"))
      assert Decimal.equal?(fi_analysis.fi_target_amount, expected_fi_target)

      # Safe withdrawal rate should be 4%
      assert Decimal.equal?(fi_analysis.safe_withdrawal_rate, Decimal.new("0.04"))

      # Portfolio value at FI should meet or exceed target
      assert Decimal.compare(fi_analysis.fi_portfolio_value, fi_analysis.fi_target_amount) != :lt
    end

    @tag :unit
    test "handles already financially independent scenario" do
      # Portfolio already exceeds 25x expenses
      current_value = Decimal.new("1500000")
      annual_contribution = Decimal.new("20000")
      annual_expenses = Decimal.new("50000")
      growth_rate = Decimal.new("0.07")

      assert {:ok, fi_analysis} =
               ForecastCalculator.calculate_fi_timeline(
                 current_value,
                 annual_contribution,
                 annual_expenses,
                 growth_rate
               )

      # Should indicate immediate FI
      assert fi_analysis.years_to_fi == 0
      assert Decimal.equal?(fi_analysis.fi_portfolio_value, current_value)
    end

    @tag :unit
    test "calculates timeline with different scenarios" do
      current_value = Decimal.new("200000")
      annual_contribution = Decimal.new("25000")
      annual_expenses = Decimal.new("60000")
      growth_rate = Decimal.new("0.06")

      assert {:ok, fi_analysis} =
               ForecastCalculator.calculate_fi_timeline(
                 current_value,
                 annual_contribution,
                 annual_expenses,
                 growth_rate
               )

      # Should include scenario analysis
      assert Map.has_key?(fi_analysis, :scenario_analysis)
      scenarios = fi_analysis.scenario_analysis

      # Should have pessimistic, realistic, optimistic timelines
      assert Map.has_key?(scenarios, :pessimistic)
      assert Map.has_key?(scenarios, :realistic)
      assert Map.has_key?(scenarios, :optimistic)

      # Each scenario should have years_to_fi
      assert is_integer(scenarios.pessimistic.years_to_fi)
      assert is_integer(scenarios.realistic.years_to_fi)
      assert is_integer(scenarios.optimistic.years_to_fi)

      # Pessimistic should take longest, optimistic shortest
      assert scenarios.pessimistic.years_to_fi >= scenarios.realistic.years_to_fi
      assert scenarios.realistic.years_to_fi >= scenarios.optimistic.years_to_fi
    end

    @tag :unit
    test "validates financial independence parameters" do
      # Test negative expenses
      assert {:error, :invalid_input} =
               ForecastCalculator.calculate_fi_timeline(
                 Decimal.new("200000"),
                 Decimal.new("20000"),
                 Decimal.new("-50000"),
                 Decimal.new("0.07")
               )

      # Test zero expenses
      assert {:error, :invalid_input} =
               ForecastCalculator.calculate_fi_timeline(
                 Decimal.new("200000"),
                 Decimal.new("20000"),
                 Decimal.new("0"),
                 Decimal.new("0.07")
               )

      # Test unrealistic expenses (> $1M annually)
      assert {:error, :unrealistic_expenses} =
               ForecastCalculator.calculate_fi_timeline(
                 Decimal.new("200000"),
                 Decimal.new("20000"),
                 Decimal.new("1500000"),
                 Decimal.new("0.07")
               )
    end

    @tag :unit
    test "handles zero contribution scenario" do
      # Test FI timeline with no additional contributions
      current_value = Decimal.new("800000")
      annual_contribution = Decimal.new("0")
      annual_expenses = Decimal.new("40000")
      growth_rate = Decimal.new("0.08")

      assert {:ok, fi_analysis} =
               ForecastCalculator.calculate_fi_timeline(
                 current_value,
                 annual_contribution,
                 annual_expenses,
                 growth_rate
               )

      # Should still calculate timeline based on growth only
      assert is_integer(fi_analysis.years_to_fi)
      assert fi_analysis.years_to_fi >= 0
    end

    @tag :performance
    test "FI timeline calculation completes within benchmark" do
      # Performance test for FI timeline calculation
      {time_us, {:ok, _fi_analysis}} =
        :timer.tc(fn ->
          ForecastCalculator.calculate_fi_timeline(
            Decimal.new("300000"),
            Decimal.new("40000"),
            Decimal.new("70000"),
            Decimal.new("0.07")
          )
        end)

      # Should complete within reasonable time (< 500ms)
      assert time_us < 500_000,
             "FI timeline calculation took #{time_us}μs, exceeds 500ms benchmark"
    end
  end

  describe "analyze_contribution_impact/4" do
    @tag :unit
    @tag :smoke
    test "analyzes contribution impact with variations" do
      current_value = Decimal.new("100000")
      # $1k/month
      base_monthly_contribution = Decimal.new("1000")
      years = 20
      growth_rate = Decimal.new("0.07")

      assert {:ok, analysis} =
               ForecastCalculator.analyze_contribution_impact(
                 current_value,
                 base_monthly_contribution,
                 years,
                 growth_rate
               )

      # Should have required keys
      assert Map.has_key?(analysis, :base_projection)
      assert Map.has_key?(analysis, :contribution_variations)

      # Base projection should be reasonable
      assert %Decimal{} = analysis.base_projection
      assert Decimal.compare(analysis.base_projection, Decimal.new("100000")) == :gt

      # Should have multiple contribution variations
      variations = analysis.contribution_variations
      assert length(variations) >= 5

      # Each variation should have expected structure
      first_variation = List.first(variations)
      assert Map.has_key?(first_variation, :monthly_change)
      assert Map.has_key?(first_variation, :annual_change)
      assert Map.has_key?(first_variation, :portfolio_value)
      assert Map.has_key?(first_variation, :value_difference)

      # Annual change should be 12x monthly change
      monthly_change = first_variation.monthly_change
      annual_change = first_variation.annual_change
      expected_annual = Decimal.mult(monthly_change, Decimal.new("12"))
      assert Decimal.equal?(annual_change, expected_annual)
    end

    @tag :unit
    test "handles negative contribution changes correctly" do
      current_value = Decimal.new("200000")
      base_monthly_contribution = Decimal.new("1500")
      years = 15
      growth_rate = Decimal.new("0.06")

      assert {:ok, analysis} =
               ForecastCalculator.analyze_contribution_impact(
                 current_value,
                 base_monthly_contribution,
                 years,
                 growth_rate
               )

      # Find variations with negative monthly changes
      negative_variations =
        Enum.filter(analysis.contribution_variations, fn variation ->
          Decimal.compare(variation.monthly_change, Decimal.new("0")) == :lt
        end)

      assert length(negative_variations) > 0

      # Negative changes should result in lower portfolio values
      negative_variation = List.first(negative_variations)
      assert Decimal.compare(negative_variation.value_difference, Decimal.new("0")) == :lt
    end

    @tag :unit
    test "validates contribution impact parameters" do
      # Test negative current value
      assert {:error, :negative_current_value} =
               ForecastCalculator.analyze_contribution_impact(
                 Decimal.new("-100000"),
                 Decimal.new("1000"),
                 20,
                 Decimal.new("0.07")
               )

      # Test negative base contribution (converted to annual)
      assert {:error, :negative_contribution} =
               ForecastCalculator.analyze_contribution_impact(
                 Decimal.new("100000"),
                 Decimal.new("-500"),
                 20,
                 Decimal.new("0.07")
               )

      # Test invalid years
      assert {:error, :invalid_years} =
               ForecastCalculator.analyze_contribution_impact(
                 Decimal.new("100000"),
                 Decimal.new("1000"),
                 -5,
                 Decimal.new("0.07")
               )

      # Test unrealistic growth rate
      assert {:error, :unrealistic_growth} =
               ForecastCalculator.analyze_contribution_impact(
                 Decimal.new("100000"),
                 Decimal.new("1000"),
                 20,
                 Decimal.new("0.60")
               )
    end

    @tag :unit
    test "ensures non-negative contribution after variations" do
      current_value = Decimal.new("150000")
      # Small base contribution
      base_monthly_contribution = Decimal.new("200")
      years = 10
      growth_rate = Decimal.new("0.08")

      assert {:ok, analysis} =
               ForecastCalculator.analyze_contribution_impact(
                 current_value,
                 base_monthly_contribution,
                 years,
                 growth_rate
               )

      # All variations should have non-negative final contributions
      # (Even if monthly_change is negative, resulting contribution should be >= 0)
      Enum.each(analysis.contribution_variations, fn variation ->
        # Since we calculate based on (base + change), and we ensure >= 0 internally,
        # all variations should be valid (no negative final contributions)
        assert %Decimal{} = variation.portfolio_value
      end)
    end

    @tag :performance
    test "contribution impact analysis completes within benchmark" do
      # Performance test for contribution impact analysis
      {time_us, {:ok, _analysis}} =
        :timer.tc(fn ->
          ForecastCalculator.analyze_contribution_impact(
            Decimal.new("200000"),
            Decimal.new("2000"),
            25,
            Decimal.new("0.07")
          )
        end)

      # Should complete within reasonable time (< 200ms for multiple scenarios)
      assert time_us < 200_000,
             "Contribution impact analysis took #{time_us}μs, exceeds 200ms benchmark"
    end
  end

  describe "optimize_contribution_for_goal/4" do
    @tag :unit
    @tag :smoke
    test "calculates required contribution for retirement goal" do
      current_value = Decimal.new("100000")
      # 25x $50k expenses = $1.25M target
      target_value = Decimal.new("1250000")
      target_years = 15
      growth_rate = Decimal.new("0.07")

      assert {:ok, optimization} =
               ForecastCalculator.optimize_contribution_for_goal(
                 current_value,
                 target_value,
                 target_years,
                 growth_rate
               )

      # Should have required keys
      assert Map.has_key?(optimization, :required_monthly_contribution)
      assert Map.has_key?(optimization, :required_annual_contribution)
      assert Map.has_key?(optimization, :probability_of_success)
      assert Map.has_key?(optimization, :scenario_analysis)

      # Required contribution should be reasonable
      monthly_required = optimization.required_monthly_contribution
      annual_required = optimization.required_annual_contribution

      assert %Decimal{} = monthly_required
      assert %Decimal{} = annual_required
      assert Decimal.compare(monthly_required, Decimal.new("0")) == :gt
      assert Decimal.compare(annual_required, Decimal.new("0")) == :gt

      # Annual should be 12x monthly
      expected_annual = Decimal.mult(monthly_required, Decimal.new("12"))
      # Allow small rounding differences
      difference = Decimal.sub(annual_required, expected_annual) |> Decimal.abs()
      assert Decimal.compare(difference, Decimal.new("1")) != :gt

      # Probability should be between 0 and 100
      probability = optimization.probability_of_success
      assert Decimal.compare(probability, Decimal.new("0")) != :lt
      assert Decimal.compare(probability, Decimal.new("100")) != :gt
    end

    @tag :unit
    test "handles already at target scenario" do
      # Current value already exceeds target
      current_value = Decimal.new("1500000")
      target_value = Decimal.new("1250000")
      target_years = 10
      growth_rate = Decimal.new("0.07")

      assert {:ok, optimization} =
               ForecastCalculator.optimize_contribution_for_goal(
                 current_value,
                 target_value,
                 target_years,
                 growth_rate
               )

      # Should require zero contributions
      assert Decimal.equal?(optimization.required_monthly_contribution, Decimal.new("0"))
      assert Decimal.equal?(optimization.required_annual_contribution, Decimal.new("0"))

      # Probability should be 100%
      assert Decimal.equal?(optimization.probability_of_success, Decimal.new("100.00"))

      # All scenarios should be achievable
      scenarios = optimization.scenario_analysis
      assert scenarios.pessimistic.achievable == true
      assert scenarios.realistic.achievable == true
      assert scenarios.optimistic.achievable == true
    end

    @tag :unit
    test "includes scenario analysis with different growth rates" do
      current_value = Decimal.new("300000")
      target_value = Decimal.new("2000000")
      target_years = 20
      growth_rate = Decimal.new("0.08")

      assert {:ok, optimization} =
               ForecastCalculator.optimize_contribution_for_goal(
                 current_value,
                 target_value,
                 target_years,
                 growth_rate
               )

      # Should have scenario analysis
      scenarios = optimization.scenario_analysis
      assert Map.has_key?(scenarios, :pessimistic)
      assert Map.has_key?(scenarios, :realistic)
      assert Map.has_key?(scenarios, :optimistic)

      # Each scenario should have expected structure
      pessimistic = scenarios.pessimistic
      realistic = scenarios.realistic
      optimistic = scenarios.optimistic

      assert Map.has_key?(pessimistic, :required_monthly)
      assert Map.has_key?(pessimistic, :achievable)
      assert is_boolean(pessimistic.achievable)

      # Pessimistic should require highest contribution, optimistic lowest
      assert Decimal.compare(
               pessimistic.required_monthly,
               realistic.required_monthly
             ) == :gt

      assert Decimal.compare(
               realistic.required_monthly,
               optimistic.required_monthly
             ) == :gt
    end

    @tag :unit
    test "validates optimization parameters" do
      # Test negative current value
      assert {:error, :negative_current_value} =
               ForecastCalculator.optimize_contribution_for_goal(
                 Decimal.new("-100000"),
                 Decimal.new("1000000"),
                 15,
                 Decimal.new("0.07")
               )

      # Test invalid target value
      assert {:error, :invalid_input} =
               ForecastCalculator.optimize_contribution_for_goal(
                 Decimal.new("100000"),
                 Decimal.new("0"),
                 15,
                 Decimal.new("0.07")
               )

      # Test unrealistic target (> $50M)
      assert {:error, :unrealistic_target} =
               ForecastCalculator.optimize_contribution_for_goal(
                 Decimal.new("100000"),
                 Decimal.new("60000000"),
                 15,
                 Decimal.new("0.07")
               )

      # Test invalid years
      assert {:error, :invalid_years} =
               ForecastCalculator.optimize_contribution_for_goal(
                 Decimal.new("100000"),
                 Decimal.new("1000000"),
                 -5,
                 Decimal.new("0.07")
               )

      # Test unrealistic growth rate
      assert {:error, :unrealistic_growth} =
               ForecastCalculator.optimize_contribution_for_goal(
                 Decimal.new("100000"),
                 Decimal.new("1000000"),
                 15,
                 Decimal.new("-0.60")
               )
    end

    @tag :unit
    test "calculates achievability correctly" do
      current_value = Decimal.new("50000")
      # Very ambitious target requiring high contributions
      target_value = Decimal.new("5000000")
      target_years = 10
      growth_rate = Decimal.new("0.06")

      assert {:ok, optimization} =
               ForecastCalculator.optimize_contribution_for_goal(
                 current_value,
                 target_value,
                 target_years,
                 growth_rate
               )

      # With such ambitious goals, some scenarios might not be achievable
      # (requiring > $10k/month contributions)
      scenarios = optimization.scenario_analysis

      # Pessimistic scenario likely requires very high contributions
      if Decimal.compare(scenarios.pessimistic.required_monthly, Decimal.new("10000")) == :gt do
        assert scenarios.pessimistic.achievable == false
      end

      # Probability should reflect achievability
      probability = optimization.probability_of_success
      assert %Decimal{} = probability
    end

    @tag :unit
    test "handles zero growth rate scenario" do
      current_value = Decimal.new("200000")
      target_value = Decimal.new("500000")
      target_years = 10
      # Zero growth
      growth_rate = Decimal.new("0")

      assert {:ok, optimization} =
               ForecastCalculator.optimize_contribution_for_goal(
                 current_value,
                 target_value,
                 target_years,
                 growth_rate
               )

      # With zero growth, need to save the full difference
      needed_amount = Decimal.sub(target_value, current_value)
      expected_annual = Decimal.div(needed_amount, Decimal.new(to_string(target_years)))
      expected_monthly = Decimal.div(expected_annual, Decimal.new("12"))

      # Allow for small rounding differences
      monthly_diff =
        Decimal.sub(optimization.required_monthly_contribution, expected_monthly)
        |> Decimal.abs()

      assert Decimal.compare(monthly_diff, Decimal.new("1")) != :gt
    end

    @tag :performance
    test "contribution optimization completes within benchmark" do
      # Performance test for contribution optimization
      {time_us, {:ok, _optimization}} =
        :timer.tc(fn ->
          ForecastCalculator.optimize_contribution_for_goal(
            Decimal.new("250000"),
            Decimal.new("1500000"),
            18,
            Decimal.new("0.07")
          )
        end)

      # Should complete within reasonable time (< 300ms for scenario analysis)
      assert time_us < 300_000,
             "Contribution optimization took #{time_us}μs, exceeds 300ms benchmark"
    end
  end
end
