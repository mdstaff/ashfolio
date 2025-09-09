defmodule Mix.Tasks.CodeGps.AstParser do
  @moduledoc """
  AST parsing utilities for Code GPS analysis.

  Provides functions for parsing Elixir source code and extracting
  specific patterns and metadata from the Abstract Syntax Tree.
  """

  @doc """
  Parses Elixir source code content into an AST.
  """
  def parse_content(content) do
    case Code.string_to_quoted(content, columns: true) do
      {:ok, ast} -> {:ok, ast}
      {:error, _} -> {:error, :parsing_failed}
    end
  end

  @doc """
  Finds the first node in the AST matching the filter function.
  """
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

  @doc """
  Collects all nodes in the AST matching the filter function.
  """
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

  @doc """
  Extracts the module name from an AST.
  """
  def extract_module_name(ast) do
    find_node(ast, fn
      {:defmodule, _, [{:__aliases__, _, module_parts} | _]} ->
        Module.concat(module_parts)

      _ ->
        nil
    end)
  end

  @doc """
  Finds the line number of a specific function in the AST.
  """
  def find_function_line(ast, func_name, arity) do
    find_node(ast, fn
      {:def, meta, [{^func_name, _, args} | _]} when is_list(args) and length(args) == arity ->
        Keyword.get(meta, :line)

      {:defp, meta, [{^func_name, _, args} | _]} when is_list(args) and length(args) == arity ->
        Keyword.get(meta, :line)

      _ ->
        nil
    end)
  end

  @doc """
  Extracts handle_event functions from a LiveView AST.
  """
  def extract_handle_events(ast) do
    ast
    |> collect_nodes(fn
      {:def, _, [{:handle_event, _, [event_name | _]} | _]} when is_binary(event_name) ->
        event_name

      _ ->
        nil
    end)
    |> Enum.uniq()
  end

  @doc """
  Extracts assigns from mount and handle_event functions.
  """
  def extract_assigns(ast) do
    ast
    |> collect_nodes(fn
      {:assign, _, [_, key | _]} when is_atom(key) ->
        key

      {:assign, _, [_, key, _]} when is_atom(key) ->
        key

      _ ->
        nil
    end)
    |> Enum.uniq()
  end

  @doc """
  Extracts PubSub subscriptions from an AST.
  """
  def extract_pubsub_subscriptions(ast) do
    ast
    |> collect_nodes(fn
      {{:., _, [{:__aliases__, _, [:Ashfolio, :PubSub]}, :subscribe]}, _, [topic | _]}
      when is_binary(topic) ->
        topic

      _ ->
        nil
    end)
    |> Enum.uniq()
  end

  @doc """
  Extracts component attributes from an AST.
  """
  def extract_component_attrs(ast) do
    ast
    |> collect_nodes(fn
      {:attr, _, args} when is_list(args) ->
        case args do
          [name | _] when is_atom(name) -> name
          _ -> nil
        end

      _ ->
        nil
    end)
    |> Enum.uniq()
  end

  @doc """
  Extracts describe blocks from test files.
  """
  def extract_describe_blocks(ast) do
    collect_nodes(ast, fn
      {:describe, _, [description | _]} when is_binary(description) ->
        description

      _ ->
        nil
    end)
  end

  @doc """
  Counts all function definitions in the AST.
  """
  def count_functions(ast) do
    ast
    |> collect_nodes(fn
      {:def, _, [{name, _, args} | _]} when is_atom(name) and is_list(args) ->
        {name, length(args)}

      {:defp, _, [{name, _, args} | _]} when is_atom(name) and is_list(args) ->
        {name, length(args)}

      _ ->
        nil
    end)
    |> length()
  end

  @doc """
  Counts setup blocks in test files.
  """
  def count_setup_blocks(ast) do
    ast
    |> collect_nodes(fn
      {:setup, _, _} -> :setup
      _ -> nil
    end)
    |> length()
  end
end
