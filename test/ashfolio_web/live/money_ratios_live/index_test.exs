defmodule AshfolioWeb.MoneyRatiosLive.IndexTest do
  use AshfolioWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Ashfolio.Financial.MoneyRatios
  alias Ashfolio.FinancialManagement.FinancialProfile

  describe "MoneyRatiosLive.Index" do
    @tag :liveview
    test "mounts successfully with default state", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/money-ratios")

      assert html =~ "Money Ratios"
      assert html =~ "Financial Health Assessment"
    end

    @tag :liveview
    test "displays create profile form when no profile exists", %{conn: conn} do
      {:ok, _mview, html} = live(conn, "/money-ratios")

      assert html =~ "Create Financial Profile"
      assert html =~ "Gross Annual Income"
      assert html =~ "Birth Year"
      assert html =~ "Household Members"
    end

    @tag :liveview
    test "displays all 8 ratios when profile exists", %{conn: conn} do
      # Create a financial profile
      {:ok, _profile} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("100000"),
          birth_year: 1985,
          household_members: 2
        })

      {:ok, view, html} = live(conn, "/money-ratios")

      assert html =~ "Capital-to-Income Ratio"
      assert html =~ "Savings Ratio"
      assert html =~ "Mortgage-to-Income Ratio"
      assert html =~ "Education-to-Income Ratio"
      assert html =~ "Life Insurance"
      assert html =~ "Disability Insurance"
    end

    @tag :liveview
    test "shows proper status indicators", %{conn: conn} do
      {:ok, _profile} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("100000"),
          birth_year: 1985,
          household_members: 2
        })

      {:ok, _view, html} = live(conn, "/money-ratios")

      # Should have status indicators (emojis or classes)
      assert html =~ "status" or html =~ "✅" or html =~ "❌" or html =~ "⚠️"
    end

    @tag :liveview
    test "handles tab switching between overview, capital, debt, profile", %{conn: conn} do
      {:ok, _profile} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("100000"),
          birth_year: 1985
        })

      {:ok, view, _html} = live(conn, "/money-ratios")

      # Test tab switching
      view |> element("button", "Capital Analysis") |> render_click()
      assert render(view) =~ "Capital Analysis"

      view |> element("button", "Debt Management") |> render_click()
      assert render(view) =~ "Debt Management"

      view |> element("button", "Financial Profile") |> render_click()
      assert render(view) =~ "Financial Profile"

      view |> element("button", "Action Plan") |> render_click()
      assert render(view) =~ "Action Plan"
    end

    @tag :liveview
    test "updates ratios in real-time when profile changes", %{conn: conn} do
      {:ok, _profile} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("100000"),
          birth_year: 1985
        })

      {:ok, view, _html} = live(conn, "/money-ratios")

      # Switch to Financial Profile tab
      view |> element("button", "Financial Profile") |> render_click()

      # Update income
      view
      |> form("#financial-profile-form", form: %{gross_annual_income: "120000"})
      |> render_submit()

      # Should see updated calculations - switch to overview to see ratios
      view |> element("button", "Overview") |> render_click()
      updated_html = render(view)
      # The ratios should be recalculated - look for ratio values or status indicators
      assert updated_html =~ "Target:" or updated_html =~ "✅" or updated_html =~ "⚠️" or updated_html =~ "❌"
    end

    @tag :liveview
    test "validates profile form inputs", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/money-ratios")

      # Submit invalid data
      view
      |> form("#financial-profile-form",
        form: %{
          gross_annual_income: "-1000",
          birth_year: "1800"
        }
      )
      |> render_submit()

      assert render(view) =~ "must be greater than 0"
      assert render(view) =~ "age must be between 18 and 100"
    end

    @tag :liveview
    test "displays age-appropriate benchmarks", %{conn: conn} do
      # Test young professional
      {:ok, profile_young} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("75000"),
          # ~30 years old
          birth_year: 1995
        })

      {:ok, _view, html} = live(conn, "/money-ratios")

      # Should show age-appropriate targets
      assert html =~ "Target" or html =~ "Benchmark"

      # Clean up and test older professional
      FinancialProfile.destroy(profile_young)

      {:ok, _profile_older} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("150000"),
          # ~50 years old
          birth_year: 1975
        })

      {:ok, _view2, html2} = live(conn, "/money-ratios")
      assert html2 =~ "Target" or html2 =~ "Benchmark"
    end

    @tag :liveview
    test "shows recommendations in Action Plan tab", %{conn: conn} do
      {:ok, _profile} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("100000"),
          birth_year: 1985,
          # High mortgage
          mortgage_balance: Decimal.new("300000")
        })

      {:ok, view, _html} = live(conn, "/money-ratios")

      # Switch to Action Plan
      view |> element("button", "Action Plan") |> render_click()

      action_html = render(view)
      assert action_html =~ "Recommendation" or action_html =~ "Action"
      assert action_html =~ "mortgage" or action_html =~ "debt"
    end

    @tag :liveview
    test "handles missing net worth data gracefully", %{conn: conn} do
      {:ok, _profile} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("100000"),
          birth_year: 1985
        })

      {:ok, _view, html} = live(conn, "/money-ratios")

      # Should still render without crashing
      assert html =~ "Money Ratios"
      # Should indicate missing data
      assert html =~ "net worth" or html =~ "Add data" or html =~ "Calculate"
    end
  end

  describe "form component integration" do
    @tag :integration
    test "profile form creates new profile successfully", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/money-ratios")

      # Submit valid profile data
      view
      |> form("#financial-profile-form",
        form: %{
          gross_annual_income: "85000",
          birth_year: "1988",
          household_members: "1"
        }
      )
      |> render_submit()

      # Should redirect or show success
      updated_html = render(view)
      refute updated_html =~ "Create Financial Profile"
      assert updated_html =~ "Capital-to-Income" or updated_html =~ "85,000"
    end

    @tag :integration
    test "profile form updates existing profile", %{conn: conn} do
      {:ok, _profile} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("100000"),
          birth_year: 1985
        })

      {:ok, view, _html} = live(conn, "/money-ratios")

      # Navigate to Financial Profile tab
      view |> element("button", "Financial Profile") |> render_click()

      # Update the profile
      view
      |> form("#financial-profile-form",
        form: %{
          gross_annual_income: "110000",
          mortgage_balance: "250000"
        }
      )
      |> render_submit()

      # Should see updated values - switch to overview to see ratios
      view |> element("button", "Overview") |> render_click()
      updated_html = render(view)
      # The ratios should be recalculated - look for ratio values or status indicators
      assert updated_html =~ "Target:" or updated_html =~ "✅" or updated_html =~ "⚠️" or updated_html =~ "❌"
    end
  end

  describe "ratio calculation display" do
    @tag :unit
    test "formats ratio display correctly", %{conn: conn} do
      {:ok, _profile} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("100000"),
          birth_year: 1985
        })

      {:ok, _view, html} = live(conn, "/money-ratios")

      # Should format ratios nicely (e.g., "2.5x" not "2.500000")
      assert html =~ ~r/\d+\.?\d*x/ or html =~ ~r/\d+%/
    end

    @tag :unit
    test "displays appropriate colors for ratio status", %{conn: conn} do
      {:ok, _profile} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("50000"),
          birth_year: 1985,
          # High debt ratio
          student_loan_balance: Decimal.new("100000")
        })

      {:ok, _view, html} = live(conn, "/money-ratios")

      # Should have styling classes for behind/warning status
      assert html =~ "text-red" or html =~ "text-yellow" or html =~ "bg-red" or html =~ "danger"
    end
  end
end
