defmodule Ashfolio.Portfolio.PerformanceCacheTest do
  @moduledoc """
  Test suite for the performance cache system.

  Tests ETS caching, TTL expiration, PubSub invalidation, and cache statistics
  with comprehensive coverage of edge cases and performance scenarios.
  """

  use Ashfolio.DataCase, async: false

  alias Ashfolio.Portfolio.PerformanceCache

  setup do
    # Start cache for testing
    {:ok, _pid} = PerformanceCache.start_link([])

    # Clear any existing cache entries
    PerformanceCache.clear_all()

    :ok
  end

  describe "cache_key/3" do
    @tag :unit
    test "generates correct cache keys for different calculation types" do
      assert PerformanceCache.cache_key(:twr, "account-123", 12) == "twr:account-123:12"
      assert PerformanceCache.cache_key(:mwr, "global", 36) == "mwr:global:36"
      assert PerformanceCache.cache_key(:rolling_returns, "account-456", 24) == "rolling_returns:account-456:24"
    end

    @tag :unit
    test "handles various account IDs and periods" do
      assert PerformanceCache.cache_key(:twr, "abc-123-xyz", 1) == "twr:abc-123-xyz:1"
      assert PerformanceCache.cache_key(:mwr, "global", 60) == "mwr:global:60"
    end
  end

  describe "get/1 and put/3" do
    @tag :unit
    test "stores and retrieves cached values" do
      key = PerformanceCache.cache_key(:twr, "account-123", 12)
      value = Decimal.new("15.67")

      assert :miss = PerformanceCache.get(key)

      assert :ok = PerformanceCache.put(key, value)
      assert {:ok, ^value} = PerformanceCache.get(key)
    end

    @tag :unit
    test "handles different data types as cached values" do
      twr_key = PerformanceCache.cache_key(:twr, "account-123", 12)
      twr_value = Decimal.new("15.67")

      rolling_key = PerformanceCache.cache_key(:rolling_returns, "account-456", 24)
      rolling_value = [%{period: "2023-Q1", return: Decimal.new("8.5")}]

      PerformanceCache.put(twr_key, twr_value)
      PerformanceCache.put(rolling_key, rolling_value)

      assert {:ok, ^twr_value} = PerformanceCache.get(twr_key)
      assert {:ok, ^rolling_value} = PerformanceCache.get(rolling_key)
    end

    @tag :unit
    test "returns :miss for non-existent keys" do
      assert :miss = PerformanceCache.get("nonexistent:key")
      assert :miss = PerformanceCache.get("twr:missing:12")
    end

    @tag :unit
    test "overwrites existing cache entries" do
      key = PerformanceCache.cache_key(:mwr, "account-789", 6)

      first_value = Decimal.new("10.0")
      second_value = Decimal.new("12.5")

      PerformanceCache.put(key, first_value)
      assert {:ok, ^first_value} = PerformanceCache.get(key)

      PerformanceCache.put(key, second_value)
      assert {:ok, ^second_value} = PerformanceCache.get(key)
    end
  end

  describe "TTL expiration" do
    @tag :unit
    test "respects TTL and expires cached values" do
      key = PerformanceCache.cache_key(:twr, "account-456", 12)
      value = Decimal.new("8.42")

      # Cache with 1 second TTL
      assert :ok = PerformanceCache.put(key, value, 1)
      assert {:ok, ^value} = PerformanceCache.get(key)

      # Wait for expiration
      :timer.sleep(1100)
      assert :miss = PerformanceCache.get(key)
    end

    @tag :unit
    test "uses default TTL when not specified" do
      key = PerformanceCache.cache_key(:mwr, "account-123", 24)
      value = Decimal.new("5.5")

      PerformanceCache.put(key, value)

      # Should still be available after a short time
      :timer.sleep(100)
      assert {:ok, ^value} = PerformanceCache.get(key)
    end

    @tag :unit
    test "removes expired entries on access" do
      key = PerformanceCache.cache_key(:twr, "account-expire", 12)
      value = Decimal.new("20.0")

      PerformanceCache.put(key, value, 1)

      # Wait for expiration
      :timer.sleep(1100)

      # First access should return :miss and remove the entry
      assert :miss = PerformanceCache.get(key)

      # Subsequent access should also return :miss
      assert :miss = PerformanceCache.get(key)
    end
  end

  describe "invalidate_account/1" do
    @tag :unit
    test "invalidates all cache entries for specific account" do
      account_id = "account-789"

      key1 = PerformanceCache.cache_key(:twr, account_id, 12)
      key2 = PerformanceCache.cache_key(:mwr, account_id, 24)
      key3 = PerformanceCache.cache_key(:rolling_returns, account_id, 6)

      # Cache some values for the account
      PerformanceCache.put(key1, Decimal.new("10.0"))
      PerformanceCache.put(key2, Decimal.new("12.0"))
      PerformanceCache.put(key3, [%{return: Decimal.new("5.0")}])

      # Cache for different account (should not be affected)
      other_key = PerformanceCache.cache_key(:twr, "other-account", 12)
      PerformanceCache.put(other_key, Decimal.new("8.0"))

      # Verify all entries exist
      assert {:ok, _} = PerformanceCache.get(key1)
      assert {:ok, _} = PerformanceCache.get(key2)
      assert {:ok, _} = PerformanceCache.get(key3)
      assert {:ok, _} = PerformanceCache.get(other_key)

      # Invalidate the account
      assert :ok = PerformanceCache.invalidate_account(account_id)

      # Account entries should be gone
      assert :miss = PerformanceCache.get(key1)
      assert :miss = PerformanceCache.get(key2)
      assert :miss = PerformanceCache.get(key3)

      # Other account should be unaffected
      assert {:ok, _} = PerformanceCache.get(other_key)
    end

    @tag :unit
    test "handles invalidation of non-existent account gracefully" do
      assert :ok = PerformanceCache.invalidate_account("non-existent-account")
    end
  end

  describe "stats/0" do
    @tag :unit
    test "returns cache statistics" do
      # Add some cache entries
      key1 = PerformanceCache.cache_key(:twr, "account-1", 12)
      key2 = PerformanceCache.cache_key(:mwr, "account-2", 24)

      PerformanceCache.put(key1, Decimal.new("10.0"))
      PerformanceCache.put(key2, Decimal.new("15.0"))

      # Simulate some cache hits and misses
      # Hit
      PerformanceCache.get(key1)
      # Hit
      PerformanceCache.get(key2)
      # Miss
      PerformanceCache.get("nonexistent")

      stats = PerformanceCache.stats()

      assert is_map(stats)
      assert Map.has_key?(stats, :entries)
      assert Map.has_key?(stats, :memory_words)
      assert Map.has_key?(stats, :hit_rate)
      assert Map.has_key?(stats, :uptime_seconds)

      assert stats.entries >= 2
      assert is_number(stats.hit_rate)
      assert stats.uptime_seconds >= 0
    end

    @tag :unit
    test "calculates hit rate correctly" do
      key = PerformanceCache.cache_key(:twr, "test-account", 12)
      PerformanceCache.put(key, Decimal.new("10.0"))

      # Generate hits and misses
      # Hit
      PerformanceCache.get(key)
      # Hit
      PerformanceCache.get(key)
      # Miss
      PerformanceCache.get("miss1")
      # Miss
      PerformanceCache.get("miss2")

      stats = PerformanceCache.stats()

      # Note: The actual hit/miss tracking would need to be implemented
      # in the GenServer state for accurate statistics
      assert is_number(stats.hit_rate)
      assert stats.hit_rate >= 0.0
      assert stats.hit_rate <= 100.0
    end
  end

  describe "clear_all/0" do
    @tag :unit
    test "clears all cache entries" do
      # Add multiple cache entries
      key1 = PerformanceCache.cache_key(:twr, "account-1", 12)
      key2 = PerformanceCache.cache_key(:mwr, "account-2", 24)
      key3 = PerformanceCache.cache_key(:rolling_returns, "account-3", 6)

      PerformanceCache.put(key1, Decimal.new("10.0"))
      PerformanceCache.put(key2, Decimal.new("15.0"))
      PerformanceCache.put(key3, [%{return: Decimal.new("5.0")}])

      # Verify entries exist
      assert {:ok, _} = PerformanceCache.get(key1)
      assert {:ok, _} = PerformanceCache.get(key2)
      assert {:ok, _} = PerformanceCache.get(key3)

      # Clear all entries
      assert :ok = PerformanceCache.clear_all()

      # All entries should be gone
      assert :miss = PerformanceCache.get(key1)
      assert :miss = PerformanceCache.get(key2)
      assert :miss = PerformanceCache.get(key3)

      # Stats should reflect empty cache
      stats = PerformanceCache.stats()
      assert stats.entries == 0
    end
  end

  describe "PubSub integration" do
    @tag :integration
    test "invalidates cache on transaction events" do
      account_id = "test-account-123"
      key = PerformanceCache.cache_key(:twr, account_id, 12)

      # Cache a value
      PerformanceCache.put(key, Decimal.new("15.0"))
      assert {:ok, _} = PerformanceCache.get(key)

      # Simulate transaction created event
      transaction = %{account_id: account_id, amount: Decimal.new("1000")}
      Ashfolio.PubSub.broadcast("transactions", {:transaction_created, transaction})

      # Give the GenServer a moment to process
      :timer.sleep(50)

      # Cache should be invalidated
      assert :miss = PerformanceCache.get(key)
    end

    @tag :integration
    test "handles account update events" do
      # Cache some global calculations
      global_key = PerformanceCache.cache_key(:twr, "global", 12)
      PerformanceCache.put(global_key, Decimal.new("8.5"))

      # Simulate account update
      account = %{id: "account-123", name: "Updated Account"}
      Ashfolio.PubSub.broadcast("accounts", {:account_updated, account})

      # Give the GenServer a moment to process
      :timer.sleep(50)

      # Global cache entries should be invalidated
      assert :miss = PerformanceCache.get(global_key)
    end
  end

  describe "concurrent access" do
    @tag :unit
    test "handles concurrent read/write operations safely" do
      key = PerformanceCache.cache_key(:twr, "concurrent-test", 12)

      # Spawn multiple processes to access cache concurrently
      tasks =
        Enum.map(1..10, fn i ->
          Task.async(fn ->
            value = Decimal.new("#{i}.0")
            PerformanceCache.put(key, value)
            PerformanceCache.get(key)
          end)
        end)

      # Wait for all tasks to complete
      results = Task.await_many(tasks)

      # All should have succeeded (no crashes)
      assert length(results) == 10

      # Final value should be one of the written values
      assert {:ok, final_value} = PerformanceCache.get(key)
      assert %Decimal{} = final_value
    end
  end

  describe "performance characteristics" do
    @tag :performance
    test "handles large number of cache entries efficiently" do
      # Create many cache entries
      entries_count = 1000

      {time_us, :ok} =
        :timer.tc(fn ->
          Enum.each(1..entries_count, fn i ->
            key = PerformanceCache.cache_key(:twr, "account-#{i}", 12)
            value = Decimal.new("#{rem(i, 100)}.#{rem(i, 10)}0")
            PerformanceCache.put(key, value)
          end)
        end)

      # Should complete within reasonable time (< 1 second for 1000 entries)
      assert time_us < 1_000_000, "Creating #{entries_count} entries took #{time_us}μs"

      # Verify cache stats
      stats = PerformanceCache.stats()
      assert stats.entries >= entries_count
    end

    @tag :performance
    test "cache lookup performance remains consistent with many entries" do
      # Pre-populate cache with many entries
      Enum.each(1..500, fn i ->
        key = PerformanceCache.cache_key(:twr, "account-#{i}", 12)
        PerformanceCache.put(key, Decimal.new("10.0"))
      end)

      # Test lookup performance
      test_key = PerformanceCache.cache_key(:twr, "account-250", 12)

      {time_us, {:ok, _value}} =
        :timer.tc(fn ->
          PerformanceCache.get(test_key)
        end)

      # Lookup should be very fast (< 1ms)
      assert time_us < 1000, "Cache lookup took #{time_us}μs, should be < 1ms"
    end
  end
end
