defmodule Ashfolio.FinancialManagement.EmergencyFundCalculatorTest do
  use Ashfolio.DataCase

  alias Ashfolio.FinancialManagement.{EmergencyFundCalculator, Expense}

  @moduletag :unit

  describe "calculate_emergency_fund_target/2" do
    @tag :unit
    test "calculates 6 months emergency fund by default" do
      monthly_expenses = Decimal.new("4000.00")
      expected = Decimal.new("24000.00")

      assert {:ok, result} =
               EmergencyFundCalculator.calculate_emergency_fund_target(monthly_expenses)

      assert Decimal.equal?(result, expected)
    end

    @tag :unit
    test "calculates custom months emergency fund" do
      monthly_expenses = Decimal.new("5000.00")
      months = 3
      expected = Decimal.new("15000.00")

      assert {:ok, result} =
               EmergencyFundCalculator.calculate_emergency_fund_target(monthly_expenses, months)

      assert Decimal.equal?(result, expected)
    end

    @tag :unit
    test "handles edge cases - zero expenses" do
      monthly_expenses = Decimal.new("0.00")
      expected = Decimal.new("0.00")

      assert {:ok, result} =
               EmergencyFundCalculator.calculate_emergency_fund_target(monthly_expenses)

      assert Decimal.equal?(result, expected)
    end

    @tag :unit
    test "validates negative expenses" do
      monthly_expenses = Decimal.new("-1000.00")

      assert {:error, :negative_expenses} =
               EmergencyFundCalculator.calculate_emergency_fund_target(monthly_expenses)
    end

    @tag :unit
    test "validates invalid months" do
      monthly_expenses = Decimal.new("4000.00")

      assert {:error, :invalid_months} =
               EmergencyFundCalculator.calculate_emergency_fund_target(monthly_expenses, 0)

      assert {:error, :invalid_months} =
               EmergencyFundCalculator.calculate_emergency_fund_target(monthly_expenses, -3)
    end
  end

  describe "calculate_monthly_expenses_from_period/2" do
    setup do
      # Create test expenses for last 12 months
      today = Date.utc_today()

      expenses_data = [
        {Date.add(today, -30), "3500.00"},
        {Date.add(today, -60), "4200.00"},
        {Date.add(today, -90), "3800.00"},
        {Date.add(today, -120), "4000.00"},
        {Date.add(today, -150), "3700.00"},
        {Date.add(today, -180), "4100.00"}
      ]

      expenses =
        for {date, amount} <- expenses_data do
          {:ok, expense} =
            Expense.create(%{
              description: "Test Expense",
              amount: Decimal.new(amount),
              date: date
            })

          expense
        end

      %{expenses: expenses}
    end

    @tag :integration
    test "calculates average monthly expenses from last 12 months", %{expenses: _expenses} do
      assert {:ok, monthly_average} =
               EmergencyFundCalculator.calculate_monthly_expenses_from_period(12)

      # Average should be around 1941.67 (23300 / 12 months)
      # We have 6 expenses totaling 23300 spread over 12 months
      assert Decimal.gt?(monthly_average, Decimal.new("1900.00"))
      assert Decimal.lt?(monthly_average, Decimal.new("2000.00"))
    end

    @tag :integration
    test "handles period with no expenses" do
      # Query future period with no expenses
      assert {:ok, result} =
               EmergencyFundCalculator.calculate_monthly_expenses_from_period(
                 12,
                 Date.add(Date.utc_today(), 365)
               )

      assert Decimal.equal?(result, Decimal.new("0.00"))
    end

    @tag :integration
    test "validates invalid period months" do
      assert {:error, :invalid_period} =
               EmergencyFundCalculator.calculate_monthly_expenses_from_period(0)

      assert {:error, :invalid_period} =
               EmergencyFundCalculator.calculate_monthly_expenses_from_period(-6)
    end
  end

  describe "emergency_fund_status/3" do
    @tag :unit
    test "calculates emergency fund status with current amount" do
      target_amount = Decimal.new("24000.00")
      current_amount = Decimal.new("12000.00")
      monthly_contribution = Decimal.new("1000.00")

      assert {:ok, status} =
               EmergencyFundCalculator.emergency_fund_status(
                 target_amount,
                 current_amount,
                 monthly_contribution
               )

      assert Decimal.equal?(status.target_amount, target_amount)
      assert Decimal.equal?(status.current_amount, current_amount)
      assert Decimal.equal?(status.amount_remaining, Decimal.new("12000.00"))
      assert Decimal.equal?(status.progress_percentage, Decimal.new("50.00"))
      assert status.months_to_goal == 12
    end

    @tag :unit
    test "handles goal already achieved" do
      target_amount = Decimal.new("24000.00")
      current_amount = Decimal.new("25000.00")
      monthly_contribution = Decimal.new("1000.00")

      assert {:ok, status} =
               EmergencyFundCalculator.emergency_fund_status(
                 target_amount,
                 current_amount,
                 monthly_contribution
               )

      assert Decimal.equal?(status.amount_remaining, Decimal.new("0.00"))
      assert Decimal.equal?(status.progress_percentage, Decimal.new("100.00"))
      assert status.months_to_goal == 0
      assert status.goal_achieved == true
    end

    @tag :unit
    test "handles no monthly contribution" do
      target_amount = Decimal.new("24000.00")
      current_amount = Decimal.new("12000.00")
      monthly_contribution = Decimal.new("0.00")

      assert {:ok, status} =
               EmergencyFundCalculator.emergency_fund_status(
                 target_amount,
                 current_amount,
                 monthly_contribution
               )

      assert status.months_to_goal == nil
      assert status.goal_achieved == false
    end
  end

  describe "auto_create_emergency_fund_goal/1" do
    @tag :integration
    test "creates emergency fund goal based on recent expenses" do
      # Create some test expenses
      today = Date.utc_today()

      {:ok, _expense} =
        Expense.create(%{
          description: "Rent",
          amount: Decimal.new("2000.00"),
          date: Date.add(today, -15)
        })

      {:ok, _expense} =
        Expense.create(%{
          description: "Groceries",
          amount: Decimal.new("800.00"),
          date: Date.add(today, -20)
        })

      assert {:ok, goal} = EmergencyFundCalculator.auto_create_emergency_fund_goal(6)

      assert goal.name == "Emergency Fund"
      assert goal.goal_type == :emergency_fund
      assert Decimal.gt?(goal.target_amount, Decimal.new("0.00"))
    end

    @tag :integration
    test "validates custom months parameter" do
      assert {:error, :invalid_months} =
               EmergencyFundCalculator.auto_create_emergency_fund_goal(0)

      assert {:error, :invalid_months} =
               EmergencyFundCalculator.auto_create_emergency_fund_goal(-3)
    end
  end

  describe "FinancialGoal integration" do
    setup do
      alias Ashfolio.FinancialManagement.FinancialGoal

      # Create test expenses for realistic analysis
      today = Date.utc_today()

      {:ok, _expense1} =
        Expense.create(%{
          description: "Monthly Rent",
          amount: Decimal.new("1500.00"),
          date: Date.add(today, -30)
        })

      {:ok, _expense2} =
        Expense.create(%{
          description: "Utilities",
          amount: Decimal.new("200.00"),
          date: Date.add(today, -45)
        })

      {:ok, _expense3} =
        Expense.create(%{
          description: "Groceries",
          amount: Decimal.new("600.00"),
          date: Date.add(today, -60)
        })

      %{financial_goal_module: FinancialGoal}
    end

    @tag :integration
    test "setup_emergency_fund_goal! creates new goal when none exists", %{
      financial_goal_module: financial_goal_module
    } do
      # Ensure no emergency fund goals exist
      goals = financial_goal_module.by_type!(:emergency_fund)
      assert Enum.empty?(goals)

      assert {:created, goal} = financial_goal_module.setup_emergency_fund_goal!(6)

      assert goal.name == "Emergency Fund"
      assert goal.goal_type == :emergency_fund
      assert Decimal.gt?(goal.target_amount, Decimal.new("0.00"))
      assert goal.is_active == true
    end

    @tag :integration
    test "analyze_emergency_fund_readiness! provides comprehensive analysis", %{
      financial_goal_module: financial_goal_module
    } do
      # Create an emergency fund goal first
      {:created, _goal} = financial_goal_module.setup_emergency_fund_goal!(6)

      assert {:analysis, analysis} = financial_goal_module.analyze_emergency_fund_readiness!()

      assert Map.has_key?(analysis, :goal)
      assert Map.has_key?(analysis, :monthly_expenses)
      assert Map.has_key?(analysis, :progress_percentage)
      assert Map.has_key?(analysis, :amount_remaining)
      assert Map.has_key?(analysis, :readiness_level)
      assert Map.has_key?(analysis, :months_coverage)

      # Should be underfunded since we just created it with 0 current amount
      assert analysis.readiness_level == :underfunded
      assert Decimal.equal?(analysis.progress_percentage, Decimal.new("0.00"))
    end

    @tag :integration
    test "analyze_emergency_fund_readiness! handles no goal scenario", %{
      financial_goal_module: financial_goal_module
    } do
      # Ensure no goals exist
      goals = financial_goal_module.by_type!(:emergency_fund)
      assert Enum.empty(goals)

      assert {:no_goal, recommendation} =
               financial_goal_module.analyze_emergency_fund_readiness!()

      assert Map.has_key?(recommendation, :recommended_target)
      assert Map.has_key?(recommendation, :monthly_expenses)
      assert Map.has_key?(recommendation, :months_coverage)
      assert recommendation.status == :no_goal
      assert Decimal.gt?(recommendation.recommended_target, Decimal.new("0.00"))
    end
  end
end
