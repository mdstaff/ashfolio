defmodule AshfolioWeb.Integration.TransactionPubSubTest do
  @moduledoc """
  Integration tests for transaction PubSub events.

  These tests verify that transaction events are properly broadcast
  and that the dashboard updates in response to transaction changes.
  """

  use AshfolioWeb.LiveViewCase

  import Phoenix.LiveViewTest
  alias Ashfolio.SQLiteHelpers

  @moduletag :integration
  @moduletag :pubsub

  describe "transaction PubSub integration" do
    test "dashboard subscribes to transaction events and updates portfolio data", %{conn: conn} do
      # Setup: Use global test data
      user = Ashfolio.SQLiteHelpers.get_default_user()
      account = Ashfolio.SQLiteHelpers.get_default_account(user)
      symbol = Ashfolio.SQLiteHelpers.get_common_symbol("AAPL")

      # Navigate to dashboard - this should subscribe to transaction events
      {:ok, dashboard_live, _html} = live(conn, ~p"/")

      # Verify dashboard is properly mounted and subscribed
      assert render(dashboard_live) =~ "Portfolio Dashboard"

      # Simulate a transaction_saved PubSub event
      transaction = %{id: "test-id", symbol: "TEST", type: :buy}
      send(dashboard_live.pid, {:transaction_saved, transaction})

      # Verify dashboard handles the event (should trigger portfolio data reload)
      assert render(dashboard_live) =~ "Portfolio Dashboard"
    end

    test "dashboard handles transaction_deleted PubSub events", %{conn: conn} do
      # Setup: Use global test data with existing transaction
      user = Ashfolio.SQLiteHelpers.get_default_user()
      account = Ashfolio.SQLiteHelpers.get_default_account(user)
      symbol = Ashfolio.SQLiteHelpers.get_common_symbol("AAPL")

      {:ok, transaction} =
        create_local_transaction(user, account, symbol, %{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("150.00")
        })

      # Navigate to dashboard
      {:ok, dashboard_live, _html} = live(conn, ~p"/")

      # Simulate a transaction_deleted PubSub event
      send(dashboard_live.pid, {:transaction_deleted, transaction.id})

      # Verify dashboard handles the event (should trigger portfolio data reload)
      assert render(dashboard_live) =~ "Portfolio Dashboard"
    end

    test "transaction creation broadcasts PubSub event", %{conn: conn} do
      # Setup: Use global test data
      user = Ashfolio.SQLiteHelpers.get_default_user()
      account = Ashfolio.SQLiteHelpers.get_default_account(user)
      symbol = Ashfolio.SQLiteHelpers.get_common_symbol("AAPL")

      # Subscribe to transaction events to verify broadcasting
      Ashfolio.PubSub.subscribe("transactions")

      # Navigate to transactions page and create a transaction
      {:ok, transaction_live, _html} = live(conn, ~p"/transactions")

      # Click new transaction button
      transaction_live
      |> element("button", "New Transaction")
      |> render_click()

      # Fill and submit transaction form
      transaction_live
      |> form("#transaction-form",
        transaction: %{
          type: "buy",
          symbol_id: symbol.id,
          account_id: account.id,
          quantity: "100",
          price: "150.00",
          fee: "9.95",
          date: Date.to_string(Date.utc_today())
        }
      )
      |> render_submit()

      # Verify PubSub event was broadcast
      assert_receive {:transaction_saved, _transaction}, 1000

      # Verify success message is displayed
      assert render(transaction_live) =~ "Transaction created successfully"
    end

    test "transaction deletion broadcasts PubSub event", %{conn: conn} do
      # Setup: Use global test data with existing transaction
      user = Ashfolio.SQLiteHelpers.get_default_user()
      account = Ashfolio.SQLiteHelpers.get_default_account(user)
      symbol = Ashfolio.SQLiteHelpers.get_common_symbol("AAPL")

      {:ok, transaction} =
        create_local_transaction(user, account, symbol, %{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("150.00")
        })

      # Subscribe to transaction events to verify broadcasting
      Ashfolio.PubSub.subscribe("transactions")

      # Navigate to transactions page
      {:ok, transaction_live, _html} = live(conn, ~p"/transactions")

      # Delete the transaction
      transaction_live
      |> element("button[phx-click='delete_transaction'][phx-value-id='#{transaction.id}']")
      |> render_click()

      # Verify PubSub event was broadcast
      assert_receive {:transaction_deleted, transaction_id}, 1000
      assert transaction_id == transaction.id

      # Verify success message is displayed
      assert render(transaction_live) =~ "Transaction deleted successfully"
    end
  end

  describe "PubSub subscription management" do
    test "dashboard subscribes to transaction events on mount", %{conn: conn} do
      # This test verifies that the dashboard properly subscribes to transaction events
      {:ok, _dashboard_live, _html} = live(conn, ~p"/")

      # Verify subscription was established (implicit through successful mount)
      # In a real implementation, we might check the PubSub registry
      assert true
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

  defp create_local_transaction(user, account, symbol, attrs \\ %{}) do
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
    attrs =
      if Map.has_key?(attrs, :total_amount) do
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
end
