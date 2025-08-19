defmodule Ashfolio.MarketData.YahooFinanceBehaviour do
  @moduledoc """
  Defines the behaviour for a Yahoo Finance API client.
  """

  @callback fetch_price(String.t()) :: {:ok, Decimal.t()} | {:error, atom()}
  @callback fetch_prices([String.t()]) :: {:ok, map()} | {:error, atom()}
end
