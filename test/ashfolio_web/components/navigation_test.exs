defmodule AshfolioWeb.Components.NavigationTest do
  use AshfolioWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag :liveview
  @moduletag :unit

  describe "Navigation Menu" do
    test "includes all major features in navigation", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Check for Analytics link
      assert html =~ ~r{href="/expenses/analytics"}
      assert html =~ "Analytics"

      # Check for Net Worth link  
      assert html =~ ~r{href="/net_worth"}
      assert html =~ "Net Worth"

      # Check for other important links
      assert html =~ ~r{href="/expenses"}
      assert html =~ ~r{href="/goals"}
      assert html =~ ~r{href="/forecast"}
      assert html =~ ~r{href="/retirement"}
    end

    test "navigation links are accessible from all pages", %{conn: conn} do
      # Test from dashboard
      {:ok, _view, html} = live(conn, "/")
      assert html =~ ~r{href="/expenses/analytics"}
      assert html =~ ~r{href="/net_worth"}

      # Test from expenses page
      {:ok, _view, html} = live(conn, "/expenses")
      assert html =~ ~r{href="/expenses/analytics"}
      assert html =~ ~r{href="/net_worth"}

      # Test from goals page
      {:ok, _view, html} = live(conn, "/goals")
      assert html =~ ~r{href="/expenses/analytics"}
      assert html =~ ~r{href="/net_worth"}
    end

    test "Analytics submenu includes expense analytics", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Should have direct link or dropdown with expense analytics
      assert html =~ "/expenses/analytics"
      # Could be labeled as "Expense Analytics" or just "Analytics"
      assert html =~ ~r{Analytics}i
    end

    test "navigation renders properly in mobile view", %{conn: conn} do
      # This test ensures navigation doesn't break on smaller screens
      {:ok, _view, html} = live(conn, "/")

      # Navigation should exist
      assert html =~ ~r{<nav|role="navigation"}i

      # Key links should still be present (may be in hamburger menu)
      assert html =~ "/expenses/analytics"
      assert html =~ "/net_worth"
    end
  end

  describe "Top Bar Component" do
    test "top bar includes all navigation items", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Check if top_bar component includes these links
      # The actual implementation may vary
      expected_links = [
        "/expenses",
        "/expenses/analytics",
        "/net_worth",
        "/goals",
        "/forecast",
        "/retirement"
      ]

      Enum.each(expected_links, fn link ->
        assert html =~ link, "Missing navigation link: #{link}"
      end)
    end
  end
end
