defmodule Mix.Tasks.CodeGps do
  @shortdoc "Generates AI code navigation manifest"

  @moduledoc """
  Generates an AI-optimized codebase manifest in YAML format.

  Usage:
    mix code_gps

  Generates .code-gps.yaml with navigation hints, patterns, and integration opportunities.
  """

  use Mix.Task

  alias Mix.Tasks.CodeGps.AstParser
  alias Mix.Tasks.CodeGps.PatternDetector

  def run(_args) do
    Mix.Task.run("compile")

    IO.puts("🧭 Analyzing codebase structure...")

    start_time = System.monotonic_time(:millisecond)

    # Gather data
    live_views = analyze_live_views()
    components = analyze_components()
    tests = analyze_tests()
    modules = analyze_modules()
    patterns = extract_patterns()
    suggestions = generate_integration_hints(live_views, components)
    routes = analyze_routes()
    dependencies = analyze_dependencies()
    freshness = analyze_git_freshness()
    test_gaps = analyze_test_gaps()

    # Always run code quality analysis
    code_quality = analyze_code_quality()

    end_time = System.monotonic_time(:millisecond)
    generation_time = end_time - start_time

    # Build manifest data
    manifest_data = %{
      metadata: %{
        version: "3.1-final",
        generated_at: DateTime.utc_now(),
        files_analyzed: count_analyzed_files(),
        generation_time_ms: generation_time
      },
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

    # Generate YAML content
    yaml_content = generate_yaml_manifest(manifest_data)

    # Write to file
    File.write!(".code-gps.yaml", yaml_content)

    IO.puts("✅ Code GPS generated: .code-gps.yaml (#{generation_time}ms)")

    IO.puts(
      "📊 Found #{length(live_views)} LiveViews, #{length(components)} components, #{modules.summary.total_modules} modules, #{length(suggestions)} suggestions"
    )

    manifest_data
  end

  # === ANALYSIS FUNCTIONS (AST-BASED) ===

  defp analyze_live_views do
    "lib/**/*_live.ex"
    |> Path.wildcard()
    |> Enum.map(&analyze_live_view_file/1)
    |> Enum.reject(&is_nil/1)
  end

  defp analyze_live_view_file(file) do
    content = File.read!(file)

    case AstParser.parse_content(content) do
      {:ok, ast} ->
        module_name = extract_module_name_ast(ast)

        %{
          name: module_name,
          file: file,
          mount_line: find_function_line_ast(ast, :mount, 3) || find_function_line_regex(content, :mount, 3),
          render_line: find_function_line_ast(ast, :render, 1) || find_function_line_regex(content, :render, 1),
          events: extract_handle_events_ast(ast),
          assigns: extract_assigns_ast(ast),
          subscriptions: extract_pubsub_subscriptions_ast(ast),
          missing_subscriptions: suggest_missing_subscriptions(ast)
        }

      _ ->
        nil
    end
  end

  defp analyze_components do
    "lib/**/*components*.ex"
    |> Path.wildcard()
    |> Enum.flat_map(&extract_components_from_file/1)
  end

  defp extract_components_from_file(file) do
    content = File.read!(file)

    case AstParser.parse_content(content) do
      {:ok, ast} ->
        AstParser.collect_nodes(ast, fn
          # def component(assigns) do ... end
          {:def, meta, [{name, _, [_assigns]}, _body]} ->
            %{
              name: name,
              file: file,
              line: meta[:line],
              attrs: extract_component_attrs_ast(ast),
              usage_count: count_component_usage(name)
            }

          # def component(assigns) when is_map(assigns) do ... end
          {:def, meta, [{:when, _, [{name, _, [_assigns]}, _guard]}, _body]} ->
            %{
              name: name,
              file: file,
              line: meta[:line],
              attrs: extract_component_attrs_ast(ast),
              usage_count: count_component_usage(name)
            }

          _ ->
            nil
        end)

      _ ->
        []
    end
  end

  defp analyze_tests do
    test_files = Path.wildcard("test/**/*_test.exs")

    test_analysis =
      test_files
      |> Enum.map(&analyze_test_file/1)
      |> Enum.reject(&is_nil/1)

    # Build summary statistics
    total_tests = test_analysis |> Enum.map(& &1.test_count) |> Enum.sum()
    total_test_modules = length(test_analysis)
    avg_tests_per_module = if total_test_modules > 0, do: Float.round(total_tests / total_test_modules, 1), else: 0.0

    # Find largest test modules
    largest_test_modules =
      test_analysis
      |> Enum.sort_by(& &1.test_count, :desc)
      |> Enum.take(10)

    %{
      test_modules: test_analysis,
      summary: %{
        total_test_modules: total_test_modules,
        total_tests: total_tests,
        average_tests_per_module: avg_tests_per_module
      },
      largest_test_modules: largest_test_modules
    }
  end

  defp analyze_test_file(file) do
    content = File.read!(file)

    case AstParser.parse_content(content) do
      {:ok, ast} ->
        module_name = extract_module_name_ast(ast)
        # Use regex as it's more accurate
        test_count = count_tests_regex_fallback(content)
        describes = extract_describe_blocks_ast(ast)

        %{
          name: module_name,
          file: file,
          test_count: test_count,
          describes: describes,
          describe_count: length(describes),
          tested_module: infer_tested_module(module_name),
          assertion_count: count_assertions_in_content(content),
          setup_blocks: count_setup_blocks_ast(ast)
        }

      _ ->
        # Fallback analysis for test files that fail AST parsing
        test_count = count_tests_regex_fallback(content)
        assertion_count = count_assertions_in_content(content)

        %{
          name: file |> Path.basename(".exs") |> Macro.camelize(),
          file: file,
          test_count: test_count,
          describes: [],
          describe_count: 0,
          tested_module: "",
          assertion_count: assertion_count,
          setup_blocks: 0
        }
    end
  end

  defp analyze_modules do
    # Analyze both lib and test files for complete picture
    (Path.wildcard("lib/**/*.ex") ++ Path.wildcard("test/**/*.exs"))
    |> Enum.map(&analyze_module_file/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1.total_functions, :desc)
    |> build_module_summary()
  end

  defp analyze_module_file(file) do
    content = File.read!(file)

    case AstParser.parse_content(content) do
      {:ok, ast} ->
        module_name = extract_module_name_ast(ast)
        function_counts = count_functions_ast(ast)

        %{
          name: module_name || Path.basename(file, ".ex"),
          file: file,
          total_functions: function_counts.total,
          public_functions: function_counts.public,
          private_functions: function_counts.private,
          type: if(String.contains?(file, "test/"), do: :test, else: :lib)
        }

      {:error, _} ->
        # Fallback to basic analysis if AST parsing fails
        IO.warn("AST parsing failed for #{file}, using fallback analysis")

        function_count = count_functions_regex_fallback(content)

        %{
          name: file |> Path.basename(".ex") |> Macro.camelize(),
          file: file,
          total_functions: function_count,
          public_functions: function_count,
          private_functions: 0,
          type: if(String.contains?(file, "test/"), do: :test, else: :lib)
        }
    end
  end

  defp count_functions_ast(ast) do
    functions =
      AstParser.collect_nodes(ast, fn
        {:def, _, [{_name, _, args}, _]} when is_list(args) -> {:public, 1}
        {:defp, _, [{_name, _, args}, _]} when is_list(args) -> {:private, 1}
        _ -> nil
      end)

    public_count = functions |> Enum.filter(&match?({:public, _}, &1)) |> length()
    private_count = functions |> Enum.filter(&match?({:private, _}, &1)) |> length()

    %{
      total: public_count + private_count,
      public: public_count,
      private: private_count
    }
  end

  defp build_module_summary(modules) do
    lib_modules = Enum.filter(modules, &(&1.type == :lib))
    test_modules = Enum.filter(modules, &(&1.type == :test))

    total_modules = length(modules)
    total_functions = modules |> Enum.map(& &1.total_functions) |> Enum.sum()
    total_public = modules |> Enum.map(& &1.public_functions) |> Enum.sum()
    total_private = modules |> Enum.map(& &1.private_functions) |> Enum.sum()

    lib_functions = lib_modules |> Enum.map(& &1.total_functions) |> Enum.sum()
    test_functions = test_modules |> Enum.map(& &1.total_functions) |> Enum.sum()

    avg_functions = if total_modules > 0, do: Float.round(total_functions / total_modules, 1), else: 0.0

    complex_modules = modules |> Enum.filter(&(&1.total_functions > 30)) |> length()

    # Check for any modules with 0 functions (potential parsing issues)
    empty_modules = modules |> Enum.filter(&(&1.total_functions == 0)) |> length()

    top_20_modules = Enum.take(modules, 20)

    %{
      top_modules: top_20_modules,
      summary: %{
        total_modules: total_modules,
        lib_modules: length(lib_modules),
        test_modules: length(test_modules),
        total_functions: total_functions,
        lib_functions: lib_functions,
        test_functions: test_functions,
        total_public_functions: total_public,
        total_private_functions: total_private,
        average_functions_per_module: avg_functions,
        complex_modules_count: complex_modules,
        empty_modules_count: empty_modules
      }
    }
  end

  # === AST HELPER FUNCTIONS ===

  defp extract_module_name_ast(ast) do
    AstParser.find_node(ast, fn
      {:defmodule, _, [name, _]} -> Macro.to_string(name)
      _ -> false
    end)
  end

  defp find_function_line_ast(ast, fun_name, arity) do
    AstParser.find_function_line(ast, fun_name, arity)
  end

  defp extract_handle_events_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {:def, _, [{:handle_event, _, [event, _, _]}, _]} when is_binary(event) -> event
      _ -> nil
    end)
    |> Enum.uniq()
  end

  defp extract_assigns_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {{:., _, [{:assign, _, _}, _]}, _, [_, key]} when is_atom(key) -> Atom.to_string(key)
      {{:., _, [:assign, _]}, _, [_, key, _]} when is_atom(key) -> Atom.to_string(key)
      _ -> nil
    end)
    |> Enum.uniq()
    |> Enum.take(10)
  end

  defp extract_pubsub_subscriptions_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {{:., _, [{:__aliases__, _, [:Ashfolio, :PubSub]}, :subscribe]}, _, [topic]}
      when is_binary(topic) ->
        topic

      _ ->
        nil
    end)
    |> Enum.uniq()
  end

  # Regex fallback for function line detection
  defp find_function_line_regex(content, fun_name, _arity) do
    # Create pattern like "def mount(" for mount/3
    pattern = ~r/^\s*def\s+#{fun_name}\s*\(/m

    content
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.find(fn {line, _index} -> Regex.match?(pattern, line) end)
    |> case do
      {_line, index} -> index
      nil -> nil
    end
  end

  defp suggest_missing_subscriptions(ast) do
    suggested = ["expenses", "net_worth", "accounts", "transactions"]
    current = extract_pubsub_subscriptions_ast(ast)
    suggested -- current
  end

  defp extract_component_attrs_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {:attr, _, [{name, _, _}, _]} -> Atom.to_string(name)
      _ -> nil
    end)
    |> Enum.uniq()
  end

  defp count_component_usage(component_name) do
    "lib/**/*.ex"
    |> Path.wildcard()
    |> Enum.map(&File.read!/1)
    |> Enum.map(&length(Regex.scan(~r/<.#{component_name}/, &1)))
    |> Enum.sum()
  end

  defp extract_describe_blocks_ast(ast) do
    AstParser.collect_nodes(ast, fn
      {:describe, _, [description, _]} when is_binary(description) -> description
      _ -> nil
    end)
  end

  defp infer_tested_module(test_module_name) do
    if test_module_name do
      test_module_name
      |> to_string()
      |> String.replace("Test", "")
      |> String.replace("Elixir.", "")
    else
      ""
    end
  end

  # === PATTERN EXTRACTION ===

  defp extract_patterns do
    PatternDetector.extract_patterns()
  end

  # === SUGGESTION GENERATION (RULE-BASED) ===

  defp generate_integration_hints(live_views, components) do
    PatternDetector.generate_integration_hints(live_views, components)
  end

  defp count_analyzed_files do
    "{lib,test}/**/*.{ex,exs}" |> Path.wildcard() |> length()
  end

  # === YAML GENERATION ===

  defp generate_yaml_manifest(data) do
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

  # === STRUCTURED ENCODERS ===

  defp encode_live_views_structured(live_views) do
    live_views
    |> Enum.map(fn lv ->
      name = lv.name |> String.replace("AshfolioWeb.", "") |> String.replace("Live", "")

      """
      #{name}:
        file: #{lv.file}
        mount: #{lv.mount_line || "?"} | render: #{lv.render_line || "?"}
        events: #{format_list(lv.events)}
        subscriptions: #{format_list(lv.subscriptions)}
        missing: #{format_list(lv.missing_subscriptions)}
      """
    end)
    |> Enum.map_join("", & &1)
  end

  defp encode_components_with_attrs(components) do
    # Focus on components that are either highly used OR have attrs (actionable)
    components
    |> Enum.filter(fn comp ->
      comp.usage_count >= 3 or
        length(comp.attrs) > 0 or
        String.contains?(to_string(comp.name), ["card", "button", "form", "input"])
    end)
    # Limit to most important
    |> Enum.take(8)
    |> Enum.map(fn comp ->
      attrs_str =
        if length(comp.attrs) > 0 do
          " | attrs: #{format_list(comp.attrs)}"
        else
          ""
        end

      "#{comp.name}: #{comp.file}:#{comp.line} (#{comp.usage_count}x)#{attrs_str}"
    end)
    |> Enum.map_join("\n", & &1)
  end

  defp encode_suggestions_structured([]) do
    "# (none)"
  end

  defp encode_suggestions_structured(suggestions) do
    suggestions
    |> Enum.map(&encode_single_suggestion/1)
    |> Enum.map_join("\n", & &1)
  end

  # Helper function to reduce nesting depth
  defp encode_single_suggestion(sugg) do
    # Group steps by action type for readability
    subscribe_steps = Enum.filter(sugg.steps, &String.contains?(&1.action, "subscription"))
    load_steps = Enum.filter(sugg.steps, &String.contains?(&1.action, ["Load", "Add event"]))

    render_steps =
      Enum.filter(sugg.steps, &String.contains?(&1.action, ["widget", "Add expense"]))

    steps_summary = build_steps_summary(subscribe_steps, load_steps, render_steps)

    """
    #{sugg.name}:
      desc: #{sugg.description}
      priority: #{sugg.priority}
    #{Enum.join(steps_summary, "\n")}
    """
  end

  # Helper function to reduce nesting depth
  defp build_steps_summary(subscribe_steps, load_steps, render_steps) do
    []
    |> add_subscribe_step(subscribe_steps)
    |> add_load_step(load_steps)
    |> add_render_step(render_steps)
  end

  # Helper function to reduce nesting depth
  defp add_subscribe_step(steps_summary, subscribe_steps) do
    if length(subscribe_steps) > 0 do
      step = List.first(subscribe_steps)
      steps_summary ++ ["  subscribe: #{step.file}:#{step[:line] || "mount+2"}"]
    else
      steps_summary
    end
  end

  # Helper function to reduce nesting depth
  defp add_load_step(steps_summary, load_steps) do
    if length(load_steps) > 0 do
      step = List.first(load_steps)
      steps_summary ++ ["  load_data: #{step.file}:#{step[:after_function] || "?"}"]
    else
      steps_summary
    end
  end

  # Helper function to reduce nesting depth
  defp add_render_step(steps_summary, render_steps) do
    if length(render_steps) > 0 do
      step = List.first(render_steps)
      steps_summary ++ ["  render: #{step.file}:#{step[:after_line] || "?"}"]
    else
      steps_summary
    end
  end

  defp format_list([]), do: "[]"
  defp format_list(list) when length(list) <= 3, do: inspect(list)
  defp format_list(list), do: "[#{list |> Enum.take(3) |> Enum.join(", ")}|...#{length(list)} ]"

  # === NEW v2.0 ENCODERS ===

  defp encode_routes(%{live_routes: routes}) do
    if Enum.empty?(routes) do
      "no routes found"
    else
      format_routes(routes)
    end
  end

  defp format_routes(routes) do
    routes
    |> Enum.map(&format_route/1)
    |> Enum.map_join("\n", & &1)
  end

  defp format_route({path, module, exists?}) do
    status = if exists?, do: "✅", else: "❌"
    "#{path}: #{module} #{status}"
  end

  defp encode_dependencies(%{key_deps: deps}) do
    deps
    |> Enum.map(fn {dep, info} ->
      usage_info = if info.usage_count > 0, do: " (#{info.usage_count})", else: ""
      "#{dep}: #{info.status}#{usage_info}"
    end)
    |> Enum.map_join("\n", & &1)
  end

  defp encode_freshness(%{recent_files: recent, uncommitted_count: uncommitted, commits_ahead: ahead}) do
    recent_str =
      if length(recent) > 0 do
        "recent: #{inspect(Enum.take(recent, 5))}"
      else
        "recent: []"
      end

    String.trim("""
    #{recent_str}
    uncommitted: #{uncommitted} files
    commits_ahead: #{ahead}
    """)
  end

  defp encode_test_gaps(%{missing_tests: missing, orphaned_tests: orphaned}) do
    missing_str =
      if length(missing) > 0 do
        missing
        |> Enum.take(5)
        |> Enum.map_join("\n", &"#{&1} ❌")
      else
        "all implementations have tests ✅"
      end

    orphaned_str =
      if length(orphaned) > 0 do
        orphaned
        |> Enum.take(3)
        |> Enum.map_join("\n", &"#{&1} ⚠️")
      else
        ""
      end

    result = "missing_tests:\n#{missing_str}"

    if String.length(orphaned_str) > 0 do
      result <> "\norphaned_tests:\n#{orphaned_str}"
    else
      result
    end
  end

  defp encode_code_quality(%{
         credo_issues: credo_issues,
         dialyzer_warnings: _dialyzer_warnings,
         total_issues: total_issues,
         quality_score: quality_score,
         credo_summary: credo_summary
       }) do
    summary_info =
      if credo_summary do
        "credo_analysis: #{credo_summary.mods_funs} mods/funs, #{credo_summary.files} files (#{credo_summary.analysis_time}s)\n"
      else
        "credo_analysis: completed ✅\n"
      end

    credo_str =
      if length(credo_issues) > 0 do
        "#{summary_info}credo_issues: #{length(credo_issues)} refactoring opportunities\n" <>
          (credo_issues
           |> Enum.take(5)
           |> Enum.map_join("\n", fn issue ->
             "  #{issue.file}:#{issue.line} #{issue.category}: #{issue.message}"
           end))
      else
        "#{summary_info}credo_issues: 0"
      end

    # Skip Dialyzer output for better performance
    dialyzer_str = "dialyzer_analysis: skipped for performance ⚡"

    """
    #{credo_str}

    #{dialyzer_str}

    quality_score: #{quality_score}/100 (#{total_issues} total issues)
    """
  end

  defp encode_test_analysis(%{summary: summary, largest_test_modules: largest}) do
    summary_str = """
    summary:
      total_test_modules: #{summary.total_test_modules}
      total_tests: #{summary.total_tests}
      average_tests_per_module: #{summary.average_tests_per_module}

    top_10_test_modules:
    """

    modules_str =
      Enum.map_join(largest, "\n", fn test_module ->
        name = String.replace(test_module.name || "Unknown", "Elixir.", "")

        "  #{name}: #{test_module.test_count} tests, #{test_module.assertion_count} assertions (#{test_module.describe_count} describes) | #{test_module.file}"
      end)

    String.trim(summary_str <> modules_str)
  end

  defp encode_module_analysis(%{top_modules: top_modules, summary: summary}) do
    summary_str = """
    summary:
      total_modules: #{summary.total_modules} (#{summary.lib_modules} lib, #{summary.test_modules} test)
      total_functions: #{summary.total_functions} (#{summary.lib_functions} lib, #{summary.test_functions} test)
      public/private: #{summary.total_public_functions} public, #{summary.total_private_functions} private
      average_functions_per_module: #{summary.average_functions_per_module}
      complex_modules: #{summary.complex_modules_count} (>30 functions)#{if summary.empty_modules_count > 0, do: "\n      empty_modules: #{summary.empty_modules_count} (potential parsing issues)", else: ""}

    top_20_modules:
    """

    modules_str =
      Enum.map_join(top_modules, "\n", fn module ->
        name = String.replace(module.name || "Unknown", "Elixir.", "")

        "  #{name}: #{module.total_functions} functions (#{module.public_functions} public, #{module.private_functions} private) | #{module.file}"
      end)

    String.trim(summary_str <> modules_str)
  end

  # === NEW v2.0 ANALYSIS FUNCTIONS ===

  defp analyze_routes do
    router_file = "lib/ashfolio_web/router.ex"

    if File.exists?(router_file) do
      content = File.read!(router_file)

      # Extract live routes
      live_routes =
        ~r/live\s+\"([^\"]+)\",\s*(\w+)/
        |> Regex.scan(content)
        |> Enum.map(fn [_, path, module] ->
          {path, module, check_live_view_exists(module)}
        end)

      %{live_routes: live_routes, total_routes: length(live_routes)}
    else
      %{live_routes: [], total_routes: 0}
    end
  end

  defp check_live_view_exists(module_name) do
    # Check if the LiveView file actually exists
    base_name =
      module_name
      |> to_string()
      |> String.split("Live")
      |> List.first()
      |> Macro.underscore()

    possible_paths = [
      # Single file pattern: dashboard_live.ex
      "lib/ashfolio_web/live/#{base_name}_live.ex",
      # Directory pattern: expense_live/index.ex
      "lib/ashfolio_web/live/#{base_name}_live/index.ex",
      # Directory pattern: account_live/show.ex, form_component.ex
      "lib/ashfolio_web/live/#{base_name}_live/",
      # Legacy patterns
      "lib/ashfolio_web/live/#{String.downcase(to_string(module_name))}.ex",
      "lib/ashfolio_web/live/#{Macro.underscore(module_name)}.ex"
    ]

    Enum.any?(possible_paths, fn path ->
      if String.ends_with?(path, "/") do
        # Check if directory exists and has files
        File.exists?(path) and length(Path.wildcard("#{path}*.ex")) > 0
      else
        File.exists?(path)
      end
    end)
  end

  defp analyze_dependencies do
    mix_file = "mix.exs"

    if File.exists?(mix_file) do
      analyze_mix_dependencies(mix_file)
    else
      %{key_deps: %{}}
    end
  end

  defp analyze_mix_dependencies(mix_file) do
    content = File.read!(mix_file)

    case AstParser.parse_content(content) do
      {:ok, ast} ->
        deps = extract_dependencies_from_mix_ast(ast)
        key_deps = ["contex", "mox", "decimal", "ash"]
        usage_analysis = Map.new(key_deps, &analyze_dependency(&1, deps))
        %{key_deps: usage_analysis}

      _ ->
        %{key_deps: %{}}
    end
  end

  defp extract_dependencies_from_mix_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {:defp, _, [{:deps, _, []}, [do: deps_list]]} ->
        Enum.map(deps_list, fn
          {dep_name, _, _} -> Atom.to_string(dep_name)
          {dep_name, _} -> Atom.to_string(dep_name)
        end)

      _ ->
        nil
    end)
    |> List.first()
    |> case do
      nil -> []
      deps when is_list(deps) -> Enum.uniq(deps)
      _ -> []
    end
  end

  defp analyze_dependency(dep, deps) do
    usage_count = count_dependency_usage(dep)
    installed = dep in deps
    status = get_dependency_status(installed, usage_count)

    {dep, %{status: status, usage_count: usage_count, installed: installed}}
  end

  defp get_dependency_status(installed, usage_count) do
    cond do
      not installed and usage_count > 0 -> "❌"
      installed and usage_count == 0 -> "⚠️"
      installed and usage_count > 0 -> "✅"
      true -> "➖"
    end
  end

  defp count_dependency_usage(dep_name) do
    "lib/**/*.ex"
    |> Path.wildcard()
    |> Enum.map(&File.read!/1)
    |> Enum.map(&length(Regex.scan(~r/#{dep_name}/i, &1)))
    |> Enum.sum()
  end

  # Fallback function counting using regex when AST parsing fails
  defp count_functions_regex_fallback(content) do
    def_pattern = ~r/^\s*def\s+[a-zA-Z_][a-zA-Z0-9_]*[\s\(]/m
    defp_pattern = ~r/^\s*defp\s+[a-zA-Z_][a-zA-Z0-9_]*[\s\(]/m

    def_count = length(Regex.scan(def_pattern, content))
    defp_count = length(Regex.scan(defp_pattern, content))

    def_count + defp_count
  end

  # Test analysis helper functions
  defp count_tests_regex_fallback(content) do
    test_pattern = ~r/^\s*test\s+/m
    length(Regex.scan(test_pattern, content))
  end

  defp count_assertions_in_content(content) do
    # Count common assertion patterns
    patterns = [
      ~r/assert\s+/,
      ~r/assert_/,
      ~r/refute\s+/,
      ~r/refute_/,
      ~r/assert_in_delta/,
      ~r/assert_receive/
    ]

    Enum.reduce(patterns, 0, fn pattern, acc ->
      acc + length(Regex.scan(pattern, content))
    end)
  end

  defp count_setup_blocks_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {:setup, _, _} -> true
      _ -> nil
    end)
    |> length()
  end

  defp analyze_git_freshness do
    # Get recent file changes
    {recent_output, 0} =
      System.cmd("git", ["log", "--name-only", "--since=7 days ago", "--pretty=format:"])

    recent_files =
      recent_output
      |> String.split("\n")
      |> Enum.filter(&(String.contains?(&1, ".ex") and String.length(&1) > 0))
      |> Enum.uniq()
      |> Enum.take(10)

    # Get git status
    {status_output, _} = System.cmd("git", ["status", "--porcelain"])

    uncommitted =
      status_output
      |> String.split("\n")
      |> Enum.filter(&(String.contains?(&1, ".ex") and !String.starts_with?(&1, "##")))
      |> length()

    # Get commits ahead of main
    {ahead_output, _} =
      System.cmd("git", ["rev-list", "--count", "HEAD", "^main"], stderr_to_stdout: true)

    commits_ahead =
      case Integer.parse(String.trim(ahead_output)) do
        {num, _} -> num
        _ -> 0
      end

    %{recent_files: recent_files, uncommitted_count: uncommitted, commits_ahead: commits_ahead}
  end

  defp analyze_test_gaps do
    # Find implementation files without tests
    impl_files = Path.wildcard("lib/**/*_live*.ex") ++ Path.wildcard("lib/**/components/*.ex")
    test_files = Path.wildcard("test/**/*_test.exs")

    missing_tests =
      Enum.filter(impl_files, fn impl_file ->
        test_pattern =
          impl_file
          |> String.replace("lib/", "test/")
          |> String.replace(".ex", "_test.exs")

        not File.exists?(test_pattern)
      end)

    # Find test files without implementations
    orphaned_tests =
      Enum.filter(test_files, fn test_file ->
        impl_pattern =
          test_file
          |> String.replace("test/", "lib/")
          |> String.replace("_test.exs", ".ex")

        not File.exists?(impl_pattern)
      end)

    %{missing_tests: missing_tests, orphaned_tests: orphaned_tests}
  end

  defp analyze_code_quality do
    {credo_issues, credo_summary} = run_credo_analysis()

    %{
      credo_issues: credo_issues,
      dialyzer_warnings: [],
      total_issues: length(credo_issues),
      quality_score: calculate_quality_score(credo_issues, []),
      credo_summary: credo_summary
    }
  end

  defp run_credo_analysis do
    # Get JSON output for detailed issues
    {json_output, _} =
      System.cmd("mix", ["credo", "--format", "json", "--strict"], stderr_to_stdout: true)

    # Get text output for summary statistics
    {text_output, _} = System.cmd("mix", ["credo", "--strict"], stderr_to_stdout: true)

    # Parse both outputs
    {issues, _} = parse_credo_output(json_output)
    summary = extract_credo_summary(text_output)

    {issues, summary}
  rescue
    _ ->
      # Graceful degradation - if Credo fails, continue without it
      {[], nil}
  end

  defp parse_credo_output(output) do
    # Split output to handle mixed JSON + text output
    lines = String.split(output, "\n")

    # Find JSON part (starts with {)
    json_start = Enum.find_index(lines, &String.starts_with?(&1, "{"))

    if json_start do
      json_lines = Enum.drop(lines, json_start)
      json_string = Enum.join(json_lines, "\n")
      parse_json_output(json_string, output)
    else
      {[], nil}
    end
  rescue
    _ -> {[], nil}
  end

  defp parse_json_output(json_string, full_output) do
    case Jason.decode(json_string) do
      {:ok, json_data} ->
        process_credo_json(json_data, full_output)

      {:error, _} ->
        # Try parsing the full output as JSON as fallback
        parse_full_output_as_json(full_output)
    end
  end

  defp process_credo_json(json_data, full_output) do
    issues = Map.get(json_data, "issues", [])
    summary = extract_credo_summary(full_output)

    filtered_issues =
      issues
      |> Enum.filter(&filter_credo_issue/1)
      |> Enum.map(&format_credo_issue/1)
      |> Enum.take(10)

    {filtered_issues, summary}
  end

  defp parse_full_output_as_json(output) do
    case Jason.decode(output) do
      {:ok, json_data} ->
        issues = Map.get(json_data, "issues", [])
        summary = %{mods_funs: "unknown", files: "unknown", analysis_time: "unknown"}

        filtered_issues =
          issues
          |> Enum.filter(&filter_credo_issue/1)
          |> Enum.map(&format_credo_issue/1)
          |> Enum.take(10)

        {filtered_issues, summary}

      _ ->
        {[], nil}
    end
  end

  defp extract_credo_summary(output) do
    # Extract summary from the text output that appears after JSON
    lines = String.split(output, "\n")

    # Look for analysis summary line like:
    # "Analysis took 1.6 seconds (0.1s to load, 1.5s running 54 checks on 223 files)"
    analysis_line = Enum.find(lines, &String.contains?(&1, "Analysis took"))

    # Look for mods/funs line like "2052 mods/funs, found 10 refactoring opportunities"
    summary_line = Enum.find(lines, &String.contains?(&1, "mods/funs"))

    if analysis_line && summary_line do
      # Parse "2052 mods/funs, found 10 refactoring opportunities"
      mods_funs =
        case Regex.run(~r/(\d+) mods\/funs/, summary_line) do
          [_, count] -> count
          _ -> "unknown"
        end

      # Parse "223 files"
      files =
        case Regex.run(~r/(\d+) files/, analysis_line) do
          [_, count] -> count
          _ -> "unknown"
        end

      # Parse analysis time "1.6 seconds"
      time =
        case Regex.run(~r/Analysis took ([\d.]+) seconds/, analysis_line) do
          [_, seconds] -> seconds
          _ -> "unknown"
        end

      %{mods_funs: mods_funs, files: files, analysis_time: time}
    end
  end

  defp filter_credo_issue(issue) do
    filename = Map.get(issue, "filename", "")
    message = Map.get(issue, "message", "")

    # Filter out noise but be less aggressive to catch actual issues
    cond do
      # Only filter @moduledoc issues in test files
      String.contains?(filename, "/test/") and String.contains?(message, "@moduledoc") -> false
      String.contains?(filename, "_test.exs") and String.contains?(message, "@moduledoc") -> false
      # Keep all other issues including complexity and refactoring opportunities
      true -> true
    end
  end

  defp format_credo_issue(issue) do
    %{
      file: Map.get(issue, "filename", "unknown"),
      line: Map.get(issue, "line_no", 0),
      message: Map.get(issue, "message", ""),
      category: Map.get(issue, "category", "unknown")
    }
  end

  defp calculate_quality_score(credo_issues, _dialyzer_warnings) do
    # Simple quality score calculation
    total_issues = length(credo_issues)

    case total_issues do
      0 -> 100
      n when n <= 5 -> 95
      n when n <= 10 -> 85
      n when n <= 20 -> 75
      n when n <= 50 -> 60
      _ -> 40
    end
  end
end
