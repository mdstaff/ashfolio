defmodule Ashfolio.Portfolio.Calculators.BetaCalculatorTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Portfolio.Calculators.BetaCalculator
  alias Decimal, as: D

  doctest BetaCalculator

  describe "calculate_beta/2" do
    test "calculates beta of 1.0 for market portfolio (identical returns)" do
      # Identical returns = beta of 1.0
      portfolio_returns = [D.new("0.05"), D.new("-0.02"), D.new("0.07"), D.new("0.03"), D.new("-0.01")]
      market_returns = [D.new("0.05"), D.new("-0.02"), D.new("0.07"), D.new("0.03"), D.new("-0.01")]

      assert {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      assert %{
               beta: beta,
               portfolio_variance: portfolio_variance,
               market_variance: market_variance,
               covariance: covariance
             } = result

      # Beta should be exactly 1.0 for identical returns
      assert D.equal?(beta, D.new("1.0"))
      # Variances should be equal for identical returns
      assert D.equal?(portfolio_variance, market_variance)
      # Covariance equals variance when returns are identical
      assert D.equal?(covariance, market_variance)
    end

    test "calculates beta > 1.0 for high volatility portfolio" do
      # Portfolio with amplified market movements (high beta)
      portfolio_returns = [D.new("0.10"), D.new("-0.04"), D.new("0.14"), D.new("0.06"), D.new("-0.02")]
      market_returns = [D.new("0.05"), D.new("-0.02"), D.new("0.07"), D.new("0.03"), D.new("-0.01")]

      assert {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      # Beta should be > 1.0 (approximately 2.0 for 2x amplification)
      assert D.compare(result.beta, D.new("1.0")) == :gt
      assert D.compare(result.beta, D.new("1.8")) == :gt
      assert D.compare(result.beta, D.new("2.2")) == :lt
    end

    test "calculates beta < 1.0 for defensive portfolio" do
      # Defensive portfolio with muted market movements (low beta)
      portfolio_returns = [D.new("0.025"), D.new("-0.01"), D.new("0.035"), D.new("0.015"), D.new("-0.005")]
      market_returns = [D.new("0.05"), D.new("-0.02"), D.new("0.07"), D.new("0.03"), D.new("-0.01")]

      assert {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      # Beta should be < 1.0 (approximately 0.5 for half the volatility)
      assert D.compare(result.beta, D.new("1.0")) == :lt
      assert D.compare(result.beta, D.new("0.3")) == :gt
      assert D.compare(result.beta, D.new("0.7")) == :lt
    end

    test "calculates beta = 0 for uncorrelated returns" do
      # Portfolio returns uncorrelated with market
      portfolio_returns = [D.new("0.02"), D.new("0.02"), D.new("0.02"), D.new("0.02"), D.new("0.02")]
      market_returns = [D.new("0.05"), D.new("-0.02"), D.new("0.07"), D.new("0.03"), D.new("-0.01")]

      assert {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      # Beta should be close to 0 (uncorrelated)
      assert D.compare(D.abs(result.beta), D.new("0.1")) == :lt
      assert D.equal?(result.covariance, D.new("0"))
    end

    test "calculates negative beta for inverse correlation" do
      # Portfolio moves opposite to market
      portfolio_returns = [D.new("-0.05"), D.new("0.02"), D.new("-0.07"), D.new("-0.03"), D.new("0.01")]
      market_returns = [D.new("0.05"), D.new("-0.02"), D.new("0.07"), D.new("0.03"), D.new("-0.01")]

      assert {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      # Beta should be negative (inverse correlation)
      assert D.compare(result.beta, D.new("0")) == :lt
      assert D.compare(result.beta, D.new("-1.2")) == :gt
      assert D.compare(result.beta, D.new("-0.8")) == :lt
    end

    test "handles insufficient data (< 2 returns)" do
      portfolio_returns = [D.new("0.05")]
      market_returns = [D.new("0.03")]

      assert {:error, :insufficient_data} =
               BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      assert {:error, :insufficient_data} = BetaCalculator.calculate_beta([], [])
    end

    test "handles mismatched return periods" do
      portfolio_returns = [D.new("0.05"), D.new("0.03"), D.new("0.07")]
      market_returns = [D.new("0.04"), D.new("0.02")]

      assert {:error, :mismatched_return_periods} =
               BetaCalculator.calculate_beta(portfolio_returns, market_returns)
    end

    test "handles zero market variance edge case" do
      # Market with no volatility
      portfolio_returns = [D.new("0.05"), D.new("0.03"), D.new("0.07")]
      market_returns = [D.new("0.04"), D.new("0.04"), D.new("0.04")]

      assert {:error, :zero_market_variance} =
               BetaCalculator.calculate_beta(portfolio_returns, market_returns)
    end

    test "handles market crash scenario" do
      # 2008-style market crash with high beta stock
      portfolio_returns = [
        D.new("-0.25"),
        D.new("-0.12"),
        D.new("-0.18"),
        D.new("-0.30"),
        D.new("-0.08"),
        D.new("0.05")
      ]

      market_returns = [
        D.new("-0.15"),
        D.new("-0.08"),
        D.new("-0.12"),
        D.new("-0.20"),
        D.new("-0.05"),
        D.new("0.03")
      ]

      assert {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      # High beta stock amplifies market movements during crash
      assert D.compare(result.beta, D.new("1.0")) == :gt
      assert D.compare(result.beta, D.new("2.0")) == :lt
      assert D.compare(result.covariance, D.new("0")) == :gt
    end

    test "handles high inflation period scenario" do
      # 1970s-style high inflation with defensive stock
      portfolio_returns = [
        D.new("0.08"),
        D.new("-0.02"),
        D.new("0.04"),
        D.new("-0.01"),
        D.new("0.06"),
        D.new("0.02")
      ]

      market_returns = [
        D.new("0.15"),
        D.new("-0.05"),
        D.new("0.08"),
        D.new("-0.03"),
        D.new("0.12"),
        D.new("0.04")
      ]

      assert {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      # Defensive stock with lower beta
      assert D.compare(result.beta, D.new("1.0")) == :lt
      assert D.compare(result.beta, D.new("0.3")) == :gt
    end

    test "validates input data types" do
      invalid_returns = ["0.05", 0.03, "invalid"]
      valid_returns = [D.new("0.05"), D.new("0.03")]

      assert {:error, :invalid_return_format} =
               BetaCalculator.calculate_beta(invalid_returns, valid_returns)

      assert {:error, :invalid_return_format} =
               BetaCalculator.calculate_beta(valid_returns, invalid_returns)
    end
  end

  describe "performance tests" do
    @tag :performance
    test "performance test for 1000 returns < 100ms" do
      # Generate 1000 random returns for performance testing
      portfolio_returns =
        Enum.map(1..1000, fn i ->
          # Generate pseudo-random returns based on index
          base = rem(i * 17 + 23, 200) - 100
          D.div(D.new(base), D.new("1000"))
        end)

      market_returns =
        Enum.map(1..1000, fn i ->
          # Generate correlated market returns
          base = rem(i * 13 + 37, 150) - 75
          D.div(D.new(base), D.new("1000"))
        end)

      # Measure calculation time
      start_time = System.monotonic_time(:millisecond)
      assert {:ok, _result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)
      end_time = System.monotonic_time(:millisecond)

      calculation_time = end_time - start_time

      # Should complete within 100ms
      assert calculation_time < 100,
             "Beta calculation took #{calculation_time}ms, expected < 100ms"
    end
  end

  describe "edge cases and error handling" do
    test "handles zero/nil values gracefully" do
      # Portfolio with zero returns
      portfolio_returns = [D.new("0"), D.new("0"), D.new("0")]
      market_returns = [D.new("0.05"), D.new("-0.02"), D.new("0.03")]

      assert {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      # Zero covariance when portfolio has no variance
      assert D.equal?(result.covariance, D.new("0"))
      assert D.equal?(result.beta, D.new("0"))
    end

    test "handles extreme volatility scenarios" do
      # Very high volatility returns
      portfolio_returns = [
        D.new("0.50"),
        D.new("-0.40"),
        D.new("0.60"),
        D.new("-0.30"),
        D.new("0.45")
      ]

      market_returns = [
        D.new("0.25"),
        D.new("-0.20"),
        D.new("0.30"),
        D.new("-0.15"),
        D.new("0.22")
      ]

      assert {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      # Should handle extreme volatility without errors
      assert is_struct(result.beta, D)
      assert D.compare(result.beta, D.new("1.5")) == :gt
    end

    test "handles negative interest rate environment" do
      # European-style negative rate scenario
      portfolio_returns = [
        D.new("-0.001"),
        D.new("-0.002"),
        D.new("0.001"),
        D.new("-0.0005"),
        D.new("0.0015")
      ]

      market_returns = [
        D.new("-0.0008"),
        D.new("-0.0015"),
        D.new("0.0008"),
        D.new("-0.0003"),
        D.new("0.0012")
      ]

      assert {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      # Should handle negative expected returns
      assert is_struct(result.beta, D)
      assert D.compare(result.beta, D.new("0")) == :gt
    end
  end

  describe "financial accuracy scenarios" do
    test "beta calculation with real market data simulation" do
      # Simulate S&P 500 monthly returns over 2 years
      market_returns = [
        D.new("0.025"),
        D.new("-0.015"),
        D.new("0.035"),
        D.new("0.008"),
        D.new("-0.022"),
        D.new("0.018"),
        D.new("0.042"),
        D.new("-0.009"),
        D.new("0.031"),
        D.new("-0.012"),
        D.new("0.007"),
        D.new("0.019"),
        D.new("-0.028"),
        D.new("0.044"),
        D.new("0.011"),
        D.new("-0.016"),
        D.new("0.027"),
        D.new("0.033"),
        D.new("-0.005"),
        D.new("0.014"),
        D.new("0.021"),
        D.new("-0.013"),
        D.new("0.038"),
        D.new("0.006")
      ]

      # High-beta tech stock (1.5x market sensitivity)
      portfolio_returns =
        Enum.map(market_returns, fn market_return ->
          # 1.5x market sensitivity plus some noise
          amplified = D.mult(market_return, D.new("1.5"))
          noise = D.new("0.002")
          D.add(amplified, noise)
        end)

      assert {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      # Beta should be close to 1.5
      assert D.compare(result.beta, D.new("1.4")) == :gt
      assert D.compare(result.beta, D.new("1.6")) == :lt

      # Should have positive covariance
      assert D.compare(result.covariance, D.new("0")) == :gt
    end

    test "handles systematic risk measurement accuracy" do
      # Portfolio with high systematic risk (high beta)
      portfolio_returns = [D.new("0.15"), D.new("-0.08"), D.new("0.20"), D.new("-0.12")]
      market_returns = [D.new("0.10"), D.new("-0.05"), D.new("0.12"), D.new("-0.07")]

      assert {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      # Should capture amplified market movements
      assert D.compare(result.beta, D.new("1.0")) == :gt
      assert D.compare(result.covariance, D.new("0")) == :gt

      # Verify calculation accuracy
      # Expected covariance and variance calculations
      assert D.compare(result.portfolio_variance, D.new("0")) == :gt
      assert D.compare(result.market_variance, D.new("0")) == :gt
    end

    test "handles 1999 dot-com boom scenario" do
      # Tech bubble high volatility portfolio vs stable market
      portfolio_returns = [
        D.new("0.30"),
        D.new("0.45"),
        D.new("0.25"),
        D.new("-0.50"),
        D.new("-0.30"),
        D.new("-0.20")
      ]

      market_returns = [
        D.new("0.15"),
        D.new("0.22"),
        D.new("0.12"),
        D.new("-0.25"),
        D.new("-0.15"),
        D.new("-0.10")
      ]

      assert {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)

      # Tech stock should have high beta during bubble
      assert D.compare(result.beta, D.new("1.5")) == :gt
      assert D.compare(result.portfolio_variance, result.market_variance) == :gt
    end
  end
end
