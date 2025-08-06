defmodule Ashfolio.MarketData.YahooFinanceBehaviour do
  @moduledoc """
  Behaviour for Yahoo Finance API integration.

  This behaviour defines the contract for fetching market data,
  allowing for easy mocking in tests.
  """

  @doc """
  Fetches the current price for a single symbol.
  """
  @callback fetch_price(symbol :: String.t()) ::
              {:ok, Decimal.t()} | {:error, atom()}

  @doc """
  Fetches current prices for multiple symbols in a single request.
  """
  @callback fetch_prices(symbols :: [String.t()]) ::
              {:ok, %{String.t() => Decimal.t()}} | {:error, atom()}
end
