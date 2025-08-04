defmodule Ashfolio.MarketData.PriceManagerSimpleTest do
  use ExUnit.Case, async: false

  alias Ashfolio.MarketData.PriceManager

  # No setup needed - PriceManager is started by the application

  describe "basic functionality" do
    test "starts successfully" do
      assert Process.whereis(PriceManager) != nil
    end

    test "refresh_status returns :idle when not refreshing" do
      assert :idle = PriceManager.refresh_status()
    end

    test "last_refresh returns timestamp or nil" do
      # Since PriceManager is a singleton GenServer that persists across tests,
      # last_refresh may return a timestamp if other tests have run refresh operations
      result = PriceManager.last_refresh()
      assert result == nil or match?(%DateTime{}, result)
    end
  end
end
