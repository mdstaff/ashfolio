defmodule Ashfolio.Portfolio.PerformanceCache do
  @moduledoc """
  ETS-based cache for expensive financial performance calculations.

  Provides high-performance caching for TWR, MWR, and rolling returns calculations
  with automatic invalidation on portfolio changes via PubSub integration.

  This module follows patterns established in the existing codebase for
  cache management, PubSub subscriptions, and error handling.
  """

  use GenServer

  require Logger

  @cache_table :performance_cache
  # 1 hour in seconds
  @default_ttl 3600

  # Public API

  @doc """
  Start the performance cache GenServer.

  Initializes the ETS table and subscribes to relevant PubSub topics
  for automatic cache invalidation.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Generate a cache key for performance calculations.

  ## Examples

      iex> PerformanceCache.cache_key(:twr, "account-123", 12)
      "twr:account-123:12"
      
      iex> PerformanceCache.cache_key(:mwr, "global", 36)
      "mwr:global:36"
  """
  def cache_key(calculation_type, account_id, period_months) do
    "#{calculation_type}:#{account_id}:#{period_months}"
  end

  @doc """
  Retrieve a cached performance calculation.

  Returns {:ok, value} if found and not expired, :miss otherwise.

  ## Examples

      iex> PerformanceCache.get("twr:account-123:12")
      {:ok, Decimal.new("15.67")}
      
      iex> PerformanceCache.get("nonexistent:key")
      :miss
  """
  def get(cache_key) do
    case :ets.lookup(@cache_table, cache_key) do
      [{^cache_key, value, expires_at}] ->
        current_time = :os.system_time(:second)

        if current_time < expires_at do
          Logger.debug("Cache hit: #{cache_key}")
          {:ok, value}
        else
          # Expired - remove from cache
          :ets.delete(@cache_table, cache_key)
          Logger.debug("Cache expired: #{cache_key}")
          :miss
        end

      [] ->
        Logger.debug("Cache miss: #{cache_key}")
        :miss
    end
  end

  @doc """
  Store a performance calculation result in cache.

  ## Parameters

    - cache_key: String cache key from cache_key/3
    - value: Calculation result to cache (typically Decimal)
    - ttl: Time-to-live in seconds (default: 1 hour)

  ## Examples

      iex> PerformanceCache.put("twr:account-123:12", Decimal.new("15.67"))
      :ok
      
      iex> PerformanceCache.put("mwr:global:24", Decimal.new("12.34"), 7200)
      :ok
  """
  def put(cache_key, value, ttl \\ @default_ttl) do
    expires_at = :os.system_time(:second) + ttl
    :ets.insert(@cache_table, {cache_key, value, expires_at})
    Logger.debug("Cached performance metric: #{cache_key} (expires in #{ttl}s)")
    :ok
  end

  @doc """
  Invalidate all cached calculations for a specific account.

  Called automatically when portfolio transactions are updated.

  ## Examples

      iex> PerformanceCache.invalidate_account("account-123")
      :ok
  """
  def invalidate_account(account_id) do
    GenServer.call(__MODULE__, {:invalidate_account, account_id})
  end

  @doc """
  Get cache statistics for monitoring and debugging.

  Returns information about cache size, hit rate, and memory usage.
  """
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @doc """
  Clear all cached entries (useful for testing).
  """
  def clear_all do
    GenServer.call(__MODULE__, :clear_all)
  end

  # GenServer Callbacks

  @impl true
  def init(_opts) do
    # Create ETS table for caching
    :ets.new(@cache_table, [:set, :public, :named_table])

    # Subscribe to portfolio-related PubSub events for cache invalidation
    Ashfolio.PubSub.subscribe("transactions")
    Ashfolio.PubSub.subscribe("accounts")

    Logger.info("Performance cache initialized with table: #{@cache_table}")

    # Initialize state to track cache statistics
    initial_state = %{
      hits: 0,
      misses: 0,
      invalidations: 0,
      started_at: :os.system_time(:second)
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:invalidate_account, account_id}, _from, state) do
    count = invalidate_account_entries(account_id)
    Logger.debug("Invalidated #{count} cache entries for account: #{account_id}")

    new_state = %{state | invalidations: state.invalidations + count}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    cache_info = :ets.info(@cache_table)
    current_time = :os.system_time(:second)
    uptime = current_time - state.started_at

    stats = %{
      entries: cache_info[:size],
      memory_words: cache_info[:memory],
      hits: state.hits,
      misses: state.misses,
      invalidations: state.invalidations,
      hit_rate: calculate_hit_rate(state.hits, state.misses),
      uptime_seconds: uptime
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_call(:clear_all, _from, state) do
    count = :ets.info(@cache_table)[:size]
    :ets.delete_all_objects(@cache_table)
    Logger.info("Cleared all #{count} cache entries")

    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:transaction_created, transaction}, state) do
    # Invalidate cache for affected account
    account_id = transaction.account_id
    invalidate_account_entries(account_id)

    new_state = %{state | invalidations: state.invalidations + 1}
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:transaction_updated, transaction}, state) do
    account_id = transaction.account_id
    invalidate_account_entries(account_id)

    new_state = %{state | invalidations: state.invalidations + 1}
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:transaction_deleted, transaction}, state) do
    account_id = transaction.account_id
    invalidate_account_entries(account_id)

    new_state = %{state | invalidations: state.invalidations + 1}
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:account_updated, _account}, state) do
    # Account updates might affect global calculations
    invalidate_global_entries()

    new_state = %{state | invalidations: state.invalidations + 1}
    {:noreply, new_state}
  end

  @impl true
  def handle_info(_msg, state) do
    # Ignore other PubSub messages
    {:noreply, state}
  end

  # Private helper functions

  defp invalidate_account_entries(account_id) do
    # Use a simpler approach to find and delete matching entries
    all_keys = :ets.select(@cache_table, [{:"$1", [], [:"$1"]}])

    matching_keys =
      Enum.filter(all_keys, fn {key, _value, _expires} ->
        String.contains?(key, ":#{account_id}:")
      end)

    # Delete matching entries
    count =
      Enum.reduce(matching_keys, 0, fn {key, _value, _expires}, acc ->
        :ets.delete(@cache_table, key)
        acc + 1
      end)

    count
  end

  defp invalidate_global_entries do
    # Invalidate entries that use "global" account ID
    all_keys = :ets.select(@cache_table, [{:"$1", [], [:"$1"]}])

    global_keys =
      Enum.filter(all_keys, fn {key, _value, _expires} ->
        String.contains?(key, ":global:")
      end)

    Enum.each(global_keys, fn {key, _value, _expires} ->
      :ets.delete(@cache_table, key)
    end)

    length(global_keys)
  end

  defp calculate_hit_rate(hits, misses) when hits + misses > 0 do
    rate = hits / (hits + misses) * 100
    Float.round(rate, 2)
  end

  defp calculate_hit_rate(_hits, _misses), do: 0.0
end
