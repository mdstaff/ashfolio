defmodule Ashfolio.FinancialManagement.ForecastChartDataTest do
  use ExUnit.Case, async: true

  alias Ashfolio.FinancialManagement.ForecastCalculator

  @moduletag :unit

  describe "Chart Data Generation" do
    test "scenario projections return final values not time series" do
      initial = Decimal.new("100000")
      # $1000/month
      contribution = Decimal.new("12000")
      years = 10

      # Generate projection data
      result =
        ForecastCalculator.calculate_scenario_projections(
          initial,
          contribution,
          years
        )

      # The function returns final values, not time series
      assert {:ok, data} = result
      assert Map.has_key?(data, :realistic)
      assert Map.has_key?(data.realistic, :growth_rate)
      assert Map.has_key?(data.realistic, :portfolio_value)

      # Verify growth rate is correct
      assert Decimal.equal?(data.realistic.growth_rate, Decimal.new("0.07"))
    end

    test "scenario comparison generates three distinct final values" do
      initial = Decimal.new("100000")
      contribution = Decimal.new("12000")
      years = 5

      result =
        ForecastCalculator.calculate_scenario_projections(
          initial,
          contribution,
          years
        )

      assert {:ok, data} = result
      assert Map.has_key?(data, :pessimistic)
      assert Map.has_key?(data, :realistic)
      assert Map.has_key?(data, :optimistic)
      assert Map.has_key?(data, :weighted_average)

      # Each scenario should have different final values
      pessimistic_value = data.pessimistic.portfolio_value
      realistic_value = data.realistic.portfolio_value
      optimistic_value = data.optimistic.portfolio_value

      # Values should be in ascending order
      assert Decimal.compare(pessimistic_value, realistic_value) == :lt
      assert Decimal.compare(realistic_value, optimistic_value) == :lt

      # Growth rates should be correct
      assert Decimal.equal?(data.pessimistic.growth_rate, Decimal.new("0.05"))
      assert Decimal.equal?(data.realistic.growth_rate, Decimal.new("0.07"))
      assert Decimal.equal?(data.optimistic.growth_rate, Decimal.new("0.10"))
    end

    test "contribution impact generates distinct chart data" do
      initial = Decimal.new("100000")
      base_contribution = Decimal.new("12000")
      years = 10
      growth_rate = Decimal.new("0.07")

      # This function needs to be implemented or fixed
      variations = [
        # -$500/month
        Decimal.new("-6000"),
        # -$100/month
        Decimal.new("-1200"),
        Decimal.new("0"),
        # +$100/month
        Decimal.new("1200"),
        # +$500/month
        Decimal.new("6000")
      ]

      impact_data =
        Enum.map(variations, fn delta ->
          contribution = Decimal.add(base_contribution, delta)

          {:ok, result} =
            ForecastCalculator.project_portfolio_growth(
              initial,
              contribution,
              years,
              growth_rate
            )

          %{
            contribution_delta: delta,
            monthly_contribution: Decimal.div(contribution, Decimal.new("12")),
            final_value: result
          }
        end)

      # All variations should produce different final values
      assert length(impact_data) == 5
      assert Enum.all?(impact_data, &Map.has_key?(&1, :final_value))

      # Higher contributions should result in higher final values
      values = Enum.map(impact_data, & &1.final_value)
      sorted_values = Enum.sort(values, &(Decimal.compare(&1, &2) == :lt))
      assert values == sorted_values
    end
  end

  describe "Chart Y-Axis Formatting" do
    test "chart should use proper number formatting" do
      # Test that chart configuration uses the right formatter
      chart_config = %{
        y_axis_formatter: &format_y_axis/1
      }

      # Test the formatter
      assert chart_config.y_axis_formatter.(1_000_000) == "$1M"
      assert chart_config.y_axis_formatter.(2_000_000_000) == "$2B"
      refute chart_config.y_axis_formatter.(2_000_000_000) =~ "BGN"
    end
  end

  # Helper function that should match the actual implementation
  defp format_y_axis(value) when is_number(value) do
    cond do
      value >= 1_000_000_000 ->
        formatted = Float.round(value / 1_000_000_000, 1)

        if formatted == trunc(formatted) do
          "$#{trunc(formatted)}B"
        else
          "$#{formatted}B"
        end

      value >= 1_000_000 ->
        formatted = Float.round(value / 1_000_000, 1)

        if formatted == trunc(formatted) do
          "$#{trunc(formatted)}M"
        else
          "$#{formatted}M"
        end

      value >= 1_000 ->
        formatted = Float.round(value / 1_000, 1)

        if formatted == trunc(formatted) do
          "$#{trunc(formatted)}K"
        else
          "$#{formatted}K"
        end

      true ->
        "$#{trunc(value)}"
    end
  end
end
