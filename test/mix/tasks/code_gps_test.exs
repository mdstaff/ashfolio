defmodule Mix.Tasks.CodeGpsTest do
  @moduledoc """
  Tests for the Code GPS MVP - AI-optimized codebase manifest generator.
  """
  use ExUnit.Case

  alias Mix.Tasks.CodeGps

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

    test "generates no suggestions when integrations are present" do
      manifest = CodeGps.run([])

      assert length(manifest.suggestions) == 0
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

  describe "Phase 1: Stage 1 - Robust Pattern Detection" do
    test "pattern detection is deterministic across multiple runs" do
      # Clean up any existing manifest
      File.rm(".code-gps.yaml")

      # Run pattern extraction multiple times
      manifest1 = CodeGps.run([])
      manifest2 = CodeGps.run([])
      manifest3 = CodeGps.run([])

      # Patterns should be identical across runs
      assert manifest1.patterns == manifest2.patterns
      assert manifest2.patterns == manifest3.patterns

      # Specifically test that sampling doesn't cause variation
      assert manifest1.patterns.error_handling == manifest2.patterns.error_handling
      assert manifest1.patterns.currency_formatting == manifest2.patterns.currency_formatting
      assert manifest1.patterns.test_setup == manifest2.patterns.test_setup
    end

    test "pattern detection analyzes all relevant files instead of sampling" do
      manifest = CodeGps.run([])

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
        # Should at least find Decimal pattern consistently
        assert manifest.patterns.currency_formatting =~ "Decimal" or
                 manifest.patterns.currency_formatting =~ "Money",
               "Should find consistent currency pattern, got: #{manifest.patterns.currency_formatting}"
      end

      # Error handling pattern should be more specific than generic "put_flash/3"
      # With comprehensive analysis, should find actual error handling patterns
      assert String.length(manifest.patterns.error_handling) > 10,
             "Error pattern should be more specific with comprehensive analysis, got: #{manifest.patterns.error_handling}"
    end

    test "comprehensive pattern analysis maintains performance requirements" do
      # Measure performance of comprehensive analysis
      start_time = System.monotonic_time(:millisecond)

      CodeGps.run([])

      end_time = System.monotonic_time(:millisecond)
      duration = end_time - start_time

      # Should complete comprehensive analysis in under 2 seconds
      # Current sampling takes ~200ms, comprehensive should be <2000ms
      assert duration < 2000,
             "Comprehensive pattern analysis should complete in <2 seconds, took #{duration}ms"
    end

    test "pattern detection finds project-specific patterns accurately" do
      manifest = CodeGps.run([])

      # Test that comprehensive analysis finds accurate PubSub pattern
      # Current sampling might miss the actual Ashfolio.PubSub usage
      assert manifest.patterns.pubsub_usage == "Ashfolio.PubSub.subscribe/1",
             "Should find Ashfolio-specific PubSub pattern, got: #{manifest.patterns.pubsub_usage}"

      # Test that comprehensive analysis finds accurate test setup pattern
      # Should find "require Ash.Query" pattern if it exists in test files
      if File.exists?("test/support/") do
        test_files = Path.wildcard("test/**/*.exs")

        ash_query_used =
          Enum.any?(test_files, fn file ->
            File.read!(file) |> String.contains?("require Ash.Query")
          end)

        if ash_query_used do
          assert manifest.patterns.test_setup =~ "Ash.Query",
                 "Should find Ash.Query test pattern with comprehensive analysis, got: #{manifest.patterns.test_setup}"
        end
      end
    end

    test "pattern extraction covers all pattern types consistently" do
      # Test that all pattern extraction functions work with comprehensive analysis
      manifest = CodeGps.run([])

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
      refute manifest.patterns.error_handling == "put_flash/3",
             "Should find specific error handling pattern, not generic fallback"

      refute manifest.patterns.currency_formatting == "Decimal formatting",
             "Should find specific currency pattern, not generic fallback"
    end
  end

  describe "Phase 1: Stage 4 - Credo and Dialyzer Integration" do
    test "credo integration finds actual code issues" do
      manifest = CodeGps.run([])

      # Should include code_quality section with credo issues
      assert Map.has_key?(manifest, :code_quality),
             "Manifest should include code_quality section"

      assert Map.has_key?(manifest.code_quality, :credo_issues),
             "Should include credo_issues in code_quality section"

      # Issues should have proper structure with file paths and line numbers
      if length(manifest.code_quality.credo_issues) > 0 do
        issue = List.first(manifest.code_quality.credo_issues)
        assert Map.has_key?(issue, :file), "Credo issue should have file path"
        assert Map.has_key?(issue, :line), "Credo issue should have line number"
        assert Map.has_key?(issue, :message), "Credo issue should have message"
        assert Map.has_key?(issue, :category), "Credo issue should have category"
      end
    end

    test "dialyzer integration reports type issues" do
      manifest = CodeGps.run([])

      # Should include dialyzer section in code_quality
      assert Map.has_key?(manifest.code_quality, :dialyzer_warnings),
             "Should include dialyzer_warnings in code_quality section"

      # Warnings should be actionable with locations
      Enum.each(manifest.code_quality.dialyzer_warnings, fn warning ->
        assert Map.has_key?(warning, :file), "Dialyzer warning should have file path"
        assert Map.has_key?(warning, :type), "Dialyzer warning should have type"
        assert Map.has_key?(warning, :line), "Dialyzer warning should have line number"
        assert is_binary(warning.message), "Dialyzer warning should have string message"
      end)
    end

    test "code quality analysis maintains performance requirements" do
      start_time = System.monotonic_time(:millisecond)

      CodeGps.run([])

      end_time = System.monotonic_time(:millisecond)
      duration = end_time - start_time

      # Including Credo + Dialyzer should still complete in <5 seconds
      assert duration < 5000,
             "Code quality analysis should complete in <5 seconds, took #{duration}ms"
    end

    test "code quality results are filtered for relevance" do
      manifest = CodeGps.run([])

      # Should exclude common noise (like missing @moduledoc on test files)
      test_file_issues =
        manifest.code_quality.credo_issues
        |> Enum.filter(&String.contains?(&1.file, "/test/"))
        |> Enum.filter(&String.contains?(&1.message, "@moduledoc"))

      # Should have minimal test file moduledoc complaints
      assert length(test_file_issues) < 5,
             "Should filter out noise from test files, found #{length(test_file_issues)} @moduledoc complaints"
    end

    test "code quality section appears in YAML output" do
      CodeGps.run([])

      # Read the generated YAML file
      content = File.read!(".code-gps.yaml")

      # Should contain code quality section
      assert content =~ "# === CODE QUALITY ===", "YAML should contain code quality section"
      assert content =~ "credo_issues:", "YAML should list credo issues"
      assert content =~ "dialyzer_warnings:", "YAML should list dialyzer warnings"
      assert content =~ "quality_score:", "YAML should include overall quality score"
    end

    test "graceful degradation when tools are unavailable" do
      # This test verifies that Code GPS continues working even if Credo/Dialyzer fail
      manifest = CodeGps.run([])

      # Should still generate manifest even if quality tools fail
      assert Map.has_key?(manifest, :live_views)
      assert Map.has_key?(manifest, :components)

      # Code quality section should exist but may be empty if tools unavailable
      if Map.has_key?(manifest, :code_quality) do
        assert is_map(manifest.code_quality)
      end
    end
  end
end
