defmodule Ashfolio.FinancialManagement.ForecastCalculatorAERTest do
  @moduledoc """
  Integration tests for AER standardization in ForecastCalculator.

  These tests verify that ForecastCalculator properly integrates with AERCalculator
  to provide consistent compound interest calculations across all portfolio projections.

  All tests in this file should FAIL initially (RED phase) until AER integration
  is implemented in Day 2 (GREEN phase).
  """

  use Ashfolio.DataCase

  alias Ashfolio.FinancialManagement.AERCalculator
  alias Ashfolio.FinancialManagement.ForecastCalculator

  @moduletag :unit

  # AER Integration Checklist for ForecastCalculator
  # [ ] Replace calculate_compound_growth_with_contributions/4 logic with AERCalculator.compound_with_aer/4
  # [ ] Remove calculate_future_value_of_present/3 and calculate_future_value_of_present_monthly/3
  # [ ] Remove calculate_future_value_of_annuity_monthly/3 (replaced by AER methodology)
  # [ ] Remove calculate_power/2 helper (use AER's precise power calculations)
  # [ ] Update all scenario functions to delegate to AERCalculator
  # [ ] Ensure all rate inputs are treated as AER (no conversion needed in UI)
  # [ ] Performance: <100ms for 10-year projections
  #
  # Integration Points Identified:
  # - Line 219: calculate_compound_growth_with_contributions/4 - main integration point
  # - Line 256: calculate_future_value_of_present/3 - replace with AER
  # - Line 263: calculate_future_value_of_present_monthly/3 - replace with AER
  # - Line 270: calculate_future_value_of_annuity_monthly/3 - replace with AER
  # - Line 285: calculate_power/2 - use AER's power calculations
  # - Mixed compounding strategy (lines 232-252) - standardize to AER

  describe "AER integration in project_portfolio_growth/4" do
    @tag :unit
    @tag :aer_integration
    test "uses AERCalculator.compound_with_aer/4 for growth calculations without contributions" do
      # This test verifies that ForecastCalculator delegates to AERCalculator
      # for consistent compound interest methodology
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("0")
      years = 10
      growth_rate = Decimal.new("0.07")

      # Calculate expected result using AERCalculator directly
      expected_aer_result =
        AERCalculator.compound_with_aer(
          current_value,
          growth_rate,
          years,
          # no monthly contributions
          Decimal.new("0")
        )

      {:ok, forecast_result} =
        ForecastCalculator.project_portfolio_growth(
          current_value,
          annual_contribution,
          years,
          growth_rate
        )

      # ForecastCalculator should produce identical results to AERCalculator
      # when using the same AER methodology
      assert Decimal.equal?(forecast_result, expected_aer_result),
             "ForecastCalculator (#{forecast_result}) should match AERCalculator (#{expected_aer_result}) for growth-only scenarios"
    end

    @tag :unit
    @tag :aer_integration
    test "uses AERCalculator.compound_with_aer/4 for growth calculations with contributions" do
      # This test verifies that ForecastCalculator uses AER methodology
      # for scenarios with regular monthly contributions
      current_value = Decimal.new("100000")
      # $1000/month
      annual_contribution = Decimal.new("12000")
      years = 10
      growth_rate = Decimal.new("0.07")

      # Calculate expected result using AERCalculator directly
      # AERCalculator expects monthly contributions, so convert annual to monthly
      monthly_contribution = Decimal.div(annual_contribution, Decimal.new("12"))

      expected_aer_result =
        AERCalculator.compound_with_aer(
          current_value,
          growth_rate,
          years,
          monthly_contribution
        )

      {:ok, forecast_result} =
        ForecastCalculator.project_portfolio_growth(
          current_value,
          annual_contribution,
          years,
          growth_rate
        )

      # Results should be within $10 due to rounding differences
      difference = forecast_result |> Decimal.sub(expected_aer_result) |> Decimal.abs()

      assert Decimal.compare(difference, Decimal.new("10.00")) != :gt,
             "ForecastCalculator (#{forecast_result}) should closely match AERCalculator (#{expected_aer_result}), difference: #{difference}"
    end

    @tag :unit
    @tag :aer_integration
    test "properly converts monthly rates using AERCalculator.aer_to_monthly/1" do
      # This test verifies that internal monthly rate calculations use AER conversion
      current_value = Decimal.new("50000")
      annual_contribution = Decimal.new("6000")
      years = 5
      # 8% AER
      growth_rate = Decimal.new("0.08")

      # The internal calculation should use AERCalculator.aer_to_monthly/1
      # to convert 8% AER to proper monthly rate (~0.643% monthly)
      _expected_monthly_rate = AERCalculator.aer_to_monthly(growth_rate)

      # This assertion will fail until ForecastCalculator is updated
      # to use AER methodology internally
      {:ok, result} =
        ForecastCalculator.project_portfolio_growth(
          current_value,
          annual_contribution,
          years,
          growth_rate
        )

      # Calculate what the result should be using direct AER calculation
      monthly_contribution = Decimal.div(annual_contribution, Decimal.new("12"))

      expected_result =
        AERCalculator.compound_with_aer(
          current_value,
          growth_rate,
          years,
          monthly_contribution
        )

      difference = result |> Decimal.sub(expected_result) |> Decimal.abs()

      assert Decimal.compare(difference, Decimal.new("5.00")) != :gt,
             "Expected AER-consistent result #{expected_result}, got #{result}, difference: #{difference}"
    end
  end

  describe "AER integration in multi-period projections" do
    @tag :unit
    @tag :aer_integration
    test "project_multi_period_growth/4 uses consistent AER methodology across all periods" do
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("12000")
      growth_rate = Decimal.new("0.07")
      periods = [5, 10, 15, 20]

      {:ok, results} =
        ForecastCalculator.project_multi_period_growth(
          current_value,
          annual_contribution,
          growth_rate,
          periods
        )

      # Verify each period uses AER methodology by comparing with direct AER calculation
      monthly_contribution = Decimal.div(annual_contribution, Decimal.new("12"))

      Enum.each(periods, fn years ->
        period_key = String.to_atom("year_#{years}")
        forecast_result = Map.get(results, period_key)

        expected_aer_result =
          AERCalculator.compound_with_aer(
            current_value,
            growth_rate,
            years,
            monthly_contribution
          )

        difference = forecast_result |> Decimal.sub(expected_aer_result) |> Decimal.abs()

        assert Decimal.compare(difference, Decimal.new("10.00")) != :gt,
               "Period #{years}: Expected AER result #{expected_aer_result}, got #{forecast_result}, difference: #{difference}"
      end)
    end
  end

  describe "AER integration edge cases" do
    @tag :unit
    @tag :aer_integration
    test "handles zero growth rate using AER methodology" do
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("12000")
      years = 10
      # 0% growth
      growth_rate = Decimal.new("0")

      {:ok, forecast_result} =
        ForecastCalculator.project_portfolio_growth(
          current_value,
          annual_contribution,
          years,
          growth_rate
        )

      # With 0% growth, result should be initial + total contributions
      expected_result =
        AERCalculator.compound_with_aer(
          current_value,
          growth_rate,
          years,
          Decimal.div(annual_contribution, Decimal.new("12"))
        )

      assert Decimal.equal?(forecast_result, expected_result),
             "Zero growth should match AER calculation: expected #{expected_result}, got #{forecast_result}"
    end

    @tag :unit
    @tag :aer_integration
    test "handles negative returns using AER methodology" do
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("12000")
      years = 5
      # -2% annual decline
      growth_rate = Decimal.new("-0.02")

      {:ok, forecast_result} =
        ForecastCalculator.project_portfolio_growth(
          current_value,
          annual_contribution,
          years,
          growth_rate
        )

      # Calculate expected using AER methodology
      monthly_contribution = Decimal.div(annual_contribution, Decimal.new("12"))

      expected_aer_result =
        AERCalculator.compound_with_aer(
          current_value,
          growth_rate,
          years,
          monthly_contribution
        )

      difference = forecast_result |> Decimal.sub(expected_aer_result) |> Decimal.abs()

      assert Decimal.compare(difference, Decimal.new("10.00")) != :gt,
             "Negative return AER calculation: expected #{expected_aer_result}, got #{forecast_result}, difference: #{difference}"
    end

    @tag :unit
    @tag :aer_integration
    test "handles very long time horizons efficiently with AER methodology" do
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("12000")
      # Long-term projection
      years = 30
      growth_rate = Decimal.new("0.07")

      # Measure performance - should be under 100ms
      start_time = System.monotonic_time(:millisecond)

      {:ok, forecast_result} =
        ForecastCalculator.project_portfolio_growth(
          current_value,
          annual_contribution,
          years,
          growth_rate
        )

      end_time = System.monotonic_time(:millisecond)
      calculation_time = end_time - start_time

      # Performance requirement
      assert calculation_time < 100,
             "30-year projection took #{calculation_time}ms, should be under 100ms"

      # Accuracy requirement using AER methodology
      monthly_contribution = Decimal.div(annual_contribution, Decimal.new("12"))

      expected_aer_result =
        AERCalculator.compound_with_aer(
          current_value,
          growth_rate,
          years,
          monthly_contribution
        )

      difference = forecast_result |> Decimal.sub(expected_aer_result) |> Decimal.abs()

      assert Decimal.compare(difference, Decimal.new("50.00")) != :gt,
             "30-year projection accuracy: expected #{expected_aer_result}, got #{forecast_result}, difference: #{difference}"
    end
  end

  describe "scenario projections with AER integration" do
    @tag :unit
    @tag :aer_integration
    test "calculate_scenario_projections/3 uses AER methodology for all scenarios" do
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("12000")
      years = 20

      {:ok, scenarios} =
        ForecastCalculator.calculate_scenario_projections(
          current_value,
          annual_contribution,
          years
        )

      # Standard scenario rates from ForecastCalculator
      standard_rates = %{
        pessimistic: Decimal.new("0.05"),
        realistic: Decimal.new("0.07"),
        optimistic: Decimal.new("0.10")
      }

      monthly_contribution = Decimal.div(annual_contribution, Decimal.new("12"))

      # Each scenario should match AER calculation
      Enum.each([:pessimistic, :realistic, :optimistic], fn scenario ->
        scenario_result = Map.get(scenarios, scenario)
        scenario_rate = Map.get(standard_rates, scenario)

        expected_aer_result =
          AERCalculator.compound_with_aer(
            current_value,
            scenario_rate,
            years,
            monthly_contribution
          )

        difference = scenario_result.portfolio_value |> Decimal.sub(expected_aer_result) |> Decimal.abs()

        assert Decimal.compare(difference, Decimal.new("20.00")) != :gt,
               "Scenario #{scenario}: expected #{expected_aer_result}, got #{scenario_result.portfolio_value}, difference: #{difference}"
      end)
    end
  end

  describe "UI rate interpretation as AER" do
    @tag :unit
    @tag :aer_integration
    test "input rates are properly interpreted as Annual Equivalent Rate (AER)" do
      # This test documents that UI-provided rates should be treated as AER
      # User enters "7%" expecting that to be the effective annual rate
      current_value = Decimal.new("100000")
      annual_contribution = Decimal.new("0")
      years = 10
      # User enters 7%
      ui_rate = Decimal.new("0.07")

      {:ok, forecast_result} =
        ForecastCalculator.project_portfolio_growth(
          current_value,
          annual_contribution,
          years,
          ui_rate
        )

      # The result should match what user expects from 7% AER compounding
      # User expectation: $100k * (1.07)^10 ≈ $196,715
      expected_user_result =
        AERCalculator.compound_with_aer(
          current_value,
          ui_rate,
          years,
          Decimal.new("0")
        )

      assert Decimal.equal?(forecast_result, expected_user_result),
             "UI rate interpretation: user expects #{expected_user_result} from 7% AER, ForecastCalculator returns #{forecast_result}"
    end
  end

  # Performance regression test
  @tag :unit
  @tag :performance
  test "AER integration maintains performance for typical use cases" do
    current_value = Decimal.new("100000")
    annual_contribution = Decimal.new("12000")
    years = 10
    growth_rate = Decimal.new("0.07")

    # Run calculation 10 times and measure average performance
    times =
      Enum.map(1..10, fn _ ->
        start_time = System.monotonic_time(:microsecond)

        {:ok, _result} =
          ForecastCalculator.project_portfolio_growth(
            current_value,
            annual_contribution,
            years,
            growth_rate
          )

        end_time = System.monotonic_time(:microsecond)
        end_time - start_time
      end)

    average_time = Enum.sum(times) / length(times)
    average_time_ms = average_time / 1000

    # Should average under 50ms for typical 10-year projections
    assert average_time_ms < 50.0,
           "Average calculation time #{Float.round(average_time_ms, 2)}ms should be under 50ms"
  end
end
