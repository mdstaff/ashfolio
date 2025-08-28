defmodule AshfolioWeb.Live.FormatHelpersTest do
  use ExUnit.Case, async: true

  alias AshfolioWeb.Live.FormatHelpers

  @moduletag :liveview
  @moduletag :unit
  @moduletag :fast

  describe "format_currency/2" do
    test "formats positive decimal values correctly" do
      assert FormatHelpers.format_currency(Decimal.new("1234.56")) == "$1,234.56"
      assert FormatHelpers.format_currency(Decimal.new("1000000.00")) == "$1,000,000.00"
      assert FormatHelpers.format_currency(Decimal.new("0.99")) == "$0.99"
      assert FormatHelpers.format_currency(Decimal.new("0")) == "$0.00"
    end

    test "formats negative decimal values correctly" do
      assert FormatHelpers.format_currency(Decimal.new("-1234.56")) == "-$1,234.56"
      assert FormatHelpers.format_currency(Decimal.new("-0.01")) == "-$0.01"
    end

    test "formats without cents when show_cents is false" do
      assert FormatHelpers.format_currency(Decimal.new("1234.56"), false) == "$1,235"
      assert FormatHelpers.format_currency(Decimal.new("1000.00"), false) == "$1,000"
      assert FormatHelpers.format_currency(Decimal.new("-500.75"), false) == "-$501"
    end

    test "handles numeric values" do
      assert FormatHelpers.format_currency(1234.56) == "$1,234.56"
      assert FormatHelpers.format_currency(-500.25) == "-$500.25"
      assert FormatHelpers.format_currency(0) == "$0.00"
      assert FormatHelpers.format_currency(1000) == "$1,000.00"
    end

    test "handles nil and invalid values" do
      assert FormatHelpers.format_currency(nil) == "$0.00"
      assert FormatHelpers.format_currency("invalid") == "$0.00"
      assert FormatHelpers.format_currency(%{}) == "$0.00"
    end

    test "adds commas correctly for large numbers" do
      assert FormatHelpers.format_currency(Decimal.new("1234567.89")) == "$1,234,567.89"
      assert FormatHelpers.format_currency(Decimal.new("123456789.01")) == "$123,456,789.01"
    end
  end

  describe "format_percentage/2" do
    test "formats positive decimal percentages correctly" do
      assert FormatHelpers.format_percentage(Decimal.new("15.25")) == "15.25%"
      assert FormatHelpers.format_percentage(Decimal.new("100.00")) == "100.00%"
      assert FormatHelpers.format_percentage(Decimal.new("0.5")) == "0.50%"
      assert FormatHelpers.format_percentage(Decimal.new("0")) == "0.00%"
    end

    test "formats negative decimal percentages correctly" do
      assert FormatHelpers.format_percentage(Decimal.new("-15.25")) == "-15.25%"
      assert FormatHelpers.format_percentage(Decimal.new("-0.01")) == "-0.01%"
    end

    test "respects decimal_places parameter" do
      assert FormatHelpers.format_percentage(Decimal.new("15.25678"), 0) == "15%"
      assert FormatHelpers.format_percentage(Decimal.new("15.25678"), 1) == "15.3%"
      assert FormatHelpers.format_percentage(Decimal.new("15.25678"), 3) == "15.257%"
      assert FormatHelpers.format_percentage(Decimal.new("15.25678"), 4) == "15.2568%"
    end

    test "handles numeric values" do
      assert FormatHelpers.format_percentage(15.25) == "15.25%"
      assert FormatHelpers.format_percentage(-5.5) == "-5.50%"
      assert FormatHelpers.format_percentage(0) == "0.00%"
      assert FormatHelpers.format_percentage(100) == "100.00%"
    end

    test "handles nil and invalid values" do
      assert FormatHelpers.format_percentage(nil) == "0.00%"
      assert FormatHelpers.format_percentage("invalid") == "0.00%"
      assert FormatHelpers.format_percentage(%{}) == "0.00%"
    end
  end

  describe "format_relative_time/2" do
    test "formats seconds correctly" do
      current_time = ~U[2025-01-28 10:30:00Z]
      # 30 seconds ago
      past_time = ~U[2025-01-28 10:29:30Z]

      assert FormatHelpers.format_relative_time(past_time, current_time) == "30 seconds ago"
    end

    test "formats minutes correctly" do
      current_time = ~U[2025-01-28 10:30:00Z]
      # 5 minutes ago
      past_time = ~U[2025-01-28 10:25:00Z]

      assert FormatHelpers.format_relative_time(past_time, current_time) == "5 minutes ago"
    end

    test "formats hours correctly" do
      current_time = ~U[2025-01-28 10:30:00Z]
      # 2 hours ago
      past_time = ~U[2025-01-28 08:30:00Z]

      assert FormatHelpers.format_relative_time(past_time, current_time) == "2 hours ago"
    end

    test "formats days correctly" do
      current_time = ~U[2025-01-28 10:30:00Z]
      # 2 days ago
      past_time = ~U[2025-01-26 10:30:00Z]

      assert FormatHelpers.format_relative_time(past_time, current_time) == "2 days ago"
    end

    test "uses current time when not provided" do
      # This test is a bit tricky since we can't control DateTime.utc_now()
      # We'll just verify it doesn't crash and returns a reasonable string
      # 5 minutes ago
      past_time = DateTime.add(DateTime.utc_now(), -300, :second)
      result = FormatHelpers.format_relative_time(past_time)

      assert String.contains?(result, "ago")
    end

    test "handles nil and invalid values" do
      assert FormatHelpers.format_relative_time(nil) == "Never"
      assert FormatHelpers.format_relative_time("invalid") == "Unknown"
      assert FormatHelpers.format_relative_time(%{}) == "Unknown"
    end
  end

  describe "positive?/1" do
    test "correctly identifies positive decimal values" do
      assert FormatHelpers.positive?(Decimal.new("15.25")) == true
      assert FormatHelpers.positive?(Decimal.new("0.01")) == true
      assert FormatHelpers.positive?(Decimal.new("1000")) == true
    end

    test "correctly identifies negative decimal values" do
      assert FormatHelpers.positive?(Decimal.new("-15.25")) == false
      assert FormatHelpers.positive?(Decimal.new("-0.01")) == false
      assert FormatHelpers.positive?(Decimal.new("-1000")) == false
    end

    test "correctly identifies zero as not positive" do
      assert FormatHelpers.positive?(Decimal.new("0")) == false
      assert FormatHelpers.positive?(Decimal.new("0.00")) == false
    end

    test "handles numeric values" do
      assert FormatHelpers.positive?(15.25) == true
      assert FormatHelpers.positive?(-15.25) == false
      assert FormatHelpers.positive?(0) == false
      assert FormatHelpers.positive?(0.0) == false
    end

    test "handles nil and invalid values" do
      assert FormatHelpers.positive?(nil) == false
      assert FormatHelpers.positive?("invalid") == false
      assert FormatHelpers.positive?(%{}) == false
    end
  end

  describe "value_color_class/4" do
    test "returns positive class for positive values" do
      assert FormatHelpers.value_color_class(Decimal.new("15.25")) == "text-green-700"
      assert FormatHelpers.value_color_class(15.25) == "text-green-700"
      assert FormatHelpers.value_color_class(Decimal.new("0.01")) == "text-green-700"
    end

    test "returns negative class for negative values" do
      assert FormatHelpers.value_color_class(Decimal.new("-15.25")) == "text-red-700"
      assert FormatHelpers.value_color_class(-15.25) == "text-red-700"
      assert FormatHelpers.value_color_class(Decimal.new("-0.01")) == "text-red-700"
    end

    test "returns neutral class for zero values" do
      assert FormatHelpers.value_color_class(Decimal.new("0")) == "text-gray-600"
      assert FormatHelpers.value_color_class(0) == "text-gray-600"
      assert FormatHelpers.value_color_class(Decimal.new("0.00")) == "text-gray-600"
    end

    test "allows custom CSS classes" do
      positive_class = "text-success"
      negative_class = "text-danger"
      neutral_class = "text-muted"

      assert FormatHelpers.value_color_class(
               Decimal.new("15.25"),
               positive_class,
               negative_class,
               neutral_class
             ) == "text-success"

      assert FormatHelpers.value_color_class(
               Decimal.new("-15.25"),
               positive_class,
               negative_class,
               neutral_class
             ) == "text-danger"

      assert FormatHelpers.value_color_class(
               Decimal.new("0"),
               positive_class,
               negative_class,
               neutral_class
             ) == "text-muted"
    end

    test "handles nil and invalid values" do
      assert FormatHelpers.value_color_class(nil) == "text-gray-600"
      assert FormatHelpers.value_color_class("invalid") == "text-gray-600"
      assert FormatHelpers.value_color_class(%{}) == "text-gray-600"
    end
  end

  describe "format_date/1" do
    test "formats valid dates correctly" do
      assert FormatHelpers.format_date(~D[2023-12-25]) == "Dec 25, 2023"
      assert FormatHelpers.format_date(~D[2025-01-01]) == "Jan 01, 2025"
      assert FormatHelpers.format_date(~D[2024-07-04]) == "Jul 04, 2024"
    end

    test "handles nil and invalid values" do
      assert FormatHelpers.format_date(nil) == "N/A"
      assert FormatHelpers.format_date("invalid") == "Invalid Date"
      assert FormatHelpers.format_date(%{}) == "Invalid Date"
    end
  end

  describe "format_quantity/1" do
    test "formats decimal quantities correctly" do
      assert FormatHelpers.format_quantity(Decimal.new("123.456")) == "123.456"
      assert FormatHelpers.format_quantity(Decimal.new("100.000")) == "100.000"
      assert FormatHelpers.format_quantity(Decimal.new("0.001")) == "0.001"
      assert FormatHelpers.format_quantity(Decimal.new("0")) == "0"
    end

    test "formats numeric quantities correctly" do
      assert FormatHelpers.format_quantity(123.456) == "123.456"
      assert FormatHelpers.format_quantity(100.0) == "100.000"
      assert FormatHelpers.format_quantity(0.001) == "0.001"
      assert FormatHelpers.format_quantity(0) == "0.000"
    end

    test "handles nil and invalid values" do
      assert FormatHelpers.format_quantity(nil) == "0"
      assert FormatHelpers.format_quantity("invalid") == "0"
      assert FormatHelpers.format_quantity(%{}) == "0"
    end
  end
end
