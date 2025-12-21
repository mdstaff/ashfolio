# Task: Dynamic Module Registry

**Phase**: 2 - Module Integration
**Priority**: P1
**Estimate**: 4-6 hours
**Status**: Not Started

## Objective

Create a centralized registry that dynamically discovers and registers MCP tools from multiple sources: Ash domains, Parseable modules, and custom tool providers.

## Prerequisites

- [ ] Phase 1 complete
- [ ] Task P2-01 (Parseable MCP) complete
- [ ] Understanding of Elixir module discovery

## Acceptance Criteria

### Functional Requirements

1. Registry discovers tools from:
   - Ash domains with `tools` blocks
   - Parseable modules with `mcp_tool_definition/0`
   - Custom tool providers (future extensibility)
2. Tools can be registered/unregistered at runtime
3. Tool metadata includes source information
4. Privacy mode filtering applies across all sources

### Non-Functional Requirements

1. Discovery completes in < 100ms at startup
2. Runtime registration is thread-safe
3. No performance impact on tool invocation
4. Clear error messages for conflicts

## TDD Test Cases

### Test File: `test/ashfolio_web/mcp/module_registry_test.exs`

```elixir
defmodule AshfolioWeb.Mcp.ModuleRegistryTest do
  use Ashfolio.DataCase, async: false

  alias AshfolioWeb.Mcp.ModuleRegistry

  describe "startup discovery" do
    test "discovers tools from Ash domains" do
      tools = ModuleRegistry.all_tools()

      # Core tools from Portfolio domain
      tool_names = Enum.map(tools, & &1.name)
      assert "list_accounts" in tool_names
      assert "list_transactions" in tool_names
      assert "get_portfolio_summary" in tool_names
    end

    test "discovers tools from Parseable modules" do
      tools = ModuleRegistry.all_tools()

      # Should include parser tools if any are MCP-enabled
      parser_tools = Enum.filter(tools, &(&1.source == :parseable))
      # At minimum, the structure should work
      assert is_list(parser_tools)
    end

    test "includes source metadata" do
      tools = ModuleRegistry.all_tools()

      for tool <- tools do
        assert Map.has_key?(tool, :source)
        assert tool.source in [:ash_domain, :parseable, :custom]
        assert Map.has_key?(tool, :module)
      end
    end
  end

  describe "tool lookup" do
    test "find_tool returns tool by name" do
      tool = ModuleRegistry.find_tool("list_accounts")

      assert tool != nil
      assert tool.name == "list_accounts"
      assert tool.source == :ash_domain
    end

    test "find_tool returns nil for unknown tool" do
      assert ModuleRegistry.find_tool("nonexistent_tool") == nil
    end

    test "find_tool is case-sensitive" do
      assert ModuleRegistry.find_tool("list_accounts") != nil
      assert ModuleRegistry.find_tool("List_Accounts") == nil
    end
  end

  describe "runtime registration" do
    test "register_tool adds custom tool" do
      custom_tool = %{
        name: "custom_analysis",
        description: "Custom portfolio analysis",
        source: :custom,
        module: MyCustomModule,
        input_schema: %{type: "object"},
        executor: fn args -> {:ok, %{result: args}} end
      }

      :ok = ModuleRegistry.register_tool(custom_tool)

      assert ModuleRegistry.find_tool("custom_analysis") != nil
    end

    test "unregister_tool removes tool" do
      custom_tool = %{
        name: "temporary_tool",
        description: "Temporary",
        source: :custom,
        module: TempModule,
        input_schema: %{type: "object"},
        executor: fn _ -> {:ok, %{}} end
      }

      :ok = ModuleRegistry.register_tool(custom_tool)
      assert ModuleRegistry.find_tool("temporary_tool") != nil

      :ok = ModuleRegistry.unregister_tool("temporary_tool")
      assert ModuleRegistry.find_tool("temporary_tool") == nil
    end

    test "registration rejects duplicate names" do
      custom_tool = %{
        name: "list_accounts",  # Already exists
        description: "Conflict",
        source: :custom,
        module: ConflictModule,
        input_schema: %{type: "object"},
        executor: fn _ -> {:ok, %{}} end
      }

      assert {:error, :name_conflict} = ModuleRegistry.register_tool(custom_tool)
    end

    test "registration validates required fields" do
      invalid_tool = %{
        name: "missing_fields"
        # Missing description, input_schema, etc.
      }

      assert {:error, {:invalid_tool, _reason}} = ModuleRegistry.register_tool(invalid_tool)
    end
  end

  describe "privacy filtering" do
    test "tools_for_mode returns tools available at privacy level" do
      # Strict mode should have fewer tools
      strict_tools = ModuleRegistry.tools_for_mode(:strict)
      full_tools = ModuleRegistry.tools_for_mode(:full)

      assert length(strict_tools) <= length(full_tools)
    end

    test "tools respect minimum privacy mode" do
      custom_tool = %{
        name: "sensitive_tool",
        description: "Needs full access",
        source: :custom,
        module: SensitiveModule,
        input_schema: %{type: "object"},
        privacy_mode: :full,  # Only available in full mode
        executor: fn _ -> {:ok, %{}} end
      }

      :ok = ModuleRegistry.register_tool(custom_tool)

      assert "sensitive_tool" not in tool_names(ModuleRegistry.tools_for_mode(:strict))
      assert "sensitive_tool" not in tool_names(ModuleRegistry.tools_for_mode(:anonymized))
      assert "sensitive_tool" not in tool_names(ModuleRegistry.tools_for_mode(:standard))
      assert "sensitive_tool" in tool_names(ModuleRegistry.tools_for_mode(:full))
    end
  end

  describe "tool execution" do
    test "execute_tool runs tool and returns result" do
      {:ok, result} = ModuleRegistry.execute_tool("list_accounts", %{})

      assert result != nil
    end

    test "execute_tool applies privacy filter" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized)

      {:ok, result} = ModuleRegistry.execute_tool("list_accounts", %{})

      # Result should be anonymized
      refute result |> inspect() |> String.contains?("Fidelity")
    end

    test "execute_tool returns error for unknown tool" do
      assert {:error, :tool_not_found} = ModuleRegistry.execute_tool("unknown", %{})
    end

    test "execute_tool returns error for privacy violation" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :strict)

      # Register tool that requires full mode
      custom_tool = %{
        name: "full_mode_only",
        description: "Requires full",
        source: :custom,
        module: FullModeModule,
        input_schema: %{type: "object"},
        privacy_mode: :full,
        executor: fn _ -> {:ok, %{sensitive: true}} end
      }
      :ok = ModuleRegistry.register_tool(custom_tool)

      assert {:error, :privacy_mode_insufficient} =
               ModuleRegistry.execute_tool("full_mode_only", %{})
    end
  end

  describe "MCP tools/list integration" do
    test "to_mcp_tools_list returns formatted tool list" do
      tools_list = ModuleRegistry.to_mcp_tools_list()

      assert is_list(tools_list)

      for tool <- tools_list do
        assert Map.has_key?(tool, "name")
        assert Map.has_key?(tool, "description")
        assert Map.has_key?(tool, "inputSchema")
      end
    end

    test "to_mcp_tools_list respects current privacy mode" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :strict)
      strict_list = ModuleRegistry.to_mcp_tools_list()

      Application.put_env(:ashfolio, :mcp, privacy_mode: :full)
      full_list = ModuleRegistry.to_mcp_tools_list()

      assert length(strict_list) <= length(full_list)
    end
  end

  # Helper functions

  defp tool_names(tools) do
    Enum.map(tools, & &1.name)
  end
end
```

