# Task: Tool Search Implementation

**Phase**: 2 - Module Integration
**Priority**: P2
**Estimate**: 3-4 hours
**Status**: Not Started

## Objective

Implement a Tool Search Tool following Anthropic's advanced tool use pattern that reduces token usage by ~85% through deferred tool loading.

## Prerequisites

- [ ] Phase 1 complete
- [ ] Task P2-02 (Module Registry) complete
- [ ] Understanding of Anthropic's tool search pattern

## Background

From Anthropic's "Advanced Tool Use" engineering blog:

> The tool search tool gives Claude a way to search for the right tool before calling it directly. Instead of passing all tool schemas in the initial prompt, pass a single "tool search" tool that Claude can call to find relevant tools.

Benefits:
- 85% reduction in token usage for systems with many tools
- Better tool selection through semantic search
- Faster initial response (smaller prompt)

## Acceptance Criteria

### Functional Requirements

1. `search_tools` MCP tool implemented
2. Search by keyword, category, or description
3. Returns matching tool definitions
4. Supports loading tools into active session

### Non-Functional Requirements

1. Search completes in < 50ms
2. Relevant results in top 3 for common queries
3. Works with all privacy modes
4. No impact on direct tool calls

## TDD Test Cases

### Test File: `test/ashfolio_web/mcp/tool_search_test.exs`

```elixir
defmodule AshfolioWeb.Mcp.ToolSearchTest do
  use Ashfolio.DataCase, async: false
  use AshfolioWeb.ConnCase

  alias AshfolioWeb.Mcp.ToolSearch

  describe "search_tools function" do
    test "searches by keyword" do
      results = ToolSearch.search("accounts")

      tool_names = Enum.map(results, & &1.name)
      assert "list_accounts" in tool_names
    end

    test "searches by category" do
      results = ToolSearch.search("portfolio")

      tool_names = Enum.map(results, & &1.name)
      assert "get_portfolio_summary" in tool_names
    end

    test "searches by description content" do
      results = ToolSearch.search("allocation")

      # Portfolio summary mentions allocation
      tool_names = Enum.map(results, & &1.name)
      assert "get_portfolio_summary" in tool_names
    end

    test "returns empty for no matches" do
      results = ToolSearch.search("xyznonexistent")
      assert results == []
    end

    test "limits results" do
      results = ToolSearch.search("list", limit: 2)
      assert length(results) <= 2
    end

    test "respects privacy mode" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :strict)

      results = ToolSearch.search("transactions")

      # In strict mode, detailed transaction tools shouldn't appear
      tool_names = Enum.map(results, & &1.name)
      refute "list_transactions" in tool_names
    end
  end

  describe "search_tools MCP tool" do
    test "search_tools is listed in tools/list", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      response = tools_list(conn, session_id)
      tool_names = Enum.map(response["result"]["tools"], & &1["name"])

      assert "search_tools" in tool_names
    end

    test "search_tools returns matching tools via MCP", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "search_tools", %{
        "query" => "accounts"
      })

      assert result["result"]["isError"] == false
      content = parse_content(result)

      assert is_list(content["tools"])
      assert length(content["tools"]) > 0

      first_tool = hd(content["tools"])
      assert Map.has_key?(first_tool, "name")
      assert Map.has_key?(first_tool, "description")
      assert Map.has_key?(first_tool, "inputSchema")
    end

    test "search_tools respects limit parameter", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "search_tools", %{
        "query" => "list",
        "limit" => 1
      })

      content = parse_content(result)
      assert length(content["tools"]) <= 1
    end

    test "search_tools includes tool examples when available", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "search_tools", %{
        "query" => "accounts"
      })

      content = parse_content(result)
      tools_with_examples = Enum.filter(content["tools"], &(&1["examples"]))

      # At least some tools should have examples
      assert length(tools_with_examples) > 0
    end
  end

  describe "deferred loading pattern" do
    test "initial tools/list only shows search_tools in deferred mode", %{conn: conn} do
      Application.put_env(:ashfolio, :mcp, deferred_loading: true)
      {conn, session_id} = initialize_mcp(conn)

      response = tools_list(conn, session_id)
      tools = response["result"]["tools"]

      # Should only have search_tools and maybe a few core tools
      assert length(tools) < 5
      tool_names = Enum.map(tools, & &1["name"])
      assert "search_tools" in tool_names
    end

    test "searched tools become available in session", %{conn: conn} do
      Application.put_env(:ashfolio, :mcp, deferred_loading: true)
      {conn, session_id} = initialize_mcp(conn)

      # Search for accounts tools
      _search_result = call_tool(conn, session_id, "search_tools", %{
        "query" => "accounts"
      })

      # Now the tool should be callable
      result = call_tool(conn, session_id, "list_accounts", %{})
      assert result["result"]["isError"] == false
    end
  end

  describe "search quality" do
    test "exact name match ranks highest" do
      results = ToolSearch.search("list_accounts")

      assert hd(results).name == "list_accounts"
    end

    test "partial match works" do
      results = ToolSearch.search("account")

      tool_names = Enum.map(results, & &1.name)
      assert "list_accounts" in tool_names
    end

    test "case insensitive search" do
      results_lower = ToolSearch.search("accounts")
      results_upper = ToolSearch.search("ACCOUNTS")

      assert results_lower == results_upper
    end

    test "multi-word queries work" do
      results = ToolSearch.search("portfolio summary metrics")

      tool_names = Enum.map(results, & &1.name)
      assert "get_portfolio_summary" in tool_names
    end
  end

  # Helper functions

  defp initialize_mcp(conn) do
    request = %{
      "jsonrpc" => "2.0",
      "id" => "init",
      "method" => "initialize",
      "params" => %{
        "protocolVersion" => "2025-03-26",
        "clientInfo" => %{"name" => "test"}
      }
    }

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept", "application/json")
      |> post("/mcp", Jason.encode!(request))

    session_id = get_resp_header(conn, "mcp-session-id") |> hd()
    {conn, session_id}
  end

  defp tools_list(conn, session_id) do
    request = %{"jsonrpc" => "2.0", "id" => "tools", "method" => "tools/list"}

    conn
    |> recycle()
    |> put_req_header("content-type", "application/json")
    |> put_req_header("mcp-session-id", session_id)
    |> post("/mcp", Jason.encode!(request))
    |> Map.get(:resp_body)
    |> Jason.decode!()
  end

  defp call_tool(conn, session_id, tool_name, arguments) do
    request = %{
      "jsonrpc" => "2.0",
      "id" => "call",
      "method" => "tools/call",
      "params" => %{"name" => tool_name, "arguments" => arguments}
    }

    conn
    |> recycle()
    |> put_req_header("content-type", "application/json")
    |> put_req_header("mcp-session-id", session_id)
    |> post("/mcp", Jason.encode!(request))
    |> Map.get(:resp_body)
    |> Jason.decode!()
  end

  defp parse_content(result) do
    result
    |> get_in(["result", "content"])
    |> List.first()
    |> Map.get("text")
    |> Jason.decode!()
  end
end
```

