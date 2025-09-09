defmodule Mix.Tasks.CodeGps.PatternDetector do
  @moduledoc """
  Pattern detection utilities for Code GPS analysis.

  Identifies common patterns and integration opportunities across the codebase.
  """

  alias Mix.Tasks.CodeGps.AstParser

  @doc """
  Extracts all recognized patterns from the codebase.
  """
  def extract_patterns do
    error_patterns = find_error_patterns()
    currency_patterns = find_currency_patterns()
    test_setup_patterns = find_test_setup_patterns()

    %{
      error_handling: summarize_error_patterns(error_patterns),
      currency_formatting: summarize_currency_patterns(currency_patterns),
      test_setup: summarize_test_setup_patterns(test_setup_patterns)
    }
  end

  @doc """
  Finds error handling patterns in a file.
  """
  def find_error_pattern(file_path) do
    with {:ok, content} <- File.read(file_path),
         {:ok, ast} <- AstParser.parse_content(content) do
      patterns = []

      # Check for error handling functions
      patterns =
        if has_handle_error_function?(ast) do
          [{:error_handler, file_path} | patterns]
        else
          patterns
        end

      # Check for changeset error formatting
      patterns =
        if has_changeset_error_formatting?(ast) do
          [{:changeset_errors, file_path} | patterns]
        else
          patterns
        end

      patterns
    else
      _ -> []
    end
  end

  @doc """
  Finds currency formatting patterns in a file.
  """
  def find_currency_pattern(file_path) do
    with {:ok, content} <- File.read(file_path),
         {:ok, ast} <- AstParser.parse_content(content) do
      patterns = []

      # Check for currency formatting functions
      patterns =
        if has_currency_formatting?(ast) do
          [{:currency_formatter, file_path} | patterns]
        else
          patterns
        end

      # Check for decimal operations
      patterns =
        if has_decimal_operations?(ast) do
          [{:decimal_operations, file_path} | patterns]
        else
          patterns
        end

      patterns
    else
      _ -> []
    end
  end

  @doc """
  Finds test setup patterns in a test file.
  """
  def find_test_setup_pattern(file_path) do
    with {:ok, content} <- File.read(file_path),
         {:ok, ast} <- AstParser.parse_content(content) do
      setup_count = AstParser.count_setup_blocks(ast)
      describe_blocks = AstParser.extract_describe_blocks(ast)

      %{
        setup_blocks: setup_count,
        describe_blocks: describe_blocks,
        has_fixtures: has_fixtures?(ast),
        has_mocks: has_mocks?(ast)
      }
    else
      _ -> %{setup_blocks: 0, describe_blocks: [], has_fixtures: false, has_mocks: false}
    end
  end

  @doc """
  Finds component usage patterns.
  """
  def find_component_patterns do
    component_files = Path.wildcard("lib/ashfolio_web/components/**/*.ex")

    component_files
    |> Enum.map(fn file ->
      with {:ok, content} <- File.read(file),
           {:ok, ast} <- AstParser.parse_content(content) do
        %{
          file: file,
          attrs: AstParser.extract_component_attrs(ast),
          has_slot: has_slot_definition?(ast),
          function_count: AstParser.count_functions(ast)
        }
      else
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Finds PubSub usage patterns.
  """
  def find_pubsub_patterns do
    all_files = Path.wildcard("lib/**/*.ex")

    all_files
    |> Enum.flat_map(fn file ->
      with {:ok, content} <- File.read(file),
           {:ok, ast} <- AstParser.parse_content(content) do
        subscriptions = AstParser.extract_pubsub_subscriptions(ast)

        if subscriptions == [] do
          []
        else
          [{file, subscriptions}]
        end
      else
        _ -> []
      end
    end)
    |> Map.new()
  end

  @doc """
  Counts occurrences of a specific pattern.
  """
  def count_pattern_occurrences(pattern_type, codebase_files) do
    Enum.reduce(codebase_files, 0, fn file, acc ->
      count_single_pattern(pattern_type, file, acc)
    end)
  end

  defp count_single_pattern(:error_handling, file, acc) do
    if find_error_pattern(file) == [], do: acc, else: acc + 1
  end

  defp count_single_pattern(:currency_formatting, file, acc) do
    if find_currency_pattern(file) == [], do: acc, else: acc + 1
  end

  defp count_single_pattern(_, _file, acc), do: acc

  @doc """
  Generates integration hints based on detected patterns.
  """
  def generate_integration_hints(live_views, components) do
    hints = []

    # Suggest PubSub subscriptions
    hints = hints ++ suggest_pubsub_integrations(live_views)

    # Suggest component usage (only one general suggestion)
    hints = hints ++ suggest_component_usage(live_views, components)

    # Suggest error handling improvements (only for views without it)
    hints = hints ++ suggest_error_handling(live_views)

    # Deduplicate similar suggestions
    Enum.uniq_by(hints, fn hint -> {hint.name, hint.priority} end)
  end

  # Private helper functions

  defp find_error_patterns do
    "lib/**/*.ex"
    |> Path.wildcard()
    |> Enum.flat_map(&find_error_pattern/1)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
  end

  defp find_currency_patterns do
    "lib/**/*.ex"
    |> Path.wildcard()
    |> Enum.flat_map(&find_currency_pattern/1)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
  end

  defp find_test_setup_patterns do
    "test/**/*_test.exs"
    |> Path.wildcard()
    |> Map.new(&{&1, find_test_setup_pattern(&1)})
  end

  defp has_handle_error_function?(ast) do
    AstParser.find_node(ast, fn
      {:def, _, [{:handle_error, _, _} | _]} -> true
      _ -> nil
    end) != nil
  end

  defp has_changeset_error_formatting?(ast) do
    AstParser.find_node(ast, fn
      {:def, _, [{name, _, _} | _]} when name in [:format_changeset_errors, :traverse_errors] ->
        true

      _ ->
        nil
    end) != nil
  end

  defp has_currency_formatting?(ast) do
    AstParser.find_node(ast, fn
      {:def, _, [{name, _, _} | _]} ->
        if name |> Atom.to_string() |> String.contains?("currency") do
          true
        end

      _ ->
        nil
    end) != nil
  end

  defp has_decimal_operations?(ast) do
    AstParser.find_node(ast, fn
      {{:., _, [{:__aliases__, _, [:Decimal]}, _]}, _, _} -> true
      _ -> nil
    end) != nil
  end

  defp has_fixtures?(ast) do
    AstParser.find_node(ast, fn
      {:def, _, [{name, _, _} | _]} ->
        if name |> Atom.to_string() |> String.contains?("fixture") do
          true
        end

      _ ->
        nil
    end) != nil
  end

  defp has_mocks?(ast) do
    AstParser.find_node(ast, fn
      {{:., _, [{:__aliases__, _, [:Mox]}, _]}, _, _} -> true
      {{:., _, [_, :expect]}, _, _} -> true
      {{:., _, [_, :stub]}, _, _} -> true
      _ -> nil
    end) != nil
  end

  defp has_slot_definition?(ast) do
    AstParser.find_node(ast, fn
      {:slot, _, _} -> true
      _ -> nil
    end) != nil
  end

  defp suggest_pubsub_integrations(live_views) do
    Enum.flat_map(live_views, fn view_data ->
      missing = view_data.missing_subscriptions || []

      if missing == [] do
        []
      else
        [
          %{
            name: "Add PubSub Subscriptions",
            description: "Add missing PubSub subscriptions: #{Enum.join(missing, ", ")}",
            priority: "medium",
            steps: [
              %{
                action: "Add subscription",
                file: view_data.file,
                line: view_data.mount_line || 10
              }
            ]
          }
        ]
      end
    end)
  end

  defp suggest_component_usage(_live_views, components) do
    frequently_used =
      components
      |> Enum.filter(fn component -> component.usage_count > 5 end)
      |> Enum.map(fn component -> component.name end)
      |> Enum.uniq()
      |> Enum.take(10)

    if Enum.empty?(frequently_used) do
      []
    else
      # Return just one general suggestion
      [
        %{
          name: "Use Popular Components",
          description: "Consider using frequently used components: #{Enum.join(frequently_used, ", ")}",
          priority: "low",
          steps: []
        }
      ]
    end
  end

  defp suggest_error_handling(live_views) do
    views_without_error_handling =
      live_views
      |> Enum.reject(fn view_data -> has_error_handling?(view_data.file) end)
      |> Enum.take(3)

    if Enum.empty?(views_without_error_handling) do
      []
    else
      # Return one suggestion listing all files that need error handling
      files = Enum.map(views_without_error_handling, fn v -> Path.basename(v.file) end)

      [
        %{
          name: "Add Error Handling",
          description: "Add error handling to: #{Enum.join(files, ", ")}",
          priority: "high",
          steps:
            Enum.map(views_without_error_handling, fn view_data ->
              %{
                action: "Add error handling",
                file: view_data.file,
                line: view_data.mount_line || 10
              }
            end)
        }
      ]
    end
  end

  defp has_error_handling?(file_path) do
    find_error_pattern(file_path) != []
  end

  # Pattern summarization functions for YAML output
  defp summarize_error_patterns(patterns) do
    cond do
      Map.has_key?(patterns, :error_handler) and length(patterns[:error_handler]) > 0 ->
        "Ashfolio.ErrorHandler.handle_error/2 (#{length(patterns[:error_handler])} files)"

      Map.has_key?(patterns, :changeset_errors) and length(patterns[:changeset_errors]) > 0 ->
        "Changeset error formatting (#{length(patterns[:changeset_errors])} files)"

      true ->
        "Standard put_flash error handling"
    end
  end

  defp summarize_currency_patterns(patterns) do
    cond do
      Map.has_key?(patterns, :currency_formatter) and length(patterns[:currency_formatter]) > 0 ->
        "Currency formatting functions (#{length(patterns[:currency_formatter])} files)"

      Map.has_key?(patterns, :decimal_operations) and length(patterns[:decimal_operations]) > 0 ->
        "Decimal operations (#{length(patterns[:decimal_operations])} files)"

      true ->
        "Basic decimal formatting"
    end
  end

  defp summarize_test_setup_patterns(test_patterns) do
    setup_count =
      test_patterns
      |> Map.values()
      |> Enum.map(&Map.get(&1, :setup_blocks, 0))
      |> Enum.sum()

    cond do
      setup_count > 10 ->
        "ExUnit setup blocks (#{setup_count} total)"

      setup_count > 0 ->
        "Standard test setup patterns"

      true ->
        "Basic test structure"
    end
  end
end
