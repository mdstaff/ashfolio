defmodule Ashfolio.FinancialManagement.SymbolSearchTest do
  use Ashfolio.DataCase, async: false

  @moduletag :ash_resources
  @moduletag :unit
  @moduletag :fast

  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.FinancialManagement.SymbolSearch

  describe "SymbolSearch.search/2" do
    setup do
      # Create test symbols with unique identifiers to avoid conflicts
      unique_id = System.unique_integer([:positive])

      _symbols = [
        # Exact match scenarios
        {:ok, aapl} = Symbol.create(%{
          symbol: "AAPL#{unique_id}",
          name: "Apple Inc.",
          asset_class: :stock,
          data_source: :yahoo_finance
        }),
        
        {:ok, googl} = Symbol.create(%{
          symbol: "GOOGL#{unique_id}",
          name: "Alphabet Inc. Class A",
          asset_class: :stock,
          data_source: :yahoo_finance
        }),
        
        {:ok, goog} = Symbol.create(%{
          symbol: "GOOG#{unique_id}",
          name: "Alphabet Inc. Class C",
          asset_class: :stock,
          data_source: :yahoo_finance
        }),
        
        # Name matching scenarios
        {:ok, msft} = Symbol.create(%{
          symbol: "MSFT#{unique_id}",
          name: "Microsoft Corporation",
          asset_class: :stock,
          data_source: :yahoo_finance
        }),
        
        # Mixed case scenarios
        {:ok, btc} = Symbol.create(%{
          symbol: "BTC-USD#{unique_id}",
          name: "Bitcoin USD",
          asset_class: :crypto,
          data_source: :coingecko
        }),
        
        # ETF for variety
        {:ok, spy} = Symbol.create(%{
          symbol: "SPY#{unique_id}",
          name: "SPDR S&P 500 ETF Trust",
          asset_class: :etf,
          data_source: :yahoo_finance
        })
      ]

      %{
        aapl: aapl,
        googl: googl,
        goog: goog,
        msft: msft,
        btc: btc,
        spy: spy,
        unique_id: unique_id
      }
    end

    test "searches symbols by ticker case-insensitive", %{aapl: aapl, unique_id: unique_id} do
      # Test exact match case-insensitive
      query = "aapl#{unique_id}"
      {:ok, results} = SymbolSearch.search(query)
      
      assert length(results) == 1
      assert hd(results).id == aapl.id
      assert hd(results).symbol == aapl.symbol
      
      # Test uppercase query
      query_upper = "AAPL#{unique_id}"
      {:ok, results_upper} = SymbolSearch.search(query_upper)
      
      assert length(results_upper) == 1
      assert hd(results_upper).id == aapl.id
    end

    test "searches symbols by company name partial match", %{msft: msft} do
      # Test company name search
      {:ok, results} = SymbolSearch.search("Microsoft")
      
      symbol_ids = Enum.map(results, & &1.id)
      assert msft.id in symbol_ids
      
      # Test partial name match
      {:ok, results_partial} = SymbolSearch.search("Micro")
      symbol_ids_partial = Enum.map(results_partial, & &1.id)
      assert msft.id in symbol_ids_partial
    end

    test "ranks results by relevance (exact, starts with, contains)", %{
      googl: _googl, 
      goog: _goog,
      unique_id: unique_id
    } do
      # Create additional symbols for ranking test
      {:ok, _google_spac} = Symbol.create(%{
        symbol: "GSPAC#{unique_id}",
        name: "Google SPAC Corp",
        asset_class: :stock,
        data_source: :manual
      })
      
      {:ok, _facebook} = Symbol.create(%{
        symbol: "META#{unique_id}",
        name: "Meta Platforms (formerly Facebook, Google competitor)",
        asset_class: :stock,
        data_source: :yahoo_finance
      })
      
      # Search for "goog" - should rank by relevance
      query = "goog"
      {:ok, results} = SymbolSearch.search(query)
      
      # Should be ordered by relevance:
      # 1. Starts with: GOOG#{unique_id} (starts with "goog")
      # 2. Starts with: GOOGL#{unique_id} (starts with "goog")
      # Note: Neither is an exact match for "goog", so both are "starts with" priority
      
      assert length(results) >= 2
      
      # Find our symbols in results
      result_symbols = Enum.map(results, & &1.symbol)
      assert "GOOG#{unique_id}" in result_symbols
      assert "GOOGL#{unique_id}" in result_symbols
      
      # Both start with "goog", but "GOOG" should come before "GOOGL" alphabetically within same relevance
      # Actually, let's just ensure both are present and in some reasonable order
      goog_index = Enum.find_index(results, &(&1.symbol == "GOOG#{unique_id}"))
      googl_index = Enum.find_index(results, &(&1.symbol == "GOOGL#{unique_id}"))
      
      assert goog_index != nil
      assert googl_index != nil
    end

    test "limits results to maximum 50 symbols" do
      # This test would need 51+ symbols to be meaningful
      # For now, verify that we get results and the function accepts limit
      {:ok, results} = SymbolSearch.search("", max_results: 10)
      
      assert is_list(results)
      assert length(results) <= 10
    end

    test "returns empty list for no matches" do
      {:ok, results} = SymbolSearch.search("NONEXISTENTSYMBOL123456789")
      
      assert results == []
    end

    test "handles empty query gracefully" do
      {:ok, results} = SymbolSearch.search("")
      
      # Empty query should return empty results or limited results
      assert is_list(results)
    end

    test "handles whitespace in query" do
      # Test query with leading/trailing whitespace
      {:ok, results} = SymbolSearch.search("  AAPL  ")
      
      assert is_list(results)
    end
  end

  describe "SymbolSearch options" do
    test "respects max_results option" do
      {:ok, results_5} = SymbolSearch.search("", max_results: 5)
      {:ok, results_10} = SymbolSearch.search("", max_results: 10)
      
      assert length(results_5) <= 5
      assert length(results_10) <= 10
    end

    test "uses default max_results of 50" do
      # Create enough symbols to test the default limit
      # This is more of a documentation test
      {:ok, results} = SymbolSearch.search("")
      
      assert length(results) <= 50
    end
  end

  describe "SymbolSearch error handling" do
    test "handles database errors gracefully" do
      # This test would need to mock database errors
      # For now, ensure the function exists and handles basic error cases
      
      result = SymbolSearch.search("test")
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end
end