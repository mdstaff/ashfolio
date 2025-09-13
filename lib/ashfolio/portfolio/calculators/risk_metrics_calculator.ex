defmodule Ashfolio.Portfolio.Calculators.RiskMetricsCalculator do
  @moduledoc """
  Professional risk analytics calculator for portfolio performance assessment.

  Implements industry-standard risk metrics required for fiduciary compliance:
  - Sharpe Ratio - Risk-adjusted return (excess return per unit of volatility)
  - Sortino Ratio - Downside deviation-focused risk assessment
  - Maximum Drawdown - Peak-to-trough decline measurement
  - Value at Risk (VaR) - Potential loss at 95% confidence interval
  - Information Ratio - Active management effectiveness
  - Standard Deviation - Portfolio volatility measurement

  ## References

  - Sharpe, W.F. (1966). "Mutual Fund Performance"
  - Sortino, F.A. & Price, L.N. (1994). "Performance Measurement in a Downside Risk Framework"
  - CFA Institute Standards for risk measurement

  ## Mathematical Formulas

      Sharpe Ratio = (Portfolio Return - Risk-Free Rate) / Portfolio Volatility
      Sortino Ratio = (Portfolio Return - Target Return) / Downside Deviation
      Maximum Drawdown = (Peak Value - Trough Value) / Peak Value
      VaR(95%) = Portfolio Value × (Mean Return - 1.645 × Standard Deviation)
  """

  alias Ashfolio.Financial.DecimalHelpers, as: DH
  alias Ashfolio.Financial.Mathematical
  alias Decimal, as: D

  require Logger

  @doc """
  Calculates Sharpe Ratio for risk-adjusted return analysis.

  The Sharpe Ratio measures excess return per unit of risk, providing a standardized
  metric for comparing investments with different risk profiles.

  ## Parameters

    - returns: List of Decimal - Portfolio returns (e.g., monthly or daily)
    - risk_free_rate: Decimal - Risk-free rate (default: current 10-year Treasury ~4.5%)

  ## Returns

    - {:ok, %{sharpe_ratio: Decimal, excess_return: Decimal, volatility: Decimal}}
    - {:error, reason} - Error with descriptive reason

  ## Examples

      iex> returns = [D.new("0.05"), D.new("0.03"), D.new("0.07")]
      iex> {:ok, result} = RiskMetricsCalculator.calculate_sharpe_ratio(returns, D.new("0.02"))
      iex> D.compare(result.sharpe_ratio, D.new("0")) == :gt
      true
  """
  def calculate_sharpe_ratio(returns, risk_free_rate \\ D.new("0.045")) when is_list(returns) do
    Logger.debug("Calculating Sharpe Ratio for #{length(returns)} return periods")

    with :ok <- validate_returns(returns),
         :ok <- validate_risk_free_rate(risk_free_rate) do
      # Calculate portfolio statistics
      mean_return = calculate_mean(returns)
      volatility = calculate_standard_deviation(returns, mean_return)

      # Annualized risk-free rate adjusted for return frequency
      periods_per_year = infer_periods_per_year(length(returns))
      period_risk_free_rate = D.div(risk_free_rate, periods_per_year)

      # Excess return = Portfolio return - Risk-free rate
      excess_return = D.sub(mean_return, period_risk_free_rate)

      # Sharpe Ratio = Excess return / Volatility
      sharpe_ratio =
        if D.equal?(volatility, D.new("0")) do
          D.new("0")
        else
          DH.safe_divide(excess_return, volatility)
        end

      result = %{
        sharpe_ratio: D.round(sharpe_ratio, 4),
        excess_return: D.round(excess_return, 6),
        volatility: D.round(volatility, 6),
        risk_free_rate: period_risk_free_rate,
        mean_return: D.round(mean_return, 6)
      }

      Logger.debug("Sharpe Ratio calculated: #{result.sharpe_ratio}")
      {:ok, result}
    end
  end

  @doc """
  Calculates Sortino Ratio focusing on downside risk.

  The Sortino Ratio is similar to Sharpe Ratio but only considers downside volatility,
  providing a better measure for asymmetric return distributions.

  ## Parameters

    - returns: List of Decimal - Portfolio returns
    - target_return: Decimal - Minimum acceptable return (default: 0%)

  ## Returns

    - {:ok, %{sortino_ratio: Decimal, excess_return: Decimal, downside_deviation: Decimal}}
    - {:error, reason} - Error with descriptive reason
  """
  def calculate_sortino_ratio(returns, target_return \\ D.new("0")) when is_list(returns) do
    Logger.debug("Calculating Sortino Ratio for #{length(returns)} return periods")

    with :ok <- validate_returns(returns) do
      mean_return = calculate_mean(returns)
      downside_deviation = calculate_downside_deviation(returns, target_return)

      # Excess return above target
      excess_return = D.sub(mean_return, target_return)

      # Sortino Ratio = Excess return / Downside deviation
      sortino_ratio =
        if D.equal?(downside_deviation, D.new("0")) do
          D.new("0")
        else
          DH.safe_divide(excess_return, downside_deviation)
        end

      result = %{
        sortino_ratio: D.round(sortino_ratio, 4),
        excess_return: D.round(excess_return, 6),
        downside_deviation: D.round(downside_deviation, 6),
        target_return: target_return,
        mean_return: D.round(mean_return, 6)
      }

      Logger.debug("Sortino Ratio calculated: #{result.sortino_ratio}")
      {:ok, result}
    end
  end

  @doc """
  Calculates Maximum Drawdown - the largest peak-to-trough decline.

  Maximum Drawdown measures the worst-case loss from any peak to subsequent trough,
  critical for understanding downside risk exposure.

  ## Parameters

    - cumulative_values: List of Decimal - Portfolio values over time

  ## Returns

    - {:ok, %{max_drawdown: Decimal, peak_value: Decimal, trough_value: Decimal, recovery_periods: integer}}
    - {:error, reason} - Error with descriptive reason
  """
  def calculate_maximum_drawdown(cumulative_values) when is_list(cumulative_values) do
    Logger.debug("Calculating Maximum Drawdown for #{length(cumulative_values)} value points")

    with :ok <- validate_values(cumulative_values) do
      {max_drawdown, peak_value, trough_value, recovery_periods} =
        calculate_drawdown_statistics(cumulative_values)

      result = %{
        max_drawdown: D.round(max_drawdown, 6),
        max_drawdown_percentage: D.round(D.mult(max_drawdown, D.new("100")), 2),
        peak_value: peak_value,
        trough_value: trough_value,
        recovery_periods: recovery_periods
      }

      Logger.debug("Maximum Drawdown calculated: #{result.max_drawdown_percentage}%")
      {:ok, result}
    end
  end

  @doc """
  Calculates Value at Risk (VaR) at 95% confidence level.

  VaR estimates the maximum expected loss over a specific time horizon at a given
  confidence level, assuming normal distribution of returns.

  ## Parameters

    - returns: List of Decimal - Portfolio returns
    - portfolio_value: Decimal - Current portfolio value
    - confidence_level: Decimal - Confidence level (default: 0.95 for 95%)

  ## Returns

    - {:ok, %{var_amount: Decimal, var_percentage: Decimal, z_score: Decimal}}
    - {:error, reason} - Error with descriptive reason
  """
  def calculate_value_at_risk(returns, portfolio_value, confidence_level \\ D.new("0.95")) when is_list(returns) do
    Logger.debug("Calculating VaR at #{confidence_level} confidence for portfolio value #{portfolio_value}")

    with :ok <- validate_returns(returns),
         :ok <- validate_portfolio_value(portfolio_value),
         :ok <- validate_confidence_level(confidence_level) do
      mean_return = calculate_mean(returns)
      std_deviation = calculate_standard_deviation(returns, mean_return)

      # Z-score for confidence level (95% = 1.645, 99% = 2.326)
      z_score = confidence_level_to_z_score(confidence_level)

      # VaR = Portfolio Value × (Mean Return - Z-Score × Standard Deviation)
      var_return = D.sub(mean_return, D.mult(z_score, std_deviation))
      var_amount = D.mult(portfolio_value, D.abs(var_return))
      var_percentage = D.mult(D.abs(var_return), D.new("100"))

      result = %{
        var_amount: D.round(var_amount, 2),
        var_percentage: D.round(var_percentage, 4),
        z_score: z_score,
        confidence_level: confidence_level,
        expected_return: D.round(mean_return, 6),
        volatility: D.round(std_deviation, 6)
      }

      Logger.debug("VaR calculated: $#{result.var_amount} (#{result.var_percentage}%)")
      {:ok, result}
    end
  end

  @doc """
  Calculates Information Ratio for active management assessment.

  Information Ratio measures excess return per unit of tracking error, evaluating
  how much additional return a portfolio generates relative to its benchmark.

  ## Parameters

    - portfolio_returns: List of Decimal - Portfolio returns
    - benchmark_returns: List of Decimal - Benchmark returns

  ## Returns

    - {:ok, %{information_ratio: Decimal, tracking_error: Decimal, active_return: Decimal}}
    - {:error, reason} - Error with descriptive reason
  """
  def calculate_information_ratio(portfolio_returns, benchmark_returns)
      when is_list(portfolio_returns) and is_list(benchmark_returns) do
    Logger.debug("Calculating Information Ratio with #{length(portfolio_returns)} periods")

    with :ok <- validate_matching_periods(portfolio_returns, benchmark_returns),
         :ok <- validate_returns(portfolio_returns),
         :ok <- validate_returns(benchmark_returns) do
      # Calculate excess returns (portfolio - benchmark)
      excess_returns = calculate_excess_returns(portfolio_returns, benchmark_returns)

      # Active return = Mean of excess returns
      active_return = calculate_mean(excess_returns)

      # Tracking error = Standard deviation of excess returns
      tracking_error = calculate_standard_deviation(excess_returns, active_return)

      # Information Ratio = Active return / Tracking error
      information_ratio =
        if D.equal?(tracking_error, D.new("0")) do
          D.new("0")
        else
          DH.safe_divide(active_return, tracking_error)
        end

      result = %{
        information_ratio: D.round(information_ratio, 4),
        active_return: D.round(active_return, 6),
        tracking_error: D.round(tracking_error, 6)
      }

      Logger.debug("Information Ratio calculated: #{result.information_ratio}")
      {:ok, result}
    end
  end

  # Private helper functions

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

  defp validate_risk_free_rate(%D{} = rate) do
    if D.compare(rate, D.new("0")) == :lt or D.compare(rate, D.new("1")) == :gt do
      {:error, :invalid_risk_free_rate}
    else
      :ok
    end
  end

  defp validate_values(values) do
    cond do
      length(values) < 2 ->
        {:error, :insufficient_data}

      not Enum.all?(values, &is_struct(&1, D)) ->
        {:error, :invalid_value_format}

      not Enum.all?(values, &(D.compare(&1, D.new("0")) == :gt)) ->
        {:error, :non_positive_values}

      true ->
        :ok
    end
  end

  defp validate_portfolio_value(%D{} = value) do
    if D.compare(value, D.new("0")) == :gt do
      :ok
    else
      {:error, :invalid_portfolio_value}
    end
  end

  defp validate_confidence_level(%D{} = level) do
    if D.compare(level, D.new("0")) == :gt and D.compare(level, D.new("1")) == :lt do
      :ok
    else
      {:error, :invalid_confidence_level}
    end
  end

  defp validate_matching_periods(portfolio_returns, benchmark_returns) do
    if length(portfolio_returns) == length(benchmark_returns) do
      :ok
    else
      {:error, :mismatched_return_periods}
    end
  end

  defp calculate_mean(values) do
    sum = Enum.reduce(values, D.new("0"), &D.add/2)
    DH.safe_divide(sum, length(values))
  end

  defp calculate_standard_deviation(values, mean) do
    n = length(values)

    variance_sum =
      Enum.reduce(values, D.new("0"), fn value, acc ->
        diff = D.sub(value, mean)
        squared_diff = Mathematical.power(diff, 2)
        D.add(acc, squared_diff)
      end)

    variance = DH.safe_divide(variance_sum, n - 1)
    Mathematical.nth_root(variance, 2)
  end

  defp calculate_downside_deviation(returns, target_return) do
    # Only consider returns below target for downside deviation
    downside_returns = Enum.filter(returns, &(D.compare(&1, target_return) == :lt))

    if length(downside_returns) == 0 do
      D.new("0")
    else
      downside_variance_sum =
        Enum.reduce(downside_returns, D.new("0"), fn return, acc ->
          diff = D.sub(return, target_return)
          squared_diff = Mathematical.power(diff, 2)
          D.add(acc, squared_diff)
        end)

      downside_variance = DH.safe_divide(downside_variance_sum, length(returns))
      Mathematical.nth_root(downside_variance, 2)
    end
  end

  defp calculate_drawdown_statistics(cumulative_values) do
    {_, max_drawdown, peak_value, trough_value, recovery_periods} =
      Enum.reduce(cumulative_values, {D.new("0"), D.new("0"), D.new("0"), D.new("0"), 0}, fn value,
                                                                                             {running_peak, max_dd,
                                                                                              peak_val, trough_val,
                                                                                              recovery} ->
        # Update running peak
        new_peak = if D.compare(value, running_peak) == :gt, do: value, else: running_peak

        # Calculate current drawdown
        current_drawdown =
          if D.equal?(new_peak, D.new("0")) do
            D.new("0")
          else
            D.div(D.sub(new_peak, value), new_peak)
          end

        # Update maximum drawdown
        {updated_max_dd, updated_peak, updated_trough, updated_recovery} =
          if D.compare(current_drawdown, max_dd) == :gt do
            {current_drawdown, new_peak, value, 0}
          else
            {max_dd, peak_val, trough_val, recovery + 1}
          end

        {new_peak, updated_max_dd, updated_peak, updated_trough, updated_recovery}
      end)

    {max_drawdown, peak_value, trough_value, recovery_periods}
  end

  defp calculate_excess_returns(portfolio_returns, benchmark_returns) do
    portfolio_returns
    |> Enum.zip(benchmark_returns)
    |> Enum.map(fn {portfolio, benchmark} -> D.sub(portfolio, benchmark) end)
  end

  defp confidence_level_to_z_score(%D{} = confidence_level) do
    # Common confidence levels and their Z-scores
    case D.to_float(confidence_level) do
      # 99%
      level when level >= 0.99 -> D.new("2.326")
      # 97.5%
      level when level >= 0.975 -> D.new("1.960")
      # 95%
      level when level >= 0.95 -> D.new("1.645")
      # 90%
      level when level >= 0.90 -> D.new("1.282")
      # Default to 95%
      _ -> D.new("1.645")
    end
  end

  defp infer_periods_per_year(data_points) do
    # Heuristic to determine frequency based on data points
    # This could be enhanced with date analysis in the future
    cond do
      # Daily (trading days)
      data_points >= 250 -> D.new("252")
      # Weekly
      data_points >= 50 -> D.new("52")
      # Monthly
      data_points >= 10 -> D.new("12")
      # Quarterly
      true -> D.new("4")
    end
  end
end
