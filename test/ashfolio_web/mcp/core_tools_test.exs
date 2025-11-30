defmodule AshfolioWeb.Mcp.CoreToolsTest do
  use AshfolioWeb.ConnCase, async: false

  @moduletag :mcp

  alias Ashfolio.Portfolio.Account
  alias Ashfolio.Portfolio.Symbol

  setup do
    # Create test symbol
    {:ok, symbol} =
      Ash.create(Symbol, %{
        symbol: "VTI",
        name: "Vanguard Total Stock Market ETF",
        asset_class: :etf,
        data_source: :manual,
        current_price: Decimal.new("250.00")
      })

    # Create test account
    {:ok, account} =
      Ash.create(Account, %{
        name: "Test 401k",
        account_type: :investment,
        platform: "Fidelity",
        balance: Decimal.new("10000.00")
      })

    %{account: account, symbol: symbol}
  end

  describe "tools/list" do
    test "returns portfolio tools", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      request = %{
        "jsonrpc" => "2.0",
        "id" => "tools",
        "method" => "tools/list"
      }

      conn =
        conn
        |> recycle()
        |> put_req_header("content-type", "application/json")
        |> put_req_header("mcp-session-id", session_id)
        |> post("/mcp", Jason.encode!(request))

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)

      tools = response["result"]["tools"]
      assert is_list(tools)

      tool_names = Enum.map(tools, & &1["name"])
      assert "list_accounts" in tool_names
      assert "list_transactions" in tool_names
      assert "list_symbols" in tool_names
      assert "get_portfolio_summary" in tool_names
    end
  end

  describe "list_accounts tool" do
    test "returns accounts via MCP", %{conn: conn, account: _account} do
      {conn, session_id} = initialize_mcp(conn)

      response = call_tool(conn, session_id, "list_accounts", %{})

      # Tool should execute without error
      assert response["result"]
      refute response["error"]
    end
  end

  describe "list_symbols tool" do
    test "returns symbols via MCP", %{conn: conn, symbol: _symbol} do
      {conn, session_id} = initialize_mcp(conn)

      response = call_tool(conn, session_id, "list_symbols", %{})

      assert response["result"]
      refute response["error"]
    end
  end

  describe "list_transactions tool" do
    test "returns transactions via MCP", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      response = call_tool(conn, session_id, "list_transactions", %{})

      assert response["result"]
      refute response["error"]
    end
  end

  describe "get_portfolio_summary tool" do
    test "returns portfolio summary via MCP", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      response = call_tool(conn, session_id, "get_portfolio_summary", %{})

      assert response["result"]
      refute response["error"]
    end
  end

  describe "privacy filtering" do
    test "list_accounts applies privacy filter in anonymized mode", %{conn: conn} do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized)
      {conn, session_id} = initialize_mcp(conn)

      response = call_tool(conn, session_id, "list_accounts", %{})
      content = get_tool_content(response)

      # In anonymized mode, should have letter IDs not real names
      refute content |> inspect() |> String.contains?("Test 401k")
    end

    test "list_accounts returns full data in full mode", %{conn: conn} do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :full)
      {conn, session_id} = initialize_mcp(conn)

      response = call_tool(conn, session_id, "list_accounts", %{})
      content = get_tool_content(response)

      # In full mode, real names should be present
      assert content |> inspect() |> String.contains?("Test 401k")
    end
  end

  describe "error handling" do
    test "returns error for unknown tool", %{conn: conn} do
      {conn, session_id} = initialize_mcp(conn)

      response = call_tool(conn, session_id, "unknown_tool", %{})

      assert response["error"]
      assert response["error"]["code"]
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

    session_id = conn |> get_resp_header("mcp-session-id") |> hd()
    {conn, session_id}
  end

  defp call_tool(conn, session_id, tool_name, arguments) do
    request = %{
      "jsonrpc" => "2.0",
      "id" => "tool-call",
      "method" => "tools/call",
      "params" => %{
        "name" => tool_name,
        "arguments" => arguments
      }
    }

    conn =
      conn
      |> recycle()
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept", "application/json")
      |> put_req_header("mcp-session-id", session_id)
      |> post("/mcp", Jason.encode!(request))

    Jason.decode!(conn.resp_body)
  end

  defp get_tool_content(response) do
    response["result"]["content"]
    |> hd()
    |> Map.get("text")
    |> Jason.decode!()
  end
end
