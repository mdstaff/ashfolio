defmodule Ashfolio.FinancialManagement.AERCalculatorTest do
  use ExUnit.Case, async: true

  alias Ashfolio.FinancialManagement.AERCalculator

  @moduletag :unit

  describe "monthly_to_aer/1" do
    test "converts monthly rate to annual equivalent rate" do
      # 1% monthly = 12.6825% AER (not 12% simple)
      monthly_rate = Decimal.new("0.01")
      aer = AERCalculator.monthly_to_aer(monthly_rate)

      # (1 + 0.01)^12 - 1 = 1.126825 - 1 = 0.126825
      expected = Decimal.new("0.126825")
      assert_in_delta(Decimal.to_float(aer), Decimal.to_float(expected), 0.00001)
    end

    test "handles zero monthly rate" do
      monthly_rate = Decimal.new("0")
      aer = AERCalculator.monthly_to_aer(monthly_rate)

      assert Decimal.compare(aer, Decimal.new("0")) == :eq
    end

    test "handles negative monthly rate" do
      # -1% monthly = -11.36% AER
      monthly_rate = Decimal.new("-0.01")
      aer = AERCalculator.monthly_to_aer(monthly_rate)

      # (1 - 0.01)^12 - 1 = 0.99^12 - 1 = 0.8864 - 1 = -0.1136
      expected = Decimal.new("-0.1136")
      assert_in_delta(Decimal.to_float(aer), Decimal.to_float(expected), 0.0001)
    end

    test "raises error for invalid monthly rate <= -100%" do
      assert_raise ArgumentError, "Monthly rate cannot be <= -100%", fn ->
        AERCalculator.monthly_to_aer(Decimal.new("-1"))
      end

      assert_raise ArgumentError, "Monthly rate cannot be <= -100%", fn ->
        AERCalculator.monthly_to_aer(Decimal.new("-1.1"))
      end
    end
  end

  describe "aer_to_monthly/1" do
    test "converts annual equivalent rate to monthly rate" do
      # 12% AER = 0.9489% monthly (not 1% simple)
      aer = Decimal.new("0.12")
      monthly_rate = AERCalculator.aer_to_monthly(aer)

      # (1.12)^(1/12) - 1 = 1.009488793 - 1 = 0.009488793
      expected = Decimal.new("0.009488792934525269")
      assert_in_delta(Decimal.to_float(monthly_rate), Decimal.to_float(expected), 0.000001)
    end

    test "handles zero annual rate" do
      aer = Decimal.new("0")
      monthly_rate = AERCalculator.aer_to_monthly(aer)

      assert Decimal.compare(monthly_rate, Decimal.new("0")) == :eq
    end

    test "handles negative annual rate" do
      # -10% AER = -0.8742% monthly
      aer = Decimal.new("-0.10")
      monthly_rate = AERCalculator.aer_to_monthly(aer)

      # (0.9)^(1/12) - 1 = 0.991258 - 1 = -0.008742
      expected = Decimal.new("-0.008742")
      assert_in_delta(Decimal.to_float(monthly_rate), Decimal.to_float(expected), 0.00001)
    end

    test "raises error for invalid AER <= -100%" do
      assert_raise ArgumentError, "AER cannot be <= -100%", fn ->
        AERCalculator.aer_to_monthly(Decimal.new("-1"))
      end

      assert_raise ArgumentError, "AER cannot be <= -100%", fn ->
        AERCalculator.aer_to_monthly(Decimal.new("-1.5"))
      end
    end
  end

  describe "compound_with_aer/4" do
    test "compounds principal with annual rate over years" do
      principal = Decimal.new("10000")
      # 7% annual
      aer = Decimal.new("0.07")
      years = 10

      # Standard compound interest: P * (1 + r)^t
      # 10000 * (1.07)^10 = 19,671.51
      result = AERCalculator.compound_with_aer(principal, aer, years)
      expected = Decimal.new("19671.51")

      assert_in_delta(Decimal.to_float(result), Decimal.to_float(expected), 0.1)
    end

    test "compounds with monthly contributions" do
      principal = Decimal.new("10000")
      aer = Decimal.new("0.07")
      years = 10
      monthly_contribution = Decimal.new("100")

      # Future value with annuity
      result = AERCalculator.compound_with_aer(principal, aer, years, monthly_contribution)

      # Should be greater than without contributions
      without_contrib = AERCalculator.compound_with_aer(principal, aer, years)
      assert Decimal.compare(result, without_contrib) == :gt

      # Expected ~$37,000 (19,671 from principal + 17,409 from contributions)
      expected = Decimal.new("37000")
      assert_in_delta(Decimal.to_float(result), Decimal.to_float(expected), 1000)
    end

    test "handles zero interest rate" do
      principal = Decimal.new("10000")
      aer = Decimal.new("0")
      years = 10
      monthly_contribution = Decimal.new("100")

      result = AERCalculator.compound_with_aer(principal, aer, years, monthly_contribution)

      # With 0% interest: principal + (monthly * 12 * years)
      # 10000 + (100 * 12 * 10) = 10000 + 12000 = 22000
      expected = Decimal.new("22000")
      assert Decimal.compare(result, expected) == :eq
    end

    test "handles zero years" do
      principal = Decimal.new("10000")
      aer = Decimal.new("0.07")
      years = 0

      result = AERCalculator.compound_with_aer(principal, aer, years)

      # No time = no growth
      assert Decimal.compare(result, principal) == :eq
    end
  end

  describe "effective_rate/2" do
    test "calculates effective annual rate from nominal rate with monthly compounding" do
      # 12% nominal
      nominal_rate = Decimal.new("0.12")
      # monthly
      periods = 12

      effective = AERCalculator.effective_rate(nominal_rate, periods)

      # (1 + 0.12/12)^12 - 1 = (1.01)^12 - 1 = 0.126825
      expected = Decimal.new("0.126825")
      assert_in_delta(Decimal.to_float(effective), Decimal.to_float(expected), 0.00001)
    end

    test "calculates effective rate with quarterly compounding" do
      nominal_rate = Decimal.new("0.12")
      # quarterly
      periods = 4

      effective = AERCalculator.effective_rate(nominal_rate, periods)

      # (1 + 0.12/4)^4 - 1 = (1.03)^4 - 1 = 0.125509
      expected = Decimal.new("0.12550881")
      assert_in_delta(Decimal.to_float(effective), Decimal.to_float(expected), 0.00001)
    end

    test "handles annual compounding (periods = 1)" do
      nominal_rate = Decimal.new("0.12")
      periods = 1

      effective = AERCalculator.effective_rate(nominal_rate, periods)

      # With annual compounding, effective = nominal
      assert Decimal.compare(effective, nominal_rate) == :eq
    end
  end

  describe "nominal_rate/2" do
    test "calculates nominal rate from effective rate with monthly compounding" do
      # ~12.68% effective
      effective_rate = Decimal.new("0.12682503")
      periods = 12

      nominal = AERCalculator.nominal_rate(effective_rate, periods)

      # Should give us back ~12% nominal
      expected = Decimal.new("0.12")
      assert_in_delta(Decimal.to_float(nominal), Decimal.to_float(expected), 0.00001)
    end
  end

  describe "continuous_to_aer/1" do
    test "converts continuous compounding rate to AER" do
      continuous_rate = Decimal.new("0.12")

      aer = AERCalculator.continuous_to_aer(continuous_rate)

      # e^0.12 - 1 = 1.1275 - 1 = 0.1275
      expected = Decimal.new("0.1275")
      assert_in_delta(Decimal.to_float(aer), Decimal.to_float(expected), 0.0001)
    end
  end

  describe "aer_to_continuous/1" do
    test "converts AER to continuous compounding rate" do
      aer = Decimal.new("0.1275")

      continuous = AERCalculator.aer_to_continuous(aer)

      # ln(1.1275) = 0.12
      expected = Decimal.new("0.12")
      assert_in_delta(Decimal.to_float(continuous), Decimal.to_float(expected), 0.0001)
    end
  end

  describe "future_value_with_regular_deposits/5" do
    test "calculates future value with regular monthly deposits" do
      principal = Decimal.new("10000")
      monthly_deposit = Decimal.new("500")
      aer = Decimal.new("0.08")
      years = 20

      result =
        AERCalculator.future_value_with_regular_deposits(
          principal,
          monthly_deposit,
          aer,
          years,
          :monthly
        )

      # Should be substantial after 20 years
      # Principal grows to ~46,610
      # Deposits grow to ~235,000
      # Total ~330,000 (higher due to compounding)
      expected = Decimal.new("330000")
      assert_in_delta(Decimal.to_float(result), Decimal.to_float(expected), 10_000)
    end

    test "supports different deposit frequencies" do
      principal = Decimal.new("10000")
      # Same as 500/month
      annual_deposit = Decimal.new("6000")
      aer = Decimal.new("0.08")
      years = 20

      result =
        AERCalculator.future_value_with_regular_deposits(
          principal,
          annual_deposit,
          aer,
          years,
          :annual
        )

      # Should be similar but slightly less than monthly (less frequent compounding)
      expected = Decimal.new("330000")
      assert_in_delta(Decimal.to_float(result), Decimal.to_float(expected), 10_000)
    end
  end
end
