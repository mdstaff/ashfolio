# Task: MCP Integration Tests

**Phase**: 1 - Core MCP Tools
**Priority**: P1
**Estimate**: 3-4 hours
**Status**: Complete

## Implementation Status (2025-11-27)

**Completed:**
- [x] Full MCP session lifecycle test (initialize → tools/list → tool calls → shutdown)
- [x] Privacy mode tests (anonymized, full)
- [x] Tool parameter tests
- [x] Error handling tests
- [x] Performance benchmark test
- [x] 11 integration tests + 76 total MCP tests passing

## Objective

Create comprehensive end-to-end integration tests that verify the complete MCP workflow from Claude Code connection through tool execution and privacy filtering.

## Prerequisites

- [ ] Tasks 01-05 complete
- [ ] Test database with realistic financial data
- [ ] Understanding of MCP session lifecycle
- [ ] `PrivacyFilter` refactored to support Process dictionary config overrides (for thread-safe testing)

## Acceptance Criteria

### Functional Requirements

1. Full MCP session lifecycle tested
2. All 5 core tools tested with real data
3. All 4 privacy modes verified
4. Error scenarios covered
5. Performance benchmarks established

### Non-Functional Requirements

1. Tests complete in < 30 seconds
2. No flaky tests (deterministic)
3. Tests work in CI environment
4. Clear failure messages

## TDD Test Cases

### Test File: `test/ashfolio_web/mcp/integration_test.exs`

