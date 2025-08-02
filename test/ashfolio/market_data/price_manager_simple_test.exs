defmodule Ashfolio.MarketData.PriceManagerSimpleTest do
  use ExUnit.Case, async: false

  alias Ashfolio.MarketData.PriceManager

  # No setup needed - PriceManager is started by the application

  describe "basic functionality" do
    test "starts successfully" do
      assert Process.whereis(PriceManager) != nil
    end

    test "refresh_status returns :idle initially" do
      assert :idle = PriceManager.refresh_status()
    end

    test "last_refresh returns nil initially" do
      assert nil == PriceManager.last_refresh()
    end
  end
end
