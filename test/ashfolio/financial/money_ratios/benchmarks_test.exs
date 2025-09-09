defmodule Ashfolio.Financial.MoneyRatios.BenchmarksTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Financial.MoneyRatios.Benchmarks

  describe "capital_target_for_age/1" do
    @tag :unit
    test "returns correct target for young professionals (25-30)" do
      assert Decimal.equal?(Benchmarks.capital_target_for_age(25), Decimal.new("0.5"))
      assert Decimal.equal?(Benchmarks.capital_target_for_age(30), Decimal.new("1.0"))
    end

    @tag :unit
    test "returns increasing targets for mid-career (30-45)" do
      assert Decimal.equal?(Benchmarks.capital_target_for_age(35), Decimal.new("2.0"))
      assert Decimal.equal?(Benchmarks.capital_target_for_age(40), Decimal.new("3.0"))
      assert Decimal.equal?(Benchmarks.capital_target_for_age(45), Decimal.new("5.0"))
    end

    @tag :unit
    test "returns high targets for pre-retirement (45-65)" do
      assert Decimal.equal?(Benchmarks.capital_target_for_age(50), Decimal.new("7.0"))
      assert Decimal.equal?(Benchmarks.capital_target_for_age(55), Decimal.new("9.0"))
      assert Decimal.equal?(Benchmarks.capital_target_for_age(60), Decimal.new("11.0"))
      assert Decimal.equal?(Benchmarks.capital_target_for_age(65), Decimal.new("12.0"))
    end

    @tag :unit
    test "returns retirement-ready target for 65+" do
      assert Decimal.equal?(Benchmarks.capital_target_for_age(67), Decimal.new("12.0"))
      assert Decimal.equal?(Benchmarks.capital_target_for_age(75), Decimal.new("12.0"))
    end

    @tag :unit
    test "handles boundary ages correctly" do
      # Test that age 29 gets young professional target, age 30 gets next tier
      assert Decimal.equal?(Benchmarks.capital_target_for_age(29), Decimal.new("0.5"))
      assert Decimal.equal?(Benchmarks.capital_target_for_age(30), Decimal.new("1.0"))

      # Test other boundaries
      assert Decimal.equal?(Benchmarks.capital_target_for_age(34), Decimal.new("1.0"))
      assert Decimal.equal?(Benchmarks.capital_target_for_age(35), Decimal.new("2.0"))
    end

    @tag :unit
    test "handles edge cases for very young or old ages" do
      assert Decimal.equal?(Benchmarks.capital_target_for_age(18), Decimal.new("0.5"))
      assert Decimal.equal?(Benchmarks.capital_target_for_age(100), Decimal.new("12.0"))
    end
  end

  describe "mortgage_target_for_age/1" do
    @tag :unit
    test "returns decreasing mortgage targets by age" do
      assert Decimal.equal?(Benchmarks.mortgage_target_for_age(25), Decimal.new("2.5"))
      assert Decimal.equal?(Benchmarks.mortgage_target_for_age(30), Decimal.new("2.0"))
      assert Decimal.equal?(Benchmarks.mortgage_target_for_age(40), Decimal.new("1.5"))
      assert Decimal.equal?(Benchmarks.mortgage_target_for_age(50), Decimal.new("1.0"))
      assert Decimal.equal?(Benchmarks.mortgage_target_for_age(60), Decimal.new("0.5"))
      assert Decimal.equal?(Benchmarks.mortgage_target_for_age(65), Decimal.new("0"))
    end
  end

  describe "life_stage_analysis/1" do
    @tag :unit
    test "identifies correct life stage for different ages" do
      assert Benchmarks.life_stage_analysis(25) == %{
               stage: :early_career,
               focus: "Building emergency fund and starting retirement savings",
               priority_ratios: [:savings_ratio, :capital_ratio]
             }

      assert Benchmarks.life_stage_analysis(35) == %{
               stage: :mid_career,
               focus: "Accelerating wealth accumulation and managing debt",
               priority_ratios: [:capital_ratio, :mortgage_ratio]
             }

      assert Benchmarks.life_stage_analysis(50) == %{
               stage: :pre_retirement,
               focus: "Maximizing retirement savings and reducing debt",
               priority_ratios: [:capital_ratio, :mortgage_ratio]
             }

      assert Benchmarks.life_stage_analysis(67) == %{
               stage: :retirement,
               focus: "Preserving wealth and managing withdrawals",
               priority_ratios: [:capital_ratio]
             }
    end
  end

  describe "retirement_readiness_score/2" do
    @tag :unit
    test "calculates readiness score based on age and capital ratio" do
      # Someone at age 40 with 3x income (right on target)
      profile = %{birth_year: Date.utc_today().year - 40}

      ratios = %{
        capital_ratio: %{
          current_ratio: Decimal.new("3.0"),
          target_ratio: Decimal.new("3.0"),
          status: :on_track
        }
      }

      assert Benchmarks.retirement_readiness_score(profile, ratios) == %{
               score: 100,
               assessment: :on_track,
               years_to_retirement: 25
             }
    end

    @tag :unit
    test "penalizes behind-target scenarios" do
      # Someone at age 40 with only 1x income (behind target of 3x)
      profile = %{birth_year: Date.utc_today().year - 40}

      ratios = %{
        capital_ratio: %{
          current_ratio: Decimal.new("1.0"),
          target_ratio: Decimal.new("3.0"),
          status: :behind
        }
      }

      result = Benchmarks.retirement_readiness_score(profile, ratios)
      assert result.score < 50
      assert result.assessment == :behind
    end
  end

  describe "catch_up_recommendations/2" do
    @tag :unit
    test "provides specific catch-up advice for behind scenarios" do
      profile = %{birth_year: Date.utc_today().year - 45}

      ratios = %{
        capital_ratio: %{
          current_ratio: Decimal.new("2.0"),
          target_ratio: Decimal.new("5.0"),
          status: :behind
        },
        savings_ratio: %{
          current_ratio: Decimal.new("0.08"),
          target_ratio: Decimal.new("0.12"),
          status: :behind
        }
      }

      recommendations = Benchmarks.catch_up_recommendations(profile, ratios)

      assert is_list(recommendations)
      assert length(recommendations) > 0
      assert Enum.any?(recommendations, fn r -> String.contains?(r, "catch-up") end)
      assert Enum.any?(recommendations, fn r -> String.contains?(r, "increase savings") end)
    end
  end

  describe "accelerated_timeline/2" do
    @tag :unit
    test "calculates early retirement potential for ahead scenarios" do
      profile = %{birth_year: Date.utc_today().year - 35}

      ratios = %{
        capital_ratio: %{
          current_ratio: Decimal.new("4.0"),
          target_ratio: Decimal.new("2.0"),
          status: :ahead
        }
      }

      timeline = Benchmarks.accelerated_timeline(profile, ratios)

      assert Map.has_key?(timeline, :early_retirement_age)
      assert Map.has_key?(timeline, :years_ahead_of_schedule)
      assert timeline.early_retirement_age < 65
    end
  end
end
