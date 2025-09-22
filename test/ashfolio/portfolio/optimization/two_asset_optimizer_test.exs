defmodule Ashfolio.Portfolio.Optimization.TwoAssetOptimizerTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Portfolio.Optimization.TwoAssetOptimizer
  alias Decimal, as: D

  doctest TwoAssetOptimizer

  describe "minimum_variance/3" do
    test "finds minimum variance portfolio for two assets" do
      asset_a = %{symbol: "STOCK", volatility: D.new("0.20")}
      asset_b = %{symbol: "BOND", volatility: D.new("0.05")}
      correlation = D.new("0.2")

      {:ok, result} = TwoAssetOptimizer.minimum_variance(asset_a, asset_b, correlation)

      # Formula: w1 = (σ₂² - σ₁σ₂ρ) / (σ₁² + σ₂² - 2σ₁σ₂ρ)
      # Expected: ~1.3% Stock, 98.7% Bond (heavily favor lower volatility bond)
      assert_in_delta(D.to_float(result.weight_a), 0.013, 0.001)
      assert_in_delta(D.to_float(result.weight_b), 0.987, 0.001)
    end

    test "calculates portfolio volatility correctly" do
      asset_a = %{symbol: "STOCK", volatility: D.new("0.20")}
      asset_b = %{symbol: "BOND", volatility: D.new("0.05")}
      correlation = D.new("0.2")

      {:ok, result} = TwoAssetOptimizer.minimum_variance(asset_a, asset_b, correlation)

      # σp² = w₁²σ₁² + w₂²σ₂² + 2w₁w₂σ₁σ₂ρ
      # Expected portfolio volatility with optimal weights should be minimized
      assert_in_delta(D.to_float(result.portfolio_volatility), 0.04994, 0.001)
    end

    test "handles perfectly correlated assets (ρ = 1)" do
      asset_a = %{symbol: "STOCK", volatility: D.new("0.20")}
      asset_b = %{symbol: "BOND", volatility: D.new("0.05")}

      {:ok, result} = TwoAssetOptimizer.minimum_variance(asset_a, asset_b, D.new("1.0"))

      # With ρ = 1, choose 100% lower volatility asset
      assert D.equal?(result.weight_b, D.new("1.0"))
      assert D.equal?(result.weight_a, D.new("0.0"))
      assert D.equal?(result.portfolio_volatility, D.new("0.05"))
    end

    test "achieves zero variance with perfect negative correlation (ρ = -1)" do
      asset_a = %{symbol: "STOCK", volatility: D.new("0.20")}
      asset_b = %{symbol: "BOND", volatility: D.new("0.05")}

      {:ok, result} = TwoAssetOptimizer.minimum_variance(asset_a, asset_b, D.new("-1.0"))

      # Can achieve σp = 0 with w₁ = σ₂/(σ₁ + σ₂)
      expected_weight_a = D.div(D.new("0.05"), D.add(D.new("0.20"), D.new("0.05")))
      assert_in_delta(D.to_float(result.weight_a), D.to_float(expected_weight_a), 0.001)
      assert_in_delta(D.to_float(result.portfolio_volatility), 0.0, 0.0001)
    end

    test "handles independent assets (ρ = 0)" do
      asset_a = %{symbol: "STOCK", volatility: D.new("0.20")}
      asset_b = %{symbol: "BOND", volatility: D.new("0.05")}

      {:ok, result} = TwoAssetOptimizer.minimum_variance(asset_a, asset_b, D.new("0"))

      # Simplified formula when ρ = 0: w₁ = σ₂²/(σ₁² + σ₂²)
      # 0.04
      sigma_a_sq = D.mult(D.new("0.20"), D.new("0.20"))
      # 0.0025
      sigma_b_sq = D.mult(D.new("0.05"), D.new("0.05"))
      expected_weight_a = D.div(sigma_b_sq, D.add(sigma_a_sq, sigma_b_sq))

      assert_in_delta(D.to_float(result.weight_a), D.to_float(expected_weight_a), 0.001)
    end
  end

  describe "validate_inputs/3" do
    test "rejects correlation > 1" do
      asset_a = %{volatility: D.new("0.20")}
      asset_b = %{volatility: D.new("0.05")}

      assert {:error, :invalid_correlation} =
               TwoAssetOptimizer.minimum_variance(asset_a, asset_b, D.new("1.1"))
    end

    test "rejects correlation < -1" do
      asset_a = %{volatility: D.new("0.20")}
      asset_b = %{volatility: D.new("0.05")}

      assert {:error, :invalid_correlation} =
               TwoAssetOptimizer.minimum_variance(asset_a, asset_b, D.new("-1.1"))
    end

    test "rejects negative volatility" do
      asset_a = %{volatility: D.new("-0.10")}
      asset_b = %{volatility: D.new("0.05")}

      assert {:error, :invalid_volatility} =
               TwoAssetOptimizer.minimum_variance(asset_a, asset_b, D.new("0.3"))
    end

    test "rejects zero volatility for both assets" do
      asset_a = %{volatility: D.new("0")}
      asset_b = %{volatility: D.new("0")}

      assert {:error, :degenerate_case} =
               TwoAssetOptimizer.minimum_variance(asset_a, asset_b, D.new("0.3"))
    end

    test "handles one zero-volatility asset" do
      asset_a = %{volatility: D.new("0")}
      asset_b = %{volatility: D.new("0.05")}

      {:ok, result} = TwoAssetOptimizer.minimum_variance(asset_a, asset_b, D.new("0.3"))

      # Should put 100% in the zero-volatility asset
      assert D.equal?(result.weight_a, D.new("1.0"))
      assert D.equal?(result.weight_b, D.new("0.0"))
      assert D.equal?(result.portfolio_volatility, D.new("0"))
    end

    test "validates weight sum equals 1" do
      asset_a = %{volatility: D.new("0.20")}
      asset_b = %{volatility: D.new("0.05")}
      correlation = D.new("0.3")

      {:ok, result} = TwoAssetOptimizer.minimum_variance(asset_a, asset_b, correlation)

      sum = D.add(result.weight_a, result.weight_b)
      assert D.equal?(sum, D.new("1.0"))
    end
  end

  describe "performance" do
    @tag :performance
    test "two-asset minimum variance < 5ms" do
      asset_a = %{volatility: D.new("0.20")}
      asset_b = %{volatility: D.new("0.05")}
      correlation = D.new("0.3")

      {time, {:ok, _}} =
        :timer.tc(fn ->
          TwoAssetOptimizer.minimum_variance(asset_a, asset_b, correlation)
        end)

      # microseconds
      assert time < 5_000
    end

    @tag :performance
    test "100 optimizations < 100ms" do
      asset_a = %{volatility: D.new("0.20")}
      asset_b = %{volatility: D.new("0.05")}
      correlation = D.new("0.3")

      {time, _} =
        :timer.tc(fn ->
          for _ <- 1..100 do
            TwoAssetOptimizer.minimum_variance(asset_a, asset_b, correlation)
          end
        end)

      assert time < 100_000
    end
  end

  describe "numerical_stability" do
    test "handles near-zero volatility difference" do
      asset_a = %{volatility: D.new("0.1000")}
      asset_b = %{volatility: D.new("0.1001")}

      {:ok, result} = TwoAssetOptimizer.minimum_variance(asset_a, asset_b, D.new("0.5"))

      # Should be approximately equal weights
      assert_in_delta(D.to_float(result.weight_a), 0.5, 0.1)
    end

    test "handles very high correlation (0.9999)" do
      asset_a = %{volatility: D.new("0.20")}
      asset_b = %{volatility: D.new("0.05")}

      {:ok, result} = TwoAssetOptimizer.minimum_variance(asset_a, asset_b, D.new("0.9999"))

      # Should heavily favor lower volatility
      assert D.compare(result.weight_b, D.new("0.99")) == :gt
    end

    test "handles very low correlation (-0.9999)" do
      asset_a = %{volatility: D.new("0.20")}
      asset_b = %{volatility: D.new("0.05")}

      {:ok, result} = TwoAssetOptimizer.minimum_variance(asset_a, asset_b, D.new("-0.9999"))

      # Near-zero portfolio volatility possible
      assert D.compare(result.portfolio_volatility, D.new("0.001")) == :lt
    end
  end
end
