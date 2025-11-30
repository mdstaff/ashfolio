defmodule Ashfolio.Parsing.Schema do
  @moduledoc """
  Schema definitions and validation for LLM-assisted structuring.

  When an MCP tool receives unstructured input, it can return schema guidance
  that tells the LLM how to structure the data. The LLM then re-calls the tool
  with properly structured input that can be validated and processed.

  ## Workflow

  1. User says: "Add $1800 rent expense"
  2. MCP tool receives: `{text: "rent $1800"}`
  3. Tool returns: `{needs_structure: true, schema: {...}, example: {...}}`
  4. LLM re-calls: `{expenses: [{amount: "1800", category: "Housing", ...}]}`
  5. Server validates against schema and creates record

  ## Example

      # Get schema guidance for LLM
      guidance = Schema.schema_guidance_response(:expense)
      # => %{needs_structure: true, schema: %{...}, example: %{...}}

      # Validate structured input
      Schema.validate_against_schema(input, Schema.expense_schema())
      # => :ok | {:error, ["amount must be string", ...]}
  """

  @doc """
  Returns the JSON Schema for expense records.

  All amounts are strings to allow flexible parsing (e.g., "$100", "85k").
  """
  @spec expense_schema() :: map()
  def expense_schema do
    %{
      type: "object",
      properties: %{
        amount: %{
          type: "string",
          description: "Expense amount (e.g., '$100', '85.50', '1.5k')"
        },
        category: %{
          type: "string",
          description: "Expense category (e.g., 'Food', 'Housing', 'Transportation')"
        },
        date: %{
          type: "string",
          description: "Date in ISO format (YYYY-MM-DD) or relative ('today', 'yesterday')"
        },
        description: %{
          type: "string",
          description: "Optional description of the expense"
        },
        vendor: %{
          type: "string",
          description: "Optional vendor/merchant name"
        }
      },
      required: ["amount", "category", "date"]
    }
  end

  @doc """
  Returns the JSON Schema for transaction records.
  """
  @spec transaction_schema() :: map()
  def transaction_schema do
    %{
      type: "object",
      properties: %{
        type: %{
          type: "string",
          enum: ["buy", "sell", "dividend", "fee", "interest", "liability", "deposit", "withdrawal"],
          description: "Transaction type"
        },
        symbol: %{
          type: "string",
          description: "Stock/ETF ticker symbol (e.g., 'AAPL', 'VTI')"
        },
        quantity: %{
          type: "string",
          description: "Number of shares"
        },
        price: %{
          type: "string",
          description: "Price per share (e.g., '$150.00')"
        },
        date: %{
          type: "string",
          description: "Date in ISO format (YYYY-MM-DD)"
        },
        account: %{
          type: "string",
          description: "Optional account name or ID"
        },
        fee: %{
          type: "string",
          description: "Optional transaction fee"
        }
      },
      required: ["type", "symbol", "quantity", "price", "date"]
    }
  end

  @doc """
  Validates input data against a JSON Schema.

  Returns `:ok` if valid, `{:error, errors}` with list of validation errors otherwise.

  ## Examples

      iex> Schema.validate_against_schema(%{"amount" => "$100", "category" => "Food", "date" => "2024-01-15"}, Schema.expense_schema())
      :ok

      iex> Schema.validate_against_schema(%{"amount" => 100}, Schema.expense_schema())
      {:error, ["amount: expected string, got integer", "category: required field missing", ...]}
  """
  @spec validate_against_schema(map(), map()) :: :ok | {:error, [String.t()]}
  def validate_against_schema(data, schema) when is_map(data) and is_map(schema) do
    errors =
      []
      |> check_required_fields(data, schema)
      |> check_field_types(data, schema)
      |> check_enum_values(data, schema)

    case errors do
      [] -> :ok
      _ -> {:error, errors}
    end
  end

  @doc """
  Generates an example object from a schema.

  Useful for showing LLMs the expected format.
  """
  @spec schema_to_example(map()) :: map()
  def schema_to_example(schema) do
    Map.new(schema.properties, fn {field, spec} ->
      {Atom.to_string(field), generate_example_value(spec)}
    end)
  end

  @doc """
  Returns a complete guidance response for LLM-assisted structuring.

  This is what an MCP tool returns when it receives unstructured input
  and needs the LLM to re-call with structured data.

  ## Examples

      iex> Schema.schema_guidance_response(:expense)
      %{
        needs_structure: true,
        schema: %{type: "object", ...},
        example: %{"amount" => "$100", ...},
        instructions: "Please provide expense data..."
      }
  """
  @spec schema_guidance_response(atom()) :: map() | {:error, String.t()}
  def schema_guidance_response(:expense) do
    schema = expense_schema()

    %{
      needs_structure: true,
      schema: schema,
      example: schema_to_example(schema),
      instructions: """
      Please provide expense data in the structured format shown in the schema.
      All amounts should be strings (e.g., "$100", "85.50").
      Dates should be in ISO format (YYYY-MM-DD) or relative terms like "today" or "yesterday".
      """
    }
  end

  def schema_guidance_response(:transaction) do
    schema = transaction_schema()

    %{
      needs_structure: true,
      schema: schema,
      example: schema_to_example(schema),
      instructions: """
      Please provide transaction data in the structured format shown in the schema.
      Type must be one of: buy, sell, dividend, fee, interest, liability, deposit, withdrawal.
      Amounts and prices should be strings (e.g., "$150.00").
      Dates should be in ISO format (YYYY-MM-DD).
      """
    }
  end

  def schema_guidance_response(unknown) do
    {:error, "Unknown schema type: #{inspect(unknown)}"}
  end

  # =============================================================================
  # Private Validation Helpers
  # =============================================================================

  defp check_required_fields(errors, data, schema) do
    required_fields = schema[:required] || []

    Enum.reduce(required_fields, errors, fn field, acc ->
      if Map.has_key?(data, field) do
        acc
      else
        ["#{field}: required field missing" | acc]
      end
    end)
  end

  defp check_field_types(errors, data, schema) do
    properties = schema[:properties] || %{}

    Enum.reduce(data, errors, fn {field, value}, acc ->
      field_atom = safe_to_atom(field)
      spec = if field_atom, do: Map.get(properties, field_atom)

      if spec && !valid_type?(value, spec[:type]) do
        ["#{field}: expected #{spec[:type]}, got #{type_of(value)}" | acc]
      else
        acc
      end
    end)
  end

  defp check_enum_values(errors, data, schema) do
    properties = schema[:properties] || %{}

    Enum.reduce(data, errors, fn {field, value}, acc ->
      field_atom = safe_to_atom(field)
      spec = if field_atom, do: Map.get(properties, field_atom)

      if spec && spec[:enum] && value not in spec[:enum] do
        ["#{field}: must be one of #{inspect(spec[:enum])}, got #{inspect(value)}" | acc]
      else
        acc
      end
    end)
  end

  defp safe_to_atom(field) when is_atom(field), do: field

  defp safe_to_atom(field) when is_binary(field) do
    String.to_existing_atom(field)
  rescue
    ArgumentError -> nil
  end

  defp valid_type?(value, "string") when is_binary(value), do: true
  defp valid_type?(value, "number") when is_number(value), do: true
  defp valid_type?(value, "integer") when is_integer(value), do: true
  defp valid_type?(value, "boolean") when is_boolean(value), do: true
  defp valid_type?(value, "array") when is_list(value), do: true
  defp valid_type?(value, "object") when is_map(value), do: true
  defp valid_type?(_, _), do: false

  defp type_of(value) when is_binary(value), do: "string"
  defp type_of(value) when is_integer(value), do: "integer"
  defp type_of(value) when is_float(value), do: "number"
  defp type_of(value) when is_boolean(value), do: "boolean"
  defp type_of(value) when is_list(value), do: "array"
  defp type_of(value) when is_map(value), do: "object"
  defp type_of(_), do: "unknown"

  defp generate_example_value(%{enum: [first | _]}), do: first

  defp generate_example_value(%{type: "string", description: desc}) do
    cond do
      String.contains?(desc || "", "amount") -> "$100.00"
      String.contains?(desc || "", "date") -> "2024-01-15"
      String.contains?(desc || "", "symbol") -> "AAPL"
      String.contains?(desc || "", "quantity") -> "10"
      String.contains?(desc || "", "price") -> "$150.00"
      String.contains?(desc || "", "category") -> "Food"
      true -> "example"
    end
  end

  defp generate_example_value(%{type: "number"}), do: 100.0
  defp generate_example_value(%{type: "integer"}), do: 100
  defp generate_example_value(%{type: "boolean"}), do: true
  defp generate_example_value(_), do: "example"
end
