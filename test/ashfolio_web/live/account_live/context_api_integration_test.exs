defmodule AshfolioWeb.AccountLive.ContextApiIntegrationTest do
  @moduledoc """
  Tests for Context API integration in AccountLive modules.

  This test file specifically tests the integration with Ashfolio.Context
  including dashboard data loading, account filtering, and real-time updates.
  """

  use AshfolioWeb.LiveViewCase

  @moduletag :liveview
  @moduletag :integration
  @moduletag :fast
  @moduletag :context_api

  alias Ashfolio.Portfolio.{Account, User}
  alias Ashfolio.Context

  setup do
    # Get or create the default test user
    {:ok, user} = get_or_create_default_user()

    # Create test accounts with different types
    {:ok, investment_account} =
      Account.create(%{
        name: "Investment Account",
        platform: "Brokerage",
        balance: Decimal.new("5000.00"),
        account_type: :investment,
        user_id: user.id
      })

    {:ok, cash_account} =
      Account.create(%{
        name: "Savings Account",
        platform: "Bank",
        balance: Decimal.new("2000.00"),
        account_type: :savings,
        user_id: user.id
      })

    {:ok, excluded_account} =
      Account.create(%{
        name: "Closed Account",
        platform: "Old Bank",
        balance: Decimal.new("100.00"),
        account_type: :checking,
        is_excluded: true,
        user_id: user.id
      })

    %{
      user: user,
      investment_account: investment_account,
      cash_account: cash_account,
      excluded_account: excluded_account
    }
  end

  describe "Context API integration - AccountLive.Index" do
    test "loads dashboard data using Context API", %{conn: conn} do
      {:ok, index_live, html} = live(conn, ~p"/accounts")

      # Should show updated title for both investment and cash accounts
      assert html =~ "Accounts"
      assert html =~ "Manage your investment and cash accounts"

      # Should show loading state initially, then accounts
      assert html =~ "Investment Account" or html =~ "Loading accounts..."
      assert html =~ "Savings Account" or html =~ "Loading accounts..."
    end

    test "displays account type filtering tabs", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/accounts")

      # Should show filter tabs with counts
      assert html =~ "All Accounts"
      assert html =~ "Investment"
      assert html =~ "Cash"
    end

    test "filters accounts by type - All", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Click All Accounts filter
      html =
        index_live
        |> element("button[phx-value-filter='all']")
        |> render_click()

      # Should show all accounts including excluded ones
      assert html =~ "Investment Account"
      assert html =~ "Savings Account"
      assert html =~ "Closed Account"
    end

    test "filters accounts by type - Investment", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Click Investment filter
      html =
        index_live
        |> element("button[phx-value-filter='investment']")
        |> render_click()

      # Should show only investment accounts
      assert html =~ "Investment Account"
      refute html =~ "Savings Account"
      refute html =~ "Closed Account"
    end

    test "filters accounts by type - Cash", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Click Cash filter
      html =
        index_live
        |> element("button[phx-value-filter='cash']")
        |> render_click()

      # Should show only cash accounts (savings and checking)
      refute html =~ "Investment Account"
      assert html =~ "Savings Account"
      assert html =~ "Closed Account"
    end

    test "displays Context-calculated summary balances", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/accounts")

      # Should show total, investment, and cash balances from Context API
      assert html =~ "Total Balance"
      assert html =~ "Investment Value"
      assert html =~ "Cash Balance"

      # Should show calculated amounts (may include other test accounts)
      # Investment balance from our test account
      assert html =~ "$5,000.00"
      # Cash balance section exists
      assert html =~ "Cash Balance"
      # Total balance section exists
      assert html =~ "Total Balance"
    end

    test "updates display when accounts change", %{conn: conn, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Create a new account
      {:ok, new_account} =
        Account.create(%{
          name: "New Test Account",
          platform: "New Platform",
          balance: Decimal.new("1000.00"),
          account_type: :checking,
          user_id: user.id
        })

      # Broadcast account creation
      Ashfolio.PubSub.broadcast!("accounts", {:account_saved, new_account})

      # Should update to show new account
      html = render(index_live)
      assert html =~ "New Test Account"
      assert html =~ "$1,000.00"
    end
  end

  describe "Context API integration - AccountLive.Show" do
    test "loads account details using Context API", %{conn: conn, investment_account: account} do
      {:ok, _show_live, html} = live(conn, ~p"/accounts/#{account.id}")

      # Should show account details loaded via Context
      assert html =~ account.name
      assert html =~ "$5,000.00"
      assert html =~ "Account Details"
    end

    test "shows loading state while fetching data", %{conn: conn, investment_account: account} do
      {:ok, _show_live, html} = live(conn, ~p"/accounts/#{account.id}")

      # Should either show loading or the actual data (test runs fast)
      assert html =~ account.name or html =~ "Loading account details..."
    end

    test "handles account not found from Context API", %{conn: conn} do
      # Try to access non-existent account - should redirect immediately
      result = live(conn, ~p"/accounts/invalid-id")

      # Should get a redirect response
      assert {:error, {:live_redirect, %{to: "/accounts"}}} = result
    end

    test "updates when account is modified via PubSub", %{conn: conn, investment_account: account} do
      {:ok, show_live, _html} = live(conn, ~p"/accounts/#{account.id}")

      # Update the account
      {:ok, updated_account} = Account.update(account, %{name: "Updated Investment Account"})

      # Broadcast account update
      Ashfolio.PubSub.broadcast!("accounts", {:account_updated, updated_account})

      # Should update to show new name
      html = render(show_live)
      assert html =~ "Updated Investment Account"
    end

    test "redirects when account is deleted via PubSub", %{
      conn: conn,
      investment_account: account
    } do
      {:ok, show_live, _html} = live(conn, ~p"/accounts/#{account.id}")

      # Delete the account
      Account.destroy(account)

      # Broadcast account deletion
      Ashfolio.PubSub.broadcast!("accounts", {:account_deleted, account.id})

      # Should redirect to accounts page
      assert_redirect(show_live, ~p"/accounts")
    end
  end

  describe "error handling with Context API" do
    test "handles Context API errors gracefully", %{conn: conn} do
      # Mock a Context API error by temporarily breaking the user ID
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      # Force a data reload that might fail
      send(index_live.pid, {:account_updated, %{id: "fake-account"}})

      # Should handle the error without crashing
      html = render(index_live)
      # Page should still render
      assert html =~ "Accounts"
    end

    test "shows helpful error messages", %{conn: conn} do
      # Test error handling by navigating to the page
      {:ok, _index_live, html} = live(conn, ~p"/accounts")

      # Should not show error messages in normal operation
      refute html =~ "Failed to load"
      refute html =~ "Error"
    end
  end

  describe "performance with Context API" do
    test "loads data efficiently", %{conn: conn} do
      start_time = System.monotonic_time()

      {:ok, _index_live, _html} = live(conn, ~p"/accounts")

      end_time = System.monotonic_time()
      duration_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

      # Should load within reasonable time (adjust threshold as needed)
      assert duration_ms < 1000, "Page load took #{duration_ms}ms, expected < 1000ms"
    end

    test "efficiently handles account filtering", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      start_time = System.monotonic_time()

      # Test multiple filter changes
      index_live |> element("button[phx-value-filter='investment']") |> render_click()
      index_live |> element("button[phx-value-filter='cash']") |> render_click()
      index_live |> element("button[phx-value-filter='all']") |> render_click()

      end_time = System.monotonic_time()
      duration_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

      # Filtering should be fast
      assert duration_ms < 500, "Filtering took #{duration_ms}ms, expected < 500ms"
    end
  end
end
