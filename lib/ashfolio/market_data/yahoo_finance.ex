defmodule Ashfolio.MarketData.YahooFinance do
  @moduledoc """
  Simple Yahoo Finance API integration for fetching stock prices.

  This module provides basic price fetching functionality using Yahoo Finance's
  unofficial API endpoints. It includes simple error handling and JSON parsing.
  """

  @behaviour Ashfolio.MarketData.YahooFinanceBehaviour

  require Logger

  @base_url "https://query1.finance.yahoo.com/v8/finance/chart"
  @timeout 10_000

  @doc """
  Fetches the current price for a given symbol from Yahoo Finance.

  ## Examples

      iex> YahooFinance.fetch_price("AAPL")
      {:ok, %Decimal{}}

      iex> YahooFinance.fetch_price("INVALID")
      {:error, :not_found}
  """
  def fetch_price(symbol) when is_binary(symbol) do
    Logger.debug("Fetching price for symbol: #{symbol}")

    case make_request(symbol) do
      {:ok, %{status_code: 200, body: body}} ->
        parse_price_response(body, symbol)

      {:ok, %{status_code: 404}} ->
        Logger.warning("Symbol not found: #{symbol}")
        {:error, :not_found}

      {:ok, %{status_code: status_code}} ->
        Logger.warning("Yahoo Finance API returned status #{status_code} for #{symbol}")
        {:error, :api_error}

      {:error, %HTTPoison.Error{reason: :timeout}} ->
        Logger.warning("Timeout fetching price for #{symbol}")
        {:error, :timeout}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP error fetching price for #{symbol}: #{inspect(reason)}")
        {:error, :network_error}

      {:error, reason} ->
        Logger.error("Unexpected error fetching price for #{symbol}: #{inspect(reason)}")
        {:error, :unknown_error}
    end
  end

  @doc """
  Fetches prices for multiple symbols in a single request.

  ## Examples

      iex> YahooFinance.fetch_prices(["AAPL", "MSFT"])
      {:ok, %{"AAPL" => %Decimal{}, "MSFT" => %Decimal{}}}
  """
  def fetch_prices(symbols) when is_list(symbols) do
    Logger.debug("Fetching prices for #{length(symbols)} symbols")

    # For now, make individual requests. Could be optimized later.
    results =
      symbols
      |> Enum.map(fn symbol ->
        case fetch_price(symbol) do
          {:ok, price} -> {symbol, {:ok, price}}
          {:error, reason} -> {symbol, {:error, reason}}
        end
      end)
      |> Enum.into(%{})

    # Check if we have any successful results
    successful_results =
      results
      |> Enum.filter(fn {_symbol, result} -> match?({:ok, _}, result) end)
      |> Enum.map(fn {symbol, {:ok, price}} -> {symbol, price} end)
      |> Enum.into(%{})

    if map_size(successful_results) > 0 do
      {:ok, successful_results}
    else
      {:error, :all_failed}
    end
  end

  # Private functions

  defp make_request(symbol) do
    url = build_url(symbol)

    headers = [
      {"User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"},
      {"Accept", "application/json"}
    ]

    HTTPoison.get(url, headers, timeout: @timeout, recv_timeout: @timeout)
  end

  defp build_url(symbol) do
    "#{@base_url}/#{URI.encode(symbol)}?interval=1d&range=1d"
  end

  defp parse_price_response(body, symbol) do
    case Jason.decode(body) do
      {:ok, %{"chart" => %{"result" => [result | _]}}} ->
        extract_current_price(result, symbol)

      {:ok, %{"chart" => %{"result" => []}}} ->
        Logger.warning("No data returned for symbol: #{symbol}")
        {:error, :no_data}

      {:ok, %{"chart" => %{"error" => error}}} ->
        Logger.warning("Yahoo Finance API error for #{symbol}: #{inspect(error)}")
        {:error, :api_error}

      {:ok, _unexpected} ->
        Logger.warning("Unexpected response format for #{symbol}")
        {:error, :parse_error}

      {:error, reason} ->
        Logger.error("JSON parsing failed for #{symbol}: #{inspect(reason)}")
        {:error, :parse_error}
    end
  end

  defp extract_current_price(result, symbol) do
    with %{"meta" => meta} <- result,
         %{"regularMarketPrice" => price} when is_number(price) <- meta do
      decimal_price = Decimal.from_float(price)
      Logger.debug("Successfully fetched price for #{symbol}: #{decimal_price}")
      {:ok, decimal_price}
    else
      _ ->
        Logger.warning("Could not extract price from response for #{symbol}")
        {:error, :price_not_found}
    end
  end
end
