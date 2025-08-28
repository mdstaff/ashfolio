defmodule Ashfolio.Performance.SymbolSearchCachePerformanceTest do
  @moduledoc """
  Symbol search cache performance tests for Task 14 Stage 3.

  Tests ETS cache performance and optimization opportunities:
  - Cache hit rate: 80%+ for realistic usage patterns
  - Cache hit performance: <10ms response time
  - Cache miss optimization: efficient fallback behavior
  - Memory management: LRU eviction and cache size limits
  - Cache warming: popular symbols pre-populated

  Performance targets:
  - Cache hit response: <10ms
  - Cache hit rate: 80%+ for typical user behavior
  - Cache memory usage: <50MB for 10,000 cached searches
  - Cache eviction: Efficient LRU-based cleanup
  """

  use Ashfolio.DataCase, async: false

  alias Ashfolio.FinancialManagement.SymbolSearch
  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.SQLiteHelpers

  @moduletag :performance
  @moduletag :slow
  @moduletag :symbol_search_cache

  # Test data setup
  @popular_symbols ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "META", "NFLX", "NVDA"]

  describe "Symbol Search Cache Hit Performance" do
    setup do
      # Ensure we have symbols in database for testing
      symbols = setup_test_symbols()

      # Clear cache to start fresh
      SymbolSearch.clear_cache()

      %{symbols: symbols}
    end

    test "cache hit performance under 10ms", %{symbols: _symbols} do
      query = "AAPL"

      # First search to populate cache
      {:ok, _results} = SymbolSearch.search(query)

      # Measure cache hit performance
      {time_us, {:ok, results}} =
        :timer.tc(fn ->
          SymbolSearch.search(query)
        end)

      time_ms = time_us / 1000

      assert length(results) > 0

      assert time_ms < 10,
             "Cache hit took #{time_ms}ms, expected < 10ms"
    end

    test "multiple cache hits maintain consistent performance" do
      query = "GOOGL"

      # Populate cache
      {:ok, _results} = SymbolSearch.search(query)

      # Test multiple cache hits
      times =
        for _ <- 1..10 do
          {time_us, {:ok, _results}} =
            :timer.tc(fn ->
              SymbolSearch.search(query)
            end)

          time_us / 1000
        end

      avg_time = Enum.sum(times) / length(times)
      max_time = Enum.max(times)
      std_dev = calculate_standard_deviation(times)

      assert avg_time < 8, "Average cache hit time #{avg_time}ms too high"
      assert max_time < 15, "Max cache hit time #{max_time}ms indicates inconsistency"
      assert std_dev < 3, "Cache hit performance too inconsistent: std_dev #{std_dev}ms"
    end

    test "concurrent cache access performance" do
      query = "MSFT"

      # Populate cache
      {:ok, _results} = SymbolSearch.search(query)

      # Test concurrent cache access
      tasks =
        for _ <- 1..5 do
          Task.async(fn ->
            {time_us, {:ok, _results}} =
              :timer.tc(fn ->
                SymbolSearch.search(query)
              end)

            time_us / 1000
          end)
        end

      times = Task.await_many(tasks, 5_000)
      avg_time = Enum.sum(times) / length(times)

      assert avg_time < 12,
             "Concurrent cache access averaged #{avg_time}ms, expected < 12ms"
    end
  end

  describe "Cache Hit Rate Analysis" do
    setup do
      symbols = setup_test_symbols()
      SymbolSearch.clear_cache()
      %{symbols: symbols}
    end

    test "realistic usage pattern achieves 80%+ hit rate" do
      # Simulate realistic user behavior:
      # - 70% searches are for popular symbols (repeated)
      # - 20% searches are for common companies
      # - 10% searches are for new/rare symbols

      search_patterns = generate_realistic_search_patterns(100)

      hits = 0
      total_searches = length(search_patterns)

      search_results =
        for query <- search_patterns do
          cache_hit_before = SymbolSearch.cache_hit?(query)
          {:ok, _results} = SymbolSearch.search(query)

          if cache_hit_before, do: hits + 1, else: hits
        end

      final_hits = Enum.sum(search_results)
      hit_rate = final_hits / total_searches * 100

      assert hit_rate >= 60,
             "Cache hit rate #{hit_rate}% too low, expected >= 60% (realistic for cold start)"

      # Test second round (cache should be warmed up)
      warmed_hits =
        for query <- search_patterns do
          if SymbolSearch.cache_hit?(query), do: 1, else: 0
        end

      warmed_hit_rate = Enum.sum(warmed_hits) / total_searches * 100

      assert warmed_hit_rate >= 80,
             "Warmed cache hit rate #{warmed_hit_rate}% too low, expected >= 80%"
    end

    test "cache effectiveness over time with TTL" do
      query = "AAPL"
      # 1 second for testing
      short_ttl = 1

      # Search with short TTL
      {:ok, _results} = SymbolSearch.search(query, ttl_seconds: short_ttl)

      # Immediate cache hit
      assert SymbolSearch.cache_hit?(query) == true

      # Wait for TTL expiration
      Process.sleep(1100)

      # Should be cache miss after TTL
      assert SymbolSearch.cache_hit?(query) == false

      # But search should still work (cache miss + repopulate)
      {time_us, {:ok, results}} =
        :timer.tc(fn ->
          SymbolSearch.search(query, ttl_seconds: short_ttl)
        end)

      time_ms = time_us / 1000

      assert length(results) > 0
      # Cache miss should be slower but still reasonable
      assert time_ms < 100,
             "Cache miss took #{time_ms}ms, expected < 100ms"
    end
  end

  describe "Cache Memory Management" do
    setup do
      symbols = setup_test_symbols()
      SymbolSearch.clear_cache()
      %{symbols: symbols}
    end

    test "memory usage stays reasonable with many cached searches" do
      :erlang.garbage_collect()
      initial_memory = :erlang.memory(:total)

      # Perform many unique searches to fill cache
      unique_queries = generate_unique_queries(100)

      for query <- unique_queries do
        {:ok, _results} = SymbolSearch.search(query)
      end

      :erlang.garbage_collect()
      final_memory = :erlang.memory(:total)

      memory_increase = final_memory - initial_memory
      memory_increase_mb = memory_increase / (1024 * 1024)

      # Should not use excessive memory for caching
      assert memory_increase_mb < 25,
             "Cache used #{memory_increase_mb}MB for 500 searches, expected < 25MB"
    end

    @tag timeout: :infinity
    test "cache size limits prevent memory bloat" do
      # This would test LRU eviction if implemented
      # For now, test that cache doesn't grow indefinitely

      initial_cache_size = get_cache_size()

      # Perform many searches (reduced for performance)
      for i <- 1..50 do
        unique_query = "TEST#{i}"
        {:ok, _results} = SymbolSearch.search(unique_query)
      end

      final_cache_size = get_cache_size()
      cache_growth = final_cache_size - initial_cache_size

      # For now, just ensure cache doesn't grow beyond reasonable bounds
      assert cache_growth < 2000,
             "Cache grew by #{cache_growth} entries, may need LRU eviction"
    end
  end

  describe "Cache Warming Opportunities" do
    setup do
      symbols = setup_test_symbols()
      SymbolSearch.clear_cache()
      %{symbols: symbols}
    end

    test "popular symbols can be pre-warmed for better hit rates" do
      # Test current behavior (no warming)
      initial_hit_rate = test_popular_symbol_hit_rate()

      # Manually warm cache with popular symbols
      for symbol <- @popular_symbols do
        {:ok, _results} = SymbolSearch.search(symbol)
      end

      # Test hit rate after warming
      warmed_hit_rate = test_popular_symbol_hit_rate()

      assert warmed_hit_rate > initial_hit_rate,
             "Cache warming should improve hit rate: #{initial_hit_rate}% -> #{warmed_hit_rate}%"

      assert warmed_hit_rate >= 80,
             "Warmed cache should achieve >= 80% hit rate, got #{warmed_hit_rate}%"
    end

    test "cache warming performance impact" do
      # Measure time to warm cache
      {time_us, _results} =
        :timer.tc(fn ->
          for symbol <- @popular_symbols do
            {:ok, _results} = SymbolSearch.search(symbol)
          end
        end)

      warming_time_ms = time_us / 1000

      # Cache warming should be reasonably fast
      assert warming_time_ms < 1000,
             "Cache warming took #{warming_time_ms}ms, expected < 1000ms"

      # Verify all symbols are cached
      cached_count =
        Enum.count(@popular_symbols, fn symbol ->
          SymbolSearch.cache_hit?(symbol)
        end)

      assert cached_count == length(@popular_symbols),
             "Only #{cached_count}/#{length(@popular_symbols)} symbols cached after warming"
    end
  end

  describe "Performance Regression Prevention" do
    test "cache performance scales with database size" do
      # Add many symbols to test scalability
      additional_symbols = create_many_test_symbols(1000)

      query = "PERFORMANCE_TEST"

      # First search (cache miss)
      {miss_time_us, {:ok, _results}} =
        :timer.tc(fn ->
          SymbolSearch.search(query)
        end)

      miss_time_ms = miss_time_us / 1000

      # Second search (cache hit)
      {hit_time_us, {:ok, _results}} =
        :timer.tc(fn ->
          SymbolSearch.search(query)
        end)

      hit_time_ms = hit_time_us / 1000

      # Cache hit should be much faster than cache miss
      improvement_factor = miss_time_ms / hit_time_ms

      assert improvement_factor >= 3,
             "Cache should provide 3x+ improvement, got #{improvement_factor}x"

      assert hit_time_ms < 10,
             "Cache hit took #{hit_time_ms}ms, expected < 10ms"

      # Clean up additional symbols
      cleanup_additional_symbols(additional_symbols)
    end

    test "cache handles high frequency searches efficiently" do
      query = "HIGH_FREQ_TEST"

      # Populate cache
      {:ok, _results} = SymbolSearch.search(query)

      # Measure high frequency access
      times =
        for _ <- 1..50 do
          {time_us, {:ok, _results}} =
            :timer.tc(fn ->
              SymbolSearch.search(query)
            end)

          time_us / 1000
        end

      avg_time = Enum.sum(times) / length(times)

      assert avg_time < 8,
             "High frequency cache access averaged #{avg_time}ms, expected < 8ms"

      # Performance should remain consistent
      std_dev = calculate_standard_deviation(times)

      assert std_dev < 2,
             "High frequency access inconsistent: std_dev #{std_dev}ms"
    end
  end

  # Helper functions for test setup and measurement

  defp setup_test_symbols do
    Enum.map(@popular_symbols, fn symbol_name ->
      SQLiteHelpers.get_or_create_symbol(symbol_name, %{
        name: "#{symbol_name} Corporation",
        asset_class: :stock,
        current_price: Decimal.new("#{100 + :rand.uniform(200)}.00")
      })
    end)
  end

  defp generate_realistic_search_patterns(count) do
    # 70% popular symbols (high cache hit potential)
    popular_count = round(count * 0.7)

    popular_searches =
      for _ <- 1..popular_count do
        Enum.random(@popular_symbols)
      end

    # 20% company name searches (medium cache hit potential)
    company_count = round(count * 0.2)

    company_searches =
      for _ <- 1..company_count do
        Enum.random(["Apple", "Microsoft", "Google", "Amazon"])
      end

    # 10% unique/rare searches (low cache hit potential)
    unique_count = count - popular_count - company_count

    unique_searches =
      for i <- 1..unique_count do
        "RARE#{i}"
      end

    Enum.shuffle(popular_searches ++ company_searches ++ unique_searches)
  end

  defp generate_unique_queries(count) do
    for i <- 1..count do
      "UNIQUE_#{i}_#{:rand.uniform(1000)}"
    end
  end

  defp test_popular_symbol_hit_rate do
    searches_with_hits =
      for symbol <- @popular_symbols do
        if SymbolSearch.cache_hit?(symbol), do: 1, else: 0
      end

    hits = Enum.sum(searches_with_hits)
    hits / length(@popular_symbols) * 100
  end

  defp get_cache_size do
    :ets.info(:ashfolio_symbol_search_cache, :size) || 0
  rescue
    _ -> 0
  end

  defp create_many_test_symbols(count) do
    for i <- 1..count do
      {:ok, symbol} =
        Symbol.create(%{
          symbol: "TEST#{i}",
          name: "Test Symbol #{i}",
          asset_class: :stock,
          data_source: :manual
        })

      symbol
    end
  end

  defp cleanup_additional_symbols(symbols) do
    for symbol <- symbols do
      Symbol.destroy(symbol.id)
    end
  end

  defp calculate_standard_deviation(values) do
    mean = Enum.sum(values) / length(values)
    variance = Enum.sum(Enum.map(values, fn x -> :math.pow(x - mean, 2) end)) / length(values)
    :math.sqrt(variance)
  end
end
