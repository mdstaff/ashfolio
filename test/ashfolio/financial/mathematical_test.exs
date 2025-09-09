defmodule Ashfolio.Financial.MathematicalTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Financial.Mathematical

  doctest Mathematical

  describe "power/2" do
    test "calculates integer powers correctly" do
      assert Decimal.equal?(Mathematical.power(Decimal.new("2"), 3), Decimal.new("8"))
      assert Decimal.equal?(Mathematical.power(Decimal.new("1.05"), 10), Decimal.new("1.628894626777442"))
      assert Decimal.equal?(Mathematical.power(Decimal.new("10"), 2), Decimal.new("100"))
    end

    test "handles edge cases" do
      assert Decimal.equal?(Mathematical.power(Decimal.new("5"), 0), Decimal.new("1"))
      assert Decimal.equal?(Mathematical.power(Decimal.new("5"), 1), Decimal.new("5"))
      assert Decimal.equal?(Mathematical.power(Decimal.new("0"), 5), Decimal.new("0"))
    end

    test "handles negative exponents" do
      result = Mathematical.power(Decimal.new("2"), -2)
      expected = Decimal.new("0.25")
      assert Decimal.equal?(result, expected)
    end

    test "handles decimal exponents" do
      # 4^0.5 = 2
      result = Mathematical.power(Decimal.new("4"), Decimal.new("0.5"))
      assert Decimal.equal?(Decimal.round(result, 1), Decimal.new("2.0"))
    end

    test "accepts various input types" do
      assert Decimal.equal?(Mathematical.power("2", 3), Decimal.new("8"))
      assert Decimal.equal?(Mathematical.power(2, 3), Decimal.new("8"))
      assert Decimal.equal?(Mathematical.power(2.0, 3), Decimal.new("8"))
    end
  end

  describe "nth_root/2" do
    test "calculates roots correctly" do
      assert Decimal.equal?(Mathematical.nth_root(Decimal.new("8"), 3), Decimal.new("2"))
      assert Decimal.equal?(Mathematical.nth_root(Decimal.new("100"), 2), Decimal.new("10"))
      assert Decimal.equal?(Mathematical.nth_root(Decimal.new("27"), 3), Decimal.new("3"))
    end

    test "handles edge cases" do
      assert Decimal.equal?(Mathematical.nth_root(Decimal.new("0"), 5), Decimal.new("0"))
      assert Decimal.equal?(Mathematical.nth_root(Decimal.new("10"), 1), Decimal.new("10"))
    end

    test "handles square roots" do
      result = Mathematical.nth_root(Decimal.new("16"), 2)
      assert Decimal.equal?(result, Decimal.new("4"))
    end
  end

  describe "binary_search_nth_root/3" do
    test "provides precise root calculation" do
      result = Mathematical.binary_search_nth_root(Decimal.new("8"), 3)
      # Should be very close to 2
      diff = Decimal.sub(result, Decimal.new("2"))
      assert Decimal.compare(Decimal.abs(diff), Decimal.new("0.01")) == :lt
    end

    test "handles different precision levels" do
      # Low precision
      result1 = Mathematical.binary_search_nth_root(Decimal.new("8"), 3, 5)
      # High precision
      result2 = Mathematical.binary_search_nth_root(Decimal.new("8"), 3, 20)

      # High precision should be more accurate
      diff1 = Decimal.abs(Decimal.sub(result1, Decimal.new("2")))
      diff2 = Decimal.abs(Decimal.sub(result2, Decimal.new("2")))

      assert Decimal.compare(diff2, diff1) == :lt
    end

    test "works with large numbers" do
      result = Mathematical.binary_search_nth_root(Decimal.new("1000"), 3)
      expected = Decimal.new("10")
      diff = Decimal.abs(Decimal.sub(result, expected))
      assert Decimal.compare(diff, Decimal.new("0.1")) == :lt
    end
  end

  describe "exp/1" do
    test "calculates natural exponential" do
      # e^0 = 1
      result = Mathematical.exp(Decimal.new("0"))
      assert Decimal.equal?(result, Decimal.new("1"))

      # e^1 ≈ 2.718
      result = Mathematical.exp(Decimal.new("1"))
      expected = Decimal.new("2.718281828459045")
      assert Decimal.equal?(Decimal.round(result, 10), Decimal.round(expected, 10))
    end

    test "handles negative values" do
      # e^(-1) ≈ 0.368
      result = Mathematical.exp(Decimal.new("-1"))
      assert Decimal.compare(result, Decimal.new("0.3")) == :gt
      assert Decimal.compare(result, Decimal.new("0.4")) == :lt
    end
  end

  describe "ln/1" do
    test "calculates natural logarithm" do
      # ln(1) = 0
      result = Mathematical.ln(Decimal.new("1"))
      assert Decimal.equal?(Decimal.round(result, 5), Decimal.new("0"))

      # ln(e) ≈ 1
      e = Decimal.new("2.718281828459045")
      result = Mathematical.ln(e)
      assert Decimal.equal?(Decimal.round(result, 1), Decimal.new("1.0"))
    end

    test "handles various inputs" do
      # ln(10) ≈ 2.303
      result = Mathematical.ln(Decimal.new("10"))
      assert Decimal.compare(result, Decimal.new("2.3")) == :gt
      assert Decimal.compare(result, Decimal.new("2.4")) == :lt
    end
  end

  describe "compound_growth/3" do
    test "calculates compound growth correctly" do
      # $1000 at 5% for 10 years
      result = Mathematical.compound_growth(Decimal.new("1000"), Decimal.new("0.05"), 10)
      expected = Decimal.new("1628.894626777442")
      assert Decimal.equal?(Decimal.round(result, 8), Decimal.round(expected, 8))
    end

    test "handles zero interest rate" do
      result = Mathematical.compound_growth(Decimal.new("1000"), Decimal.new("0"), 10)
      assert Decimal.equal?(result, Decimal.new("1000"))
    end

    test "handles single period" do
      result = Mathematical.compound_growth(Decimal.new("1000"), Decimal.new("0.05"), 1)
      assert Decimal.equal?(result, Decimal.new("1050"))
    end

    test "accepts string inputs" do
      result = Mathematical.compound_growth("1000", "0.05", 10)
      expected = Decimal.new("1628.894626777442")
      assert Decimal.equal?(Decimal.round(result, 8), Decimal.round(expected, 8))
    end
  end

  describe "future_value_annuity/3" do
    test "calculates future value of annuity" do
      # $100/month at 0.5% monthly rate for 12 months
      result = Mathematical.future_value_annuity(Decimal.new("100"), Decimal.new("0.005"), 12)
      # Should be slightly more than 1200 due to compounding
      assert Decimal.compare(result, Decimal.new("1200")) == :gt
      assert Decimal.compare(result, Decimal.new("1240")) == :lt
    end

    test "handles zero interest rate" do
      result = Mathematical.future_value_annuity(Decimal.new("100"), Decimal.new("0"), 12)
      assert Decimal.equal?(result, Decimal.new("1200"))
    end

    test "handles single payment" do
      result = Mathematical.future_value_annuity(Decimal.new("100"), Decimal.new("0.05"), 1)
      assert Decimal.equal?(result, Decimal.new("100"))
    end
  end

  describe "present_value/3" do
    test "calculates present value correctly" do
      # PV of $1000 in 10 years at 5% discount
      result = Mathematical.present_value(Decimal.new("1000"), Decimal.new("0.05"), 10)
      expected = Decimal.new("613.913253540756")
      assert Decimal.equal?(Decimal.round(result, 8), Decimal.round(expected, 8))
    end

    test "handles zero discount rate" do
      result = Mathematical.present_value(Decimal.new("1000"), Decimal.new("0"), 10)
      assert Decimal.equal?(result, Decimal.new("1000"))
    end

    test "inverse relationship with compound growth" do
      principal = Decimal.new("1000")
      rate = Decimal.new("0.05")
      periods = 10

      # Compound then discount should return original value
      future_value = Mathematical.compound_growth(principal, rate, periods)
      present_value = Mathematical.present_value(future_value, rate, periods)

      # Allow for small rounding differences
      diff = Decimal.abs(Decimal.sub(present_value, principal))
      assert Decimal.compare(diff, Decimal.new("0.01")) == :lt
    end
  end

  describe "continuous_compound/3" do
    test "calculates continuous compounding" do
      # $1000 at 5% continuously for 10 years
      result = Mathematical.continuous_compound(Decimal.new("1000"), Decimal.new("0.05"), 10)
      # e^(0.05 * 10) * 1000 = e^0.5 * 1000 ≈ 1649
      assert Decimal.compare(result, Decimal.new("1640")) == :gt
      assert Decimal.compare(result, Decimal.new("1660")) == :lt
    end

    test "handles zero rate" do
      result = Mathematical.continuous_compound(Decimal.new("1000"), Decimal.new("0"), 10)
      assert Decimal.equal?(result, Decimal.new("1000"))
    end

    test "handles zero time" do
      result = Mathematical.continuous_compound(Decimal.new("1000"), Decimal.new("0.05"), 0)
      assert Decimal.equal?(result, Decimal.new("1000"))
    end
  end

  describe "effective_annual_rate/2" do
    test "calculates EAR from nominal rate" do
      # 12% nominal compounded monthly
      result = Mathematical.effective_annual_rate(Decimal.new("0.12"), 12)
      # Should be slightly higher than 12% due to compounding
      assert Decimal.compare(result, Decimal.new("0.12")) == :gt
      assert Decimal.compare(result, Decimal.new("0.13")) == :lt
    end

    test "handles annual compounding" do
      result = Mathematical.effective_annual_rate(Decimal.new("0.12"), 1)
      assert Decimal.equal?(result, Decimal.new("0.12"))
    end

    test "handles zero rate" do
      result = Mathematical.effective_annual_rate(Decimal.new("0"), 12)
      assert Decimal.equal?(result, Decimal.new("0"))
    end

    test "handles zero periods" do
      result = Mathematical.effective_annual_rate(Decimal.new("0.12"), 0)
      assert Decimal.equal?(result, Decimal.new("0"))
    end
  end

  describe "cagr/3" do
    test "calculates CAGR correctly" do
      # Investment doubles in 10 years: CAGR = (2/1)^(1/10) - 1 ≈ 7.18%
      result = Mathematical.cagr(Decimal.new("1000"), Decimal.new("2000"), 10)
      assert Decimal.compare(result, Decimal.new("0.07")) == :gt
      assert Decimal.compare(result, Decimal.new("0.075")) == :lt
    end

    test "handles no growth" do
      result = Mathematical.cagr(Decimal.new("1000"), Decimal.new("1000"), 10)
      assert Decimal.equal?(Decimal.round(result, 5), Decimal.new("0"))
    end

    test "handles single year" do
      result = Mathematical.cagr(Decimal.new("1000"), Decimal.new("1100"), 1)
      assert Decimal.equal?(result, Decimal.new("0.1"))
    end

    test "handles zero beginning value" do
      result = Mathematical.cagr(Decimal.new("0"), Decimal.new("1000"), 10)
      assert Decimal.equal?(result, Decimal.new("0"))
    end

    test "handles zero years" do
      result = Mathematical.cagr(Decimal.new("1000"), Decimal.new("2000"), 0)
      assert Decimal.equal?(result, Decimal.new("0"))
    end
  end

  describe "rule_of_72/1" do
    test "calculates doubling time approximation" do
      # 6% annual rate should double in ~12 years (72/6)
      result = Mathematical.rule_of_72(Decimal.new("0.06"))
      assert Decimal.equal?(result, Decimal.new("12"))

      # 8% annual rate should double in 9 years (72/8)
      result = Mathematical.rule_of_72(Decimal.new("0.08"))
      assert Decimal.equal?(result, Decimal.new("9"))
    end

    test "handles various rates" do
      # 12% rate
      result = Mathematical.rule_of_72(Decimal.new("0.12"))
      assert Decimal.equal?(result, Decimal.new("6"))

      # 3% rate
      result = Mathematical.rule_of_72(Decimal.new("0.03"))
      assert Decimal.equal?(result, Decimal.new("24"))
    end

    test "provides reasonable approximation" do
      # Compare Rule of 72 with actual CAGR calculation
      rate = Decimal.new("0.06")

      # Rule of 72 prediction
      rule72_years = Mathematical.rule_of_72(rate)

      # Actual doubling with compound growth
      result_after_rule72 = Mathematical.compound_growth(Decimal.new("1000"), rate, Decimal.to_integer(rule72_years))

      # Should be close to doubling ($2000)
      diff = Decimal.abs(Decimal.sub(result_after_rule72, Decimal.new("2000")))
      # Within $100
      assert Decimal.compare(diff, Decimal.new("100")) == :lt
    end
  end

  describe "ensure_decimal/1 (private)" do
    # Test through public functions that use ensure_decimal
    test "handles various input types in power function" do
      # Test that ensure_decimal works correctly via power function
      # integer
      assert Decimal.equal?(Mathematical.power(2, 3), Decimal.new("8"))
      # string
      assert Decimal.equal?(Mathematical.power("2", 3), Decimal.new("8"))
      # float
      assert Decimal.equal?(Mathematical.power(2.0, 3), Decimal.new("8"))
      # decimal
      assert Decimal.equal?(Mathematical.power(Decimal.new("2"), 3), Decimal.new("8"))
    end
  end

  describe "integration with financial calculations" do
    test "compound growth matches traditional formula" do
      principal = Decimal.new("10000")
      # 7% annual
      rate = Decimal.new("0.07")
      years = 20

      result = Mathematical.compound_growth(principal, rate, years)

      # Manually calculate: 10000 * (1.07)^20
      expected = Decimal.mult(principal, Mathematical.power(Decimal.new("1.07"), years))

      assert Decimal.equal?(Decimal.round(result, 2), Decimal.round(expected, 2))
    end

    test "future value annuity formula accuracy" do
      # $500 monthly
      payment = Decimal.new("500")
      # 0.5% monthly (6% annual)
      rate = Decimal.new("0.005")
      # 5 years
      periods = 60

      result = Mathematical.future_value_annuity(payment, rate, periods)

      # Manual formula: PMT * [((1 + r)^n - 1) / r]
      compound_factor = Mathematical.power(Decimal.add(Decimal.new("1"), rate), periods)
      numerator = Decimal.sub(compound_factor, Decimal.new("1"))
      factor = Decimal.div(numerator, rate)
      expected = Decimal.mult(payment, factor)

      assert Decimal.equal?(Decimal.round(result, 2), Decimal.round(expected, 2))
    end

    test "present and future value are inverses" do
      future_value = Decimal.new("50000")
      rate = Decimal.new("0.04")
      periods = 15

      # Calculate present value
      pv = Mathematical.present_value(future_value, rate, periods)

      # Calculate future value from that present value
      fv_calculated = Mathematical.compound_growth(pv, rate, periods)

      # Should match original future value
      diff = Decimal.abs(Decimal.sub(fv_calculated, future_value))
      assert Decimal.compare(diff, Decimal.new("0.01")) == :lt
    end
  end
end
