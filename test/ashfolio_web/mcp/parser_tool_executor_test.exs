defmodule AshfolioWeb.Mcp.ParserToolExecutorTest do
  @moduledoc """
  Tests for the Parser Tool Executor.

  The executor handles the two-phase MCP flow:
  1. Unstructured input -> Returns schema guidance
  2. Structured input -> Validates and executes
  """
  use Ashfolio.DataCase, async: true

  alias Ashfolio.Parsing.Schema
  alias AshfolioWeb.Mcp.ParserToolExecutor

  @moduletag :mcp

  describe "execute/3 with unstructured input" do
    test "returns schema guidance when input has 'text' field" do
      input = %{"text" => "rent $1800"}

      result = ParserToolExecutor.execute(:add_expense, input)

      assert {:guidance, guidance} = result
      assert guidance.needs_structure == true
      assert is_map(guidance.schema)
      assert is_map(guidance.example)
      assert is_binary(guidance.instructions)
    end

    test "returns schema guidance for transaction tool" do
      input = %{"text" => "bought 10 AAPL at 150"}

      result = ParserToolExecutor.execute(:add_transaction, input)

      assert {:guidance, guidance} = result
      assert guidance.needs_structure == true
      assert "type" in guidance.schema.required
    end

    test "returns error for unknown tool" do
      input = %{"text" => "something"}

      result = ParserToolExecutor.execute(:unknown_tool, input)

      assert {:error, message} = result
      assert message =~ "Unknown tool"
    end
  end

  describe "execute/3 with structured expense input" do
    test "validates and creates expense with valid data" do
      input = %{
        "expense" => %{
          "amount" => "$1,800",
          "category" => "Housing",
          "date" => "2024-01-15",
          "description" => "Monthly rent"
        }
      }

      result = ParserToolExecutor.execute(:add_expense, input)

      assert {:ok, expense} = result
      assert Decimal.equal?(expense.amount, Decimal.new("1800"))
      assert expense.description == "Monthly rent"
      assert expense.date == ~D[2024-01-15]
    end

    test "validates and creates expense with minimal data" do
      input = %{
        "expense" => %{
          "amount" => "50",
          "category" => "Food",
          "date" => "2024-01-15",
          "description" => "Lunch"
        }
      }

      result = ParserToolExecutor.execute(:add_expense, input)

      assert {:ok, expense} = result
      assert Decimal.equal?(expense.amount, Decimal.new("50"))
    end

    test "parses amounts with abbreviations" do
      input = %{
        "expense" => %{
          "amount" => "1.5k",
          "category" => "Travel",
          "date" => "2024-01-15",
          "description" => "Flight tickets"
        }
      }

      result = ParserToolExecutor.execute(:add_expense, input)

      assert {:ok, expense} = result
      assert Decimal.equal?(expense.amount, Decimal.new("1500"))
    end

    test "returns validation error for missing required field" do
      input = %{
        "expense" => %{
          "amount" => "$100",
          "category" => "Food"
          # missing date and description
        }
      }

      result = ParserToolExecutor.execute(:add_expense, input)

      assert {:error, errors} = result
      assert is_list(errors) or is_binary(errors)
    end

    test "returns error for invalid amount format" do
      input = %{
        "expense" => %{
          "amount" => "not-a-number",
          "category" => "Food",
          "date" => "2024-01-15",
          "description" => "Test"
        }
      }

      result = ParserToolExecutor.execute(:add_expense, input)

      assert {:error, _} = result
    end
  end

  describe "execute/3 with structured transaction input" do
    test "validates and creates buy transaction" do
      # First create a symbol and account for the transaction
      {:ok, symbol} =
        Ash.create(Ashfolio.Portfolio.Symbol, %{
          symbol: "TEST",
          name: "Test Stock",
          asset_class: :stock,
          data_source: :manual
        })

      {:ok, account} =
        Ash.create(Ashfolio.Portfolio.Account, %{
          name: "Test Account",
          account_type: :investment,
          platform: "Test",
          balance: Decimal.new("10000")
        })

      input = %{
        "transaction" => %{
          "type" => "buy",
          "symbol" => "TEST",
          "quantity" => "10",
          "price" => "$150",
          "date" => "2024-01-15",
          "account" => account.id
        }
      }

      result = ParserToolExecutor.execute(:add_transaction, input)

      assert {:ok, transaction} = result
      assert transaction.type == :buy
      assert Decimal.equal?(transaction.quantity, Decimal.new("10"))
      assert Decimal.equal?(transaction.price, Decimal.new("150"))
    end
  end

  describe "schema_for_tool/1" do
    test "returns expense schema for add_expense" do
      schema = ParserToolExecutor.schema_for_tool(:add_expense)
      assert schema == Schema.expense_schema()
    end

    test "returns transaction schema for add_transaction" do
      schema = ParserToolExecutor.schema_for_tool(:add_transaction)
      assert schema == Schema.transaction_schema()
    end

    test "returns nil for unknown tool" do
      assert ParserToolExecutor.schema_for_tool(:unknown) == nil
    end
  end

  describe "supported_tools/0" do
    test "returns list of supported tool names" do
      tools = ParserToolExecutor.supported_tools()

      assert :add_expense in tools
      assert :add_transaction in tools
    end
  end
end
