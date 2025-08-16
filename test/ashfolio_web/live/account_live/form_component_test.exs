defmodule AshfolioWeb.AccountLive.FormComponentTest do
  use AshfolioWeb.LiveViewCase, async: false

  @moduletag :liveview
  @moduletag :unit
  @moduletag :fast


  describe "FormComponent" do
    test "submitting a valid form creates an account", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/accounts")

      view |> element("button", "New Account") |> render_click()

      assert has_element?(view, "#account-form")

      unique_name = "Valid Account #{System.unique_integer([:positive])}"

      view
      |> form("#account-form",
        form: %{name: unique_name, platform: "Valid Platform", balance: "1234.56"}
      )
      |> render_submit()

      # Wait a moment for the form to process
      Process.sleep(100)

      refute has_element?(view, "#account-form")
      assert render(view) =~ unique_name
    end

    test "submitting an invalid form shows validation errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/accounts")

      view |> element("button", "New Account") |> render_click()

      assert has_element?(view, "#account-form")

      view
      |> form("#account-form", form: %{name: "", platform: "", balance: "-100"})
      |> render_submit()

      assert has_element?(view, "#account-form")
      assert render(view) =~ "Account name is required"
      assert render(view) =~ "Account balance cannot be negative"
    end
  end
end
