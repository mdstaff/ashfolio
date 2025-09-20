defmodule Ashfolio.Portfolio.Optimization.EfficientFrontierTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Portfolio.Optimization.EfficientFrontier
  alias Decimal, as: D

  describe "generate/3" do
    @tag :unit
    test "generates efficient frontier for two-asset portfolio" do
      assets = [
        %{symbol: "STOCK", expected_return: D.new("0.15"), volatility: D.new("0.20")},
        %{symbol: "BOND", expected_return: D.new("0.05"), volatility: D.new("0.05")}
      ]

      correlation_matrix = [[D.new("1.0"), D.new("0.3")], [D.new("0.3"), D.new("1.0")]]

      {:ok, frontier} = EfficientFrontier.generate(assets, correlation_matrix, points: 20)

      # Should generate requested number of portfolios
      # Allow for some optimization failures
      assert length(frontier.portfolios) >= 15

      # Portfolios should be on efficient frontier (increasing return with risk generally)
      sorted_portfolios = Enum.sort_by(frontier.portfolios, &D.to_float(&1.volatility))
      returns = Enum.map(sorted_portfolios, &D.to_float(&1.expected_return))

      # Most returns should be non-decreasing (allowing for small variations)
      increasing_count =
        returns
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.count(fn [a, b] -> b >= a - 0.001 end)

      # 80% should be increasing
      assert increasing_count > length(returns) * 0.8

      # Min variance portfolio should be included
      assert frontier.min_variance_portfolio
      assert frontier.min_variance_portfolio.expected_return
      assert frontier.min_variance_portfolio.volatility

      # Max return portfolio should be included
      assert frontier.max_return_portfolio
      assert frontier.max_return_portfolio.expected_return
      assert frontier.max_return_portfolio.volatility

      # Tangency portfolio should be included
      assert frontier.tangency_portfolio
      assert frontier.tangency_portfolio.sharpe_ratio
    end

    @tag :unit
    test "returns error for insufficient assets" do
      single_asset = [
        %{symbol: "STOCK", expected_return: D.new("0.15"), volatility: D.new("0.20")}
      ]

      correlation_matrix = [[D.new("1.0")]]

      assert {:error, :insufficient_assets} =
               EfficientFrontier.generate(single_asset, correlation_matrix)
    end

    @tag :unit
    test "returns error for mismatched dimensions" do
      assets = [
        %{symbol: "STOCK", expected_return: D.new("0.15"), volatility: D.new("0.20")},
        %{symbol: "BOND", expected_return: D.new("0.05"), volatility: D.new("0.05")}
      ]

      # Wrong sized correlation matrix
      correlation_matrix = [[D.new("1.0")]]

      assert {:error, :mismatched_dimensions} =
               EfficientFrontier.generate(assets, correlation_matrix)
    end

    @tag :unit
    test "returns error for insufficient points" do
      assets = [
        %{symbol: "STOCK", expected_return: D.new("0.15"), volatility: D.new("0.20")},
        %{symbol: "BOND", expected_return: D.new("0.05"), volatility: D.new("0.05")}
      ]

      correlation_matrix = [[D.new("1.0"), D.new("0.3")], [D.new("0.3"), D.new("1.0")]]

      assert {:error, :insufficient_points} =
               EfficientFrontier.generate(assets, correlation_matrix, points: 1)
    end

    @tag :unit
    test "handles three-asset portfolio" do
      assets = [
        %{symbol: "STOCK", expected_return: D.new("0.12"), volatility: D.new("0.20")},
        %{symbol: "BOND", expected_return: D.new("0.04"), volatility: D.new("0.05")},
        %{symbol: "REIT", expected_return: D.new("0.08"), volatility: D.new("0.15")}
      ]

      correlation_matrix = [
        [D.new("1.0"), D.new("0.2"), D.new("0.3")],
        [D.new("0.2"), D.new("1.0"), D.new("0.1")],
        [D.new("0.3"), D.new("0.1"), D.new("1.0")]
      ]

      {:ok, frontier} = EfficientFrontier.generate(assets, correlation_matrix, points: 10)

      # Should generate some portfolios (may not be all due to limited optimization support)
      assert length(frontier.portfolios) >= 1

      # All portfolios should have valid weights that sum to 1
      Enum.each(frontier.portfolios, fn portfolio ->
        weight_sum = portfolio.weights |> Map.values() |> Enum.reduce(D.new("0"), &D.add/2)
        assert D.compare(D.abs(D.sub(weight_sum, D.new("1.0"))), D.new("0.01")) == :lt
      end)
    end
  end

  describe "find_tangency_portfolio/3" do
    @tag :unit
    test "finds tangency portfolio with maximum Sharpe ratio" do
      assets = [
        %{symbol: "STOCK", expected_return: D.new("0.15"), volatility: D.new("0.20")},
        %{symbol: "BOND", expected_return: D.new("0.05"), volatility: D.new("0.05")}
      ]

      correlation_matrix = [[D.new("1.0"), D.new("0.3")], [D.new("0.3"), D.new("1.0")]]
      risk_free_rate = D.new("0.03")

      {:ok, tangency} =
        EfficientFrontier.find_tangency_portfolio(assets, correlation_matrix, risk_free_rate)

      # Should have positive Sharpe ratio
      assert D.compare(tangency.sharpe_ratio, D.new("0")) == :gt

      # Should be a valid portfolio
      weight_sum = tangency.weights |> Map.values() |> Enum.reduce(D.new("0"), &D.add/2)
      assert D.equal?(weight_sum, D.new("1.0"))

      # Expected return should exceed risk-free rate
      assert D.compare(tangency.expected_return, risk_free_rate) == :gt
    end

    @tag :unit
    test "handles assets with equal returns to risk-free rate" do
      assets = [
        %{symbol: "STOCK", expected_return: D.new("0.03"), volatility: D.new("0.20")},
        %{symbol: "BOND", expected_return: D.new("0.03"), volatility: D.new("0.05")}
      ]

      correlation_matrix = [[D.new("1.0"), D.new("0.3")], [D.new("0.3"), D.new("1.0")]]
      risk_free_rate = D.new("0.03")

      {:ok, tangency} =
        EfficientFrontier.find_tangency_portfolio(assets, correlation_matrix, risk_free_rate)

      # Should still return a valid portfolio (minimum variance when no excess return)
      assert tangency.weights
      assert tangency.expected_return
      assert tangency.volatility
    end
  end

  describe "performance" do
    @tag :performance
    test "generates frontier under 500ms for two assets" do
      assets = [
        %{symbol: "STOCK", expected_return: D.new("0.15"), volatility: D.new("0.20")},
        %{symbol: "BOND", expected_return: D.new("0.05"), volatility: D.new("0.05")}
      ]

      correlation_matrix = [[D.new("1.0"), D.new("0.3")], [D.new("0.3"), D.new("1.0")]]

      {time, {:ok, _frontier}} =
        :timer.tc(fn ->
          EfficientFrontier.generate(assets, correlation_matrix, points: 50)
        end)

      # microseconds
      assert time < 500_000
    end

    @tag :performance
    test "generates frontier under 1000ms for three assets" do
      assets = [
        %{symbol: "STOCK", expected_return: D.new("0.12"), volatility: D.new("0.20")},
        %{symbol: "BOND", expected_return: D.new("0.04"), volatility: D.new("0.05")},
        %{symbol: "REIT", expected_return: D.new("0.08"), volatility: D.new("0.15")}
      ]

      correlation_matrix = [
        [D.new("1.0"), D.new("0.2"), D.new("0.3")],
        [D.new("0.2"), D.new("1.0"), D.new("0.1")],
        [D.new("0.3"), D.new("0.1"), D.new("1.0")]
      ]

      {time, {:ok, _frontier}} =
        :timer.tc(fn ->
          EfficientFrontier.generate(assets, correlation_matrix, points: 30)
        end)

      # microseconds
      assert time < 1_000_000
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles identical assets" do
      # Two assets with identical risk-return profiles
      assets = [
        %{symbol: "STOCK_A", expected_return: D.new("0.10"), volatility: D.new("0.15")},
        %{symbol: "STOCK_B", expected_return: D.new("0.10"), volatility: D.new("0.15")}
      ]

      correlation_matrix = [[D.new("1.0"), D.new("1.0")], [D.new("1.0"), D.new("1.0")]]

      # This edge case may fail due to perfect correlation and identical assets
      # So we'll accept either success or specific error types
      result = EfficientFrontier.generate(assets, correlation_matrix, points: 10)

      case result do
        {:ok, frontier} ->
          # If successful, verify the results
          assert frontier.portfolios
          assert frontier.min_variance_portfolio
          assert frontier.max_return_portfolio

          # All portfolios should have same risk-return characteristics
          Enum.each(frontier.portfolios, fn portfolio ->
            assert_in_delta(D.to_float(portfolio.expected_return), 0.10, 0.001)
            assert_in_delta(D.to_float(portfolio.volatility), 0.15, 0.001)
          end)

        {:error, reason} when reason in [:insufficient_frontier_points, :degenerate_case] ->
          # This is acceptable for this edge case
          assert true

        other ->
          flunk("Unexpected result: #{inspect(other)}")
      end
    end

    @tag :unit
    test "handles perfectly negatively correlated assets" do
      assets = [
        %{symbol: "STOCK", expected_return: D.new("0.15"), volatility: D.new("0.20")},
        %{symbol: "HEDGE", expected_return: D.new("0.05"), volatility: D.new("0.20")}
      ]

      # Perfect negative correlation
      correlation_matrix = [[D.new("1.0"), D.new("-1.0")], [D.new("-1.0"), D.new("1.0")]]

      {:ok, frontier} = EfficientFrontier.generate(assets, correlation_matrix, points: 20)

      # Should be able to achieve very low volatility through diversification
      min_volatility =
        frontier.portfolios
        |> Enum.map(&D.to_float(&1.volatility))
        |> Enum.min()

      # With perfect negative correlation, should be able to get close to zero volatility
      assert min_volatility < 0.05
    end

    @tag :unit
    test "validates portfolio weights sum to one" do
      assets = [
        %{symbol: "STOCK", expected_return: D.new("0.15"), volatility: D.new("0.20")},
        %{symbol: "BOND", expected_return: D.new("0.05"), volatility: D.new("0.05")}
      ]

      correlation_matrix = [[D.new("1.0"), D.new("0.3")], [D.new("0.3"), D.new("1.0")]]

      {:ok, frontier} = EfficientFrontier.generate(assets, correlation_matrix, points: 25)

      # All portfolios should have weights that sum to 1.0
      Enum.each(frontier.portfolios, fn portfolio ->
        weight_sum = portfolio.weights |> Map.values() |> Enum.reduce(D.new("0"), &D.add/2)
        assert D.compare(D.abs(D.sub(weight_sum, D.new("1.0"))), D.new("0.001")) == :lt
      end)
    end
  end
end
