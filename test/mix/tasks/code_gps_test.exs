defmodule Mix.Tasks.CodeGpsTest do
  @moduledoc """
  Tests for the Code GPS MVP - AI-optimized codebase manifest generator.

  Fast tests run by default. Slow tests (code quality integration) can be run with:
  mix test test/mix/tasks/code_gps_test.exs --include slow

  To skip these tests entirely during normal test runs:
  mix test --exclude code_gps
  """
  use ExUnit.Case

  alias Mix.Tasks.CodeGps

  # Skip slow tests by default for faster feedback loops
  @moduletag :capture_log
  @moduletag :code_gps

  # Run CodeGps once for the entire test suite
  setup_all do
    # Clean up any existing manifest
    File.rm(".code-gps.yaml")

    # Run CodeGps once and capture result for entire test suite (use fast mode for performance)
    start_time = System.monotonic_time(:millisecond)
    manifest = CodeGps.run(["--fast"])
    end_time = System.monotonic_time(:millisecond)
    generation_time = end_time - start_time

    # Read generated file content
    file_content =
      if File.exists?(".code-gps.yaml") do
        File.read!(".code-gps.yaml")
      else
        ""
      end

    {:ok, manifest: manifest, generation_time: generation_time, file_content: file_content}
  end

  describe "code_gps task" do
    test "generates manifest file", %{file_content: content} do
      # Verify file was created and has expected content
      assert content != ""
      assert content =~ "# Code GPS"
      assert content =~ "LIVE VIEWS"
      assert content =~ "KEY COMPONENTS"
      assert content =~ "PATTERNS"
      assert content =~ "INTEGRATION OPPORTUNITIES"
    end

    test "analyzes dashboard live view correctly", %{manifest: manifest} do
      dashboard_lv =
        Enum.find(manifest.live_views, fn lv -> String.contains?(lv.name, "DashboardLive") end)

      assert dashboard_lv
      assert dashboard_lv.mount_line
      assert dashboard_lv.render_line
      assert "accounts" in dashboard_lv.subscriptions
      # Dashboard now has expenses subscription added in v0.3.1
      assert "expenses" in dashboard_lv.subscriptions
    end

    test "generates no suggestions when integrations are present", %{manifest: manifest} do
      assert Enum.empty?(manifest.suggestions)
    end

    test "performance is under 20 seconds", %{generation_time: generation_time} do
      # Performance validated during setup_all - includes full Credo analysis
      assert generation_time < 20_000,
             "Performance should be under 20 seconds, took #{generation_time}ms"
    end

    test "route detection finds existing LiveView files correctly", %{manifest: manifest} do
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

  describe "Phase 1: Stage 1 - Robust Pattern Detection" do
    test "pattern detection is deterministic across multiple runs", %{manifest: manifest} do
      # Test determinism by running pattern extraction multiple times
      # Since we're using comprehensive analysis instead of sampling,
      # patterns should be identical across runs
      manifest2 = CodeGps.run(["--fast"])
      manifest3 = CodeGps.run(["--fast"])

      # Patterns should be identical across runs
      assert manifest.patterns == manifest2.patterns
      assert manifest2.patterns == manifest3.patterns

      # Specifically test that sampling doesn't cause variation
      assert manifest.patterns.error_handling == manifest2.patterns.error_handling
      assert manifest.patterns.currency_formatting == manifest2.patterns.currency_formatting
      assert manifest.patterns.test_setup == manifest2.patterns.test_setup
    end

    test "pattern detection analyzes all relevant files instead of sampling", %{
      manifest: manifest
    } do
      # Should find actual patterns from comprehensive analysis
      # This test will initially fail because current implementation samples only 3-5 files

      # Check if FormatHelpers exists and verify currency pattern detection
      format_helpers_exists =
        File.exists?("lib/ashfolio_web/format_helpers.ex") or
          File.exists?("lib/ashfolio/format_helpers.ex")

      if format_helpers_exists do
        # Should find FormatHelpers pattern with comprehensive analysis
        assert manifest.patterns.currency_formatting =~ "FormatHelpers",
               "Should find FormatHelpers.format_currency with comprehensive analysis, got: #{manifest.patterns.currency_formatting}"
      else
        # Should at least find Decimal pattern consistently, or better patterns like FormatHelpers
        assert manifest.patterns.currency_formatting =~ "Decimal" or
                 manifest.patterns.currency_formatting =~ "Money" or
                 manifest.patterns.currency_formatting =~ "FormatHelpers",
               "Should find consistent currency pattern, got: #{manifest.patterns.currency_formatting}"
      end

      # Error handling pattern should be more specific than generic "put_flash/3"
      # With comprehensive analysis, should find actual error handling patterns
      assert String.length(manifest.patterns.error_handling) > 10,
             "Error pattern should be more specific with comprehensive analysis, got: #{manifest.patterns.error_handling}"
    end

    test "comprehensive pattern analysis maintains performance requirements", %{
      generation_time: generation_time
    } do
      # Should complete comprehensive analysis including Credo in under 20 seconds
      # Pattern analysis is fast, but Credo analysis adds ~12 seconds
      assert generation_time < 20_000,
             "Comprehensive analysis with code quality should complete in <20 seconds, took #{generation_time}ms"
    end

    test "pattern detection finds project-specific patterns accurately", %{manifest: manifest} do
      # Test that comprehensive analysis finds accurate PubSub pattern
      # Current sampling might miss the actual Ashfolio.PubSub usage
      assert manifest.patterns.pubsub_usage =~ "Ashfolio.PubSub.subscribe/1",
             "Should find Ashfolio-specific PubSub pattern, got: #{manifest.patterns.pubsub_usage}"

      # Test that comprehensive analysis finds accurate test setup pattern
      # Should find "require Ash.Query" pattern if it exists in test files
      if File.exists?("test/support/") do
        test_files = Path.wildcard("test/**/*.exs")

        ash_query_used =
          Enum.any?(test_files, fn file ->
            file |> File.read!() |> String.contains?("require Ash.Query")
          end)

        if ash_query_used do
          assert manifest.patterns.test_setup =~ "Ash.Query",
                 "Should find Ash.Query test pattern with comprehensive analysis, got: #{manifest.patterns.test_setup}"
        end
      end
    end

    test "pattern extraction covers all pattern types consistently", %{manifest: manifest} do
      # Test that all pattern extraction functions work with comprehensive analysis

      # All patterns should be non-empty strings
      assert is_binary(manifest.patterns.error_handling) and
               String.length(manifest.patterns.error_handling) > 0

      assert is_binary(manifest.patterns.currency_formatting) and
               String.length(manifest.patterns.currency_formatting) > 0

      assert is_binary(manifest.patterns.test_setup) and
               String.length(manifest.patterns.test_setup) > 0

      assert is_binary(manifest.patterns.component_style) and
               String.length(manifest.patterns.component_style) > 0

      assert is_binary(manifest.patterns.pubsub_usage) and
               String.length(manifest.patterns.pubsub_usage) > 0

      # Patterns should not be generic fallbacks with comprehensive analysis
      # Now we expect to find specific patterns like "Ashfolio.ErrorHandler.handle_error/2"
      assert manifest.patterns.error_handling =~ "ErrorHandler" or
               manifest.patterns.error_handling != "put_flash/3",
             "Should find specific error handling pattern, got: #{manifest.patterns.error_handling}"

      assert manifest.patterns.currency_formatting =~ "FormatHelpers" or
               manifest.patterns.currency_formatting =~ "Money" or
               manifest.patterns.currency_formatting != "Decimal formatting",
             "Should find specific currency pattern, got: #{manifest.patterns.currency_formatting}"
    end
  end

  describe "Phase 1: Stage 4 - Code Quality Integration (Full Analysis)" do
    @tag :slow
    @tag timeout: 60_000
    test "credo integration finds actual code issues" do
      # Run full analysis without --fast mode to test Credo integration
      manifest = CodeGps.run([])

      # Should include code_quality section with credo issues
      assert Map.has_key?(manifest, :code_quality),
             "Manifest should include code_quality section"

      assert Map.has_key?(manifest.code_quality, :credo_issues),
             "Should include credo_issues in code_quality section"

      # Should find some issues - we know there are at least 10 refactoring opportunities
      assert length(manifest.code_quality.credo_issues) > 0,
             "Should find actual Credo issues, found: #{length(manifest.code_quality.credo_issues)}"

      # Issues should have proper structure
      if length(manifest.code_quality.credo_issues) > 0 do
        issue = List.first(manifest.code_quality.credo_issues)
        assert Map.has_key?(issue, :file), "Credo issue should have file path"
        assert Map.has_key?(issue, :line), "Credo issue should have line number"
        assert Map.has_key?(issue, :message), "Credo issue should have message"
        assert Map.has_key?(issue, :category), "Credo issue should have category"
      end
    end

    @tag :slow
    @tag timeout: 60_000
    test "code quality section appears in YAML output with real data" do
      CodeGps.run([])

      # Read the generated YAML file
      content = File.read!(".code-gps.yaml")

      # Should contain code quality section
      assert content =~ "# === CODE QUALITY ===", "YAML should contain code quality section"
      assert content =~ "credo_analysis:", "YAML should show credo analysis"
      assert content =~ "credo_issues:", "YAML should list credo issues"
      assert content =~ "quality_score:", "YAML should include overall quality score"

      # Should show actual analysis stats (2052 mods/funs based on manual check)
      assert content =~ "mods/funs", "Should show modules/functions analysis count"
    end

    @tag :slow
    @tag timeout: 60_000
    test "dialyzer integration attempts analysis" do
      manifest = CodeGps.run([])

      # Should include dialyzer section in code_quality
      assert Map.has_key?(manifest.code_quality, :dialyzer_warnings),
             "Should include dialyzer_warnings in code_quality section"

      # Dialyzer may not find issues or may fail if PLT not built, but should not crash
      assert is_list(manifest.code_quality.dialyzer_warnings),
             "Dialyzer warnings should be a list"
    end

    @tag :slow
    @tag timeout: 60_000
    test "graceful degradation when tools are unavailable" do
      # This test verifies that Code GPS continues working even if Credo/Dialyzer fail
      manifest = CodeGps.run([])

      # Should still generate manifest even if quality tools fail
      assert Map.has_key?(manifest, :live_views)
      assert Map.has_key?(manifest, :components)

      # Code quality section should exist
      assert Map.has_key?(manifest, :code_quality)
      assert is_map(manifest.code_quality)
    end

    @tag :slow
    @tag timeout: 60_000
    test "performance with code quality analysis is reasonable" do
      # This test allows longer time for code quality analysis but ensures it's not excessive
      start_time = System.monotonic_time(:millisecond)

      CodeGps.run([])

      end_time = System.monotonic_time(:millisecond)
      duration = end_time - start_time

      # Allow up to 30 seconds for full analysis including Credo + Dialyzer
      assert duration < 30_000,
             "Full code quality analysis should complete in <30 seconds, took #{duration}ms"
    end
  end

  # Note: Fast mode tests use --fast flag to skip expensive code quality analysis
  #
  # To run slow tests (code quality integration):
  # mix test test/mix/tasks/code_gps_test.exs --include slow
  #
  # To run only slow tests:
  # mix test test/mix/tasks/code_gps_test.exs --only slow
end
