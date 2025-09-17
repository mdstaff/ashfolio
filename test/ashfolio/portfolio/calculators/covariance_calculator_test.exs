defmodule Ashfolio.Portfolio.Calculators.CovarianceCalculatorTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Portfolio.Calculators.CovarianceCalculator
  alias Decimal, as: D

  doctest CovarianceCalculator

  describe "calculate_pair/2" do
    test "calculates covariance for perfectly correlated series" do
      returns_a = [D.new("0.1"), D.new("0.2"), D.new("0.3"), D.new("0.4")]
      returns_b = [D.new("0.1"), D.new("0.2"), D.new("0.3"), D.new("0.4")]

      assert {:ok, covariance} = CovarianceCalculator.calculate_pair(returns_a, returns_b)
      # Covariance of identical series equals variance
      assert D.compare(covariance, D.new("0")) == :gt
    end

    test "calculates covariance for negatively correlated series" do
      returns_a = [D.new("0.1"), D.new("0.2"), D.new("0.3"), D.new("0.4")]
      returns_b = [D.new("0.4"), D.new("0.3"), D.new("0.2"), D.new("0.1")]

      assert {:ok, covariance} = CovarianceCalculator.calculate_pair(returns_a, returns_b)
      # Negative correlation should give negative covariance
      assert D.compare(covariance, D.new("0")) == :lt
    end

    test "calculates known covariance example" do
      # Example from finance textbook
      returns_a = [D.new("0.02"), D.new("0.03"), D.new("-0.01"), D.new("0.04")]
      returns_b = [D.new("0.01"), D.new("0.04"), D.new("-0.02"), D.new("0.03")]

      assert {:ok, covariance} = CovarianceCalculator.calculate_pair(returns_a, returns_b)
      # Should be positive
      assert D.compare(covariance, D.new("0")) == :gt
    end

    test "returns error for mismatched series lengths" do
      returns_a = [D.new("0.1"), D.new("0.2")]
      returns_b = [D.new("0.1"), D.new("0.2"), D.new("0.3")]

      assert {:error, :mismatched_lengths} = CovarianceCalculator.calculate_pair(returns_a, returns_b)
    end

    test "returns error for empty series" do
      assert {:error, :insufficient_data} = CovarianceCalculator.calculate_pair([], [])
    end

    test "returns error for single data point" do
      returns_a = [D.new("0.1")]
      returns_b = [D.new("0.2")]

      assert {:error, :insufficient_data} = CovarianceCalculator.calculate_pair(returns_a, returns_b)
    end
  end

  describe "calculate_matrix/1" do
    test "calculates 2x2 covariance matrix" do
      asset_returns = [
        [D.new("0.1"), D.new("0.2"), D.new("0.3")],
        [D.new("0.15"), D.new("0.25"), D.new("0.35")]
      ]

      assert {:ok, matrix} = CovarianceCalculator.calculate_matrix(asset_returns)
      assert length(matrix) == 2
      assert length(Enum.at(matrix, 0)) == 2

      # Matrix should be symmetric
      cov_01 = Enum.at(Enum.at(matrix, 0), 1)
      cov_10 = Enum.at(Enum.at(matrix, 1), 0)
      assert D.equal?(cov_01, cov_10)

      # Diagonal elements should be variances (positive)
      assert D.compare(Enum.at(Enum.at(matrix, 0), 0), D.new("0")) == :gt
      assert D.compare(Enum.at(Enum.at(matrix, 1), 1), D.new("0")) == :gt
    end

    test "calculates 3x3 covariance matrix" do
      asset_returns = [
        [D.new("0.1"), D.new("0.2"), D.new("0.15"), D.new("0.25")],
        [D.new("0.05"), D.new("0.15"), D.new("0.1"), D.new("0.2")],
        [D.new("-0.05"), D.new("0.1"), D.new("-0.02"), D.new("0.08")]
      ]

      assert {:ok, matrix} = CovarianceCalculator.calculate_matrix(asset_returns)
      assert length(matrix) == 3
      assert Enum.all?(matrix, &(length(&1) == 3))

      # Check symmetry
      for i <- 0..2, j <- 0..2, i != j do
        assert D.equal?(
                 Enum.at(Enum.at(matrix, i), j),
                 Enum.at(Enum.at(matrix, j), i)
               )
      end
    end

    test "returns error for empty input" do
      assert {:error, :no_assets} = CovarianceCalculator.calculate_matrix([])
    end

    test "returns error for single asset" do
      asset_returns = [[D.new("0.1"), D.new("0.2")]]
      assert {:error, :insufficient_assets} = CovarianceCalculator.calculate_matrix(asset_returns)
    end

    test "returns error for mismatched return series lengths" do
      asset_returns = [
        [D.new("0.1"), D.new("0.2")],
        [D.new("0.1"), D.new("0.2"), D.new("0.3")]
      ]

      assert {:error, :mismatched_lengths} = CovarianceCalculator.calculate_matrix(asset_returns)
    end
  end

  describe "performance" do
    @tag :performance
    test "calculate_matrix performs within 50ms for 10x10 matrix" do
      # Generate 10 assets with 252 trading days of returns
      asset_returns =
        for _ <- 1..10 do
          for _ <- 1..252 do
            :rand.uniform()
            |> to_string()
            |> D.new()
            |> D.sub(D.new("0.5"))
            |> D.mult(D.new("0.1"))
          end
        end

      {time_us, {:ok, _matrix}} =
        :timer.tc(fn ->
          CovarianceCalculator.calculate_matrix(asset_returns)
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

      {time_us, {:ok, _covariance}} =
        :timer.tc(fn ->
          CovarianceCalculator.calculate_pair(returns_a, returns_b)
        end)

      time_ms = time_us / 1000
      assert time_ms < 10, "Pair calculation took #{time_ms}ms, expected < 10ms"
    end
  end
end
