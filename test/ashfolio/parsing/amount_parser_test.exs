defmodule Ashfolio.Parsing.AmountParserTest do
  @moduledoc """
  Tests for the AmountParser module.

  The AmountParser handles various monetary amount formats:
  - Basic numbers: 100, 1000.50
  - Currency prefixes: $100, EUR 500
  - Thousands separators: 1,000.00
  - Abbreviations: 10k, 1.5M, 2B
  - Ranges (returns midpoint): $50-100
  - Negative amounts: -$100, ($500)
  """
  use Ashfolio.DataCase, async: true

  alias Ashfolio.Parsing.AmountParser

  # Helper to compare Decimal values (handles different representations like 1500 vs 1500.0)
  defp assert_decimal_equal({:ok, actual}, expected) do
    assert Decimal.equal?(actual, Decimal.new(expected)),
           "Expected #{expected}, got #{Decimal.to_string(actual)}"
  end

  describe "parse/1 with basic numbers" do
    test "parses integer" do
      assert_decimal_equal(AmountParser.parse("100"), "100")
    end

    test "parses decimal" do
      assert_decimal_equal(AmountParser.parse("100.50"), "100.50")
    end

    test "parses decimal with leading zero" do
      assert_decimal_equal(AmountParser.parse("0.99"), "0.99")
    end

    test "parses large number" do
      assert_decimal_equal(AmountParser.parse("1000000"), "1000000")
    end
  end

  describe "parse/1 with currency symbols" do
    test "parses dollar sign prefix" do
      assert_decimal_equal(AmountParser.parse("$100"), "100")
    end

    test "parses dollar sign with decimal" do
      assert_decimal_equal(AmountParser.parse("$1,234.56"), "1234.56")
    end

    test "parses euro prefix" do
      assert_decimal_equal(AmountParser.parse("EUR 500"), "500")
    end

    test "parses euro symbol" do
      assert_decimal_equal(AmountParser.parse("€500"), "500")
    end

    test "parses pound symbol" do
      assert_decimal_equal(AmountParser.parse("£250"), "250")
    end

    test "parses yen symbol" do
      assert_decimal_equal(AmountParser.parse("¥10000"), "10000")
    end
  end

  describe "parse/1 with thousands separators" do
    test "parses comma-separated thousands" do
      assert_decimal_equal(AmountParser.parse("1,000"), "1000")
    end

    test "parses multiple comma separators" do
      assert_decimal_equal(AmountParser.parse("1,234,567"), "1234567")
    end

    test "parses comma with decimal" do
      assert_decimal_equal(AmountParser.parse("1,234.56"), "1234.56")
    end

    test "parses currency with thousands" do
      assert_decimal_equal(AmountParser.parse("$10,000.00"), "10000.00")
    end
  end

  describe "parse/1 with abbreviations" do
    test "parses lowercase k (thousands)" do
      assert_decimal_equal(AmountParser.parse("10k"), "10000")
    end

    test "parses uppercase K (thousands)" do
      assert_decimal_equal(AmountParser.parse("10K"), "10000")
    end

    test "parses k with decimal" do
      assert_decimal_equal(AmountParser.parse("1.5k"), "1500")
    end

    test "parses k with currency" do
      assert_decimal_equal(AmountParser.parse("$85k"), "85000")
    end

    test "parses lowercase m (millions)" do
      assert_decimal_equal(AmountParser.parse("1m"), "1000000")
    end

    test "parses uppercase M (millions)" do
      assert_decimal_equal(AmountParser.parse("2.5M"), "2500000")
    end

    test "parses M with currency" do
      assert_decimal_equal(AmountParser.parse("$1.2M"), "1200000")
    end

    test "parses lowercase b (billions)" do
      assert_decimal_equal(AmountParser.parse("1b"), "1000000000")
    end

    test "parses uppercase B (billions)" do
      assert_decimal_equal(AmountParser.parse("2B"), "2000000000")
    end
  end

  describe "parse/1 with ranges" do
    test "parses range with hyphen, returns midpoint" do
      assert_decimal_equal(AmountParser.parse("50-100"), "75")
    end

    test "parses range with currency" do
      assert_decimal_equal(AmountParser.parse("$50-100"), "75")
    end

    test "parses range with 'to'" do
      assert_decimal_equal(AmountParser.parse("50 to 100"), "75")
    end

    test "parses range with both currency symbols" do
      assert_decimal_equal(AmountParser.parse("$1,000-$2,000"), "1500")
    end
  end

  describe "parse/1 with negative amounts" do
    test "parses negative with minus sign" do
      assert_decimal_equal(AmountParser.parse("-100"), "-100")
    end

    test "parses negative with currency" do
      assert_decimal_equal(AmountParser.parse("-$50.00"), "-50.00")
    end

    test "parses parentheses as negative (accounting notation)" do
      assert_decimal_equal(AmountParser.parse("($500)"), "-500")
    end

    test "parses parentheses with comma" do
      assert_decimal_equal(AmountParser.parse("($1,234.56)"), "-1234.56")
    end
  end

  describe "parse/1 with whitespace" do
    test "trims leading whitespace" do
      assert_decimal_equal(AmountParser.parse("  100"), "100")
    end

    test "trims trailing whitespace" do
      assert_decimal_equal(AmountParser.parse("100  "), "100")
    end

    test "handles space after currency" do
      assert_decimal_equal(AmountParser.parse("$ 100"), "100")
    end
  end

  describe "parse/1 error cases" do
    test "returns error for empty string" do
      assert {:error, _} = AmountParser.parse("")
    end

    test "returns error for non-numeric" do
      assert {:error, _} = AmountParser.parse("abc")
    end

    test "returns error for nil" do
      assert {:error, _} = AmountParser.parse(nil)
    end

    test "returns error for invalid format" do
      assert {:error, _} = AmountParser.parse("$$$")
    end
  end

  describe "Parseable behaviour compliance" do
    test "implements name/0" do
      assert AmountParser.name() == "parse_amount"
    end

    test "implements description/0" do
      assert is_binary(AmountParser.description())
    end

    test "implements input_schema/0" do
      schema = AmountParser.input_schema()
      assert is_map(schema)
      assert schema.type == "object"
    end

    test "implements validate/1" do
      assert AmountParser.validate(%{"amount" => "$100"}) == :ok
      assert {:error, _} = AmountParser.validate(%{})
    end

    test "implements execute/1" do
      assert {:ok, %Decimal{}} = AmountParser.execute(%{"amount" => "$100"})
    end

    test "implements can_quick_parse?/1" do
      assert AmountParser.can_quick_parse?("$100") == true
      assert AmountParser.can_quick_parse?(%{}) == false
    end

    test "implements quick_parse/1" do
      assert {:ok, %Decimal{}} = AmountParser.quick_parse("$100")
    end

    test "works with Parseable.parse/2" do
      alias Ashfolio.Parsing.Parseable

      # Quick parse path
      assert {:ok, %Decimal{}} = Parseable.parse(AmountParser, "$100")

      # Standard path
      assert {:ok, %Decimal{}} = Parseable.parse(AmountParser, %{"amount" => "$100"})
    end
  end
end
