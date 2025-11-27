# Task: Tool Examples Implementation

**Phase**: 1 - Core MCP Tools
**Priority**: P2
**Estimate**: 2-3 hours
**Status**: Deferred (Partial Implementation)

## Implementation Status (2025-11-27)

**Assessment:** The original spec assumed AshAi's `tool` DSL supports an `examples` option, but this doesn't exist in AshAi 0.3.0. The supported options are: `name`, `resource`, `action`, `action_parameters`, `load`, `async`, `description`, `identity`.

**Partial Implementation:**
- [x] Enhanced tool descriptions with usage guidance and expected outputs
- [ ] ~~Examples in tools/list response~~ (requires AshAi upstream support)

**Future Work:**
- Consider contributing `examples` support to AshAi upstream (see: https://github.com/ash-project/ash_ai)
- Once AshAi supports examples, implement `AshfolioWeb.Mcp.ToolExamples` module per original spec

## Objective

Implement tool examples following Anthropic's best practices for optimal Claude understanding and usage of Ashfolio MCP tools.

## Prerequisites

- [ ] Task 04 (Core Tools) complete
- [ ] Understanding of Anthropic tool use best practices

## Acceptance Criteria

### Functional Requirements

1. Each tool has 2-3 example invocations
2. Examples demonstrate common use cases
3. Examples show filter/sort/limit parameters
4. Examples returned in `tools/list` response
5. Examples cover edge cases (e.g., empty results, filtered views)

### Non-Functional Requirements

1. Examples follow Anthropic's documented patterns
2. Clear expected output descriptions
3. Examples work with all privacy modes

## TDD Test Cases

### Test File: `test/ashfolio_web/mcp/tool_examples_test.exs`

```elixir
defmodule AshfolioWeb.Mcp.ToolExamplesTest do
  use AshfolioWeb.ConnCase, async: true

  describe "tools/list includes examples" do
    test "list_accounts has usage examples", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      response = tools_list(conn, session_id)
      list_accounts = find_tool(response, "list_accounts")

      assert list_accounts["examples"]
      assert length(list_accounts["examples"]) >= 2

      # First example should be basic usage
      first = hd(list_accounts["examples"])
      assert first["description"]
      assert first["input"]
    end

    test "list_transactions has filter examples", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      response = tools_list(conn, session_id)
      list_transactions = find_tool(response, "list_transactions")

      examples = list_transactions["examples"]

      # Should have filter example
      filter_example = Enum.find(examples, &(&1["description"] =~ "filter"))
      assert filter_example
      assert filter_example["input"]["filter"]

      # Should have sort example
      sort_example = Enum.find(examples, &(&1["description"] =~ "sort"))
      assert sort_example
      assert sort_example["input"]["sort"]
    end

    test "get_portfolio_summary has scenario examples", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      response = tools_list(conn, session_id)
      summary = find_tool(response, "get_portfolio_summary")

      examples = summary["examples"]
      assert length(examples) >= 1

      # Example should describe what Claude can learn
      first = hd(examples)
      assert first["expected_output"] =~ ~r/(allocation|diversification|risk)/i
    end

    test "list_symbols has asset type filter example", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      response = tools_list(conn, session_id)
      list_symbols = find_tool(response, "list_symbols")

      examples = list_symbols["examples"]
      type_example = Enum.find(examples, &(&1["description"] =~ "type"))
      assert type_example
    end
  end

  describe "example format follows Anthropic patterns" do
    test "examples have required fields", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      response = tools_list(conn, session_id)
      tools = response["result"]["tools"]

      for tool <- tools do
        for example <- tool["examples"] || [] do
          assert Map.has_key?(example, "description"),
                 "Example missing description in #{tool["name"]}"
          assert Map.has_key?(example, "input"),
                 "Example missing input in #{tool["name"]}"
        end
      end
    end

    test "example inputs match tool schema", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      response = tools_list(conn, session_id)
      list_transactions = find_tool(response, "list_transactions")

      schema_props = list_transactions["inputSchema"]["properties"] || %{}

      for example <- list_transactions["examples"] || [] do
        input_keys = Map.keys(example["input"])
        schema_keys = Map.keys(schema_props)

        # All example input keys should be valid schema properties
        for key <- input_keys do
          assert key in schema_keys,
                 "Example input '#{key}' not in schema for list_transactions"
        end
      end
    end
  end

  describe "examples are executable" do
    setup do
      # Create test data
      {:ok, symbol} = Ashfolio.Portfolio.Symbol.create(%{
        ticker: "VTI",
        name: "Vanguard Total Stock",
        asset_type: :etf
      })

      {:ok, account} = Ashfolio.Portfolio.Account.create(%{
        name: "Test Account",
        account_type: :investment
      })

      %{symbol: symbol, account: account}
    end

    test "list_accounts example executes successfully", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      response = tools_list(conn, session_id)
      list_accounts = find_tool(response, "list_accounts")
      first_example = hd(list_accounts["examples"])

      # Execute the example
      result = call_tool(conn, session_id, "list_accounts", first_example["input"])

      assert result["result"]["isError"] == false
    end

    test "list_transactions filter example executes", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      response = tools_list(conn, session_id)
      list_transactions = find_tool(response, "list_transactions")
      filter_example = Enum.find(
        list_transactions["examples"],
        &(&1["description"] =~ "filter")
      )

      result = call_tool(conn, session_id, "list_transactions", filter_example["input"])

      # Should succeed (even if empty results)
      assert result["result"]["isError"] == false
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
    request = %{
      "jsonrpc" => "2.0",
      "id" => "tools",
      "method" => "tools/list"
    }

    conn
    |> recycle()
    |> put_req_header("content-type", "application/json")
    |> put_req_header("mcp-session-id", session_id)
    |> post("/mcp", Jason.encode!(request))
    |> Map.get(:resp_body)
    |> Jason.decode!()
  end

  defp find_tool(response, name) do
    Enum.find(response["result"]["tools"], &(&1["name"] == name))
  end

  defp call_tool(conn, session_id, tool_name, arguments) do
    request = %{
      "jsonrpc" => "2.0",
      "id" => "call",
      "method" => "tools/call",
      "params" => %{
        "name" => tool_name,
        "arguments" => arguments
      }
    }

    conn
    |> recycle()
    |> put_req_header("content-type", "application/json")
    |> put_req_header("mcp-session-id", session_id)
    |> post("/mcp", Jason.encode!(request))
    |> Map.get(:resp_body)
    |> Jason.decode!()
  end
end
```

## Implementation Steps

### Step 1: Create Tool Examples Module

```elixir
# lib/ashfolio_web/mcp/tool_examples.ex

defmodule AshfolioWeb.Mcp.ToolExamples do
  @moduledoc """
  Provides examples for MCP tools following Anthropic best practices.

  Examples help Claude understand:
  1. When to use each tool
  2. What parameters to provide
  3. What output to expect
  """

  @doc """
  Get examples for a specific tool.
  """
  def for_tool(tool_name) do
    case tool_name do
      "list_accounts" -> list_accounts_examples()
      "list_transactions" -> list_transactions_examples()
      "get_portfolio_summary" -> get_portfolio_summary_examples()
      "list_symbols" -> list_symbols_examples()
      "get_account" -> get_account_examples()
      _ -> []
    end
  end

  defp list_accounts_examples do
    [
      %{
        description: "List all accounts to see portfolio overview",
        input: %{},
        expected_output: "Returns accounts with IDs, types, and relative weights. Use this to understand the user's account structure."
      },
      %{
        description: "Get accounts sorted by value (largest first)",
        input: %{
          sort: [%{field: "current_value", direction: "desc"}]
        },
        expected_output: "Accounts ordered by size, useful for identifying primary accounts."
      },
      %{
        description: "Get only investment accounts",
        input: %{
          filter: %{account_type: "investment"}
        },
        expected_output: "Filtered list of investment accounts only."
      }
    ]
  end

  defp list_transactions_examples do
    [
      %{
        description: "Get recent transactions",
        input: %{
          limit: 10,
          sort: [%{field: "date", direction: "desc"}]
        },
        expected_output: "Most recent 10 transactions with types and relative amounts."
      },
      %{
        description: "Filter transactions by type (buy orders only)",
        input: %{
          filter: %{type: "buy"}
        },
        expected_output: "All buy transactions, useful for analyzing purchase history."
      },
      %{
        description: "Get transactions for a specific account",
        input: %{
          filter: %{account_id: "A"},
          sort: [%{field: "date", direction: "desc"}]
        },
        expected_output: "Transactions for account A, ordered by date."
      },
      %{
        description: "Get dividend income transactions",
        input: %{
          filter: %{type: "dividend"}
        },
        expected_output: "All dividend transactions for income analysis."
      }
    ]
  end

  defp get_portfolio_summary_examples do
    [
      %{
        description: "Get overall portfolio metrics",
        input: %{},
        expected_output: "Returns value tier, allocation percentages by account type, diversification score, and risk assessment. Percentages and ratios are exact; absolute values are categorized."
      },
      %{
        description: "Analyze portfolio for retirement planning",
        input: %{},
        expected_output: "Use the allocation and risk_level fields to assess retirement readiness. Compare against age-appropriate asset allocation guidelines."
      }
    ]
  end

  defp list_symbols_examples do
    [
      %{
        description: "List all securities in portfolio",
        input: %{},
        expected_output: "All symbols with ticker, name, and asset type (stock, etf, bond, etc.)."
      },
      %{
        description: "Filter by asset type (ETFs only)",
        input: %{
          filter: %{asset_type: "etf"}
        },
        expected_output: "Only ETF holdings, useful for analyzing passive investment exposure."
      }
    ]
  end

  defp get_account_examples do
    [
      %{
        description: "Get details for a specific account",
        input: %{
          id: "A"
        },
        expected_output: "Account details including holdings and their weights within this account."
      }
    ]
  end
end
```

### Step 2: Integrate Examples with AshAi Tools

```elixir
# lib/ashfolio/portfolio.ex - Update tools block

defmodule Ashfolio.Portfolio do
  use Ash.Domain,
    extensions: [AshAi]

  # ... resources ...

  tools do
    tool :list_accounts, Ashfolio.Portfolio.Account, :read,
      description: "List all investment and cash accounts with their current values. Returns anonymized data by default (letter IDs, relative weights instead of balances).",
      load: [:holdings],
      examples: AshfolioWeb.Mcp.ToolExamples.for_tool("list_accounts")

    tool :list_transactions, Ashfolio.Portfolio.Transaction, :read,
      description: "Query transactions by account, date range, type, or symbol. Supports filtering, sorting, and pagination. Returns anonymized data by default.",
      action_parameters: [:filter, :sort, :limit, :offset],
      examples: AshfolioWeb.Mcp.ToolExamples.for_tool("list_transactions")

    tool :list_symbols, Ashfolio.Portfolio.Symbol, :read,
      description: "List all available securities/symbols in the portfolio. Symbols are not considered sensitive data.",
      examples: AshfolioWeb.Mcp.ToolExamples.for_tool("list_symbols")

    tool :get_portfolio_summary, Ashfolio.Portfolio.PortfolioSummary, :summary,
      description: "Get aggregate portfolio metrics including allocation percentages, diversification score, and risk assessment. Safe for all privacy modes.",
      examples: AshfolioWeb.Mcp.ToolExamples.for_tool("get_portfolio_summary")
  end
end
```

### Step 3: Run Tests

```bash
mix test test/ashfolio_web/mcp/tool_examples_test.exs --trace
```

## Definition of Done

- [ ] All 5 tools have examples
- [ ] Examples follow Anthropic patterns
- [ ] Examples are executable (don't error)
- [ ] Examples appear in tools/list response
- [ ] All TDD tests pass
- [ ] `mix test` passes (no regressions)

## Dependencies

**Blocked By**: Task 04 (Core Tools)
**Blocks**: Task 06 (Integration Tests)

## Notes

- Examples should reflect privacy mode behavior
- Consider adding "why to use this tool" guidance
- Future: Auto-generate examples from test data

---

*Parent: [../README.md](../README.md)*
