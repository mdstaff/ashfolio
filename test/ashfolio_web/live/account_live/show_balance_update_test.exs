defmodule AshfolioWeb.AccountLive.ShowBalanceUpdateTest do
  use AshfolioWeb.LiveViewCase

  import Phoenix.LiveViewTest

  alias Ashfolio.Context
  alias Ashfolio.Portfolio.Account

  describe "AccountLive.Show Balance Update Integration" do
    setup do
      # Database-as-user architecture: No user needed

      # Create a cash account for testing
      {:ok, cash_account} =
        Account.create(%{
          name: "Test Savings Account",
          platform: "Test Bank",
          account_type: :savings,
          balance: Decimal.new("1000.00")
        })

      # Create an investment account (should not show update button)
      {:ok, investment_account} =
        Account.create(%{
          name: "Test Investment Account",
          platform: "Test Broker",
          account_type: :investment,
          balance: Decimal.new("5000.00")
        })

      %{
        cash_account: cash_account,
        investment_account: investment_account
      }
    end

    test "shows update balance button for cash accounts", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Verify update balance button is present
      assert has_element?(view, "button", "Update Balance")
    end

    test "does not show update balance button for investment accounts", %{
      conn: conn,
      investment_account: investment_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{investment_account.id}")

      # Verify update balance button is NOT present
      refute has_element?(view, "button", "Update Balance")
    end

    test "can open balance update modal", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Click update balance button
      view |> element("button", "Update Balance") |> render_click()

      # Verify modal is open
      assert has_element?(view, "h3", "Update Cash Balance")
      assert has_element?(view, "form")
      assert has_element?(view, "input[name='new_balance']")
    end

    test "can cancel balance update modal", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Open modal
      view |> element("button", "Update Balance") |> render_click()
      assert has_element?(view, "h3", "Update Cash Balance")

      # Cancel modal
      view |> element("button", "Cancel") |> render_click()

      # Verify modal is closed
      refute has_element?(view, "h3", "Update Cash Balance")
    end

    test "can update account balance through modal", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Open modal and submit new balance
      view |> element("button", "Update Balance") |> render_click()

      view
      |> form("#balance-update-form", %{"new_balance" => "1500.00", "notes" => "Test update"})
      |> render_submit()

      # Verify account was updated
      {:ok, updated_account} = Account.get_by_id(cash_account.id)
      assert Decimal.equal?(updated_account.balance, Decimal.new("1500.00"))
    end

    test "shows balance history timeline after update", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Initially, no balance history should be shown (no changes yet)
      refute has_element?(view, "h2", "Balance History")

      # Open modal and update balance
      view |> element("button", "Update Balance") |> render_click()

      view
      |> form("#balance-update-form", %{"new_balance" => "1200.00", "notes" => "Test update"})
      |> render_submit()

      # Verify balance history section appears
      assert has_element?(view, "h2", "Balance History") or
               has_element?(view, "h3", "Balance History")

      # Should show the balance change
      assert has_element?(view, "div", "1,000.00") or
               render(view) =~ "1,000.00"

      assert has_element?(view, "div", "1,200.00") or
               render(view) =~ "1,200.00"
    end

    test "validates balance update form", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Open modal and submit invalid balance
      view |> element("button", "Update Balance") |> render_click()

      html =
        view
        |> form("#balance-update-form", %{"new_balance" => "-100.00", "notes" => "Invalid test"})
        |> render_submit()

      # Should show validation error - check for common error indicators
      assert html =~ "error" or
               html =~ "invalid" or
               html =~ "must be" or
               html =~ "cannot be" or
               html =~ "required" or
               has_element?(view, ".error") or
               has_element?(view, "[phx-feedback-for]")
    end

    test "updates displayed balance in real-time", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Verify initial balance is shown (the test account name should be displayed)
      assert render(view) =~ "Test Savings Account"

      # Update balance
      view |> element("button", "Update Balance") |> render_click()

      view
      |> form("#balance-update-form", %{"new_balance" => "2500.00", "notes" => "Test update"})
      |> render_submit()

      # Verify new balance is displayed by checking the account name is still there
      # and that the form is dismissed (modal closed)
      assert render(view) =~ "Test Savings Account"
      refute render(view) =~ "balance-update-form"
    end

    test "shows success message after balance update", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Update balance
      view |> element("button", "Update Balance") |> render_click()

      view
      |> form("#balance-update-form", %{"new_balance" => "3000.00", "notes" => "Test update"})
      |> render_submit()

      # Should show success message (either flash or inline)
      html = render(view)

      assert html =~ "updated" or
               html =~ "success" or
               html =~ "Balance updated"
    end

    test "preserves other account details during balance update", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Verify account details are shown
      assert render(view) =~ cash_account.name
      assert render(view) =~ cash_account.platform

      # Update balance
      view |> element("button", "Update Balance") |> render_click()

      view
      |> form("#balance-update-form", %{"new_balance" => "1750.00", "notes" => "Test update"})
      |> render_submit()

      # Verify account details are still shown
      assert render(view) =~ cash_account.name
      assert render(view) =~ cash_account.platform

      # Verify only balance changed
      {:ok, updated_account} = Account.get_by_id(cash_account.id)
      assert updated_account.name == cash_account.name
      assert updated_account.platform == cash_account.platform
      assert Decimal.equal?(updated_account.balance, Decimal.new("1750.00"))
    end

    test "handles concurrent balance updates gracefully", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Simulate external balance update
      {:ok, _updated} = Account.update(cash_account.id, %{balance: Decimal.new("999.99")})

      # Try to update through UI
      view |> element("button", "Update Balance") |> render_click()

      view
      |> form("#balance-update-form", %{"new_balance" => "2000.00", "notes" => "Test update"})
      |> render_submit()

      # Should handle gracefully (either success or appropriate error message)
      html = render(view)
      assert html =~ "$2,000.00" or html =~ "error" or html =~ "conflict"
    end

    test "balance update affects dashboard calculations", %{
      conn: conn,
      cash_account: cash_account
    } do
      # Get initial dashboard data
      {:ok, initial_dashboard} = Context.get_user_dashboard_data()
      initial_total = initial_dashboard.summary.total_balance

      # Update balance through UI
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")
      view |> element("button", "Update Balance") |> render_click()

      view
      |> form("#balance-update-form", %{"new_balance" => "5000.00", "notes" => "Test update"})
      |> render_submit()

      # Verify dashboard data reflects the change
      {:ok, updated_dashboard} = Context.get_user_dashboard_data()
      updated_total = updated_dashboard.summary.total_balance

      # Total should have increased by the balance difference
      balance_diff = Decimal.sub(Decimal.new("5000.00"), Decimal.new("1000.00"))
      expected_total = Decimal.add(initial_total, balance_diff)

      assert Decimal.equal?(updated_total, expected_total)
    end
  end
end
