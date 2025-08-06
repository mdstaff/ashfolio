defmodule AshfolioWeb.TransactionLive.IndexTest do
  use AshfolioWeb.ConnCase
  import Phoenix.LiveViewTest
  # import Ashfolio.TestFixtures

  describe "index" do
    test "lists all transactions", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/transactions")

      assert html =~ "Transactions"
      assert html =~ "Manage your investment transactions"
    end

    test "shows empty state when no transactions", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/transactions")
      assert html =~ "No transactions yet"
    end

    test "can create new transaction", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/transactions")
      assert index_live |> element("button", "New Transaction") |> render_click()
      assert_patch(index_live, ~p"/transactions")
    end

    test "responsive design elements present", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/transactions")
      assert html =~ "flex-col sm:flex-row"
      assert html =~ "w-full sm:w-auto"
    end
  end
end