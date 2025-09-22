defmodule Ashfolio.Portfolio.Calculators.BetaCalculator do
  @moduledoc """
  Professional beta calculation for portfolio risk assessment and systematic risk analysis.

  Beta measures a portfolio's sensitivity to market movements, providing essential insights
  for risk management and portfolio construction. This implementation follows industry
  standards used by financial institutions and portfolio managers.

  ## Beta Interpretation

  - Beta = 1.0: Portfolio moves with the market
  - Beta > 1.0: Portfolio is more volatile than the market (aggressive)
  - Beta < 1.0: Portfolio is less volatile than the market (defensive)
  - Beta = 0.0: Portfolio is uncorrelated with the market
  - Beta < 0.0: Portfolio moves opposite to the market (inverse correlation)

  ## Mathematical Formula

      Beta = Covariance(Portfolio Returns, Market Returns) / Variance(Market Returns)

  Where:
  - Covariance measures how portfolio and market returns move together
  - Market Variance measures the volatility of market returns
  - All calculations use Decimal precision for financial accuracy

  ## References

  - Sharpe, W.F. (1964). "Capital Asset Pricing Model"
  - Treynor, J.L. (1961). "Market Value, Time, and Risk"
  - CFA Institute Standards for risk measurement
  - Modern Portfolio Theory (Markowitz, 1952)

  ## Edge Cases Handled

  - Zero market variance (constant market returns)
  - Mismatched return periods
  - Insufficient data points
  - Extreme volatility scenarios
  - Negative return environments
  """

  alias Ashfolio.Financial.DecimalHelpers, as: DH
  alias Ashfolio.Financial.Mathematical
  alias Decimal, as: D

  require Logger

  # Type definitions
  @type returns :: list(D.t())
  @type beta_calculation_result ::
          {:ok,
           %{
             beta: D.t(),
             covariance: D.t(),
             portfolio_variance: D.t(),
             market_variance: D.t(),
             portfolio_mean: D.t(),
             market_mean: D.t()
           }}
          | {:error, atom()}

  @doc """
  Calculates portfolio beta relative to market benchmark.

  Beta measures systematic risk - the portion of portfolio risk that cannot be
  diversified away. Essential for CAPM calculations and risk-adjusted returns.

  ## Parameters

    - portfolio_returns: List of Decimal - Portfolio returns (e.g., monthly or daily)
    - market_returns: List of Decimal - Market benchmark returns (same frequency)

  ## Returns

    - {:ok, %{beta: Decimal, covariance: Decimal, portfolio_variance: Decimal, market_variance: Decimal}}
    - {:error, reason} - Error with descriptive reason

  ## Examples

      iex> portfolio_returns = [D.new("0.05"), D.new("0.03"), D.new("0.07")]
      iex> market_returns = [D.new("0.05"), D.new("0.03"), D.new("0.07")]
      iex> {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)
      iex> D.equal?(result.beta, D.new("1.0"))
      true

      iex> portfolio_returns = [D.new("0.10"), D.new("0.06"), D.new("0.14")]
      iex> market_returns = [D.new("0.05"), D.new("0.03"), D.new("0.07")]
      iex> {:ok, result} = BetaCalculator.calculate_beta(portfolio_returns, market_returns)
      iex> D.compare(result.beta, D.new("1.0")) == :gt
      true
  """
  @spec calculate_beta(returns(), returns()) :: beta_calculation_result()
  def calculate_beta(portfolio_returns, market_returns) when is_list(portfolio_returns) and is_list(market_returns) do
    Logger.debug("Calculating Beta for #{length(portfolio_returns)} return periods")

    with :ok <- validate_returns(portfolio_returns),
         :ok <- validate_returns(market_returns),
         :ok <- validate_matching_periods(portfolio_returns, market_returns) do
      # Calculate statistical measures
      portfolio_mean = calculate_mean(portfolio_returns)
      market_mean = calculate_mean(market_returns)

      covariance = calculate_covariance(portfolio_returns, market_returns, portfolio_mean, market_mean)
      market_variance = calculate_variance(market_returns, market_mean)
      portfolio_variance = calculate_variance(portfolio_returns, portfolio_mean)

      # Check for zero market variance (undefined beta)
      if D.equal?(market_variance, D.new("0")) do
        {:error, :zero_market_variance}
      else
        # Beta = Covariance(Portfolio, Market) / Variance(Market)
        beta = DH.safe_divide(covariance, market_variance)

        result = %{
          beta: D.round(beta, 6),
          covariance: D.round(covariance, 8),
          portfolio_variance: D.round(portfolio_variance, 8),
          market_variance: D.round(market_variance, 8),
          portfolio_mean: D.round(portfolio_mean, 6),
          market_mean: D.round(market_mean, 6)
        }

        Logger.debug("Beta calculated: #{result.beta}")
        {:ok, result}
      end
    end
  end

  # Private validation functions

  @spec validate_returns(returns()) :: :ok | {:error, atom()}
  defp validate_returns(returns) do
    cond do
      length(returns) < 2 ->
        {:error, :insufficient_data}

      not Enum.all?(returns, &is_struct(&1, D)) ->
        {:error, :invalid_return_format}

      true ->
        :ok
    end
  end

  @spec validate_matching_periods(returns(), returns()) :: :ok | {:error, atom()}
  defp validate_matching_periods(portfolio_returns, market_returns) do
    if length(portfolio_returns) == length(market_returns) do
      :ok
    else
      {:error, :mismatched_return_periods}
    end
  end

  # Private calculation helper functions

  @spec calculate_mean(returns()) :: D.t()
  defp calculate_mean(values) do
    sum = Enum.reduce(values, D.new("0"), &D.add/2)
    DH.safe_divide(sum, length(values))
  end

  @spec calculate_variance(returns(), D.t()) :: D.t()
  defp calculate_variance(values, mean) do
    n = length(values)

    variance_sum =
      Enum.reduce(values, D.new("0"), fn value, acc ->
        diff = D.sub(value, mean)
        squared_diff = Mathematical.power(diff, 2)
        D.add(acc, squared_diff)
      end)

    # Use sample variance (n-1) for unbiased estimator
    DH.safe_divide(variance_sum, n - 1)
  end

  @spec calculate_covariance(returns(), returns(), D.t(), D.t()) :: D.t()
  defp calculate_covariance(portfolio_returns, market_returns, portfolio_mean, market_mean) do
    n = length(portfolio_returns)

    covariance_sum =
      portfolio_returns
      |> Enum.zip(market_returns)
      |> Enum.reduce(D.new("0"), fn {portfolio_return, market_return}, acc ->
        portfolio_diff = D.sub(portfolio_return, portfolio_mean)
        market_diff = D.sub(market_return, market_mean)
        product = D.mult(portfolio_diff, market_diff)
        D.add(acc, product)
      end)

    # Use sample covariance (n-1) for unbiased estimator
    DH.safe_divide(covariance_sum, n - 1)
  end
end
