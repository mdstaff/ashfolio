defmodule Mix.Tasks.CodeGpsTest do
  use ExUnit.Case
  
  @moduledoc """
  Tests for the Code GPS MVP - AI-optimized codebase manifest generator.
  """
  
  describe "code_gps task" do
    test "generates manifest file" do
      # Clean up any existing manifest
      File.rm(".code-gps.yaml")
      
      # Run the task
      Mix.Tasks.CodeGps.run([])
      
      # Verify file was created
      assert File.exists?(".code-gps.yaml")
      
      # Verify it's valid YAML-like content
      content = File.read!(".code-gps.yaml")
      assert content =~ "# Code GPS"
      assert content =~ "LIVE VIEWS"
      assert content =~ "KEY COMPONENTS"
      assert content =~ "PATTERNS"
      assert content =~ "INTEGRATION OPPORTUNITIES"
      
      # Clean up
      File.rm(".code-gps.yaml")
    end
    
    test "analyzes dashboard live view correctly" do
      manifest = Mix.Tasks.CodeGps.run([])
      
      dashboard_lv = 
        manifest.live_views
        |> Enum.find(fn lv -> String.contains?(lv.name, "DashboardLive") end)
      
      assert dashboard_lv != nil
      assert dashboard_lv.mount_line != nil
      assert dashboard_lv.render_line != nil
      assert "accounts" in dashboard_lv.subscriptions
      # Dashboard now has expenses subscription added in v0.3.1
      assert "expenses" in dashboard_lv.subscriptions
      
      # Clean up
      File.rm(".code-gps.yaml")
    end
    
    test "generates integration suggestions" do
      manifest = Mix.Tasks.CodeGps.run([])
      
      assert length(manifest.suggestions) > 0
      
      # Now that dashboard has expenses, it suggests net worth snapshot instead
      snapshot_suggestion = 
        Enum.find(manifest.suggestions, fn s -> s.name == "add_manual_snapshot" end)
      
      assert snapshot_suggestion != nil
      assert snapshot_suggestion.description =~ "snapshot"
      assert length(snapshot_suggestion.steps) > 0
      
      # Clean up
      File.rm(".code-gps.yaml")
    end
    
    test "performance is under 5 seconds" do
      start_time = System.monotonic_time(:millisecond)
      
      Mix.Tasks.CodeGps.run([])
      
      end_time = System.monotonic_time(:millisecond)
      duration = end_time - start_time
      
      # Should complete in under 5000ms (5 seconds)
      assert duration < 5000
      
      # Clean up
      File.rm(".code-gps.yaml")
    end
  end
end