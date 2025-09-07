defmodule Mix.Tasks.CodeGps do
  @shortdoc "Generates AI code navigation manifest"

  @moduledoc """
  Generates an AI-optimized codebase manifest in YAML format.

  Usage:
    mix code_gps

  Generates .code-gps.yaml with navigation hints, patterns, and integration opportunities.
  """

  use Mix.Task

  alias Mix.Tasks.CodeGps.FileAnalyzer
  alias Mix.Tasks.CodeGps.QualityAnalyzer
  alias Mix.Tasks.CodeGps.ReportGenerator
  alias Mix.Tasks.CodeGps.TestAnalyzer

  def run(_args) do
    Mix.Task.run("compile")

    IO.puts("🧭 Analyzing codebase structure...")

    start_time = System.monotonic_time(:millisecond)

    # Gather data using specialized analyzers
    live_views = FileAnalyzer.analyze_live_views()
    components = FileAnalyzer.analyze_components()
    tests = TestAnalyzer.analyze_tests()
    raw_modules = FileAnalyzer.analyze_modules()

    modules = %{
      modules: Enum.sort_by(raw_modules, & &1.total_functions, :desc),
      summary: FileAnalyzer.build_module_summary(raw_modules)
    }

    patterns = extract_patterns()
    suggestions = generate_integration_hints(live_views, components)
    routes = QualityAnalyzer.analyze_routes()
    dependencies = QualityAnalyzer.analyze_dependencies()
    freshness = QualityAnalyzer.analyze_git_freshness()
    test_gaps = TestAnalyzer.analyze_test_gaps()
    code_quality = QualityAnalyzer.analyze_code_quality()

    end_time = System.monotonic_time(:millisecond)
    generation_time = end_time - start_time

    # Build analysis data structure
    analysis_data = %{
      live_views: live_views,
      components: components,
      tests: tests,
      modules: modules,
      patterns: patterns,
      suggestions: suggestions,
      routes: routes,
      dependencies: dependencies,
      freshness: freshness,
      test_gaps: test_gaps,
      code_quality: code_quality
    }

    # Build manifest and generate report
    manifest_data = ReportGenerator.build_manifest_data(analysis_data, generation_time)

    yaml_content = ReportGenerator.generate_yaml_manifest(manifest_data)
    ReportGenerator.write_manifest_file(manifest_data, yaml_content)

    manifest_data
  end

  # === PATTERN EXTRACTION ===

  defp extract_patterns do
    %{
      error_handling: "Standard put_flash error handling",
      currency_formatting: "Basic decimal formatting",
      test_setup: "ExUnit setup blocks (#{count_setup_blocks()} total)"
    }
  end

  defp count_setup_blocks do
    "test/**/*_test.exs"
    |> Path.wildcard()
    |> Enum.reduce(0, fn file, acc ->
      content = File.read!(file)
      matches = ~r/setup(_all)?\s+do/ |> Regex.scan(content) |> length()
      acc + matches
    end)
  end

  # === INTEGRATION SUGGESTIONS ===

  defp generate_integration_hints(live_views, components) do
    suggestions = []

    # Suggest missing PubSub subscriptions
    suggestions = suggestions ++ suggest_pubsub_subscriptions(live_views)

    # Suggest using popular components
    suggestions = suggestions ++ suggest_component_usage(components)

    # Suggest adding error handling
    suggestions = suggestions ++ suggest_error_handling(live_views)

    # Limit suggestions
    Enum.take(suggestions, 5)
  end

  defp suggest_pubsub_subscriptions(live_views) do
    missing_subs =
      live_views
      |> Enum.flat_map(& &1.missing_subscriptions)
      |> Enum.uniq()

    if length(missing_subs) > 0 do
      [
        %{
          title: "Add PubSub Subscriptions",
          description: "Add missing PubSub subscriptions: #{Enum.join(missing_subs, ", ")}",
          priority: "medium",
          action: "subscribe",
          location: "lib/ashfolio_web/live/example_live.ex:14"
        }
      ]
    else
      []
    end
  end

  defp suggest_component_usage(components) do
    popular_components =
      components
      |> Enum.filter(&(&1.usage_count > 5))
      |> Enum.map(& &1.name)
      |> Enum.take(10)

    if length(popular_components) > 0 do
      [
        %{
          title: "Use Popular Components",
          description: "Consider using frequently used components: #{Enum.join(popular_components, ", ")}",
          priority: "low",
          action: "component",
          location: ""
        }
      ]
    else
      []
    end
  end

  defp suggest_error_handling(live_views) do
    files_without_error_handling =
      live_views
      |> Enum.filter(fn lv ->
        content = File.read!(lv.file)

        not String.contains?(content, "put_flash") and
          not String.contains?(content, "error")
      end)
      |> Enum.map(& &1.file)

    if length(files_without_error_handling) > 0 do
      [
        %{
          title: "Add Error Handling",
          description: "Add error handling to: #{files_without_error_handling |> Enum.take(3) |> Enum.join(", ")}",
          priority: "high",
          action: "error_handling",
          location: ""
        }
      ]
    else
      []
    end
  end
end
