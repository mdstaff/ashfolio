defmodule AshfolioWeb.AccountLive.FormComponentTest do
  use AshfolioWeb.LiveViewCase, async: true

  alias Ashfolio.Portfolio.Account
  alias AshfolioWeb.AccountLive.FormComponent

  describe "FormComponent" do
    test "submitting a valid form creates an account", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/accounts")

      view |> element("button", "New Account") |> render_click()

      assert has_element?(view, "#account-form")

      view
      |> form("#account-form", account: %{name: "Valid Account", platform: "Valid Platform", balance: "1234.56"})
      |> render_submit()

      refute has_element?(view, "#account-form")
      assert render(view) =~ "Valid Account"
    end

    test "submitting an invalid form shows validation errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/accounts")

      view |> element("button", "New Account") |> render_click()

      assert has_element?(view, "#account-form")

      view
      |> form("#account-form", account: %{name: "", platform: "", balance: "-100"})
      |> render_submit()

      assert has_element?(view, "#account-form")
      assert render(view) =~ "Account name is required"
      assert render(view) =~ "Account balance cannot be negative"
    end
  end
end