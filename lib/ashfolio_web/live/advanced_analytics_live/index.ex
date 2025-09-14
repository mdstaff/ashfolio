defmodule AshfolioWeb.AdvancedAnalyticsLive.Index do
  @moduledoc """
  Advanced Analytics LiveView providing professional-grade portfolio performance analysis.

  Features:
  - Time-Weighted Return (TWR) calculations and charts
  - Money-Weighted Return (MWR) with IRR methodology
  - Rolling returns analysis with volatility metrics
  - Performance caching for optimized load times
  - Real-time updates via PubSub integration

  Follows existing LiveView patterns in the codebase for consistency and maintainability.
  """

  use AshfolioWeb, :live_view

  alias Ashfolio.Financial.Formatters
  alias Ashfolio.Portfolio.Calculators.RiskMetricsCalculator
  alias Ashfolio.Portfolio.PerformanceCache
  alias Ashfolio.Portfolio.PerformanceCalculator

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to portfolio changes for real-time updates
      Ashfolio.PubSub.subscribe("accounts")
      Ashfolio.PubSub.subscribe("transactions")
    end

    socket =
      socket
      |> assign_current_page(:advanced_analytics)
      |> assign(:page_title, "Advanced Analytics")
      |> assign_initial_state()
      |> maybe_calculate_analytics()

    {:ok, socket}
  end

  @impl true
  def handle_event("calculate_twr", _params, socket) do
    Logger.debug("Calculating Time-Weighted Return")

    # Set loading state immediately and schedule async calculation
    socket = assign(socket, :loading_twr, true)
    Process.send_after(self(), :complete_twr_calculation, 10)

    {:noreply, socket}
  end

  @impl true
  def handle_event("calculate_mwr", _params, socket) do
    Logger.debug("Calculating Money-Weighted Return")

    # Set loading state immediately and schedule async calculation
    socket = assign(socket, :loading_mwr, true)
    Process.send_after(self(), :complete_mwr_calculation, 10)

    {:noreply, socket}
  end

  @impl true
  def handle_event("calculate_rolling_returns", _params, socket) do
    Logger.debug("Calculating Rolling Returns Analysis")

    # Set loading state immediately and schedule async calculation
    socket = assign(socket, :loading_rolling, true)
    Process.send_after(self(), :complete_rolling_calculation, 10)

    {:noreply, socket}
  end

  @impl true
  def handle_event("calculate_risk_metrics", _params, socket) do
    Logger.debug("Calculating Risk Metrics")

    # Set loading state immediately and schedule async calculation
    socket = assign(socket, :loading_risk_metrics, true)
    Process.send_after(self(), :complete_risk_metrics_calculation, 10)

    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh_all", _params, socket) do
    Logger.debug("Refreshing all analytics calculations")

    socket =
      socket
      |> assign(:loading_all, true)
      |> calculate_time_weighted_return()
      |> calculate_money_weighted_return()
      |> calculate_rolling_returns()
      |> calculate_risk_metrics()
      |> assign(:loading_all, false)
      |> put_flash(:info, "All analytics refreshed successfully")

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_cache", _params, socket) do
    Logger.debug("Clearing performance cache")

    PerformanceCache.clear_all()

    socket =
      socket
      |> put_flash(:info, "Performance cache cleared")
      |> assign(:cache_stats, get_cache_stats())

    {:noreply, socket}
  end

  @impl true
  def handle_event("show_cache_stats", _params, socket) do
    socket = assign(socket, :cache_stats, get_cache_stats())
    {:noreply, socket}
  end

  @impl true
  def handle_info({:transaction_created, _transaction}, socket) do
    Logger.debug("Transaction created - refreshing analytics")

    socket =
      socket
      |> put_flash(:info, "Portfolio updated - analytics refreshed")
      |> maybe_calculate_analytics()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:transaction_updated, _transaction}, socket) do
    socket =
      socket
      |> put_flash(:info, "Transaction updated - analytics refreshed")
      |> maybe_calculate_analytics()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:account_updated, _account}, socket) do
    socket = maybe_calculate_analytics(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:complete_twr_calculation, socket) do
    socket =
      socket
      |> calculate_time_weighted_return()
      |> assign(:loading_twr, false)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:complete_mwr_calculation, socket) do
    socket =
      socket
      |> calculate_money_weighted_return()
      |> assign(:loading_mwr, false)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:complete_rolling_calculation, socket) do
    socket =
      socket
      |> calculate_rolling_returns()
      |> assign(:loading_rolling, false)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:complete_risk_metrics_calculation, socket) do
    socket =
      socket
      |> calculate_risk_metrics()
      |> assign(:loading_risk_metrics, false)

    {:noreply, socket}
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # Private helper functions

  defp assign_initial_state(socket) do
    socket
    |> assign(:twr_result, nil)
    |> assign(:mwr_result, nil)
    |> assign(:rolling_returns, nil)
    |> assign(:risk_metrics, nil)
    |> assign(:loading_twr, false)
    |> assign(:loading_mwr, false)
    |> assign(:loading_rolling, false)
    |> assign(:loading_risk_metrics, false)
    |> assign(:loading_all, false)
    |> assign(:cache_stats, get_cache_stats())
    |> assign(:calculation_history, [])
    |> assign(:error_message, nil)
  end

  defp maybe_calculate_analytics(socket) do
    # Auto-calculate on mount if we have portfolio data
    if has_portfolio_data?() do
      socket
      |> calculate_time_weighted_return()
      |> calculate_money_weighted_return()
    else
      put_flash(socket, :info, "Add portfolio transactions to see advanced analytics")
    end
  end

  defp calculate_time_weighted_return(socket) do
    cache_key = PerformanceCache.cache_key(:twr, "global", 12)

    case PerformanceCache.get(cache_key) do
      {:ok, cached_result} ->
        Logger.debug("Using cached TWR result")
        assign(socket, :twr_result, cached_result)

      :miss ->
        perform_twr_calculation(socket, cache_key)
    end
  end

  defp perform_twr_calculation(socket, cache_key) do
    {:ok, transactions} = get_portfolio_transactions_for_twr()
    process_twr_result(socket, transactions, cache_key)
  end

  defp process_twr_result(socket, transactions, cache_key) do
    case PerformanceCalculator.calculate_time_weighted_return(transactions) do
      {:ok, twr} ->
        # Cache the result
        PerformanceCache.put(cache_key, twr)

        socket
        |> assign(:twr_result, twr)
        |> add_to_calculation_history("TWR", twr, "success")
        |> assign(:error_message, nil)

      {:error, reason} ->
        Logger.warning("TWR calculation failed: #{inspect(reason)}")
        error_msg = "Time-Weighted Return calculation failed: #{inspect(reason)}"

        socket
        |> assign(:twr_result, nil)
        |> assign(:error_message, error_msg)
        |> put_flash(:error, error_msg)
    end
  end

  defp calculate_money_weighted_return(socket) do
    cache_key = PerformanceCache.cache_key(:mwr, "global", 12)

    case PerformanceCache.get(cache_key) do
      {:ok, cached_result} ->
        Logger.debug("Using cached MWR result")
        assign(socket, :mwr_result, cached_result)

      :miss ->
        perform_mwr_calculation(socket, cache_key)
    end
  end

  defp perform_mwr_calculation(socket, cache_key) do
    {:ok, cash_flows} = get_portfolio_cash_flows_for_mwr()
    process_mwr_result(socket, cash_flows, cache_key)
  end

  defp process_mwr_result(socket, cash_flows, cache_key) do
    case PerformanceCalculator.calculate_money_weighted_return(cash_flows) do
      {:ok, mwr} ->
        # Cache the result
        PerformanceCache.put(cache_key, mwr)

        socket
        |> assign(:mwr_result, mwr)
        |> add_to_calculation_history("MWR", mwr, "success")
        |> assign(:error_message, nil)

      {:error, reason} ->
        Logger.warning("MWR calculation failed: #{inspect(reason)}")
        error_msg = "Money-Weighted Return calculation failed: #{inspect(reason)}"

        socket
        |> assign(:mwr_result, nil)
        |> assign(:error_message, error_msg)
        |> put_flash(:error, error_msg)
    end
  end

  defp calculate_rolling_returns(socket) do
    cache_key = PerformanceCache.cache_key(:rolling_returns, "global", 12)

    case PerformanceCache.get(cache_key) do
      {:ok, cached_result} ->
        Logger.debug("Using cached rolling returns result")
        assign(socket, :rolling_returns, cached_result)

      :miss ->
        perform_rolling_returns_calculation(socket, cache_key)
    end
  end

  defp perform_rolling_returns_calculation(socket, cache_key) do
    case get_monthly_returns_data() do
      {:ok, monthly_data} ->
        process_rolling_returns_result(socket, monthly_data, cache_key)
        # get_monthly_returns_data always returns {:ok, _}, so this case is unused
        # Keeping for future when real data access might fail
    end
  end

  defp process_rolling_returns_result(socket, monthly_data, cache_key) do
    case PerformanceCalculator.calculate_rolling_returns(monthly_data, 12) do
      rolling_returns when is_list(rolling_returns) ->
        # Handle direct list return (current implementation)
        analysis = PerformanceCalculator.analyze_rolling_returns(monthly_data, 12)

        result = %{
          rolling_periods: rolling_returns,
          analysis: analysis
        }

        PerformanceCache.put(cache_key, result)

        socket
        |> assign(:rolling_returns, result)
        |> add_to_calculation_history("Rolling Returns", "Analysis complete", "success")

      {:error, reason} ->
        Logger.warning("Rolling returns calculation failed: #{inspect(reason)}")
        error_msg = "Rolling Returns calculation failed: #{inspect(reason)}"

        socket
        |> assign(:rolling_returns, nil)
        |> assign(:error_message, error_msg)
        |> put_flash(:error, error_msg)
    end
  end

  defp calculate_risk_metrics(socket) do
    cache_key = PerformanceCache.cache_key(:risk_metrics, "global", 12)

    case PerformanceCache.get(cache_key) do
      {:ok, cached_result} ->
        Logger.debug("Using cached risk metrics result")
        assign(socket, :risk_metrics, cached_result)

      :miss ->
        perform_risk_metrics_calculation(socket, cache_key)
    end
  end

  defp perform_risk_metrics_calculation(socket, cache_key) do
    {:ok, returns} = get_portfolio_returns_for_risk_analysis()
    {:ok, portfolio_values} = get_portfolio_values_for_drawdown()
    process_risk_metrics_result(socket, returns, portfolio_values, cache_key)
  end

  defp process_risk_metrics_result(socket, returns, portfolio_values, cache_key) do
    # Calculate all risk metrics
    with {:ok, sharpe} <- RiskMetricsCalculator.calculate_sharpe_ratio(returns),
         {:ok, sortino} <- RiskMetricsCalculator.calculate_sortino_ratio(returns),
         {:ok, max_drawdown} <- RiskMetricsCalculator.calculate_maximum_drawdown(portfolio_values),
         {:ok, var_result} <- RiskMetricsCalculator.calculate_value_at_risk(returns, List.last(portfolio_values)) do
      # Combine all metrics
      risk_metrics = %{
        sharpe_ratio: sharpe,
        sortino_ratio: sortino,
        maximum_drawdown: max_drawdown,
        value_at_risk: var_result,
        portfolio_volatility: sharpe.volatility,
        calculated_at: DateTime.utc_now()
      }

      PerformanceCache.put(cache_key, risk_metrics)

      socket
      |> assign(:risk_metrics, risk_metrics)
      |> add_to_calculation_history("Risk Metrics", "Complete analysis", "success")
      |> assign(:error_message, nil)
    else
      {:error, reason} ->
        Logger.warning("Risk metrics calculation failed: #{inspect(reason)}")
        error_msg = "Risk metrics calculation failed: #{inspect(reason)}"

        socket
        |> assign(:risk_metrics, nil)
        |> assign(:error_message, error_msg)
        |> put_flash(:error, error_msg)
    end
  end

  defp add_to_calculation_history(socket, calculation_type, result, status) do
    timestamp = DateTime.utc_now()

    history_entry = %{
      type: calculation_type,
      result: format_result_for_history(result),
      status: status,
      timestamp: timestamp
    }

    current_history = socket.assigns[:calculation_history] || []
    # Keep last 10
    updated_history = [history_entry | Enum.take(current_history, 9)]

    assign(socket, :calculation_history, updated_history)
  end

  defp format_result_for_history(result) when is_binary(result), do: result

  defp format_result_for_history(%Decimal{} = result) do
    Formatters.format_percentage(result)
  end

  # Data fetching functions (simplified for now)

  # Check if user has any transactions or accounts
  # This would integrate with the actual portfolio data
  # For now, return true to enable calculations
  defp has_portfolio_data? do
    true
  rescue
    _ -> false
  end

  defp get_portfolio_transactions_for_twr do
    # Generate sample data for demonstration
    # In production, this would fetch actual portfolio transactions
    sample_transactions = [
      %{date: ~D[2023-01-01], amount: Decimal.new("-10000"), type: :buy},
      %{date: ~D[2023-06-01], amount: Decimal.new("-5000"), type: :buy},
      %{date: ~D[2023-12-31], amount: Decimal.new("18500"), type: :current_value}
    ]

    {:ok, sample_transactions}
  end

  defp get_portfolio_cash_flows_for_mwr do
    # Generate sample cash flow data
    sample_cash_flows = [
      %{date: ~D[2023-01-01], amount: Decimal.new("-10000")},
      %{date: ~D[2023-06-01], amount: Decimal.new("-5000")},
      %{date: ~D[2023-12-31], amount: Decimal.new("17000")}
    ]

    {:ok, sample_cash_flows}
  end

  defp get_monthly_returns_data do
    # Generate sample monthly returns for rolling analysis
    sample_returns =
      Enum.map(1..36, fn i ->
        base_date = ~D[2021-01-01]
        month_date = Date.add(base_date, i * 30)
        return_pct = -5.0 + :rand.uniform() * 20.0

        # -5% to +15%

        %{
          date: month_date,
          return: Decimal.from_float(return_pct)
        }
      end)

    {:ok, sample_returns}
  end

  defp get_portfolio_returns_for_risk_analysis do
    # Generate sample monthly returns for risk analysis
    sample_returns =
      Enum.map(1..24, fn _i ->
        # 0.8% monthly average
        base_return = 0.008
        # 4% monthly volatility
        volatility = 0.04
        random_component = :rand.normal() * volatility

        return_value = base_return + random_component
        Decimal.from_float(return_value)
      end)

    {:ok, sample_returns}
  end

  defp get_portfolio_values_for_drawdown do
    # Generate sample portfolio values showing growth with drawdowns
    initial_value = 100_000

    values =
      Enum.scan(1..36, initial_value, fn month, prev_value ->
        # Simulate monthly returns with occasional drawdowns
        monthly_return =
          case month do
            # Simulate a market crash period
            month when month in [18, 19, 20] -> -0.08 + :rand.uniform() * 0.05
            # Normal growth with volatility
            _ -> 0.008 + (:rand.uniform() - 0.5) * 0.06
          end

        prev_value * (1 + monthly_return)
      end)

    decimal_values = Enum.map(values, &Decimal.from_float/1)
    {:ok, decimal_values}
  end

  defp get_cache_stats do
    PerformanceCache.stats()
  rescue
    _ -> %{entries: 0, hit_rate: 0.0, uptime_seconds: 0}
  end

  defp percentage_color(nil), do: "text-gray-400"

  defp percentage_color(value) do
    if Decimal.compare(value, Decimal.new("0")) == :gt do
      "text-green-600"
    else
      "text-red-600"
    end
  end
end
