defmodule AshfolioWeb.RouterTest do
  use AshfolioWeb.ConnCase

  describe "basic routing" do
    test "GET / routes to DashboardLive", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Portfolio Dashboard"
    end

    test "GET /accounts routes to AccountLive.Index", %{conn: conn} do
      conn = get(conn, "/accounts")
      assert html_response(conn, 200) =~ "Accounts"
    end

    test "GET /transactions routes to TransactionLive.Index", %{conn: conn} do
      conn = get(conn, "/transactions")
      assert html_response(conn, 200) =~ "Transactions"
    end
  end

  describe "route helpers" do
    test "verified routes generate correct paths" do
      # Test that the ~p sigil works correctly
      assert ~p"/" == "/"
      assert ~p"/accounts" == "/accounts"
      assert ~p"/transactions" == "/transactions"
    end
  end

  describe "no authentication required" do
    test "all routes are accessible without authentication", %{conn: conn} do
      # Dashboard
      conn = get(conn, "/")
      assert conn.status == 200

      # Accounts
      conn = get(conn, "/accounts")
      assert conn.status == 200

      # Transactions
      conn = get(conn, "/transactions")
      assert conn.status == 200
    end
  end
end
