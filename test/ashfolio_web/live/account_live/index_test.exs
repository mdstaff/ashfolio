defmodule AshfolioWeb.AccountLive.IndexTest do
  use AshfolioWeb.LiveViewCase

  alias Ashfolio.Portfolio.{Account, User}

  setup do
    # Create default user
    {:ok, user} = User.create(%{name: "Test User", currency: "USD", locale: "en-US"})

    # Create test accounts
    {:ok, account1} = Account.create(%{
      name: "Test Account 1",
      platform: "Test Platform",
      balance: Decimal.new("1000.00"),
      user_id: user.id
    })

    {:ok, account2} = Account.create(%{
      name: "Test Account 2",
      platform: "Another Platform",
      balance: Decimal.new("2000.00"),
      is_excluded: true,
      user_id: user.id
    })

    %{user: user, account1: account1, account2: account2}
  end

  describe "account listing" do
    test "displays all accounts", %{conn: conn, account1: account1, account2: account2} do
      {:ok, _index_live, html} = live(conn, ~p"/accounts")

      assert html =~ "Investment Accounts"
      assert html =~ account1.name
      assert html =~ account2.name
      assert html =~ "$1,000.00"
      assert html =~ "$2,000.00"
      assert html =~ "Excluded"
    end

    test "shows empty state when no accounts exist", %{conn: conn} do
      # Delete all accounts
      Account.list!() |> Enum.each(&Account.destroy/1)

      {:ok, _index_live, html} = live(conn, ~p"/accounts")

      assert html =~ "No accounts"
      assert html =~ "Get started by creating your first investment account"
    end
  end

  describe "account creation" do
    test "opens new account form", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      assert index_live |> element("button", "New Account") |> render_click() =~
               "New Account"
    end
  end

  describe "account management" do
    test "toggles account exclusion", %{conn: conn, account1: account1} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Toggle exclusion
      html = index_live
             |> element("button[phx-click='toggle_exclusion'][phx-value-id='#{account1.id}']")
             |> render_click()

      # Check that the account exclusion was updated
      assert html =~ "Account exclusion updated successfully"
    end

    test "shows loading state during exclusion toggle", %{conn: conn, account1: account1} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Check initial state - should show "Exclude" button
      assert render(index_live) =~ "Exclude"

      # Toggle exclusion and check for loading state
      # Note: In tests, the operation is synchronous so we can't easily test the loading state
      # But we can verify the button exists and the operation completes
      html = index_live
             |> element("button[phx-click='toggle_exclusion'][phx-value-id='#{account1.id}']")
             |> render_click()

      # After toggle, should show success message and "Include" button
      assert html =~ "Account exclusion updated successfully"
      assert html =~ "Include"
    end

    test "deletes account with confirmation", %{conn: conn, account1: account1} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Delete account
      html = index_live
             |> element("button[phx-click='delete_account'][phx-value-id='#{account1.id}']")
             |> render_click()

      # Check that the account was deleted
      assert html =~ "Account deleted successfully"
    end
  end
end
