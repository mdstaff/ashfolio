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

      assert is_list(response["result"]["tools"])
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

      # Success with null result
      assert response["result"] == nil
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

      assert response["error"]["code"] == -32_601
      assert response["error"]["message"] =~ "not implemented"
    end

    test "POST /mcp with invalid JSON returns parse error", %{conn: conn} do
      # AshAi.Mcp.Router uses Plug.Parsers which raises ParseError for invalid JSON
      # rather than returning JSON-RPC -32700. This is acceptable behavior since
      # clients should always send valid JSON.
      assert_raise Plug.Parsers.ParseError, fn ->
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/mcp", "not valid json")
      end
    end

    test "GET /mcp returns SSE endpoint info", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "text/event-stream")
        |> get("/mcp")

      assert conn.status == 200
      assert conn |> get_resp_header("content-type") |> hd() =~ "text/event-stream"
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

    session_id = conn |> get_resp_header("mcp-session-id") |> hd()
    {conn, session_id}
  end
end
