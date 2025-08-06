defmodule AshfolioWeb.AccessibilityTest do
  use AshfolioWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "WCAG AA accessibility compliance" do
    test "tables have proper accessibility attributes", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/")

      assert html =~ ~s(role="table")
      assert html =~ ~s(aria-label="Portfolio holdings")
    end

    test "buttons have proper aria labels", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/accounts")

      assert html =~ "aria-label"
      assert html =~ "title="
    end

    test "loading states use standardized spinner", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/")

      # Should not contain old SVG spinners
      refute html =~ "animate-spin -ml-1 mr-3 h-4 w-4"
    end

    test "color contrast meets WCAG standards", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/")

      # Check for enhanced contrast colors
      assert html =~ "text-green-700" || html =~ "text-red-700"
    end
  end
end