## Implementation Steps

### Step 1: Create Tool Search Module

```elixir
# lib/ashfolio_web/mcp/tool_search.ex

defmodule AshfolioWeb.Mcp.ToolSearch do
  @moduledoc """
  Implements tool search functionality following Anthropic's advanced tool use pattern.

  ## Token Reduction

  Instead of sending all tool schemas in the initial prompt, Claude can search
  for relevant tools and load only what's needed. This can reduce token usage
  by 85% for systems with many tools.

  ## Usage

      # Direct search
      ToolSearch.search("accounts")
      #=> [%{name: "list_accounts", ...}, ...]

      # Via MCP
      tools/call search_tools {query: "portfolio metrics"}
  """

  alias AshfolioWeb.Mcp.ModuleRegistry
  alias AshfolioWeb.Mcp.PrivacyFilter

  @doc """
  Search for tools matching a query.

  ## Options

  - `:limit` - Maximum results (default: 5)
  - `:include_examples` - Include tool examples (default: true)
  """
  @spec search(String.t(), keyword()) :: list(map())
  def search(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    include_examples = Keyword.get(opts, :include_examples, true)

    current_mode = PrivacyFilter.current_mode()

    ModuleRegistry.tools_for_mode(current_mode)
    |> score_and_rank(query)
    |> Enum.take(limit)
    |> maybe_include_examples(include_examples)
  end

  @doc """
  MCP tool definition for search_tools.
  """
  def tool_definition do
    %{
      name: "search_tools",
      description: """
      Search for available tools by keyword, category, or description.
      Use this to find the right tool before calling it directly.
      Returns matching tool definitions with their schemas and examples.
      """,
      source: :built_in,
      module: __MODULE__,
      privacy_mode: :strict,  # Always available
      input_schema: %{
        type: "object",
        properties: %{
          query: %{
            type: "string",
            description: "Search query (keywords, tool name, or description)"
          },
          limit: %{
            type: "integer",
            description: "Maximum number of results (default: 5)",
            default: 5
          },
          category: %{
            type: "string",
            enum: ["portfolio", "transactions", "tax", "analysis", "parsing"],
            description: "Filter by category"
          }
        },
        required: ["query"]
      },
      examples: [
        %{
          description: "Find tools for viewing accounts",
          input: %{query: "accounts"},
          expected_output: "Returns list_accounts and related tools"
        },
        %{
          description: "Find portfolio analysis tools",
          input: %{query: "portfolio metrics allocation"},
          expected_output: "Returns get_portfolio_summary and related tools"
        },
        %{
          description: "Find transaction tools with limit",
          input: %{query: "transactions", limit: 2},
          expected_output: "Returns top 2 matching transaction tools"
        }
      ],
      executor: &execute/1
    }
  end

  @doc """
  Execute search_tools tool call.
  """
  def execute(%{"query" => query} = args) do
    limit = Map.get(args, "limit", 5)
    category = Map.get(args, "category")

    results =
      search(query, limit: limit)
      |> maybe_filter_category(category)
      |> Enum.map(&format_for_response/1)

    {:ok, %{
      tools: results,
      count: length(results),
      query: query
    }}
  end

  # Private Functions

  defp score_and_rank(tools, query) do
    query_terms = query |> String.downcase() |> String.split(~r/\s+/)

    tools
    |> Enum.map(fn tool ->
      score = calculate_score(tool, query_terms)
      {tool, score}
    end)
    |> Enum.filter(fn {_tool, score} -> score > 0 end)
    |> Enum.sort_by(fn {_tool, score} -> score end, :desc)
    |> Enum.map(fn {tool, _score} -> tool end)
  end

  defp calculate_score(tool, query_terms) do
    name_lower = String.downcase(tool.name)
    desc_lower = String.downcase(tool.description)

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

  defp maybe_include_examples(tools, true) do
    tools
  end

  defp maybe_include_examples(tools, false) do
    Enum.map(tools, &Map.delete(&1, :examples))
  end

  defp maybe_filter_category(tools, nil), do: tools

  defp maybe_filter_category(tools, category) do
    Enum.filter(tools, fn tool ->
      tool_category(tool) == category
    end)
  end

  defp tool_category(tool) do
    name = tool.name

    cond do
      String.contains?(name, "account") -> "portfolio"
      String.contains?(name, "transaction") -> "transactions"
      String.contains?(name, "tax") -> "tax"
      String.contains?(name, "portfolio") or String.contains?(name, "summary") -> "analysis"
      String.contains?(name, "parse") -> "parsing"
      true -> "other"
    end
  end

  defp format_for_response(tool) do
    base = %{
      "name" => tool.name,
      "description" => tool.description,
      "inputSchema" => tool.input_schema
    }

    if tool.examples && Enum.any?(tool.examples) do
      Map.put(base, "examples", tool.examples)
    else
      base
    end
  end
end
```

