defmodule Ashfolio.Portfolio.Optimization.PortfolioOptimizer do
  @moduledoc """
  Portfolio optimization using Markowitz mean-variance framework.

  This module provides various portfolio optimization techniques including:
  - Two-asset analytical optimization
  - Multi-asset minimum variance portfolios
  - Maximum Sharpe ratio portfolios
  - Target return optimization

  ## Mathematical Foundation

  Based on Modern Portfolio Theory (Markowitz, 1952), optimizing the trade-off
  between expected return and risk (variance).

  ### Key Formulas

  Portfolio Return: E[Rp] = Σ(wi × E[Ri])
  Portfolio Variance: σp² = w'Σw (where Σ is covariance matrix)
  Sharpe Ratio: S = (E[Rp] - Rf) / σp

  ## References

  - Markowitz, H. (1952). "Portfolio Selection"
  - Merton, R.C. (1972). "An Analytic Derivation of the Efficient Portfolio Frontier"
  """

  alias Ashfolio.Portfolio.Optimization.TwoAssetOptimizer
  alias Decimal, as: D

  @type asset :: %{
          symbol: String.t(),
          expected_return: D.t(),
          volatility: D.t()
        }

  @type optimization_result :: %{
          weights: map(),
          expected_return: D.t(),
          volatility: D.t(),
          sharpe_ratio: D.t() | nil
        }

  @type correlation_matrix :: [[D.t()]]

  @doc """
  Optimizes a two-asset portfolio using analytical solution.

  For two-asset portfolios, we can use closed-form solutions from the
  Markowitz framework, providing exact optimal weights.

  ## Parameters

  - `assets`: List of exactly 2 assets with symbol, expected_return, and volatility
  - `correlation_matrix`: 2x2 correlation matrix

  ## Returns

  `{:ok, result}` with optimal weights, expected return, and volatility
  `{:error, reason}` for invalid inputs
  """
  @spec optimize_two_asset([asset()], correlation_matrix()) ::
          {:ok, optimization_result()} | {:error, atom()}
  def optimize_two_asset(assets, correlation_matrix) do
    with :ok <- validate_two_asset_inputs(assets, correlation_matrix) do
      # For the general optimization, we'll maximize Sharpe ratio with a reasonable risk-free rate
      # This provides a more meaningful optimization than just minimum variance
      # 3% risk-free rate assumption
      risk_free_rate = D.new("0.03")
      maximize_sharpe(assets, correlation_matrix, risk_free_rate)
    end
  end

  @doc """
  Finds the minimum variance portfolio for a set of assets.

  This portfolio has the lowest possible risk (volatility) without
  considering expected returns.

  ## Parameters

  - `assets`: List of assets with expected_return and volatility
  - `correlation_matrix`: NxN correlation matrix where N is number of assets

  ## Returns

  `{:ok, result}` with weights that minimize portfolio variance
  `{:error, reason}` for invalid inputs
  """
  @spec find_minimum_variance([asset()], correlation_matrix()) ::
          {:ok, optimization_result()} | {:error, atom()}
  def find_minimum_variance([], _), do: {:error, :no_assets}
  def find_minimum_variance([_], _), do: {:error, :insufficient_assets}

  def find_minimum_variance(assets, correlation_matrix) when length(assets) == 2 do
    optimize_two_asset_minimum_variance(assets, correlation_matrix)
  end

  def find_minimum_variance(assets, correlation_matrix) when length(assets) == 3 do
    # For 3-asset portfolios, we'll use a simplified approach
    # This is a placeholder implementation that uses equal weighting
    # TODO: Implement proper 3-asset optimization using Lagrange multipliers
    with :ok <- validate_correlation_matrix(correlation_matrix, length(assets)) do
      # For 3 assets, use weights that sum exactly to 1.0
      # Using a slightly different approach to avoid rounding issues
      n = length(assets)

      weights_list =
        if n == 3 do
          # For 3 assets, use exact fractions that sum to 1
          [D.new("0.333333333333333333"), D.new("0.333333333333333333"), D.new("0.333333333333333334")]
        else
          equal_weight = D.div(D.new("1"), D.new(to_string(n)))
          List.duplicate(equal_weight, n)
        end

      weights =
        assets
        |> Enum.zip(weights_list)
        |> Map.new(fn {asset, weight} -> {String.to_atom(String.downcase(asset.symbol)), weight} end)

      # Calculate portfolio volatility with equal weights
      portfolio_vol = calculate_portfolio_volatility(assets, Map.values(weights), correlation_matrix)

      # Calculate expected return
      expected_return =
        assets
        |> Enum.zip(Map.values(weights))
        |> Enum.map(fn {asset, weight} -> D.mult(asset.expected_return, weight) end)
        |> Enum.reduce(D.new("0"), &D.add/2)

      {:ok,
       %{
         weights: weights,
         expected_return: expected_return,
         volatility: portfolio_vol,
         sharpe_ratio: nil
       }}
    end
  end

  def find_minimum_variance(_assets, _correlation_matrix) do
    {:error, :not_implemented_for_n_assets}
  end

  @doc """
  Finds the portfolio with maximum Sharpe ratio.

  The Sharpe ratio measures risk-adjusted return: (E[Rp] - Rf) / σp

  ## Parameters

  - `assets`: List of assets with expected_return and volatility
  - `correlation_matrix`: Correlation matrix
  - `risk_free_rate`: Risk-free rate for Sharpe calculation

  ## Returns

  `{:ok, result}` with weights that maximize Sharpe ratio
  `{:error, reason}` for invalid inputs
  """
  @spec maximize_sharpe([asset()], correlation_matrix(), D.t()) ::
          {:ok, optimization_result()} | {:error, atom()}
  def maximize_sharpe(assets, correlation_matrix, risk_free_rate) when length(assets) == 2 do
    with :ok <- validate_two_asset_inputs(assets, correlation_matrix) do
      # For two assets, we can iterate through different weight combinations
      # to find the maximum Sharpe ratio
      find_max_sharpe_two_assets(assets, correlation_matrix, risk_free_rate)
    end
  end

  def maximize_sharpe(_assets, _correlation_matrix, _risk_free_rate) do
    {:error, :not_implemented_for_n_assets}
  end

  @doc """
  Optimizes portfolio for a target expected return.

  Finds the minimum variance portfolio that achieves the specified
  target return.

  ## Parameters

  - `assets`: List of assets
  - `correlation_matrix`: Correlation matrix
  - `target_return`: Desired portfolio return

  ## Returns

  `{:ok, result}` with optimal weights for target return
  `{:error, :unattainable_return}` if target cannot be achieved
  """
  @spec optimize_target_return([asset()], correlation_matrix(), D.t()) ::
          {:ok, optimization_result()} | {:error, atom()}
  def optimize_target_return(assets, correlation_matrix, target_return) when length(assets) == 2 do
    with :ok <- validate_two_asset_inputs(assets, correlation_matrix),
         :ok <- validate_target_return(assets, target_return) do
      calculate_target_return_weights(assets, correlation_matrix, target_return)
    end
  end

  def optimize_target_return(_assets, _correlation_matrix, _target_return) do
    {:error, :not_implemented_for_n_assets}
  end

  # Private functions

  defp validate_two_asset_inputs(assets, correlation_matrix) do
    cond do
      length(assets) < 2 ->
        {:error, :insufficient_assets}

      length(assets) > 2 ->
        {:error, :too_many_assets_for_two_asset_optimization}

      length(correlation_matrix) != 2 or length(Enum.at(correlation_matrix, 0)) != 2 ->
        {:error, :mismatched_matrix_size}

      true ->
        validate_correlation_matrix(correlation_matrix, 2)
    end
  end

  defp validate_correlation_matrix(matrix, size) do
    cond do
      length(matrix) != size ->
        {:error, :invalid_correlation_matrix}

      not Enum.all?(matrix, &(length(&1) == size)) ->
        {:error, :invalid_correlation_matrix}

      not matrix_symmetric?(matrix) ->
        {:error, :invalid_correlation_matrix}

      not diagonal_ones?(matrix) ->
        {:error, :invalid_correlation_matrix}

      not correlations_in_bounds?(matrix) ->
        {:error, :invalid_correlation_matrix}

      true ->
        :ok
    end
  end

  defp matrix_symmetric?(matrix) do
    size = length(matrix)

    Enum.all?(0..(size - 1), fn i ->
      Enum.all?(0..(size - 1), fn j ->
        elem_ij = matrix |> Enum.at(i) |> Enum.at(j)
        elem_ji = matrix |> Enum.at(j) |> Enum.at(i)
        D.equal?(elem_ij, elem_ji)
      end)
    end)
  end

  defp diagonal_ones?(matrix) do
    matrix
    |> Enum.with_index()
    |> Enum.all?(fn {row, i} ->
      D.equal?(Enum.at(row, i), D.new("1.0"))
    end)
  end

  defp correlations_in_bounds?(matrix) do
    Enum.all?(matrix, fn row ->
      Enum.all?(row, fn corr ->
        D.compare(corr, D.new("-1")) != :lt and
          D.compare(corr, D.new("1")) != :gt
      end)
    end)
  end

  defp optimize_two_asset_minimum_variance(assets, correlation_matrix) do
    [asset_a, asset_b] = assets
    correlation = correlation_matrix |> Enum.at(0) |> Enum.at(1)

    case TwoAssetOptimizer.minimum_variance(asset_a, asset_b, correlation) do
      {:ok, result} ->
        weights = %{
          String.to_atom(String.downcase(asset_a.symbol)) => result.weight_a,
          String.to_atom(String.downcase(asset_b.symbol)) => result.weight_b
        }

        expected_return =
          D.add(
            D.mult(asset_a.expected_return, result.weight_a),
            D.mult(asset_b.expected_return, result.weight_b)
          )

        {:ok,
         %{
           weights: weights,
           expected_return: expected_return,
           volatility: result.portfolio_volatility,
           sharpe_ratio: nil
         }}

      error ->
        error
    end
  end

  defp find_max_sharpe_two_assets(assets, correlation_matrix, risk_free_rate) do
    [asset_a, asset_b] = assets

    # Check if both assets have same expected return as risk-free rate
    excess_a = D.sub(asset_a.expected_return, risk_free_rate)
    excess_b = D.sub(asset_b.expected_return, risk_free_rate)

    if D.equal?(excess_a, D.new("0")) and D.equal?(excess_b, D.new("0")) do
      # Zero excess returns - return minimum variance portfolio
      assets
      |> optimize_two_asset_minimum_variance(correlation_matrix)
      |> case do
        {:ok, result} ->
          {:ok, Map.put(result, :sharpe_ratio, D.new("0"))}

        error ->
          error
      end
    else
      # Search for maximum Sharpe ratio by testing different weight combinations
      # For simplicity, we'll test 101 points from 0% to 100% in asset A
      weights_to_test =
        Enum.map(0..100, fn i -> D.div(D.new(to_string(i)), D.new("100")) end)

      correlation = correlation_matrix |> Enum.at(0) |> Enum.at(1)

      best =
        weights_to_test
        |> Enum.map(fn w_a ->
          w_b = D.sub(D.new("1"), w_a)

          # Calculate portfolio return and volatility
          portfolio_return =
            D.add(
              D.mult(asset_a.expected_return, w_a),
              D.mult(asset_b.expected_return, w_b)
            )

          portfolio_vol =
            calculate_two_asset_volatility(
              w_a,
              w_b,
              asset_a.volatility,
              asset_b.volatility,
              correlation
            )

          excess_return = D.sub(portfolio_return, risk_free_rate)

          sharpe =
            if D.equal?(portfolio_vol, D.new("0")) do
              D.new("0")
            else
              D.div(excess_return, portfolio_vol)
            end

          %{
            weight_a: w_a,
            weight_b: w_b,
            return: portfolio_return,
            volatility: portfolio_vol,
            sharpe: sharpe
          }
        end)
        |> Enum.max_by(fn p -> D.to_float(p.sharpe) end)

      weights = %{
        String.to_atom(String.downcase(asset_a.symbol)) => best.weight_a,
        String.to_atom(String.downcase(asset_b.symbol)) => best.weight_b
      }

      {:ok,
       %{
         weights: weights,
         expected_return: best.return,
         volatility: best.volatility,
         sharpe_ratio: best.sharpe
       }}
    end
  end

  defp calculate_two_asset_volatility(w_a, w_b, sigma_a, sigma_b, correlation) do
    # σp = √(w₁²σ₁² + w₂²σ₂² + 2w₁w₂σ₁σ₂ρ)
    term1 = D.mult(D.mult(w_a, w_a), D.mult(sigma_a, sigma_a))
    term2 = D.mult(D.mult(w_b, w_b), D.mult(sigma_b, sigma_b))

    term3 =
      D.mult(
        D.mult(D.mult(D.new("2"), w_a), w_b),
        D.mult(D.mult(sigma_a, sigma_b), correlation)
      )

    variance = D.add(D.add(term1, term2), term3)
    sqrt_decimal(variance)
  end

  defp validate_target_return(assets, target_return) do
    min_return = assets |> Enum.map(& &1.expected_return) |> Enum.min()
    max_return = assets |> Enum.map(& &1.expected_return) |> Enum.max()

    cond do
      D.compare(target_return, max_return) == :gt ->
        {:error, :unattainable_return}

      D.compare(target_return, min_return) == :lt ->
        {:error, :unattainable_return}

      true ->
        :ok
    end
  end

  defp calculate_target_return_weights(assets, correlation_matrix, target_return) do
    [asset_a, asset_b] = assets

    # For target return R, weight in asset A is:
    # w_a = (R - R_b) / (R_a - R_b)
    return_diff = D.sub(asset_a.expected_return, asset_b.expected_return)

    if D.equal?(return_diff, D.new("0")) do
      # Both assets have same return, any combination works
      # Return minimum variance portfolio
      optimize_two_asset_minimum_variance(assets, correlation_matrix)
    else
      numerator = D.sub(target_return, asset_b.expected_return)
      weight_a = D.div(numerator, return_diff)
      weight_b = D.sub(D.new("1"), weight_a)

      correlation = correlation_matrix |> Enum.at(0) |> Enum.at(1)

      portfolio_vol =
        calculate_two_asset_volatility(
          weight_a,
          weight_b,
          asset_a.volatility,
          asset_b.volatility,
          correlation
        )

      weights = %{
        String.to_atom(String.downcase(asset_a.symbol)) => weight_a,
        String.to_atom(String.downcase(asset_b.symbol)) => weight_b
      }

      {:ok,
       %{
         weights: weights,
         expected_return: target_return,
         volatility: portfolio_vol,
         sharpe_ratio: nil
       }}
    end
  end

  defp calculate_portfolio_volatility(assets, weights, correlation_matrix) do
    # σp² = w'Σw where Σ is the covariance matrix
    # Covariance[i,j] = Correlation[i,j] * σi * σj

    n = length(assets)
    variance = D.new("0")

    variance =
      Enum.reduce(0..(n - 1), variance, fn i, acc ->
        Enum.reduce(0..(n - 1), acc, fn j, inner_acc ->
          asset_i = Enum.at(assets, i)
          asset_j = Enum.at(assets, j)
          weight_i = Enum.at(weights, i)
          weight_j = Enum.at(weights, j)
          corr_ij = correlation_matrix |> Enum.at(i) |> Enum.at(j)

          cov_ij = D.mult(D.mult(asset_i.volatility, asset_j.volatility), corr_ij)
          contribution = D.mult(D.mult(weight_i, weight_j), cov_ij)

          D.add(inner_acc, contribution)
        end)
      end)

    sqrt_decimal(variance)
  end

  # Square root implementation using Newton's method
  defp sqrt_decimal(decimal) do
    if D.equal?(decimal, D.new("0")) do
      D.new("0")
    else
      initial =
        if D.compare(decimal, D.new("1")) == :lt do
          decimal
        else
          D.div(decimal, D.new("2"))
        end

      iterate_sqrt(decimal, initial, 20)
    end
  end

  defp iterate_sqrt(_target, current, 0), do: current

  defp iterate_sqrt(target, current, iterations) do
    quotient = D.div(target, current)
    sum = D.add(current, quotient)
    next = D.div(sum, D.new("2"))

    diff = D.abs(D.sub(next, current))

    if D.compare(diff, D.new("0.00000000001")) == :lt do
      next
    else
      iterate_sqrt(target, next, iterations - 1)
    end
  end
end
