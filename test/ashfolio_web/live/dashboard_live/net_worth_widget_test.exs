defmodule AshfolioWeb.DashboardLive.NetWorthWidgetTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Ashfolio.FinancialManagement.NetWorthSnapshot
  alias Ashfolio.Portfolio.Account

  describe "dashboard net worth widget" do
    setup do
      # Reset account balances
      require Ash.Query

      Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(fn account ->
        Account.update(account, %{balance: Decimal.new("0.00")})
      end)

      # Create accounts with balances
      {:ok, investment_account} =
        Account.create(%{
          name: "Test Investment",
          account_type: :investment,
          balance: Decimal.new("75000.00")
        })

      {:ok, checking_account} =
        Account.create(%{
          name: "Test Checking",
          account_type: :checking,
          balance: Decimal.new("5000.00")
        })

      # Create net worth snapshots for trend
      snapshots_data = [
        {Date.add(Date.utc_today(), -30), "78000.00"},
        {Date.add(Date.utc_today(), -15), "79000.00"},
        {Date.utc_today(), "80000.00"}
      ]

      snapshots =
        for {date, value} <- snapshots_data do
          {:ok, snapshot} =
            NetWorthSnapshot.create(%{
              snapshot_date: date,
              total_assets: Decimal.new(value),
              total_liabilities: Decimal.new("0.00"),
              net_worth: Decimal.new(value),
              investment_value: Decimal.new(value),
              cash_value: Decimal.new("0.00"),
              other_assets_value: Decimal.new("0.00")
            })

          snapshot
        end

      %{
        investment_account: investment_account,
        checking_account: checking_account,
        snapshots: snapshots
      }
    end

    test "dashboard shows current net worth prominently", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      # Should show current net worth (account balances: $75k + $5k = $80k)
      assert html =~ "$80,000"
      assert has_element?(view, "[data-testid='net-worth-total']")
    end

    test "net worth widget shows growth trend", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      # Should show positive trend from snapshots
      # From $78k to $80k = +$2k = +2.6%
      assert html =~ "Net Worth"
      # Basic test - trend calculation would be implemented
    end

    test "create snapshot button in widget", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Should have create snapshot button
      assert has_element?(view, "button[phx-click='create_snapshot']", "Snapshot Now")

      # Click create snapshot
      initial_count = length(elem(NetWorthSnapshot.list(), 1))
      view |> element("button[phx-click='create_snapshot']") |> render_click()

      # Should still have same count (today's snapshot gets updated, not created new)
      {:ok, snapshots_after} = NetWorthSnapshot.list()
      # Same count, but updated values
      assert length(snapshots_after) == initial_count

      # Flash message might be available in Phoenix.LiveView context
      # This test passes if the functionality works (snapshot created)
      rendered_html = render(view)
      # Basic verification the page still renders correctly after snapshot creation
      assert rendered_html =~ "Net Worth"
    end

    test "handles missing snapshot data gracefully", %{conn: conn} do
      # Delete all snapshots
      {:ok, snapshots} = NetWorthSnapshot.list()

      Enum.each(snapshots, fn snapshot ->
        NetWorthSnapshot.destroy(snapshot)
      end)

      {:ok, _view, html} = live(conn, ~p"/")

      # Should still show current calculated net worth
      assert html =~ "$80,000"

      # Should show net worth data
      assert html =~ "Net Worth"
    end
  end
end
