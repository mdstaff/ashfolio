defmodule AshfolioWeb.Mcp.ToolSearch do
  @moduledoc """
  Tool search functionality following Anthropic's advanced tool use pattern.

  Instead of sending all tool schemas in the initial prompt, Claude can search
  for relevant tools and load only what's needed. This reduces token usage
  by ~85% for systems with many tools.

  ## Scoring Algorithm

  - Exact name match: 100 points
  - Name contains term: 50 points
  - Description contains term: 10 points

  ## Usage

      # Direct search
      ToolSearch.search("accounts")
      #=> [%{name: :list_accounts, ...}, ...]

      # With options
      ToolSearch.search("portfolio", limit: 3)
  """

  alias AshfolioWeb.Mcp.ModuleRegistry
  alias AshfolioWeb.Mcp.PrivacyFilter

  @doc """
  Search for tools matching a query.

  ## Options

  - `:limit` - Maximum results (default: 5)
  - `:mode` - Privacy mode override (default: current mode)
  """
  @spec search(String.t(), keyword()) :: [map()]
  def search(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    mode = Keyword.get(opts, :mode, PrivacyFilter.current_mode())

    mode
    |> ModuleRegistry.tools_for_mode()
    |> score_and_rank(query)
    |> Enum.take(limit)
  end

  @doc """
  Execute search as an MCP tool call.

  Returns `{:ok, result}` with matching tools.
  """
  @spec execute(map()) :: {:ok, map()}
  def execute(%{"query" => query} = args) do
    limit = Map.get(args, "limit", 5)

    results =
      query
      |> search(limit: limit)
      |> Enum.map(&format_tool_for_response/1)

    {:ok,
     %{
       tools: results,
       count: length(results),
       query: query
     }}
  end

  def execute(_args) do
    {:error, "Missing required 'query' parameter"}
  end

  # =============================================================================
  # Private: Scoring
  # =============================================================================

  defp score_and_rank(tools, query) do
    query_terms =
      query
      |> String.downcase()
      |> String.split(~r/[\s_]+/, trim: true)

    tools
    |> Enum.map(fn tool -> {tool, calculate_score(tool, query_terms)} end)
    |> Enum.filter(fn {_tool, score} -> score > 0 end)
    |> Enum.sort_by(fn {_tool, score} -> score end, :desc)
    |> Enum.map(fn {tool, _score} -> tool end)
  end

  defp calculate_score(tool, query_terms) do
    name_str = Atom.to_string(tool.name)
    name_lower = String.downcase(name_str)
    desc_lower = String.downcase(tool.description || "")

    Enum.reduce(query_terms, 0, fn term, acc ->
      cond do
        # Exact name match - highest score
        name_lower == term -> acc + 100
        # Name contains term
        String.contains?(name_lower, term) -> acc + 50
        # Description contains term
        String.contains?(desc_lower, term) -> acc + 10
        true -> acc
      end
    end)
  end

  # =============================================================================
  # Private: Response Formatting
  # =============================================================================

  defp format_tool_for_response(tool) do
    %{
      name: tool.name,
      description: tool.description,
      source: tool.source,
      privacy_modes: tool.privacy_modes
    }
  end
end
