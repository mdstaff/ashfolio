defmodule Mix.Tasks.CodeGps.ReportGenerator do
  @moduledoc """
  Handles generation of YAML reports and structured data output.

  Extracted from Mix.Tasks.CodeGps to reduce complexity and improve maintainability.
  """

  @doc """
  Builds the complete manifest data structure from analysis results.
  """
  def build_manifest_data(analysis_data, generation_time) do
    %{
      metadata: %{
        version: "3.1-final",
        generated_at: DateTime.utc_now(),
        files_analyzed: count_analyzed_files(),
        generation_time_ms: generation_time
      },
      live_views: analysis_data.live_views,
      components: analysis_data.components,
      tests: analysis_data.tests,
      modules: analysis_data.modules,
      patterns: analysis_data.patterns,
      suggestions: analysis_data.suggestions,
      routes: analysis_data.routes,
      dependencies: analysis_data.dependencies,
      freshness: analysis_data.freshness,
      test_gaps: analysis_data.test_gaps,
      code_quality: analysis_data.code_quality
    }
  end

  @doc """
  Generates the complete YAML manifest from data.
  """
  def generate_yaml_manifest(data) do
    """
    # Code GPS v#{data.metadata.version} | #{length(data.live_views)} LiveViews | #{length(data.components)} Components

    # === ROUTES ===
    #{encode_routes(data.routes)}

    # === LIVE VIEWS ===
    #{encode_live_views_structured(data.live_views)}

    # === KEY COMPONENTS ===
    #{encode_components_with_attrs(data.components)}

    # === DEPENDENCIES ===
    #{encode_dependencies(data.dependencies)}

    # === FRESHNESS ===
    #{encode_freshness(data.freshness)}

    # === TEST ANALYSIS ===
    #{encode_test_analysis(data.tests)}

    # === TEST GAPS ===
    #{encode_test_gaps(data.test_gaps)}

    # === MODULE ANALYSIS ===
    #{encode_module_analysis(data.modules)}

    # === CODE QUALITY ===
    #{encode_code_quality(data.code_quality)}

    # === PATTERNS ===
    error_handling: \"#{data.patterns.error_handling}\"
    currency_format: \"#{data.patterns.currency_formatting}\"
    test_setup: \"#{data.patterns.test_setup}\"

    # === INTEGRATION OPPORTUNITIES ===
    #{encode_suggestions_structured(data.suggestions)}
    """
  end

  @doc """
  Writes the manifest to .code-gps.yaml file and prints summary.
  """
  def write_manifest_file(manifest_data, yaml_content) do
    File.write!(".code-gps.yaml", yaml_content)

    generation_time = manifest_data.metadata.generation_time_ms
    live_views = manifest_data.live_views
    components = manifest_data.components
    modules = manifest_data.modules
    suggestions = manifest_data.suggestions

    IO.puts("✅ Code GPS generated: .code-gps.yaml (#{generation_time}ms)")

    IO.puts(
      "📊 Found #{length(live_views)} LiveViews, #{length(components)} components, #{modules.summary.total_modules} modules, #{length(suggestions)} suggestions"
    )
  end

  # Private encoding functions

  defp count_analyzed_files do
    lib_count = length(Path.wildcard("lib/**/*.ex"))
    test_count = length(Path.wildcard("test/**/*.ex"))
    lib_count + test_count
  end

  defp encode_routes(routes) do
    Enum.map_join(routes, "\n", fn {path, info} ->
      status = if info.exists, do: "✅", else: "❌"
      "#{path}: #{info.module} #{status}"
    end)
  end

  defp encode_live_views_structured(live_views) do
    Enum.map_join(live_views, "\n", fn lv ->
      name = lv.name |> String.replace("AshfolioWeb.", "") |> String.replace("Live", "")
      subscriptions = format_list_field(lv.subscriptions, 5)
      missing = format_list_field(lv.missing_subscriptions, 4)

      String.trim("""
      #{name}:
        file: #{lv.file}
        mount: #{lv.mount_line} | render: #{lv.render_line}
        events: #{encode_events(lv.events)}
        subscriptions: #{subscriptions}
        missing: #{missing}
      """)
    end)
  end

  defp encode_components_with_attrs(components) do
    components
    |> Enum.filter(&(&1.usage_count > 0))
    |> Enum.sort_by(& &1.usage_count, :desc)
    |> Enum.take(6)
    |> Enum.map_join("\n", fn comp ->
      "#{comp.name}: #{comp.file}:#{comp.line} (#{comp.usage_count}x)"
    end)
  end

  defp encode_dependencies(deps) do
    Enum.map_join(deps, "\n", fn {name, info} ->
      status = if info.used, do: "❌", else: "❌"
      "#{name}: #{status} (#{info.references})"
    end)
  end

  defp encode_freshness(%{recent_files: recent, uncommitted_files: uncommitted, commits_ahead: ahead}) do
    recent_list = recent |> Enum.take(5) |> format_file_list()
    uncommitted_count = if is_list(uncommitted), do: length(uncommitted), else: uncommitted

    String.trim("""
    recent: #{recent_list}
    uncommitted: #{uncommitted_count} files
    commits_ahead: #{ahead}
    """)
  end

  defp encode_test_analysis(%{summary: summary, largest_test_modules: largest}) do
    top_modules =
      largest
      |> Enum.take(10)
      |> Enum.map_join("\n", fn test ->
        "  #{test.name}: #{test.test_count} tests, #{test.assertion_count} assertions (#{test.describe_count} describes) | #{test.file}"
      end)

    String.trim("""
    summary:
      total_test_modules: #{summary.total_test_modules}
      total_tests: #{summary.total_tests}
      average_tests_per_module: #{summary.average_tests_per_module}

    top_10_test_modules:
    #{top_modules}
    """)
  end

  defp encode_test_gaps(%{missing_tests: missing, orphaned_tests: orphaned}) do
    missing_formatted = missing |> Enum.take(5) |> Enum.map_join("\n", &"#{&1} ❌")
    orphaned_formatted = orphaned |> Enum.take(3) |> Enum.map_join("\n", &"#{&1} ⚠️")

    String.trim("""
    missing_tests:
    #{missing_formatted}
    orphaned_tests:
    #{orphaned_formatted}
    """)
  end

  defp encode_module_analysis(%{modules: modules, summary: summary}) do
    top_modules =
      modules
      |> Enum.take(20)
      |> Enum.map_join("\n", fn mod ->
        "  #{mod.name}: #{mod.total_functions} functions (#{mod.public_functions} public, #{mod.private_functions} private) | #{mod.file}"
      end)

    String.trim("""
    summary:
      total_modules: #{summary.total_modules} (#{summary.lib_modules} lib, #{summary.test_modules} test)
      total_functions: #{summary.total_functions} (#{summary.lib_functions} lib, #{summary.test_functions} test)
      public/private: #{summary.public_functions} public, #{summary.private_functions} private
      average_functions_per_module: #{summary.average_functions_per_module}
      complex_modules: #{summary.complex_modules} (>30 functions)
          empty_modules: #{summary.empty_modules} (potential parsing issues)

    top_20_modules:
    #{top_modules}
    """)
  end

  defp encode_code_quality(%{credo_issues: issues, quality_score: score, credo_summary: summary}) do
    issue_list =
      issues
      |> Enum.take(5)
      |> Enum.map_join("\n", fn issue ->
        "  #{issue.filename}:#{issue.line_no} #{issue.category}: #{issue.message}"
      end)

    String.trim("""
    credo_analysis: #{summary}
    credo_issues: #{length(issues)} #{get_issue_category(issues)}
    #{issue_list}

    dialyzer_analysis: skipped for performance ⚡

    quality_score: #{score}/100 (#{length(issues)} total issues)
    """)
  end

  defp encode_suggestions_structured(suggestions) do
    Enum.map_join(suggestions, "\n\n", fn suggestion ->
      String.trim("""
      #{suggestion.title}:
        desc: #{suggestion.description}
        priority: #{suggestion.priority}
        #{suggestion.action}: #{suggestion.location}
      """)
    end)
  end

  # Helper functions

  defp encode_events([]), do: "[]"

  defp encode_events(events) when length(events) <= 8 do
    inspect(events)
  end

  defp encode_events(events) do
    shown = Enum.take(events, 8)
    remaining = length(events) - 8
    inspect(shown) <> "|...#{remaining} "
  end

  defp format_list_field([], _), do: "[]"

  defp format_list_field(items, limit) when length(items) <= limit do
    inspect(items)
  end

  defp format_list_field(items, limit) do
    shown = Enum.take(items, limit)
    remaining = length(items) - limit
    inspect(shown) <> "|...#{remaining} "
  end

  defp format_file_list(files) do
    case files do
      [] -> "[]"
      files -> files |> Enum.map(&Path.relative_to_cwd/1) |> inspect()
    end
  end

  defp get_issue_category(issues) do
    case issues do
      [] ->
        ""

      _ ->
        primary_category =
          issues
          |> Enum.group_by(& &1.category)
          |> Enum.max_by(fn {_cat, list} -> length(list) end)
          |> elem(0)

        "#{primary_category} opportunities"
    end
  end
end
