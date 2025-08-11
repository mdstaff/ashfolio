defmodule Ashfolio.FinancialManagement.SymbolSearch do
  @moduledoc """
  Local-first symbol search with ETS caching for Ashfolio financial management.
  
  Provides efficient symbol lookup by ticker and company name with relevance ranking
  and configurable TTL-based caching. Optimized for SQLite local-first architecture.
  
  Features:
  - Case-insensitive search by ticker symbol and company name
  - Relevance-based result ranking (exact > starts with > contains)
  - ETS-based result caching with configurable TTL (default: 5 minutes)
  - Maximum 50 results per search to prevent UI overflow
  - Performance monitoring with telemetry integration
  
  ## Examples
  
      # Search by ticker
      {:ok, results} = SymbolSearch.search("AAPL")
      
      # Search by company name
      {:ok, results} = SymbolSearch.search("Apple")
      
      # Search with custom options
      {:ok, results} = SymbolSearch.search("MSFT", max_results: 10, ttl_seconds: 600)
  """
  
  alias Ashfolio.Portfolio.Symbol
  require Logger

  # ETS table for caching search results
  @cache_table :ashfolio_symbol_search_cache
  @default_ttl_seconds 300  # 5 minutes
  @default_max_results 50   # Maximum results to prevent UI overflow

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
    create_cache_table()
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
    # Delete existing table if it exists
    try do
      :ets.delete(@cache_table)
    rescue
      ArgumentError -> :ok
    end
    
    # Create new table
    :ets.new(@cache_table, [:named_table, :public, :set])
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

  defp perform_search("", max_results) do
    # Empty query returns limited results (recent symbols)
    {:ok, symbols} = Symbol.list()
    limited_results = symbols |> Enum.take(max_results)
    {:ok, limited_results}
  end

  defp perform_search(normalized_query, max_results) do
    with {:ok, all_symbols} <- Symbol.list() do
      results = 
        all_symbols
        |> filter_and_rank_symbols(normalized_query)
        |> Enum.take(max_results)
      
      {:ok, results}
    end
  end

  defp filter_and_rank_symbols(symbols, query) do
    symbols
    |> Enum.reduce([], fn symbol, acc ->
      case calculate_relevance(symbol, query) do
        0 -> acc  # No match
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
end