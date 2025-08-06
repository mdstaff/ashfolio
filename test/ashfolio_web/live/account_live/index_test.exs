defmodule AshfolioWeb.AccountLive.IndexTest do
  use AshfolioWeb.LiveViewCase

  alias Ashfolio.Portfolio.{Account, User, Transaction, Symbol}

  setup do
    # Create default user
    {:ok, user} = User.create(%{name: "Test User", currency: "USD", locale: "en-US"})

    # Create test accounts
    {:ok, account1} =
      Account.create(%{
        name: "Test Account 1",
        platform: "Test Platform",
        balance: Decimal.new("1000.00"),
        user_id: user.id
      })

    {:ok, account2} =
      Account.create(%{
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

    test "displays form fields when creating new account", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      html = index_live |> element("button", "New Account") |> render_click()

      # Check that form fields are present
      assert html =~ "Account Name"
      assert html =~ "Platform"
      assert html =~ "Current Balance"
      assert html =~ "Exclude from portfolio calculations"
      assert html =~ "Create Account"
    end

    test "can cancel form", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Open form
      index_live |> element("button", "New Account") |> render_click()

      # Cancel form
      index_live
      |> element("button[phx-click='cancel']")
      |> render_click()

      # Get the updated HTML after the cancel action
      html = render(index_live)

      # Form should be closed - check for form-specific elements
      refute html =~ "Account Name"
      refute html =~ "Current Balance"
      refute html =~ "Create Account"
    end

    test "validates form fields", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Open form
      index_live |> element("button", "New Account") |> render_click()

      # Try to submit empty form
      html =
        index_live
        |> form("#account-form", form: %{name: ""})
        |> render_submit()

      # Should show validation errors
      assert html =~ "can't be blank" or html =~ "is required"
    end

    test "creates account with valid data", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Open form
      index_live |> element("button", "New Account") |> render_click()

      # Submit valid form
      index_live
      |> form("#account-form",
        form: %{
          name: "New Test Account",
          platform: "Test Platform",
          balance: "5000.00"
        }
      )
      |> render_submit()

      # Get the updated HTML after the form submission
      html = render(index_live)

      # Should show success message and new account
      assert html =~ "Account created successfully with balance of $5,000.00"
      assert html =~ "New Test Account"
      assert html =~ "$5,000.00"
    end
  end

  describe "account editing" do
    test "opens edit form with pre-populated data", %{conn: conn, account1: account1} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Click edit button
      html =
        index_live
        |> element("button[phx-click='edit_account'][phx-value-id='#{account1.id}']")
        |> render_click()

      # Should show edit form with pre-populated data
      assert html =~ "Edit Account"
      assert html =~ "Update Account"

      # Check that form fields are pre-populated with account data
      assert html =~ ~s(value="#{account1.name}")
      assert html =~ ~s(value="#{account1.platform}")
      assert html =~ ~s(value="#{account1.balance}")
    end

    test "can cancel edit form", %{conn: conn, account1: account1} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Open edit form
      index_live
      |> element("button[phx-click='edit_account'][phx-value-id='#{account1.id}']")
      |> render_click()

      # Cancel form
      index_live
      |> element("button[phx-click='cancel']")
      |> render_click()

      # Get the updated HTML after the cancel action
      html = render(index_live)

      # Form should be closed
      refute html =~ "Edit Account"
      refute html =~ "Update Account"
      refute html =~ "Account Name"
    end

    test "validates edit form fields", %{conn: conn, account1: account1} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Open edit form
      index_live
      |> element("button[phx-click='edit_account'][phx-value-id='#{account1.id}']")
      |> render_click()

      # Try to submit form with empty name
      html =
        index_live
        |> form("#account-form", form: %{name: ""})
        |> render_submit()

      # Should show validation errors
      assert html =~ "can't be blank" or html =~ "is required"
    end

    test "updates account with valid data", %{conn: conn, account1: account1} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Open edit form
      index_live
      |> element("button[phx-click='edit_account'][phx-value-id='#{account1.id}']")
      |> render_click()

      # Submit updated form data
      index_live
      |> form("#account-form",
        form: %{
          name: "Updated Account Name",
          platform: "Updated Platform",
          balance: "3000.00",
          is_excluded: "true"
        }
      )
      |> render_submit()

      # Get the updated HTML after the form submission
      html = render(index_live)

      # Should show success message and updated account data
      assert html =~ "Account updated successfully"
      assert html =~ "Updated Account Name"
      assert html =~ "Updated Platform"
      assert html =~ "$3,000.00"
      assert html =~ "Excluded"
    end

    test "handles edit form validation errors", %{conn: conn, account1: account1} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Open edit form
      index_live
      |> element("button[phx-click='edit_account'][phx-value-id='#{account1.id}']")
      |> render_click()

      # Submit form with invalid balance (negative)
      html =
        index_live
        |> form("#account-form",
          form: %{
            name: "Valid Name",
            balance: "-100.00"
          }
        )
        |> render_submit()

      # Should show validation error for negative balance
      assert html =~ "cannot be negative" or html =~ "must be greater than or equal to"
    end

    test "preserves other accounts when editing one account", %{
      conn: conn,
      account1: account1,
      account2: account2
    } do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Open edit form for account1
      index_live
      |> element("button[phx-click='edit_account'][phx-value-id='#{account1.id}']")
      |> render_click()

      # Update account1
      index_live
      |> form("#account-form",
        form: %{
          name: "Updated Account 1",
          platform: "Updated Platform"
        }
      )
      |> render_submit()

      # Get the updated HTML
      html = render(index_live)

      # Should show updated account1 and unchanged account2
      assert html =~ "Updated Account 1"
      assert html =~ "Updated Platform"
      # account2 should remain unchanged
      assert html =~ account2.name
      # account2 platform should remain unchanged
      assert html =~ account2.platform
    end
  end

  describe "account management" do
    test "toggles account exclusion", %{conn: conn, account1: account1} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Toggle exclusion
      html =
        index_live
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
      html =
        index_live
        |> element("button[phx-click='toggle_exclusion'][phx-value-id='#{account1.id}']")
        |> render_click()

      # After toggle, should show success message and "Include" button
      assert html =~ "Account exclusion updated successfully"
      assert html =~ "Include"
    end

    test "deletes account with confirmation", %{conn: conn, account1: account1} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Delete account
      html =
        index_live
        |> element("button[phx-click='delete_account'][phx-value-id='#{account1.id}']")
        |> render_click()

      # Check that the account was deleted
      assert html =~ "Account deleted successfully"
    end
  end

  describe "account deletion" do
    test "deletes account with no transactions", %{conn: conn, account1: account1} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Verify account exists initially
      assert render(index_live) =~ account1.name

      # Delete account (account1 has no transactions by default)
      html =
        index_live
        |> element("button[phx-click='delete_account'][phx-value-id='#{account1.id}']")
        |> render_click()

      # Should show success message
      assert html =~ "Account deleted successfully"

      # Account should no longer appear in the list
      refute html =~ account1.name
    end

    test "prevents deletion of account with transactions", %{
      conn: conn,
      account1: account1,
      user: user
    } do
      # First create a symbol for the transaction
      {:ok, symbol} =
        Symbol.create(%{
          symbol: "AAPL",
          name: "Apple Inc.",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("150.00")
        })

      # Create a transaction for account1
      {:ok, _transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("150.00"),
          total_amount: Decimal.new("1500.00"),
          fee: Decimal.new("0.00"),
          date: Date.utc_today(),
          account_id: account1.id,
          symbol_id: symbol.id
        })

      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Verify account exists initially
      assert render(index_live) =~ account1.name

      # Try to delete account with transactions
      html =
        index_live
        |> element("button[phx-click='delete_account'][phx-value-id='#{account1.id}']")
        |> render_click()

      # Should show error message preventing deletion
      assert html =~ "Cannot delete account with transactions"
      assert html =~ "Consider excluding it instead"

      # Account should still appear in the list
      assert html =~ account1.name
    end

    test "shows helpful error message when deletion prevented", %{
      conn: conn,
      account1: account1,
      user: user
    } do
      # Create a symbol and transaction for account1
      {:ok, symbol} =
        Symbol.create(%{
          symbol: "TSLA",
          name: "Tesla Inc.",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("200.00")
        })

      {:ok, _transaction} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("-5"),
          price: Decimal.new("200.00"),
          total_amount: Decimal.new("-1000.00"),
          fee: Decimal.new("5.00"),
          date: Date.utc_today(),
          account_id: account1.id,
          symbol_id: symbol.id
        })

      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Try to delete account with transactions
      html =
        index_live
        |> element("button[phx-click='delete_account'][phx-value-id='#{account1.id}']")
        |> render_click()

      # Should show specific error message with helpful suggestion
      assert html =~ "Cannot delete account with transactions"
      assert html =~ "Consider excluding it instead"
    end

    test "suggests account exclusion as alternative", %{
      conn: conn,
      account1: account1,
      user: user
    } do
      # Create a symbol and transaction for account1
      {:ok, symbol} =
        Symbol.create(%{
          symbol: "NVDA",
          name: "NVIDIA Corporation",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("300.00")
        })

      {:ok, _transaction} =
        Transaction.create(%{
          type: :dividend,
          quantity: Decimal.new("2"),
          price: Decimal.new("1.50"),
          total_amount: Decimal.new("3.00"),
          fee: Decimal.new("0.00"),
          date: Date.utc_today(),
          account_id: account1.id,
          symbol_id: symbol.id
        })

      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Try to delete account with transactions
      html =
        index_live
        |> element("button[phx-click='delete_account'][phx-value-id='#{account1.id}']")
        |> render_click()

      # Should suggest exclusion as alternative
      assert html =~ "Consider excluding it instead"

      # Verify that the exclusion toggle button is still available
      assert html =~ "Exclude"
    end

    test "allows deletion after all transactions are removed", %{
      conn: conn,
      account1: account1,
      user: user
    } do
      # Create a symbol and transaction for account1
      {:ok, symbol} =
        Symbol.create(%{
          symbol: "MSFT",
          name: "Microsoft Corporation",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("250.00")
        })

      {:ok, transaction} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("8"),
          price: Decimal.new("250.00"),
          total_amount: Decimal.new("2000.00"),
          fee: Decimal.new("10.00"),
          date: Date.utc_today(),
          account_id: account1.id,
          symbol_id: symbol.id
        })

      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # First attempt should fail
      html =
        index_live
        |> element("button[phx-click='delete_account'][phx-value-id='#{account1.id}']")
        |> render_click()

      assert html =~ "Cannot delete account with transactions"

      # Remove the transaction
      Transaction.destroy(transaction)

      # Refresh the page to get updated state
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Now deletion should succeed
      html =
        index_live
        |> element("button[phx-click='delete_account'][phx-value-id='#{account1.id}']")
        |> render_click()

      assert html =~ "Account deleted successfully"
      refute html =~ account1.name
    end
  end
end
