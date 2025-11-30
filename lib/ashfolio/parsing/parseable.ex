defmodule Ashfolio.Parsing.Parseable do
  @moduledoc """
  Behaviour for parsing modules that can be used with MCP tools.

  Implements a hybrid parsing strategy:
  - **Quick parse**: Rule-based fast path for simple, well-defined inputs
  - **Standard parse**: Full validation + execution for structured inputs

  ## Required Callbacks

  - `name/0` - Tool identifier (snake_case)
  - `description/0` - Human-readable description for tool discovery
  - `input_schema/0` - JSON Schema defining expected input format
  - `validate/1` - Validates input against schema, returns `:ok` or `{:error, reason}`
  - `execute/1` - Executes the parsing/action, returns `{:ok, result}` or `{:error, reason}`

  ## Optional Callbacks

  - `can_quick_parse?/1` - Returns `true` if input can be quickly parsed without full validation
  - `quick_parse/1` - Fast path for simple inputs (e.g., "$100" -> Decimal.new("100"))

  ## Example Implementation

      defmodule MyApp.Parsing.AmountParser do
        @behaviour Ashfolio.Parsing.Parseable

        @impl true
        def name, do: "parse_amount"

        @impl true
        def description, do: "Parses monetary amounts from various formats"

        @impl true
        def input_schema do
          %{
            type: "object",
            properties: %{
              amount: %{type: "string", description: "Amount to parse (e.g., '$100', '1.5k')"}
            },
            required: ["amount"]
          }
        end

        @impl true
        def validate(%{"amount" => amount}) when is_binary(amount), do: :ok
        def validate(_), do: {:error, "amount must be a string"}

        @impl true
        def execute(%{"amount" => amount}) do
          # Parse and return Decimal
          {:ok, Decimal.new(amount)}
        end

        # Optional: enable quick parsing for simple formats
        @impl true
        def can_quick_parse?(input) when is_binary(input), do: true
        def can_quick_parse?(_), do: false

        @impl true
        def quick_parse(input) when is_binary(input) do
          {:ok, Decimal.new(input)}
        end
      end

  ## Usage

  Use the unified `parse/2` function which automatically selects the optimal path:

      Parseable.parse(AmountParser, "$100")        # Uses quick_parse
      Parseable.parse(AmountParser, %{"amount" => "$100"})  # Uses validate + execute
  """

  @doc "Returns the tool name (snake_case identifier)"
  @callback name() :: String.t()

  @doc "Returns a human-readable description"
  @callback description() :: String.t()

  @doc "Returns the JSON Schema for expected input"
  @callback input_schema() :: map()

  @doc "Validates input, returns :ok or {:error, reason}"
  @callback validate(input :: any()) :: :ok | {:error, term()}

  @doc "Executes the parsing/action on validated input"
  @callback execute(input :: any()) :: {:ok, term()} | {:error, term()}

  @doc "Returns true if input can be quickly parsed (optional)"
  @callback can_quick_parse?(input :: any()) :: boolean()

  @doc "Fast path parsing for simple inputs (optional)"
  @callback quick_parse(input :: any()) :: {:ok, term()} | {:error, term()}

  @optional_callbacks can_quick_parse?: 1, quick_parse: 1

  @doc """
  Unified parsing interface that selects the optimal execution path.

  1. If module implements `can_quick_parse?/1` and it returns `true`, uses `quick_parse/1`
  2. Otherwise, runs `validate/1` followed by `execute/1`

  ## Examples

      iex> Parseable.parse(AmountParser, "$100")
      {:ok, #Decimal<100>}

      iex> Parseable.parse(AmountParser, %{"amount" => "invalid"})
      {:error, "could not parse amount"}
  """
  @spec parse(module(), any()) :: {:ok, term()} | {:error, term()}
  def parse(module, input) do
    if quick_parse_available?(module) && module.can_quick_parse?(input) do
      module.quick_parse(input)
    else
      with :ok <- module.validate(input) do
        module.execute(input)
      end
    end
  end

  defp quick_parse_available?(module) do
    function_exported?(module, :can_quick_parse?, 1) &&
      function_exported?(module, :quick_parse, 1)
  end
end
