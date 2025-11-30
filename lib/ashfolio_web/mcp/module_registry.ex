defmodule AshfolioWeb.Mcp.ModuleRegistry do
  @moduledoc """
  Central registry for MCP tools with discovery and lookup capabilities.

  Discovers tools from multiple sources:
  - Ash domains with AshAi extensions (existing portfolio tools)
  - Parseable modules (parsing-enabled tools)
  - Runtime registrations (future extensibility)

  ## Usage

      # Get all available tools
      ModuleRegistry.all_tools()

      # Find a specific tool
      ModuleRegistry.find_tool(:list_accounts)

      # Get tools for a privacy mode
      ModuleRegistry.tools_for_mode(:anonymized)

      # Runtime registration
      ModuleRegistry.register_tool(:custom_tool, %{...})
  """
  use GenServer

  alias AshfolioWeb.Mcp.ParserToolExecutor
  alias Spark.Dsl.Extension

  require Logger

  @type tool_definition :: %{
          name: atom(),
          description: String.t(),
          source: :ash_domain | :parseable | :runtime,
          domain: module() | nil,
          action: atom() | nil,
          resource: module() | nil,
          privacy_modes: [:strict | :anonymized | :standard | :full]
        }

  # =============================================================================
  # Client API
  # =============================================================================

  @doc """
  Starts the module registry.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns all registered tools.
  """
  @spec all_tools() :: [tool_definition()]
  def all_tools do
    GenServer.call(__MODULE__, :all_tools)
  end

  @doc """
  Finds a tool by name.

  Returns `{:ok, tool}` if found, `:error` otherwise.
  """
  @spec find_tool(atom()) :: {:ok, tool_definition()} | :error
  def find_tool(name) when is_atom(name) do
    GenServer.call(__MODULE__, {:find_tool, name})
  end

  @doc """
  Returns tools available for a specific privacy mode.

  Tools are filtered based on their `privacy_modes` list.
  """
  @spec tools_for_mode(:strict | :anonymized | :standard | :full) :: [tool_definition()]
  def tools_for_mode(mode) when mode in [:strict, :anonymized, :standard, :full] do
    GenServer.call(__MODULE__, {:tools_for_mode, mode})
  end

  @doc """
  Registers a tool at runtime.

  Returns `:ok` if successful, `{:error, reason}` otherwise.
  """
  @spec register_tool(atom(), map()) :: :ok | {:error, String.t()}
  def register_tool(name, definition) when is_atom(name) and is_map(definition) do
    GenServer.call(__MODULE__, {:register_tool, name, definition})
  end

  @doc """
  Unregisters a runtime-registered tool.

  Only tools with source `:runtime` can be unregistered.
  Returns `:ok` if successful, `{:error, reason}` otherwise.
  """
  @spec unregister_tool(atom()) :: :ok | {:error, String.t()}
  def unregister_tool(name) when is_atom(name) do
    GenServer.call(__MODULE__, {:unregister_tool, name})
  end

  @doc """
  Forces a refresh of discovered tools.

  Useful after hot code reloading or configuration changes.
  """
  @spec refresh() :: :ok
  def refresh do
    GenServer.cast(__MODULE__, :refresh)
  end

  # =============================================================================
  # Server Callbacks
  # =============================================================================

  @impl true
  def init(_opts) do
    state = %{
      tools: %{},
      runtime_tools: %{}
    }

    {:ok, state, {:continue, :discover}}
  end

  @impl true
  def handle_continue(:discover, state) do
    tools = discover_all_tools()
    {:noreply, %{state | tools: tools}}
  end

  @impl true
  def handle_call(:all_tools, _from, state) do
    all = Map.merge(state.tools, state.runtime_tools)
    {:reply, Map.values(all), state}
  end

  @impl true
  def handle_call({:find_tool, name}, _from, state) do
    result =
      case Map.get(state.tools, name) || Map.get(state.runtime_tools, name) do
        nil -> :error
        tool -> {:ok, tool}
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:tools_for_mode, mode}, _from, state) do
    all = Map.merge(state.tools, state.runtime_tools)

    filtered =
      all
      |> Map.values()
      |> Enum.filter(fn tool ->
        mode in (tool[:privacy_modes] || [:standard, :full])
      end)

    {:reply, filtered, state}
  end

  @impl true
  def handle_call({:register_tool, name, definition}, _from, state) do
    if Map.has_key?(state.tools, name) do
      {:reply, {:error, "Tool #{name} already exists (discovered)"}, state}
    else
      tool = Map.merge(definition, %{name: name, source: :runtime})
      new_runtime = Map.put(state.runtime_tools, name, tool)
      {:reply, :ok, %{state | runtime_tools: new_runtime}}
    end
  end

  @impl true
  def handle_call({:unregister_tool, name}, _from, state) do
    if Map.has_key?(state.runtime_tools, name) do
      new_runtime = Map.delete(state.runtime_tools, name)
      {:reply, :ok, %{state | runtime_tools: new_runtime}}
    else
      {:reply, {:error, "Tool #{name} not found or cannot be unregistered"}, state}
    end
  end

  @impl true
  def handle_cast(:refresh, state) do
    tools = discover_all_tools()
    {:noreply, %{state | tools: tools}}
  end

  # =============================================================================
  # Private: Discovery
  # =============================================================================

  defp discover_all_tools do
    ash_tools = discover_ash_domain_tools()
    parseable_tools = discover_parseable_tools()

    # Ash domain tools take precedence (they're already registered with AshAi)
    # Only add parseable tools that aren't already in the domain
    parseable_only =
      Map.reject(parseable_tools, fn {name, _} ->
        Map.has_key?(ash_tools, name)
      end)

    Map.merge(ash_tools, parseable_only)
  end

  defp discover_ash_domain_tools do
    domains = configured_domains()

    Enum.reduce(domains, %{}, fn domain, acc ->
      case discover_domain_tools(domain) do
        {:ok, tools} -> Map.merge(acc, tools)
        {:error, _} -> acc
      end
    end)
  end

  defp discover_domain_tools(domain) do
    with true <- Code.ensure_loaded?(domain),
         tools when tools != nil and tools != [] <-
           Extension.get_entities(domain, [:tools]) do
      {:ok, build_tool_map(tools, domain)}
    else
      false -> {:error, :not_loaded}
      _ -> {:error, :no_tools}
    end
  end

  defp build_tool_map(tools, domain) do
    Map.new(tools, fn tool ->
      {tool.name,
       %{
         name: tool.name,
         description: tool.description || "",
         source: :ash_domain,
         domain: domain,
         action: tool.action,
         resource: tool.resource,
         privacy_modes: infer_privacy_modes(tool.name)
       }}
    end)
  end

  defp discover_parseable_tools do
    # Get tools from ParserToolExecutor
    supported = ParserToolExecutor.supported_tools()

    Enum.reduce(supported, %{}, fn tool_name, acc ->
      schema = ParserToolExecutor.schema_for_tool(tool_name)

      definition = %{
        name: tool_name,
        description: parseable_tool_description(tool_name),
        source: :parseable,
        domain: nil,
        action: nil,
        resource: nil,
        schema: schema,
        privacy_modes: [:standard, :full]
      }

      Map.put(acc, tool_name, definition)
    end)
  end

  defp parseable_tool_description(:add_expense) do
    "Add an expense record with natural language support"
  end

  defp parseable_tool_description(:add_transaction) do
    "Add a portfolio transaction with natural language support"
  end

  defp parseable_tool_description(_), do: ""

  defp infer_privacy_modes(tool_name) do
    # Tools that work in all modes (non-sensitive or meta-tools)
    full_access_tools = [:list_symbols, :search_tools]

    # Tools that only work in standard/full (contain sensitive data)
    standard_only_tools = [:add_expense, :add_transaction]

    cond do
      tool_name in full_access_tools ->
        [:strict, :anonymized, :standard, :full]

      tool_name in standard_only_tools ->
        [:standard, :full]

      true ->
        # Default: work in anonymized and above
        [:anonymized, :standard, :full]
    end
  end

  defp configured_domains do
    # Return domains that use AshAi
    [Ashfolio.Portfolio]
  end
end
