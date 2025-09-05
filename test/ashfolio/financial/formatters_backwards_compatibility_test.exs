defmodule Ashfolio.Financial.FormattersBackwardsCompatibilityTest do
  @moduledoc """
  Backwards compatibility tests to ensure our unified formatter produces
  identical outputs to the existing implementations we're consolidating.

  This test suite validates against the actual current implementations in:
  - lib/ashfolio_web/helpers/format_helper.ex
  - lib/ashfolio_web/live/format_helpers.ex
  - lib/ashfolio_web/helpers/chart_helpers.ex
  """

  use ExUnit.Case, async: true

  alias Ashfolio.Financial.Formatters
  alias AshfolioWeb.Helpers.ChartHelpers
  alias AshfolioWeb.Helpers.FormatHelper
  alias AshfolioWeb.Live.FormatHelpers

  describe "format_helper.ex backwards compatibility" do
    test "identical behavior for decimal values" do
      test_values = [
        Decimal.new("1234.56"),
        Decimal.new("1000.00"),
        Decimal.new("0.99"),
        Decimal.new("123456789.12"),
        Decimal.new("0"),
        Decimal.new("1")
      ]

      for value <- test_values do
        expected = FormatHelper.format_currency(value)
        actual = Formatters.format_currency_classic(value)

        assert actual == expected,
               "Mismatch for #{inspect(value)}: expected '#{expected}', got '#{actual}'"
      end
    end

    test "identical behavior for numeric values" do
      test_values = [1234.56, 1000.0, 0.99, 123_456_789.12, 0, 1]

      for value <- test_values do
        expected = FormatHelper.format_currency(value)
        actual = Formatters.format_currency_classic(value)

        assert actual == expected,
               "Mismatch for #{inspect(value)}: expected '#{expected}', got '#{actual}'"
      end
    end

    test "identical behavior for nil and edge cases" do
      edge_cases = [nil]

      for value <- edge_cases do
        expected = FormatHelper.format_currency(value)
        actual = Formatters.format_currency_classic(value)

        assert actual == expected,
               "Mismatch for #{inspect(value)}: expected '#{expected}', got '#{actual}'"
      end
    end
  end

  describe "format_helpers.ex backwards compatibility" do
    test "identical behavior with show_cents=true" do
      test_values = [
        Decimal.new("1234.56"),
        Decimal.new("-123.45"),
        Decimal.new("1000.00"),
        Decimal.new("0.01"),
        123,
        123.45,
        -456.78
      ]

      for value <- test_values do
        expected = FormatHelpers.format_currency(value, true)
        actual = Formatters.format_currency_with_cents(value, true)

        assert actual == expected,
               "Mismatch for #{inspect(value)} with show_cents=true: expected '#{expected}', got '#{actual}'"
      end
    end

    test "identical behavior with show_cents=false" do
      test_values = [
        Decimal.new("1234.56"),
        Decimal.new("-123.45"),
        Decimal.new("1000.00"),
        Decimal.new("123.49"),
        Decimal.new("123.50"),
        123,
        123.45
      ]

      for value <- test_values do
        expected = FormatHelpers.format_currency(value, false)
        actual = Formatters.format_currency_with_cents(value, false)

        assert actual == expected,
               "Mismatch for #{inspect(value)} with show_cents=false: expected '#{expected}', got '#{actual}'"
      end
    end

    test "identical behavior with default show_cents parameter" do
      test_values = [
        Decimal.new("1234.56"),
        Decimal.new("-123.45"),
        123.45
      ]

      for value <- test_values do
        expected = FormatHelpers.format_currency(value)
        actual = Formatters.format_currency_with_cents(value)

        assert actual == expected,
               "Mismatch for #{inspect(value)} with default show_cents: expected '#{expected}', got '#{actual}'"
      end
    end

    test "identical behavior for nil and edge cases with both show_cents values" do
      edge_cases = [nil]

      for value <- edge_cases do
        for show_cents <- [true, false] do
          expected = FormatHelpers.format_currency(value, show_cents)
          actual = Formatters.format_currency_with_cents(value, show_cents)

          assert actual == expected,
                 "Mismatch for #{inspect(value)} with show_cents=#{show_cents}: expected '#{expected}', got '#{actual}'"
        end
      end
    end
  end

  describe "chart_helpers.ex backwards compatibility" do
    test "identical behavior for decimal values" do
      test_values = [
        Decimal.new("1234.56"),
        Decimal.new("123456.78"),
        Decimal.new("0.99"),
        Decimal.new("1000.00"),
        Decimal.new("0"),
        Decimal.new("1")
      ]

      for value <- test_values do
        expected = ChartHelpers.format_currency(value)
        actual = Formatters.format_currency_simple(value)

        assert actual == expected,
               "Mismatch for #{inspect(value)}: expected '#{expected}', got '#{actual}'"
      end
    end

    test "identical behavior for numeric values" do
      test_values = [123.45, 1234.56, 0.99, 1000.0, 0, 1]

      for value <- test_values do
        expected = ChartHelpers.format_currency(value)
        actual = Formatters.format_currency_simple(value)

        assert actual == expected,
               "Mismatch for #{inspect(value)}: expected '#{expected}', got '#{actual}'"
      end
    end

    test "identical behavior for nil and invalid inputs" do
      edge_cases = [nil, "invalid", :atom, %{}, []]

      for value <- edge_cases do
        expected = ChartHelpers.format_currency(value)
        actual = Formatters.format_currency_simple(value)

        assert actual == expected,
               "Mismatch for #{inspect(value)}: expected '#{expected}', got '#{actual}'"
      end
    end
  end

  describe "comprehensive cross-validation" do
    test "all implementations produce consistent results for identical inputs" do
      # Test cases that should work across all implementations
      common_test_values = [
        Decimal.new("1234.56"),
        Decimal.new("1000.00"),
        Decimal.new("0.99"),
        nil
      ]

      for value <- common_test_values do
        # Get outputs from all existing implementations
        format_helper_output = FormatHelper.format_currency(value)

        # format_helpers.ex with show_cents=true (default behavior)
        format_helpers_output = FormatHelpers.format_currency(value, true)

        # chart_helpers.ex output
        _chart_helpers_output = ChartHelpers.format_currency(value)

        # Get outputs from our unified implementation's compatibility functions
        our_classic_output = Formatters.format_currency_classic(value)
        our_with_cents_output = Formatters.format_currency_with_cents(value, true)
        _our_simple_output = Formatters.format_currency_simple(value)

        # Validate our compatibility functions match their respective originals
        assert our_classic_output == format_helper_output,
               "format_currency_classic mismatch for #{inspect(value)}"

        assert our_with_cents_output == format_helpers_output,
               "format_currency_with_cents mismatch for #{inspect(value)}"

        # Note: chart_helpers behavior may differ due to no comma formatting
        # This is expected and documented in our design
      end
    end

    test "negative value handling is consistent across all implementations" do
      negative_value = Decimal.new("-123.45")

      # All implementations should preserve negative values
      format_helpers_output = FormatHelpers.format_currency(negative_value, true)
      our_with_cents_output = Formatters.format_currency_with_cents(negative_value, true)

      assert our_with_cents_output == format_helpers_output
      assert String.starts_with?(our_with_cents_output, "-")

      # chart_helpers.ex also preserves negative values but with $-format
      chart_helpers_output = ChartHelpers.format_currency(negative_value)
      our_simple_output = Formatters.format_currency_simple(negative_value)

      assert our_simple_output == chart_helpers_output
      assert String.contains?(our_simple_output, "$-")
    end

    test "comma formatting differences are documented and intentional" do
      large_value = Decimal.new("123456.78")

      # format_helper.ex and format_helpers.ex should have commas
      format_helper_output = FormatHelper.format_currency(large_value)
      format_helpers_output = FormatHelpers.format_currency(large_value, true)

      our_classic_output = Formatters.format_currency_classic(large_value)
      our_with_cents_output = Formatters.format_currency_with_cents(large_value, true)

      assert our_classic_output == format_helper_output
      assert our_with_cents_output == format_helpers_output
      assert String.contains?(our_classic_output, ",")
      assert String.contains?(our_with_cents_output, ",")

      # chart_helpers.ex should NOT have commas
      chart_helpers_output = ChartHelpers.format_currency(large_value)
      our_simple_output = Formatters.format_currency_simple(large_value)

      assert our_simple_output == chart_helpers_output
      refute String.contains?(our_simple_output, ",")
    end
  end

  describe "property-based compatibility validation" do
    test "unified API can reproduce all existing behaviors through options" do
      test_value = Decimal.new("1234.56")

      # format_helper.ex behavior: commas, cents, no negative handling
      classic_result = FormatHelper.format_currency(test_value)

      unified_classic_result =
        Formatters.currency(test_value,
          show_cents: true,
          comma_formatting: true,
          handle_negative: true
        )

      assert unified_classic_result == classic_result

      # format_helpers.ex behavior: commas, configurable cents, negative handling
      helpers_result = FormatHelpers.format_currency(test_value, true)

      unified_helpers_result =
        Formatters.currency(test_value,
          show_cents: true,
          comma_formatting: true,
          handle_negative: true
        )

      assert unified_helpers_result == helpers_result

      # chart_helpers.ex behavior: no commas, cents, preserves negatives
      chart_result = ChartHelpers.format_currency(test_value)

      unified_chart_result =
        Formatters.currency(test_value,
          show_cents: true,
          comma_formatting: false,
          handle_negative: true
        )

      assert unified_chart_result == chart_result
    end
  end

  describe "migration safety validation" do
    test "all compatibility functions are drop-in replacements" do
      # Test that we can safely replace calls without changing behavior

      # format_helper.ex pattern: format_currency(value)
      original_call = fn value -> FormatHelper.format_currency(value) end
      replacement_call = fn value -> Formatters.format_currency_classic(value) end

      test_values = [Decimal.new("123.45"), 123.45, nil]

      for value <- test_values do
        assert original_call.(value) == replacement_call.(value)
      end

      # format_helpers.ex pattern: format_currency(value, show_cents)
      original_call_2 = fn value, show_cents ->
        FormatHelpers.format_currency(value, show_cents)
      end

      replacement_call_2 = fn value, show_cents ->
        Formatters.format_currency_with_cents(value, show_cents)
      end

      for value <- test_values do
        for show_cents <- [true, false] do
          assert original_call_2.(value, show_cents) == replacement_call_2.(value, show_cents)
        end
      end

      # chart_helpers.ex pattern: format_currency(value)
      original_call_3 = fn value -> ChartHelpers.format_currency(value) end
      replacement_call_3 = fn value -> Formatters.format_currency_simple(value) end

      for value <- test_values do
        assert original_call_3.(value) == replacement_call_3.(value)
      end
    end
  end
end
