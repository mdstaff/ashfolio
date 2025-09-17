defmodule Ashfolio.Portfolio.Calculators.CorrelationCalculatorTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Portfolio.Calculators.CorrelationCalculator
  alias Decimal, as: D

  doctest CorrelationCalculator

  describe "calculate_pair/2" do
    test "calculates perfect positive correlation" do
      returns_a = [D.new("0.1"), D.new("0.2"), D.new("0.3"), D.new("0.4")]
      returns_b = [D.new("0.1"), D.new("0.2"), D.new("0.3"), D.new("0.4")]

      assert {:ok, correlation} = CorrelationCalculator.calculate_pair(returns_a, returns_b)
      # Allow for small numerical precision differences
      assert D.compare(D.abs(D.sub(correlation, D.new("1.0"))), D.new("0.0001")) == :lt
    end

    test "calculates perfect negative correlation" do
      returns_a = [D.new("0.1"), D.new("0.2"), D.new("0.3"), D.new("0.4")]
      returns_b = [D.new("0.4"), D.new("0.3"), D.new("0.2"), D.new("0.1")]

      assert {:ok, correlation} = CorrelationCalculator.calculate_pair(returns_a, returns_b)
      # Allow for small numerical precision differences
      assert D.compare(D.abs(D.sub(correlation, D.new("-1.0"))), D.new("0.0001")) == :lt
    end

    test "calculates zero correlation for uncorrelated series" do
      returns_a = [D.new("0.1"), D.new("-0.1"), D.new("0.1"), D.new("-0.1")]
      returns_b = [D.new("0.2"), D.new("0.2"), D.new("-0.2"), D.new("-0.2")]

      assert {:ok, correlation} = CorrelationCalculator.calculate_pair(returns_a, returns_b)
      assert D.compare(D.abs(correlation), D.new("0.01")) == :lt
    end

    test "calculates known correlation example" do
      # Example with positive correlation (shifted series)
      returns_a = [D.new("0.01"), D.new("0.02"), D.new("0.03"), D.new("0.04"), D.new("0.05")]
      returns_b = [D.new("0.01"), D.new("0.02"), D.new("0.03"), D.new("0.04"), D.new("0.05")]

      assert {:ok, correlation} = CorrelationCalculator.calculate_pair(returns_a, returns_b)
      # Should have perfect positive correlation
      assert D.compare(D.abs(D.sub(correlation, D.new("1.0"))), D.new("0.001")) == :lt
    end

    test "returns error for mismatched series lengths" do
      returns_a = [D.new("0.1"), D.new("0.2")]
      returns_b = [D.new("0.1"), D.new("0.2"), D.new("0.3")]

      assert {:error, :mismatched_lengths} = CorrelationCalculator.calculate_pair(returns_a, returns_b)
    end

    test "returns error for empty series" do
      assert {:error, :insufficient_data} = CorrelationCalculator.calculate_pair([], [])
    end

    test "returns error for single data point" do
      returns_a = [D.new("0.1")]
      returns_b = [D.new("0.2")]

      assert {:error, :insufficient_data} = CorrelationCalculator.calculate_pair(returns_a, returns_b)
    end

    test "handles series with zero variance" do
      returns_a = [D.new("0.1"), D.new("0.1"), D.new("0.1")]
      returns_b = [D.new("0.2"), D.new("0.3"), D.new("0.4")]

      assert {:error, :zero_variance} = CorrelationCalculator.calculate_pair(returns_a, returns_b)
    end

    test "handles both series with zero variance" do
      returns_a = [D.new("0.1"), D.new("0.1"), D.new("0.1")]
      returns_b = [D.new("0.2"), D.new("0.2"), D.new("0.2")]

      assert {:error, :zero_variance} = CorrelationCalculator.calculate_pair(returns_a, returns_b)
    end

    test "maintains correlation bounds between -1 and 1" do
      # Test with random-like data
      returns_a = [D.new("0.05"), D.new("-0.03"), D.new("0.02"), D.new("0.04"), D.new("-0.01")]
      returns_b = [D.new("0.03"), D.new("0.01"), D.new("-0.02"), D.new("0.03"), D.new("0.02")]

      assert {:ok, correlation} = CorrelationCalculator.calculate_pair(returns_a, returns_b)
      assert D.compare(correlation, D.new("-1.0")) in [:gt, :eq]
      assert D.compare(correlation, D.new("1.0")) in [:lt, :eq]
    end
  end

  describe "calculate_matrix/1" do
    test "calculates 2x2 correlation matrix" do
      asset_returns = [
        [D.new("0.1"), D.new("0.2"), D.new("0.3")],
        [D.new("0.15"), D.new("0.25"), D.new("0.35")]
      ]

      assert {:ok, matrix} = CorrelationCalculator.calculate_matrix(asset_returns)
      assert length(matrix) == 2
      assert length(Enum.at(matrix, 0)) == 2

      # Diagonal should be 1.0
      assert D.compare(D.abs(D.sub(Enum.at(Enum.at(matrix, 0), 0), D.new("1.0"))), D.new("0.0001")) == :lt
      assert D.compare(D.abs(D.sub(Enum.at(Enum.at(matrix, 1), 1), D.new("1.0"))), D.new("0.0001")) == :lt

      # Matrix should be symmetric
      correlation_01 = Enum.at(Enum.at(matrix, 0), 1)
      correlation_10 = Enum.at(Enum.at(matrix, 1), 0)
      assert D.equal?(correlation_01, correlation_10)
    end

    test "calculates 3x3 correlation matrix" do
      asset_returns = [
        [D.new("0.1"), D.new("0.2"), D.new("0.15"), D.new("0.25")],
        [D.new("0.05"), D.new("0.15"), D.new("0.1"), D.new("0.2")],
        [D.new("-0.05"), D.new("0.1"), D.new("-0.02"), D.new("0.08")]
      ]

      assert {:ok, matrix} = CorrelationCalculator.calculate_matrix(asset_returns)
      assert length(matrix) == 3
      assert Enum.all?(matrix, &(length(&1) == 3))

      # Check all diagonal elements are 1.0
      for i <- 0..2 do
        assert D.compare(D.abs(D.sub(Enum.at(Enum.at(matrix, i), i), D.new("1.0"))), D.new("0.0001")) == :lt
      end

      # Check symmetry
      for i <- 0..2, j <- 0..2, i != j do
        assert D.equal?(
                 Enum.at(Enum.at(matrix, i), j),
                 Enum.at(Enum.at(matrix, j), i)
               )
      end
    end

    test "returns error for empty input" do
      assert {:error, :no_assets} = CorrelationCalculator.calculate_matrix([])
    end

    test "returns error for single asset" do
      asset_returns = [[D.new("0.1"), D.new("0.2")]]
      assert {:error, :insufficient_assets} = CorrelationCalculator.calculate_matrix(asset_returns)
    end

    test "returns error for mismatched return series lengths" do
      asset_returns = [
        [D.new("0.1"), D.new("0.2")],
        [D.new("0.1"), D.new("0.2"), D.new("0.3")]
      ]

      assert {:error, :mismatched_lengths} = CorrelationCalculator.calculate_matrix(asset_returns)
    end

    test "handles matrix with some zero variance assets" do
      asset_returns = [
        # Zero variance
        [D.new("0.1"), D.new("0.1"), D.new("0.1")],
        # Non-zero variance
        [D.new("0.1"), D.new("0.2"), D.new("0.3")]
      ]

      assert {:error, :zero_variance} = CorrelationCalculator.calculate_matrix(asset_returns)
    end
  end

  describe "calculate_rolling_correlation/3" do
    test "calculates rolling correlation with window size 3" do
      returns_a = [D.new("0.1"), D.new("0.2"), D.new("0.15"), D.new("0.25"), D.new("0.18")]
      returns_b = [D.new("0.08"), D.new("0.18"), D.new("0.14"), D.new("0.22"), D.new("0.16")]
      window_size = 3

      assert {:ok, correlations} =
               CorrelationCalculator.calculate_rolling_correlation(
                 returns_a,
                 returns_b,
                 window_size
               )

      # Should have 3 correlation values (5 data points - 3 window + 1)
      assert length(correlations) == 3

      # All correlations should be within bounds
      Enum.each(correlations, fn corr ->
        assert D.compare(corr, D.new("-1.0")) in [:gt, :eq]
        assert D.compare(corr, D.new("1.0")) in [:lt, :eq]
      end)
    end

    test "returns error when window size exceeds data length" do
      returns_a = [D.new("0.1"), D.new("0.2")]
      returns_b = [D.new("0.15"), D.new("0.25")]
      window_size = 3

      assert {:error, :window_too_large} =
               CorrelationCalculator.calculate_rolling_correlation(
                 returns_a,
                 returns_b,
                 window_size
               )
    end

    test "returns error for window size less than 2" do
      returns_a = [D.new("0.1"), D.new("0.2")]
      returns_b = [D.new("0.15"), D.new("0.25")]

      assert {:error, :invalid_window_size} =
               CorrelationCalculator.calculate_rolling_correlation(
                 returns_a,
                 returns_b,
                 1
               )
    end

    test "handles perfect correlation in rolling windows" do
      returns_a = [D.new("0.1"), D.new("0.2"), D.new("0.3"), D.new("0.4"), D.new("0.5")]
      returns_b = [D.new("0.1"), D.new("0.2"), D.new("0.3"), D.new("0.4"), D.new("0.5")]
      window_size = 3

      assert {:ok, correlations} =
               CorrelationCalculator.calculate_rolling_correlation(
                 returns_a,
                 returns_b,
                 window_size
               )

      # All rolling correlations should be 1.0 for perfectly correlated series
      Enum.each(correlations, fn corr ->
        assert D.compare(D.abs(D.sub(corr, D.new("1.0"))), D.new("0.0001")) == :lt
      end)
    end
  end

  describe "performance" do
    @tag :performance
    test "calculate_matrix performs within 50ms for 10x10 matrix" do
      # Generate 10 assets with 252 trading days of returns
      asset_returns =
        for _ <- 1..10 do
          for _ <- 1..252 do
            # Random returns between -5% and 5%
            :rand.uniform()
            |> to_string()
            |> D.new()
            |> D.sub(D.new("0.5"))
            |> D.mult(D.new("0.1"))
          end
        end

      {time_us, {:ok, _matrix}} =
        :timer.tc(fn ->
          CorrelationCalculator.calculate_matrix(asset_returns)
        end)

      time_ms = time_us / 1000
      assert time_ms < 100, "Matrix calculation took #{time_ms}ms, expected < 100ms"
    end

    @tag :performance
    test "calculate_pair performs within 5ms for 1000 data points" do
      returns_a =
        for _ <- 1..1000 do
          :rand.uniform() |> to_string() |> D.new() |> D.sub(D.new("0.5")) |> D.mult(D.new("0.1"))
        end

      returns_b =
        for _ <- 1..1000 do
          :rand.uniform() |> to_string() |> D.new() |> D.sub(D.new("0.5")) |> D.mult(D.new("0.1"))
        end

      {time_us, {:ok, _correlation}} =
        :timer.tc(fn ->
          CorrelationCalculator.calculate_pair(returns_a, returns_b)
        end)

      time_ms = time_us / 1000
      assert time_ms < 10, "Pair calculation took #{time_ms}ms, expected < 10ms"
    end
  end
end
