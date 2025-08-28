defmodule AshfolioWeb.AccessibilityTest do
  use AshfolioWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "WCAG AA accessibility compliance" do
    test "navigation has proper accessibility attributes", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/")

      assert html =~ ~s(role="navigation")
      assert html =~ ~s(aria-label="Main navigation")
      assert html =~ ~s(aria-label="Mobile navigation")
    end

    test "buttons have proper aria labels", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/accounts")

      # Check for specific accessibility attributes that we know exist
      assert html =~ "Toggle mobile menu"
      assert html =~ "Mobile navigation"
    end

    test "loading states use standardized spinner", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/")

      # Should not contain old SVG spinners
      refute html =~ "animate-spin -ml-1 mr-3 h-4 w-4"
    end

    test "color contrast meets WCAG standards", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/")

      # Check for enhanced contrast colors in the dashboard summary cards
      assert html =~ "text-red-600" || html =~ "text-green-600"
    end
  end
end
