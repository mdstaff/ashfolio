defmodule Ashfolio.Portfolio.Calculators.DrawdownCalculatorTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Portfolio.Calculators.DrawdownCalculator
  alias Decimal, as: D

  doctest DrawdownCalculator

  describe "calculate/1" do
    test "calculates no drawdown for continuously increasing values" do
      values = [D.new("100000"), D.new("110000"), D.new("120000"), D.new("130000")]

      assert {:ok, result} = DrawdownCalculator.calculate(values)

      assert D.equal?(result.max_drawdown, D.new("0"))
      assert D.equal?(result.max_drawdown_percentage, D.new("0"))
      assert D.equal?(result.current_drawdown, D.new("0"))
      assert D.equal?(result.peak_value, D.new("130000"))
      assert result.recovery_periods == 0
      assert result.underwater_periods == 0
    end

    test "calculates 50% drawdown from peak to trough" do
      # Portfolio: 1M -> 1.2M -> 600k -> 1.1M
      values = [
        D.new("1000000"),
        D.new("1200000"),
        D.new("600000"),
        D.new("1100000")
      ]

      assert {:ok, result} = DrawdownCalculator.calculate(values)

      # Max drawdown: (1.2M - 600k) / 1.2M = 50%
      expected_drawdown = D.new("0.5")
      assert D.compare(D.abs(D.sub(result.max_drawdown, expected_drawdown)), D.new("0.001")) == :lt

      assert D.equal?(result.peak_value, D.new("1200000"))
      assert D.equal?(result.trough_value, D.new("600000"))
      assert D.compare(result.max_drawdown_percentage, D.new("49")) == :gt
      assert D.compare(result.max_drawdown_percentage, D.new("51")) == :lt
    end

    test "calculates multiple drawdowns and identifies maximum" do
      # Two drawdowns: 20% then 30%
      values = [
        # Initial
        D.new("100000"),
        # Peak 1
        D.new("120000"),
        # Trough 1 (20% drawdown)
        D.new("96000"),
        # Recovery
        D.new("110000"),
        # Peak 2 (new high)
        D.new("140000"),
        # Trough 2 (30% drawdown)
        D.new("98000"),
        # Partial recovery
        D.new("130000")
      ]

      assert {:ok, result} = DrawdownCalculator.calculate(values)

      # Should identify the 30% drawdown as maximum
      expected_max = D.new("0.3")
      assert D.compare(D.abs(D.sub(result.max_drawdown, expected_max)), D.new("0.01")) == :lt

      assert D.equal?(result.peak_value, D.new("140000"))
      assert D.equal?(result.trough_value, D.new("98000"))
    end

    test "calculates recovery time for full recovery" do
      # Peak -> trough -> full recovery
      values = [
        D.new("100000"),
        # Peak (index 1)
        D.new("120000"),
        # Trough (index 2)
        D.new("80000"),
        # Partial recovery (index 3)
        D.new("90000"),
        # Partial recovery (index 4)
        D.new("110000"),
        # Full recovery (index 5)
        D.new("120000")
      ]

      assert {:ok, result} = DrawdownCalculator.calculate(values)

      # Recovery time from trough to full recovery
      # From index 2 to index 5
      assert result.recovery_periods == 3
    end

    test "calculates underwater periods correctly" do
      # Portfolio stays below peak for extended period
      values = [
        D.new("100000"),
        # Peak
        D.new("120000"),
        # Below peak (underwater period starts)
        D.new("90000"),
        # Still underwater
        D.new("95000"),
        # Still underwater
        D.new("85000"),
        # Still underwater
        D.new("100000"),
        # Still underwater
        D.new("115000"),
        # Above peak (underwater period ends)
        D.new("125000")
      ]

      assert {:ok, result} = DrawdownCalculator.calculate(values)

      # Underwater for 5 periods (indices 2-6)
      assert result.underwater_periods == 5
    end

    test "calculates current drawdown when still underwater" do
      # Portfolio still below peak
      values = [
        D.new("100000"),
        # Peak
        D.new("120000"),
        # Current (25% below peak)
        D.new("90000")
      ]

      assert {:ok, result} = DrawdownCalculator.calculate(values)

      # Current drawdown: (120k - 90k) / 120k = 25%
      expected_current = D.new("0.25")
      assert D.compare(D.abs(D.sub(result.current_drawdown, expected_current)), D.new("0.01")) == :lt
    end

    test "handles single value (insufficient data)" do
      values = [D.new("100000")]

      assert {:error, :insufficient_data} = DrawdownCalculator.calculate(values)
    end

    test "handles empty data" do
      assert {:error, :insufficient_data} = DrawdownCalculator.calculate([])
    end

    test "handles all negative returns scenario" do
      # All values declining
      values = [
        D.new("100000"),
        D.new("90000"),
        D.new("80000"),
        D.new("70000")
      ]

      assert {:ok, result} = DrawdownCalculator.calculate(values)

      # Max drawdown from initial peak
      # (100k - 70k) / 100k
      expected_drawdown = D.new("0.3")
      assert D.compare(D.abs(D.sub(result.max_drawdown, expected_drawdown)), D.new("0.01")) == :lt

      assert D.equal?(result.peak_value, D.new("100000"))
      assert D.equal?(result.trough_value, D.new("70000"))
      # No recovery
      assert result.recovery_periods == nil
    end

    test "performance test for 1000 values under 100ms" do
      # Generate 1000 portfolio values with multiple drawdowns
      values = generate_large_portfolio_values(1000)

      {time, {:ok, _result}} =
        :timer.tc(fn ->
          DrawdownCalculator.calculate(values)
        end)

      # microseconds (100ms)
      assert time < 100_000
    end

    test "handles market crash scenario (2008-style 55% decline)" do
      # Simulate 2008 financial crisis drawdown
      crisis_values = [
        # Oct 2007 peak
        D.new("1565150"),
        D.new("1400000"),
        D.new("1200000"),
        D.new("1000000"),
        D.new("800000"),
        # Mar 2009 trough (-56.8%)
        D.new("676530"),
        D.new("750000"),
        D.new("900000"),
        D.new("1100000"),
        D.new("1300000"),
        # Full recovery
        D.new("1565150")
      ]

      assert {:ok, result} = DrawdownCalculator.calculate(crisis_values)

      # Should capture ~57% drawdown
      assert D.compare(result.max_drawdown_percentage, D.new("55")) == :gt
      assert D.compare(result.max_drawdown_percentage, D.new("60")) == :lt

      assert D.equal?(result.peak_value, D.new("1565150"))
      assert D.equal?(result.trough_value, D.new("676530"))
    end

    test "handles 2020 COVID crash and recovery" do
      # Rapid 30% decline and quick recovery
      covid_values = [
        # Feb 2020 peak
        D.new("3386150"),
        D.new("3000000"),
        D.new("2500000"),
        # Mar 2020 trough (-30%)
        D.new("2380000"),
        D.new("2800000"),
        D.new("3200000"),
        # New high within months
        D.new("3500000"),
        D.new("3800000")
      ]

      assert {:ok, result} = DrawdownCalculator.calculate(covid_values)

      # Should capture ~30% drawdown with quick recovery
      # (3386150 - 2380000) / 3386150
      expected_drawdown = D.new("0.297")
      assert D.compare(D.abs(D.sub(result.max_drawdown, expected_drawdown)), D.new("0.01")) == :lt

      # Should have recovery within few periods
      assert result.recovery_periods <= 4
    end

    test "rejects non-positive values" do
      values = [D.new("100000"), D.new("0"), D.new("50000")]

      assert {:error, :non_positive_values} = DrawdownCalculator.calculate(values)
    end

    test "rejects invalid data format" do
      invalid_values = ["100000", 50_000, "invalid"]

      assert {:error, :invalid_value_format} = DrawdownCalculator.calculate(invalid_values)
    end
  end

  describe "calculate_history/2" do
    @tag :skip
    test "identifies all drawdown periods above threshold" do
      values = [
        D.new("100000"),
        # Peak 1
        D.new("120000"),
        # 25% drawdown
        D.new("90000"),
        # Recovery
        D.new("110000"),
        # Peak 2
        D.new("140000"),
        # 30% drawdown
        D.new("98000"),
        # Recovery
        D.new("130000")
      ]

      # 20% threshold
      threshold = D.new("0.2")

      assert {:ok, history} = DrawdownCalculator.calculate_history(values, threshold)

      assert length(history) == 2

      # First drawdown period
      first_period = Enum.at(history, 0)
      assert D.compare(first_period.drawdown_percentage, D.new("20")) == :gt
      assert first_period.peak_index == 1
      assert first_period.trough_index == 2

      # Second drawdown period
      second_period = Enum.at(history, 1)
      assert D.compare(second_period.drawdown_percentage, D.new("25")) == :gt
      assert second_period.peak_index == 4
      assert second_period.trough_index == 5
    end

    @tag :skip
    test "returns empty history when no drawdowns exceed threshold" do
      values = [D.new("100000"), D.new("105000"), D.new("110000")]
      # 20% threshold
      threshold = D.new("0.2")

      assert {:ok, history} = DrawdownCalculator.calculate_history(values, threshold)

      assert history == []
    end

    @tag :skip
    test "calculates drawdown durations for each period" do
      values = [
        D.new("100000"),
        # Peak (index 1)
        D.new("120000"),
        # Trough (index 2)
        D.new("90000"),
        # Recovery point (index 3)
        D.new("100000"),
        # Still recovering (index 4)
        D.new("115000"),
        # Full recovery (index 5)
        D.new("120000")
      ]

      # 10% threshold
      threshold = D.new("0.1")

      assert {:ok, history} = DrawdownCalculator.calculate_history(values, threshold)

      period = Enum.at(history, 0)
      # From index 1 to 2
      assert period.duration_periods == 1
      # From index 2 to 5
      assert period.recovery_periods == 3
    end
  end

  describe "edge cases and error handling" do
    test "handles zero values gracefully" do
      # Should reject zero values as non-positive
      values = [D.new("100000"), D.new("0"), D.new("50000")]

      assert {:error, :non_positive_values} = DrawdownCalculator.calculate(values)
    end

    test "handles extreme volatility scenarios" do
      # Very volatile portfolio with large swings
      volatile_values = [
        D.new("100000"),
        # 100% gain
        D.new("200000"),
        # 75% drawdown from peak
        D.new("50000"),
        # Recovery
        D.new("150000"),
        # Another severe drawdown
        D.new("25000"),
        # Strong recovery to new high
        D.new("300000")
      ]

      assert {:ok, result} = DrawdownCalculator.calculate(volatile_values)

      # Should handle extreme volatility without errors
      assert D.compare(result.max_drawdown_percentage, D.new("70")) == :gt
      assert is_struct(result.max_drawdown, D)
      assert is_struct(result.peak_value, D)
      assert is_struct(result.trough_value, D)
    end

    test "validates input data types" do
      invalid_values = ["100000", 50_000, :invalid]

      assert {:error, :invalid_value_format} = DrawdownCalculator.calculate(invalid_values)
    end

    test "handles identical values (zero volatility)" do
      # All values identical = no drawdown
      values = [D.new("100000"), D.new("100000"), D.new("100000")]

      assert {:ok, result} = DrawdownCalculator.calculate(values)

      assert D.equal?(result.max_drawdown, D.new("0"))
      assert D.equal?(result.current_drawdown, D.new("0"))
      assert result.underwater_periods == 0
    end
  end

  describe "financial accuracy scenarios" do
    test "handles dot-com bubble burst (2000-2002)" do
      # NASDAQ declined ~78% from peak
      bubble_values = [
        # Mar 2000 peak
        D.new("5048620"),
        D.new("4500000"),
        D.new("3800000"),
        D.new("3000000"),
        D.new("2500000"),
        D.new("2000000"),
        D.new("1500000"),
        # Oct 2002 trough (-78%)
        D.new("1114110")
      ]

      assert {:ok, result} = DrawdownCalculator.calculate(bubble_values)

      # Should capture ~78% drawdown
      assert D.compare(result.max_drawdown_percentage, D.new("75")) == :gt
      assert D.compare(result.max_drawdown_percentage, D.new("80")) == :lt
    end

    test "handles Great Depression scenario" do
      # Stock market declined ~89% from 1929-1932
      depression_values = [
        # Sep 1929 peak
        D.new("381170"),
        D.new("300000"),
        D.new("230000"),
        D.new("180000"),
        D.new("120000"),
        D.new("80000"),
        # Jul 1932 trough (-89%)
        D.new("41220")
      ]

      assert {:ok, result} = DrawdownCalculator.calculate(depression_values)

      # Should capture ~89% drawdown
      assert D.compare(result.max_drawdown_percentage, D.new("85")) == :gt
      assert D.compare(result.max_drawdown_percentage, D.new("92")) == :lt
    end

    test "measures systematic risk impact on drawdowns" do
      # High-beta portfolio should have larger drawdowns than market
      high_beta_values = generate_high_beta_portfolio_values()
      market_values = generate_market_index_values()

      assert {:ok, portfolio_result} = DrawdownCalculator.calculate(high_beta_values)
      assert {:ok, market_result} = DrawdownCalculator.calculate(market_values)

      # High-beta portfolio should have larger max drawdown
      assert D.compare(portfolio_result.max_drawdown, market_result.max_drawdown) == :gt
    end
  end

  # Helper functions for test data generation
  defp generate_large_portfolio_values(count) do
    # Generate realistic portfolio values with multiple drawdown periods
    base_value = 1_000_000

    Enum.map(1..count, fn i ->
      # Add some volatility and trend
      # ±20% noise
      noise = :rand.uniform() * 0.4 - 0.2
      # Cyclical trend
      trend = :math.sin(i / 50) * 0.3
      # Periodic crashes
      crash_factor = if rem(i, 200) < 20, do: -0.4, else: 0

      value = base_value * (1 + trend + noise + crash_factor)
      D.new(to_string(trunc(value)))
    end)
  end

  defp generate_high_beta_portfolio_values do
    # Generate portfolio with high correlation to market but amplified moves
    market_returns = [0.10, -0.05, 0.15, -0.20, 0.08, -0.12, 0.25]
    base_value = 100_000

    {_, values} =
      Enum.reduce(market_returns, {base_value, [D.new("100000")]}, fn return, {current, acc} ->
        # High-beta portfolio: 1.5x market moves
        portfolio_return = return * 1.5
        new_value = current * (1 + portfolio_return)
        {new_value, acc ++ [D.new(to_string(trunc(new_value)))]}
      end)

    values
  end

  defp generate_market_index_values do
    # Generate standard market index values
    market_returns = [0.10, -0.05, 0.15, -0.20, 0.08, -0.12, 0.25]
    base_value = 100_000

    {_, values} =
      Enum.reduce(market_returns, {base_value, [D.new("100000")]}, fn return, {current, acc} ->
        new_value = current * (1 + return)
        {new_value, acc ++ [D.new(to_string(trunc(new_value)))]}
      end)

    values
  end
end
