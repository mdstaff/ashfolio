# Task: MCP Router Setup

**Phase**: 1 - Core MCP Tools
**Priority**: P0 (Blocking)
**Estimate**: 2-4 hours
**Status**: Complete

## Objective

Configure Phoenix router to forward MCP requests to `AshAi.Mcp.Router` and verify basic MCP protocol functionality.

## Prerequisites

- [ ] Ash AI 0.3.0+ installed (already in mix.exs)
- [ ] Understanding of MCP protocol basics

## Acceptance Criteria

### Functional Requirements

1. MCP endpoint responds at `/mcp`
2. `initialize` method returns server info and capabilities
3. `tools/list` method returns available tools (empty initially)
4. `shutdown` method completes gracefully
5. Unknown methods return proper JSON-RPC error

### Non-Functional Requirements

1. Response time < 50ms for protocol methods
2. No console errors or warnings
3. Works with Claude Code CLI connection

## TDD Test Cases

### Test File: `test/ashfolio_web/mcp/router_test.exs`

```elixir
defmodule AshfolioWeb.Mcp.RouterTest do
  use AshfolioWeb.ConnCase, async: true

  describe "MCP protocol" do
    test "POST /mcp with initialize returns server info", %{conn: conn} do
      request = %{
        "jsonrpc" => "2.0",
        "id" => "1",
        "method" => "initialize",
        "params" => %{
          "protocolVersion" => "2025-03-26",
          "clientInfo" => %{"name" => "test-client", "version" => "1.0"}
        }
      }

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("accept", "application/json")
        |> post("/mcp", Jason.encode!(request))

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)

      assert response["jsonrpc"] == "2.0"
      assert response["id"] == "1"
      assert response["result"]["serverInfo"]["name"] == "Ashfolio Portfolio Manager"
      assert response["result"]["capabilities"]["tools"]

      # Session ID should be returned in header
      assert get_resp_header(conn, "mcp-session-id") != []
    end

    test "POST /mcp with tools/list returns empty list initially", %{conn: conn} do
      # First initialize to get session
      {conn, session_id} = initialize_session(conn)

      request = %{
        "jsonrpc" => "2.0",
        "id" => "2",
        "method" => "tools/list"
      }

      conn =
        conn
        |> recycle()
        |> put_req_header("content-type", "application/json")
        |> put_req_header("accept", "application/json")
        |> put_req_header("mcp-session-id", session_id)
        |> post("/mcp", Jason.encode!(request))

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)

      assert response["result"]["tools"] |> is_list()
    end

    test "POST /mcp with shutdown returns success", %{conn: conn} do
      {conn, session_id} = initialize_session(conn)

      request = %{
        "jsonrpc" => "2.0",
        "id" => "3",
        "method" => "shutdown",
        "params" => %{}
      }

      conn =
        conn
        |> recycle()
        |> put_req_header("content-type", "application/json")
        |> put_req_header("mcp-session-id", session_id)
        |> post("/mcp", Jason.encode!(request))

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)

      assert response["result"] == nil  # Success with null result
    end

    test "POST /mcp with unknown method returns error", %{conn: conn} do
      {conn, session_id} = initialize_session(conn)

      request = %{
        "jsonrpc" => "2.0",
        "id" => "4",
        "method" => "unknown/method",
        "params" => %{}
      }

      conn =
        conn
        |> recycle()
        |> put_req_header("content-type", "application/json")
        |> put_req_header("mcp-session-id", session_id)
        |> post("/mcp", Jason.encode!(request))

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)

      assert response["error"]["code"] == -32601
      assert response["error"]["message"] =~ "not implemented"
    end

    test "POST /mcp with invalid JSON returns parse error", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", "not valid json")

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)

      assert response["error"]["code"] == -32700
    end

    test "GET /mcp returns SSE endpoint info", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "text/event-stream")
        |> get("/mcp")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") |> hd() =~ "text/event-stream"
    end
  end

  # Helper functions

  defp initialize_session(conn) do
    request = %{
      "jsonrpc" => "2.0",
      "id" => "init",
      "method" => "initialize",
      "params" => %{"protocolVersion" => "2025-03-26", "clientInfo" => %{"name" => "test"}}
    }

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept", "application/json")
      |> post("/mcp", Jason.encode!(request))

    session_id = get_resp_header(conn, "mcp-session-id") |> hd()
    {conn, session_id}
  end
end
```

## Implementation Steps

### Step 1: Add Route to Router

```elixir
# lib/ashfolio_web/router.ex

defmodule AshfolioWeb.Router do
  use AshfolioWeb, :router

  # ... existing pipelines ...

  # MCP endpoint (no pipeline - AshAi.Mcp.Router handles everything)
  forward "/mcp", AshAi.Mcp.Router,
    otp_app: :ashfolio,
    mcp_name: "Ashfolio Portfolio Manager",
    mcp_server_version: Application.spec(:ashfolio, :vsn) |> to_string()
end
```

### Step 2: Add Configuration

```elixir
# config/config.exs

config :ashfolio, :mcp,
  enabled: true,
  privacy_mode: :anonymized
```

### Step 3: Verify AshAi Extension

Ensure `AshAi` extension is added to at least one domain (even without tools initially):

```elixir
# lib/ashfolio/portfolio.ex

defmodule Ashfolio.Portfolio do
  use Ash.Domain,
    extensions: [AshAi]  # Add this

  # ... existing resources ...
end
```

### Step 4: Run Tests

```bash
# Run router tests only
mix test test/ashfolio_web/mcp/router_test.exs

# Run all tests to ensure no regressions
mix test
```

### Step 5: Manual Verification with Claude Code

```bash
# In Ashfolio project directory with server running
claude --mcp-server http://localhost:4000/mcp

# Or add to Claude Code config
# ~/.config/claude-code/mcp_servers.json
{
  "ashfolio": {
    "url": "http://localhost:4000/mcp"
  }
}
```

## Definition of Done

- [x] All TDD tests pass
- [x] Route added to router.ex
- [x] Configuration added to config.exs
- [x] No compilation warnings
- [ ] Manual test with Claude Code CLI succeeds
- [x] `mix test` passes (no regressions)

## Rollback Plan

If issues arise:
1. Remove `forward "/mcp"` from router
2. Remove `extensions: [AshAi]` from domain
3. Tests will fail but app remains functional

## Dependencies

**Blocked By**: None
**Blocks**: All other Phase 1 tasks

## Notes

- AshAi.Mcp.Router handles JSON parsing internally
- No authentication needed (single-user model)
- Session management is handled by AshAi

---

*Parent: [../README.md](../README.md)*
