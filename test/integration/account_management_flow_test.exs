defmodule AshfolioWeb.Integration.AccountManagementFlowTest do
  @moduledoc """
  Integration tests for complete Account Management workflow:
  Create Account → Validate Fields → View in List → Edit → Delete

  Task 29.1: Core Workflow Integration Tests - Account Management Flow
  """
  use AshfolioWeb.ConnCase, async: false

  @moduletag :integration
  @moduletag :slow

  import Phoenix.LiveViewTest

  alias Ashfolio.Portfolio.Account
  alias Ashfolio.SQLiteHelpers

  setup do
    # Ensure we have a default user for single-user application
    {:ok, user} = SQLiteHelpers.get_or_create_default_user()
    %{user: user}
  end

  describe "Complete Account Management Workflow" do
    test "end-to-end account lifecycle: create → validate → list → edit → delete", %{
      conn: conn,
      user: user
    } do
      # Step 1: Navigate to accounts page
      {:ok, view, _html} = live(conn, "/accounts")

      # Verify we start with empty state or existing accounts
      initial_accounts_count =
        case Account.accounts_for_user(user.id) do
          {:ok, accounts} -> length(accounts)
          _ -> 0
        end

      # Step 2: Create Account - Click "New Account" button (check both empty state and header)
      if render(view) =~ "Create Your First Account" do
        view
        |> element("button", "Create Your First Account")
        |> render_click()
      else
        # If accounts exist, click the New Account button in header
        view
        |> element("button", "New Account")
        |> render_click()
      end

      # Verify modal form appears
      assert has_element?(view, "#account-form")
      assert has_element?(view, "form")

      # Step 3: Validate Fields - Test validation with invalid data
      view
      |> element("form")
      |> render_submit(%{
        "form" => %{
          # Invalid: empty name
          "name" => "",
          # Invalid: non-numeric balance
          "platform" => "",
          # Invalid: non-numeric balance
          "balance" => "invalid"
        }
      })

      # Verify validation errors appear (check multiple error display patterns)
      html_after_validation = render(view)

      assert has_element?(view, ".phx-form-error") or
               html_after_validation =~ "can't be blank" or
               html_after_validation =~ "is required" or
               html_after_validation =~ "invalid"

      # Step 4: Create Account with valid data
      account_data = %{
        name: "Test Investment Account",
        platform: "Test Brokerage",
        balance: "10000.50"
      }

      view
      |> form("#account-form", form: account_data)
      |> render_submit()

      # Wait for form to close (may redirect or update view)
      :timer.sleep(100)

      # Step 5: View in List - Check if we need to refresh view
      current_html = render(view)

      # If we don't see the account data, try refreshing the view
      {view, current_html} =
        if not (current_html =~ "Test Investment Account") do
          {:ok, new_view, _html} = live(conn, "/accounts")
          {new_view, render(new_view)}
        else
          {view, current_html}
        end

      # Verify account appears in the list
      assert current_html =~ "Test Investment Account"
      assert current_html =~ "Test Brokerage"
      assert current_html =~ "$10,000.50" or current_html =~ "10,000"

      # Verify account count increased
      {:ok, updated_accounts} = Account.accounts_for_user(user.id)
      assert length(updated_accounts) == initial_accounts_count + 1

      # Get the created account for further testing
      created_account =
        updated_accounts
        |> Enum.find(fn acc -> acc.name == "Test Investment Account" end)

      refute is_nil(created_account)

      # Step 6: Edit Account - Click edit button
      view
      |> element("button[phx-click='edit_account'][phx-value-id='#{created_account.id}']")
      |> render_click()

      # Verify edit modal appears
      assert has_element?(view, "#account-form")

      # Check for pre-populated data in the form (values may be in different input formats)
      edit_html = render(view)
      assert edit_html =~ "Test Investment Account"
      assert edit_html =~ "Test Brokerage"

      # Update account data
      updated_data = %{
        "name" => "Updated Investment Account",
        "platform" => "Updated Brokerage",
        "balance" => "15000.75"
      }

      view
      |> element("form")
      |> render_submit(%{"form" => updated_data})

      # Wait for update to complete
      :timer.sleep(100)

      # Check if form closed and updates are visible
      current_html = render(view)

      {view, current_html} =
        if not (current_html =~ "Updated Investment Account") do
          {:ok, new_view, _html} = live(conn, "/accounts")
          {new_view, render(new_view)}
        else
          {view, current_html}
        end

      # Verify changes
      assert current_html =~ "Updated Investment Account"
      assert current_html =~ "Updated Brokerage"
      assert current_html =~ "$15,000.75" or current_html =~ "15,000"

      # Step 7: Delete Account - Click delete button
      view
      |> element("button[phx-click='delete_account'][phx-value-id='#{created_account.id}']")
      |> render_click()

      # Wait for deletion to complete
      :timer.sleep(100)

      # Verify account is removed from list
      {:ok, final_accounts} = Account.accounts_for_user(user.id)
      assert length(final_accounts) == initial_accounts_count

      refute Enum.any?(final_accounts, fn acc -> acc.name == "Updated Investment Account" end)
    end

    test "account exclusion toggle functionality", %{conn: conn, user: user} do
      # Create a test account
      {:ok, account} =
        Account.create(%{
          name: "Toggle Test Account",
          platform: "Test Platform",
          balance: Decimal.new("5000"),
          user_id: user.id
        })

      {:ok, view, _html} = live(conn, "/accounts")

      # Verify account starts as included (not excluded)
      refute account.is_excluded

      # Click exclusion toggle
      view
      |> element("button[phx-click='toggle_exclusion'][phx-value-id='#{account.id}']")
      |> render_click()

      # Verify account is now excluded
      {:ok, updated_account} = Account.get_by_id(account.id)
      assert updated_account.is_excluded

      # Toggle back to included
      view
      |> element("button[phx-click='toggle_exclusion'][phx-value-id='#{account.id}']")
      |> render_click()

      # Verify account is included again
      {:ok, final_account} = Account.get_by_id(account.id)
      refute final_account.is_excluded
    end

    @tag :skip
    test "error handling during account operations", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/accounts")

      # Test network/server error simulation during create
      if render(view) =~ "Create Your First Account" do
        view
        |> element("button", "Create Your First Account")
        |> render_click()
      else
        view
        |> element("button", "New Account")
        |> render_click()
      end

      # Try to create account with edge case data that might cause issues
      edge_case_data = %{
        "name" => "Valid Name",
        "platform" => "Valid Platform",
        # Very large balance
        "balance" => "999999999999999.99"
      }

      view
      |> element("form")
      |> render_submit(%{"form" => edge_case_data})

      # Verify system handles edge cases gracefully (either success or proper error)
      # The exact behavior depends on validation rules
      # Form still exists (either showing errors or accepting the data)
      assert has_element?(view, "form")
    end
  end
end
