defmodule Ashfolio.Financial.DecimalHelpersTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Financial.DecimalHelpers, as: DH
  alias Decimal, as: D

  describe "ensure_decimal/1" do
    test "converts integer to decimal" do
      assert DH.ensure_decimal(42) == D.new("42")
    end

    test "converts float to decimal" do
      result = DH.ensure_decimal(42.5)
      assert D.to_float(result) == 42.5
    end

    test "converts string to decimal" do
      assert DH.ensure_decimal("100.50") == D.new("100.50")
    end

    test "returns existing decimal unchanged" do
      decimal = D.new("10")
      assert DH.ensure_decimal(decimal) == decimal
    end

    test "converts nil to zero" do
      assert DH.ensure_decimal(nil) == D.new("0")
    end
  end

  describe "percentage conversions" do
    test "to_percentage multiplies by 100" do
      assert DH.to_percentage(D.new("0.075")) == D.new("7.500")
      assert DH.to_percentage(D.new("0.5")) == D.new("50.0")
      assert DH.to_percentage(D.new("1")) == D.new("100")
    end

    test "from_percentage divides by 100" do
      assert DH.from_percentage(D.new("7.5")) == D.new("0.075")
      assert DH.from_percentage(D.new("50")) == D.new("0.5")
      assert DH.from_percentage(D.new("100")) == D.new("1")
    end
  end

  describe "time period conversions" do
    test "monthly_to_annual multiplies by 12" do
      assert DH.monthly_to_annual(D.new("1000")) == D.new("12000")
      assert DH.monthly_to_annual(D.new("500.50")) == D.new("6006.00")
    end

    test "annual_to_monthly divides by 12" do
      assert DH.annual_to_monthly(D.new("12000")) == D.new("1000")
      assert DH.annual_to_monthly(D.new("6000")) == D.new("500")
    end
  end

  describe "sign checking functions" do
    test "positive? correctly identifies positive values" do
      assert DH.positive?(D.new("1"))
      assert DH.positive?(D.new("0.001"))
      assert DH.positive?(D.new("1000000"))
      refute DH.positive?(D.new("0"))
      refute DH.positive?(D.new("-1"))
    end

    test "negative? correctly identifies negative values" do
      assert DH.negative?(D.new("-1"))
      assert DH.negative?(D.new("-0.001"))
      refute DH.negative?(D.new("0"))
      refute DH.negative?(D.new("1"))
    end

    test "zero? correctly identifies zero" do
      assert DH.zero?(D.new("0"))
      assert DH.zero?(D.new("0.0"))
      refute DH.zero?(D.new("0.001"))
      refute DH.zero?(D.new("-0.001"))
    end

    test "non_zero? correctly identifies non-zero values" do
      assert DH.non_zero?(D.new("1"))
      assert DH.non_zero?(D.new("-1"))
      assert DH.non_zero?(D.new("0.001"))
      refute DH.non_zero?(D.new("0"))
    end
  end

  describe "safe_divide/2" do
    test "performs normal division" do
      assert DH.safe_divide(D.new("10"), D.new("2")) == D.new("5")
      assert DH.safe_divide(D.new("100"), D.new("4")) == D.new("25")
    end

    test "returns zero when dividing by zero" do
      assert DH.safe_divide(D.new("10"), D.new("0")) == D.new("0")
      assert DH.safe_divide(D.new("100"), nil) == D.new("0")
    end

    test "handles negative numbers" do
      assert DH.safe_divide(D.new("-10"), D.new("2")) == D.new("-5")
      assert DH.safe_divide(D.new("10"), D.new("-2")) == D.new("-5")
    end
  end

  describe "percentage_change/2" do
    test "calculates positive percentage change" do
      assert DH.percentage_change(D.new("100"), D.new("110")) == D.new("10.0")
      assert DH.percentage_change(D.new("50"), D.new("75")) == D.new("50.0")
    end

    test "calculates negative percentage change" do
      assert DH.percentage_change(D.new("100"), D.new("90")) == D.new("-10.0")
      assert DH.percentage_change(D.new("100"), D.new("50")) == D.new("-50.0")
    end

    test "returns zero when from value is zero" do
      assert DH.percentage_change(D.new("0"), D.new("100")) == D.new("0")
    end
  end

  describe "sum/1" do
    test "sums a list of decimals" do
      values = [D.new("10"), D.new("20"), D.new("30")]
      assert DH.sum(values) == D.new("60")
    end

    test "handles empty list" do
      assert DH.sum([]) == D.new("0")
    end

    test "handles mixed types" do
      values = [10, "20", D.new("30")]
      assert DH.sum(values) == D.new("60")
    end

    test "handles nil values" do
      values = [D.new("10"), nil, D.new("20")]
      assert DH.sum(values) == D.new("30")
    end
  end

  describe "average/1" do
    test "calculates average of decimals" do
      values = [D.new("10"), D.new("20"), D.new("30")]
      assert DH.average(values) == D.new("20")
    end

    test "handles single value" do
      assert DH.average([D.new("42")]) == D.new("42")
    end

    test "returns zero for empty list" do
      assert DH.average([]) == D.new("0")
    end
  end

  describe "safe_power/2" do
    test "calculates powers correctly" do
      assert DH.safe_power(D.new("2"), 3) == D.new("8.0")
      assert DH.safe_power(D.new("10"), 2) == D.new("100.0")
    end

    test "handles power of 0" do
      assert DH.safe_power(D.new("5"), 0) == D.new("1")
    end

    test "handles power of 1" do
      assert DH.safe_power(D.new("5"), 1) == D.new("5")
    end

    test "handles base of 0" do
      assert DH.safe_power(D.new("0"), 5) == D.new("0")
    end

    test "handles fractional powers" do
      result = DH.safe_power(D.new("4"), 0.5)
      assert D.to_float(result) == 2.0
    end
  end

  describe "safe_nth_root/2" do
    test "calculates roots correctly" do
      result = DH.safe_nth_root(D.new("8"), 3)
      assert_in_delta D.to_float(result), 2.0, 0.0001

      result = DH.safe_nth_root(D.new("16"), 4)
      assert_in_delta D.to_float(result), 2.0, 0.0001
    end

    test "calculates square root" do
      result = DH.safe_nth_root(D.new("9"), 2)
      assert_in_delta D.to_float(result), 3.0, 0.0001
    end

    test "handles zero" do
      assert DH.safe_nth_root(D.new("0"), 3) == D.new("0")
    end
  end

  describe "compound/3" do
    test "calculates compound growth" do
      # $1000 at 5% for 10 periods
      result = DH.compound(D.new("1000"), D.new("0.05"), 10)
      assert_in_delta D.to_float(result), 1628.89, 0.01
    end

    test "handles zero rate" do
      result = DH.compound(D.new("1000"), D.new("0"), 10)
      assert result == D.new("1000.0")
    end

    test "handles zero periods" do
      result = DH.compound(D.new("1000"), D.new("0.05"), 0)
      assert result == D.new("1000")
    end
  end

  describe "round_to/2" do
    test "rounds to specified decimal places" do
      assert DH.round_to(D.new("10.12345"), 2) == D.new("10.12")
      assert DH.round_to(D.new("10.12345"), 3) == D.new("10.123")
      assert DH.round_to(D.new("10.12345"), 0) == D.new("10")
    end

    test "defaults to 2 decimal places" do
      assert DH.round_to(D.new("10.12345")) == D.new("10.12")
    end
  end

  describe "decimal_max/2 and decimal_min/2" do
    test "decimal_max returns larger value" do
      assert DH.decimal_max(D.new("10"), D.new("20")) == D.new("20")
      assert DH.decimal_max(D.new("-10"), D.new("-5")) == D.new("-5")
    end

    test "decimal_min returns smaller value" do
      assert DH.decimal_min(D.new("10"), D.new("20")) == D.new("10")
      assert DH.decimal_min(D.new("-10"), D.new("-5")) == D.new("-10")
    end
  end

  describe "clamp/3" do
    test "clamps value within bounds" do
      assert DH.clamp(D.new("5"), D.new("0"), D.new("10")) == D.new("5")
      assert DH.clamp(D.new("-5"), D.new("0"), D.new("10")) == D.new("0")
      assert DH.clamp(D.new("15"), D.new("0"), D.new("10")) == D.new("10")
    end
  end

  describe "to_float_safe/1" do
    test "converts decimal to float" do
      assert DH.to_float_safe(D.new("42.5")) == 42.5
    end

    test "returns 0.0 for nil" do
      assert DH.to_float_safe(nil) == 0.0
    end

    test "handles various input types" do
      assert DH.to_float_safe(42) == 42.0
      assert DH.to_float_safe("42.5") == 42.5
    end
  end
end
