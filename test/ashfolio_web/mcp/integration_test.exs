defmodule AshfolioWeb.Mcp.IntegrationTest do
  @moduledoc """
  End-to-end integration tests for MCP workflow.

  Tests the complete flow from MCP connection through tool execution
  and privacy filtering with realistic financial data.
  """
  use AshfolioWeb.ConnCase, async: false

  alias Ashfolio.Portfolio.Account
  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Portfolio.Transaction

  @moduletag :integration
  @moduletag :mcp

  # Realistic test data setup
  setup do
    # Create symbols
    symbols = [
      create_symbol!("VTI", "Vanguard Total Stock", :etf, "220.50"),
      create_symbol!("VXUS", "Vanguard Intl Stock", :etf, "58.25"),
      create_symbol!("BND", "Vanguard Total Bond", :etf, "74.80"),
      create_symbol!("AAPL", "Apple Inc", :stock, "175.00")
    ]

    # Create accounts with balances
    # Valid types: :investment, :checking, :savings, :money_market, :cd
    investment =
      create_account!("Fidelity 401k", :investment, "Fidelity", "50000.00")

    savings = create_account!("Ally Savings", :savings, "Ally", "25000.00")
    checking = create_account!("Chase Checking", :checking, "Chase", "5000.00")

    # Create transactions
    create_transaction!(
      investment,
      Enum.at(symbols, 0),
      :buy,
      "100",
      "220.50",
      ~D[2024-01-15]
    )

    create_transaction!(
      investment,
      Enum.at(symbols, 2),
      :buy,
      "50",
      "74.80",
      ~D[2024-01-20]
    )

    create_transaction!(savings, Enum.at(symbols, 0), :buy, "25", "218.00", ~D[2024-02-01])
    create_transaction!(savings, Enum.at(symbols, 3), :buy, "10", "175.00", ~D[2024-02-15])
    create_transaction!(investment, Enum.at(symbols, 0), :buy, "10", "215.00", ~D[2024-03-01])

    create_transaction!(
      savings,
      Enum.at(symbols, 3),
      :dividend,
      "10",
      "0.96",
      ~D[2024-06-01]
    )

    # Clean up Process dictionary after each test (thread-safe approach)
    on_exit(fn ->
      Process.delete(:mcp_privacy_mode)
    end)

    %{
      symbols: symbols,
      accounts: [investment, savings, checking],
      investment: investment,
      savings: savings
    }
  end

  describe "complete MCP session lifecycle" do
    test "initialize -> tools/list -> tool calls -> shutdown", %{conn: conn} do
      # Step 1: Initialize
      {conn, session_id, init_response} = initialize_mcp(conn)

      assert init_response["result"]["serverInfo"]["name"]
      assert init_response["result"]["capabilities"]["tools"]
      assert session_id

      # Step 2: List tools
      tools_response = tools_list(conn, session_id)
      tool_names = Enum.map(tools_response["result"]["tools"], & &1["name"])

      assert "list_accounts" in tool_names
      assert "list_transactions" in tool_names
      assert "get_portfolio_summary" in tool_names
      assert "list_symbols" in tool_names

      # Step 3: Call each tool
      accounts_result = call_tool(conn, session_id, "list_accounts", %{})
      assert accounts_result["result"]
      refute accounts_result["error"]

      transactions_result = call_tool(conn, session_id, "list_transactions", %{"limit" => 5})
      assert transactions_result["result"]
      refute transactions_result["error"]

      summary_result = call_tool(conn, session_id, "get_portfolio_summary", %{})
      assert summary_result["result"]
      refute summary_result["error"]

      symbols_result = call_tool(conn, session_id, "list_symbols", %{})
      assert symbols_result["result"]
      refute symbols_result["error"]

      # Step 4: Shutdown
      shutdown_result = shutdown_mcp(conn, session_id)
      # Shutdown returns empty result on success
      refute shutdown_result["error"]
    end
  end

  describe "privacy mode: anonymized (default)" do
    setup do
      # Use Process dictionary for thread-safe test isolation
      Process.put(:mcp_privacy_mode, :anonymized)
      :ok
    end

    test "accounts have letter IDs not real names", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_accounts", %{})
      content = parse_content(result)

      # Privacy filter returns %{accounts: [...], portfolio: %{...}}
      assert Map.has_key?(content, "accounts")
      accounts = content["accounts"]
      assert is_list(accounts)
      assert length(accounts) > 0

      # Account IDs should be letter IDs (A, B, C)
      account_ids = Enum.map(accounts, & &1["id"])
      assert Enum.all?(account_ids, &(&1 in ["A", "B", "C", "D", "E"]))

      # No real names visible
      result_str = inspect(result)
      refute String.contains?(result_str, "Fidelity 401k")
      refute String.contains?(result_str, "Ally Savings")
      refute String.contains?(result_str, "Chase Checking")
    end

    test "balances become weights", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_accounts", %{})
      content = parse_content(result)

      accounts = content["accounts"]

      # Should have weights that sum to ~1.0 (allow for rounding)
      weights = Enum.map(accounts, & &1["weight"])
      assert_in_delta Enum.sum(weights), 1.0, 0.02

      # No exact balances visible
      result_str = inspect(result)
      refute String.contains?(result_str, "50000")
      refute String.contains?(result_str, "25000")
    end

    test "portfolio has value tier", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_accounts", %{})
      content = parse_content(result)

      # Portfolio section should have value_tier
      assert Map.has_key?(content, "portfolio")
      portfolio = content["portfolio"]
      assert Map.has_key?(portfolio, "value_tier")
    end

    test "ratios pass through in portfolio summary", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "get_portfolio_summary", %{})
      content = parse_content(result)

      # Privacy filter returns ratios
      assert Map.has_key?(content, "ratios")
    end
  end

  describe "privacy mode: full" do
    setup do
      # Use Process dictionary for thread-safe test isolation
      Process.put(:mcp_privacy_mode, :full)
      :ok
    end

    test "returns all data unfiltered", %{conn: conn, investment: investment} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_accounts", %{})
      content = parse_content(result)

      # Real names should be visible
      result_str = inspect(result)
      assert String.contains?(result_str, "Fidelity 401k")

      # Real IDs should be visible
      ids = Enum.map(content, & &1["id"])
      assert investment.id in ids
    end

    test "exact balances visible", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_accounts", %{})
      content = parse_content(result)

      # Should have balance field with actual values
      balances = Enum.map(content, & &1["balance"])
      assert Enum.any?(balances, &(&1 != nil))
    end
  end

  describe "tool parameters" do
    setup do
      # Use Process dictionary for thread-safe test isolation
      Process.put(:mcp_privacy_mode, :full)
      :ok
    end

    test "list_transactions returns data", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "list_transactions", %{"limit" => 10})
      content = parse_content(result)

      # In full mode, should return a list of transactions
      assert is_list(content)
      assert length(content) > 0
    end
  end

  describe "error handling" do
    test "invalid tool returns proper error", %{conn: conn} do
      {conn, session_id, _} = initialize_mcp(conn)

      result = call_tool(conn, session_id, "nonexistent_tool", %{})

      assert result["error"]
      assert result["error"]["code"]
    end

    test "missing session header still works for initialize", %{conn: conn} do
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

      response = Jason.decode!(conn.resp_body)
      # Initialize should work without session
      assert response["result"]
    end
  end

  describe "performance" do
    @tag :performance
    test "tool calls complete within 200ms", %{conn: conn} do
      # Use Process dictionary for thread-safe test isolation
      Process.put(:mcp_privacy_mode, :anonymized)
      {conn, session_id, _} = initialize_mcp(conn)

      tools = ["list_accounts", "list_transactions", "get_portfolio_summary", "list_symbols"]

      for tool <- tools do
        {time_us, _result} =
          :timer.tc(fn ->
            call_tool(conn, session_id, tool, %{})
          end)

        time_ms = time_us / 1000
        assert time_ms < 200, "#{tool} took #{time_ms}ms, expected < 200ms"
      end
    end
  end

  # Helper functions

  defp create_symbol!(ticker, name, asset_class, price) do
    {:ok, symbol} =
      Ash.create(Symbol, %{
        symbol: ticker,
        name: name,
        asset_class: asset_class,
        data_source: :manual,
        current_price: Decimal.new(price)
      })

    symbol
  end

  defp create_account!(name, type, platform, balance) do
    {:ok, account} =
      Ash.create(Account, %{
        name: name,
        account_type: type,
        platform: platform,
        balance: Decimal.new(balance)
      })

    account
  end

  defp create_transaction!(account, symbol, type, quantity, price, date) do
    total = Decimal.mult(Decimal.new(quantity), Decimal.new(price))

    {:ok, txn} =
      Ash.create(Transaction, %{
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
    session_id = conn |> get_resp_header("mcp-session-id") |> List.first()
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
