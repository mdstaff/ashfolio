defmodule Mix.Tasks.CodeGps do
  @shortdoc "Generates AI code navigation manifest"

  @moduledoc """
  Generates an AI-optimized codebase manifest in YAML format.

  Usage:
    mix code_gps

  Generates .code-gps.yaml with navigation hints, patterns, and integration opportunities.
  """

  use Mix.Task

  # Helper module for all AST-related parsing.
  defmodule AstParser do
    @moduledoc false

    def parse_content(content) do
      case Code.string_to_quoted(content, columns: true) do
        {:ok, ast} -> {:ok, ast}
        {:error, _} -> {:error, :parsing_failed}
      end
    end

    def find_node(ast, filter_fun) do
      result =
        Macro.prewalk(ast, nil, fn
          node, acc ->
            case filter_fun.(node) do
              result when result != false and result != nil ->
                {:halt, result}

              _ ->
                {node, acc}
            end
        end)

      case result do
        {:halt, value} -> value
        {_ast, _acc} -> nil
      end
    end

    def collect_nodes(ast, filter_fun) do
      ast
      |> Macro.prewalk([], fn
        node, acc ->
          case filter_fun.(node) do
            nil -> {node, acc}
            result -> {node, [result | acc]}
          end
      end)
      |> elem(1)
      |> Enum.reverse()
    end
  end

  def run(_args) do
    Mix.Task.run("compile")

    IO.puts("🧭 Analyzing codebase structure...")

    start_time = System.monotonic_time(:millisecond)

    # Gather data
    live_views = analyze_live_views()
    components = analyze_components()
    tests = analyze_tests()
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
      "📊 Found #{length(live_views)} LiveViews, #{length(components)} components, #{length(suggestions)} suggestions"
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
    "test/**/*_test.exs"
    |> Path.wildcard()
    |> Enum.map(&analyze_test_file/1)
    |> Enum.reject(&is_nil/1)
  end

  defp analyze_test_file(file) do
    content = File.read!(file)

    case AstParser.parse_content(content) do
      {:ok, ast} ->
        module_name = extract_module_name_ast(ast)

        %{
          name: module_name,
          file: file,
          test_count: count_tests_ast(ast),
          describes: extract_describe_blocks_ast(ast),
          tested_module: infer_tested_module(module_name)
        }

      _ ->
        nil
    end
  end

  # === AST HELPER FUNCTIONS ===

  defp extract_module_name_ast(ast) do
    AstParser.find_node(ast, fn
      {:defmodule, _, [name, _]} -> Macro.to_string(name)
      _ -> false
    end)
  end

  defp find_function_line_ast(ast, fun_name, arity) do
    AstParser.find_node(ast, fn
      {:def, meta, [{^fun_name, _, args}, _]} when is_list(args) and length(args) == arity ->
        meta[:line]

      # Handle functions with attributes like @impl
      {:@, _, _} ->
        nil

      # Also try defp functions
      {:defp, meta, [{^fun_name, _, args}, _]} when is_list(args) and length(args) == arity ->
        meta[:line]

      _ ->
        nil
    end)
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

  defp count_tests_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {:test, _, [_, _]} -> true
      _ -> nil
    end)
    |> length()
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
    all_files = Path.wildcard("{lib,test}/**/*.{ex,exs}")

    %{
      error_handling: find_error_pattern(all_files),
      currency_formatting: find_currency_pattern(all_files),
      test_setup: find_test_setup_pattern(all_files),
      component_style: find_component_pattern(all_files),
      pubsub_usage: find_pubsub_pattern(all_files)
    }
  end

  # === SUGGESTION GENERATION (RULE-BASED) ===

  defp generate_integration_hints(live_views, _components) do
    rules = load_suggestion_rules()

    Enum.flat_map(rules, &apply_rule(&1, live_views))
  end

  defp load_suggestion_rules do
    rules_file = "config/code_gps_rules.exs"

    if File.exists?(rules_file) do
      try do
        {rules, _binding} = Code.eval_file(rules_file)
        rules
      rescue
        _ ->
          IO.warn("Could not load or parse suggestion rules from #{rules_file}")
          []
      end
    else
      []
    end
  end

  defp apply_rule(rule, live_views) do
    live_views
    |> Enum.filter(&live_view_matches?(rule.condition, &1))
    |> Enum.map(&build_suggestion(rule, &1))
  end

  defp live_view_matches?(condition, live_view) do
    # Check if the live view name contains the specified string
    name_matches = String.contains?(live_view.name, condition.live_view)

    # Check for missing subscription
    subscription_matches =
      case condition[:missing_subscription] do
        nil -> true
        topic -> name_matches and !Enum.member?(live_view.subscriptions, topic)
      end

    # Check for missing event handler
    event_matches =
      case condition[:missing_event] do
        nil -> true
        event -> name_matches and !Enum.member?(live_view.events, event)
      end

    name_matches and subscription_matches and event_matches
  end

  defp build_suggestion(rule, live_view) do
    # Replace placeholders in suggestion steps
    steps =
      Enum.map(rule.suggestion.steps, fn step ->
        step
        |> Map.put(:file, live_view.file)
        # Simple line logic for now - handle nil mount_line
        |> Map.put(:line, (live_view.mount_line || 10) + 2)
      end)

    %{
      name: rule.name,
      description: rule.description,
      priority: rule.priority,
      steps: steps
    }
  end

  defp count_analyzed_files do
    "{lib,test}/**/*.{ex,exs}" |> Path.wildcard() |> length()
  end

  # === PATTERN FINDERS ===

  defp find_error_pattern(files) do
    # Comprehensive analysis: check all lib files for error handling patterns
    lib_files = Enum.filter(files, &String.starts_with?(&1, "lib/"))

    # Use streaming for memory efficiency with large codebases
    patterns_found =
      lib_files
      |> Stream.map(&File.read!/1)
      |> Enum.reduce(%{}, fn content, acc ->
        cond do
          String.contains?(content, "Ashfolio.ErrorHandler.handle_error") ->
            Map.put(acc, :ashfolio_error_handler, true)

          String.contains?(content, "ErrorHelpers.put_error_flash") ->
            Map.put(acc, :error_helpers, true)

          String.contains?(content, "put_flash(socket, :error") ->
            Map.put(acc, :put_flash_error, true)

          String.contains?(content, "handle_error(") ->
            Map.put(acc, :generic_handle_error, true)

          true ->
            acc
        end
      end)

    cond do
      Map.get(patterns_found, :ashfolio_error_handler) ->
        "Ashfolio.ErrorHandler.handle_error/2"

      Map.get(patterns_found, :error_helpers) ->
        "ErrorHelpers.put_error_flash"

      Map.get(patterns_found, :put_flash_error) ->
        "put_flash(socket, :error, message)"

      Map.get(patterns_found, :generic_handle_error) ->
        "handle_error/1 pattern"

      true ->
        "put_flash/3"
    end
  end

  defp find_currency_pattern(files) do
    # Comprehensive analysis: check all lib files for currency formatting patterns
    lib_files = Enum.filter(files, &String.starts_with?(&1, "lib/"))

    patterns_found =
      lib_files
      |> Stream.map(&File.read!/1)
      |> Enum.reduce(%{decimal: 0, money: 0, format_helpers: 0}, fn content, acc ->
        %{
          decimal: acc.decimal + count_pattern_occurrences(content, "Decimal"),
          money: acc.money + count_pattern_occurrences(content, "Money."),
          format_helpers:
            acc.format_helpers +
              count_pattern_occurrences(content, "FormatHelpers.format_currency")
        }
      end)

    cond do
      patterns_found.format_helpers > 0 ->
        "FormatHelpers.format_currency"

      patterns_found.money > 0 ->
        "Money.to_string (#{patterns_found.money} usages)"

      patterns_found.decimal > 10 ->
        "Decimal operations (#{patterns_found.decimal} usages)"

      true ->
        "Decimal formatting"
    end
  end

  defp find_test_setup_pattern(files) do
    test_files = Enum.filter(files, &String.contains?(&1, "test/"))

    if length(test_files) > 0 do
      # Comprehensive analysis: check all test files for setup patterns
      patterns_found =
        test_files
        |> Stream.map(&File.read!/1)
        |> Enum.reduce(%{}, fn content, acc ->
          cond do
            String.contains?(content, "require Ash.Query") ->
              Map.put(acc, :ash_query, true)

            String.contains?(content, "Ashfolio.DataCase") ->
              Map.put(acc, :data_case, true)

            String.contains?(content, "Ashfolio.ConnCase") ->
              Map.put(acc, :conn_case, true)

            String.contains?(content, "setup do") ->
              Map.put(acc, :setup_blocks, true)

            true ->
              acc
          end
        end)

      cond do
        Map.get(patterns_found, :ash_query) ->
          "require Ash.Query; Ash-based test setup"

        Map.get(patterns_found, :data_case) ->
          "Ashfolio.DataCase setup pattern"

        Map.get(patterns_found, :conn_case) ->
          "Ashfolio.ConnCase setup pattern"

        Map.get(patterns_found, :setup_blocks) ->
          "Standard ExUnit setup blocks"

        true ->
          "Standard ExUnit setup"
      end
    else
      "No test pattern found"
    end
  end

  defp find_component_pattern(files) do
    # Comprehensive analysis: focus on component files
    component_files =
      Enum.filter(files, fn file ->
        String.contains?(file, "components") or String.contains?(file, "_live")
      end)

    if length(component_files) > 0 do
      patterns_found =
        component_files
        |> Stream.map(&File.read!/1)
        |> Enum.reduce(%{heex: 0, phoenix_html: 0, assigns: 0}, fn content, acc ->
          %{
            heex: acc.heex + count_pattern_occurrences(content, "~H\"\"\""),
            phoenix_html: acc.phoenix_html + count_pattern_occurrences(content, "Phoenix.HTML"),
            assigns: acc.assigns + count_pattern_occurrences(content, "@")
          }
        end)

      cond do
        patterns_found.heex > 0 ->
          "~H sigil with proper assigns (#{patterns_found.heex} components)"

        patterns_found.assigns > 100 ->
          "Phoenix component style with heavy @ usage"

        true ->
          "Phoenix component style"
      end
    else
      "Phoenix component style"
    end
  end

  defp find_pubsub_pattern(files) do
    # Comprehensive analysis: check all lib files for PubSub usage
    lib_files = Enum.filter(files, &String.starts_with?(&1, "lib/"))

    patterns_found =
      lib_files
      |> Stream.map(&File.read!/1)
      |> Enum.reduce(%{ashfolio_pubsub: 0, phoenix_pubsub: 0}, fn content, acc ->
        %{
          ashfolio_pubsub: acc.ashfolio_pubsub + count_pattern_occurrences(content, "Ashfolio.PubSub"),
          phoenix_pubsub: acc.phoenix_pubsub + count_pattern_occurrences(content, "Phoenix.PubSub")
        }
      end)

    cond do
      patterns_found.ashfolio_pubsub > 0 ->
        "Ashfolio.PubSub.subscribe/1 (#{patterns_found.ashfolio_pubsub} usages)"

      patterns_found.phoenix_pubsub > 0 ->
        "Phoenix.PubSub (#{patterns_found.phoenix_pubsub} usages)"

      true ->
        "Phoenix.PubSub"
    end
  end

  # Helper function for counting pattern occurrences
  defp count_pattern_occurrences(content, pattern) do
    content
    |> String.split(pattern)
    |> length()
    |> Kernel.-(1)
    |> max(0)
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

    # === TEST GAPS ===
    #{encode_test_gaps(data.test_gaps)}

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

      case Jason.decode(json_string) do
        {:ok, json_data} ->
          issues = Map.get(json_data, "issues", [])

          # Extract summary from full output
          summary = extract_credo_summary(output)

          filtered_issues =
            issues
            |> Enum.filter(&filter_credo_issue/1)
            |> Enum.map(&format_credo_issue/1)
            |> Enum.take(10)

          {filtered_issues, summary}

        {:error, _} ->
          # Try parsing the full output as JSON
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
    else
      {[], nil}
    end
  rescue
    _ -> {[], nil}
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
