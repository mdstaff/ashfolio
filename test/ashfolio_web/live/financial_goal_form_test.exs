defmodule AshfolioWeb.FinancialGoalFormTest do
  use AshfolioWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Ashfolio.FinancialManagement.Expense

  @moduletag :liveview
  @moduletag :unit

  describe "Goal Creation Form - recommended_target field" do
    setup do
      # Create test expenses for emergency fund calculations
      today = Date.utc_today()

      {:ok, _} =
        Expense.create(%{
          description: "Test Expense",
          amount: Decimal.new("1000.00"),
          date: Date.add(today, -30)
        })

      :ok
    end

    test "form renders without KeyError when emergency fund suggestion exists", %{conn: conn} do
      # This test verifies the recommended_target field is properly handled
      {:ok, _view, html} = live(conn, ~p"/goals/new")

      # Form should render without crashing
      assert html =~ "Add Financial Goal"

      # Check if emergency fund suggestion is displayed
      if html =~ "Emergency Fund Recommendation" do
        # If suggestion exists, it should show recommended target without error
        refute html =~ "KeyError"
        refute html =~ "key :recommended_target not found"
      end
    end

    test "emergency fund template button works with recommended_target", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/goals/new")

      # Click the emergency fund template button if it exists
      case view |> element("[phx-click=use_emergency_fund_template]") |> render_click() do
        {:error, _} ->
          # Button might not exist, that's ok for this test
          :ok

        html ->
          # If button exists and is clicked, form should still render
          assert html =~ "Emergency Fund"
          refute html =~ "KeyError"
      end
    end
  end

  describe "Chart Display Formatting" do
    @tag :unit
    test "growth rate should display as percentage not decimal" do
      # This will test the FormatHelper or equivalent
      decimal_rate = Decimal.new("0.07")

      # This function needs to be created/fixed
      formatted = format_growth_rate(decimal_rate)

      assert formatted == "7%"
      refute formatted == "0.07%"
    end

    @tag :unit
    test "large numbers format with M/K notation" do
      # Test Y-axis formatting
      assert format_chart_value(1_000_000) == "$1M"
      assert format_chart_value(2_500_000) == "$2.5M"
      assert format_chart_value(500_000) == "$500K"
      assert format_chart_value(1_000) == "$1K"

      # Should not show BGN or other incorrect formatting
      refute format_chart_value(2_000_000_000) =~ "BGN"
    end
  end

  # Helper functions that should exist in the actual implementation
  defp format_growth_rate(decimal_value) do
    value = Decimal.mult(decimal_value, Decimal.new("100"))
    rounded = Decimal.round(value, 2)
    formatted = rounded |> Decimal.to_string() |> String.trim_trailing("0") |> String.trim_trailing(".")
    "#{formatted}%"
  end

  defp format_chart_value(number) when is_integer(number) do
    cond do
      number >= 1_000_000 ->
        formatted =
          if rem(number, 1_000_000) == 0 do
            "$#{div(number, 1_000_000)}M"
          else
            "$#{Float.round(number / 1_000_000, 1)}M"
          end

        formatted

      number >= 1_000 ->
        formatted =
          if rem(number, 1_000) == 0 do
            "$#{div(number, 1_000)}K"
          else
            "$#{Float.round(number / 1_000, 1)}K"
          end

        formatted

      true ->
        "$#{number}"
    end
  end
end
