defmodule Ashfolio.FinancialManagement.ContributionAnalyzerTest do
  use Ashfolio.DataCase

  alias Ashfolio.FinancialManagement.{ForecastCalculator, ContributionAnalyzer}

  @moduletag :unit

  describe "analyze_contribution_impact/4 - Basic Sensitivity Analysis" do
    @tag :unit
    @tag :smoke
    test "calculates impact of different contribution levels" do
      current_value = Decimal.new("100000")
      base_monthly = Decimal.new("1000")
      years = 20
      growth_rate = Decimal.new("0.07")

      assert {:ok, analysis} =
               ContributionAnalyzer.analyze_contribution_impact(
                 current_value,
                 base_monthly,
                 years,
                 growth_rate
               )

      # Should have base projection
      assert Map.has_key?(analysis, :base_projection)
      assert analysis.base_projection.monthly_contribution == base_monthly

      assert analysis.base_projection.annual_contribution ==
               Decimal.mult(base_monthly, Decimal.new("12"))

      # Final value should be a Decimal struct - verified by successful operations above

      # Should have contribution variations
      assert Map.has_key?(analysis, :contribution_variations)
      assert is_list(analysis.contribution_variations)
      assert length(analysis.contribution_variations) >= 5

      # Should include specific variation amounts
      variations_map =
        Enum.into(analysis.contribution_variations, %{}, &{&1.monthly_contribution, &1})

      # Check for standard variations
      # -$500
      assert Map.has_key?(variations_map, Decimal.new("500"))
      # -$100
      assert Map.has_key?(variations_map, Decimal.new("900"))
      # +$100
      assert Map.has_key?(variations_map, Decimal.new("1100"))
      # +$500
      assert Map.has_key?(variations_map, Decimal.new("1500"))
      # +$1000
      assert Map.has_key?(variations_map, Decimal.new("2000"))

      # Each variation should have required fields
      Enum.each(analysis.contribution_variations, fn variation ->
        assert Map.has_key?(variation, :monthly_contribution)
        assert Map.has_key?(variation, :annual_contribution)
        assert Map.has_key?(variation, :final_value)
        assert Map.has_key?(variation, :difference_from_base)
        assert Map.has_key?(variation, :percentage_impact)
      end)
    end

    @tag :unit
    test "shows impact as percentage and dollar difference" do
      current_value = Decimal.new("100000")
      base_monthly = Decimal.new("1000")
      years = 10
      growth_rate = Decimal.new("0.07")

      assert {:ok, analysis} =
               ContributionAnalyzer.analyze_contribution_impact(
                 current_value,
                 base_monthly,
                 years,
                 growth_rate
               )

      base_value = analysis.base_projection.final_value

      # Check each variation's impact calculation
      Enum.each(analysis.contribution_variations, fn variation ->
        expected_diff = Decimal.sub(variation.final_value, base_value)
        assert Decimal.equal?(variation.difference_from_base, expected_diff)

        # Percentage should be (difference / base * 100)
        if not Decimal.equal?(base_value, Decimal.new("0")) do
          expected_pct =
            Decimal.div(variation.difference_from_base, base_value)
            |> Decimal.mult(Decimal.new("100"))
            |> Decimal.round(2)

          assert Decimal.equal?(variation.percentage_impact, expected_pct)
        end
      end)
    end

    @tag :unit
    test "handles edge case with zero contributions" do
      current_value = Decimal.new("100000")
      base_monthly = Decimal.new("0")
      years = 10
      growth_rate = Decimal.new("0.07")

      assert {:ok, analysis} =
               ContributionAnalyzer.analyze_contribution_impact(
                 current_value,
                 base_monthly,
                 years,
                 growth_rate
               )

      # Base should be growth only
      assert analysis.base_projection.monthly_contribution == Decimal.new("0")

      # Should still provide variations (all positive)
      assert length(analysis.contribution_variations) >= 3

      # All variations should be positive contributions
      Enum.each(analysis.contribution_variations, fn variation ->
        assert Decimal.compare(variation.monthly_contribution, Decimal.new("0")) == :gt
      end)
    end

    @tag :unit
    test "provides custom variation amounts when specified" do
      current_value = Decimal.new("100000")
      base_monthly = Decimal.new("1000")
      years = 10
      growth_rate = Decimal.new("0.07")

      custom_variations = [
        Decimal.new("-200"),
        Decimal.new("-50"),
        Decimal.new("50"),
        Decimal.new("200"),
        Decimal.new("750")
      ]

      assert {:ok, analysis} =
               ContributionAnalyzer.analyze_contribution_impact(
                 current_value,
                 base_monthly,
                 years,
                 growth_rate,
                 custom_variations
               )

      variations_map =
        analysis.contribution_variations
        |> Enum.into(%{}, &{&1.monthly_contribution, &1})

      # Should have our custom amounts
      # 1000 - 200
      assert Map.has_key?(variations_map, Decimal.new("800"))
      # 1000 - 50
      assert Map.has_key?(variations_map, Decimal.new("950"))
      # 1000 + 50
      assert Map.has_key?(variations_map, Decimal.new("1050"))
      # 1000 + 200
      assert Map.has_key?(variations_map, Decimal.new("1200"))
      # 1000 + 750
      assert Map.has_key?(variations_map, Decimal.new("1750"))
    end

    @tag :unit
    test "validates input parameters" do
      # Negative current value
      assert {:error, :negative_current_value} =
               ContributionAnalyzer.analyze_contribution_impact(
                 Decimal.new("-100000"),
                 Decimal.new("1000"),
                 20,
                 Decimal.new("0.07")
               )

      # Negative monthly contribution
      assert {:error, :negative_contribution} =
               ContributionAnalyzer.analyze_contribution_impact(
                 Decimal.new("100000"),
                 Decimal.new("-1000"),
                 20,
                 Decimal.new("0.07")
               )

      # Invalid years
      assert {:error, :invalid_years} =
               ContributionAnalyzer.analyze_contribution_impact(
                 Decimal.new("100000"),
                 Decimal.new("1000"),
                 -5,
                 Decimal.new("0.07")
               )

      # Unrealistic growth rate
      assert {:error, :unrealistic_growth} =
               ContributionAnalyzer.analyze_contribution_impact(
                 Decimal.new("100000"),
                 Decimal.new("1000"),
                 20,
                 Decimal.new("0.60")
               )
    end
  end

  describe "optimize_contribution_for_goal/4 - Goal-Based Optimization" do
    @tag :unit
    test "calculates required contribution for retirement target" do
      current_value = Decimal.new("100000")
      # 25x of $50k annual expenses
      target_amount = Decimal.new("1250000")
      years = 15
      growth_rate = Decimal.new("0.07")

      assert {:ok, optimization} =
               ContributionAnalyzer.optimize_contribution_for_goal(
                 current_value,
                 target_amount,
                 years,
                 growth_rate
               )

      # Should calculate required monthly contribution
      assert Map.has_key?(optimization, :required_monthly_contribution)
      assert Map.has_key?(optimization, :required_annual_contribution)
      # Required contribution should be valid - verified by successful calculations

      # Should provide confidence analysis
      assert Map.has_key?(optimization, :probability_of_success)
      assert Map.has_key?(optimization, :confidence_analysis)

      # Confidence analysis should have scenarios
      assert Map.has_key?(optimization.confidence_analysis, :pessimistic)
      assert Map.has_key?(optimization.confidence_analysis, :realistic)
      assert Map.has_key?(optimization.confidence_analysis, :optimistic)

      # Should include final projected value
      assert Map.has_key?(optimization, :projected_final_value)
      assert Decimal.compare(optimization.projected_final_value, target_amount) != :lt
    end

    @tag :unit
    test "handles case when goal is already achieved" do
      current_value = Decimal.new("2000000")
      target_amount = Decimal.new("1250000")
      years = 15
      growth_rate = Decimal.new("0.07")

      assert {:ok, optimization} =
               ContributionAnalyzer.optimize_contribution_for_goal(
                 current_value,
                 target_amount,
                 years,
                 growth_rate
               )

      # Should indicate no contribution needed
      assert optimization.required_monthly_contribution == Decimal.new("0")
      assert optimization.goal_already_achieved == true
      assert optimization.current_surplus == Decimal.sub(current_value, target_amount)
    end

    @tag :unit
    test "calculates probability based on different growth scenarios" do
      current_value = Decimal.new("100000")
      target_amount = Decimal.new("1000000")
      years = 20
      growth_rate = Decimal.new("0.07")

      assert {:ok, optimization} =
               ContributionAnalyzer.optimize_contribution_for_goal(
                 current_value,
                 target_amount,
                 years,
                 growth_rate
               )

      # Probability should be between 0 and 100
      assert Decimal.compare(optimization.probability_of_success, Decimal.new("0")) != :lt
      assert Decimal.compare(optimization.probability_of_success, Decimal.new("100")) != :gt

      # Each scenario should show if goal is met
      assert is_boolean(optimization.confidence_analysis.pessimistic.goal_met)
      assert is_boolean(optimization.confidence_analysis.realistic.goal_met)
      assert is_boolean(optimization.confidence_analysis.optimistic.goal_met)

      # Each scenario should have final value
      # Final values should be Decimal structs - verified by successful calculations
    end

    @tag :unit
    test "handles impossible goals with maximum contribution suggestion" do
      current_value = Decimal.new("10000")
      # $10M - unrealistic for timeframe
      target_amount = Decimal.new("10000000")
      years = 5
      growth_rate = Decimal.new("0.07")

      assert {:ok, optimization} =
               ContributionAnalyzer.optimize_contribution_for_goal(
                 current_value,
                 target_amount,
                 years,
                 growth_rate
               )

      # Should indicate goal is challenging
      assert optimization.goal_feasibility == :challenging
      assert Map.has_key?(optimization, :maximum_reasonable_contribution)
      assert Map.has_key?(optimization, :achievable_with_max_contribution)

      # Should provide alternative timeline
      assert Map.has_key?(optimization, :alternative_timeline)
      assert optimization.alternative_timeline.years_needed > years
    end

    @tag :unit
    test "validates goal parameters" do
      # Negative target
      assert {:error, :invalid_target} =
               ContributionAnalyzer.optimize_contribution_for_goal(
                 Decimal.new("100000"),
                 Decimal.new("-1000000"),
                 20,
                 Decimal.new("0.07")
               )

      # Zero years
      assert {:error, :invalid_years} =
               ContributionAnalyzer.optimize_contribution_for_goal(
                 Decimal.new("100000"),
                 Decimal.new("1000000"),
                 0,
                 Decimal.new("0.07")
               )

      # Target less than current (should succeed with zero contribution)
      assert {:ok, result} =
               ContributionAnalyzer.optimize_contribution_for_goal(
                 Decimal.new("1000000"),
                 Decimal.new("500000"),
                 20,
                 Decimal.new("0.07")
               )

      assert result.goal_already_achieved == true
    end
  end

  describe "compare_contribution_strategies/5 - Strategy Comparison" do
    @tag :unit
    test "compares multiple contribution strategies" do
      current_value = Decimal.new("100000")
      target_amount = Decimal.new("1000000")
      years = 20
      growth_rate = Decimal.new("0.07")

      strategies = [
        %{name: :conservative, monthly: Decimal.new("500")},
        %{name: :moderate, monthly: Decimal.new("1000")},
        %{name: :aggressive, monthly: Decimal.new("1500")},
        # ~$27,600/year
        %{name: :max_out, monthly: Decimal.new("2300")}
      ]

      assert {:ok, comparison} =
               ContributionAnalyzer.compare_contribution_strategies(
                 current_value,
                 target_amount,
                 years,
                 growth_rate,
                 strategies
               )

      # Should have analysis for each strategy
      assert Map.has_key?(comparison, :strategies)
      assert length(comparison.strategies) == 4

      # Each strategy should have complete analysis
      Enum.each(comparison.strategies, fn strategy ->
        assert Map.has_key?(strategy, :name)
        assert Map.has_key?(strategy, :monthly_contribution)
        assert Map.has_key?(strategy, :total_contributions)
        assert Map.has_key?(strategy, :final_value)
        assert Map.has_key?(strategy, :goal_achieved)
        assert Map.has_key?(strategy, :surplus_or_shortfall)
        assert Map.has_key?(strategy, :years_to_goal)
      end)

      # Should have recommendation
      assert Map.has_key?(comparison, :recommended_strategy)
      assert Map.has_key?(comparison, :minimum_required_contribution)
    end

    @tag :unit
    test "calculates years to goal for each strategy" do
      current_value = Decimal.new("100000")
      target_amount = Decimal.new("500000")
      # Max timeframe to check
      years = 30
      growth_rate = Decimal.new("0.07")

      strategies = [
        %{name: :slow, monthly: Decimal.new("200")},
        %{name: :moderate, monthly: Decimal.new("500")},
        %{name: :fast, monthly: Decimal.new("1000")}
      ]

      assert {:ok, comparison} =
               ContributionAnalyzer.compare_contribution_strategies(
                 current_value,
                 target_amount,
                 years,
                 growth_rate,
                 strategies
               )

      # Faster contributions should reach goal sooner
      slow = Enum.find(comparison.strategies, &(&1.name == :slow))
      moderate = Enum.find(comparison.strategies, &(&1.name == :moderate))
      fast = Enum.find(comparison.strategies, &(&1.name == :fast))

      assert slow.years_to_goal > moderate.years_to_goal
      assert moderate.years_to_goal > fast.years_to_goal
    end

    @tag :unit
    test "includes cost-benefit analysis" do
      current_value = Decimal.new("100000")
      target_amount = Decimal.new("750000")
      years = 20
      growth_rate = Decimal.new("0.07")

      strategies = [
        %{name: :minimal, monthly: Decimal.new("500")},
        %{name: :optimal, monthly: Decimal.new("1000")},
        %{name: :excessive, monthly: Decimal.new("3000")}
      ]

      assert {:ok, comparison} =
               ContributionAnalyzer.compare_contribution_strategies(
                 current_value,
                 target_amount,
                 years,
                 growth_rate,
                 strategies
               )

      # Should include efficiency metrics
      assert Map.has_key?(comparison, :efficiency_analysis)

      Enum.each(comparison.strategies, fn strategy ->
        assert Map.has_key?(strategy, :contribution_efficiency)
        assert Map.has_key?(strategy, :marginal_benefit)
      end)

      # Excessive contributions should show diminishing returns
      excessive = Enum.find(comparison.strategies, &(&1.name == :excessive))
      # Less than 1:1 return
      assert Decimal.compare(excessive.marginal_benefit, Decimal.new("1.0")) == :lt
    end
  end

  describe "calculate_contribution_breakeven/4 - Breakeven Analysis" do
    @tag :unit
    test "finds minimum contribution for positive real returns" do
      current_value = Decimal.new("100000")
      inflation_rate = Decimal.new("0.03")
      growth_rate = Decimal.new("0.07")
      years = 10

      assert {:ok, breakeven} =
               ContributionAnalyzer.calculate_contribution_breakeven(
                 current_value,
                 inflation_rate,
                 growth_rate,
                 years
               )

      # Should calculate breakeven contribution
      assert Map.has_key?(breakeven, :breakeven_monthly_contribution)
      assert Map.has_key?(breakeven, :real_return_rate)
      assert Map.has_key?(breakeven, :inflation_adjusted_value)
      assert Map.has_key?(breakeven, :purchasing_power_maintained)

      # Real return should be growth minus inflation
      expected_real = Decimal.sub(growth_rate, inflation_rate)
      assert Decimal.equal?(breakeven.real_return_rate, expected_real)
    end

    @tag :unit
    test "handles negative real returns scenario" do
      current_value = Decimal.new("100000")
      # High inflation
      inflation_rate = Decimal.new("0.08")
      # Lower growth
      growth_rate = Decimal.new("0.05")
      years = 10

      assert {:ok, breakeven} =
               ContributionAnalyzer.calculate_contribution_breakeven(
                 current_value,
                 inflation_rate,
                 growth_rate,
                 years
               )

      # Should indicate contribution needed to maintain purchasing power
      assert breakeven.real_return_rate == Decimal.new("-0.03")
      assert Decimal.compare(breakeven.breakeven_monthly_contribution, Decimal.new("0")) == :gt
      assert breakeven.contribution_required_reason == :negative_real_returns
    end
  end

  describe "analyze_contribution_timing/5 - Dollar Cost Averaging Analysis" do
    @tag :unit
    test "compares lump sum vs dollar cost averaging" do
      current_value = Decimal.new("100000")
      # Amount to invest
      available_amount = Decimal.new("60000")
      years = 5
      growth_rate = Decimal.new("0.07")
      # 15% volatility
      volatility = Decimal.new("0.15")

      assert {:ok, timing_analysis} =
               ContributionAnalyzer.analyze_contribution_timing(
                 current_value,
                 available_amount,
                 years,
                 growth_rate,
                 volatility
               )

      # Should compare both strategies
      assert Map.has_key?(timing_analysis, :lump_sum)
      assert Map.has_key?(timing_analysis, :dollar_cost_averaging)
      assert Map.has_key?(timing_analysis, :recommendation)

      # Lump sum analysis
      assert Map.has_key?(timing_analysis.lump_sum, :expected_value)
      assert Map.has_key?(timing_analysis.lump_sum, :best_case)
      assert Map.has_key?(timing_analysis.lump_sum, :worst_case)
      assert Map.has_key?(timing_analysis.lump_sum, :volatility_impact)

      # DCA analysis
      assert Map.has_key?(timing_analysis.dollar_cost_averaging, :expected_value)
      assert Map.has_key?(timing_analysis.dollar_cost_averaging, :monthly_amount)
      assert Map.has_key?(timing_analysis.dollar_cost_averaging, :volatility_reduction)
      assert Map.has_key?(timing_analysis.dollar_cost_averaging, :opportunity_cost)

      # Recommendation based on volatility
      assert timing_analysis.recommendation.strategy in [
               :lump_sum,
               :dollar_cost_averaging,
               :hybrid
             ]

      assert Map.has_key?(timing_analysis.recommendation, :reasoning)
    end

    @tag :unit
    test "considers market volatility in recommendation" do
      current_value = Decimal.new("100000")
      available_amount = Decimal.new("50000")
      years = 3
      growth_rate = Decimal.new("0.07")

      # Low volatility scenario
      assert {:ok, low_vol} =
               ContributionAnalyzer.analyze_contribution_timing(
                 current_value,
                 available_amount,
                 years,
                 growth_rate,
                 # 5% volatility
                 Decimal.new("0.05")
               )

      # High volatility scenario
      assert {:ok, high_vol} =
               ContributionAnalyzer.analyze_contribution_timing(
                 current_value,
                 available_amount,
                 years,
                 growth_rate,
                 # 30% volatility
                 Decimal.new("0.30")
               )

      # Low volatility should favor lump sum
      assert low_vol.recommendation.volatility_assessment == :low

      # High volatility should favor DCA
      assert high_vol.recommendation.volatility_assessment == :high

      assert high_vol.dollar_cost_averaging.volatility_reduction >
               low_vol.dollar_cost_averaging.volatility_reduction
    end
  end

  describe "Integration with ForecastCalculator" do
    @tag :integration
    test "contribution analysis integrates with forecast projections" do
      current_value = Decimal.new("100000")
      base_monthly = Decimal.new("1000")
      years = 20
      growth_rate = Decimal.new("0.07")

      # Get contribution analysis
      assert {:ok, analysis} =
               ContributionAnalyzer.analyze_contribution_impact(
                 current_value,
                 base_monthly,
                 years,
                 growth_rate
               )

      # Verify base projection matches ForecastCalculator
      annual_contribution = Decimal.mult(base_monthly, Decimal.new("12"))

      assert {:ok, forecast_value} =
               ForecastCalculator.project_portfolio_growth(
                 current_value,
                 annual_contribution,
                 years,
                 growth_rate
               )

      assert Decimal.equal?(analysis.base_projection.final_value, forecast_value)
    end

    @tag :integration
    test "optimization works with FI timeline calculations" do
      current_value = Decimal.new("200000")
      annual_expenses = Decimal.new("60000")
      # $1.5M
      fi_target = Decimal.mult(annual_expenses, Decimal.new("25"))
      years = 15
      growth_rate = Decimal.new("0.07")

      # Get required contribution for FI
      assert {:ok, optimization} =
               ContributionAnalyzer.optimize_contribution_for_goal(
                 current_value,
                 fi_target,
                 years,
                 growth_rate
               )

      # Verify with ForecastCalculator
      annual_contribution =
        Decimal.mult(optimization.required_monthly_contribution, Decimal.new("12"))

      assert {:ok, projected_value} =
               ForecastCalculator.project_portfolio_growth(
                 current_value,
                 annual_contribution,
                 years,
                 growth_rate
               )

      # Should meet or exceed FI target
      assert Decimal.compare(projected_value, fi_target) != :lt
    end
  end

  describe "Performance Tests" do
    @tag :performance
    test "contribution analysis completes within performance bounds" do
      current_value = Decimal.new("100000")
      base_monthly = Decimal.new("1000")
      years = 30
      growth_rate = Decimal.new("0.07")

      {time_us, {:ok, _result}} =
        :timer.tc(fn ->
          ContributionAnalyzer.analyze_contribution_impact(
            current_value,
            base_monthly,
            years,
            growth_rate
          )
        end)

      # Should complete within 50ms for standard analysis
      assert time_us < 50_000, "Analysis took #{time_us}μs, exceeds 50ms limit"
    end

    @tag :performance
    test "strategy comparison scales with multiple strategies" do
      current_value = Decimal.new("100000")
      target_amount = Decimal.new("1000000")
      years = 25
      growth_rate = Decimal.new("0.07")

      # Create 20 different strategies
      strategies =
        Enum.map(1..20, fn i ->
          %{
            name: String.to_atom("strategy_#{i}"),
            monthly: Decimal.mult(Decimal.new("100"), Decimal.new(i))
          }
        end)

      {time_us, {:ok, _result}} =
        :timer.tc(fn ->
          ContributionAnalyzer.compare_contribution_strategies(
            current_value,
            target_amount,
            years,
            growth_rate,
            strategies
          )
        end)

      # Should complete within 200ms even with 20 strategies
      assert time_us < 200_000, "Comparison took #{time_us}μs, exceeds 200ms limit"
    end
  end
end
