# Task: Parseable MCP Extension

**Phase**: 2 - Module Integration
**Priority**: P1
**Estimate**: 3-4 hours
**Status**: Not Started

## Objective

Extend the `Parseable` behaviour to optionally expose parsing capabilities as MCP tools, enabling Claude to help with transaction import and categorization.

## Prerequisites

- [ ] Phase 1 complete
- [ ] Smart Parsing Module System implemented (or in progress)
- [ ] Understanding of Parseable behaviour pattern

## Acceptance Criteria

### Functional Requirements

1. New optional `mcp_tool_definition/0` callback in Parseable
2. Modules can opt-in to MCP exposure
3. Tool definitions include input schema from parser
4. Privacy filter respects module-level settings

### Non-Functional Requirements

1. No breaking changes to existing Parseable modules
2. Lazy loading of tool definitions
3. Clear documentation for module authors

## TDD Test Cases

### Test File: `test/ashfolio/parsing/parseable_mcp_test.exs`

```elixir
defmodule Ashfolio.Parsing.ParseableMcpTest do
  use Ashfolio.DataCase, async: true

  alias Ashfolio.Parsing.ParseableRegistry

  describe "Parseable MCP extension" do
    test "modules can define mcp_tool_definition/0" do
      defmodule TestParserWithMcp do
        @behaviour Ashfolio.Parsing.Parseable

        @impl true
        def name, do: "Test Parser"

        @impl true
        def supported_formats, do: [:csv]

        @impl true
        def parse(_content, _opts), do: {:ok, []}

        @impl true
        def mcp_tool_definition do
          %{
            name: "parse_test_format",
            description: "Parse test format transactions",
            input_schema: %{
              type: "object",
              properties: %{
                content: %{type: "string", description: "CSV content to parse"}
              },
              required: ["content"]
            }
          }
        end
      end

      assert TestParserWithMcp.mcp_tool_definition()[:name] == "parse_test_format"
    end

    test "mcp_tool_definition is optional" do
      defmodule TestParserWithoutMcp do
        @behaviour Ashfolio.Parsing.Parseable

        @impl true
        def name, do: "Basic Parser"

        @impl true
        def supported_formats, do: [:csv]

        @impl true
        def parse(_content, _opts), do: {:ok, []}

        # No mcp_tool_definition - should default to nil
      end

      # Should not raise
      refute function_exported?(TestParserWithoutMcp, :mcp_tool_definition, 0)
    end

    test "mcp_enabled?/0 returns true when tool definition exists" do
      defmodule McpEnabledParser do
        @behaviour Ashfolio.Parsing.Parseable

        @impl true
        def name, do: "MCP Enabled"

        @impl true
        def supported_formats, do: [:csv]

        @impl true
        def parse(_content, _opts), do: {:ok, []}

        @impl true
        def mcp_tool_definition do
          %{name: "test_tool"}
        end

        @impl true
        def mcp_enabled?, do: true
      end

      assert McpEnabledParser.mcp_enabled?()
    end
  end

  describe "tool definition schema" do
    test "tool definition has required fields" do
      defmodule ValidToolParser do
        @behaviour Ashfolio.Parsing.Parseable

        @impl true
        def name, do: "Valid Tool Parser"

        @impl true
        def supported_formats, do: [:csv]

        @impl true
        def parse(_content, _opts), do: {:ok, []}

        @impl true
        def mcp_tool_definition do
          %{
            name: "parse_valid",
            description: "Parse valid format",
            input_schema: %{
              type: "object",
              properties: %{
                content: %{type: "string"}
              }
            },
            privacy_mode: :standard,  # Minimum required mode
            examples: [
              %{
                description: "Parse sample CSV",
                input: %{content: "date,amount\n2024-01-01,100"}
              }
            ]
          }
        end
      end

      definition = ValidToolParser.mcp_tool_definition()

      assert Map.has_key?(definition, :name)
      assert Map.has_key?(definition, :description)
      assert Map.has_key?(definition, :input_schema)
    end

    test "tool definition can specify minimum privacy mode" do
      defmodule StrictPrivacyParser do
        @behaviour Ashfolio.Parsing.Parseable

        @impl true
        def name, do: "Strict Parser"

        @impl true
        def supported_formats, do: [:csv]

        @impl true
        def parse(_content, _opts), do: {:ok, []}

        @impl true
        def mcp_tool_definition do
          %{
            name: "parse_strict",
            description: "Parser requiring full privacy mode",
            input_schema: %{type: "object"},
            privacy_mode: :full  # Only available in full mode
          }
        end
      end

      assert StrictPrivacyParser.mcp_tool_definition()[:privacy_mode] == :full
    end
  end

  describe "registry integration" do
    test "registry collects MCP-enabled parsers" do
      # Register test parsers
      ParseableRegistry.register(FidelityParser)
      ParseableRegistry.register(SchwabParser)

      mcp_parsers = ParseableRegistry.mcp_enabled_parsers()

      # Only parsers with mcp_tool_definition should be returned
      assert Enum.all?(mcp_parsers, fn parser ->
        function_exported?(parser, :mcp_tool_definition, 0)
      end)
    end

    test "registry returns tool definitions for all enabled parsers" do
      definitions = ParseableRegistry.mcp_tool_definitions()

      assert is_list(definitions)
      for definition <- definitions do
        assert Map.has_key?(definition, :name)
        assert Map.has_key?(definition, :description)
      end
    end
  end
end
```

