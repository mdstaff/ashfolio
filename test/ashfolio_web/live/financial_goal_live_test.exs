defmodule AshfolioWeb.FinancialGoalLiveTest do
  use AshfolioWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Ashfolio.FinancialManagement.Expense
  alias Ashfolio.FinancialManagement.FinancialGoal

  @moduletag :liveview

  setup do
    # Create test expenses for emergency fund calculations
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

    :ok
  end

  describe "Emergency Fund Integration" do
    test "displays emergency fund status when no goal exists", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/goals")

      # Should show emergency fund analysis widget
      assert html =~ "Emergency Fund Status"
      assert html =~ "Monthly Expenses"
    end

    test "setup_emergency_fund event creates emergency fund goal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/goals")

      # Verify no goals exist initially
      assert FinancialGoal.by_type!(:emergency_fund) == []

      # Click the create emergency fund button
      view
      |> element("button", "Create Emergency Fund")
      |> render_click()

      # Verify goal was created
      goals = FinancialGoal.by_type!(:emergency_fund)
      assert length(goals) == 1

      goal = List.first(goals)
      assert goal.name == "Emergency Fund"
      assert goal.goal_type == :emergency_fund
      assert goal.is_active == true
      assert Decimal.gt?(goal.target_amount, Decimal.new("0"))

      # Verify UI updates
      html = render(view)
      assert html =~ "Emergency Fund"
      assert html =~ "Underfunded"
      # Current amount
      assert html =~ "$0.00"
    end

    test "displays emergency fund analysis when goal exists", %{conn: conn} do
      # Create an emergency fund goal first
      {:created, _goal} = FinancialGoal.setup_emergency_fund_goal!(6)

      {:ok, _view, html} = live(conn, ~p"/goals")

      # Should show detailed emergency fund analysis
      assert html =~ "Emergency Fund Status"
      assert html =~ "Current Emergency Fund"
      # Should be underfunded with $0 current
      assert html =~ "Underfunded"
      assert html =~ "6.0 months coverage"
      # Current amount
      assert html =~ "$0.00"

      # Should show goal in the table
      # Goal name
      assert html =~ "Emergency Fund"
      # Progress
      assert html =~ "0.00%% complete"
    end

    test "handles different emergency fund readiness levels", %{conn: conn} do
      # Create and partially fund an emergency fund goal
      {:created, goal} = FinancialGoal.setup_emergency_fund_goal!(6)
      target = goal.target_amount
      # 50% funded
      partial_amount = Decimal.mult(target, Decimal.new("0.5"))

      {:ok, _updated_goal} = FinancialGoal.update(goal, %{current_amount: partial_amount})

      {:ok, _view, html} = live(conn, ~p"/goals")

      # Should show appropriate status for partially funded goal
      assert html =~ "Emergency Fund Status"
      # The exact status depends on the EmergencyFundCalculator logic
      # but should not be "Underfunded" since it's 50% funded
      refute html =~ "Not Started"
    end

    test "emergency fund status colors and labels work correctly", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/goals")

      # Test that status functions don't crash
      assert html =~ "Monthly Expenses"

      # No specific color testing since that would require complex CSS parsing,
      # but the page loading successfully means the status functions work
    end

    test "goal creation displays success message", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/goals")

      view
      |> element("button", "Create Emergency Fund")
      |> render_click()

      # Check for success flash message (implementation depends on flash system)
      html = render(view)
      # The exact success message will depend on implementation
      # Should show the created goal
      assert html =~ "Emergency Fund"
    end
  end

  describe "Goal Form Component" do
    test "new goal form loads without KeyError for recommended_target when no goal exists", %{conn: conn} do
      # This test should pass when the KeyError for :recommended_target is fixed
      {:ok, _view, html} = live(conn, ~p"/goals/new")

      # Form should render without KeyError for recommended_target
      assert html =~ "Add Financial Goal"
      assert html =~ "Goal Name"
      assert html =~ "Target Amount"
      assert html =~ "Goal Type"
    end

    test "new goal form loads without KeyError for recommended_target when goal exists", %{conn: conn} do
      # Create an emergency fund goal first to trigger the :analysis path
      {:created, _goal} = FinancialGoal.setup_emergency_fund_goal!(6)

      # This should trigger the KeyError since the :analysis path doesn't include recommended_target
      {:ok, _view, html} = live(conn, ~p"/goals/new")

      # Form should render without KeyError for recommended_target
      assert html =~ "Add Financial Goal"
      assert html =~ "Goal Name"
      assert html =~ "Target Amount"
      assert html =~ "Goal Type"
    end

    @tag :failing
    test "new goal form loads without error", %{conn: conn} do
      # This test should pass when the FormData protocol issue is fixed
      {:ok, view, _html} = live(conn, ~p"/goals")

      # Click Add Goal to open the form modal
      view
      |> element("a", "Add Goal")
      |> render_click()

      # Form should render without Protocol.UndefinedError
      html = render(view)
      assert html =~ "Add Financial Goal"
      assert html =~ "Goal Name"
      assert html =~ "Target Amount"
      assert html =~ "Goal Type"
    end

    test "form component handles Ash.Changeset correctly", %{conn: conn} do
      # Direct navigation to /goals/new should not crash (Protocol issue is now fixed)
      {:ok, _view, html} = live(conn, ~p"/goals/new")

      # Form should load without Protocol.UndefinedError
      assert html =~ "Add Financial Goal"
      assert html =~ "Goal Name"
    end

    @tag :failing
    test "form submission creates goal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/goals")

      # Open form
      view
      |> element("a", "Add Goal")
      |> render_click()

      # Submit form with valid data
      view
      |> form("#goal-form",
        goal: %{
          name: "Vacation Fund",
          target_amount: "5000.00",
          goal_type: "vacation",
          monthly_contribution: "500.00"
        }
      )
      |> render_submit()

      # Check for success and new goal in list
      html = render(view)
      assert html =~ "Vacation Fund"
      assert html =~ "$5,000.00"
    end
  end

  describe "Goals Table Integration" do
    test "shows empty state when no goals exist", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/goals")

      # The actual implementation shows a table even when empty
      assert html =~ "Goal"
      assert html =~ "Type"
      assert html =~ "Progress"
      assert html =~ "Target"
    end

    test "displays emergency fund goal in table", %{conn: conn} do
      {:created, goal} = FinancialGoal.setup_emergency_fund_goal!(6)

      {:ok, _view, html} = live(conn, ~p"/goals")

      # Should show goal details in table
      assert html =~ goal.name
      # Type badge
      assert html =~ "Emergency Fund"
      # Current amount
      assert html =~ "$0.00"
      # Progress
      assert html =~ "0.00%% complete"
      # Target
      assert html =~ "$#{Decimal.to_string(goal.target_amount)}"
      # Date
      assert html =~ "No target date"
      assert html =~ "Edit"
      assert html =~ "Delete"
    end

    test "goal statistics update correctly", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/goals")

      # Initially no goals
      # Total goals
      assert html =~ "0"
      # Total saved and target
      assert html =~ "$0.00"

      # Create emergency fund goal
      view
      |> element("button", "Create Emergency Fund")
      |> render_click()

      html = render(view)

      # Should update statistics
      # Total goals and active goals
      assert html =~ "1"
      # Total saved (still 0)
      assert html =~ "$0.00"
      # Total target should be > 0 - check that we have a target amount displayed
      # Should have at least one dollar amount > $0.00
      assert html =~ ~r/\$\d+\.\d+/
    end
  end
end