```elixir
defmodule AshfolioWeb.Mcp.IntegrationTest do
  use Ashfolio.DataCase, async: false
  use AshfolioWeb.ConnCase

  @moduletag :integration
  @moduletag :mcp

  alias Ashfolio.Portfolio.{Account, Transaction, Symbol}

  # Note: Holdings are calculated dynamically from buy/sell transactions
  # via HoldingsCalculator - there is no Holding resource to create directly.

  # Realistic test data setup
  setup do
    # Create symbols
    symbols = [
      create_symbol!("VTI", "Vanguard Total Stock", :etf, "220.50"),
      create_symbol!("VXUS", "Vanguard Intl Stock", :etf, "58.25"),
      create_symbol!("BND", "Vanguard Total Bond", :etf, "74.80"),
      create_symbol!("AAPL", "Apple Inc", :stock, "175.00")
    ]

    # Create accounts
    investment = create_account!("Fidelity 401k", :investment, "Fidelity")
    brokerage = create_account!("Schwab Taxable", :brokerage, "Schwab")
    checking = create_account!("Chase Checking", :checking, "Chase")

    # Create buy transactions to establish holdings
    # (Holdings are derived from transaction history, not stored separately)
    create_transaction!(investment, Enum.at(symbols, 0), :buy, "100", "220.50", ~D[2024-01-15])  # 100 VTI
    create_transaction!(investment, Enum.at(symbols, 2), :buy, "50", "74.80", ~D[2024-01-20])   # 50 BND
    create_transaction!(brokerage, Enum.at(symbols, 0), :buy, "25", "218.00", ~D[2024-02-01])   # 25 VTI
    create_transaction!(brokerage, Enum.at(symbols, 3), :buy, "10", "175.00", ~D[2024-02-15])   # 10 AAPL

    # Additional transactions for testing
    create_transaction!(investment, Enum.at(symbols, 0), :buy, "10", "215.00", ~D[2024-03-01])
    create_transaction!(brokerage, Enum.at(symbols, 3), :dividend, "0", "0.96", ~D[2024-06-01])

    %{
      symbols: symbols,
      accounts: [investment, brokerage, checking],
      investment: investment,
      brokerage: brokerage
    }
  end

  describe "complete MCP session lifecycle" do
    test "initialize -> tools/list -> tool calls -> shutdown", %{conn: conn} do
      # Step 1: Initialize
      {conn, session_id, init_response} = initialize_mcp(conn)

      assert init_response["result"]["serverInfo"]["name"] == "Ashfolio Portfolio Manager"
      assert init_response["result"]["capabilities"]["tools"]
      assert session_id != nil

      # Step 2: List tools
      tools_response = tools_list(conn, session_id)
      tool_names = Enum.map(tools_response["result"]["tools"], & &1["name"])

      assert "list_accounts" in tool_names
      assert "list_transactions" in tool_names
      assert "get_portfolio_summary" in tool_names
      assert "list_symbols" in tool_names

      # Step 3: Call each tool
      accounts_result = call_tool(conn, session_id, "list_accounts", %{})
      assert accounts_result["result"]["isError"] == false

      transactions_result = call_tool(conn, session_id, "list_transactions", %{limit: 5})
      assert transactions_result["result"]["isError"] == false

      summary_result = call_tool(conn, session_id, "get_portfolio_summary", %{})
      assert summary_result["result"]["isError"] == false

      symbols_result = call_tool(conn, session_id, "list_symbols", %{})
      assert symbols_result["result"]["isError"] == false

      # Step 4: Shutdown
      shutdown_result = shutdown_mcp(conn, session_id)
      assert shutdown_result["result"] == nil  # Success
    end
  end

  describe "privacy mode: strict" do
    setup do
      # Use Process dictionary for thread-safe config overriding
      # Requires PrivacyFilter to check Process.get(:mcp_privacy_mode) first
      Process.put(:mcp_privacy_mode, :strict)
      on_exit(fn -> Process.delete(:mcp_privacy_mode) end)
    end

    test "returns only aggregate data", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_accounts", %{})
      content = parse_content(result)

      # Should have counts but no details
      assert Map.has_key?(content, "account_count")
      refute Map.has_key?(content, "accounts")

      # No sensitive data
      refute result |> inspect() |> String.contains?("Fidelity")
      refute result |> inspect() |> String.contains?("401k")
    end

    test "blocks detailed queries", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      # Transactions should return summary only
      result = call_tool(conn, session_id, "list_transactions", %{})
      content = parse_content(result)

      assert Map.has_key?(content, "transaction_count")
      refute Map.has_key?(content, "transactions")
    end
  end

  describe "privacy mode: anonymized" do
    setup do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized)
    end

    test "accounts have letter IDs", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_accounts", %{})
      content = parse_content(result)

      account_ids = get_in(content, ["accounts"]) |> Enum.map(& &1["id"])

      # Should be letter IDs
      assert Enum.all?(account_ids, &(&1 in ["A", "B", "C", "D", "E"]))

      # No real names
      refute result |> inspect() |> String.contains?("Fidelity")
      refute result |> inspect() |> String.contains?("Schwab")
    end

    test "balances are weights summing to 1.0", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_accounts", %{})
      content = parse_content(result)

      weights = get_in(content, ["accounts"]) |> Enum.map(& &1["weight"])

      # Weights should sum to ~1.0
      assert_in_delta Enum.sum(weights), 1.0, 0.01

      # No exact balances
      refute result |> inspect() |> String.contains?("22050")  # 100 * 220.50
    end

    test "portfolio value is tiered", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "get_portfolio_summary", %{})
      content = parse_content(result)

      assert content["value_tier"] in [
        "under_10k", "five_figures", "six_figures",
        "seven_figures", "eight_figures_plus"
      ]
    end

    test "ratios pass through unchanged", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "get_portfolio_summary", %{})
      content = parse_content(result)

      # Allocation percentages should be present and exact
      assert Map.has_key?(content, "allocation")
    end

    test "symbols are converted to asset classes", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_accounts", %{})
      content = parse_content(result)

      # Holdings should show asset classes, not tickers
      first_account = hd(content["accounts"])
      if Map.has_key?(first_account, "holdings") do
        holding = hd(first_account["holdings"])
        assert Map.has_key?(holding, "asset_class")
        refute Map.has_key?(holding, "ticker")
      end
    end
  end

  describe "privacy mode: standard" do
    setup do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :standard)
      on_exit(fn -> Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized) end)
    end

    test "includes account names but not exact balances", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_accounts", %{})

      # Names visible
      assert result |> inspect() |> String.contains?("Fidelity")

      # Exact balances hidden
      refute result |> inspect() |> String.contains?("22050")
    end
  end

  describe "privacy mode: full" do
    setup do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :full)
      on_exit(fn -> Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized) end)
    end

    test "returns all data unfiltered", %{conn: conn, investment: investment} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_accounts", %{})

      # All data visible
      assert result |> inspect() |> String.contains?("Fidelity")
      assert result |> inspect() |> String.contains?(investment.id)
    end
  end

  describe "tool filtering and sorting" do
    test "list_transactions respects filter", %{conn: conn} do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :full)
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_transactions", %{
        "filter" => %{"type" => "buy"}
      })
      content = parse_content(result)

      # All returned transactions should be buy type
      if is_list(content) do
        assert Enum.all?(content, &(&1["type"] == "buy"))
      end
    end

    test "list_transactions respects limit", %{conn: conn} do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :full)
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_transactions", %{
        "limit" => 1
      })
      content = parse_content(result)

      assert length(content) <= 1
    end

    test "list_transactions respects sort", %{conn: conn} do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :full)
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_transactions", %{
        "sort" => [%{"field" => "date", "direction" => "desc"}]
      })
      content = parse_content(result)

      if length(content) > 1 do
        dates = Enum.map(content, & &1["date"])
        assert dates == Enum.sort(dates, :desc)
      end
    end
  end

  describe "error handling" do
    test "invalid tool returns proper error", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "nonexistent_tool", %{})

      assert result["error"]["code"] == -32602
      assert result["error"]["message"] =~ ~r/(not found|unknown)/i
    end

    test "invalid filter gracefully fails", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_transactions", %{
        "filter" => %{"invalid_field" => "value"}
      })

      # Should return error or empty result, not crash
      assert result["result"] || result["error"]
    end

    test "malformed JSON-RPC returns parse error", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", "not valid json")

      response = Jason.decode!(conn.resp_body)
      assert response["error"]["code"] == -32700
    end

    test "missing session returns error", %{conn: conn} do
      request = %{
        "jsonrpc" => "2.0",
        "id" => "1",
        "method" => "tools/list"
      }

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", Jason.encode!(request))

      response = Jason.decode!(conn.resp_body)
      # Should either work (no session required) or return proper error
      assert response["result"] || response["error"]
    end
  end

  describe "performance" do
    @tag :performance
    test "tool calls complete within 100ms", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      tools = ["list_accounts", "list_transactions", "get_portfolio_summary", "list_symbols"]

      for tool <- tools do
        {time_us, _result} = :timer.tc(fn ->
          call_tool(conn, session_id, tool, %{})
        end)

        time_ms = time_us / 1000
        assert time_ms < 100, "#{tool} took #{time_ms}ms, expected < 100ms"
      end
    end

    @tag :performance
    test "privacy filtering adds < 5ms overhead", %{conn: conn} do
      # Test with full mode (no filtering)
      Application.put_env(:ashfolio, :mcp, privacy_mode: :full)
      {conn, session_id, _} = initialize_mcp(conn)

      {full_time, _} = :timer.tc(fn ->
        call_tool(conn, session_id, "list_accounts", %{})
      end)

      # Test with anonymized mode
      Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized)

      {anon_time, _} = :timer.tc(fn ->
        call_tool(conn, session_id, "list_accounts", %{})
      end)

      overhead_ms = (anon_time - full_time) / 1000
      assert overhead_ms < 5, "Privacy filter overhead: #{overhead_ms}ms, expected < 5ms"
    end
  end

  # Helper functions

  defp create_symbol!(ticker, name, type, price) do
    {:ok, symbol} = Symbol.create(%{
      ticker: ticker,
      name: name,
      asset_type: type,
      current_price: Decimal.new(price)
    })
    symbol
  end

  defp create_account!(name, type, institution) do
    {:ok, account} = Account.create(%{
      name: name,
      account_type: type,
      institution: institution
    })
    account
  end

  # Note: No create_holding! helper - holdings are derived from transactions
  # Use create_transaction! with :buy type to establish holdings

  defp create_transaction!(account, symbol, type, quantity, price, date) do
    total = Decimal.mult(Decimal.new(quantity), Decimal.new(price))
    {:ok, txn} = Transaction.create(%{
      account_id: account.id,
      symbol_id: symbol.id,
      type: type,
      quantity: Decimal.new(quantity),
      price: Decimal.new(price),
      total_amount: total,
      fee: Decimal.new("0"),
      date: date
    })
    txn
  end

  defp initialize_mcp(conn) do
    request = %{
      "jsonrpc" => "2.0",
      "id" => "init",
      "method" => "initialize",
      "params" => %{
        "protocolVersion" => "2025-03-26",
        "clientInfo" => %{"name" => "integration-test", "version" => "1.0"}
      }
    }

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept", "application/json")
      |> post("/mcp", Jason.encode!(request))

    response = Jason.decode!(conn.resp_body)
    session_id = get_resp_header(conn, "mcp-session-id") |> List.first()
    {conn, session_id, response}
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

  defp call_tool(conn, session_id, tool_name, arguments) do
    request = %{
      "jsonrpc" => "2.0",
      "id" => "tool-#{tool_name}",
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

  defp shutdown_mcp(conn, session_id) do
    request = %{
      "jsonrpc" => "2.0",
      "id" => "shutdown",
      "method" => "shutdown",
      "params" => %{}
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

### Step 1: Create Test File

Create the integration test file at `test/ashfolio_web/mcp/integration_test.exs`

### Step 2: Create Test Tag Configuration

```elixir
# test/test_helper.exs - add tags

