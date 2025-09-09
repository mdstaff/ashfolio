defmodule AshfolioWeb.FormHelpersTest do
  use ExUnit.Case, async: true

  alias AshfolioWeb.FormHelpers

  doctest FormHelpers

  describe "parse_decimal/1" do
    test "parses valid decimal strings" do
      assert {:ok, decimal} = FormHelpers.parse_decimal("100.50")
      assert Decimal.equal?(decimal, Decimal.new("100.50"))
    end

    test "handles empty values" do
      assert {:ok, nil} = FormHelpers.parse_decimal("")
      assert {:ok, nil} = FormHelpers.parse_decimal(nil)
    end

    test "handles formatted numbers with commas" do
      assert {:ok, decimal} = FormHelpers.parse_decimal("1,234.56")
      assert Decimal.equal?(decimal, Decimal.new("1234.56"))
    end

    test "handles currency symbols" do
      assert {:ok, decimal} = FormHelpers.parse_decimal("$100.50")
      assert Decimal.equal?(decimal, Decimal.new("100.50"))
    end

    test "returns error for invalid input" do
      assert {:error, :invalid_decimal} = FormHelpers.parse_decimal("invalid")
      assert {:error, :invalid_decimal} = FormHelpers.parse_decimal("12.34.56")
    end

    test "passes through Decimal values" do
      decimal = Decimal.new("100")
      assert {:ok, ^decimal} = FormHelpers.parse_decimal(decimal)
    end
  end

  describe "parse_decimal_unsafe/1" do
    test "returns decimal for valid input" do
      assert decimal = FormHelpers.parse_decimal_unsafe("100.50")
      assert Decimal.equal?(decimal, Decimal.new("100.50"))
    end

    test "returns nil for invalid input" do
      assert nil == FormHelpers.parse_decimal_unsafe("invalid")
      assert nil == FormHelpers.parse_decimal_unsafe("")
    end
  end

  describe "parse_decimal_fields/2" do
    test "parses specified decimal fields in params" do
      params = %{
        "amount" => "100.50",
        "fee" => "5",
        "name" => "Transaction"
      }

      result = FormHelpers.parse_decimal_fields(params, ["amount", "fee"])

      assert Decimal.equal?(result["amount"], Decimal.new("100.50"))
      assert Decimal.equal?(result["fee"], Decimal.new("5"))
      assert result["name"] == "Transaction"
    end

    test "skips missing fields" do
      params = %{"amount" => "100"}
      result = FormHelpers.parse_decimal_fields(params, ["amount", "missing_field"])

      assert Decimal.equal?(result["amount"], Decimal.new("100"))
      refute Map.has_key?(result, "missing_field")
    end
  end

  describe "parse_date/1" do
    test "parses valid ISO date strings" do
      assert {:ok, ~D[2024-01-15]} = FormHelpers.parse_date("2024-01-15")
    end

    test "handles empty values" do
      assert {:ok, nil} = FormHelpers.parse_date("")
      assert {:ok, nil} = FormHelpers.parse_date(nil)
    end

    test "returns error for invalid dates" do
      assert {:error, :invalid_date} = FormHelpers.parse_date("invalid")
      assert {:error, :invalid_date} = FormHelpers.parse_date("2024-13-45")
    end

    test "passes through Date values" do
      date = ~D[2024-01-15]
      assert {:ok, ^date} = FormHelpers.parse_date(date)
    end
  end

  describe "parse_percentage/1" do
    test "parses percentage with % symbol" do
      assert {:ok, decimal} = FormHelpers.parse_percentage("7.5%")
      assert Decimal.equal?(decimal, Decimal.new("0.075"))
    end

    test "parses percentage without % symbol" do
      assert {:ok, decimal} = FormHelpers.parse_percentage("7.5")
      assert Decimal.equal?(decimal, Decimal.new("0.075"))
    end

    test "handles decimal format (0.075)" do
      assert {:ok, decimal} = FormHelpers.parse_percentage("0.075")
      assert Decimal.equal?(decimal, Decimal.new("0.075"))
    end

    test "handles empty values" do
      assert {:ok, nil} = FormHelpers.parse_percentage("")
      assert {:ok, nil} = FormHelpers.parse_percentage(nil)
    end

    test "returns error for invalid input" do
      assert {:error, :invalid_decimal} = FormHelpers.parse_percentage("invalid")
    end
  end

  describe "parse_integer/1" do
    test "parses valid integer strings" do
      assert {:ok, 42} = FormHelpers.parse_integer("42")
      assert {:ok, -10} = FormHelpers.parse_integer("-10")
    end

    test "handles empty values" do
      assert {:ok, nil} = FormHelpers.parse_integer("")
      assert {:ok, nil} = FormHelpers.parse_integer(nil)
    end

    test "returns error for invalid input" do
      assert {:error, :invalid_integer} = FormHelpers.parse_integer("invalid")
      assert {:error, :invalid_integer} = FormHelpers.parse_integer("12.34")
    end

    test "passes through integer values" do
      assert {:ok, 42} = FormHelpers.parse_integer(42)
    end
  end

  describe "validate_positive/1" do
    test "validates positive decimals" do
      assert :ok = FormHelpers.validate_positive(Decimal.new("100"))
      assert :ok = FormHelpers.validate_positive(Decimal.new("0.01"))
    end

    test "rejects zero and negative values" do
      assert {:error, "must be positive"} = FormHelpers.validate_positive(Decimal.new("0"))
      assert {:error, "must be positive"} = FormHelpers.validate_positive(Decimal.new("-10"))
    end

    test "requires non-nil value" do
      assert {:error, "is required"} = FormHelpers.validate_positive(nil)
    end
  end

  describe "validate_non_negative/1" do
    test "validates non-negative decimals" do
      assert :ok = FormHelpers.validate_non_negative(Decimal.new("100"))
      assert :ok = FormHelpers.validate_non_negative(Decimal.new("0"))
    end

    test "rejects negative values" do
      assert {:error, "cannot be negative"} = FormHelpers.validate_non_negative(Decimal.new("-10"))
    end

    test "allows nil values" do
      assert {:ok, nil} = FormHelpers.validate_non_negative(nil)
    end
  end

  describe "empty_to_nil/1" do
    test "converts empty strings to nil" do
      assert nil == FormHelpers.empty_to_nil("")
      assert nil == FormHelpers.empty_to_nil("   ")
    end

    test "preserves non-empty strings" do
      assert "value" == FormHelpers.empty_to_nil("value")
      assert "  trimmed  " == FormHelpers.empty_to_nil("  trimmed  ")
    end

    test "passes through non-string values" do
      assert 42 == FormHelpers.empty_to_nil(42)
      assert nil == FormHelpers.empty_to_nil(nil)
    end
  end

  describe "build_error_messages/1" do
    test "builds error message map from keyword list" do
      errors = [
        amount: {"must be positive", []},
        date: {"is required", []}
      ]

      result = FormHelpers.build_error_messages(errors)

      assert result == %{
               amount: "must be positive",
               date: "is required"
             }
    end

    test "handles simple string messages" do
      errors = [
        amount: "must be positive",
        date: "is required"
      ]

      result = FormHelpers.build_error_messages(errors)

      assert result == %{
               amount: "must be positive",
               date: "is required"
             }
    end

    test "returns empty map for invalid input" do
      assert %{} == FormHelpers.build_error_messages(nil)
      assert %{} == FormHelpers.build_error_messages([])
    end
  end

  describe "validate_required_fields/2" do
    test "validates all required fields are present" do
      params = %{
        "name" => "Test",
        "amount" => "100",
        "date" => "2024-01-15"
      }

      assert :ok = FormHelpers.validate_required_fields(params, ["name", "amount"])
    end

    test "returns errors for missing fields" do
      params = %{
        "name" => "Test",
        "amount" => ""
      }

      assert {:error, errors} = FormHelpers.validate_required_fields(params, ["name", "amount", "date"])
      assert "Amount is required" in errors
      assert "Date is required" in errors
    end

    test "handles nil values as missing" do
      params = %{
        "name" => nil,
        "amount" => "100"
      }

      assert {:error, errors} = FormHelpers.validate_required_fields(params, ["name", "amount"])
      assert "Name is required" in errors
    end
  end

  describe "validate_form/3" do
    test "validates form with required fields and custom validators" do
      params = %{
        "amount" => "100",
        "date" => "2024-01-15"
      }

      validators = %{
        "amount" => fn value ->
          decimal = FormHelpers.parse_decimal_unsafe(value)
          FormHelpers.validate_positive(decimal)
        end
      }

      {valid?, errors, messages} = FormHelpers.validate_form(params, ["amount", "date"], validators)

      assert valid?
      assert errors == []
      assert messages == %{}
    end

    test "collects all validation errors" do
      params = %{
        "amount" => "-10",
        "date" => ""
      }

      validators = %{
        "amount" => fn value ->
          decimal = FormHelpers.parse_decimal_unsafe(value)
          FormHelpers.validate_positive(decimal)
        end
      }

      {valid?, errors, messages} = FormHelpers.validate_form(params, ["amount", "date"], validators)

      refute valid?
      assert "Date is required" in errors
      assert "Amount must be positive" in errors
      assert messages[:amount] == "must be positive"
    end
  end

  describe "calculate_transaction_total/3" do
    test "calculates total with quantity, price, and fee" do
      total = FormHelpers.calculate_transaction_total("10", "50.25", "2.50")
      assert Decimal.equal?(total, Decimal.new("505.00"))
    end

    test "calculates total without fee" do
      total = FormHelpers.calculate_transaction_total("10", "50.25", nil)
      assert Decimal.equal?(total, Decimal.new("502.50"))
    end

    test "handles invalid input gracefully" do
      total = FormHelpers.calculate_transaction_total("invalid", "50", "2")
      assert Decimal.equal?(total, Decimal.new("2"))
    end
  end

  describe "format_currency/1" do
    test "formats decimal as currency" do
      assert "$1,234.56" = FormHelpers.format_currency(Decimal.new("1234.56"))
      assert "$100.00" = FormHelpers.format_currency(Decimal.new("100"))
      assert "$0.50" = FormHelpers.format_currency(Decimal.new("0.50"))
    end

    test "handles large numbers with commas" do
      assert "$1,234,567.89" = FormHelpers.format_currency(Decimal.new("1234567.89"))
    end

    test "handles nil values" do
      assert "$0.00" = FormHelpers.format_currency(nil)
    end
  end

  describe "format_percentage/1" do
    test "formats decimal as percentage" do
      assert "7.50%" = FormHelpers.format_percentage(Decimal.new("0.075"))
      assert "100.00%" = FormHelpers.format_percentage(Decimal.new("1"))
      assert "0.50%" = FormHelpers.format_percentage(Decimal.new("0.005"))
    end

    test "handles nil values" do
      assert "0.00%" = FormHelpers.format_percentage(nil)
    end
  end
end
