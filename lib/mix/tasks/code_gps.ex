defmodule Mix.Tasks.CodeGps do
  @moduledoc """
  Generates an AI-optimized codebase manifest in YAML format.

  Usage:
    mix code_gps
    
  Generates .code-gps.yaml with navigation hints, patterns, and integration opportunities.
  """

  use Mix.Task

  @shortdoc "Generates AI code navigation manifest"

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

    end_time = System.monotonic_time(:millisecond)
    generation_time = end_time - start_time

    # Build manifest data
    manifest_data = %{
      metadata: %{
        version: "2.0",
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
      test_gaps: test_gaps
    }

    # Generate YAML content
    yaml_content = generate_yaml_manifest(manifest_data)

    # Write to file
    File.write!(".code-gps.yaml", yaml_content)

    IO.puts("✅ Code GPS generated: .code-gps.yaml")
    IO.puts("📊 Analyzed #{manifest_data.metadata.files_analyzed} files in #{generation_time}ms")
    IO.puts("🔍 Found #{length(live_views)} LiveViews, #{length(components)} components")
    IO.puts("💡 Generated #{length(suggestions)} integration suggestions")

    manifest_data
  end

  # === ANALYSIS FUNCTIONS ===

  defp analyze_live_views do
    Path.wildcard("lib/**/*_live.ex")
    |> Enum.map(&analyze_live_view_file/1)
    |> Enum.reject(&is_nil/1)
  end

  defp analyze_live_view_file(file) do
    content = File.read!(file)

    case extract_module_name(content) do
      nil ->
        nil

      module_name ->
        %{
          name: module_name |> to_string() |> String.replace("Elixir.", ""),
          file: file,
          mount_line: find_function_line(content, "mount"),
          render_line: find_function_line(content, "render"),
          events: extract_handle_events(content),
          assigns: extract_assigns(content),
          subscriptions: extract_pubsub_subscriptions(content),
          missing_subscriptions: suggest_missing_subscriptions(content)
        }
    end
  end

  defp analyze_components do
    Path.wildcard("lib/**/*components*.ex")
    |> Enum.flat_map(&extract_components_from_file/1)
  end

  defp extract_components_from_file(file) do
    content = File.read!(file)

    # Find component functions (def component_name)
    Regex.scan(~r/def (\w+)\(assigns\) do/, content)
    |> Enum.map(fn [_full, name] ->
      line_num = find_function_line(content, name)
      attrs = extract_component_attrs(content, name)

      %{
        name: name,
        file: file,
        line: line_num,
        attrs: attrs,
        usage_count: count_component_usage(name)
      }
    end)
  end

  defp analyze_tests do
    Path.wildcard("test/**/*_test.exs")
    |> Enum.map(&analyze_test_file/1)
    |> Enum.reject(&is_nil/1)
  end

  defp analyze_test_file(file) do
    content = File.read!(file)

    case extract_module_name(content) do
      nil ->
        nil

      module_name ->
        %{
          name: module_name |> to_string() |> String.replace("Elixir.", ""),
          file: file,
          test_count: count_tests(content),
          describes: extract_describe_blocks(content),
          tested_module: infer_tested_module(module_name)
        }
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

  # === SUGGESTION GENERATION ===

  defp generate_integration_hints(live_views, components) do
    suggestions = []

    # Check for missing expense integration in dashboard
    suggestions =
      suggestions ++ check_expense_dashboard_integration(live_views)

    # Check for missing net worth snapshot functionality
    suggestions =
      suggestions ++ check_net_worth_snapshot_integration(live_views)

    # Check for missing component usage
    suggestions =
      suggestions ++ check_missing_component_usage(live_views, components)

    suggestions
  end

  defp check_expense_dashboard_integration(live_views) do
    dashboard =
      Enum.find(live_views, fn lv ->
        String.contains?(lv.name, "DashboardLive")
      end)

    if dashboard && !Enum.member?(dashboard.subscriptions, "expenses") do
      [
        %{
          name: "add_expense_to_dashboard",
          description: "Dashboard missing expense data integration",
          priority: "high",
          steps: [
            %{
              action: "Add PubSub subscription",
              file: dashboard.file,
              line: dashboard.mount_line + 2,
              code: "Ashfolio.PubSub.subscribe(\"expenses\")"
            },
            %{
              action: "Load expense summary",
              file: dashboard.file,
              after_function: "load_portfolio_data",
              code: "|> load_expense_summary()"
            },
            %{
              action: "Add expense widget",
              file: dashboard.file,
              after_line: dashboard.render_line + 200,
              component: "expense_summary_card"
            }
          ]
        }
      ]
    else
      []
    end
  end

  defp check_net_worth_snapshot_integration(live_views) do
    dashboard =
      Enum.find(live_views, fn lv ->
        String.contains?(lv.name, "DashboardLive")
      end)

    if dashboard && !Enum.member?(dashboard.events, "create_snapshot") do
      [
        %{
          name: "add_manual_snapshot",
          description: "Add manual net worth snapshot button",
          priority: "medium",
          steps: [
            %{
              action: "Add event handler",
              file: dashboard.file,
              after_function: "handle_event",
              code: """
              def handle_event("create_snapshot", _params, socket) do
                %{manual: true}
                |> Ashfolio.Workers.NetWorthSnapshotWorker.new()
                |> Oban.insert()
                
                {:noreply, put_flash(socket, :info, "Creating snapshot...")}
              end
              """
            }
          ]
        }
      ]
    else
      []
    end
  end

  defp check_missing_component_usage(_live_views, _components) do
    # Future: Check if useful components aren't being used
    []
  end

  # === HELPER FUNCTIONS ===

  defp extract_module_name(content) do
    case Regex.run(~r/defmodule\s+([\w\.]+)/, content) do
      [_, name] -> String.to_atom(name)
      _ -> nil
    end
  end

  defp find_function_line(content, func_name) do
    content
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.find_value(fn {line, num} ->
      if Regex.match?(~r/def\s+#{func_name}\s*\(/, line) do
        num
      end
    end)
  end

  defp extract_handle_events(content) do
    Regex.scan(~r/def handle_event\("([^"]+)"/, content)
    |> Enum.map(&List.last/1)
    |> Enum.uniq()
  end

  defp extract_assigns(content) do
    Regex.scan(~r/assign\([^,]+,\s*:([^,\)]+)/, content)
    |> Enum.map(&List.last/1)
    |> Enum.uniq()
    # Limit to avoid noise
    |> Enum.take(10)
  end

  defp extract_pubsub_subscriptions(content) do
    Regex.scan(~r/PubSub\.subscribe\("([^"]+)"/, content)
    |> Enum.map(&List.last/1)
    |> Enum.uniq()
  end

  defp suggest_missing_subscriptions(content) do
    # Suggest common subscriptions that might be missing
    suggested = ["expenses", "net_worth", "accounts", "transactions"]
    current = extract_pubsub_subscriptions(content)

    suggested -- current
  end

  defp extract_component_attrs(content, component_name) do
    # Find attrs for a specific component
    lines = String.split(content, "\n")

    # Find component definition
    start_line =
      Enum.find_index(lines, fn line ->
        Regex.match?(~r/def\s+#{component_name}\s*\(/, line)
      end)

    if start_line do
      # Look backwards for attr definitions
      lines
      |> Enum.slice(max(0, start_line - 10), 10)
      |> Enum.filter(&String.contains?(&1, "attr "))
      |> Enum.map(fn line ->
        case Regex.run(~r/attr\s+:(\w+)/, line) do
          [_, attr] -> attr
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
    else
      []
    end
  end

  defp count_component_usage(component_name) do
    Path.wildcard("lib/**/*.ex")
    |> Enum.map(&File.read!/1)
    |> Enum.map(&length(Regex.scan(~r/<\.#{component_name}/, &1)))
    |> Enum.sum()
  end

  defp count_tests(content) do
    length(Regex.scan(~r/test\s+"/, content))
  end

  defp extract_describe_blocks(content) do
    Regex.scan(~r/describe\s+"([^"]+)"/, content)
    |> Enum.map(&List.last/1)
  end

  defp infer_tested_module(test_module_name) do
    test_module_name
    |> to_string()
    |> String.replace("Test", "")
    |> String.replace("Elixir.", "")
  end

  defp count_analyzed_files do
    Path.wildcard("{lib,test}/**/*.{ex,exs}") |> length()
  end

  # === PATTERN FINDERS ===

  defp find_error_pattern(files) do
    content = files |> Enum.take(5) |> Enum.map(&File.read!/1) |> Enum.join()

    cond do
      String.contains?(content, "ErrorHelpers.put_error_flash") ->
        "ErrorHelpers.put_error_flash"

      String.contains?(content, "put_flash(socket, :error") ->
        "put_flash(socket, :error, message)"

      true ->
        "put_flash/3"
    end
  end

  defp find_currency_pattern(files) do
    content = files |> Enum.take(5) |> Enum.map(&File.read!/1) |> Enum.join()

    cond do
      String.contains?(content, "FormatHelpers.format_currency") ->
        "FormatHelpers.format_currency"

      String.contains?(content, "Money.to_string") ->
        "Money.to_string"

      true ->
        "Decimal formatting"
    end
  end

  defp find_test_setup_pattern(files) do
    test_files = Enum.filter(files, &String.contains?(&1, "test/"))

    if length(test_files) > 0 do
      content = test_files |> Enum.take(3) |> Enum.map(&File.read!/1) |> Enum.join()

      if String.contains?(content, "require Ash.Query") do
        "require Ash.Query; reset account balances in setup"
      else
        "Standard ExUnit setup"
      end
    else
      "No test pattern found"
    end
  end

  defp find_component_pattern(files) do
    content = files |> Enum.take(3) |> Enum.map(&File.read!/1) |> Enum.join()

    if String.contains?(content, "~H\"\"\"") do
      "~H sigil with proper assigns"
    else
      "Phoenix component style"
    end
  end

  defp find_pubsub_pattern(files) do
    content = files |> Enum.take(3) |> Enum.map(&File.read!/1) |> Enum.join()

    if String.contains?(content, "Ashfolio.PubSub") do
      "Ashfolio.PubSub.subscribe/1"
    else
      "Phoenix.PubSub"
    end
  end

  # === YAML GENERATION ===

  defp generate_yaml_manifest(data) do
    """
    # Code GPS v#{data.metadata.version} - #{data.metadata.generation_time_ms}ms | #{length(data.live_views)} LiveViews | #{length(data.components)} Components

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

    # === PATTERNS ===
    error_handling: "#{data.patterns.error_handling}"
    currency_format: "#{data.patterns.currency_formatting}"
    test_setup: "#{data.patterns.test_setup}"

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
        mount: #{lv.mount_line} | render: #{lv.render_line}
        events: #{format_list(lv.events)}
        subscriptions: #{format_list(lv.subscriptions)}
        missing: #{format_list(lv.missing_subscriptions)}
      """
    end)
    |> Enum.join("")
  end

  defp encode_components_with_attrs(components) do
    # Focus on components that are either highly used OR have attrs (actionable)
    components
    |> Enum.filter(fn comp ->
      comp.usage_count >= 3 or
        length(comp.attrs) > 0 or
        String.contains?(comp.name, ["card", "button", "form", "input"])
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
    |> Enum.join("\n")
  end

  defp encode_suggestions_structured(suggestions) do
    suggestions
    |> Enum.map(fn sugg ->
      # Group steps by action type for readability
      subscribe_steps = Enum.filter(sugg.steps, &String.contains?(&1.action, "subscription"))
      load_steps = Enum.filter(sugg.steps, &String.contains?(&1.action, ["Load", "Add event"]))

      render_steps =
        Enum.filter(sugg.steps, &String.contains?(&1.action, ["widget", "Add expense"]))

      steps_summary = []

      steps_summary =
        if length(subscribe_steps) > 0 do
          step = List.first(subscribe_steps)
          steps_summary ++ ["  subscribe: #{step.file}:#{step[:line] || "mount+2"}"]
        else
          steps_summary
        end

      steps_summary =
        if length(load_steps) > 0 do
          step = List.first(load_steps)
          steps_summary ++ ["  load_data: #{step.file}:#{step[:after_function] || "?"}"]
        else
          steps_summary
        end

      steps_summary =
        if length(render_steps) > 0 do
          step = List.first(render_steps)
          steps_summary ++ ["  render: #{step.file}:#{step[:after_line] || "?"}"]
        else
          steps_summary
        end

      """
      #{sugg.name}:
        desc: #{sugg.description}
        priority: #{sugg.priority}
      #{Enum.join(steps_summary, "\n")}
      """
    end)
    |> Enum.join("\n")
  end

  defp format_list([]), do: "[]"
  defp format_list(list) when length(list) <= 3, do: inspect(list)
  defp format_list(list), do: "[#{Enum.take(list, 3) |> Enum.join(", ")}...#{length(list)}]"

  # === NEW v2.0 ENCODERS ===

  defp encode_routes(%{live_routes: routes}) do
    if Enum.empty?(routes) do
      "no routes found"
    else
      routes
      |> Enum.map(fn {path, module, exists?} ->
        status = if exists?, do: "✅", else: "❌"
        "#{path}: #{module} #{status}"
      end)
      |> Enum.join("\n")
    end
  end

  defp encode_dependencies(%{key_deps: deps}) do
    deps
    |> Enum.map(fn {dep, info} ->
      usage_info = if info.usage_count > 0, do: " (#{info.usage_count})", else: ""
      "#{dep}: #{info.status}#{usage_info}"
    end)
    |> Enum.join("\n")
  end

  defp encode_freshness(%{
         recent_files: recent,
         uncommitted_count: uncommitted,
         commits_ahead: ahead
       }) do
    recent_str =
      if length(recent) > 0 do
        "recent: #{inspect(Enum.take(recent, 5))}"
      else
        "recent: []"
      end

    """
    #{recent_str}
    uncommitted: #{uncommitted} files
    commits_ahead: #{ahead}
    """
    |> String.trim()
  end

  defp encode_test_gaps(%{missing_tests: missing, orphaned_tests: orphaned}) do
    missing_str =
      if length(missing) > 0 do
        missing
        |> Enum.take(5)
        |> Enum.map(&"#{&1} ❌")
        |> Enum.join("\n")
      else
        "all implementations have tests ✅"
      end

    orphaned_str =
      if length(orphaned) > 0 do
        orphaned
        |> Enum.take(3)
        |> Enum.map(&"#{&1} ⚠️")
        |> Enum.join("\n")
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

  # === NEW v2.0 ANALYSIS FUNCTIONS ===

  defp analyze_routes do
    router_file = "lib/ashfolio_web/router.ex"

    if File.exists?(router_file) do
      content = File.read!(router_file)

      # Extract live routes
      live_routes =
        Regex.scan(~r/live\s+"([^"]+)",\s*(\w+)/, content)
        |> Enum.map(fn [_, path, module] ->
          {path, module, check_live_view_exists(module)}
        end)

      %{
        live_routes: live_routes,
        total_routes: length(live_routes)
      }
    else
      %{live_routes: [], total_routes: 0}
    end
  end

  defp check_live_view_exists(module_name) do
    # Check if the LiveView file actually exists
    # Handle different naming patterns:
    # ExpenseLive.Index -> expense_live/index.ex
    # DashboardLive -> dashboard_live.ex  
    # AccountLive.Show -> account_live/show.ex

    base_name =
      module_name
      # Remove "Live" suffix and anything after
      |> String.replace(~r/Live.*$/, "")
      |> Macro.underscore()

    possible_paths = [
      # Single file pattern: dashboard_live.ex
      "lib/ashfolio_web/live/#{base_name}_live.ex",
      # Directory pattern: expense_live/index.ex
      "lib/ashfolio_web/live/#{base_name}_live/index.ex",
      # Directory pattern: account_live/show.ex, form_component.ex
      "lib/ashfolio_web/live/#{base_name}_live/",
      # Legacy patterns
      "lib/ashfolio_web/live/#{String.downcase(module_name)}.ex",
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
      content = File.read!(mix_file)

      # Extract dependencies
      deps =
        Regex.scan(~r/\{:([^,]+),/, content)
        |> Enum.map(&List.last/1)
        |> Enum.uniq()

      # Check usage for key dependencies
      key_deps = ["contex", "wallaby", "mox", "decimal", "ash"]

      usage_analysis =
        key_deps
        |> Enum.map(fn dep ->
          usage_count = count_dependency_usage(dep)
          installed = dep in deps

          status =
            cond do
              not installed and usage_count > 0 -> "❌"
              installed and usage_count == 0 -> "⚠️"
              installed and usage_count > 0 -> "✅"
              true -> "➖"
            end

          {dep, %{status: status, usage_count: usage_count, installed: installed}}
        end)
        |> Map.new()

      %{
        total_deps: length(deps),
        key_deps: usage_analysis
      }
    else
      %{total_deps: 0, key_deps: %{}}
    end
  end

  defp count_dependency_usage(dep_name) do
    Path.wildcard("lib/**/*.ex")
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
      |> Enum.filter(&String.contains?(&1, ".ex"))
      |> length()

    # Get commits ahead of main
    {ahead_output, _} =
      System.cmd("git", ["rev-list", "--count", "HEAD", "^main"], stderr_to_stdout: true)

    commits_ahead =
      case Integer.parse(String.trim(ahead_output)) do
        {num, _} -> num
        _ -> 0
      end

    %{
      recent_files: recent_files,
      uncommitted_count: uncommitted,
      commits_ahead: commits_ahead
    }
  end

  defp analyze_test_gaps do
    # Find implementation files without tests
    impl_files = Path.wildcard("lib/**/*_live*.ex") ++ Path.wildcard("lib/**/components/*.ex")
    test_files = Path.wildcard("test/**/*_test.exs")

    missing_tests =
      impl_files
      |> Enum.filter(fn impl_file ->
        test_pattern =
          impl_file
          |> String.replace("lib/", "test/")
          |> String.replace(".ex", "_test.exs")

        not File.exists?(test_pattern)
      end)

    # Find test files without implementations
    orphaned_tests =
      test_files
      |> Enum.filter(fn test_file ->
        impl_pattern =
          test_file
          |> String.replace("test/", "lib/")
          |> String.replace("_test.exs", ".ex")

        not File.exists?(impl_pattern)
      end)

    %{
      missing_tests: missing_tests,
      orphaned_tests: orphaned_tests
    }
  end
end
