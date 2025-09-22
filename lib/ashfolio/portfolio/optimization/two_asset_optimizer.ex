defmodule Ashfolio.Portfolio.Optimization.TwoAssetOptimizer do
  @moduledoc """
  Analytical portfolio optimization for two-asset portfolios.

  ## Mathematical Foundation

  Based on Markowitz Mean-Variance Optimization (1952).

  ### Minimum Variance Portfolio

  For two assets with volatilities σ₁, σ₂ and correlation ρ:

      w₁ = (σ₂² - σ₁σ₂ρ) / (σ₁² + σ₂² - 2σ₁σ₂ρ)
      w₂ = 1 - w₁

  ### Portfolio Volatility

      σp = √(w₁²σ₁² + w₂²σ₂² + 2w₁w₂σ₁σ₂ρ)

  ### Maximum Sharpe Ratio (Tangency Portfolio)

  Maximizes: (E[Rp] - Rf) / σp

  ## Examples

      iex> asset_a = %{volatility: D.new("0.20")}
      iex> asset_b = %{volatility: D.new("0.05")}
      iex> {:ok, result} = TwoAssetOptimizer.minimum_variance(asset_a, asset_b, D.new("0.2"))
      iex> D.compare(result.weight_a, D.new("0")) == :gt
      true

  ## References

  - Markowitz, H. (1952). "Portfolio Selection"
  - Bodie, Kane, Marcus (2021). "Investments" Chapter 7
  - CFA Level III Curriculum (2024). "Portfolio Management"
  """

  alias Decimal, as: D

  @type asset :: %{volatility: D.t()}
  @type correlation :: D.t()
  @type optimization_result :: %{
          weight_a: D.t(),
          weight_b: D.t(),
          portfolio_volatility: D.t()
        }
  @type error :: {:error, atom()}

  @doc """
  Finds the minimum variance portfolio for two assets.

  Returns the optimal weights that minimize portfolio variance given
  the assets' volatilities and their correlation.

  ## Parameters

  - `asset_a`: Map with `:volatility` key (Decimal)
  - `asset_b`: Map with `:volatility` key (Decimal)
  - `correlation`: Correlation coefficient between -1 and 1 (Decimal)

  ## Returns

  `{:ok, result}` where result contains:
  - `:weight_a` - Weight in asset A (0 to 1)
  - `:weight_b` - Weight in asset B (0 to 1, equals 1 - weight_a)
  - `:portfolio_volatility` - Resulting portfolio volatility

  `{:error, reason}` for invalid inputs

  ## Examples

      iex> alias Decimal, as: D
      iex> asset_a = %{volatility: D.new("0.20")}
      iex> asset_b = %{volatility: D.new("0.05")}
      iex> {:ok, result} = Ashfolio.Portfolio.Optimization.TwoAssetOptimizer.minimum_variance(asset_a, asset_b, D.new("0.2"))
      iex> D.compare(D.add(result.weight_a, result.weight_b), D.new("1.0"))
      :eq

  """
  @spec minimum_variance(asset(), asset(), correlation()) ::
          {:ok, optimization_result()} | error()
  def minimum_variance(asset_a, asset_b, correlation) do
    with :ok <- validate_inputs(asset_a, asset_b, correlation) do
      calculate_minimum_variance_weights(asset_a, asset_b, correlation)
    end
  end

  # Private helper functions

  @spec validate_inputs(asset(), asset(), correlation()) :: :ok | error()
  defp validate_inputs(asset_a, asset_b, correlation) do
    cond do
      # Check correlation bounds
      D.compare(correlation, D.new("1")) == :gt ->
        {:error, :invalid_correlation}

      D.compare(correlation, D.new("-1")) == :lt ->
        {:error, :invalid_correlation}

      # Check for negative volatilities
      D.compare(asset_a.volatility, D.new("0")) == :lt ->
        {:error, :invalid_volatility}

      D.compare(asset_b.volatility, D.new("0")) == :lt ->
        {:error, :invalid_volatility}

      # Check for degenerate case (both zero volatility)
      D.equal?(asset_a.volatility, D.new("0")) and D.equal?(asset_b.volatility, D.new("0")) ->
        {:error, :degenerate_case}

      true ->
        :ok
    end
  end

  @spec calculate_minimum_variance_weights(asset(), asset(), correlation()) ::
          {:ok, optimization_result()}
  defp calculate_minimum_variance_weights(asset_a, asset_b, correlation) do
    # Handle special case: one asset has zero volatility
    cond do
      D.equal?(asset_a.volatility, D.new("0")) ->
        # Put 100% in the zero-volatility asset
        {:ok,
         %{
           weight_a: D.new("1.0"),
           weight_b: D.new("0.0"),
           portfolio_volatility: D.new("0")
         }}

      D.equal?(asset_b.volatility, D.new("0")) ->
        # Put 100% in the zero-volatility asset
        {:ok,
         %{
           weight_a: D.new("0.0"),
           weight_b: D.new("1.0"),
           portfolio_volatility: D.new("0")
         }}

      true ->
        # Normal case: calculate optimal weights using minimum variance formula
        calculate_normal_minimum_variance(asset_a, asset_b, correlation)
    end
  end

  @spec calculate_normal_minimum_variance(asset(), asset(), correlation()) ::
          {:ok, optimization_result()}
  defp calculate_normal_minimum_variance(asset_a, asset_b, correlation) do
    sigma_a = asset_a.volatility
    sigma_b = asset_b.volatility

    # Calculate variance terms
    sigma_a_sq = D.mult(sigma_a, sigma_a)
    sigma_b_sq = D.mult(sigma_b, sigma_b)
    sigma_ab = D.mult(D.mult(sigma_a, sigma_b), correlation)

    # Special case: perfect positive correlation
    if D.equal?(correlation, D.new("1.0")) do
      # Choose 100% of the lower volatility asset
      if D.compare(sigma_a, sigma_b) == :lt do
        {:ok,
         %{
           weight_a: D.new("1.0"),
           weight_b: D.new("0.0"),
           portfolio_volatility: sigma_a
         }}
      else
        {:ok,
         %{
           weight_a: D.new("0.0"),
           weight_b: D.new("1.0"),
           portfolio_volatility: sigma_b
         }}
      end
    else
      # General minimum variance formula: w₁ = (σ₂² - σ₁σ₂ρ) / (σ₁² + σ₂² - 2σ₁σ₂ρ)
      numerator = D.sub(sigma_b_sq, sigma_ab)
      denominator = D.sub(D.add(sigma_a_sq, sigma_b_sq), D.mult(D.new("2"), sigma_ab))

      weight_a = D.div(numerator, denominator)
      weight_b = D.sub(D.new("1.0"), weight_a)

      # Calculate portfolio volatility: σp = √(w₁²σ₁² + w₂²σ₂² + 2w₁w₂σ₁σ₂ρ)
      portfolio_variance = calculate_portfolio_variance(weight_a, weight_b, sigma_a, sigma_b, correlation)
      portfolio_volatility = sqrt_decimal(portfolio_variance)

      {:ok,
       %{
         weight_a: weight_a,
         weight_b: weight_b,
         portfolio_volatility: portfolio_volatility
       }}
    end
  end

  @spec calculate_portfolio_variance(D.t(), D.t(), D.t(), D.t(), D.t()) :: D.t()
  defp calculate_portfolio_variance(weight_a, weight_b, sigma_a, sigma_b, correlation) do
    # σp² = w₁²σ₁² + w₂²σ₂² + 2w₁w₂σ₁σ₂ρ
    term1 = D.mult(D.mult(weight_a, weight_a), D.mult(sigma_a, sigma_a))
    term2 = D.mult(D.mult(weight_b, weight_b), D.mult(sigma_b, sigma_b))

    term3 =
      D.mult(
        D.mult(D.mult(D.new("2"), weight_a), weight_b),
        D.mult(D.mult(sigma_a, sigma_b), correlation)
      )

    D.add(D.add(term1, term2), term3)
  end

  @spec sqrt_decimal(D.t()) :: D.t()
  defp sqrt_decimal(decimal) do
    # Handle special case of zero
    if D.equal?(decimal, D.new("0")) do
      D.new("0")
    else
      # For very small numbers, use a better initial guess
      initial =
        if D.compare(decimal, D.new("1")) == :lt do
          decimal
        else
          D.div(decimal, D.new("2"))
        end

      # Perform more iterations for better precision
      iterate_sqrt(decimal, initial, 20)
    end
  end

  @spec iterate_sqrt(D.t(), D.t(), non_neg_integer()) :: D.t()
  defp iterate_sqrt(_target, current, 0), do: current

  defp iterate_sqrt(target, current, iterations) do
    # Newton's formula: next = (current + target/current) / 2
    quotient = D.div(target, current)
    sum = D.add(current, quotient)
    next = D.div(sum, D.new("2"))

    # Check for convergence with higher precision
    diff = D.abs(D.sub(next, current))

    if D.compare(diff, D.new("0.00000000001")) == :lt do
      next
    else
      iterate_sqrt(target, next, iterations - 1)
    end
  end
end
