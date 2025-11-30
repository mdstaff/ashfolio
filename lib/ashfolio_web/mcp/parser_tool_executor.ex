defmodule AshfolioWeb.Mcp.ParserToolExecutor do
  @moduledoc """
  Routes MCP tool calls to Parseable modules with two-phase execution.

  ## Two-Phase Flow

  1. **Unstructured Input** (has "text" field):
     Returns schema guidance so the LLM can structure the data

  2. **Structured Input** (has "expense" or "transaction" field):
     Validates against schema, parses amounts, and creates records

  ## Example

      # Phase 1: User says "add rent expense $1800"
      ParserToolExecutor.execute(:add_expense, %{"text" => "rent $1800"})
      # => {:guidance, %{needs_structure: true, schema: ..., example: ...}}

      # Phase 2: LLM re-calls with structured data
      ParserToolExecutor.execute(:add_expense, %{
        "expense" => %{"amount" => "1800", "category" => "Housing", ...}
      })
      # => {:ok, %Expense{...}}
  """

  alias Ashfolio.FinancialManagement.Expense
  alias Ashfolio.Parsing.AmountParser
  alias Ashfolio.Parsing.Schema
  alias Ashfolio.Portfolio.Account
  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Portfolio.Transaction

  require Ash.Query

  @supported_tools [:add_expense, :add_transaction]

  @doc """
  Returns list of tools supported by the parser executor.
  """
  @spec supported_tools() :: [atom()]
  def supported_tools, do: @supported_tools

  @doc """
  Returns the schema for a given tool, or nil if unknown.
  """
  @spec schema_for_tool(atom()) :: map() | nil
  def schema_for_tool(:add_expense), do: Schema.expense_schema()
  def schema_for_tool(:add_transaction), do: Schema.transaction_schema()
  def schema_for_tool(_), do: nil

  @doc """
  Executes a tool with the given input.

  Returns:
  - `{:guidance, map()}` - Schema guidance for unstructured input
  - `{:ok, record}` - Successfully created record
  - `{:error, term()}` - Validation or execution error
  """
  @spec execute(atom(), map()) :: {:guidance, map()} | {:ok, term()} | {:error, term()}
  def execute(tool_name, input) when tool_name in @supported_tools do
    cond do
      # Phase 1: Unstructured input - return schema guidance
      Map.has_key?(input, "text") ->
        {:guidance, schema_guidance(tool_name)}

      # Phase 2: Structured input - validate and execute
      Map.has_key?(input, "expense") and tool_name == :add_expense ->
        execute_add_expense(input["expense"])

      Map.has_key?(input, "transaction") and tool_name == :add_transaction ->
        execute_add_transaction(input["transaction"])

      true ->
        {:error, "Invalid input format. Expected 'text' for guidance or structured data."}
    end
  end

  def execute(tool_name, _input) do
    {:error, "Unknown tool: #{tool_name}. Supported: #{inspect(@supported_tools)}"}
  end

  # =============================================================================
  # Private: Schema Guidance
  # =============================================================================

  defp schema_guidance(:add_expense), do: Schema.schema_guidance_response(:expense)
  defp schema_guidance(:add_transaction), do: Schema.schema_guidance_response(:transaction)

  # =============================================================================
  # Private: Add Expense Execution
  # =============================================================================

  defp execute_add_expense(data) do
    with :ok <- validate_required(data, ["amount", "category", "date", "description"]),
         {:ok, amount} <- parse_amount(data["amount"]),
         {:ok, date} <- parse_date(data["date"]) do
      create_expense(%{
        amount: amount,
        description: data["description"],
        date: date,
        merchant: data["vendor"] || data["merchant"],
        notes: data["notes"]
      })
    end
  end

  defp create_expense(attrs) do
    case Ash.create(Expense, attrs) do
      {:ok, expense} -> {:ok, expense}
      {:error, changeset} -> {:error, format_ash_errors(changeset)}
    end
  end

  # =============================================================================
  # Private: Add Transaction Execution
  # =============================================================================

  defp execute_add_transaction(data) do
    with :ok <- validate_required(data, ["type", "symbol", "quantity", "price", "date"]),
         {:ok, type} <- parse_transaction_type(data["type"]),
         {:ok, symbol} <- lookup_symbol(data["symbol"]),
         {:ok, quantity} <- parse_quantity(data["quantity"], type),
         {:ok, price} <- parse_amount(data["price"]),
         {:ok, date} <- parse_date(data["date"]),
         {:ok, account} <- resolve_account(data["account"]) do
      total = Decimal.mult(Decimal.abs(quantity), price)

      create_transaction(%{
        type: type,
        symbol_id: symbol.id,
        account_id: account && account.id,
        quantity: quantity,
        price: price,
        total_amount: total,
        fee: Decimal.new("0"),
        date: date
      })
    end
  end

  defp create_transaction(attrs) do
    case Ash.create(Transaction, attrs) do
      {:ok, txn} -> {:ok, txn}
      {:error, changeset} -> {:error, format_ash_errors(changeset)}
    end
  end

  # =============================================================================
  # Private: Validation & Parsing Helpers
  # =============================================================================

  defp validate_required(data, fields) do
    missing = Enum.filter(fields, fn field -> is_nil(data[field]) or data[field] == "" end)

    case missing do
      [] -> :ok
      fields -> {:error, "Missing required fields: #{Enum.join(fields, ", ")}"}
    end
  end

  defp parse_amount(amount_str) do
    AmountParser.parse(amount_str)
  end

  defp parse_date(date_str) when is_binary(date_str) do
    cond do
      # ISO format
      Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, date_str) ->
        Date.from_iso8601(date_str)

      # Relative dates
      String.downcase(date_str) == "today" ->
        {:ok, Date.utc_today()}

      String.downcase(date_str) == "yesterday" ->
        {:ok, Date.add(Date.utc_today(), -1)}

      true ->
        {:error, "Could not parse date: #{date_str}. Use YYYY-MM-DD format."}
    end
  end

  defp parse_date(_), do: {:error, "Date must be a string"}

  defp parse_transaction_type(type_str) when is_binary(type_str) do
    valid_types = ~w(buy sell dividend fee interest liability deposit withdrawal)

    if type_str in valid_types do
      {:ok, String.to_existing_atom(type_str)}
    else
      {:error, "Invalid transaction type: #{type_str}. Must be one of: #{Enum.join(valid_types, ", ")}"}
    end
  end

  defp parse_transaction_type(_), do: {:error, "Transaction type must be a string"}

  defp parse_quantity(quantity_str, type) do
    case AmountParser.parse(quantity_str) do
      {:ok, qty} ->
        # Sells need negative quantity per Transaction validation
        if type == :sell do
          {:ok, Decimal.negate(qty)}
        else
          {:ok, qty}
        end

      error ->
        error
    end
  end

  defp lookup_symbol(symbol_str) when is_binary(symbol_str) do
    ticker = String.upcase(symbol_str)

    query =
      Symbol
      |> Ash.Query.filter(symbol: ticker)
      |> Ash.Query.limit(1)

    case Ash.read(query) do
      {:ok, [found | _]} -> {:ok, found}
      {:ok, []} -> {:error, "Symbol not found: #{symbol_str}"}
      {:error, _} -> {:error, "Symbol not found: #{symbol_str}"}
    end
  end

  defp lookup_symbol(_), do: {:error, "Symbol must be a string"}

  defp resolve_account(nil), do: {:ok, nil}
  defp resolve_account(""), do: {:ok, nil}

  defp resolve_account(account_ref) when is_binary(account_ref) do
    # Try UUID first, then name lookup
    case Ash.get(Account, account_ref) do
      {:ok, account} when not is_nil(account) ->
        {:ok, account}

      _ ->
        # Try by name
        case Ash.read(Account) do
          {:ok, accounts} ->
            account =
              Enum.find(accounts, fn a ->
                String.downcase(a.name) == String.downcase(account_ref)
              end)

            {:ok, account}

          _ ->
            {:ok, nil}
        end
    end
  end

  defp resolve_account(_), do: {:ok, nil}

  defp format_ash_errors(%Ash.Changeset{} = changeset) do
    Enum.map(changeset.errors, fn error ->
      case error do
        %{field: field, message: msg} -> "#{field}: #{msg}"
        %{message: msg} -> msg
        other -> inspect(other)
      end
    end)
  end

  defp format_ash_errors(other), do: inspect(other)
end
