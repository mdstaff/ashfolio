defmodule YahooFinanceMock do
  @moduledoc """
  Mock implementation for Yahoo Finance API calls during testing.

  Provides stubbed responses for market data fetching functionality
  to enable predictable testing without external API dependencies.
  """
  @behaviour Ashfolio.MarketData.YahooFinanceBehaviour

  @impl true
  def fetch_prices(symbols) do
    Mox.__dispatch__(__MODULE__, :fetch_prices, [symbols], %{})
  end

  @impl true
  def fetch_price(symbol) do
    Mox.__dispatch__(__MODULE__, :fetch_price, [symbol], %{})
  end
end
