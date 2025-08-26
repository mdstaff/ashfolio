defmodule Ashfolio.FinancialManagement.EmergencyFundCalculatorTest do
  use Ashfolio.DataCase

  alias Ashfolio.FinancialManagement.{EmergencyFundCalculator, Expense, FinancialGoal}

  describe "calculate_monthly_expenses/1" do
    @tag :unit
    test "returns zero when no expenses exist" do
      assert {:ok, amount} = EmergencyFundCalculator.calculate_monthly_expenses()
      assert Decimal.equal?(amount, Decimal.new("0"))
    end

    @tag :integration
    test "calculates average monthly expenses correctly" do
      # Create expenses for 3 months
      today = Date.utc_today()

      # Month 1: $3000
      {:ok, _} =
        Expense.create(%{
          description: "Rent",
          amount: Decimal.new("2000"),
          date: Date.add(today, -60)
        })

      {:ok, _} =
        Expense.create(%{
          description: "Groceries",
          amount: Decimal.new("1000"),
          date: Date.add(today, -55)
        })

      # Month 2: $3500
      {:ok, _} =
        Expense.create(%{
          description: "Rent",
          amount: Decimal.new("2000"),
          date: Date.add(today, -30)
        })

      {:ok, _} =
        Expense.create(%{
          description: "Groceries",
          amount: Decimal.new("1500"),
          date: Date.add(today, -25)
        })

      # Month 3: $2500
      {:ok, _} =
        Expense.create(%{
          description: "Rent",
          amount: Decimal.new("2000"),
          date: Date.add(today, -5)
        })

      {:ok, _} =
        Expense.create(%{
          description: "Groceries",
          amount: Decimal.new("500"),
          date: Date.add(today, -2)
        })

      assert {:ok, average} = EmergencyFundCalculator.calculate_monthly_expenses(3)

      # Average should be (3000 + 3500 + 2500) / 3 = 3000
      assert Decimal.equal?(average, Decimal.new("3000.00"))
    end
  end

  describe "calculate_target/2" do
    @tag :unit
    test "calculates emergency fund target for default 6 months" do
      monthly_expenses = Decimal.new("3000")
      assert {:ok, target} = EmergencyFundCalculator.calculate_target(monthly_expenses)
      assert Decimal.equal?(target, Decimal.new("18000.00"))
    end

    @tag :unit
    test "calculates target for custom months coverage" do
      monthly_expenses = Decimal.new("3000")
      assert {:ok, target} = EmergencyFundCalculator.calculate_target(monthly_expenses, 3)
      assert Decimal.equal?(target, Decimal.new("9000.00"))

      assert {:ok, target} = EmergencyFundCalculator.calculate_target(monthly_expenses, 12)
      assert Decimal.equal?(target, Decimal.new("36000.00"))
    end

    @tag :unit
    test "validates months coverage range" do
      monthly_expenses = Decimal.new("3000")

      assert {:error, message} = EmergencyFundCalculator.calculate_target(monthly_expenses, 2)
      assert message =~ "at least 3"

      assert {:error, message} = EmergencyFundCalculator.calculate_target(monthly_expenses, 13)
      assert message =~ "cannot exceed 12"
    end
  end

  describe "setup_emergency_fund_goal/1" do
    @tag :integration
    test "creates new emergency fund goal when none exists" do
      # Create some expenses first
      create_sample_expenses()

      assert {:ok, goal} =
               EmergencyFundCalculator.setup_emergency_fund_goal(
                 months_coverage: 6,
                 months_history: 3
               )

      assert goal.goal_type == :emergency_fund
      assert goal.name == "Emergency Fund (6 months)"
      assert goal.is_active == true
      # With our sample data averaging $3000/month, 6 months = $18000
      assert Decimal.equal?(goal.target_amount, Decimal.new("18000.00"))
    end

    @tag :integration
    test "updates existing emergency fund goal" do
      # Create initial goal
      {:ok, initial_goal} =
        FinancialGoal.create(%{
          name: "Old Emergency Fund",
          target_amount: Decimal.new("10000"),
          goal_type: :emergency_fund,
          current_amount: Decimal.new("5000")
        })

      # Create expenses
      create_sample_expenses()

      assert {:ok, updated_goal} =
               EmergencyFundCalculator.setup_emergency_fund_goal(
                 months_coverage: 9,
                 months_history: 3
               )

      assert updated_goal.id == initial_goal.id
      assert updated_goal.name == "Emergency Fund (9 months)"
      assert Decimal.equal?(updated_goal.target_amount, Decimal.new("27000.00"))
      # Current amount should be preserved
      assert Decimal.equal?(updated_goal.current_amount, Decimal.new("5000"))
    end
  end

  describe "calculate_monthly_contribution_needed/1" do
    @tag :unit
    test "calculates monthly contribution to reach goal by target date" do
      goal = %{
        target_amount: Decimal.new("18000"),
        current_amount: Decimal.new("3000"),
        # ~10 months from now
        target_date: Date.add(Date.utc_today(), 300)
      }

      assert {:ok, monthly} = EmergencyFundCalculator.calculate_monthly_contribution_needed(goal)
      # Need $15000 in 10 months = $1500/month
      assert Decimal.equal?(monthly, Decimal.new("1500.00"))
    end

    @tag :unit
    test "returns zero when goal is already met" do
      goal = %{
        target_amount: Decimal.new("18000"),
        current_amount: Decimal.new("20000"),
        target_date: Date.add(Date.utc_today(), 180)
      }

      assert {:ok, monthly} = EmergencyFundCalculator.calculate_monthly_contribution_needed(goal)
      assert Decimal.equal?(monthly, Decimal.new("0"))
    end

    @tag :unit
    test "handles missing or past target date" do
      goal_no_date = %{
        target_amount: Decimal.new("18000"),
        current_amount: Decimal.new("3000"),
        target_date: nil
      }

      assert {:error, "No target date set for goal"} =
               EmergencyFundCalculator.calculate_monthly_contribution_needed(goal_no_date)

      goal_past_date = %{
        target_amount: Decimal.new("18000"),
        current_amount: Decimal.new("3000"),
        target_date: Date.add(Date.utc_today(), -10)
      }

      assert {:error, "Target date has passed"} =
               EmergencyFundCalculator.calculate_monthly_contribution_needed(goal_past_date)
    end
  end

  describe "analyze_readiness/0" do
    @tag :integration
    test "provides comprehensive analysis with no goal" do
      create_sample_expenses()

      assert {:ok, analysis} = EmergencyFundCalculator.analyze_readiness()

      assert analysis.status == :no_goal
      assert Decimal.equal?(analysis.monthly_expenses, Decimal.new("3000.00"))
      assert Decimal.equal?(analysis.recommended_target, Decimal.new("18000.00"))
      assert analysis.recommendation =~ "Create an emergency fund goal"
    end

    @tag :integration
    test "analyzes partially funded emergency fund" do
      create_sample_expenses()

      {:ok, _goal} =
        FinancialGoal.create(%{
          name: "Emergency Fund",
          target_amount: Decimal.new("18000"),
          current_amount: Decimal.new("9000"),
          goal_type: :emergency_fund
        })

      assert {:ok, analysis} = EmergencyFundCalculator.analyze_readiness()

      assert analysis.status == :partial
      assert Decimal.equal?(analysis.current_coverage_months, Decimal.new("3.0"))
      assert Decimal.equal?(analysis.progress_percentage, Decimal.new("50.00"))
      assert analysis.recommendation =~ "Good progress"
    end

    @tag :integration
    test "recognizes fully funded emergency fund" do
      create_sample_expenses()

      {:ok, _goal} =
        FinancialGoal.create(%{
          name: "Emergency Fund",
          target_amount: Decimal.new("18000"),
          current_amount: Decimal.new("18000"),
          goal_type: :emergency_fund
        })

      assert {:ok, analysis} = EmergencyFundCalculator.analyze_readiness()

      assert analysis.status == :adequate
      assert Decimal.equal?(analysis.current_coverage_months, Decimal.new("6.0"))
      assert Decimal.equal?(analysis.progress_percentage, Decimal.new("100.00"))
      assert analysis.recommendation =~ "fully funded"
    end
  end

  describe "project_growth/3" do
    @tag :unit
    test "projects emergency fund growth over time" do
      goal = %{
        current_amount: Decimal.new("5000"),
        target_amount: Decimal.new("18000")
      }

      monthly_contribution = Decimal.new("1500")

      assert {:ok, projections} =
               EmergencyFundCalculator.project_growth(goal, monthly_contribution, 12)

      assert length(projections) == 12

      # Check first month
      first = hd(projections)
      assert first.month == 1
      assert Decimal.equal?(first.projected_amount, Decimal.new("6500"))
      assert Decimal.equal?(first.progress_percentage, Decimal.new("36.11"))
      assert first.is_complete == false

      # Check month when goal is reached (month 9: 5000 + 9*1500 = 18500, capped at 18000)
      month_9 = Enum.at(projections, 8)
      assert month_9.month == 9
      assert Decimal.equal?(month_9.projected_amount, Decimal.new("18000"))
      assert Decimal.equal?(month_9.progress_percentage, Decimal.new("100.00"))
      assert month_9.is_complete == true
    end

    @tag :unit
    test "handles already completed goals" do
      goal = %{
        current_amount: Decimal.new("20000"),
        target_amount: Decimal.new("18000")
      }

      assert {:ok, projections} =
               EmergencyFundCalculator.project_growth(goal, Decimal.new("500"), 6)

      # All projections should show 100% complete
      Enum.each(projections, fn projection ->
        assert Decimal.equal?(projection.projected_amount, Decimal.new("18000"))
        assert Decimal.equal?(projection.progress_percentage, Decimal.new("100.00"))
        assert projection.is_complete == true
      end)
    end
  end

  # Helper function to create sample expenses
  defp create_sample_expenses do
    today = Date.utc_today()

    # Create consistent $3000/month expenses
    Enum.each([60, 30, 5], fn days_ago ->
      {:ok, _} =
        Expense.create(%{
          description: "Monthly Expenses",
          amount: Decimal.new("3000"),
          date: Date.add(today, -days_ago)
        })
    end)
  end
end
