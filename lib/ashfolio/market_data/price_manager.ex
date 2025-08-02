defmodule Ashfolio.MarketData.PriceManager do
  @moduledoc """
  Simple price manager GenServer for coordinating market data updates.

  This module provides manual price refresh functionality for portfolio symbols.
  It integrates with Yahoo Finance API, ETS cache, and database storage to
  maintain current price data for active holdings.

  ## Features

  - Manual price refresh for active symbols (symbols with transactions)
  - Hybrid batch/individual API processing for efficiency and resilience
  - Dual storage: ETS cache for fast access + database for persistence
  - Partial success handling with detailed error reporting
  - Simple concurrency control (rejects concurrent refresh requests)

  ## Usage

      # Refresh all active symbols
      PriceManager.refresh_prices()

      # Refresh specific symbols
      PriceManager.refresh_symbols(["AAPL", "MSFT"])

      # Check refresh status
      PriceManager.refresh_status()

      # Get last refresh information
      PriceManager.last_refresh()
  """

  use GenServer
  require Logger

  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Cache

  import Ash.Query, only: [filter: 2, select: 2]

  @yahoo_finance_module Application.compile_env(:ashfolio, :yahoo_finance_module, Ashfolio.MarketData.YahooFinance)

  # Client API

  @doc """
  Starts the PriceManager GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Refreshes prices for all active symbols (symbols with transactions).

  Returns {:ok, results} with success/failure counts and details,
  or {:error, reason} if refresh cannot be started.

  ## Examples

      iex> PriceManager.refresh_prices()
      {:ok, %{success_count: 5, failure_count: 1, duration_ms: 2500}}

      iex> PriceManager.refresh_prices()  # Called while refresh in progress
      {:error, :refresh_in_progress}
  """
  def refresh_prices do
    GenServer.call(__MODULE__, :refresh_prices, get_timeout())
  end

  @doc """
  Refreshes prices for specific symbols.

  ## Parameters
  - symbols: List of symbol strings (e.g., ["AAPL", "MSFT"])

  ## Examples

      iex> PriceManager.refresh_symbols(["AAPL", "MSFT"])
      {:ok, %{success_count: 2, failure_count: 0, duration_ms: 1200}}
  """
  def refresh_symbols(symbols) when is_list(symbols) do
    GenServer.call(__MODULE__, {:refresh_symbols, symbols}, get_timeout())
  end

  @doc """
  Returns the current refresh status.

  ## Returns
  - :idle - No refresh in progress
  - :refreshing - Refresh currently in progress
  """
  def refresh_status do
    GenServer.call(__MODULE__, :refresh_status)
  end

  @doc """
  Returns information about the last refresh operation.

  ## Returns
  - %{timestamp: DateTime.t(), results: map()} - Last refresh info
  - nil - No refresh has been performed yet
  """
  def last_refresh do
    GenServer.call(__MODULE__, :last_refresh)
  end

  # GenServer Callbacks

  @impl true
  def init(_opts) do
    state = %{
      last_refresh_at: nil,
      refreshing?: false,
      last_refresh_results: nil,
      refresh_count: 0
    }

    Logger.info("PriceManager started")
    {:ok, state}
  end

  @impl true
  def handle_call(:refresh_prices, _from, %{refreshing?: true} = state) do
    {:reply, {:error, :refresh_in_progress}, state}
  end

  def handle_call(:refresh_prices, _from, state) do
    Logger.info("Starting price refresh for active symbols")

    case get_active_symbols() do
      {:ok, symbols} ->
        symbol_strings = Enum.map(symbols, & &1.symbol)
        do_refresh(symbol_strings, state)

      {:error, reason} ->
        Logger.error("Failed to get active symbols: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:refresh_symbols, _symbols}, _from, %{refreshing?: true} = state) do
    {:reply, {:error, :refresh_in_progress}, state}
  end

  def handle_call({:refresh_symbols, symbols}, _from, state) do
    Logger.info("Starting price refresh for #{length(symbols)} specific symbols")
    do_refresh(symbols, state)
  end

  def handle_call(:refresh_status, _from, state) do
    status = if state.refreshing?, do: :refreshing, else: :idle
    {:reply, status, state}
  end

  def handle_call(:last_refresh, _from, state) do
    last_refresh_info = case state.last_refresh_at do
      nil -> nil
      timestamp -> %{
        timestamp: timestamp,
        results: state.last_refresh_results || %{}
      }
    end

    {:reply, last_refresh_info, state}
  end

  @impl true
  def terminate(reason, state) do
    if state.refreshing? do
      Logger.info("PriceManager shutting down during refresh")
    end

    Logger.info("PriceManager terminated: #{inspect(reason)}")
    :ok
  end

  # Private Functions

  defp do_refresh(symbols, state) do
    start_time = System.monotonic_time(:millisecond)

    new_state = %{state |
      refreshing?: true,
      last_refresh_at: DateTime.utc_now()
    }

    # Perform the actual refresh
    results = refresh_symbol_prices(symbols)

    end_time = System.monotonic_time(:millisecond)
    duration_ms = end_time - start_time

    # Update state with results
    final_state = %{new_state |
      refreshing?: false,
      last_refresh_results: Map.put(results, :duration_ms, duration_ms),
      refresh_count: state.refresh_count + 1
    }

    Logger.info("Price refresh completed: #{results.success_count} success, #{results.failure_count} failures, #{duration_ms}ms")

    {:reply, {:ok, Map.put(results, :duration_ms, duration_ms)}, final_state}
  end

  defp refresh_symbol_prices(symbols) when is_list(symbols) do
    Logger.debug("Refreshing prices for symbols: #{inspect(symbols)}")

    # Try batch fetch first (hybrid approach from research)
    case @yahoo_finance_module.fetch_prices(symbols) do
      {:ok, price_map} ->
        # Batch fetch succeeded
        Logger.debug("Batch fetch successful for #{map_size(price_map)} symbols")
        process_successful_prices(price_map, symbols)

      {:error, reason} ->
        # Batch fetch failed, try individual fetches
        Logger.info("Batch fetch failed (#{inspect(reason)}), trying individual fetches")
        fetch_individually(symbols)
    end
  end

  defp fetch_individually(symbols) do
    results = Enum.map(symbols, fn symbol ->
      case @yahoo_finance_module.fetch_price(symbol) do
        {:ok, price} ->
          {symbol, {:ok, price}}
        {:error, reason} ->
          {symbol, {:error, reason}}
      end
    end)

    process_individual_results(results)
  end

  defp process_successful_prices(price_map, requested_symbols) do
    successes = Enum.map(price_map, fn {symbol, price} ->
      case store_price(symbol, price) do
        :ok -> {symbol, {:ok, price}}
        {:error, reason} -> {symbol, {:error, reason}}
      end
    end)

    # Find symbols that weren't returned in the batch
    returned_symbols = Map.keys(price_map)
    missing_symbols = requested_symbols -- returned_symbols

    failures = Enum.map(missing_symbols, fn symbol ->
      {symbol, {:error, :not_found}}
    end)

    all_results = successes ++ failures
    process_individual_results(all_results)
  end

  defp process_individual_results(results) do
    {successes, failures} = Enum.split_with(results, fn {_symbol, result} ->
      match?({:ok, _}, result)
    end)

    # Log failures for debugging
    Enum.each(failures, fn {symbol, {:error, reason}} ->
      Logger.warning("Failed to refresh #{symbol}: #{inspect(reason)}")
    end)

    %{
      success_count: length(successes),
      failure_count: length(failures),
      successes: Enum.map(successes, fn {symbol, {:ok, price}} -> {symbol, price} end),
      failures: Enum.map(failures, fn {symbol, {:error, reason}} -> {symbol, reason} end)
    }
  end

  defp store_price(symbol, price) do
    updated_at = DateTime.utc_now()

    # Store in both cache and database (dual update from research)
    with :ok <- store_in_cache(symbol, price, updated_at),
         {:ok, _symbol} <- update_database(symbol, price, updated_at) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to store price for #{symbol}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp store_in_cache(symbol, price, updated_at) do
    Cache.put_price(symbol, price, updated_at)
  end

  defp update_database(symbol_string, price, updated_at) do
    case Symbol.find_by_symbol(symbol_string) do
      {:ok, [symbol | _]} ->
        case Ash.update(symbol, %{
          current_price: price,
          price_updated_at: updated_at
        }, action: :update_price) do
          {:ok, updated_symbol} -> {:ok, updated_symbol}
          {:error, reason} -> {:error, reason}
        end

      {:ok, []} ->
        Logger.warning("Symbol not found in database: #{symbol_string}")
        {:error, :symbol_not_found}

      {:error, reason} ->
        Logger.error("Database error updating #{symbol_string}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_active_symbols do
    try do
      # Query symbols that have transactions (active holdings)
      symbols = Symbol
        |> filter(exists(transactions, true))
        |> select([:symbol, :id])
        |> Ash.read!()

      {:ok, symbols}
    rescue
      error ->
        Logger.error("Failed to query active symbols: #{inspect(error)}")
        {:error, :database_error}
    end
  end

  defp get_timeout do
    Application.get_env(:ashfolio, __MODULE__, [])
    |> Keyword.get(:refresh_timeout, 30_000)
  end
end
