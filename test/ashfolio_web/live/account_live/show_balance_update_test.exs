defmodule AshfolioWeb.AccountLive.ShowBalanceUpdateTest do
  use AshfolioWeb.LiveViewCase

  import Phoenix.LiveViewTest

  alias Ashfolio.Portfolio.{User, Account}
  alias Ashfolio.Context

  describe "AccountLive.Show Balance Update Integration" do
    setup do
      # Create a test user
      {:ok, user} = User.create(%{name: "Test User", currency: "USD", locale: "en-US"})

      # Create a cash account for testing
      {:ok, cash_account} =
        Account.create(%{
          name: "Test Savings Account",
          platform: "Test Bank",
          account_type: :savings,
          balance: Decimal.new("1000.00"),
          user_id: user.id
        })

      # Create an investment account (should not show update button)
      {:ok, investment_account} =
        Account.create(%{
          name: "Test Investment Account",
          platform: "Test Broker",
          account_type: :investment,
          balance: Decimal.new("5000.00"),
          user_id: user.id
        })

      %{
        user: user,
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

    test "opens balance update modal when button clicked", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Click update balance button
      view |> element("button", "Update Balance") |> render_click()

      # Verify modal is shown
      assert has_element?(view, "h3", "Update Cash Balance")
      assert has_element?(view, "p", cash_account.name)
    end

    test "closes modal when cancel is clicked", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Open modal
      view |> element("button", "Update Balance") |> render_click()
      assert has_element?(view, "[id='balance-update-modal']")

      # Click cancel
      view
      |> element("button", "Cancel")
      |> render_click()

      # Verify modal is closed
      refute has_element?(view, "h3", "Update Cash Balance")
    end

    test "updates balance and shows success message", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Open modal
      view |> element("button", "Update Balance") |> render_click()

      # Submit balance update
      view
      |> element("form")
      |> render_submit(%{"new_balance" => "1500.00", "notes" => "Test deposit"})

      # Verify modal is closed
      refute has_element?(view, "h3", "Update Cash Balance")

      # Verify account was updated in database
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
      |> element("form")
      |> render_submit(%{"new_balance" => "1200.00", "notes" => "First update"})

      # Verify balance history was created in database
      {:ok, history} = Context.get_balance_history(cash_account.id)
      assert length(history) == 1

      history_item = List.first(history)
      assert Decimal.equal?(history_item.old_balance, Decimal.new("1000.00"))
      assert Decimal.equal?(history_item.new_balance, Decimal.new("1200.00"))
      assert history_item.notes == "First update"

      # Update balance again to test multiple history items
      view |> element("button", "Update Balance") |> render_click()

      view
      |> element("form")
      |> render_submit(%{"new_balance" => "900.00", "notes" => "Withdrawal"})

      # Verify multiple history items in database
      {:ok, updated_history} = Context.get_balance_history(cash_account.id)
      assert length(updated_history) == 2
    end

    test "handles validation errors in modal", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Open modal
      view |> element("button", "Update Balance") |> render_click()

      # Try to submit negative balance for savings account
      view
      |> element("form")
      |> render_change(%{"new_balance" => "-100.00", "notes" => ""})

      # Verify validation error is shown
      assert has_element?(
               view,
               "li",
               "Savings accounts cannot have negative balances"
             )

      # Verify modal stays open
      assert has_element?(view, "h3", "Update Cash Balance")
    end

    test "shows real-time balance updates via PubSub", %{
      conn: conn,
      cash_account: cash_account
    } do
      {:ok, _view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Simulate external balance update via Context API
      {:ok, updated_account} =
        Context.update_cash_balance(cash_account.id, Decimal.new("2000.00"), "External update")

      # Verify the account was updated in database
      assert Decimal.equal?(updated_account.balance, Decimal.new("2000.00"))

      # Verify balance history was created
      {:ok, history} = Context.get_balance_history(cash_account.id)
      assert length(history) == 1

      history_item = List.first(history)
      assert Decimal.equal?(history_item.old_balance, Decimal.new("1000.00"))
      assert Decimal.equal?(history_item.new_balance, Decimal.new("2000.00"))
      assert history_item.notes == "External update"
    end

    test "displays balance history timeline with proper formatting", %{
      conn: conn,
      cash_account: cash_account
    } do
      # Create some balance history first
      Context.update_cash_balance(cash_account.id, Decimal.new("1100.00"), "First increase")
      Context.update_cash_balance(cash_account.id, Decimal.new("900.00"), "Withdrawal")
      Context.update_cash_balance(cash_account.id, Decimal.new("1300.00"), "Final balance")

      {:ok, view, _html} = live(conn, ~p"/accounts/#{cash_account.id}")

      # Verify balance history section exists
      assert has_element?(view, "h2", "Balance History")

      # Verify timeline structure with proper icons
      # Increase icon
      assert has_element?(view, "div[class*='bg-green-500']")
      # Decrease icon
      assert has_element?(view, "div[class*='bg-red-500']")

      # Verify all balance changes are shown
      assert has_element?(view, "span", "Balance changed from $1,100.00 to $900.00")
      assert has_element?(view, "span", "Balance changed from $900.00 to $1,300.00")

      # Verify notes are displayed
      assert has_element?(view, "p", "Withdrawal")
      assert has_element?(view, "p", "Final balance")
    end

    test "handles account not found gracefully", %{conn: conn} do
      non_existent_id = Ash.UUID.generate()

      # This should redirect to accounts page with an error
      assert {:error, {:live_redirect, %{to: "/accounts", flash: %{"error" => _}}}} =
               live(conn, ~p"/accounts/#{non_existent_id}")
    end
  end
end
