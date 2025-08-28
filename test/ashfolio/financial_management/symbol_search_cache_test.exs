defmodule Ashfolio.FinancialManagement.SymbolSearchCacheTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.FinancialManagement.SymbolSearch
  alias Ashfolio.Portfolio.Symbol

  @moduletag :ash_resources
  @moduletag :unit
  @moduletag :fast

  describe "SymbolSearch ETS caching" do
    setup do
      # Ensure clean cache state for each test
      SymbolSearch.clear_cache()

      # Create test symbols
      unique_id = System.unique_integer([:positive])

      {:ok, aapl} =
        Symbol.create(%{
          symbol: "AAPL#{unique_id}",
          name: "Apple Inc.",
          asset_class: :stock,
          data_source: :yahoo_finance
        })

      %{aapl: aapl, unique_id: unique_id}
    end

    test "caches search results with TTL", %{aapl: aapl, unique_id: unique_id} do
      query = "aapl#{unique_id}"

      # First call should hit the database and cache the result
      {:ok, results1} = SymbolSearch.search(query)
      assert length(results1) == 1
      assert hd(results1).id == aapl.id

      # Verify result is cached
      assert SymbolSearch.cache_hit?(query)
    end

    test "returns cached results on subsequent searches", %{unique_id: unique_id} do
      query = "aapl#{unique_id}"

      # Prime the cache
      {:ok, results1} = SymbolSearch.search(query)

      # Subsequent call should return cached results
      {:ok, results2} = SymbolSearch.search(query)

      # Results should be identical
      assert results1 == results2
      assert SymbolSearch.cache_hit?(query)
    end

    test "expires cache after TTL (5 minutes default)" do
      query = "test_ttl_#{System.unique_integer([:positive])}"

      # Mock a short TTL for testing (1 second)
      ttl_seconds = 1
      {:ok, _results} = SymbolSearch.search(query, ttl_seconds: ttl_seconds)

      # Verify cached
      assert SymbolSearch.cache_hit?(query)

      # Wait for TTL to expire
      # 1.1 seconds
      :timer.sleep(1100)

      # Should no longer be cached
      refute SymbolSearch.cache_hit?(query)
    end

    test "handles ETS table creation and cleanup" do
      # Verify table exists after module initialization
      assert :ets.info(:ashfolio_symbol_search_cache) != :undefined

      # Test manual table cleanup and recreation
      SymbolSearch.clear_cache()

      # Search should still work (table recreated if needed)
      {:ok, results} = SymbolSearch.search("test")
      assert is_list(results)
    end

    test "generates consistent cache keys" do
      # Test that the same query generates the same cache key
      # with whitespace
      query1 = "  AAPL  "
      # normalized
      query2 = "aapl"

      key1 = SymbolSearch.cache_key(query1)
      key2 = SymbolSearch.cache_key(query2)

      # Keys should be identical after normalization
      assert key1 == key2
      assert key1 == {:symbol_search, "aapl", 50}
    end

    test "handles multiple concurrent cache operations" do
      # Test concurrent access doesn't cause issues
      query = "concurrent_test_#{System.unique_integer([:positive])}"

      # Spawn multiple processes trying to search simultaneously
      tasks =
        for i <- 1..10 do
          Task.async(fn ->
            SymbolSearch.search("#{query}_#{i}")
          end)
        end

      # Wait for all tasks to complete
      results = Task.await_many(tasks)

      # All should succeed
      assert Enum.all?(results, fn result ->
               match?({:ok, _}, result)
             end)
    end

    test "cache respects max_results parameter" do
      query = "cache_max_results_#{System.unique_integer([:positive])}"

      # Search with different max_results - should create different cache entries
      {:ok, results_5} = SymbolSearch.search(query, max_results: 5)
      {:ok, results_10} = SymbolSearch.search(query, max_results: 10)

      # These should be separate cache entries since options differ
      assert is_list(results_5)
      assert is_list(results_10)
    end

    test "cache handles empty results" do
      nonexistent_query = "NONEXISTENT_#{System.unique_integer([:positive])}"

      # Search for non-existent symbol
      {:ok, empty_results} = SymbolSearch.search(nonexistent_query)
      assert empty_results == []

      # Should still cache the empty result
      assert SymbolSearch.cache_hit?(nonexistent_query)

      # Subsequent search should return cached empty result
      {:ok, cached_empty} = SymbolSearch.search(nonexistent_query)
      assert cached_empty == []
    end

    test "clears cache completely" do
      # Add some cached entries
      SymbolSearch.search("query1")
      SymbolSearch.search("query2")

      # Clear cache
      SymbolSearch.clear_cache()

      # Should no longer be cached
      refute SymbolSearch.cache_hit?("query1")
      refute SymbolSearch.cache_hit?("query2")
    end
  end

  describe "SymbolSearch cache performance" do
    test "cache hit is faster than cache miss" do
      query = "performance_test_#{System.unique_integer([:positive])}"

      # Time cache miss (first call)
      {miss_time, {:ok, _}} = :timer.tc(fn -> SymbolSearch.search(query) end)

      # Time cache hit (second call)
      {hit_time, {:ok, _}} = :timer.tc(fn -> SymbolSearch.search(query) end)

      # Cache hit should be significantly faster
      # Allow some variance for test stability
      assert hit_time < miss_time * 0.5
    end
  end

  describe "SymbolSearch cache configuration" do
    test "uses configurable TTL" do
      query = "configurable_ttl_#{System.unique_integer([:positive])}"
      # 2 seconds
      custom_ttl = 2

      {:ok, _results} = SymbolSearch.search(query, ttl_seconds: custom_ttl)

      # Should be cached
      assert SymbolSearch.cache_hit?(query)

      # Wait for custom TTL
      # 2.1 seconds
      :timer.sleep(2100)

      # Should be expired
      refute SymbolSearch.cache_hit?(query)
    end

    test "default TTL is 5 minutes" do
      query = "default_ttl_#{System.unique_integer([:positive])}"

      {:ok, _results} = SymbolSearch.search(query)

      # Should be cached with default TTL
      assert SymbolSearch.cache_hit?(query)

      # Should still be cached after a short time (way less than 5 minutes)
      :timer.sleep(100)
      assert SymbolSearch.cache_hit?(query)
    end
  end
end
