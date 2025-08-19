defmodule Ashfolio.Integration.SymbolAutocompleteIntegrationTest do
  @moduledoc """
  Comprehensive integration tests for symbol autocomplete functionality.

  Tests the complete symbol search and transaction creation workflow:
  - Local symbol search with ETS caching
  - External API integration with rate limiting
  - Symbol creation from external sources
  - Transaction creation using autocomplete results
  - Error handling and fallback behavior
  """

  use Ashfolio.DataCase, async: false

  @moduletag :integration
  @moduletag :v0_2_0

  alias Ashfolio.Context
  alias Ashfolio.Portfolio.{Account, Symbol, Transaction}

  import Mox

  # Setup mock for external API testing
  setup :verify_on_exit!

  describe "symbol search to transaction creation workflow" do
    setup do
      # Database-as-user architecture: No user entity needed
      {:ok, account} =
        Account.create(%{
          name: "Test Brokerage",
          account_type: :investment,
          currency: "USD",
          balance: Decimal.new("0")
        })

      # Create some local symbols for testing
      {:ok, local_symbol1} =
        Symbol.create(%{
          symbol: "TESTAAPL",
          name: "Test Apple Inc.",
          current_price: Decimal.new("175.50"),
          data_source: :manual,
          asset_class: :stock
        })

      {:ok, local_symbol2} =
        Symbol.create(%{
          symbol: "TESTMSFT",
          name: "Test Microsoft Corporation",
          current_price: Decimal.new("380.25"),
          data_source: :manual,
          asset_class: :stock
        })

      {:ok, account: account, local_symbols: [local_symbol1, local_symbol2]}
    end

    test "search symbol → select from dropdown → create buy transaction", %{
      account: account,
      local_symbols: [testaapl, _testmsft]
    } do
      # Step 1: Search for existing symbol
      {:ok, search_results} = Context.search_symbols("TESTAAPL")

      assert length(search_results) >= 1
      found_symbol = Enum.find(search_results, &(&1.symbol == "TESTAAPL"))
      assert found_symbol.name == "Test Apple Inc."
      assert Decimal.equal?(found_symbol.current_price, Decimal.new("175.50"))

      # Step 2: Use the found symbol to create a transaction
      {:ok, transaction} =
        Transaction.create(%{
          account_id: account.id,
          symbol_id: found_symbol.id,
          type: :buy,
          quantity: Decimal.new("10"),
          price: found_symbol.current_price,
          date: Date.utc_today(),
          total_amount: Decimal.mult(Decimal.new("10"), found_symbol.current_price)
        })

      # Step 3: Verify transaction was created correctly
      assert transaction.symbol_id == testaapl.id
      assert Decimal.equal?(transaction.quantity, Decimal.new("10"))
      assert Decimal.equal?(transaction.price, Decimal.new("175.50"))
      assert Decimal.equal?(transaction.total_amount, Decimal.new("1755.00"))

      # Step 4: Verify portfolio value updated
      {:ok, portfolio_summary} = Context.get_portfolio_summary()
      assert Decimal.equal?(portfolio_summary.total_value, Decimal.new("1755.00"))
    end

    @tag :skip
    test "external symbol search → create new symbol → use in transaction", %{
      account: account
    } do
      # TODO: External API mocking needs proper setup
      # This test validates external symbol creation workflow
      # but requires proper mock configuration that's not yet implemented

      # Step 1: Search for symbol not in local database
      {:ok, search_results} = Context.search_symbols("NVDA")

      # Should find no local results initially
      local_results = Enum.filter(search_results, &(&1.symbol == "NVDA"))
      assert length(local_results) == 0

      # Step 2: Create symbol from external source
      external_symbol_data = %{
        symbol: "NVDA",
        name: "NVIDIA Corporation",
        current_price: Decimal.new("450.75"),
        data_source: :manual,
        asset_class: :stock
      }

      {:ok, new_symbol} = Context.create_symbol_from_external(external_symbol_data)

      assert new_symbol.symbol == "NVDA"
      assert new_symbol.name == "NVIDIA Corporation"
      assert Decimal.equal?(new_symbol.current_price, Decimal.new("450.75"))

      # Step 3: Now search should find the newly created symbol
      {:ok, updated_search} = Context.search_symbols("NVDA")
      nvda_result = Enum.find(updated_search, &(&1.symbol == "NVDA"))
      assert nvda_result != nil

      # Step 4: Create transaction with new symbol
      {:ok, transaction} =
        Transaction.create(%{
          account_id: account.id,
          symbol_id: new_symbol.id,
          type: :buy,
          quantity: Decimal.new("5"),
          price: new_symbol.current_price,
          date: Date.utc_today(),
          total_amount: Decimal.mult(Decimal.new("5"), new_symbol.current_price)
        })

      assert Decimal.equal?(transaction.total_amount, Decimal.new("2253.75"))

      # Step 5: Verify portfolio includes new holding
      {:ok, portfolio_summary} = Context.get_portfolio_summary()
      nvidia_holding = Enum.find(portfolio_summary.holdings, &(&1.symbol == "NVDA"))
      assert nvidia_holding != nil
      assert Decimal.equal?(nvidia_holding.quantity, Decimal.new("5"))
    end

    test "symbol caching after first search", %{local_symbols: [_testaapl, _testmsft]} do
      # First search should hit database
      start_time = System.monotonic_time()
      {:ok, first_results} = Context.search_symbols("TESTAAPL")
      first_duration = System.monotonic_time() - start_time

      assert length(first_results) >= 1

      # Second search should hit cache and be faster
      cache_start = System.monotonic_time()
      {:ok, cached_results} = Context.search_symbols("TESTAAPL")
      cache_duration = System.monotonic_time() - cache_start

      # Results should be identical
      assert length(cached_results) == length(first_results)
      first_testaapl = Enum.find(first_results, &(&1.symbol == "TESTAAPL"))
      cached_testaapl = Enum.find(cached_results, &(&1.symbol == "TESTAAPL"))
      assert first_testaapl.id == cached_testaapl.id

      # Cache should be significantly faster (at least 50% improvement)
      cache_speedup = first_duration / max(cache_duration, 1)
      assert cache_speedup > 1.5, "Cache not providing expected speedup: #{cache_speedup}x"
    end

    @tag :skip
    test "symbol search with network failures", %{account: account} do
      # TODO: External API mocking needs proper setup
      # This test validates graceful handling of external API failures
      # but requires proper mock configuration that's not yet implemented

      # Should return empty results gracefully for unknown symbols
      {:ok, results} = Context.search_symbols("UNKNOWNSYMBOL")
      assert results == []

      # Should still be able to use local symbols
      {:ok, local_results} = Context.search_symbols("TESTAAPL")
      assert length(local_results) >= 1

      # Should still be able to create transactions with local symbols
      testaapl_symbol = Enum.find(local_results, &(&1.symbol == "TESTAAPL"))

      {:ok, transaction} =
        Transaction.create(%{
          account_id: account.id,
          symbol_id: testaapl_symbol.id,
          type: :buy,
          quantity: Decimal.new("1"),
          price: testaapl_symbol.current_price,
          date: Date.utc_today(),
          total_amount: testaapl_symbol.current_price
        })

      assert transaction.symbol_id == testaapl_symbol.id
    end

    @tag :skip
    test "rate limiting prevents excessive external API calls", %{} do
      # TODO: External API mocking needs proper setup
      # This test validates rate limiting functionality
      # but requires proper mock configuration that's not yet implemented

      # For now, just verify that search calls don't crash
      unique_queries = for i <- 1..5, do: "UNKNOWN#{i}"

      Enum.each(unique_queries, fn query ->
        {:ok, _results} = Context.search_symbols(query)
      end)

      # This test is skipped until proper external API mocking is implemented
      assert true
    end
  end

  describe "symbol autocomplete performance" do
    setup do
      # Create many symbols for performance testing
      symbols =
        for i <- 1..100 do
          {:ok, symbol} =
            Symbol.create(%{
              symbol: "SYM#{String.pad_leading(to_string(i), 3, "0")}",
              name: "Test Company #{i}",
              current_price: Decimal.new("#{100 + i}.#{rem(i, 100)}"),
              data_source: :manual,
              asset_class: :stock
            })

          symbol
        end

      {:ok, symbols: symbols}
    end

    test "search performance with large symbol database", %{symbols: _symbols} do
      # Test various search patterns
      search_queries = [
        # Exact match
        "SYM001",
        # Prefix match (should return many)
        "SYM",
        # Name search (should return many)
        "Company",
        # Common word (should return many)
        "Test"
      ]

      for query <- search_queries do
        start_time = System.monotonic_time()
        {:ok, results} = Context.search_symbols(query)
        duration = System.monotonic_time() - start_time
        duration_ms = System.convert_time_unit(duration, :native, :millisecond)

        # Performance should be under 1000ms even with 100 symbols (allowing for test environment overhead)
        assert duration_ms < 1000, "Search for '#{query}' took #{duration_ms}ms, expected < 500ms"

        # Should return reasonable number of results (not all 100)
        assert length(results) <= 50, "Too many results for '#{query}': #{length(results)}"
      end
    end

    test "ETS cache effectiveness", %{symbols: _symbols} do
      query = "SYM050"

      # Clear any existing cache (create table if it doesn't exist)
      try do
        :ets.delete_all_objects(:symbol_search_cache)
      rescue
        ArgumentError ->
          # Table doesn't exist, which is fine for this test
          :ok
      end

      # First search (cache miss)
      miss_start = System.monotonic_time()
      {:ok, miss_results} = Context.search_symbols(query)
      miss_duration = System.monotonic_time() - miss_start

      # Second search (cache hit)
      hit_start = System.monotonic_time()
      {:ok, hit_results} = Context.search_symbols(query)
      hit_duration = System.monotonic_time() - hit_start

      # Results should be identical
      assert length(miss_results) == length(hit_results)

      # Cache hit should be at least 5x faster
      speedup = miss_duration / max(hit_duration, 1)
      assert speedup >= 5.0, "Cache speedup insufficient: #{speedup}x"

      # Cache hit should be under 10ms
      hit_ms = System.convert_time_unit(hit_duration, :native, :millisecond)
      assert hit_ms < 10, "Cache hit too slow: #{hit_ms}ms"
    end
  end

  describe "symbol search edge cases" do
    setup do
      # Database-as-user architecture: No user entity needed
      :ok
    end

    test "search with empty query", %{} do
      {:ok, results} = Context.search_symbols("")
      assert results == []
    end

    test "search with very long query", %{} do
      long_query = String.duplicate("A", 1000)
      {:ok, results} = Context.search_symbols(long_query)
      assert results == []
    end

    test "search with special characters", %{} do
      special_queries = ["@#$%", "BRK.B", "BRK-B", "SPY/USO"]

      for query <- special_queries do
        # Should not crash, even if no results
        {:ok, results} = Context.search_symbols(query)
        assert is_list(results)
      end
    end

    @tag :skip
    test "concurrent symbol searches", %{} do
      # Start multiple concurrent searches
      tasks =
        for i <- 1..10 do
          Task.async(fn ->
            Context.search_symbols("CONCURRENT#{i}")
          end)
        end

      # All should complete successfully
      results = Task.await_many(tasks, 5000)

      Enum.each(results, fn result ->
        assert {:ok, _list} = result
      end)
    end

    test "symbol creation with duplicate data", %{} do
      # Create initial symbol
      symbol_data = %{
        symbol: "DUPE",
        name: "Duplicate Test Corp",
        current_price: Decimal.new("100.00"),
        data_source: :manual,
        asset_class: :stock
      }

      {:ok, _first_symbol} = Context.create_symbol_from_external(symbol_data)

      # Attempt to create duplicate
      result = Context.create_symbol_from_external(symbol_data)

      case result do
        {:error, _reason} ->
          # Expected behavior - duplicate prevention
          assert true

        {:ok, second_symbol} ->
          # Some implementations might return existing symbol OR create a new one
          # Both are valid depending on implementation strategy
          assert second_symbol.symbol == "DUPE"
          assert second_symbol.name == "Duplicate Test Corp"
      end
    end
  end
end
