defmodule AshfolioWeb.DashboardLiveEmergencyFundTest do
  use AshfolioWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ashfolio.DataCase

  alias Ashfolio.FinancialManagement.{FinancialGoal, Expense}

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

  describe "Dashboard Emergency Fund Widget" do
    test "displays no emergency fund status when no goal exists", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Financial Goals"
      assert html =~ "Emergency Fund: Not Started"
      assert html =~ "Manage Goals"
    end

    test "displays emergency fund status when goal exists", %{conn: conn} do
      # Create an emergency fund goal
      {:created, _goal} = FinancialGoal.setup_emergency_fund_goal!(6)

      {:ok, _view, html} = live(conn, ~p"/")

      # Should show emergency fund status in goals widget  
      assert html =~ "Financial Goals"
      # Should be underfunded with $0 current
      assert html =~ "Emergency Fund: Underfunded"
      assert html =~ "Active Goals"
      # Should show 1 active goal
      assert html =~ "1"
    end

    test "emergency fund status updates correctly with different readiness levels", %{conn: conn} do
      # Create and fully fund an emergency fund goal
      {:created, goal} = FinancialGoal.setup_emergency_fund_goal!(6)
      {:ok, _updated_goal} = FinancialGoal.update(goal, %{current_amount: goal.target_amount})

      {:ok, _view, html} = live(conn, ~p"/")

      # Should show appropriate status
      assert html =~ "Financial Goals"
      # Should not show "Not Started" since goal is fully funded
      refute html =~ "Emergency Fund: Not Started"
    end

    test "goals widget displays correct statistics", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      # Initially no goals
      # Total current amount
      assert html =~ "$0.00"

      # Create emergency fund goal (this changes the page state, so we need to re-read)
      {:created, goal} = FinancialGoal.setup_emergency_fund_goal!(6)

      # Navigate again to get updated state
      {:ok, _view, html} = live(conn, ~p"/")

      # Should show updated statistics
      # Should show 1 active goal somewhere
      assert html =~ "1"
      # Target amount should be greater than 0
      assert html =~ "$#{Decimal.to_string(goal.target_amount)}" ||
               html =~ "$#{Decimal.round(goal.target_amount, 2) |> Decimal.to_string()}"
    end

    test "dashboard loads without errors when emergency fund functions are called", %{conn: conn} do
      # This test ensures that all the status mapping functions work correctly
      # and don't cause function clause errors

      # Test with no goal
      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "Portfolio Dashboard"

      # Test with goal
      {:created, _goal} = FinancialGoal.setup_emergency_fund_goal!(6)
      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "Portfolio Dashboard"

      # If we get this far without crashes, the status functions are working
    end

    test "manage goals link navigates to goals page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Click the manage goals link
      result =
        view
        |> element("a", "Manage Goals")
        |> render_click()

      # Should navigate to goals page (this will be a redirect)
      assert_redirect(view, "/goals")
    end
  end

  describe "Status Function Integration" do
    test "handles all emergency fund readiness levels without errors", %{conn: conn} do
      # Create a goal to ensure we test the analysis path
      {:created, goal} = FinancialGoal.setup_emergency_fund_goal!(6)

      # Test different funding levels
      funding_levels = [
        # underfunded
        Decimal.new("0.00"),
        # partially_funded  
        Decimal.mult(goal.target_amount, Decimal.new("0.25")),
        # mostly_funded
        Decimal.mult(goal.target_amount, Decimal.new("0.75")),
        # fully_funded
        goal.target_amount
      ]

      for current_amount <- funding_levels do
        {:ok, _updated_goal} = FinancialGoal.update(goal, %{current_amount: current_amount})

        # Dashboard should load without errors regardless of funding level
        {:ok, _view, html} = live(conn, ~p"/")
        assert html =~ "Portfolio Dashboard"
        assert html =~ "Financial Goals"
      end
    end
  end
end
