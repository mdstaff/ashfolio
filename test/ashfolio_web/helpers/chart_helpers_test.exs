defmodule AshfolioWeb.Helpers.ChartHelpersTest do
  use ExUnit.Case, async: true

  alias AshfolioWeb.Helpers.ChartHelpers

  describe "format_growth_rate/1" do
    @tag :unit
    test "converts decimal to percentage string" do
      assert "7%" = ChartHelpers.format_growth_rate(Decimal.new("0.07"))
      assert "5%" = ChartHelpers.format_growth_rate(Decimal.new("0.05"))
      assert "10%" = ChartHelpers.format_growth_rate(Decimal.new("0.10"))
      assert "10.5%" = ChartHelpers.format_growth_rate(Decimal.new("0.105"))
    end

    @tag :unit
    test "handles float input" do
      assert "7%" = ChartHelpers.format_growth_rate(0.07)
      assert "5%" = ChartHelpers.format_growth_rate(0.05)
      assert "10%" = ChartHelpers.format_growth_rate(0.10)
    end

    @tag :unit
    test "handles string input" do
      assert "7%" = ChartHelpers.format_growth_rate("0.07")
      assert "5%" = ChartHelpers.format_growth_rate("0.05")
      assert "10%" = ChartHelpers.format_growth_rate("0.10")
    end

    @tag :unit
    test "handles invalid string input" do
      assert "0%" = ChartHelpers.format_growth_rate("invalid")
      assert "0%" = ChartHelpers.format_growth_rate("")
    end
  end

  describe "format_y_axis/1" do
    @tag :unit
    test "formats millions correctly" do
      assert "$1M" = ChartHelpers.format_y_axis(1_000_000)
      assert "$2.5M" = ChartHelpers.format_y_axis(2_500_000)
      assert "$10M" = ChartHelpers.format_y_axis(10_000_000)
      assert "$10.5M" = ChartHelpers.format_y_axis(10_500_000)
    end

    @tag :unit
    test "formats thousands correctly" do
      assert "$500K" = ChartHelpers.format_y_axis(500_000)
      assert "$1K" = ChartHelpers.format_y_axis(1_000)
      assert "$10K" = ChartHelpers.format_y_axis(10_000)
      assert "$10.5K" = ChartHelpers.format_y_axis(10_500)
    end

    @tag :unit
    test "formats billions correctly" do
      assert "$1B" = ChartHelpers.format_y_axis(1_000_000_000)
      assert "$2.5B" = ChartHelpers.format_y_axis(2_500_000_000)
    end

    @tag :unit
    test "formats small values correctly" do
      assert "$500" = ChartHelpers.format_y_axis(500)
      assert "$100" = ChartHelpers.format_y_axis(100)
      assert "$0" = ChartHelpers.format_y_axis(0)
    end

    @tag :unit
    test "handles Decimal input" do
      assert "$1M" = ChartHelpers.format_y_axis(Decimal.new("1000000"))
      assert "$500K" = ChartHelpers.format_y_axis(Decimal.new("500000"))
    end
  end

  describe "generate_chart_periods/1" do
    @tag :unit
    test "uses annual periods for short timeframes" do
      assert Enum.to_list(0..5) == Enum.to_list(ChartHelpers.generate_chart_periods(5))
      assert Enum.to_list(0..10) == Enum.to_list(ChartHelpers.generate_chart_periods(10))
    end

    @tag :unit
    test "uses bi-annual periods for medium timeframes" do
      periods = ChartHelpers.generate_chart_periods(20)
      assert [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20] == Enum.to_list(periods)
    end

    @tag :unit
    test "uses optimal spacing for long timeframes" do
      periods = ChartHelpers.generate_chart_periods(30)
      # Should take every 3rd year (30/10 = 3)
      assert [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30] == Enum.to_list(periods)
    end
  end

  describe "build_scenario_projection/4" do
    @tag :unit
    test "calculates compound growth with contributions" do
      initial = Decimal.new("100000")
      params = %{monthly_contribution: Decimal.new("1000")}
      years = 10
      growth_rate = 0.07

      result = ChartHelpers.build_scenario_projection(initial, params, years, growth_rate)

      # First value should be initial value
      assert [first | _] = result
      assert Decimal.equal?(first, initial)

      # Should have proper number of periods
      expected_periods = Enum.count(ChartHelpers.generate_chart_periods(years))
      assert length(result) == expected_periods

      # Values should increase over time
      [first, second | _] = result
      assert Decimal.compare(second, first) == :gt
    end

    @tag :unit
    test "handles zero contributions" do
      initial = Decimal.new("100000")
      params = %{monthly_contribution: Decimal.new("0")}
      years = 5
      growth_rate = 0.07

      result = ChartHelpers.build_scenario_projection(initial, params, years, growth_rate)

      assert [first | _] = result
      assert Decimal.equal?(first, initial)
      assert length(result) > 1
    end

    @tag :unit
    test "handles zero growth rate" do
      initial = Decimal.new("100000")
      params = %{monthly_contribution: Decimal.new("500")}
      years = 5
      growth_rate = 0.0

      result = ChartHelpers.build_scenario_projection(initial, params, years, growth_rate)

      assert [first | _] = result
      assert Decimal.equal?(first, initial)
    end
  end

  describe "format_currency/1" do
    @tag :unit
    test "formats Decimal values" do
      assert "$100.00" = ChartHelpers.format_currency(Decimal.new("100"))
      assert "$1000.50" = ChartHelpers.format_currency(Decimal.new("1000.50"))
    end

    @tag :unit
    test "formats numeric values" do
      assert "$100.00" = ChartHelpers.format_currency(100)
      assert "$1000.50" = ChartHelpers.format_currency(1000.50)
    end

    @tag :unit
    test "handles invalid input" do
      assert "$0.00" = ChartHelpers.format_currency(nil)
      assert "$0.00" = ChartHelpers.format_currency("invalid")
    end
  end
end
