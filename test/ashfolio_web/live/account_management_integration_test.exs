defmodule AshfolioWeb.AccountManagementIntegrationTest do
  use AshfolioWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Ashfolio.Portfolio.Account

  describe "Account Management Workflow" do
    test "user can create, edit, and delete an account", %{conn: conn} do
      # 1. Start at the accounts page
      {:ok, view, _html} = live(conn, ~p"/accounts")

      # 2. Click "New Account" button
      view |> element("button", "New Account") |> render_click()

      # 3. Fill out and submit the form
      view
      |> form("#account-form", account: %{name: "Test Account", platform: "Test Platform", balance: "1000"})
      |> render_submit()

      # 4. Verify the new account is in the list
      assert render(view) =~ "Test Account"
      assert render(view) =~ "Test Platform"
      assert render(view) =~ "$1,000.00"

      # 5. Get the new account
      [account] = Account.accounts_for_user!(get_default_user_id()) |> Enum.filter(&(&1.name == "Test Account"))

      # 6. Click the "Edit" button
      view |> element("button[phx-value-id='#{account.id}']", "Edit") |> render_click()

      # 7. Edit the form and submit
      view
      |> form("#account-form", account: %{name: "Updated Account", balance: "2000"})
      |> render_submit()

      # 8. Verify the updated account is in the list
      assert render(view) =~ "Updated Account"
      assert render(view) =~ "$2,000.00"

      # 9. Click the "Delete" button
      view |> element("button[phx-value-id='#{account.id}']", "Delete") |> render_click()

      # 10. Confirm the deletion
      view |> render_confirm()

      # 11. Verify the account is no longer in the list
      refute render(view) =~ "Updated Account"
    end
  end

  defp get_default_user_id do
    [user] = Ashfolio.Portfolio.User.get_default_user!()
    user.id
  end
end
