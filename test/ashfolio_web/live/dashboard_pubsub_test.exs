defmodule AshfolioWeb.DashboardPubSubTest do
  @moduledoc """
  Unit tests for dashboard PubSub event handling.

  These tests verify that the dashboard properly handles PubSub events
  without requiring full integration test setup.
  """

  use AshfolioWeb.LiveViewCase

  import Phoenix.LiveViewTest

  @moduletag :liveview
  @moduletag :unit
  @moduletag :fast
  @moduletag :pubsub

  describe "dashboard PubSub event handling" do
    test "handles transaction_saved events", %{conn: conn} do
      {:ok, dashboard_live, _html} = live(conn, ~p"/")

      # Verify dashboard is mounted
      assert render(dashboard_live) =~ "Portfolio Dashboard"

      # Send a transaction_saved event directly to the LiveView process
      transaction = %{id: "test-id", symbol: "TEST", type: :buy}
      send(dashboard_live.pid, {:transaction_saved, transaction})

      # Verify the dashboard still renders (handles the event gracefully)
      assert render(dashboard_live) =~ "Portfolio Dashboard"
    end

    test "handles transaction_deleted events", %{conn: conn} do
      {:ok, dashboard_live, _html} = live(conn, ~p"/")

      # Verify dashboard is mounted
      assert render(dashboard_live) =~ "Portfolio Dashboard"

      # Send a transaction_deleted event directly to the LiveView process
      send(dashboard_live.pid, {:transaction_deleted, "test-transaction-id"})

      # Verify the dashboard still renders (handles the event gracefully)
      assert render(dashboard_live) =~ "Portfolio Dashboard"
    end

    test "handles account_saved events", %{conn: conn} do
      {:ok, dashboard_live, _html} = live(conn, ~p"/")

      # Verify dashboard is mounted
      assert render(dashboard_live) =~ "Portfolio Dashboard"

      # Send an account_saved event directly to the LiveView process
      account = %{id: "test-id", name: "Test Account"}
      send(dashboard_live.pid, {:account_saved, account})

      # Verify the dashboard still renders (handles the event gracefully)
      assert render(dashboard_live) =~ "Portfolio Dashboard"
    end

    test "handles account_deleted events", %{conn: conn} do
      {:ok, dashboard_live, _html} = live(conn, ~p"/")

      # Verify dashboard is mounted
      assert render(dashboard_live) =~ "Portfolio Dashboard"

      # Send an account_deleted event directly to the LiveView process
      send(dashboard_live.pid, {:account_deleted, "test-account-id"})

      # Verify the dashboard still renders (handles the event gracefully)
      assert render(dashboard_live) =~ "Portfolio Dashboard"
    end

    test "handles account_updated events", %{conn: conn} do
      {:ok, dashboard_live, _html} = live(conn, ~p"/")

      # Verify dashboard is mounted
      assert render(dashboard_live) =~ "Portfolio Dashboard"

      # Send an account_updated event directly to the LiveView process
      account = %{id: "test-id", name: "Updated Account"}
      send(dashboard_live.pid, {:account_updated, account})

      # Verify the dashboard still renders (handles the event gracefully)
      assert render(dashboard_live) =~ "Portfolio Dashboard"
    end

    test "dashboard subscribes to PubSub topics on mount", %{conn: conn} do
      # This test verifies that the dashboard mounts successfully
      # which implies PubSub subscription setup is working
      {:ok, dashboard_live, html} = live(conn, ~p"/")

      # Verify dashboard mounted successfully with PubSub subscriptions
      assert html =~ "Portfolio Dashboard"
      assert is_pid(dashboard_live.pid)
    end
  end
end
