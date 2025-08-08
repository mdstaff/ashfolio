defmodule YahooFinanceMock do
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