defmodule Ashfolio.Performance.SymbolCacheSimpleTest do
  @moduledoc """
  Simplified symbol search cache performance tests for Task 14 Stage 3.

  Basic performance tests to establish baseline:
  - Cache hit performance: <10ms
  - Cache miss vs hit comparison
  - Basic hit rate measurement
  """

  use Ashfolio.DataCase, async: false

  alias Ashfolio.FinancialManagement.SymbolSearch
  alias Ashfolio.SQLiteHelpers

  @moduletag :performance
  @moduletag :slow
  @moduletag :symbol_cache

  describe "Basic Cache Performance" do
    setup do
      # Create test symbols
      _apple =
        SQLiteHelpers.get_or_create_symbol("AAPL", %{
          name: "Apple Inc.",
          asset_class: :stock
        })

      _google =
        SQLiteHelpers.get_or_create_symbol("GOOGL", %{
          name: "Alphabet Inc.",
          asset_class: :stock
        })

      # Clear cache
      SymbolSearch.clear_cache()

      :ok
    end

    test "cache hit performance under 10ms" do
      query = "AAPL"

      # First search (cache miss)
      {:ok, _results} = SymbolSearch.search(query)

      # Second search (cache hit)
      {time_us, {:ok, results}} =
        :timer.tc(fn ->
          SymbolSearch.search(query)
        end)

      time_ms = time_us / 1000

      assert length(results) > 0

      assert time_ms < 10,
             "Cache hit took #{time_ms}ms, expected < 10ms"
    end

    test "cache miss vs cache hit performance comparison" do
      query = "GOOGL"

      # Measure cache miss
      {miss_time_us, {:ok, miss_results}} =
        :timer.tc(fn ->
          SymbolSearch.search(query)
        end)

      miss_time_ms = miss_time_us / 1000

      # Measure cache hit
      {hit_time_us, {:ok, hit_results}} =
        :timer.tc(fn ->
          SymbolSearch.search(query)
        end)

      hit_time_ms = hit_time_us / 1000

      # Verify results are equivalent
      assert length(miss_results) == length(hit_results)

      # Cache hit should be significantly faster
      improvement_factor = miss_time_ms / hit_time_ms

      assert improvement_factor >= 2,
             "Cache should provide 2x+ improvement, got #{improvement_factor}x (#{miss_time_ms}ms -> #{hit_time_ms}ms)"

      assert hit_time_ms < 10,
             "Cache hit took #{hit_time_ms}ms, expected < 10ms"
    end

    test "cache hit verification" do
      query = "AAPL"

      # Should be cache miss initially
      assert SymbolSearch.cache_hit?(query) == false

      # First search populates cache
      {:ok, _results} = SymbolSearch.search(query)

      # Should be cache hit now
      assert SymbolSearch.cache_hit?(query) == true
    end

    test "multiple cache hits maintain performance" do
      query = "GOOGL"

      # Populate cache
      {:ok, _results} = SymbolSearch.search(query)

      # Test 5 cache hits
      times =
        for _ <- 1..5 do
          {time_us, {:ok, _results}} =
            :timer.tc(fn ->
              SymbolSearch.search(query)
            end)

          time_us / 1000
        end

      avg_time = Enum.sum(times) / length(times)
      max_time = Enum.max(times)

      assert avg_time < 8,
             "Average cache hit time #{avg_time}ms too high"

      assert max_time < 15,
             "Max cache hit time #{max_time}ms indicates inconsistency"
    end

    test "basic hit rate measurement" do
      queries = ["AAPL", "GOOGL", "AAPL", "GOOGL", "AAPL"]

      {cache_hits, _} =
        Enum.reduce(queries, {0, []}, fn query, {hits, acc} ->
          was_cache_hit = SymbolSearch.cache_hit?(query)
          {:ok, _results} = SymbolSearch.search(query)

          new_hits = if was_cache_hit, do: hits + 1, else: hits
          {new_hits, [was_cache_hit | acc]}
        end)

      hit_rate = cache_hits / length(queries) * 100

      # Expected: first AAPL=miss, first GOOGL=miss, second AAPL=hit, second GOOGL=hit, third AAPL=hit
      # Hit rate should be 60% (3 hits out of 5 searches)
      assert hit_rate >= 50,
             "Hit rate #{hit_rate}% lower than expected for repeated searches"
    end
  end

  describe "Cache Memory and TTL" do
    test "cache respects TTL expiration" do
      query = "AAPL"
      # 1 second
      short_ttl = 1

      # Search with short TTL
      {:ok, _results} = SymbolSearch.search(query, ttl_seconds: short_ttl)

      # Should be cached immediately
      assert SymbolSearch.cache_hit?(query) == true

      # Wait for expiration
      Process.sleep(1100)

      # Should be expired now
      assert SymbolSearch.cache_hit?(query) == false
    end

    test "cache clear functionality" do
      query = "AAPL"

      # Populate cache
      {:ok, _results} = SymbolSearch.search(query)
      assert SymbolSearch.cache_hit?(query) == true

      # Clear cache
      SymbolSearch.clear_cache()

      # Should be cache miss now
      assert SymbolSearch.cache_hit?(query) == false
    end
  end
end
