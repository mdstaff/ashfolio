defmodule Ashfolio.Parsing.SchemaTest do
  @moduledoc """
  Tests for the Schema helpers module.

  Schema helpers provide JSON Schema definitions for LLM-assisted structuring
  and validation functions for ensuring structured input matches expectations.
  """
  use Ashfolio.DataCase, async: true

  alias Ashfolio.Parsing.Schema

  describe "expense_schema/0" do
    test "returns a valid JSON schema" do
      schema = Schema.expense_schema()

      assert schema.type == "object"
      assert is_map(schema.properties)
      assert is_list(schema.required)
    end

    test "includes required expense fields" do
      schema = Schema.expense_schema()

      assert "amount" in schema.required
      assert "category" in schema.required
      assert "date" in schema.required
    end

    test "defines amount as string for parsing flexibility" do
      schema = Schema.expense_schema()

      assert schema.properties.amount.type == "string"
    end

    test "includes optional description field" do
      schema = Schema.expense_schema()

      assert Map.has_key?(schema.properties, :description)
      refute "description" in schema.required
    end
  end

  describe "transaction_schema/0" do
    test "returns a valid JSON schema" do
      schema = Schema.transaction_schema()

      assert schema.type == "object"
      assert is_map(schema.properties)
    end

    test "includes required transaction fields" do
      schema = Schema.transaction_schema()

      assert "type" in schema.required
      assert "symbol" in schema.required
      assert "quantity" in schema.required
      assert "price" in schema.required
      assert "date" in schema.required
    end

    test "defines type with enum values matching Transaction resource" do
      schema = Schema.transaction_schema()

      # Must match Ashfolio.Portfolio.Transaction type constraint
      expected = ["buy", "sell", "dividend", "fee", "interest", "liability", "deposit", "withdrawal"]
      assert schema.properties.type.enum == expected
    end
  end

  describe "validate_against_schema/2" do
    test "returns :ok for valid expense data" do
      valid_expense = %{
        "amount" => "$100",
        "category" => "Food",
        "date" => "2024-01-15"
      }

      assert Schema.validate_against_schema(valid_expense, Schema.expense_schema()) == :ok
    end

    test "returns error for missing required field" do
      invalid_expense = %{
        "amount" => "$100",
        "category" => "Food"
        # missing date
      }

      assert {:error, errors} = Schema.validate_against_schema(invalid_expense, Schema.expense_schema())
      assert Enum.any?(errors, &String.contains?(&1, "date"))
    end

    test "returns error for wrong type" do
      invalid_expense = %{
        # should be string
        "amount" => 100,
        "category" => "Food",
        "date" => "2024-01-15"
      }

      assert {:error, errors} = Schema.validate_against_schema(invalid_expense, Schema.expense_schema())
      assert Enum.any?(errors, &String.contains?(&1, "amount"))
    end

    test "returns :ok for valid transaction data" do
      valid_transaction = %{
        "type" => "buy",
        "symbol" => "AAPL",
        "quantity" => "10",
        "price" => "$150.00",
        "date" => "2024-01-15"
      }

      assert Schema.validate_against_schema(valid_transaction, Schema.transaction_schema()) == :ok
    end

    test "returns error for invalid transaction type" do
      invalid_transaction = %{
        "type" => "invalid",
        "symbol" => "AAPL",
        "quantity" => "10",
        "price" => "$150.00",
        "date" => "2024-01-15"
      }

      assert {:error, errors} = Schema.validate_against_schema(invalid_transaction, Schema.transaction_schema())
      assert Enum.any?(errors, &String.contains?(&1, "type"))
    end
  end

  describe "schema_to_example/1" do
    test "generates example for expense schema" do
      example = Schema.schema_to_example(Schema.expense_schema())

      assert is_map(example)
      assert Map.has_key?(example, "amount")
      assert Map.has_key?(example, "category")
      assert Map.has_key?(example, "date")
    end

    test "generates example for transaction schema" do
      example = Schema.schema_to_example(Schema.transaction_schema())

      assert is_map(example)
      assert example["type"] in ["buy", "sell", "dividend"]
      assert Map.has_key?(example, "symbol")
    end
  end

  describe "schema_guidance_response/1" do
    test "returns structured guidance for expense schema" do
      response = Schema.schema_guidance_response(:expense)

      assert Map.has_key?(response, :needs_structure)
      assert response.needs_structure == true
      assert Map.has_key?(response, :schema)
      assert Map.has_key?(response, :example)
      assert Map.has_key?(response, :instructions)
    end

    test "returns structured guidance for transaction schema" do
      response = Schema.schema_guidance_response(:transaction)

      assert response.needs_structure == true
      assert response.schema.type == "object"
    end

    test "returns error for unknown schema type" do
      assert {:error, _} = Schema.schema_guidance_response(:unknown)
    end
  end
end