## Implementation Steps

### Step 1: Update Parseable Behaviour

```elixir
# lib/ashfolio/parsing/parseable.ex

defmodule Ashfolio.Parsing.Parseable do
  @moduledoc """
  Behaviour for transaction parsing modules.

  ## MCP Integration

  Modules can optionally expose their parsing capabilities as MCP tools
  by implementing `mcp_tool_definition/0`. This allows Claude to help
  users parse and categorize transactions.

  ## Example

      defmodule MyParser do
        @behaviour Ashfolio.Parsing.Parseable

        @impl true
        def name, do: "My Institution"

        @impl true
        def supported_formats, do: [:csv, :ofx]

        @impl true
        def parse(content, opts) do
          # Parse implementation
        end

        # Optional MCP integration
        @impl true
        def mcp_tool_definition do
          %{
            name: "parse_my_institution",
            description: "Parse transaction exports from My Institution",
            input_schema: %{
              type: "object",
              properties: %{
                content: %{type: "string", description: "File content"},
                format: %{type: "string", enum: ["csv", "ofx"]}
              },
              required: ["content"]
            }
          }
        end
      end
  """

  @type parse_result :: {:ok, list(map())} | {:error, term()}
  @type format :: :csv | :ofx | :qfx | :pdf

  @doc "Human-readable name of the parser"
  @callback name() :: String.t()

  @doc "List of supported file formats"
  @callback supported_formats() :: list(format())

  @doc "Parse content and return normalized transactions"
  @callback parse(content :: String.t() | binary(), opts :: keyword()) :: parse_result()

  @doc """
  Optional: MCP tool definition for this parser.

  When implemented, the parser will be exposed as an MCP tool that Claude
  can use to help parse transactions.

  Returns a map with:
  - `:name` - Tool name (required)
  - `:description` - What the tool does (required)
  - `:input_schema` - JSON Schema for tool input (required)
  - `:privacy_mode` - Minimum required privacy mode (optional, default :standard)
  - `:examples` - Usage examples (optional but recommended)
  """
  @callback mcp_tool_definition() :: map() | nil

  @doc """
  Optional: Whether MCP is enabled for this parser.
  Defaults to true if mcp_tool_definition/0 is implemented.
  """
  @callback mcp_enabled?() :: boolean()

  @optional_callbacks [mcp_tool_definition: 0, mcp_enabled?: 0]

  @doc """
  Check if a module has MCP support.
  """
  def mcp_supported?(module) do
    function_exported?(module, :mcp_tool_definition, 0) and
      (not function_exported?(module, :mcp_enabled?, 0) or module.mcp_enabled?())
  end
end
```

