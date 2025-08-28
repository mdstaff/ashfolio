defmodule AshfolioWeb.NavigationTest do
  use AshfolioWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag :liveview
  @moduletag :unit
  @moduletag :fast

  describe "navigation routing" do
    test "dashboard route works", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Portfolio Dashboard"
      assert html =~ "Overview of your investment portfolio"
    end

    test "accounts route works", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/accounts")
      assert html =~ "Accounts"
      assert html =~ "Manage your investment and cash accounts"
    end

    test "transactions route works", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/transactions")
      assert html =~ "Transactions"
      assert html =~ "Manage your investment transactions"
    end

    test "navigation links are present in layout", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Check that navigation links are present
      assert html =~ ~s(href="/")
      assert html =~ ~s(href="/accounts")
      assert html =~ ~s(href="/transactions")
      assert html =~ ~s(href="/expenses")

      # Check navigation text
      assert html =~ "Dashboard"
      assert html =~ "Accounts"
      assert html =~ "Transactions"
      assert html =~ "Expenses"
    end

    @tag :failing
    test "financial planning navigation links are present", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # These navigation links should be present but are currently missing
      assert html =~ ~s(href="/goals"), "Goals navigation link is missing"
      assert html =~ ~s(href="/forecast"), "Forecast navigation link is missing"

      # Check navigation text
      assert html =~ "Goals", "Goals text is missing from navigation"
      assert html =~ "Forecast", "Forecast text is missing from navigation"
    end

    test "current page is highlighted in navigation", %{conn: conn} do
      # Test dashboard page - should have active styling
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "text-blue-700 bg-blue-50 border-l-4 border-blue-700"

      # Test accounts page - should have active styling
      {:ok, _view, html} = live(conn, "/accounts")
      assert html =~ "text-blue-700 bg-blue-50"

      # Test transactions page - should have active styling
      {:ok, _view, html} = live(conn, "/transactions")
      assert html =~ "text-blue-700 bg-blue-50"
    end

    test "navigation between pages works", %{conn: conn} do
      # Start on dashboard
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Portfolio Dashboard"

      # Navigate to accounts using direct navigation (nav is in layout, not LiveView)
      {:ok, _view, html} = live(conn, "/accounts")
      assert html =~ "Accounts"

      # Navigate to transactions
      {:ok, _view, html} = live(conn, "/transactions")
      assert html =~ "Transactions"

      # Navigate back to dashboard
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Portfolio Dashboard"
    end

    test "mobile navigation menu works", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Mobile menu is in the layout, not the LiveView
      # Test that the LiveView loads properly and would work with mobile navigation
      assert html =~ "Portfolio Dashboard"

      # Navigation between pages should work on mobile too
      {:ok, _view, html} = live(conn, "/accounts")
      assert html =~ "Accounts"
    end
  end

  describe "route helpers" do
    test "verified routes work correctly" do
      # Test that the ~p sigil works for our routes
      assert ~p"/" == "/"
      assert ~p"/accounts" == "/accounts"
      assert ~p"/transactions" == "/transactions"
    end
  end

  describe "authentication requirements" do
    test "no authentication required for dashboard", %{conn: conn} do
      {:ok, _view, _html} = live(conn, "/")
      # Should not redirect or require authentication
    end

    test "no authentication required for accounts", %{conn: conn} do
      {:ok, _view, _html} = live(conn, "/accounts")
      # Should not redirect or require authentication
    end

    test "no authentication required for transactions", %{conn: conn} do
      {:ok, _view, _html} = live(conn, "/transactions")
      # Should not redirect or require authentication
    end
  end
end