## Implementation Steps

### Step 1: Create Module Registry GenServer

```elixir
# lib/ashfolio_web/mcp/module_registry.ex

defmodule AshfolioWeb.Mcp.ModuleRegistry do
  @moduledoc """
  Central registry for all MCP tools from various sources.

  ## Sources

  1. **Ash Domains** - Tools defined in `tools` blocks
  2. **Parseable Modules** - Parsing tools from `mcp_tool_definition/0`
  3. **Custom Providers** - Runtime-registered tools

  ## Usage

      # Get all tools
      ModuleRegistry.all_tools()

      # Find specific tool
      ModuleRegistry.find_tool("list_accounts")

      # Execute tool
      ModuleRegistry.execute_tool("list_accounts", %{filter: %{type: "investment"}})

      # Register custom tool
      ModuleRegistry.register_tool(%{name: "custom", ...})
  """

  use GenServer

  alias AshfolioWeb.Mcp.PrivacyFilter

  @type tool :: %{
          name: String.t(),
          description: String.t(),
          source: :ash_domain | :parseable | :custom,
          module: module(),
          input_schema: map(),
          privacy_mode: atom(),
          executor: (map() -> {:ok, any()} | {:error, any()}) | nil,
          examples: list(map())
        }

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Get all registered tools"
  @spec all_tools() :: list(tool())
  def all_tools do
    GenServer.call(__MODULE__, :all_tools)
  end

  @doc "Find tool by name"
  @spec find_tool(String.t()) :: tool() | nil
  def find_tool(name) do
    GenServer.call(__MODULE__, {:find_tool, name})
  end

  @doc "Get tools available at a privacy mode"
  @spec tools_for_mode(atom()) :: list(tool())
  def tools_for_mode(mode) do
    GenServer.call(__MODULE__, {:tools_for_mode, mode})
  end

  @doc "Register a custom tool"
  @spec register_tool(map()) :: :ok | {:error, term()}
  def register_tool(tool) do
    GenServer.call(__MODULE__, {:register_tool, tool})
  end

  @doc "Unregister a tool"
  @spec unregister_tool(String.t()) :: :ok | {:error, term()}
  def unregister_tool(name) do
    GenServer.call(__MODULE__, {:unregister_tool, name})
  end

  @doc "Execute a tool"
  @spec execute_tool(String.t(), map()) :: {:ok, any()} | {:error, term()}
  def execute_tool(name, arguments) do
    GenServer.call(__MODULE__, {:execute_tool, name, arguments})
  end

  @doc "Get tools formatted for MCP tools/list response"
  @spec to_mcp_tools_list() :: list(map())
  def to_mcp_tools_list do
    GenServer.call(__MODULE__, :to_mcp_tools_list)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    tools = discover_all_tools()
    {:ok, %{tools: tools}}
  end

  @impl true
  def handle_call(:all_tools, _from, state) do
    {:reply, Map.values(state.tools), state}
  end

  @impl true
  def handle_call({:find_tool, name}, _from, state) do
    {:reply, Map.get(state.tools, name), state}
  end

  @impl true
  def handle_call({:tools_for_mode, mode}, _from, state) do
    mode_rank = %{strict: 1, anonymized: 2, standard: 3, full: 4}
    current_rank = mode_rank[mode] || 4

    filtered =
      state.tools
      |> Map.values()
      |> Enum.filter(fn tool ->
        tool_rank = mode_rank[tool.privacy_mode || :anonymized] || 2
        current_rank >= tool_rank
      end)

    {:reply, filtered, state}
  end

  @impl true
  def handle_call({:register_tool, tool}, _from, state) do
    case validate_tool(tool) do
      :ok ->
        if Map.has_key?(state.tools, tool.name) do
          {:reply, {:error, :name_conflict}, state}
        else
          normalized = normalize_tool(tool, :custom)
          {:reply, :ok, %{state | tools: Map.put(state.tools, tool.name, normalized)}}
        end

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:unregister_tool, name}, _from, state) do
    if Map.has_key?(state.tools, name) do
      {:reply, :ok, %{state | tools: Map.delete(state.tools, name)}}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:execute_tool, name, arguments}, _from, state) do
    result =
      with {:ok, tool} <- get_tool(state.tools, name),
           :ok <- check_privacy_mode(tool),
           {:ok, raw_result} <- invoke_tool(tool, arguments) do
        filtered = PrivacyFilter.filter_result(raw_result, String.to_atom(name))
        {:ok, filtered}
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call(:to_mcp_tools_list, _from, state) do
    mode = PrivacyFilter.current_mode()
    mode_rank = %{strict: 1, anonymized: 2, standard: 3, full: 4}
    current_rank = mode_rank[mode] || 2

    tools_list =
      state.tools
      |> Map.values()
      |> Enum.filter(fn tool ->
        tool_rank = mode_rank[tool.privacy_mode || :anonymized] || 2
        current_rank >= tool_rank
      end)
      |> Enum.map(&format_for_mcp/1)

    {:reply, tools_list, state}
  end

  # Private Functions

  defp discover_all_tools do
    ash_tools = discover_ash_tools()
    parser_tools = discover_parser_tools()

    (ash_tools ++ parser_tools)
    |> Enum.map(fn tool -> {tool.name, tool} end)
    |> Map.new()
  end

  defp discover_ash_tools do
    # Get tools from Ash domains with AshAi extension
    # This integrates with AshAi.Mcp.Server
    domains = [Ashfolio.Portfolio]

    domains
    |> Enum.flat_map(&get_domain_tools/1)
  end

  defp get_domain_tools(domain) do
    if Code.ensure_loaded?(domain) and function_exported?(domain, :mcp_tools, 0) do
      domain.mcp_tools()
      |> Enum.map(fn tool_def ->
        normalize_tool(tool_def, :ash_domain, domain)
      end)
    else
      []
    end
  end

  defp discover_parser_tools do
    alias Ashfolio.Parsing.ParseableRegistry

    if Code.ensure_loaded?(ParseableRegistry) do
      ParseableRegistry.mcp_tool_definitions()
      |> Enum.map(fn tool_def ->
        normalize_tool(tool_def, :parseable)
      end)
    else
      []
    end
  end

  defp normalize_tool(tool, source, module \\ nil) do
    %{
      name: tool[:name] || tool["name"],
      description: tool[:description] || tool["description"] || "",
      source: source,
      module: module || tool[:module],
      input_schema: tool[:input_schema] || tool["inputSchema"] || %{type: "object"},
      privacy_mode: tool[:privacy_mode] || :anonymized,
      executor: tool[:executor],
      examples: tool[:examples] || []
    }
  end

  defp validate_tool(tool) do
    required = [:name, :description, :input_schema]

    missing = Enum.filter(required, fn key -> not Map.has_key?(tool, key) end)

    if Enum.empty?(missing) do
      :ok
    else
      {:error, {:invalid_tool, {:missing_fields, missing}}}
    end
  end

  defp get_tool(tools, name) do
    case Map.get(tools, name) do
      nil -> {:error, :tool_not_found}
      tool -> {:ok, tool}
    end
  end

  defp check_privacy_mode(tool) do
    current_mode = PrivacyFilter.current_mode()
    required_mode = tool.privacy_mode || :anonymized

    mode_rank = %{strict: 1, anonymized: 2, standard: 3, full: 4}

    if mode_rank[current_mode] >= mode_rank[required_mode] do
      :ok
    else
      {:error, :privacy_mode_insufficient}
    end
  end

  defp invoke_tool(tool, arguments) do
    cond do
      tool.executor ->
        tool.executor.(arguments)

      tool.source == :ash_domain ->
        # Delegate to AshAi
        AshAi.Mcp.Server.execute_tool(tool.name, arguments)

      tool.source == :parseable ->
        AshfolioWeb.Mcp.ParserToolExecutor.execute(tool.name, arguments)

      true ->
        {:error, :no_executor}
    end
  end

  defp format_for_mcp(tool) do
    base = %{
      "name" => tool.name,
      "description" => tool.description,
      "inputSchema" => tool.input_schema
    }

    if Enum.any?(tool.examples) do
      Map.put(base, "examples", tool.examples)
    else
      base
    end
  end
end
```

### Step 2: Add to Application Supervisor

```elixir
# lib/ashfolio/application.ex

def start(_type, _args) do
  children = [
    # ... existing children ...
    AshfolioWeb.Mcp.ModuleRegistry
  ]

  # ...
end
```

### Step 3: Run Tests

```bash
mix test test/ashfolio_web/mcp/module_registry_test.exs --trace
```

## Definition of Done

- [ ] ModuleRegistry GenServer created
- [ ] Discovers Ash domain tools
- [ ] Discovers Parseable module tools
- [ ] Runtime registration works
- [ ] Privacy filtering applied
- [ ] Thread-safe operations
- [ ] All TDD tests pass
- [ ] `mix test` passes (no regressions)

## Dependencies

**Blocked By**: Tasks P1-*, P2-01
**Blocks**: Task P2-03 (Tool Search)

## Notes

- Consider using ETS for faster lookups
- Future: Add tool versioning
- Future: Add tool deprecation support

---

*Parent: [../README.md](../README.md)*
