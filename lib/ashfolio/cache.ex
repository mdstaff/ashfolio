defmodule Ashfolio.Cache do
  @moduledoc """
  Simple ETS-based cache for storing market price data.

  This module provides basic caching functionality for symbol prices
  with timestamp tracking for cache freshness. Optimized for Apple Silicon
  and 16GB memory systems.
  """

  require Logger

  @cache_table :ashfolio_price_cache
  # 1 hour default TTL
  @default_ttl_seconds 3600

  @doc """
  Initializes the ETS cache table.
  Called during application startup.
  """
  def init do
    case :ets.whereis(@cache_table) do
      :undefined ->
        :ets.new(@cache_table, [
          :set,
          :public,
          :named_table,
          # Leverage M1 Pro's multiple cores
          {:write_concurrency, true},
          {:read_concurrency, true},
          # Better performance on Apple Silicon
          {:decentralized_counters, true}
        ])

        Logger.info("Initialized ETS price cache: #{@cache_table}")
        :ok

      _table ->
        Logger.debug("ETS price cache already exists: #{@cache_table}")
        :ok
    end
  end

  @doc """
  Stores a price for a symbol in the cache with current timestamp.

  ## Parameters
  - symbol: String symbol (e.g., "AAPL")
  - price: Decimal price value
  - updated_at: DateTime when price was fetched (defaults to now)

  ## Examples
      iex> Ashfolio.Cache.put_price("AAPL", Decimal.new("150.25"))
      :ok
  """
  def put_price(symbol, price, updated_at \\ DateTime.utc_now()) do
    cache_entry = %{
      price: price,
      updated_at: updated_at,
      cached_at: DateTime.utc_now()
    }

    :ets.insert(@cache_table, {symbol, cache_entry})
    Logger.debug("Cached price for #{symbol}: #{price}")
    :ok
  end

  @doc """
  Retrieves a cached price for a symbol.

  ## Parameters
  - symbol: String symbol to lookup
  - max_age_seconds: Maximum age in seconds (defaults to 1 hour)

  ## Returns
  - {:ok, %{price: Decimal.t(), updated_at: DateTime.t()}} if found and fresh
  - {:error, :not_found} if symbol not in cache
  - {:error, :stale} if cached data is too old

  ## Examples
      iex> Ashfolio.Cache.get_price("AAPL")
      {:ok, %{price: #Decimal<150.25>, updated_at: ~U[2025-01-28 10:30:00Z]}}
  """
  def get_price(symbol, max_age_seconds \\ @default_ttl_seconds) do
    case :ets.lookup(@cache_table, symbol) do
      [{^symbol, cache_entry}] ->
        if is_fresh?(cache_entry.cached_at, max_age_seconds) do
          {:ok, %{price: cache_entry.price, updated_at: cache_entry.updated_at}}
        else
          Logger.debug("Stale cache entry for #{symbol}")
          {:error, :stale}
        end

      [] ->
        Logger.debug("No cache entry found for #{symbol}")
        {:error, :not_found}
    end
  end

  @doc """
  Retrieves all cached prices.

  ## Returns
  List of {symbol, price_data} tuples for all cached symbols.
  """
  def get_all_prices do
    :ets.tab2list(@cache_table)
    |> Enum.map(fn {symbol, cache_entry} ->
      {symbol, %{price: cache_entry.price, updated_at: cache_entry.updated_at}}
    end)
  end

  @doc """
  Removes a specific symbol from the cache.
  """
  def delete_price(symbol) do
    :ets.delete(@cache_table, symbol)
    Logger.debug("Removed #{symbol} from cache")
    :ok
  end

  @doc """
  Clears all cached prices.
  """
  def clear_all do
    :ets.delete_all_objects(@cache_table)
    Logger.info("Cleared all cached prices")
    :ok
  end

  @doc """
  Performs cleanup of stale cache entries with enhanced TTL management.

  ## Parameters
  - max_age_seconds: Age threshold for cleanup (defaults to 1 hour)

  ## Returns
  Number of entries removed.
  """
  def cleanup_stale_entries(max_age_seconds \\ @default_ttl_seconds) do
    current_time = DateTime.utc_now()

    stale_keys =
      :ets.tab2list(@cache_table)
      |> Enum.filter(fn {_symbol, cache_entry} ->
        not is_fresh?(cache_entry.cached_at, max_age_seconds, current_time)
      end)
      |> Enum.map(fn {symbol, _cache_entry} -> symbol end)

    Enum.each(stale_keys, &:ets.delete(@cache_table, &1))

    count = length(stale_keys)

    if count > 0 do
      Logger.info("Cleaned up #{count} stale cache entries")
    end

    count
  end

  @doc """
  Enhanced cleanup with memory pressure awareness.

  Performs more aggressive cleanup when memory usage is high.
  """
  def cleanup_with_memory_pressure do
    stats = stats()
    memory_mb = stats.memory_bytes / (1024 * 1024)

    # Aggressive cleanup if cache is using more than 50MB
    max_age = if memory_mb > 50, do: @default_ttl_seconds / 2, else: @default_ttl_seconds

    cleanup_count = cleanup_stale_entries(trunc(max_age))

    Logger.debug("Memory-aware cleanup: #{cleanup_count} entries removed, #{memory_mb}MB cache size")

    %{
      entries_removed: cleanup_count,
      memory_mb: memory_mb,
      aggressive_cleanup: memory_mb > 50
    }
  end

  @doc """
  Returns cache statistics for monitoring.
  """
  def stats do
    info = :ets.info(@cache_table)

    %{
      size: info[:size],
      memory_words: info[:memory],
      memory_bytes: info[:memory] * :erlang.system_info(:wordsize)
    }
  end

  # Private helper functions

  defp is_fresh?(cached_at, max_age_seconds, current_time \\ DateTime.utc_now()) do
    age_seconds = DateTime.diff(current_time, cached_at, :second)
    age_seconds <= max_age_seconds
  end
end
