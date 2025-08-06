defmodule AshfolioWeb.ResponsiveDesignTest do
  use AshfolioWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "responsive design compliance" do
    test "dashboard has mobile-first responsive classes", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/")

      # Check responsive header
      assert html =~ "flex-col sm:flex-row"
      assert html =~ "w-full sm:w-auto"

      # Check responsive table
      assert html =~ "overflow-x-auto"
      assert html =~ "min-w-full"
    end

    test "accounts page has responsive elements", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/accounts")

      # Check responsive layout
      assert html =~ "flex-col sm:flex-row"
      assert html =~ "account-actions"
    end

    test "navigation has accessibility attributes", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/")

      # Check ARIA attributes
      assert html =~ "aria-label"
      assert html =~ "role=\"navigation\""
    end

    test "focus states are properly implemented", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/")

      # Check focus ring classes
      assert html =~ "focus:ring-2"
      assert html =~ "focus:ring-blue-500"
    end
  end
end
