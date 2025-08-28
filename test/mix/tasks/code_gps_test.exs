defmodule Mix.Tasks.CodeGpsTest do
  @moduledoc """
  Tests for the Code GPS MVP - AI-optimized codebase manifest generator.
  """
  use ExUnit.Case

  alias Mix.Tasks.CodeGps

  @moduletag :skip

  describe "code_gps task" do
    test "generates manifest file" do
      # Clean up any existing manifest
      File.rm(".code-gps.yaml")

      # Run the task
      CodeGps.run([])

      # Verify file was created
      assert File.exists?(".code-gps.yaml")

      # Verify it's valid YAML-like content
      content = File.read!(".code-gps.yaml")
      assert content =~ "# Code GPS"
      assert content =~ "LIVE VIEWS"
      assert content =~ "KEY COMPONENTS"
      assert content =~ "PATTERNS"
      assert content =~ "INTEGRATION OPPORTUNITIES"
    end

    test "analyzes dashboard live view correctly" do
      manifest = CodeGps.run([])

      dashboard_lv =
        Enum.find(manifest.live_views, fn lv -> String.contains?(lv.name, "DashboardLive") end)

      assert dashboard_lv
      assert dashboard_lv.mount_line
      assert dashboard_lv.render_line
      assert "accounts" in dashboard_lv.subscriptions
      # Dashboard now has expenses subscription added in v0.3.1
      assert "expenses" in dashboard_lv.subscriptions
    end

    test "generates integration suggestions" do
      manifest = CodeGps.run([])

      assert length(manifest.suggestions) > 0

      # Now that dashboard has expenses, it suggests net worth snapshot instead
      snapshot_suggestion =
        Enum.find(manifest.suggestions, fn s -> s.name == "add_manual_snapshot" end)

      assert snapshot_suggestion
      assert snapshot_suggestion.description =~ "snapshot"
      assert length(snapshot_suggestion.steps) > 0
    end

    test "performance is under 5 seconds" do
      start_time = System.monotonic_time(:millisecond)

      CodeGps.run([])

      end_time = System.monotonic_time(:millisecond)
      duration = end_time - start_time

      # Should complete in under 5000ms (5 seconds)
      assert duration < 5000
    end

    test "route detection finds existing LiveView files correctly" do
      manifest = CodeGps.run([])

      # Test that routes find their corresponding LiveView implementations
      routes = manifest.routes.live_routes

      # ExpenseLive routes should show as existing (✅) since files exist at:
      # - lib/ashfolio_web/live/expense_live/index.ex
      # - lib/ashfolio_web/live/expense_live/form_component.ex
      expense_routes =
        Enum.filter(routes, fn {path, _module, _exists} ->
          String.contains?(path, "expense")
        end)

      assert length(expense_routes) > 0, "Should find expense routes in router"

      # At least one expense route should be marked as existing
      {_, _, expense_exists} = List.first(expense_routes)
      assert expense_exists == true, "ExpenseLive files exist but route detection shows ❌"

      # Dashboard route should definitely exist
      dashboard_route =
        Enum.find(routes, fn {path, _module, _exists} ->
          path == "/"
        end)

      assert dashboard_route != nil, "Should find dashboard route"
      {_, _, dashboard_exists} = dashboard_route
      assert dashboard_exists == true, "DashboardLive should be found"
    end
  end
end
