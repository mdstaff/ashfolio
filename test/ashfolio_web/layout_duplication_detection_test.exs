defmodule AshfolioWeb.LayoutDuplicationDetectionTest do
  @moduledoc """
  Integration test to detect layout duplication issues that cause duplicate IDs.
  
  This test renders an actual LiveView and checks for duplicate IDs that would
  indicate the root layout is being rendered twice.
  
  Critical IDs to check for duplication:
  - flash-group (from flash components)
  - main-topbar-mobile-menu (from topbar)
  - client-error, server-error (from flash components)
  
  If any of these appear twice, it indicates the layout configuration is wrong.
  """
  use AshfolioWeb.ConnCase
  import Phoenix.LiveViewTest

  @moduletag :integration

  describe "layout duplication detection" do
    test "LiveView rendering should not contain duplicate layout IDs", %{conn: conn} do
      # Render a simple LiveView page to check for duplicates
      {:ok, _view, html} = live(conn, ~p"/")
      
      # Check for duplicate IDs that would indicate root layout duplication
      duplicate_ids = [
        "flash-group",
        "main-topbar-mobile-menu", 
        "client-error",
        "server-error"
      ]
      
      for id <- duplicate_ids do
        count = count_id_occurrences(html, id)
        assert count <= 1, 
          """
          DUPLICATE ID DETECTED: '#{id}' appears #{count} times!
          
          This indicates the root layout is being rendered multiple times.
          
          Check the layout configuration in ashfolio_web.ex:
          - LiveView should use layout: {AshfolioWeb.Layouts, :app}
          - Router should use put_root_layout: {AshfolioWeb.Layouts, :root}
          
          See docs/TESTING_STRATEGY.md for the full fix.
          """
      end
    end

    test "transaction page should not have duplicate layout components", %{conn: conn} do
      # Test a more complex page that had issues
      {:ok, _view, html} = live(conn, ~p"/transactions")
      
      # Count occurrences of key layout elements  
      # Look for the actual topbar component structure
      topbar_count = count_element_occurrences(html, ~r/bg-white shadow-sm border-b border-gray-200/)
      flash_count = count_id_occurrences(html, "flash-group")
      mobile_menu_count = count_id_occurrences(html, "main-topbar-mobile-menu")
      
      assert topbar_count == 1, "Expected 1 topbar, found #{topbar_count}"
      assert flash_count <= 1, "Expected 0-1 flash-group, found #{flash_count}"  
      assert mobile_menu_count <= 1, "Expected 0-1 mobile menu, found #{mobile_menu_count}"
    end

    test "all LiveView routes should render without duplicate IDs", %{conn: conn} do
      # Test key routes to ensure no duplication anywhere
      routes_to_test = [
        ~p"/",
        ~p"/accounts", 
        ~p"/transactions",
        ~p"/categories"
      ]
      
      for route <- routes_to_test do
        {:ok, _view, html} = live(conn, route)
        
        # Quick check for any obviously duplicated content
        # If root layout renders twice, we'd see duplicate navigation, etc.
        nav_count = count_element_occurrences(html, ~r/role="navigation"/i)
        
        # We expect exactly 2 navigation elements: desktop nav + mobile nav
        # If we see 4, it means everything is duplicated
        assert nav_count <= 2, 
          """
          Route #{route} has #{nav_count} navigation elements (expected ≤ 2).
          This suggests layout duplication. Check ashfolio_web.ex layout config.
          """
      end
    end
  end

  # Helper functions for detecting duplicates

  defp count_id_occurrences(html, id) do
    # Count how many times an ID appears in the HTML
    regex = ~r/id="#{Regex.escape(id)}"/i
    Regex.scan(regex, html) |> length()
  end

  defp count_element_occurrences(html, regex) do
    Regex.scan(regex, html) |> length()
  end
end