defmodule Ashfolio.CacheTest do
  use ExUnit.Case, async: false

  @moduletag :unit
  @moduletag :fast

  alias Ashfolio.Cache

  setup do
    # Ensure cache is initialized for tests
    Cache.init()
    # Clear cache before each test
    Cache.clear_all()
    :ok
  end

  describe "put_price/3 and get_price/2" do
    test "stores and retrieves price data" do
      symbol = "AAPL"
      price = Decimal.new("150.25")

      assert :ok = Cache.put_price(symbol, price)

      assert {:ok, %{price: ^price, updated_at: updated_at}} = Cache.get_price(symbol)
      assert %DateTime{} = updated_at
    end

    test "returns error for non-existent symbol" do
      assert {:error, :not_found} = Cache.get_price("NONEXISTENT")
    end

    test "returns error for stale data" do
      symbol = "AAPL"
      price = Decimal.new("150.25")

      # Manually insert stale cache entry (2 hours old)
      old_cached_at = DateTime.add(DateTime.utc_now(), -7200, :second)

      cache_entry = %{
        price: price,
        updated_at: DateTime.utc_now(),
        cached_at: old_cached_at
      }

      :ets.insert(:ashfolio_price_cache, {symbol, cache_entry})

      # Should be stale with 1 hour max age
      assert {:error, :stale} = Cache.get_price(symbol, 3600)
    end
  end

  describe "get_all_prices/0" do
    test "returns all cached prices" do
      Cache.put_price("AAPL", Decimal.new("150.25"))
      Cache.put_price("MSFT", Decimal.new("300.50"))

      all_prices = Cache.get_all_prices()

      assert length(all_prices) == 2

      assert {"AAPL", %{price: _, updated_at: _}} =
               Enum.find(all_prices, fn {symbol, _} -> symbol == "AAPL" end)

      assert {"MSFT", %{price: _, updated_at: _}} =
               Enum.find(all_prices, fn {symbol, _} -> symbol == "MSFT" end)
    end
  end

  describe "delete_price/1" do
    test "removes specific symbol from cache" do
      Cache.put_price("AAPL", Decimal.new("150.25"))
      Cache.put_price("MSFT", Decimal.new("300.50"))

      assert :ok = Cache.delete_price("AAPL")

      assert {:error, :not_found} = Cache.get_price("AAPL")
      assert {:ok, _} = Cache.get_price("MSFT")
    end
  end

  describe "clear_all/0" do
    test "removes all cached prices" do
      Cache.put_price("AAPL", Decimal.new("150.25"))
      Cache.put_price("MSFT", Decimal.new("300.50"))

      assert :ok = Cache.clear_all()

      assert [] = Cache.get_all_prices()
    end
  end

  describe "cleanup_stale_entries/1" do
    test "removes only stale entries" do
      # Fresh entry
      Cache.put_price("AAPL", Decimal.new("150.25"))

      # Manually insert stale entry (2 hours old)
      old_cached_at = DateTime.add(DateTime.utc_now(), -7200, :second)

      stale_cache_entry = %{
        price: Decimal.new("300.50"),
        updated_at: DateTime.utc_now(),
        cached_at: old_cached_at
      }

      :ets.insert(:ashfolio_price_cache, {"MSFT", stale_cache_entry})

      # Cleanup with 1 hour threshold
      count = Cache.cleanup_stale_entries(3600)

      assert count == 1
      assert {:ok, _} = Cache.get_price("AAPL")
      assert {:error, :not_found} = Cache.get_price("MSFT")
    end
  end

  describe "stats/0" do
    test "returns cache statistics" do
      Cache.put_price("AAPL", Decimal.new("150.25"))

      stats = Cache.stats()

      assert %{size: size, memory_words: memory_words, memory_bytes: memory_bytes} = stats
      assert is_integer(size) and size > 0
      assert is_integer(memory_words) and memory_words > 0
      assert is_integer(memory_bytes) and memory_bytes > 0
    end
  end
end
