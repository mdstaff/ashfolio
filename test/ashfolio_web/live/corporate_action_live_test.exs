defmodule AshfolioWeb.CorporateActionLiveTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  @moduletag :live

  describe "Index" do
    test "lists corporate actions", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/corporate-actions")

      assert html =~ "Corporate Actions"
      assert html =~ "Manage stock splits, dividends, and other corporate actions"
      assert html =~ "No corporate actions found"
    end

    @tag :flaky
    test "saves new corporate action", %{conn: conn} do
      # First, we need some test data - create a symbol
      symbol = Ashfolio.SQLiteHelpers.get_or_create_symbol("TEST", %{name: "Test Corp"})

      {:ok, index_live, _html} = live(conn, ~p"/corporate-actions")

      # Click the new corporate action link
      result = index_live |> element("a", "New Corporate Action") |> render_click()

      # Check if we get a live redirect (which would indicate an error)
      case result do
        {:error, {:live_redirect, %{to: to}}} ->
          # Navigate to the new path manually
          {:ok, _index_live, _html} = live(conn, to)

        _ ->
          # Normal patch behavior
          assert_patch(index_live, ~p"/corporate-actions/new")
      end

      # Fill out the form
      assert index_live
             |> form("#corporate-action-form",
               corporate_action: %{
                 action_type: "stock_split",
                 symbol_id: symbol.id,
                 ex_date: "2024-06-01",
                 description: "2:1 stock split test",
                 split_ratio_from: "1",
                 split_ratio_to: "2"
               }
             )
             |> render_submit()

      assert_patch(index_live, ~p"/corporate-actions")

      html = render(index_live)
      assert html =~ "Corporate action created successfully"
      assert html =~ "2:1 stock split test"
    end
  end
end