### Step 2: Register search_tools in Module Registry

```elixir
# lib/ashfolio_web/mcp/module_registry.ex - update discover_all_tools

defp discover_all_tools do
  ash_tools = discover_ash_tools()
  parser_tools = discover_parser_tools()
  built_in_tools = discover_built_in_tools()

  (built_in_tools ++ ash_tools ++ parser_tools)
  |> Enum.map(fn tool -> {tool.name, tool} end)
  |> Map.new()
end

defp discover_built_in_tools do
  [
    AshfolioWeb.Mcp.ToolSearch.tool_definition()
  ]
end
```

### Step 3: Add Deferred Loading Support

```elixir
# lib/ashfolio_web/mcp/session_state.ex

defmodule AshfolioWeb.Mcp.SessionState do
  @moduledoc """
  Tracks per-session state for MCP connections, including loaded tools.
  """

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get_session(session_id) do
    Agent.get(__MODULE__, &Map.get(&1, session_id, %{loaded_tools: MapSet.new()}))
  end

  def load_tools(session_id, tool_names) when is_list(tool_names) do
    Agent.update(__MODULE__, fn sessions ->
      session = Map.get(sessions, session_id, %{loaded_tools: MapSet.new()})
      updated = %{session | loaded_tools: MapSet.union(session.loaded_tools, MapSet.new(tool_names))}
      Map.put(sessions, session_id, updated)
    end)
  end

  def tool_loaded?(session_id, tool_name) do
    session = get_session(session_id)
    MapSet.member?(session.loaded_tools, tool_name)
  end
end
```

### Step 4: Run Tests

```bash
mix test test/ashfolio_web/mcp/tool_search_test.exs --trace
```

## Definition of Done

- [ ] search_tools MCP tool implemented
- [ ] Keyword search works
- [ ] Category filtering works
- [ ] Privacy mode respected
- [ ] Deferred loading pattern supported
- [ ] Search quality tests pass
- [ ] All TDD tests pass
- [ ] `mix test` passes (no regressions)

## Dependencies

**Blocked By**: Task P2-02 (Module Registry)
**Blocks**: None (Phase 3 can proceed)

## Notes

- Consider adding semantic search with embeddings (future)
- Monitor search quality and adjust scoring
- Add analytics for common search patterns

---

*Parent: [../README.md](../README.md)*
