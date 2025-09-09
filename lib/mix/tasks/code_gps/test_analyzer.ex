defmodule Mix.Tasks.CodeGps.TestAnalyzer do
  @moduledoc """
  Handles analysis of test files, test coverage, and test gaps.

  Extracted from Mix.Tasks.CodeGps to reduce complexity and improve maintainability.
  """

  alias Mix.Tasks.CodeGps.AstParser

  @doc """
  Analyzes all test files in the project.
  """
  def analyze_tests do
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

  @doc """
  Analyzes test coverage gaps in the codebase.
  """
  def analyze_test_gaps do
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

  # Private functions

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

  defp extract_module_name_ast(ast) do
    case find_module_name_from_ast(ast) do
      {:ok, name} -> name |> Atom.to_string() |> String.split(".") |> List.last()
      _ -> "Unknown"
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

  defp extract_describe_blocks_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {{:., _, [{:__aliases__, _, [:ExUnit, :Case]}, :describe]}, _, [description]} ->
        description

      {{:., _, [{:describe, _, nil}]}, _, [description]} ->
        description

      {:describe, _, [description | _]} ->
        description

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp count_tests_regex_fallback(content) do
    # Count test macros more accurately
    test_patterns = [
      ~r/^\s*test\s+"/m,
      ~r/^\s*test\s+'/m,
      ~r/^\s*test\s+\w+/m
    ]

    test_patterns
    |> Enum.map(fn pattern ->
      pattern |> Regex.scan(content) |> length()
    end)
    |> Enum.sum()
  end

  defp count_assertions_in_content(content) do
    assertion_patterns = [
      ~r/assert\s+/,
      ~r/assert_/,
      ~r/refute\s+/,
      ~r/refute_/
    ]

    assertion_patterns
    |> Enum.map(fn pattern ->
      pattern |> Regex.scan(content) |> length()
    end)
    |> Enum.sum()
  end

  defp count_setup_blocks_ast(ast) do
    ast
    |> AstParser.collect_nodes(fn
      {:setup, _, _} -> 1
      {:setup_all, _, _} -> 1
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
    |> length()
  end

  defp infer_tested_module(test_module_name) do
    test_module_name
    |> String.replace("Test", "")
    |> String.replace("test", "")
  end
end
