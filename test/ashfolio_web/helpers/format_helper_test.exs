defmodule AshfolioWeb.Helpers.FormatHelperTest do
  use ExUnit.Case, async: true

  alias AshfolioWeb.Helpers.FormatHelper

  @moduletag :unit

  describe "format_growth_rate/1" do
    test "converts decimal to percentage string" do
      assert FormatHelper.format_growth_rate(Decimal.new("0.07")) == "7%"
      assert FormatHelper.format_growth_rate(Decimal.new("0.05")) == "5%"
      assert FormatHelper.format_growth_rate(Decimal.new("0.10")) == "10%"
      assert FormatHelper.format_growth_rate(Decimal.new("0.125")) == "12.5%"
    end

    test "handles zero and negative rates" do
      assert FormatHelper.format_growth_rate(Decimal.new("0")) == "0%"
      assert FormatHelper.format_growth_rate(Decimal.new("-0.05")) == "-5%"
    end

    test "rounds to reasonable precision" do
      assert FormatHelper.format_growth_rate(Decimal.new("0.07123")) == "7.12%"
      assert FormatHelper.format_growth_rate(Decimal.new("0.07999")) == "8%"
    end
  end

  describe "format_chart_axis/1" do
    test "formats millions correctly" do
      assert FormatHelper.format_chart_axis(1_000_000) == "$1M"
      assert FormatHelper.format_chart_axis(2_500_000) == "$2.5M"
      assert FormatHelper.format_chart_axis(10_000_000) == "$10M"
    end

    test "formats thousands correctly" do
      assert FormatHelper.format_chart_axis(500_000) == "$500K"
      assert FormatHelper.format_chart_axis(50_000) == "$50K"
      assert FormatHelper.format_chart_axis(5_000) == "$5K"
      assert FormatHelper.format_chart_axis(1_000) == "$1K"
    end

    test "formats billions correctly" do
      assert FormatHelper.format_chart_axis(1_000_000_000) == "$1B"
      assert FormatHelper.format_chart_axis(2_000_000_000) == "$2B"
      # Should not show BGN
      refute FormatHelper.format_chart_axis(2_000_000_000) =~ "BGN"
    end

    test "handles small numbers" do
      assert FormatHelper.format_chart_axis(500) == "$500"
      assert FormatHelper.format_chart_axis(100) == "$100"
      assert FormatHelper.format_chart_axis(0) == "$0"
    end

    test "handles Decimal input" do
      assert FormatHelper.format_chart_axis(Decimal.new("1000000")) == "$1M"
      assert FormatHelper.format_chart_axis(Decimal.new("500000")) == "$500K"
    end
  end
end
