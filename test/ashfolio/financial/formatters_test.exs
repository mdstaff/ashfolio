defmodule Ashfolio.Financial.FormattersTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Financial.Formatters

  doctest Formatters

  describe "currency/2 - unified API" do
    test "formats decimal with default options" do
      assert Formatters.currency(Decimal.new("1234.56")) == "$1,234.56"
    end

    test "handles show_cents option" do
      assert Formatters.currency(Decimal.new("1234.56"), show_cents: false) == "$1,235"
      assert Formatters.currency(Decimal.new("1234.56"), show_cents: true) == "$1,234.56"
    end

    test "handles comma_formatting option" do
      assert Formatters.currency(Decimal.new("1234.56"), comma_formatting: false) == "$1234.56"
      assert Formatters.currency(Decimal.new("1234.56"), comma_formatting: true) == "$1,234.56"
    end

    test "handles handle_negative option" do
      assert Formatters.currency(Decimal.new("-123.45")) == "-$123.45"
      assert Formatters.currency(Decimal.new("-123.45"), handle_negative: false) == "$123.45"
    end

    test "handles currency_symbol option" do
      assert Formatters.currency(Decimal.new("123.45"), currency_symbol: "€") == "€123.45"
      assert Formatters.currency(Decimal.new("123.45"), currency_symbol: "£") == "£123.45"
    end

    test "handles fallback option" do
      assert Formatters.currency(nil, fallback: "N/A") == "N/A"
      assert Formatters.currency("invalid", fallback: "--") == "--"
    end

    test "handles nil and invalid inputs" do
      assert Formatters.currency(nil) == "$0.00"
      assert Formatters.currency("invalid") == "$0.00"
      assert Formatters.currency(:invalid) == "$0.00"
    end

    test "handles integer values" do
      assert Formatters.currency(1234) == "$1,234.00"
      assert Formatters.currency(-567) == "-$567.00"
    end

    test "handles float values" do
      assert Formatters.currency(1234.56) == "$1,234.56"
      assert Formatters.currency(-123.45) == "-$123.45"
    end

    test "handles zero values" do
      assert Formatters.currency(Decimal.new("0")) == "$0.00"
      assert Formatters.currency(0) == "$0.00"
      assert Formatters.currency(0.0) == "$0.00"
    end

    test "handles large values with proper comma formatting" do
      assert Formatters.currency(Decimal.new("1234567.89")) == "$1,234,567.89"
      assert Formatters.currency(Decimal.new("1234567890.12")) == "$1,234,567,890.12"
    end

    test "handles small decimal values" do
      assert Formatters.currency(Decimal.new("0.01")) == "$0.01"
      assert Formatters.currency(Decimal.new("0.99")) == "$0.99"
    end

    test "rounds correctly when show_cents is false" do
      assert Formatters.currency(Decimal.new("123.45"), show_cents: false) == "$123"
      assert Formatters.currency(Decimal.new("123.50"), show_cents: false) == "$124"
      assert Formatters.currency(Decimal.new("123.49"), show_cents: false) == "$123"
    end
  end

  describe "format_currency_classic/1 - format_helper.ex compatibility" do
    test "matches format_helper.ex behavior" do
      # Test against known expected outputs from current implementation
      assert Formatters.format_currency_classic(Decimal.new("1234.56")) == "$1,234.56"
      assert Formatters.format_currency_classic(Decimal.new("1000")) == "$1,000.00"
      assert Formatters.format_currency_classic(nil) == "$0.00"
    end

    test "handles numeric conversion like format_helper.ex" do
      assert Formatters.format_currency_classic(1234.56) == "$1,234.56"
      assert Formatters.format_currency_classic(1000) == "$1,000.00"
    end

    test "always shows cents and commas" do
      assert Formatters.format_currency_classic(Decimal.new("1000")) == "$1,000.00"
      assert Formatters.format_currency_classic(Decimal.new("1")) == "$1.00"
    end

    test "handles edge cases like format_helper.ex" do
      assert Formatters.format_currency_classic(Decimal.new("0")) == "$0.00"
      assert Formatters.format_currency_classic(nil) == "$0.00"
    end
  end

  describe "format_currency_with_cents/2 - format_helpers.ex compatibility" do
    test "matches format_helpers.ex behavior with show_cents=true" do
      assert Formatters.format_currency_with_cents(Decimal.new("1234.56"), true) == "$1,234.56"
      assert Formatters.format_currency_with_cents(Decimal.new("1000"), true) == "$1,000.00"
    end

    test "matches format_helpers.ex behavior with show_cents=false" do
      assert Formatters.format_currency_with_cents(Decimal.new("1234.56"), false) == "$1,235"
      assert Formatters.format_currency_with_cents(Decimal.new("1000"), false) == "$1,000"
    end

    test "handles negative values like format_helpers.ex" do
      assert Formatters.format_currency_with_cents(Decimal.new("-123.45"), true) == "-$123.45"
      assert Formatters.format_currency_with_cents(Decimal.new("-123.45"), false) == "-$123"
    end

    test "defaults to show_cents=true" do
      assert Formatters.format_currency_with_cents(Decimal.new("123.45")) == "$123.45"
    end

    test "handles various input types like format_helpers.ex" do
      assert Formatters.format_currency_with_cents(123, true) == "$123.00"
      assert Formatters.format_currency_with_cents(123.45, true) == "$123.45"
      assert Formatters.format_currency_with_cents(nil, true) == "$0.00"
    end
  end

  describe "format_currency_simple/1 - chart_helpers.ex compatibility" do
    test "matches chart_helpers.ex behavior" do
      # Chart helpers: no comma formatting, basic behavior
      assert Formatters.format_currency_simple(Decimal.new("1234.56")) == "$1234.56"
      assert Formatters.format_currency_simple(123.45) == "$123.45"
    end

    test "no comma formatting like chart_helpers.ex" do
      assert Formatters.format_currency_simple(Decimal.new("1000000")) == "$1000000.00"
      assert Formatters.format_currency_simple(12_345) == "$12345.00"
    end

    test "handles basic fallback" do
      assert Formatters.format_currency_simple(nil) == "$0.00"
      assert Formatters.format_currency_simple("invalid") == "$0.00"
    end

    test "special negative format ($-123.45) like chart helpers" do
      # Chart helpers behavior: uses $-123.45 format for negatives
      assert Formatters.format_currency_simple(Decimal.new("-123.45")) == "$-123.45"
    end
  end

  describe "thousands separator formatting" do
    test "handles various number sizes" do
      assert Formatters.currency(Decimal.new("123")) == "$123.00"
      assert Formatters.currency(Decimal.new("1234")) == "$1,234.00"
      assert Formatters.currency(Decimal.new("12345")) == "$12,345.00"
      assert Formatters.currency(Decimal.new("123456")) == "$123,456.00"
      assert Formatters.currency(Decimal.new("1234567")) == "$1,234,567.00"
      assert Formatters.currency(Decimal.new("12345678")) == "$12,345,678.00"
    end

    test "handles decimal values with comma separation" do
      assert Formatters.currency(Decimal.new("1234.56")) == "$1,234.56"
      assert Formatters.currency(Decimal.new("123456.78")) == "$123,456.78"
    end

    test "handles edge cases" do
      assert Formatters.currency(Decimal.new("1.00")) == "$1.00"
      assert Formatters.currency(Decimal.new("12.00")) == "$12.00"
      assert Formatters.currency(Decimal.new("123.00")) == "$123.00"
    end
  end

  describe "decimal precision and rounding" do
    test "rounds to 2 decimal places when show_cents=true" do
      assert Formatters.currency(Decimal.new("123.456")) == "$123.46"
      assert Formatters.currency(Decimal.new("123.454")) == "$123.45"
    end

    test "rounds to whole number when show_cents=false" do
      assert Formatters.currency(Decimal.new("123.4"), show_cents: false) == "$123"
      assert Formatters.currency(Decimal.new("123.5"), show_cents: false) == "$124"
      assert Formatters.currency(Decimal.new("123.6"), show_cents: false) == "$124"
    end

    test "handles very precise decimal values" do
      assert Formatters.currency(Decimal.new("123.123456789")) == "$123.12"
      assert Formatters.currency(Decimal.new("123.999")) == "$124.00"
    end
  end

  describe "option combinations" do
    test "all options disabled" do
      result =
        Formatters.currency(
          Decimal.new("-1234.56"),
          show_cents: false,
          comma_formatting: false,
          handle_negative: false,
          currency_symbol: ""
        )

      assert result == "1235"
    end

    test "custom combinations" do
      result =
        Formatters.currency(
          Decimal.new("1234.56"),
          show_cents: false,
          currency_symbol: "€",
          comma_formatting: true
        )

      assert result == "€1,235"
    end

    test "mixed option scenarios" do
      # European-style formatting
      result =
        Formatters.currency(
          Decimal.new("1234.56"),
          currency_symbol: "€"
        )

      assert result == "€1,234.56"

      # No decimals, no commas (simple integer display)
      result =
        Formatters.currency(
          Decimal.new("1234.56"),
          show_cents: false,
          comma_formatting: false
        )

      assert result == "$1235"
    end
  end

  describe "error conditions and edge cases" do
    test "handles various invalid inputs gracefully" do
      invalid_inputs = [
        "not_a_number",
        :atom,
        %{not: "decimal"},
        [],
        {:tuple, :value}
      ]

      for input <- invalid_inputs do
        assert Formatters.currency(input) == "$0.00"
      end
    end

    test "handles very large numbers" do
      large_decimal = Decimal.new("999999999999999.99")
      assert Formatters.currency(large_decimal) == "$999,999,999,999,999.99"
    end

    test "handles very small numbers" do
      small_decimal = Decimal.new("0.001")
      assert Formatters.currency(small_decimal) == "$0.00"
    end
  end
end
