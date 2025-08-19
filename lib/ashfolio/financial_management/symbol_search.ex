defmodule Ashfolio.FinancialManagement.SymbolSearch do
  @moduledoc """
  Local-first symbol search with ETS caching and external API fallback for Ashfolio financial management.

  Provides efficient symbol lookup by ticker and company name with relevance ranking,
  configurable TTL-based caching, and external API integration when local results are insufficient.

  Features:
  - Case-insensitive search by ticker symbol and company name
  - Relevance-based result ranking (exact > starts with > contains)
  - ETS-based result caching with configurable TTL (default: 5 minutes)
  - External API fallback when local results < 3 matches
  - Rate limiting: maximum 10 API calls per minute per user
  - Maximum 50 results per search to prevent UI overflow
  - Graceful degradation when external API unavailable

  ## Examples

      # Search by ticker (local first, external fallback)
      {:ok, results} = SymbolSearch.search("AAPL")

      # Search by company name
      {:ok, results} = SymbolSearch.search("Apple")

      # Search with custom options
      {:ok, results} = SymbolSearch.search("MSFT", max_results: 10, ttl_seconds: 600)

      # Create symbol from external API data
      {:ok, symbol} = SymbolSearch.create_symbol_from_external(%{
        symbol: "NVDA",
        name: "NVIDIA Corporation",
        price: 450.25
      })
  """

  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.MarketData.RateLimiter
  alias Ashfolio.ErrorHandler
  require Logger

  # HTTP client for external API calls (configurable for testing)
  @http_client Application.compile_env(:ashfolio, :http_client, Ashfolio.MarketData.HttpClient)

  # ETS table for caching search results
  @cache_table :ashfolio_symbol_search_cache
  # 5 minutes
  @default_ttl_seconds 300
  # Maximum results to prevent UI overflow
  @default_max_results 50
  # Minimum local results before external API fallback
  @min_local_results 3
  # 5 seconds timeout for external API calls
  @external_api_timeout 5000

  # Yahoo Finance search endpoint
  @yahoo_search_url "https://query1.finance.yahoo.com/v1/finance/search"

  @doc """
  Initialize the SymbolSearch module and create ETS cache table.
  """
  def start_link do
    create_cache_table()
    {:ok, self()}
  end

  @doc """
  Search for symbols by ticker or company name with ETS caching.

  Performs case-insensitive search across ticker symbols and company names,
  ranks results by relevance, and caches results for improved performance.

  ## Options

  - `:max_results` - Maximum number of results to return (default: 50)
  - `:ttl_seconds` - Cache TTL in seconds (default: 300)

  ## Examples

      iex> SymbolSearch.search("AAPL")
      {:ok, [%Symbol{symbol: "AAPL", name: "Apple Inc."}]}

      iex> SymbolSearch.search("Apple")
      {:ok, [%Symbol{symbol: "AAPL", name: "Apple Inc."}]}

      iex> SymbolSearch.search("NONEXISTENT")
      {:ok, []}
  """
  def search(query, opts \\ []) do
    normalized_query = normalize_query(query)
    max_results = Keyword.get(opts, :max_results, @default_max_results)
    ttl_seconds = Keyword.get(opts, :ttl_seconds, @default_ttl_seconds)

    cache_key = build_cache_key(normalized_query, max_results)

    case get_from_cache(cache_key) do
      {:hit, results} ->
        {:ok, results}

      :miss ->
        case perform_search(normalized_query, max_results) do
          {:ok, results} ->
            cache_results(cache_key, results, ttl_seconds)
            {:ok, results}

          {:error, reason} = error ->
            Logger.warning("SymbolSearch failed for query '#{query}': #{inspect(reason)}")
            error
        end
    end
  rescue
    error ->
      Logger.error("SymbolSearch error for query '#{query}': #{inspect(error)}")
      {:error, :search_failed}
  end

  @doc """
  Clear the entire search cache.
  """
  def clear_cache do
    clear_cache_contents()
    :ok
  end

  @doc """
  Check if a query result is cached.
  """
  def cache_hit?(query, opts \\ []) do
    normalized_query = normalize_query(query)
    max_results = Keyword.get(opts, :max_results, @default_max_results)
    cache_key = build_cache_key(normalized_query, max_results)

    case get_from_cache(cache_key) do
      {:hit, _} -> true
      :miss -> false
    end
  end

  @doc """
  Generate a cache key for the given query.
  """
  def cache_key(query, opts \\ []) do
    normalized_query = normalize_query(query)
    max_results = Keyword.get(opts, :max_results, @default_max_results)
    build_cache_key(normalized_query, max_results)
  end

  # Private functions

  defp normalize_query(query) do
    query
    |> String.trim()
    |> String.downcase()
  end

  defp build_cache_key(normalized_query, max_results) do
    {:symbol_search, normalized_query, max_results}
  end

  defp create_cache_table do
    # Only create table if it doesn't exist (safer approach)
    case :ets.whereis(@cache_table) do
      :undefined ->
        try do
          :ets.new(@cache_table, [:named_table, :public, :set])
        rescue
          ArgumentError ->
            # Table was created by another process, that's fine
            @cache_table
        end

      _ ->
        # Table already exists
        @cache_table
    end
  end

  defp clear_cache_contents do
    # Clear cache contents without deleting the table (prevents service interruption)
    try do
      :ets.delete_all_objects(@cache_table)
    rescue
      ArgumentError ->
        # Table doesn't exist, create it
        create_cache_table()
    end
  end

  defp get_from_cache(cache_key) do
    try do
      case :ets.lookup(@cache_table, cache_key) do
        [{^cache_key, results, expires_at}] ->
          if DateTime.compare(DateTime.utc_now(), expires_at) == :lt do
            {:hit, results}
          else
            # Remove expired entry
            :ets.delete(@cache_table, cache_key)
            :miss
          end

        [] ->
          :miss
      end
    rescue
      ArgumentError ->
        # Table doesn't exist, create it
        create_cache_table()
        :miss
    end
  end

  defp cache_results(cache_key, results, ttl_seconds) do
    expires_at = DateTime.utc_now() |> DateTime.add(ttl_seconds, :second)

    try do
      :ets.insert(@cache_table, {cache_key, results, expires_at})
    rescue
      ArgumentError ->
        # Table doesn't exist, create it and try again
        create_cache_table()
        :ets.insert(@cache_table, {cache_key, results, expires_at})
    end
  end

  defp perform_search("", _max_results) do
    # Empty query returns no results
    {:ok, []}
  end

  defp perform_search(normalized_query, max_results) do
    with {:ok, all_symbols} <- Symbol.list() do
      local_results =
        all_symbols
        |> filter_and_rank_symbols(normalized_query)
        |> Enum.take(max_results)

      # If we have sufficient local results, return them
      if length(local_results) >= @min_local_results do
        {:ok, local_results}
      else
        # Try external API fallback for insufficient local results
        case search_external_api(normalized_query, max_results - length(local_results)) do
          {:ok, external_results} ->
            # Combine local and external results, prioritizing local
            combined_results = local_results ++ external_results
            {:ok, Enum.take(combined_results, max_results)}

          {:error, reason} ->
            Logger.info(
              "External API search failed for '#{normalized_query}': #{inspect(reason)}, returning local results"
            )

            {:ok, local_results}
        end
      end
    end
  end

  defp filter_and_rank_symbols(symbols, query) do
    symbols
    |> Enum.reduce([], fn symbol, acc ->
      case calculate_relevance(symbol, query) do
        # No match
        0 -> acc
        relevance -> [{relevance, symbol} | acc]
      end
    end)
    |> Enum.sort_by(fn {relevance, _symbol} -> relevance end, :desc)
    |> Enum.map(fn {_relevance, symbol} -> symbol end)
  end

  defp calculate_relevance(symbol, query) do
    ticker = String.downcase(symbol.symbol)
    name = String.downcase(symbol.name || "")

    cond do
      # Exact ticker match (highest priority)
      ticker == query -> 1000
      # Ticker starts with query (second priority)
      String.starts_with?(ticker, query) -> 800
      # Ticker contains query (third priority)
      String.contains?(ticker, query) -> 600
      # Company name starts with query (fourth priority)
      String.starts_with?(name, query) -> 400
      # Company name contains query (lowest priority)
      String.contains?(name, query) -> 200
      # No match
      true -> 0
    end
  end

  # External API integration functions

  @doc """
  Create a new Symbol resource from external API data.

  ## Parameters
  - symbol_data: Map containing symbol information from external API

  ## Examples

      iex> SymbolSearch.create_symbol_from_external(%{
      ...>   symbol: "NVDA",
      ...>   name: "NVIDIA Corporation",
      ...>   price: 450.25
      ...> })
      {:ok, %Symbol{}}
  """
  def create_symbol_from_external(symbol_data) when is_map(symbol_data) do
    symbol_attrs = %{
      symbol: Map.get(symbol_data, :symbol) || Map.get(symbol_data, "symbol"),
      name: Map.get(symbol_data, :name) || Map.get(symbol_data, "name"),
      # Default to stock for external symbols
      asset_class: :stock,
      data_source: :yahoo_finance
    }

    # Validate required fields
    case validate_external_symbol_data(symbol_attrs) do
      :ok ->
        case Symbol.create(symbol_attrs) do
          {:ok, symbol} ->
            Logger.info("Created new symbol from external API: #{symbol.symbol}")
            {:ok, symbol}

          {:error, changeset} ->
            Logger.warning(
              "Failed to create symbol from external API: #{inspect(changeset.errors)}"
            )

            {:error, :creation_failed}
        end

      {:error, reason} ->
        Logger.warning("Invalid external symbol data: #{inspect(reason)}")
        {:error, reason}
    end
  rescue
    error ->
      Logger.error("Error creating symbol from external data: #{inspect(error)}")
      {:error, :creation_failed}
  end

  defp validate_external_symbol_data(%{symbol: symbol, name: name})
       when is_binary(symbol) and is_binary(name) and symbol != "" and name != "" do
    :ok
  end

  defp validate_external_symbol_data(_), do: {:error, :invalid_data}

  defp search_external_api(query, max_results) do
    # Check rate limiting first
    case RateLimiter.check_rate_limit(:symbol_search, 1) do
      :ok ->
        perform_external_search(query, max_results)

      {:error, :rate_limited, retry_after_ms} ->
        Logger.info("Rate limited for symbol search, retry after #{retry_after_ms}ms")

        ErrorHandler.handle_error({:error, :symbol_search_rate_limited}, %{
          operation: :external_symbol_search,
          retry_after_ms: retry_after_ms
        })
    end
  rescue
    error ->
      ErrorHandler.handle_error({:error, :symbol_api_unavailable}, %{
        operation: :external_symbol_search,
        exception: error
      })
  end

  defp perform_external_search(query, max_results) do
    url = build_yahoo_search_url(query, max_results)

    headers = [
      {"User-Agent", "Ashfolio/1.0 (Financial Portfolio Management Application)"},
      {"Accept", "application/json"}
    ]

    case @http_client.get(url, headers,
           timeout: @external_api_timeout,
           recv_timeout: @external_api_timeout
         ) do
      {:ok, %{status_code: 200, body: body}} ->
        parse_yahoo_search_response(body)

      {:ok, %{status_code: 404}} ->
        Logger.debug("No external results found for query: #{query}")
        {:ok, []}

      {:ok, %{status_code: status_code}} ->
        Logger.warning("Yahoo Finance search API returned status #{status_code}")
        {:error, :api_error}

      {:error, %HTTPoison.Error{reason: :timeout}} ->
        Logger.warning("Timeout during external symbol search")
        {:error, :timeout}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.warning("HTTP error during external symbol search: #{inspect(reason)}")
        {:error, :network_error}

      {:error, reason} ->
        Logger.error("Unexpected error during external symbol search: #{inspect(reason)}")
        {:error, :api_unavailable}
    end
  end

  defp build_yahoo_search_url(query, max_results) do
    params =
      URI.encode_query(%{
        q: query,
        # Yahoo Finance limits
        quotesCount: min(max_results, 10),
        newsCount: 0,
        enableFuzzyQuery: false,
        quotesQueryId: "tss_match_phrase_query"
      })

    "#{@yahoo_search_url}?#{params}"
  end

  defp parse_yahoo_search_response(body) do
    case Jason.decode(body) do
      {:ok, %{"quotes" => quotes}} when is_list(quotes) ->
        symbols =
          quotes
          |> Enum.filter(&valid_yahoo_quote?/1)
          |> Enum.map(&convert_yahoo_quote_to_symbol/1)
          |> Enum.filter(&(&1 != nil))

        {:ok, symbols}

      {:ok, _} ->
        Logger.debug("No quotes found in Yahoo Finance search response")
        {:ok, []}

      {:error, reason} ->
        ErrorHandler.handle_error({:error, :symbol_api_unavailable}, %{
          operation: :yahoo_response_parsing,
          parse_error: reason
        })
    end
  end

  defp valid_yahoo_quote?(%{"symbol" => symbol, "shortname" => name})
       when is_binary(symbol) and is_binary(name) and symbol != "" and name != "" do
    # Enhanced input sanitization for external symbol data validation
    with :ok <- validate_symbol_format(symbol),
         :ok <- validate_symbol_length(symbol),
         :ok <- validate_name_format(name),
         :ok <- validate_name_length(name) do
      true
    else
      _ -> false
    end
  end

  defp valid_yahoo_quote?(_), do: false

  defp convert_yahoo_quote_to_symbol(%{"symbol" => symbol, "shortname" => name} = quote) do
    # Try to create the symbol immediately, or return existing one
    symbol_attrs = %{
      symbol: symbol,
      name: name,
      asset_class: determine_asset_class(quote),
      data_source: :yahoo_finance
    }

    case Symbol.create(symbol_attrs) do
      {:ok, created_symbol} ->
        created_symbol

      {:error, _changeset} ->
        # Symbol might already exist, try to find it
        case Symbol.find_by_symbol(symbol) do
          {:ok, [existing_symbol]} -> existing_symbol
          {:ok, []} -> nil
          {:error, _} -> nil
        end
    end
  rescue
    _error -> nil
  end

  # Enhanced input sanitization functions for external symbol data validation
  defp validate_symbol_format(symbol) do
    # Security: Only allow alphanumeric characters, hyphens, and dots for valid stock symbols
    # Filter out potentially malicious symbols (=, ^, and complex special chars)
    if Regex.match?(~r/^[A-Z0-9.-]+$/i, symbol) and
         not String.contains?(symbol, ["=", "^", "<", ">", "&", ";", "|", "`"]) do
      :ok
    else
      {:error, :invalid_symbol_format}
    end
  end

  defp validate_symbol_length(symbol) do
    # Security: Reasonable length limits for stock symbols (typically 1-5 chars, max 10)
    case String.length(symbol) do
      len when len >= 1 and len <= 10 -> :ok
      _ -> {:error, :invalid_symbol_length}
    end
  end

  defp validate_name_format(name) do
    # Security: Basic HTML/script tag detection for name field
    name_lower = String.downcase(name)

    # Check for potentially malicious content
    malicious_patterns = ["<script", "</script", "<iframe", "javascript:", "data:", "vbscript:"]

    if Enum.any?(malicious_patterns, &String.contains?(name_lower, &1)) do
      {:error, :invalid_name_format}
    else
      :ok
    end
  end

  defp validate_name_length(name) do
    # Security: Reasonable length limits for company names (max 200 chars)
    case String.length(name) do
      len when len >= 1 and len <= 200 -> :ok
      _ -> {:error, :invalid_name_length}
    end
  end

  defp determine_asset_class(%{"quoteType" => "EQUITY"}), do: :stock
  defp determine_asset_class(%{"quoteType" => "ETF"}), do: :etf
  defp determine_asset_class(%{"quoteType" => "MUTUALFUND"}), do: :mutual_fund
  defp determine_asset_class(%{"quoteType" => "CRYPTOCURRENCY"}), do: :crypto
  # Default to stock
  defp determine_asset_class(_), do: :stock
end
