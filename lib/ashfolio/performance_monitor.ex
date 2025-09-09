defmodule Ashfolio.PerformanceMonitor do
  @moduledoc """
  Performance monitoring utilities for tracking optimization improvements.

  Provides metrics for:
  - Database query performance
  - Cache hit rates
  - API rate limiting effectiveness
  - Memory usage patterns
  """

  alias Ashfolio.MarketData.RateLimiter

  require Logger

  @doc """
  Monitor database query performance with timing.

  ## Examples
      PerformanceMonitor.time_query("portfolio_calculation", fn ->
        Calculator.calculate_portfolio_value()
      end)
  """
  def time_query(operation_name, query_fun) do
    start_time = System.monotonic_time(:microsecond)

    result = query_fun.()

    end_time = System.monotonic_time(:microsecond)
    duration_ms = (end_time - start_time) / 1000

    Logger.info("Query performance: #{operation_name} took #{duration_ms}ms")

    # Log slow queries for optimization
    if duration_ms > 1000 do
      Logger.warning("Slow query detected: #{operation_name} took #{duration_ms}ms")
    end

    result
  end

  @doc """
  Get cache performance statistics.
  """
  def cache_stats do
    cache_stats = Ashfolio.Cache.stats()

    %{
      cache_size: cache_stats.size,
      memory_mb: cache_stats.memory_bytes / (1024 * 1024),
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Get rate limiter status for monitoring API usage.
  """
  def rate_limiter_stats do
    case RateLimiter.get_status() do
      status when is_map(status) ->
        Map.put(status, :timestamp, DateTime.utc_now())

      _ ->
        %{error: "Rate limiter not available", timestamp: DateTime.utc_now()}
    end
  end

  @doc """
  Generate comprehensive performance report.
  """
  def performance_report do
    %{
      cache: cache_stats(),
      rate_limiter: rate_limiter_stats(),
      system: system_stats(),
      generated_at: DateTime.utc_now()
    }
  end

  @doc """
  Monitor N+1 query prevention by counting database calls.
  """
  def monitor_query_count(operation_name, operation_fun) do
    # This would require database query instrumentation
    # For now, we provide the structure for future implementation
    Logger.debug("Monitoring query count for: #{operation_name}")

    result = operation_fun.()

    # Future: Add actual query counting logic here
    Logger.debug("Query count monitoring completed for: #{operation_name}")

    result
  end

  # Private functions

  defp system_stats do
    %{
      memory_usage: :erlang.memory(),
      process_count: :erlang.system_info(:process_count),
      ets_tables: length(:ets.all())
    }
  end
end
