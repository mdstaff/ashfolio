defmodule Ashfolio.FinancialManagement.EmergencyFundStatusTest do
  use ExUnit.Case, async: true

  alias Ashfolio.FinancialManagement.EmergencyFundStatus

  @moduletag :unit

  describe "status_color/1" do
    test "returns correct colors for legacy statuses" do
      assert EmergencyFundStatus.status_color(:adequate) == "text-green-600"
      assert EmergencyFundStatus.status_color(:partial) == "text-yellow-600"
      assert EmergencyFundStatus.status_color(:insufficient) == "text-red-600"
      assert EmergencyFundStatus.status_color(:no_goal) == "text-gray-600"
    end

    test "returns correct colors for readiness levels" do
      assert EmergencyFundStatus.status_color(:fully_funded) == "text-green-600"
      assert EmergencyFundStatus.status_color(:mostly_funded) == "text-green-500"
      assert EmergencyFundStatus.status_color(:partially_funded) == "text-yellow-600"
      assert EmergencyFundStatus.status_color(:underfunded) == "text-red-600"
    end
  end

  describe "dot_color/1" do
    test "returns correct dot colors for legacy statuses" do
      assert EmergencyFundStatus.dot_color(:adequate) == "bg-green-500"
      assert EmergencyFundStatus.dot_color(:partial) == "bg-yellow-500"
      assert EmergencyFundStatus.dot_color(:insufficient) == "bg-red-500"
      assert EmergencyFundStatus.dot_color(:no_goal) == "bg-gray-400"
    end

    test "returns correct dot colors for readiness levels" do
      assert EmergencyFundStatus.dot_color(:fully_funded) == "bg-green-500"
      assert EmergencyFundStatus.dot_color(:mostly_funded) == "bg-green-400"
      assert EmergencyFundStatus.dot_color(:partially_funded) == "bg-yellow-500"
      assert EmergencyFundStatus.dot_color(:underfunded) == "bg-red-500"
    end
  end

  describe "status_label/1" do
    test "returns correct labels for legacy statuses" do
      assert EmergencyFundStatus.status_label(:adequate) == "Ready"
      assert EmergencyFundStatus.status_label(:partial) == "Building"
      assert EmergencyFundStatus.status_label(:insufficient) == "At Risk"
      assert EmergencyFundStatus.status_label(:no_goal) == "Not Started"
    end

    test "returns correct labels for readiness levels" do
      assert EmergencyFundStatus.status_label(:fully_funded) == "Fully Funded"
      assert EmergencyFundStatus.status_label(:mostly_funded) == "Well Funded"
      assert EmergencyFundStatus.status_label(:partially_funded) == "Building"
      assert EmergencyFundStatus.status_label(:underfunded) == "Underfunded"
    end
  end

  describe "status collections" do
    test "legacy_statuses/0 returns all legacy statuses" do
      expected = [:adequate, :partial, :insufficient, :no_goal]
      assert EmergencyFundStatus.legacy_statuses() == expected
    end

    test "readiness_levels/0 returns all readiness levels" do
      expected = [:fully_funded, :mostly_funded, :partially_funded, :underfunded]
      assert EmergencyFundStatus.readiness_levels() == expected
    end

    test "all_statuses/0 returns both legacy and readiness levels" do
      expected = [
        :adequate,
        :partial,
        :insufficient,
        :no_goal,
        :fully_funded,
        :mostly_funded,
        :partially_funded,
        :underfunded
      ]

      assert EmergencyFundStatus.all_statuses() == expected
    end
  end

  describe "comprehensive status coverage" do
    test "all status functions handle every status level" do
      all_statuses = EmergencyFundStatus.all_statuses()

      for status <- all_statuses do
        # Should not raise function clause errors
        assert is_binary(EmergencyFundStatus.status_color(status))
        assert is_binary(EmergencyFundStatus.dot_color(status))
        assert is_binary(EmergencyFundStatus.status_label(status))
      end
    end

    test "status colors follow expected patterns" do
      # Green variants for good statuses
      good_statuses = [:adequate, :fully_funded, :mostly_funded]

      for status <- good_statuses do
        color = EmergencyFundStatus.status_color(status)
        assert String.contains?(color, "green")
      end

      # Yellow for building/partial statuses
      building_statuses = [:partial, :partially_funded]

      for status <- building_statuses do
        color = EmergencyFundStatus.status_color(status)
        assert String.contains?(color, "yellow")
      end

      # Red for problematic statuses
      problem_statuses = [:insufficient, :underfunded]

      for status <- problem_statuses do
        color = EmergencyFundStatus.status_color(status)
        assert String.contains?(color, "red")
      end

      # Gray for no goal
      assert String.contains?(EmergencyFundStatus.status_color(:no_goal), "gray")
    end
  end

  describe "backwards compatibility" do
    test "legacy status mappings are preserved" do
      # Ensure we don't accidentally break existing UI that might use legacy statuses
      assert EmergencyFundStatus.status_color(:adequate) == "text-green-600"
      assert EmergencyFundStatus.status_label(:adequate) == "Ready"
      assert EmergencyFundStatus.dot_color(:adequate) == "bg-green-500"
    end
  end
end
