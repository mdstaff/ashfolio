defmodule AshfolioWeb.RetirementLiveTest do
  use AshfolioWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag :liveview
  @moduletag :unit

  describe "Retirement Planning Page" do
    test "retirement page loads successfully", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/retirement")

      assert html =~ "Retirement Planning"
      assert html =~ "Plan your retirement using industry-standard calculations"
    end

    test "displays 25x rule calculation section", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/retirement")

      assert html =~ "25x Rule"
      assert html =~ "Enter your annual expenses and calculate"
      assert html =~ "Annual Expenses"
    end

    test "displays 4% withdrawal rate section", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/retirement")

      assert html =~ "4% Withdrawal Rate"
      assert html =~ "Enter your portfolio value and calculate"
    end

    test "displays retirement progress tracking", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/retirement")

      assert html =~ "Progress Tracking"
      assert html =~ "Current Portfolio"
      assert html =~ "Not calculated"
    end

    test "has expense input form for 25x calculation", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/retirement")

      # Check form fields are present
      assert html =~ "Annual Expenses"
      assert html =~ "Current Portfolio Value"
      assert html =~ "Calculate Target"
    end
  end

  describe "Retirement Calculations" do
    test "calculates 25x target from user input", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/retirement")

      # Submit form with annual expenses
      html =
        view
        |> form("#retirement-form", %{
          "annual_expenses" => "50000",
          "current_portfolio" => "500000"
        })
        |> render_submit()

      # Should display calculated retirement target (25x rule: 50000 * 25 = 1,250,000)
      assert html =~ "1,250,000"
      # Should show progress (500,000 / 1,250,000 = 40%)
      assert html =~ "40.00"
    end

    test "calculates 4% withdrawal from portfolio value", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/retirement")

      # Submit form with portfolio value
      html =
        view
        |> form("#retirement-form", %{
          "annual_expenses" => "50000",
          "current_portfolio" => "1000000"
        })
        |> render_submit()

      # Should display 4% safe withdrawal (1,000,000 * 0.04 = 40,000)
      # Annual withdrawal
      assert html =~ "40,000"
      # Monthly budget (40,000 / 12 = 3,333.33)
      assert html =~ "3,333"
    end
  end

  describe "Historical Data Integration" do
    test "can calculate retirement target from expense history", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/retirement")

      # Click button to use historical expenses
      view
      |> element("#use-historical-expenses")
      |> render_click()

      html = render(view)

      # Should display results based on historical data
      assert html =~ "Based on Historical Expenses"
      assert html =~ "25x Target"
    end
  end
end