### Step 2: Update ParseableRegistry

```elixir
# lib/ashfolio/parsing/parseable_registry.ex

defmodule Ashfolio.Parsing.ParseableRegistry do
  @moduledoc """
  Registry for discovering and managing Parseable modules.
  """

  alias Ashfolio.Parsing.Parseable

  @doc """
  Get all registered parsers that have MCP support enabled.
  """
  def mcp_enabled_parsers do
    all_parsers()
    |> Enum.filter(&Parseable.mcp_supported?/1)
  end

  @doc """
  Get MCP tool definitions from all enabled parsers.
  """
  def mcp_tool_definitions do
    mcp_enabled_parsers()
    |> Enum.map(& &1.mcp_tool_definition())
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Find parser by MCP tool name.
  """
  def find_by_tool_name(tool_name) do
    mcp_enabled_parsers()
    |> Enum.find(fn parser ->
      parser.mcp_tool_definition()[:name] == tool_name
    end)
  end

  # ... existing functions ...
end
```

### Step 3: Create Tool Executor for Parsers

```elixir
# lib/ashfolio_web/mcp/parser_tool_executor.ex

defmodule AshfolioWeb.Mcp.ParserToolExecutor do
  @moduledoc """
  Executes parsing tools from Parseable modules via MCP.
  """

  alias Ashfolio.Parsing.ParseableRegistry
  alias AshfolioWeb.Mcp.PrivacyFilter

  @doc """
  Execute a parser tool and return filtered results.
  """
  def execute(tool_name, arguments, opts \\ []) do
    with {:ok, parser} <- find_parser(tool_name),
         :ok <- check_privacy_mode(parser, opts),
         {:ok, result} <- run_parser(parser, arguments) do
      {:ok, PrivacyFilter.filter_result(result, String.to_atom(tool_name), opts)}
    end
  end

  defp find_parser(tool_name) do
    case ParseableRegistry.find_by_tool_name(tool_name) do
      nil -> {:error, {:tool_not_found, tool_name}}
      parser -> {:ok, parser}
    end
  end

  defp check_privacy_mode(parser, opts) do
    current_mode = PrivacyFilter.current_mode()
    required_mode = get_in(parser.mcp_tool_definition(), [:privacy_mode]) || :standard

    mode_rank = %{strict: 1, anonymized: 2, standard: 3, full: 4}

    if mode_rank[current_mode] >= mode_rank[required_mode] do
      :ok
    else
      {:error, {:privacy_mode_insufficient, required_mode, current_mode}}
    end
  end

  defp run_parser(parser, %{"content" => content} = arguments) do
    format = Map.get(arguments, "format", "csv") |> String.to_atom()
    opts = Map.get(arguments, "options", %{}) |> Map.to_list()

    parser.parse(content, [{:format, format} | opts])
  end
end
```

### Step 4: Run Tests

```bash
mix test test/ashfolio/parsing/parseable_mcp_test.exs --trace
```

## Definition of Done

- [ ] Parseable behaviour updated with optional MCP callbacks
- [ ] ParseableRegistry collects MCP-enabled parsers
- [ ] ParserToolExecutor created
- [ ] Privacy mode enforcement works
- [ ] All TDD tests pass
- [ ] Existing parsers unaffected
- [ ] `mix test` passes (no regressions)

## Dependencies

**Blocked By**: Phase 1 complete
**Blocks**: Task 02 (Module Registry)

## Notes

- Consider adding dry-run mode for parsers
- Future: Allow Claude to suggest parser improvements
- Consider rate limiting for parse operations

---

*Parent: [../README.md](../README.md)*
