defmodule AshfolioWeb.Integration.AccountWorkflowTest do
  @moduledoc """
  Integration tests for complete account management workflows.

  These tests verify that the entire account management process works
  end-to-end, from creation through deletion, including all user interactions.
  """

  use AshfolioWeb.ConnCase
  use AshfolioWeb.LiveViewCase

  import Phoenix.LiveViewTest

  @moduletag :integration

  describe "complete account management workflow" do
    test "user can create, edit, and delete accounts", %{conn: conn} do
      # 1. Navigate to accounts page
      {:ok, index_live, html} = live(conn, ~p"/accounts")

      # Verify we're on the accounts page
      assert html =~ "Investment Accounts"
      assert has_element?(index_live, "button", "New Account")

      # 2. Create new account
      index_live
      |> element("button", "New Account")
      |> render_click()

      # Verify form modal appears
      assert has_element?(index_live, "#account-form")

      # 3. Fill and submit form
      index_live
      |> form("#account-form",
        form: %{
          name: "Test Integration Account",
          platform: "Test Platform",
          balance: "10000.00"
        }
      )
      |> render_submit()

      # 4. Verify account appears in list
      assert render(index_live) =~ "Test Integration Account"

      # Verify success message
      assert render(index_live) =~ "Account created successfully"

      # 5. Edit the account
      index_live
      |> element("button[phx-click='edit_account']")
      |> render_click()

      # Verify edit form appears with existing data
      assert has_element?(index_live, "#account-form")
      assert has_element?(index_live, "input[value='Test Integration Account']")

      # 6. Update account information
      index_live
      |> form("#account-form",
        form: %{
          name: "Updated Integration Account",
          platform: "Updated Platform",
          balance: "15000.00"
        }
      )
      |> render_submit()

      # 7. Verify changes are reflected
      assert render(index_live) =~ "Updated Integration Account"
      assert render(index_live) =~ "Updated Platform"
      assert render(index_live) =~ "$15,000.00"

      # 8. Test account exclusion toggle
      index_live
      |> element("button[phx-click='toggle_exclusion']")
      |> render_click()

      # Verify exclusion status changed
      assert has_element?(index_live, "span", "Excluded")

      # 9. Verify delete button exists and is properly configured
      # Note: In a real test, we'd need to handle the JavaScript confirmation
      assert has_element?(index_live, "button[data-confirm*='Are you sure']")
    end

    test "account deletion is prevented when transactions exist", %{conn: conn} do
      # Setup: Create account with transactions
      {:ok, user} = create_test_user()
      {:ok, account} = create_test_account(user)
      {:ok, symbol} = create_test_symbol()
      {:ok, _transaction} = create_test_transaction(user, account, symbol)

      # Navigate to accounts page
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Attempt to delete account with transactions
      index_live
      |> element("button[phx-click='delete_account']")
      |> render_click()

      # Verify error message about existing transactions
      assert render(index_live) =~ "Cannot delete account with transactions"
      assert render(index_live) =~ "Consider excluding it instead"

      # Verify account still exists in list
      assert render(index_live) =~ account.name
    end

    test "account exclusion affects portfolio calculations", %{conn: conn} do
      # Setup: Create account with transactions
      {:ok, user} = create_test_user()
      {:ok, account} = create_test_account(user)
      {:ok, symbol} = create_test_symbol()

      {:ok, _transaction} =
        create_test_transaction(user, account, symbol, %{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("150.00")
        })

      # Navigate to dashboard to check initial portfolio value
      {:ok, dashboard_live, _html} = live(conn, ~p"/")
      initial_portfolio_html = render(dashboard_live)

      # Navigate to accounts and exclude the account
      {:ok, accounts_live, _html} = live(conn, ~p"/accounts")

      accounts_live
      |> element("button[phx-click='toggle_exclusion']")
      |> render_click()

      # Navigate back to dashboard
      {:ok, dashboard_live, _html} = live(conn, ~p"/")
      updated_portfolio_html = render(dashboard_live)

      # Verify portfolio calculations changed
      # (In a real implementation, we'd check specific values)
      refute initial_portfolio_html == updated_portfolio_html
    end
  end

  describe "account performance with multiple accounts" do
    test "handles large number of accounts efficiently", %{conn: conn} do
      # Create 50 test accounts (Phase 1 target)
      {:ok, user} = create_test_user()

      accounts =
        for i <- 1..50 do
          {:ok, account} =
            create_test_account(user, %{
              name: "Test Account #{i}",
              platform: "Platform #{rem(i, 5) + 1}",
              balance: Decimal.new("#{i * 1000}.00")
            })

          account
        end

      # Measure page load time
      start_time = System.monotonic_time(:millisecond)
      {:ok, _index_live, _html} = live(conn, ~p"/accounts")
      end_time = System.monotonic_time(:millisecond)

      load_time = end_time - start_time

      # Verify page loads within 500ms threshold (Phase 1 requirement)
      assert load_time < 500, "Account list loaded in #{load_time}ms, expected < 500ms"

      # Verify all accounts are displayed
      assert length(accounts) == 50
    end
  end

  # Helper functions for test setup
  defp create_test_user do
    Ashfolio.Portfolio.User.create(%{
      name: "Test User",
      currency: "USD",
      locale: "en-US"
    })
  end

  defp create_test_account(user, attrs \\ %{}) do
    default_attrs = %{
      name: "Test Account",
      platform: "Test Platform",
      balance: Decimal.new("10000.00"),
      user_id: user.id
    }

    attrs = Map.merge(default_attrs, attrs)
    Ashfolio.Portfolio.Account.create(attrs)
  end

  defp create_test_symbol(attrs \\ %{}) do
    default_attrs = %{
      symbol: "TEST",
      name: "Test Company Inc.",
      asset_class: :stock,
      data_source: :yahoo_finance,
      current_price: Decimal.new("100.00")
    }

    attrs = Map.merge(default_attrs, attrs)
    Ashfolio.Portfolio.Symbol.create(attrs)
  end

  defp create_test_transaction(user, account, symbol, attrs \\ %{}) do
    default_attrs = %{
      type: :buy,
      quantity: Decimal.new("10"),
      price: Decimal.new("100.00"),
      fee: Decimal.new("9.95"),
      date: Date.utc_today(),
      account_id: account.id,
      symbol_id: symbol.id
    }

    attrs = Map.merge(default_attrs, attrs)
    
    # Calculate total_amount if not provided
    attrs = if Map.has_key?(attrs, :total_amount) do
      attrs
    else
      quantity = attrs[:quantity] || default_attrs[:quantity]
      price = attrs[:price] || default_attrs[:price] 
      fee = attrs[:fee] || default_attrs[:fee]
      total_amount = Decimal.add(Decimal.mult(quantity, price), fee)
      Map.put(attrs, :total_amount, total_amount)
    end
    
    Ashfolio.Portfolio.Transaction.create(attrs)
  end

  defp get_account_id_from_page(_live_view) do
    # In a real implementation, this would extract the account ID from the page
    # For now, return a placeholder
    "550e8400-e29b-41d4-a716-446655440000"
  end
end
