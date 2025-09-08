defmodule Ashfolio.Financial.MoneyRatiosTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Financial.MoneyRatios

  describe "calculate_capital_ratio/3" do
    @tag :unit
    test "calculates correct ratio for valid profile and net worth" do
      profile = %{
        gross_annual_income: Decimal.new("100000"),
        birth_year: 1985
      }

      net_worth = Decimal.new("200000")

      result = MoneyRatios.calculate_capital_ratio(profile, net_worth, exclude_residence: true)

      assert {:ok, ratio_data} = result
      assert Decimal.equal?(ratio_data.current_ratio, Decimal.new("2.0"))
      # Age ~40
      assert Decimal.equal?(ratio_data.target_ratio, Decimal.new("3.0"))
      assert ratio_data.status == :behind
    end

    @tag :unit
    test "handles zero income gracefully" do
      profile = %{
        gross_annual_income: Decimal.new("0"),
        birth_year: 1985
      }

      net_worth = Decimal.new("100000")

      result = MoneyRatios.calculate_capital_ratio(profile, net_worth, exclude_residence: true)

      assert {:error, :zero_income} = result
    end

    @tag :unit
    test "excludes primary residence from capital calculation when requested" do
      profile = %{
        gross_annual_income: Decimal.new("100000"),
        birth_year: 1985,
        primary_residence_value: Decimal.new("300000")
      }

      # Net worth includes residence
      net_worth_with_residence = Decimal.new("500000")

      result = MoneyRatios.calculate_capital_ratio(profile, net_worth_with_residence, exclude_residence: true)

      assert {:ok, ratio_data} = result
      # Should calculate as (500000 - 300000) / 100000 = 2.0
      assert Decimal.equal?(ratio_data.current_ratio, Decimal.new("2.0"))
    end
  end

  describe "calculate_savings_ratio/2" do
    @tag :unit
    test "calculates savings ratio correctly" do
      profile = %{
        gross_annual_income: Decimal.new("100000")
      }

      annual_savings = Decimal.new("12000")

      result = MoneyRatios.calculate_savings_ratio(profile, annual_savings)

      assert {:ok, ratio_data} = result
      assert Decimal.equal?(ratio_data.current_ratio, Decimal.new("0.12"))
      assert Decimal.equal?(ratio_data.target_ratio, Decimal.new("0.12"))
      assert ratio_data.status == :on_track
    end

    @tag :unit
    test "identifies when savings rate is below target" do
      profile = %{
        gross_annual_income: Decimal.new("100000")
      }

      annual_savings = Decimal.new("8000")

      result = MoneyRatios.calculate_savings_ratio(profile, annual_savings)

      assert {:ok, ratio_data} = result
      assert Decimal.equal?(ratio_data.current_ratio, Decimal.new("0.08"))
      assert ratio_data.status == :behind
    end
  end

  describe "calculate_mortgage_ratio/1" do
    @tag :unit
    test "calculates mortgage ratio for profile with mortgage" do
      profile = %{
        gross_annual_income: Decimal.new("100000"),
        mortgage_balance: Decimal.new("200000"),
        # Age ~40
        birth_year: 1985
      }

      result = MoneyRatios.calculate_mortgage_ratio(profile)

      assert {:ok, ratio_data} = result
      assert Decimal.equal?(ratio_data.current_ratio, Decimal.new("2.0"))
      # Target for age 40
      assert Decimal.equal?(ratio_data.target_ratio, Decimal.new("1.5"))
      assert ratio_data.status == :behind
    end

    @tag :unit
    test "returns zero ratio when no mortgage" do
      profile = %{
        gross_annual_income: Decimal.new("100000"),
        mortgage_balance: nil,
        birth_year: 1985
      }

      result = MoneyRatios.calculate_mortgage_ratio(profile)

      assert {:ok, ratio_data} = result
      assert Decimal.equal?(ratio_data.current_ratio, Decimal.new("0"))
      assert ratio_data.status == :on_track
    end
  end

  describe "calculate_education_ratio/1" do
    @tag :unit
    test "calculates education debt ratio" do
      profile = %{
        gross_annual_income: Decimal.new("80000"),
        student_loan_balance: Decimal.new("60000")
      }

      result = MoneyRatios.calculate_education_ratio(profile)

      assert {:ok, ratio_data} = result
      assert Decimal.equal?(ratio_data.current_ratio, Decimal.new("0.75"))
      assert Decimal.equal?(ratio_data.target_ratio, Decimal.new("1.0"))
      assert ratio_data.status == :on_track
    end

    @tag :unit
    test "identifies excessive education debt" do
      profile = %{
        gross_annual_income: Decimal.new("50000"),
        student_loan_balance: Decimal.new("75000")
      }

      result = MoneyRatios.calculate_education_ratio(profile)

      assert {:ok, ratio_data} = result
      assert Decimal.equal?(ratio_data.current_ratio, Decimal.new("1.5"))
      assert ratio_data.status == :behind
    end
  end

  describe "calculate_all_ratios/3" do
    @tag :unit
    test "calculates all ratios for a complete profile" do
      profile = %{
        gross_annual_income: Decimal.new("100000"),
        birth_year: 1985,
        mortgage_balance: Decimal.new("150000"),
        student_loan_balance: Decimal.new("25000"),
        primary_residence_value: Decimal.new("300000")
      }

      net_worth = Decimal.new("400000")
      annual_savings = Decimal.new("15000")

      result = MoneyRatios.calculate_all_ratios(profile, net_worth, annual_savings)

      assert {:ok, all_ratios} = result
      assert Map.has_key?(all_ratios, :capital_ratio)
      assert Map.has_key?(all_ratios, :savings_ratio)
      assert Map.has_key?(all_ratios, :mortgage_ratio)
      assert Map.has_key?(all_ratios, :education_ratio)
      assert Map.has_key?(all_ratios, :overall_status)
    end

    @tag :unit
    test "provides overall status assessment" do
      profile = %{
        gross_annual_income: Decimal.new("100000"),
        birth_year: 1985,
        mortgage_balance: nil,
        student_loan_balance: nil
      }

      net_worth = Decimal.new("500000")
      annual_savings = Decimal.new("12000")

      result = MoneyRatios.calculate_all_ratios(profile, net_worth, annual_savings)

      assert {:ok, all_ratios} = result
      assert all_ratios.overall_status in [:excellent, :on_track, :needs_attention, :critical]
    end
  end

  describe "get_recommendations/1" do
    @tag :unit
    test "provides recommendations for ratios behind target" do
      ratios = %{
        capital_ratio: %{
          current_ratio: Decimal.new("1.0"),
          target_ratio: Decimal.new("3.0"),
          status: :behind
        },
        savings_ratio: %{
          current_ratio: Decimal.new("0.08"),
          target_ratio: Decimal.new("0.12"),
          status: :behind
        }
      }

      recommendations = MoneyRatios.get_recommendations(ratios)

      assert is_list(recommendations)
      assert length(recommendations) > 0
      assert Enum.any?(recommendations, fn r -> String.contains?(r, "capital") end)
      assert Enum.any?(recommendations, fn r -> String.contains?(r, "savings") end)
    end

    @tag :unit
    test "congratulates when all ratios on track" do
      ratios = %{
        capital_ratio: %{status: :on_track},
        savings_ratio: %{status: :on_track},
        mortgage_ratio: %{status: :on_track},
        education_ratio: %{status: :on_track}
      }

      recommendations = MoneyRatios.get_recommendations(ratios)

      assert Enum.any?(recommendations, fn r -> String.contains?(r, "Excellent") or String.contains?(r, "track") end)
    end
  end
end
