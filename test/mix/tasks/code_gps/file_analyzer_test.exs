defmodule Mix.Tasks.CodeGps.FileAnalyzerTest do
  @moduledoc """
  Tests for FileAnalyzer module, specifically LiveView detection logic.
  """
  use ExUnit.Case

  alias Mix.Tasks.CodeGps.FileAnalyzer

  describe "analyze_live_views/0" do
    test "detects all LiveView files, not just files ending in _live.ex" do
      live_views = FileAnalyzer.analyze_live_views()

      # Should find exactly 18 LiveView modules (not LiveComponents or helpers)
      assert length(live_views) == 18, 
        "Should detect exactly 18 LiveView files in lib/ashfolio_web/live/, found: #{length(live_views)}"

      # Should find DashboardLive (ends in _live.ex)
      dashboard_lv = Enum.find(live_views, &(&1.name == "DashboardLive"))
      assert dashboard_lv, "Should find DashboardLive"

      # Should find TransactionLive.Index (in subdirectory)
      transaction_index = Enum.find(live_views, &(&1.name == "Index" && String.contains?(&1.file, "transaction_live")))
      assert transaction_index, "Should find TransactionLive.Index in subdirectory"
      
      # Should NOT find FormComponent (it's a LiveComponent, not LiveView)
      form_component = Enum.find(live_views, &(&1.name == "FormComponent"))
      refute form_component, "Should not include LiveComponents like FormComponent"
    end

    test "correctly identifies LiveViews vs LiveComponents" do
      # Test with a known LiveView file
      dashboard_file = "lib/ashfolio_web/live/dashboard_live.ex"
      if File.exists?(dashboard_file) do
        content = File.read!(dashboard_file)
        assert content =~ "use AshfolioWeb, :live_view", "Dashboard should be a LiveView"
      end

      # Test with a known LiveComponent file  
      form_component_files = Path.wildcard("lib/ashfolio_web/live/**/form_component.ex")
      if length(form_component_files) > 0 do
        form_file = List.first(form_component_files)
        content = File.read!(form_file)
        assert content =~ "use AshfolioWeb, :live_component", "FormComponent should be a LiveComponent"
      end
    end

    test "extracts correct LiveView properties" do
      live_views = FileAnalyzer.analyze_live_views()
      
      # Find a LiveView with known characteristics
      dashboard_lv = Enum.find(live_views, &(&1.name == "DashboardLive"))
      
      if dashboard_lv do
        assert dashboard_lv.file =~ "dashboard_live.ex"
        assert is_integer(dashboard_lv.mount_line) and dashboard_lv.mount_line > 0
        assert is_list(dashboard_lv.events)
        assert is_list(dashboard_lv.assigns)
        assert is_list(dashboard_lv.subscriptions)
      end
    end
  end

  describe "LiveView detection accuracy" do
    test "compares file pattern vs content analysis" do
      # Current pattern-based approach
      pattern_files = Path.wildcard("lib/**/*_live.ex")
      
      # All files in live directory
      all_live_files = Path.wildcard("lib/ashfolio_web/live/**/*.ex")
      
      # Content-based analysis (what we should be doing)
      actual_live_views = Enum.filter(all_live_files, fn file ->
        content = File.read!(file)
        content =~ "use AshfolioWeb, :live_view"
      end)

      assert length(pattern_files) == 3, "Pattern approach finds exactly 3 files"
      assert length(all_live_files) > 20, "There are more than 20 .ex files in live directory"
      assert length(actual_live_views) > length(pattern_files), 
        "Content analysis should find more LiveViews than pattern matching"
    end
  end
end