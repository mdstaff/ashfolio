defmodule Ashfolio.FinancialManagement.FinancialGoalTest do
  use Ashfolio.DataCase

  alias Ashfolio.FinancialManagement.FinancialGoal

  describe "create/1" do
    @tag :unit
    test "creates a financial goal with valid attributes" do
      attrs = %{
        name: "Emergency Fund",
        target_amount: Decimal.new("10000.00"),
        goal_type: :emergency_fund
      }

      assert {:ok, goal} = FinancialGoal.create(attrs)
      assert goal.name == "Emergency Fund"
      assert Decimal.equal?(goal.target_amount, Decimal.new("10000.00"))
      assert Decimal.equal?(goal.current_amount, Decimal.new("0"))
      assert goal.goal_type == :emergency_fund
      assert goal.is_active == true
    end

    @tag :unit
    test "fails without required fields" do
      assert {:error, _} = FinancialGoal.create(%{})
      assert {:error, _} = FinancialGoal.create(%{name: "Test"})
      assert {:error, _} = FinancialGoal.create(%{target_amount: Decimal.new("1000")})
    end

    @tag :unit
    test "validates target amount must be positive" do
      attrs = %{
        name: "Invalid Goal",
        target_amount: Decimal.new("-100"),
        goal_type: :custom
      }

      assert {:error, changeset} = FinancialGoal.create(attrs)
      assert %{target_amount: ["must be greater than 0"]} = errors_on(changeset)
    end

    @tag :unit
    test "validates goal type must be valid" do
      attrs = %{
        name: "Invalid Type Goal",
        target_amount: Decimal.new("1000"),
        goal_type: :invalid_type
      }

      assert {:error, _changeset} = FinancialGoal.create(attrs)
    end

    @tag :unit
    test "creates goal with optional monthly contribution" do
      attrs = %{
        name: "House Down Payment",
        target_amount: Decimal.new("50000.00"),
        goal_type: :house_down_payment,
        monthly_contribution: Decimal.new("1000.00"),
        target_date: ~D[2025-12-31]
      }

      assert {:ok, goal} = FinancialGoal.create(attrs)
      assert Decimal.equal?(goal.monthly_contribution, Decimal.new("1000.00"))
      assert goal.target_date == ~D[2025-12-31]
    end
  end

  describe "update/2" do
    @tag :unit
    test "updates goal progress" do
      {:ok, goal} =
        FinancialGoal.create(%{
          name: "Vacation Fund",
          target_amount: Decimal.new("5000.00"),
          goal_type: :vacation
        })

      assert {:ok, updated} =
               FinancialGoal.update(goal, %{
                 current_amount: Decimal.new("2500.00")
               })

      assert Decimal.equal?(updated.current_amount, Decimal.new("2500.00"))
    end

    @tag :unit
    test "cannot update goal type" do
      {:ok, goal} =
        FinancialGoal.create(%{
          name: "Emergency Fund",
          target_amount: Decimal.new("10000.00"),
          goal_type: :emergency_fund
        })

      # Goal type is not in the update accept list, so this should error
      assert {:error, _} =
               FinancialGoal.update(goal, %{
                 goal_type: :retirement
               })

      # Verify goal type remains unchanged in database
      refetched = FinancialGoal.get_by_id!(goal.id)
      assert refetched.goal_type == :emergency_fund
    end
  end

  describe "calculations" do
    @tag :unit
    test "calculates progress percentage correctly" do
      {:ok, goal} =
        FinancialGoal.create(%{
          name: "Test Goal",
          target_amount: Decimal.new("1000.00"),
          current_amount: Decimal.new("250.00"),
          goal_type: :custom
        })

      goal = Ash.load!(goal, [:progress_percentage])
      assert Decimal.equal?(goal.progress_percentage, Decimal.new("25.00"))
    end

    @tag :unit
    test "calculates months to goal when monthly contribution is set" do
      {:ok, goal} =
        FinancialGoal.create(%{
          name: "Test Goal",
          target_amount: Decimal.new("12000.00"),
          current_amount: Decimal.new("2000.00"),
          monthly_contribution: Decimal.new("1000.00"),
          goal_type: :custom
        })

      goal = Ash.load!(goal, [:months_to_goal])
      assert goal.months_to_goal == 10
    end

    @tag :unit
    test "calculates amount remaining" do
      {:ok, goal} =
        FinancialGoal.create(%{
          name: "Test Goal",
          target_amount: Decimal.new("5000.00"),
          current_amount: Decimal.new("1500.00"),
          goal_type: :custom
        })

      goal = Ash.load!(goal, [:amount_remaining])
      assert Decimal.equal?(goal.amount_remaining, Decimal.new("3500.00"))
    end

    @tag :unit
    test "determines if goal is complete" do
      {:ok, incomplete_goal} =
        FinancialGoal.create(%{
          name: "Incomplete",
          target_amount: Decimal.new("1000.00"),
          current_amount: Decimal.new("500.00"),
          goal_type: :custom
        })

      {:ok, complete_goal} =
        FinancialGoal.create(%{
          name: "Complete",
          target_amount: Decimal.new("1000.00"),
          current_amount: Decimal.new("1000.00"),
          goal_type: :custom
        })

      incomplete = Ash.load!(incomplete_goal, [:is_complete])
      complete = Ash.load!(complete_goal, [:is_complete])

      assert incomplete.is_complete == false
      assert complete.is_complete == true
    end
  end

  describe "query actions" do
    @tag :integration
    test "filters active goals" do
      {:ok, active} =
        FinancialGoal.create(%{
          name: "Active Goal",
          target_amount: Decimal.new("1000.00"),
          goal_type: :custom,
          is_active: true
        })

      {:ok, _inactive} =
        FinancialGoal.create(%{
          name: "Inactive Goal",
          target_amount: Decimal.new("1000.00"),
          goal_type: :custom,
          is_active: false
        })

      active_goals = FinancialGoal.active!()
      assert length(active_goals) == 1
      assert hd(active_goals).id == active.id
    end

    @tag :integration
    test "filters by goal type" do
      {:ok, emergency} =
        FinancialGoal.create(%{
          name: "Emergency Fund",
          target_amount: Decimal.new("10000.00"),
          goal_type: :emergency_fund
        })

      {:ok, _retirement} =
        FinancialGoal.create(%{
          name: "Retirement",
          target_amount: Decimal.new("1000000.00"),
          goal_type: :retirement
        })

      emergency_goals = FinancialGoal.by_type!(:emergency_fund)
      assert length(emergency_goals) == 1
      assert hd(emergency_goals).id == emergency.id
    end
  end

  describe "helper functions" do
    @tag :integration
    test "emergency_fund_status! returns correct status" do
      # No goal case
      assert {:no_goal, _} = FinancialGoal.emergency_fund_status!(Decimal.new("2000.00"))

      # Create emergency fund goal
      {:ok, _goal} =
        FinancialGoal.create(%{
          name: "Emergency Fund",
          target_amount: Decimal.new("12000.00"),
          current_amount: Decimal.new("8000.00"),
          goal_type: :emergency_fund
        })

      # Test adequate status (8000 / 2000 = 4 months)
      assert {:partial, months} = FinancialGoal.emergency_fund_status!(Decimal.new("2000.00"))
      assert Decimal.equal?(months, Decimal.new("4.0"))

      # Test insufficient status
      assert {:insufficient, months} =
               FinancialGoal.emergency_fund_status!(Decimal.new("5000.00"))

      assert Decimal.equal?(months, Decimal.new("1.6"))
    end

    @tag :integration
    test "goal_progress_summary! aggregates by type" do
      # Create multiple goals
      {:ok, _} =
        FinancialGoal.create(%{
          name: "Emergency Fund",
          target_amount: Decimal.new("10000.00"),
          current_amount: Decimal.new("5000.00"),
          goal_type: :emergency_fund
        })

      {:ok, _} =
        FinancialGoal.create(%{
          name: "Vacation 1",
          target_amount: Decimal.new("3000.00"),
          current_amount: Decimal.new("1000.00"),
          goal_type: :vacation
        })

      {:ok, _} =
        FinancialGoal.create(%{
          name: "Vacation 2",
          target_amount: Decimal.new("2000.00"),
          current_amount: Decimal.new("2000.00"),
          goal_type: :vacation
        })

      summary = FinancialGoal.goal_progress_summary!()

      assert Map.has_key?(summary, :emergency_fund)
      assert Map.has_key?(summary, :vacation)

      emergency_summary = summary[:emergency_fund]
      assert emergency_summary.goal_count == 1
      assert Decimal.equal?(emergency_summary.total_target, Decimal.new("10000.00"))
      assert Decimal.equal?(emergency_summary.overall_progress, Decimal.new("50.00"))

      vacation_summary = summary[:vacation]
      assert vacation_summary.goal_count == 2
      assert vacation_summary.completed_count == 1
      assert Decimal.equal?(vacation_summary.total_target, Decimal.new("5000.00"))
      assert Decimal.equal?(vacation_summary.total_current, Decimal.new("3000.00"))
    end
  end
end
