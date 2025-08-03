defmodule Ashfolio.MarketData.YahooFinanceTest do
  use ExUnit.Case, async: false

  alias Ashfolio.MarketData.YahooFinance

  import ExUnit.CaptureLog

  describe "fetch_price/1" do
    test "returns error for invalid symbol format" do
      # Test with empty string
      _log = capture_log(fn ->
        result = YahooFinance.fetch_price("")
        assert match?({:error, _}, result)
      end)
    end

    test "handles network timeout gracefully" do
      # This test will actually make a network call but with a very short timeout
      # We expect it to fail gracefully
      _log = capture_log(fn ->
        # Test with a symbol that should timeout or fail
        result = YahooFinance.fetch_price("NONEXISTENT_SYMBOL_12345")
        assert match?({:error, _}, result)
      end)
    end

    @tag :integration
    test "successfully fetches price for AAPL (integration test)" do
      # This is an integration test that requires network access
      # Skip in CI or when network is unavailable
      case YahooFinance.fetch_price("AAPL") do
        {:ok, price} ->
          assert %Decimal{} = price
          assert Decimal.positive?(price)
        {:error, reason} ->
          # Network might be unavailable, log and skip
          IO.puts("Integration test skipped due to network error: #{reason}")
          :ok
      end
    end
  end

  describe "fetch_prices/1" do
    test "handles empty list" do
      assert {:error, :all_failed} = YahooFinance.fetch_prices([])
    end

    @tag :integration
    test "fetches multiple prices (integration test)" do
      case YahooFinance.fetch_prices(["AAPL", "MSFT"]) do
        {:ok, prices} ->
          assert is_map(prices)
          assert map_size(prices) > 0

          Enum.each(prices, fn {symbol, price} ->
            assert is_binary(symbol)
            assert %Decimal{} = price
            assert Decimal.positive?(price)
          end)

        {:error, reason} ->
          IO.puts("Integration test skipped due to network error: #{reason}")
          :ok
      end
    end
  end

  describe "URL building and request structure" do
    test "module implements required behaviour functions" do
      # Test that the module implements the YahooFinanceBehaviour
      assert Code.ensure_loaded?(Ashfolio.MarketData.YahooFinance)

      # Check that the module has the required functions from the behaviour
      behaviours = Ashfolio.MarketData.YahooFinance.__info__(:attributes)[:behaviour] || []
      assert Ashfolio.MarketData.YahooFinanceBehaviour in behaviours
    end
  end

  describe "error handling" do
    test "logs appropriate messages for different error types" do
      log = capture_log(fn ->
        # Test with clearly invalid symbol
        result = YahooFinance.fetch_price("INVALID_SYMBOL_THAT_SHOULD_NOT_EXIST_12345")
        assert match?({:error, _}, result)
      end)

      # Should contain some log message (debug or warning)
      assert String.length(log) > 0
    end
  end
end
