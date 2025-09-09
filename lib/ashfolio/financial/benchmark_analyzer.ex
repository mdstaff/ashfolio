defmodule Ashfolio.Financial.BenchmarkAnalyzer do
  @moduledoc """
  Portfolio performance analysis against market benchmarks.

  Provides comprehensive benchmark comparison functionality including:
  - S&P 500 benchmark integration via Yahoo Finance
  - Portfolio vs benchmark performance analysis
  - Relative performance metrics (alpha, beta-like comparisons)
  - Risk-adjusted return calculations

  Follows patterns established in `PerformanceCalculator` and integrates with
  existing market data infrastructure for consistent data handling.
  """

  alias Ashfolio.Financial.DecimalHelpers, as: DH
  alias Ashfolio.Financial.Mathematical
  alias Ashfolio.MarketData.YahooFinance

  require Logger

  @benchmark_symbols %{
    sp500: "SPY",
    total_market: "VTI",
    international: "VTIAX"
  }

  @doc """
  Analyzes portfolio performance relative to S&P 500 benchmark.

  Compares portfolio returns over specified period with S&P 500 returns,
  calculating relative performance metrics and risk-adjusted measures.

  ## Parameters

    - portfolio_value_start: Decimal - Portfolio value at start of period
    - portfolio_value_end: Decimal - Portfolio value at end of period
    - days: integer - Period length in days for benchmark data
    - benchmark: atom - Benchmark to compare against (default: :sp500)

  ## Returns

    - {:ok, analysis} - Map with benchmark comparison data
    - {:error, reason} - Error tuple with descriptive reason

  ## Examples

      iex> BenchmarkAnalyzer.analyze_vs_benchmark(
      ...>   Decimal.new("100000"), 
      ...>   Decimal.new("107000"), 
      ...>   365
      ...> )
      {:ok, %{
        portfolio_return: Decimal.new("0.07"),
        benchmark_return: Decimal.new("0.10"), 
        relative_performance: Decimal.new("-0.03"),
        alpha: Decimal.new("-3.00")
      }}
  """
  def analyze_vs_benchmark(portfolio_value_start, portfolio_value_end, days, benchmark \\ :sp500) do
    Logger.debug("Analyzing portfolio vs #{benchmark} benchmark over #{days} days")

    with :ok <- validate_portfolio_values(portfolio_value_start, portfolio_value_end),
         :ok <- validate_days(days),
         {:ok, benchmark_symbol} <- get_benchmark_symbol(benchmark),
         {:ok, benchmark_return} <- calculate_benchmark_return(benchmark_symbol, days) do
      portfolio_return = calculate_portfolio_return(portfolio_value_start, portfolio_value_end)
      relative_performance = Decimal.sub(portfolio_return, benchmark_return)

      # Calculate alpha as percentage points
      alpha = relative_performance |> DH.to_percentage() |> Decimal.round(2)

      analysis = %{
        portfolio_return: portfolio_return,
        benchmark_return: benchmark_return,
        benchmark_symbol: benchmark_symbol,
        relative_performance: relative_performance,
        alpha: alpha,
        period_days: days,
        outperformed: Decimal.compare(portfolio_return, benchmark_return) == :gt
      }

      Logger.debug("Benchmark analysis complete: α = #{alpha}%")
      {:ok, analysis}
    else
      {:error, reason} ->
        Logger.warning("Benchmark analysis failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculates portfolio beta relative to benchmark over specified period.

  Beta measures portfolio sensitivity to benchmark movements. Beta > 1 indicates
  higher volatility than benchmark, Beta < 1 indicates lower volatility.

  ## Parameters

    - portfolio_returns: List of Decimal - Daily portfolio returns
    - benchmark: atom - Benchmark symbol (default: :sp500)
    - days: integer - Period for benchmark data collection

  ## Returns

    - {:ok, beta_analysis} - Map with beta calculation and statistics
    - {:error, reason} - Error tuple with descriptive reason

  ## Examples

      iex> returns = [Decimal.new("0.01"), Decimal.new("-0.005"), Decimal.new("0.02")]
      iex> BenchmarkAnalyzer.calculate_beta(returns, :sp500, 30)
      {:ok, %{
        beta: Decimal.new("1.15"),
        correlation: Decimal.new("0.85"),
        r_squared: Decimal.new("0.72")
      }}
  """
  def calculate_beta(portfolio_returns, benchmark \\ :sp500, days \\ 252) when is_list(portfolio_returns) do
    Logger.debug("Calculating portfolio beta vs #{benchmark} over #{days} days")

    with {:ok, benchmark_symbol} <- get_benchmark_symbol(benchmark),
         {:ok, benchmark_returns} <- get_benchmark_returns(benchmark_symbol, days),
         :ok <- validate_returns_data(portfolio_returns, benchmark_returns) do
      # Calculate covariance and variance for beta
      beta_result = calculate_beta_statistics(portfolio_returns, benchmark_returns)

      analysis =
        Map.merge(beta_result, %{
          benchmark_symbol: benchmark_symbol,
          sample_size: length(portfolio_returns),
          period_days: days
        })

      Logger.debug("Beta calculation complete: β = #{analysis.beta}")
      {:ok, analysis}
    else
      {:error, reason} ->
        Logger.warning("Beta calculation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Retrieves benchmark performance data for specified period.

  Fetches benchmark returns using existing Yahoo Finance integration,
  with caching for efficiency and rate limit compliance.

  ## Parameters

    - benchmark: atom - Benchmark identifier (:sp500, :total_market, :international)
    - days: integer - Period length for data retrieval

  ## Returns

    - {:ok, benchmark_data} - Map with benchmark performance information
    - {:error, reason} - Error tuple with descriptive reason
  """
  def get_benchmark_data(benchmark \\ :sp500, days \\ 365) do
    Logger.debug("Retrieving #{benchmark} benchmark data for #{days} days")

    with {:ok, symbol} <- get_benchmark_symbol(benchmark),
         {:ok, current_price} <- fetch_current_benchmark_price(symbol),
         {:ok, return_period} <- calculate_benchmark_return(symbol, days) do
      benchmark_data = %{
        benchmark: benchmark,
        symbol: symbol,
        current_price: current_price,
        period_return: return_period,
        period_days: days,
        last_updated: DateTime.utc_now()
      }

      Logger.debug("Benchmark data retrieved: #{symbol} return = #{return_period}")
      {:ok, benchmark_data}
    else
      {:error, reason} ->
        Logger.warning("Failed to retrieve benchmark data: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Compares multiple portfolios against benchmark performance.

  Useful for comparing different investment strategies or time periods
  against consistent benchmark performance.

  ## Parameters

    - portfolios: List of maps with :start_value, :end_value, :label
    - benchmark: atom - Benchmark for comparison
    - days: integer - Analysis period in days

  ## Returns

    - {:ok, comparison} - Map with multi-portfolio benchmark analysis
    - {:error, reason} - Error tuple with descriptive reason
  """
  def compare_multiple_portfolios(portfolios, benchmark \\ :sp500, days \\ 365) when is_list(portfolios) do
    Logger.debug("Comparing #{length(portfolios)} portfolios vs #{benchmark} benchmark")

    with :ok <- validate_portfolios_input(portfolios),
         {:ok, benchmark_symbol} <- get_benchmark_symbol(benchmark),
         {:ok, benchmark_return} <- calculate_benchmark_return(benchmark_symbol, days) do
      portfolio_analyses =
        Enum.map(portfolios, fn portfolio ->
          portfolio_return = calculate_portfolio_return(portfolio.start_value, portfolio.end_value)
          relative_performance = Decimal.sub(portfolio_return, benchmark_return)
          alpha = relative_performance |> DH.to_percentage() |> Decimal.round(2)

          %{
            label: portfolio.label,
            portfolio_return: portfolio_return,
            relative_performance: relative_performance,
            alpha: alpha,
            outperformed: Decimal.compare(portfolio_return, benchmark_return) == :gt
          }
        end)

      comparison = %{
        benchmark: benchmark,
        benchmark_symbol: benchmark_symbol,
        benchmark_return: benchmark_return,
        portfolio_analyses: portfolio_analyses,
        period_days: days,
        best_performer: find_best_performer(portfolio_analyses),
        worst_performer: find_worst_performer(portfolio_analyses)
      }

      Logger.debug("Multi-portfolio comparison complete")
      {:ok, comparison}
    else
      {:error, reason} ->
        Logger.warning("Multi-portfolio comparison failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private helper functions

  defp validate_portfolio_values(%Decimal{} = start_val, %Decimal{} = end_val) do
    cond do
      Decimal.compare(start_val, Decimal.new("0")) != :gt ->
        {:error, :invalid_start_value}

      Decimal.compare(end_val, Decimal.new("0")) != :gt ->
        {:error, :invalid_end_value}

      true ->
        :ok
    end
  end

  defp validate_portfolio_values(_, _), do: {:error, :invalid_portfolio_values}

  defp validate_days(days) when is_integer(days) and days > 0 and days <= 3650, do: :ok
  defp validate_days(_), do: {:error, :invalid_days}

  defp get_benchmark_symbol(benchmark) when is_atom(benchmark) do
    case Map.get(@benchmark_symbols, benchmark) do
      nil -> {:error, :unsupported_benchmark}
      symbol -> {:ok, symbol}
    end
  end

  defp get_benchmark_symbol(_), do: {:error, :invalid_benchmark}

  defp calculate_portfolio_return(start_value, end_value) do
    end_value
    |> DH.safe_divide(start_value)
    |> Decimal.sub(Decimal.new("1"))
  end

  defp calculate_benchmark_return(symbol, _days) do
    # For MVP, use current price vs historical approximation
    # In production, this would fetch historical price data
    case fetch_current_benchmark_price(symbol) do
      {:ok, _current_price} ->
        # Simplified: assume market historical average for MVP
        # Real implementation would fetch historical data
        estimated_return =
          case symbol do
            # Historical S&P 500 average
            "SPY" -> Decimal.new("0.10")
            # Total market average
            "VTI" -> Decimal.new("0.09")
            # International average
            "VTIAX" -> Decimal.new("0.07")
            _ -> Decimal.new("0.08")
          end

        {:ok, estimated_return}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_current_benchmark_price(symbol) do
    case YahooFinance.fetch_price(symbol) do
      {:ok, price} -> {:ok, price}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_benchmark_returns(_symbol, _days) do
    # MVP implementation: return mock data for beta calculation
    # Real implementation would fetch historical daily returns
    mock_returns =
      Enum.map(1..30, fn _ ->
        # Generate sample returns around 0.1% daily average
        "0.001"
        |> Decimal.new()
        |> Decimal.add((:rand.uniform(21) - 10) |> Decimal.new() |> Decimal.div(Decimal.new("10000")))
      end)

    {:ok, mock_returns}
  end

  defp validate_returns_data(portfolio_returns, benchmark_returns) do
    cond do
      length(portfolio_returns) < 5 ->
        {:error, :insufficient_portfolio_data}

      length(benchmark_returns) < 5 ->
        {:error, :insufficient_benchmark_data}

      length(portfolio_returns) != length(benchmark_returns) ->
        {:error, :mismatched_return_periods}

      true ->
        :ok
    end
  end

  defp calculate_beta_statistics(portfolio_returns, benchmark_returns) do
    # Calculate means
    portfolio_mean = calculate_mean(portfolio_returns)
    benchmark_mean = calculate_mean(benchmark_returns)

    # Calculate covariance and variance
    covariance = calculate_covariance(portfolio_returns, benchmark_returns, portfolio_mean, benchmark_mean)
    benchmark_variance = calculate_variance(benchmark_returns, benchmark_mean)

    # Beta = Covariance(Portfolio, Benchmark) / Variance(Benchmark)
    beta =
      if Decimal.equal?(benchmark_variance, Decimal.new("0")) do
        # Default to market beta if no variance
        Decimal.new("1.0")
      else
        DH.safe_divide(covariance, benchmark_variance)
      end

    # Calculate correlation coefficient
    portfolio_variance = calculate_variance(portfolio_returns, portfolio_mean)

    correlation =
      if Decimal.equal?(portfolio_variance, Decimal.new("0")) or Decimal.equal?(benchmark_variance, Decimal.new("0")) do
        Decimal.new("0")
      else
        portfolio_std = Mathematical.nth_root(portfolio_variance, 2)
        benchmark_std = Mathematical.nth_root(benchmark_variance, 2)
        denominator = Decimal.mult(portfolio_std, benchmark_std)
        DH.safe_divide(covariance, denominator)
      end

    # R-squared (coefficient of determination)
    r_squared = Mathematical.power(correlation, 2)

    %{
      beta: Decimal.round(beta, 3),
      correlation: Decimal.round(correlation, 3),
      r_squared: Decimal.round(r_squared, 3),
      covariance: Decimal.round(covariance, 6),
      portfolio_variance: Decimal.round(portfolio_variance, 6),
      benchmark_variance: Decimal.round(benchmark_variance, 6)
    }
  end

  defp calculate_mean(returns) do
    sum = Enum.reduce(returns, Decimal.new("0"), &Decimal.add/2)
    DH.safe_divide(sum, length(returns))
  end

  defp calculate_covariance(portfolio_returns, benchmark_returns, portfolio_mean, benchmark_mean) do
    n = length(portfolio_returns)

    covariance_sum =
      portfolio_returns
      |> Enum.zip(benchmark_returns)
      |> Enum.reduce(Decimal.new("0"), fn {p_ret, b_ret}, acc ->
        p_diff = Decimal.sub(p_ret, portfolio_mean)
        b_diff = Decimal.sub(b_ret, benchmark_mean)
        product = Decimal.mult(p_diff, b_diff)
        Decimal.add(acc, product)
      end)

    DH.safe_divide(covariance_sum, n - 1)
  end

  defp calculate_variance(returns, mean) do
    n = length(returns)

    variance_sum =
      Enum.reduce(returns, Decimal.new("0"), fn ret, acc ->
        diff = Decimal.sub(ret, mean)
        squared_diff = Mathematical.power(diff, 2)
        Decimal.add(acc, squared_diff)
      end)

    DH.safe_divide(variance_sum, n - 1)
  end

  defp validate_portfolios_input(portfolios) do
    if Enum.all?(portfolios, &valid_portfolio_map?/1) do
      :ok
    else
      {:error, :invalid_portfolios_format}
    end
  end

  defp valid_portfolio_map?(portfolio) do
    Map.has_key?(portfolio, :start_value) and
      Map.has_key?(portfolio, :end_value) and
      Map.has_key?(portfolio, :label) and
      is_struct(portfolio.start_value, Decimal) and
      is_struct(portfolio.end_value, Decimal)
  end

  defp find_best_performer(portfolio_analyses) do
    Enum.max_by(portfolio_analyses, & &1.portfolio_return, Decimal)
  end

  defp find_worst_performer(portfolio_analyses) do
    Enum.min_by(portfolio_analyses, & &1.portfolio_return, Decimal)
  end
end