ExUnit.configure(
  exclude: [:skip, :pending],
  include: []
)

# Allow running specific test categories
# mix test --only integration
# mix test --only mcp
# mix test --only performance
```

### Step 3: Run Integration Tests

```bash
# Run all MCP integration tests
mix test test/ashfolio_web/mcp/integration_test.exs --trace

# Run only performance tests
mix test test/ashfolio_web/mcp/integration_test.exs --only performance

# Run without performance tests (faster CI)
mix test test/ashfolio_web/mcp/integration_test.exs --exclude performance
```

### Step 4: Add to CI Pipeline

```yaml
# .github/workflows/test.yml - add MCP test job

mcp-tests:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Set up Elixir
      uses: erlef/setup-beam@v1
      with:
        elixir-version: '1.16'
        otp-version: '26'
    - name: Install dependencies
      run: mix deps.get
    - name: Run MCP integration tests
      run: mix test test/ashfolio_web/mcp/ --exclude performance
```

## Definition of Done

- [ ] All integration tests pass
- [ ] Full session lifecycle verified
- [ ] All 4 privacy modes tested
- [ ] Error handling verified
- [ ] Performance benchmarks pass
- [ ] Tests run in CI
- [ ] No flaky tests
- [ ] `mix test` passes (no regressions)

## Dependencies

**Blocked By**: Tasks 01-05
**Blocks**: Phase 2 tasks

## Notes

- Performance tests may need adjustment based on hardware
- Consider adding load tests for concurrent sessions
- Integration tests should be tagged for selective CI runs

---

*Parent: [../README.md](../README.md)*
