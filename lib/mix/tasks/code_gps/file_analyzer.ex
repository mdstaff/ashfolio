defmodule Mix.Tasks.CodeGps.FileAnalyzer do
  @moduledoc """
  Handles analysis of Phoenix LiveViews, Components, and Elixir modules.

  Extracted from Mix.Tasks.CodeGps to reduce complexity and improve maintainability.
  """

  alias Mix.Tasks.CodeGps.AstParser

  @doc """
  Analyzes all LiveView files in the project.
  """
  def analyze_live_views do
    "lib/ashfolio_web/live/**/*.ex"
    |> Path.wildcard()
    |> Enum.filter(&is_live_view_file?/1)
    |> Enum.map(&analyze_live_view_file/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Analyzes all component files in the project.
  """
  def analyze_components do
    "lib/**/*components*.ex"
    |> Path.wildcard()
    |> Enum.flat_map(&extract_components_from_file/1)
  end

  @doc """
  Analyzes all modules in the project.
  """
  def analyze_modules do
    lib_files = Path.wildcard("lib/**/*.ex")
    test_files = Path.wildcard("test/**/*.ex")

    (lib_files ++ test_files)
    |> Enum.map(&analyze_module_file/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Builds a summary of module statistics.
  """
  def build_module_summary(modules) do
    lib_modules = Enum.filter(modules, &String.starts_with?(&1.file, "lib/"))
    test_modules = Enum.filter(modules, &String.starts_with?(&1.file, "test/"))

    total_functions = Enum.reduce(modules, 0, &(&2 + &1.total_functions))
    lib_functions = Enum.reduce(lib_modules, 0, &(&2 + &1.total_functions))
    test_functions = Enum.reduce(test_modules, 0, &(&2 + &1.total_functions))

    public_functions = Enum.reduce(modules, 0, &(&2 + &1.public_functions))
    private_functions = total_functions - public_functions

    complex_modules =
      modules
      |> Enum.filter(&(&1.total_functions > 30))
      |> length()

    empty_modules =
      modules
      |> Enum.filter(&(&1.total_functions == 0))
      |> length()

    %{
      total_modules: length(modules),
      lib_modules: length(lib_modules),
      test_modules: length(test_modules),
      total_functions: total_functions,
      lib_functions: lib_functions,
      test_functions: test_functions,
      public_functions: public_functions,
      private_functions: private_functions,
      average_functions_per_module:
        if(length(modules) > 0, do: Float.round(total_functions / length(modules), 1), else: 0),
      complex_modules: complex_modules,
      empty_modules: empty_modules
    }
  end

  @doc """
  Counts total files analyzed across the project.
  """
  def count_analyzed_files do
    lib_count = length(Path.wildcard("lib/**/*.ex"))
    test_count = length(Path.wildcard("test/**/*.ex"))
    lib_count + test_count
  end

  # Private functions for LiveView analysis

  # TODO: rename predicate function
  defp is_live_view_file?(file) do
    content = File.read!(file)
    content =~ "use AshfolioWeb, :live_view"
  end

  defp analyze_live_view_file(file) do
    content = File.read!(file)

    case AstParser.parse_content(content) do
      {:ok, ast} ->
        module_name =
          case extract_module_name_ast(ast) do
            "Unknown" -> extract_module_name_from_content(content)
            name -> name
          end

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
        # Fallback to regex-based analysis if AST parsing fails
        %{
          name: extract_module_name_from_content(content),
          file: file,
          mount_line: find_function_line_regex(content, :mount, 3),
          render_line: find_function_line_regex(content, :render, 1),
          events: [],
          assigns: [],
          subscriptions: [],
          missing_subscriptions: []
        }
    end
  end

  defp extract_module_name_ast(ast) do
    case find_module_name_from_ast(ast) do
      {:ok, name} -> name |> Atom.to_string() |> String.split(".") |> List.last()
      _ -> "Unknown"
    end
  end

  defp extract_module_name_from_content(content) do
    case Regex.run(~r/defmodule\s+([A-Za-z0-9_.]+)/, content) do
      [_, module_name] ->
        module_name
        |> String.split(".")
        |> List.last()

      _ ->
        "Unknown"
    end
  end

  defp find_module_name_from_ast(ast) do
    result =
      AstParser.find_node(ast, fn
        {:defmodule, _, [{:__aliases__, _, module_parts}, _]} ->
          {:ok, Module.concat(module_parts)}

        _ ->
          false
      end)

    case result do
      {:halt, module_name} -> module_name
      _ -> {:error, :not_found}
    end
  end

  defp find_function_line_ast(ast, fun_name, arity) do
    AstParser.find_function_line(ast, fun_name, arity)
  end

  defp extract_handle_events_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {:def, _meta, [{:handle_event, _, [event_name | _]}, _]} when is_binary(event_name) ->
        event_name

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp extract_assigns_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {:assign, _, [_, key | _]} when is_atom(key) -> Atom.to_string(key)
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp extract_pubsub_subscriptions_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {{:., _, [{:__aliases__, _, [:Phoenix, :PubSub]}, :subscribe]}, _, [_, topic]}
      when is_binary(topic) ->
        topic

      {{:., _, [{:__aliases__, _, [:PubSub]}, :subscribe]}, _, [_, topic]}
      when is_binary(topic) ->
        topic

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp find_function_line_regex(content, fun_name, _arity) do
    case Regex.run(~r/^  def #{fun_name}\(/m, content, return: :index) do
      [{start_pos, _}] ->
        content
        |> String.slice(0, start_pos)
        |> String.split("\n")
        |> length()

      _ ->
        nil
    end
  end

  defp suggest_missing_subscriptions(ast) do
    # Simple heuristic: suggest common topics if not present
    existing = extract_pubsub_subscriptions_ast(ast)
    common_topics = ["accounts", "transactions", "net_worth", "expenses", "goals", "prices", "forecasts"]

    common_topics
    |> Enum.reject(&(&1 in existing))
    # Limit suggestions
    |> Enum.take(7)
  end

  # Private functions for Component analysis

  defp extract_components_from_file(file) do
    content = File.read!(file)

    case AstParser.parse_content(content) do
      {:ok, ast} ->
        ast
        |> AstParser.collect_nodes(fn
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
        |> Enum.reject(&is_nil/1)

      _ ->
        []
    end
  end

  defp extract_component_attrs_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {:attr, _, [name | _]} when is_atom(name) -> Atom.to_string(name)
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp count_component_usage(component_name) do
    # Count usage across all .ex and .heex files
    patterns = [
      "lib/**/*.ex",
      "lib/**/*.heex"
    ]

    patterns
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.reduce(0, fn file, acc ->
      content = File.read!(file)
      matches = Regex.scan(~r/<\.#{component_name}[>\s]|#{component_name}\(/i, content)
      acc + length(matches)
    end)
  end

  # Private functions for Module analysis

  defp analyze_module_file(file) do
    content = File.read!(file)

    case AstParser.parse_content(content) do
      {:ok, ast} ->
        {public, private} = count_functions_ast(ast)
        module_name = extract_module_name_ast(ast)

        %{
          name: module_name,
          file: file,
          total_functions: public + private,
          public_functions: public,
          private_functions: private
        }

      _ ->
        nil
    end
  end

  defp count_functions_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {:def, _, [{_name, _, args}, _]} when is_list(args) -> {:public, 1}
      {:defp, _, [{_name, _, args}, _]} when is_list(args) -> {:private, 1}
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce({0, 0}, fn
      {:public, count}, {pub, priv} -> {pub + count, priv}
      {:private, count}, {pub, priv} -> {pub, priv + count}
    end)
  end
end
