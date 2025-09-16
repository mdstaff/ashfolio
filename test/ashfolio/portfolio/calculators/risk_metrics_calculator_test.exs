defmodule Ashfolio.Portfolio.Calculators.RiskMetricsCalculatorTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Portfolio.Calculators.RiskMetricsCalculator
  alias Decimal, as: D

  doctest RiskMetricsCalculator

  describe "calculate_sharpe_ratio/2" do
    test "calculates Sharpe ratio for positive returns" do
      returns = [D.new("0.05"), D.new("0.03"), D.new("0.07"), D.new("0.02"), D.new("0.06")]
      risk_free_rate = D.new("0.02")

      assert {:ok, result} = RiskMetricsCalculator.calculate_sharpe_ratio(returns, risk_free_rate)

      assert %{
               sharpe_ratio: sharpe,
               excess_return: excess,
               volatility: volatility,
               mean_return: mean
             } = result

      # Expected mean: (0.05 + 0.03 + 0.07 + 0.02 + 0.06) / 5 = 0.046
      assert D.compare(mean, D.new("0.046")) == :eq

      # Should have positive Sharpe ratio for returns above risk-free rate
      assert D.compare(sharpe, D.new("0")) == :gt
      assert D.compare(excess, D.new("0")) == :gt
      assert D.compare(volatility, D.new("0")) == :gt
    end

    test "handles negative Sharpe ratio for poor performance" do
      returns = [D.new("-0.02"), D.new("-0.01"), D.new("0.01"), D.new("-0.03"), D.new("0.00")]
      risk_free_rate = D.new("0.03")

      assert {:ok, result} = RiskMetricsCalculator.calculate_sharpe_ratio(returns, risk_free_rate)

      # Expected mean: (-0.02 - 0.01 + 0.01 - 0.03 + 0.00) / 5 = -0.01
      assert D.compare(result.mean_return, D.new("-0.01")) == :eq
      assert D.compare(result.sharpe_ratio, D.new("0")) == :lt
    end

    test "handles zero volatility edge case" do
      # All returns identical = zero volatility
      returns = [D.new("0.05"), D.new("0.05"), D.new("0.05"), D.new("0.05")]
      risk_free_rate = D.new("0.02")

      assert {:ok, result} = RiskMetricsCalculator.calculate_sharpe_ratio(returns, risk_free_rate)

      assert D.equal?(result.volatility, D.new("0"))
      assert D.equal?(result.sharpe_ratio, D.new("0"))
    end

    test "handles market crash scenario" do
      # 2008-style market crash returns
      returns = [
        D.new("-0.15"),
        D.new("-0.08"),
        D.new("-0.12"),
        D.new("-0.20"),
        D.new("-0.05"),
        D.new("0.03")
      ]

      risk_free_rate = D.new("0.01")

      assert {:ok, result} = RiskMetricsCalculator.calculate_sharpe_ratio(returns, risk_free_rate)

      # Should have negative Sharpe ratio and high volatility
      assert D.compare(result.sharpe_ratio, D.new("0")) == :lt
      assert D.compare(result.volatility, D.new("0.05")) == :gt
    end

    test "rejects insufficient data" do
      assert {:error, :insufficient_data} =
               RiskMetricsCalculator.calculate_sharpe_ratio([D.new("0.05")])

      assert {:error, :insufficient_data} = RiskMetricsCalculator.calculate_sharpe_ratio([])
    end

    test "rejects invalid risk-free rate" do
      returns = [D.new("0.05"), D.new("0.03")]

      assert {:error, :invalid_risk_free_rate} =
               RiskMetricsCalculator.calculate_sharpe_ratio(returns, D.new("-0.01"))

      assert {:error, :invalid_risk_free_rate} =
               RiskMetricsCalculator.calculate_sharpe_ratio(returns, D.new("1.5"))
    end
  end

  describe "calculate_sortino_ratio/2" do
    test "calculates Sortino ratio with mixed returns" do
      returns = [D.new("0.05"), D.new("-0.02"), D.new("0.07"), D.new("-0.01"), D.new("0.03")]
      target_return = D.new("0.02")

      assert {:ok, result} = RiskMetricsCalculator.calculate_sortino_ratio(returns, target_return)

      assert %{
               sortino_ratio: sortino,
               excess_return: excess,
               downside_deviation: downside_dev
             } = result

      # Should focus only on downside volatility
      assert D.compare(sortino, D.new("0")) == :gt
      assert D.compare(downside_dev, D.new("0")) == :gt
      assert D.compare(excess, D.new("0")) == :gt
    end

    test "handles no downside returns" do
      # All returns above target
      returns = [D.new("0.05"), D.new("0.03"), D.new("0.07"), D.new("0.04")]
      target_return = D.new("0.02")

      assert {:ok, result} = RiskMetricsCalculator.calculate_sortino_ratio(returns, target_return)

      # No downside deviation = zero downside risk
      assert D.equal?(result.downside_deviation, D.new("0"))
      assert D.equal?(result.sortino_ratio, D.new("0"))
    end

    test "handles high inflation period scenario" do
      # 1970s-style high inflation with mixed real returns
      returns = [
        D.new("0.15"),
        D.new("-0.05"),
        D.new("0.08"),
        D.new("-0.10"),
        D.new("0.12"),
        D.new("-0.03")
      ]

      # High inflation target
      target_return = D.new("0.10")

      assert {:ok, result} = RiskMetricsCalculator.calculate_sortino_ratio(returns, target_return)

      # Should penalize periods below target more heavily
      assert D.compare(result.downside_deviation, D.new("0")) == :gt
    end
  end

  describe "calculate_maximum_drawdown/1" do
    test "calculates maximum drawdown from peak to trough" do
      # Portfolio values: 100k -> 120k -> 80k -> 110k
      values = [
        D.new("100000"),
        D.new("120000"),
        D.new("80000"),
        D.new("110000")
      ]

      assert {:ok, result} = RiskMetricsCalculator.calculate_maximum_drawdown(values)

      # Max drawdown: (120k - 80k) / 120k = 33.33%
      expected_drawdown = D.new("0.333333")
      assert D.compare(D.abs(D.sub(result.max_drawdown, expected_drawdown)), D.new("0.001")) == :lt

      assert D.equal?(result.peak_value, D.new("120000"))
      assert D.equal?(result.trough_value, D.new("80000"))
      assert D.compare(result.max_drawdown_percentage, D.new("33")) == :gt
    end

    test "handles continuously rising portfolio" do
      values = [D.new("100000"), D.new("110000"), D.new("120000"), D.new("130000")]

      assert {:ok, result} = RiskMetricsCalculator.calculate_maximum_drawdown(values)

      # No drawdown in rising portfolio
      assert D.equal?(result.max_drawdown, D.new("0"))
      assert D.equal?(result.max_drawdown_percentage, D.new("0"))
    end

    test "handles severe market crash scenario" do
      # 2008-style 50% crash
      values = [
        D.new("1000000"),
        D.new("800000"),
        D.new("600000"),
        D.new("500000"),
        D.new("700000")
      ]

      assert {:ok, result} = RiskMetricsCalculator.calculate_maximum_drawdown(values)

      # Max drawdown: 50%
      assert D.compare(result.max_drawdown_percentage, D.new("45")) == :gt
      assert D.equal?(result.peak_value, D.new("1000000"))
      assert D.equal?(result.trough_value, D.new("500000"))
    end

    test "rejects insufficient data" do
      assert {:error, :insufficient_data} =
               RiskMetricsCalculator.calculate_maximum_drawdown([D.new("100000")])
    end

    test "rejects non-positive values" do
      values = [D.new("100000"), D.new("0"), D.new("50000")]

      assert {:error, :non_positive_values} =
               RiskMetricsCalculator.calculate_maximum_drawdown(values)
    end
  end

  describe "calculate_value_at_risk/3" do
    test "calculates VaR for normal return distribution" do
      returns = [
        D.new("0.02"),
        D.new("-0.01"),
        D.new("0.03"),
        D.new("0.01"),
        D.new("-0.005"),
        D.new("0.025")
      ]

      portfolio_value = D.new("1000000")
      confidence_level = D.new("0.95")

      assert {:ok, result} = RiskMetricsCalculator.calculate_value_at_risk(returns, portfolio_value, confidence_level)

      assert %{
               var_amount: var_amount,
               var_percentage: _var_percentage,
               z_score: z_score,
               confidence_level: conf_level
             } = result

      # Should use 95% confidence Z-score (1.645)
      assert D.equal?(z_score, D.new("1.645"))
      assert D.equal?(conf_level, confidence_level)

      # VaR amount should be reasonable for $1M portfolio
      assert D.compare(var_amount, D.new("0")) == :gt
      # Should be < 20%
      assert D.compare(var_amount, D.new("200000")) == :lt
    end

    test "calculates VaR for 99% confidence level" do
      returns = [D.new("0.01"), D.new("-0.02"), D.new("0.03")]
      portfolio_value = D.new("500000")
      confidence_level = D.new("0.99")

      assert {:ok, result} = RiskMetricsCalculator.calculate_value_at_risk(returns, portfolio_value, confidence_level)

      # Should use 99% confidence Z-score (2.326)
      assert D.equal?(result.z_score, D.new("2.326"))

      # 99% VaR should be higher than 95% VaR
      assert D.compare(result.var_amount, D.new("0")) == :gt
    end

    test "handles negative interest rate environment" do
      # European-style negative rate scenario
      returns = [
        D.new("-0.001"),
        D.new("-0.002"),
        D.new("0.001"),
        D.new("-0.0005"),
        D.new("0.0015")
      ]

      portfolio_value = D.new("250000")

      assert {:ok, result} = RiskMetricsCalculator.calculate_value_at_risk(returns, portfolio_value)

      # Should handle negative expected returns
      assert D.compare(result.var_amount, D.new("0")) == :gt
    end

    test "rejects invalid confidence levels" do
      returns = [D.new("0.01"), D.new("0.02")]
      portfolio_value = D.new("100000")

      assert {:error, :invalid_confidence_level} =
               RiskMetricsCalculator.calculate_value_at_risk(returns, portfolio_value, D.new("1.5"))

      assert {:error, :invalid_confidence_level} =
               RiskMetricsCalculator.calculate_value_at_risk(returns, portfolio_value, D.new("0"))
    end

    test "rejects invalid portfolio value" do
      returns = [D.new("0.01"), D.new("0.02")]

      assert {:error, :invalid_portfolio_value} =
               RiskMetricsCalculator.calculate_value_at_risk(returns, D.new("0"))

      assert {:error, :invalid_portfolio_value} =
               RiskMetricsCalculator.calculate_value_at_risk(returns, D.new("-1000"))
    end
  end

  describe "calculate_information_ratio/2" do
    test "calculates information ratio for outperforming portfolio" do
      portfolio_returns = [D.new("0.08"), D.new("0.12"), D.new("0.06"), D.new("0.10")]
      benchmark_returns = [D.new("0.07"), D.new("0.10"), D.new("0.05"), D.new("0.08")]

      assert {:ok, result} = RiskMetricsCalculator.calculate_information_ratio(portfolio_returns, benchmark_returns)

      assert %{
               information_ratio: info_ratio,
               active_return: active_return,
               tracking_error: tracking_error
             } = result

      # Portfolio outperforms benchmark consistently
      assert D.compare(active_return, D.new("0")) == :gt
      assert D.compare(info_ratio, D.new("0")) == :gt
      assert D.compare(tracking_error, D.new("0")) == :gt
    end

    test "calculates information ratio for underperforming portfolio" do
      portfolio_returns = [D.new("0.05"), D.new("0.03"), D.new("0.07")]
      benchmark_returns = [D.new("0.08"), D.new("0.06"), D.new("0.09")]

      assert {:ok, result} = RiskMetricsCalculator.calculate_information_ratio(portfolio_returns, benchmark_returns)

      # Portfolio underperforms consistently
      assert D.compare(result.active_return, D.new("0")) == :lt
      assert D.compare(result.information_ratio, D.new("0")) == :lt
    end

    test "handles perfect tracking (zero tracking error)" do
      # Portfolio exactly matches benchmark
      returns = [D.new("0.05"), D.new("0.03"), D.new("0.07")]

      assert {:ok, result} = RiskMetricsCalculator.calculate_information_ratio(returns, returns)

      assert D.equal?(result.active_return, D.new("0"))
      assert D.equal?(result.tracking_error, D.new("0"))
      assert D.equal?(result.information_ratio, D.new("0"))
    end

    test "rejects mismatched return periods" do
      portfolio_returns = [D.new("0.05"), D.new("0.03")]
      benchmark_returns = [D.new("0.07")]

      assert {:error, :mismatched_return_periods} =
               RiskMetricsCalculator.calculate_information_ratio(portfolio_returns, benchmark_returns)
    end
  end

  describe "edge cases and error handling" do
    test "handles zero values gracefully" do
      zero_returns = [D.new("0"), D.new("0"), D.new("0")]

      assert {:ok, sharpe_result} = RiskMetricsCalculator.calculate_sharpe_ratio(zero_returns)
      assert D.equal?(sharpe_result.sharpe_ratio, D.new("0"))

      assert {:ok, sortino_result} = RiskMetricsCalculator.calculate_sortino_ratio(zero_returns)
      assert D.equal?(sortino_result.sortino_ratio, D.new("0"))
    end

    test "handles extreme volatility scenarios" do
      # Very high volatility returns
      volatile_returns = [
        D.new("0.50"),
        D.new("-0.40"),
        D.new("0.60"),
        D.new("-0.30"),
        D.new("0.45")
      ]

      assert {:ok, result} = RiskMetricsCalculator.calculate_sharpe_ratio(volatile_returns)

      # Should handle extreme volatility without errors
      assert D.compare(result.volatility, D.new("0.30")) == :gt
      assert is_struct(result.sharpe_ratio, D)
    end

    test "validates input data types" do
      invalid_returns = ["0.05", 0.03, "invalid"]

      assert {:error, :invalid_return_format} =
               RiskMetricsCalculator.calculate_sharpe_ratio(invalid_returns)
    end
  end

  describe "calculate_calmar_ratio/2" do
    test "calculates Calmar ratio with positive returns and drawdown" do
      returns = [D.new("0.12"), D.new("0.08"), D.new("-0.05"), D.new("0.15"), D.new("0.10")]

      cumulative_values = [
        D.new("100000"),
        D.new("112000"),
        D.new("121000"),
        D.new("115000"),
        D.new("132000"),
        D.new("145000")
      ]

      assert {:ok, result} = RiskMetricsCalculator.calculate_calmar_ratio(returns, cumulative_values)

      assert %{
               calmar_ratio: calmar,
               annualized_return: annual_return,
               max_drawdown: max_dd
             } = result

      # Should have positive Calmar ratio with positive average returns
      assert D.compare(calmar, D.new("0")) == :gt
      assert D.compare(annual_return, D.new("0")) == :gt
      assert D.compare(max_dd, D.new("0")) == :gt
    end

    test "calculates Calmar ratio with negative returns" do
      returns = [D.new("-0.05"), D.new("-0.08"), D.new("-0.03"), D.new("-0.12")]
      cumulative_values = [D.new("100000"), D.new("95000"), D.new("87000"), D.new("84000"), D.new("74000")]

      assert {:ok, result} = RiskMetricsCalculator.calculate_calmar_ratio(returns, cumulative_values)

      # Should have negative Calmar ratio with negative returns
      assert D.compare(result.calmar_ratio, D.new("0")) == :lt
      assert D.compare(result.annualized_return, D.new("0")) == :lt
    end

    test "handles zero drawdown scenario" do
      # Continuously rising portfolio
      returns = [D.new("0.05"), D.new("0.03"), D.new("0.07"), D.new("0.04")]
      cumulative_values = [D.new("100000"), D.new("105000"), D.new("108150"), D.new("115721"), D.new("120350")]

      assert {:ok, result} = RiskMetricsCalculator.calculate_calmar_ratio(returns, cumulative_values)

      # With zero drawdown, Calmar ratio should be effectively infinite, but we return a default high value
      assert D.compare(result.max_drawdown, D.new("0")) == :eq
      assert D.compare(result.calmar_ratio, D.new("999.99")) == :eq
    end

    test "handles market crash scenario" do
      # 2008-style crash with recovery
      returns = [D.new("0.15"), D.new("-0.25"), D.new("-0.35"), D.new("-0.15"), D.new("0.30"), D.new("0.20")]

      cumulative_values = [
        D.new("100000"),
        D.new("115000"),
        D.new("86250"),
        D.new("56063"),
        D.new("47653"),
        D.new("61949"),
        D.new("74339")
      ]

      assert {:ok, result} = RiskMetricsCalculator.calculate_calmar_ratio(returns, cumulative_values)

      # Should capture severe drawdown impact on risk-adjusted return
      assert D.compare(result.max_drawdown, D.new("0.40")) == :gt
      assert is_struct(result.calmar_ratio, D)
    end

    test "rejects insufficient data" do
      assert {:error, :insufficient_data} =
               RiskMetricsCalculator.calculate_calmar_ratio([D.new("0.05")], [D.new("100000"), D.new("105000")])

      assert {:error, :insufficient_data} = RiskMetricsCalculator.calculate_calmar_ratio([], [])
    end

    test "rejects mismatched data lengths" do
      returns = [D.new("0.05"), D.new("0.03")]
      cumulative_values = [D.new("100000"), D.new("105000")]

      assert {:error, :mismatched_data_lengths} =
               RiskMetricsCalculator.calculate_calmar_ratio(returns, cumulative_values)
    end
  end

  describe "calculate_sterling_ratio/3" do
    test "calculates Sterling ratio with default threshold" do
      returns = [D.new("0.12"), D.new("0.08"), D.new("-0.05"), D.new("0.15")]
      cumulative_values = [D.new("100000"), D.new("112000"), D.new("120960"), D.new("114912"), D.new("132149")]

      assert {:ok, result} = RiskMetricsCalculator.calculate_sterling_ratio(returns, cumulative_values)

      assert %{
               sterling_ratio: sterling,
               annualized_return: _annual_return,
               adjusted_drawdown: adj_dd
             } = result

      # Default threshold is 10%, so adjusted drawdown should account for this
      assert D.compare(sterling, D.new("0")) == :gt
      # Adjusted drawdown can be negative if max_drawdown < threshold
      assert is_struct(adj_dd, D)
    end

    test "calculates Sterling ratio with custom threshold" do
      returns = [D.new("0.10"), D.new("-0.08"), D.new("0.12"), D.new("-0.15")]
      cumulative_values = [D.new("100000"), D.new("110000"), D.new("101200"), D.new("113344"), D.new("96342")]
      # 5% threshold
      threshold = D.new("0.05")

      assert {:ok, result} = RiskMetricsCalculator.calculate_sterling_ratio(returns, cumulative_values, threshold)

      # Adjusted drawdown = max_drawdown - threshold
      # Should be different from default 10% threshold
      assert is_struct(result.sterling_ratio, D)
      assert is_struct(result.adjusted_drawdown, D)
    end

    test "handles maximum drawdown less than threshold" do
      # Small drawdown scenario
      returns = [D.new("0.05"), D.new("-0.02"), D.new("0.03"), D.new("0.01")]
      cumulative_values = [D.new("100000"), D.new("105000"), D.new("102900"), D.new("105987"), D.new("107047")]
      # 10% threshold
      threshold = D.new("0.10")

      assert {:ok, result} = RiskMetricsCalculator.calculate_sterling_ratio(returns, cumulative_values, threshold)

      # When drawdown < threshold, adjusted drawdown should be minimal
      # Sterling ratio should be very high
      assert D.compare(result.sterling_ratio, D.new("100")) == :gt
    end

    test "handles high inflation period scenario" do
      # 1970s-style returns with high volatility
      returns = [
        D.new("0.20"),
        D.new("-0.12"),
        D.new("0.25"),
        D.new("-0.18"),
        D.new("0.15"),
        D.new("-0.08")
      ]

      cumulative_values = [
        D.new("100000"),
        D.new("120000"),
        D.new("105600"),
        D.new("132000"),
        D.new("108240"),
        D.new("124476"),
        D.new("114518")
      ]

      assert {:ok, result} = RiskMetricsCalculator.calculate_sterling_ratio(returns, cumulative_values)

      # Should handle high volatility environment
      assert is_struct(result.sterling_ratio, D)
      assert D.compare(result.adjusted_drawdown, D.new("0")) == :gt
    end

    test "rejects negative thresholds" do
      returns = [D.new("0.05"), D.new("0.03")]
      cumulative_values = [D.new("100000"), D.new("105000"), D.new("108150")]

      assert {:error, :invalid_threshold} =
               RiskMetricsCalculator.calculate_sterling_ratio(returns, cumulative_values, D.new("-0.05"))
    end

    test "rejects threshold greater than 100%" do
      returns = [D.new("0.05"), D.new("0.03")]
      cumulative_values = [D.new("100000"), D.new("105000"), D.new("108150")]

      assert {:error, :invalid_threshold} =
               RiskMetricsCalculator.calculate_sterling_ratio(returns, cumulative_values, D.new("1.5"))
    end
  end

  describe "performance tests for new ratios" do
    test "calculates Calmar ratio for 1000 returns under 100ms" do
      # Generate 1000 random returns
      returns = for _ <- 1..1000, do: D.new(Float.to_string(Enum.random(-20..30) / 100))

      # Generate corresponding cumulative values
      {cumulative_values, _} =
        Enum.reduce(returns, {[D.new("100000")], D.new("100000")}, fn return, {acc, current_value} ->
          new_value = D.mult(current_value, D.add(D.new("1"), return))
          {[new_value | acc], new_value}
        end)

      cumulative_values = Enum.reverse(cumulative_values)

      start_time = System.monotonic_time(:millisecond)
      assert {:ok, _result} = RiskMetricsCalculator.calculate_calmar_ratio(returns, cumulative_values)
      end_time = System.monotonic_time(:millisecond)

      execution_time = end_time - start_time
      assert execution_time < 100, "Calmar ratio calculation took #{execution_time}ms, expected < 100ms"
    end

    test "calculates Sterling ratio for 1000 returns under 100ms" do
      # Generate 1000 random returns
      returns = for _ <- 1..1000, do: D.new(Float.to_string(Enum.random(-20..30) / 100))

      # Generate corresponding cumulative values
      {cumulative_values, _} =
        Enum.reduce(returns, {[D.new("100000")], D.new("100000")}, fn return, {acc, current_value} ->
          new_value = D.mult(current_value, D.add(D.new("1"), return))
          {[new_value | acc], new_value}
        end)

      cumulative_values = Enum.reverse(cumulative_values)

      start_time = System.monotonic_time(:millisecond)
      assert {:ok, _result} = RiskMetricsCalculator.calculate_sterling_ratio(returns, cumulative_values)
      end_time = System.monotonic_time(:millisecond)

      execution_time = end_time - start_time
      assert execution_time < 100, "Sterling ratio calculation took #{execution_time}ms, expected < 100ms"
    end
  end

  describe "financial accuracy scenarios" do
    test "handles 1999 dot-com boom scenario" do
      # Tech bubble high returns followed by crash
      boom_returns = [
        D.new("0.30"),
        D.new("0.45"),
        D.new("0.25"),
        D.new("-0.50"),
        D.new("-0.30"),
        D.new("-0.20")
      ]

      assert {:ok, sharpe} = RiskMetricsCalculator.calculate_sharpe_ratio(boom_returns)
      assert {:ok, sortino} = RiskMetricsCalculator.calculate_sortino_ratio(boom_returns)

      # Sortino should be more favorable than Sharpe due to upside focus
      assert D.compare(sortino.sortino_ratio, sharpe.sharpe_ratio) == :gt
    end

    test "handles systematic risk measurement accuracy" do
      # Portfolio with high systematic risk (high beta)
      portfolio_returns = [D.new("0.15"), D.new("-0.08"), D.new("0.20"), D.new("-0.12")]
      market_returns = [D.new("0.10"), D.new("-0.05"), D.new("0.12"), D.new("-0.07")]

      assert {:ok, result} = RiskMetricsCalculator.calculate_information_ratio(portfolio_returns, market_returns)

      # Should capture amplified market movements
      assert D.compare(D.abs(result.active_return), D.new("0.01")) == :gt
    end

    test "validates Calmar vs Sterling ratios in volatile markets" do
      # High volatility scenario that should show difference between ratios
      returns = [D.new("0.25"), D.new("-0.30"), D.new("0.20"), D.new("-0.15"), D.new("0.18")]

      cumulative_values = [
        D.new("100000"),
        D.new("125000"),
        D.new("87500"),
        D.new("105000"),
        D.new("89250"),
        D.new("105315")
      ]

      assert {:ok, calmar_result} = RiskMetricsCalculator.calculate_calmar_ratio(returns, cumulative_values)
      assert {:ok, sterling_result} = RiskMetricsCalculator.calculate_sterling_ratio(returns, cumulative_values)

      # Sterling ratio should typically be higher than Calmar due to threshold adjustment
      # (when drawdown > threshold)
      if D.compare(calmar_result.max_drawdown, D.new("0.10")) == :gt do
        assert D.compare(sterling_result.sterling_ratio, calmar_result.calmar_ratio) == :gt
      end
    end
  end
end
