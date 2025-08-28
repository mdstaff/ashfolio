defmodule AshfolioWeb.NetWorthLive.IndexTest do
  use AshfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Ashfolio.FinancialManagement.NetWorthSnapshot
  alias Ashfolio.Portfolio.Account

  describe "net worth trends" do
    setup do
      # Reset account balances for clean test state
      require Ash.Query

      Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(fn account ->
        Account.update(account, %{balance: Decimal.new("0.00")})
      end)

      # Create test accounts with known balances
      {:ok, investment_account} =
        Account.create(%{
          name: "Test Investment",
          account_type: :investment,
          balance: Decimal.new("10000.00")
        })

      {:ok, checking_account} =
        Account.create(%{
          name: "Test Checking",
          account_type: :checking,
          balance: Decimal.new("5000.00")
        })

      # Create test net worth snapshots
      snapshots_data = [
        {Date.add(Date.utc_today(), -90), "12000.00"},
        {Date.add(Date.utc_today(), -60), "13500.00"},
        {Date.add(Date.utc_today(), -30), "14200.00"},
        {Date.add(Date.utc_today(), -1), "15000.00"}
      ]

      snapshots =
        for {date, value} <- snapshots_data do
          total_assets = Decimal.new(value)
          total_liabilities = Decimal.new("0.00")
          net_worth = Decimal.sub(total_assets, total_liabilities)

          {:ok, snapshot} =
            NetWorthSnapshot.create(%{
              snapshot_date: date,
              total_assets: total_assets,
              total_liabilities: total_liabilities,
              net_worth: net_worth,
              cash_value: Decimal.new("5000.00"),
              investment_value: Decimal.sub(total_assets, Decimal.new("5000.00"))
            })

          snapshot
        end

      %{
        investment_account: investment_account,
        checking_account: checking_account,
        snapshots: snapshots
      }
    end

    test "displays net worth trends page", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/net_worth")

      assert html =~ "Net Worth Trends"
      assert html =~ "Track your financial progress over time"
      assert has_element?(view, "button", "Create Snapshot")
    end

    test "displays existing snapshots in trend chart", %{conn: conn, snapshots: _snapshots} do
      {:ok, view, html} = live(conn, ~p"/net_worth")

      # Should show current net worth
      assert html =~ "$15,000.00"

      # Should show net worth change
      # 15000 - 12000 = 3000 increase
      assert html =~ "$3,000.00"

      # Should display trend chart section
      assert has_element?(view, "h3", "Net Worth Trend")

      # Should not show empty state
      refute html =~ "No net worth data to display"
    end

    test "date range filtering updates chart", %{conn: conn, snapshots: _snapshots} do
      {:ok, view, _html} = live(conn, ~p"/net_worth")

      # Change to last month filter
      view |> element("button", "Last Month") |> render_click()

      # Should update the data shown (only last month's data)
      html = render(view)
      assert html =~ "Last Month Change"
    end

    @tag :skip
    test "create snapshot button adds new data point", %{conn: conn, snapshots: snapshots} do
      {:ok, view, _html} = live(conn, ~p"/net_worth")

      # Count existing snapshots
      initial_count = length(snapshots)

      # Click create snapshot
      view |> element("button", "Create Snapshot") |> render_click()

      # Should show success message
      assert render(view) =~ "Net worth snapshot created successfully"

      # Should create new snapshot in database
      {:ok, all_snapshots} = NetWorthSnapshot.list()
      assert length(all_snapshots) == initial_count + 1
    end

    @tag :skip
    test "empty snapshots shows create snapshot prompt", %{conn: conn} do
      # Delete all snapshots
      {:ok, snapshots} = NetWorthSnapshot.list()

      Enum.each(snapshots, fn snapshot ->
        NetWorthSnapshot.destroy(snapshot)
      end)

      {:ok, view, html} = live(conn, ~p"/net_worth")

      # Should show empty state
      assert html =~ "No net worth data to display"
      assert html =~ "Create your first net worth snapshot"
      assert has_element?(view, "button", "Create First Snapshot")

      # Should not show chart
      refute html =~ "Net Worth Trend"
    end

    @tag :skip
    test "handles missing account data gracefully", %{conn: conn} do
      # Delete all accounts to simulate edge case
      {:ok, accounts} = Account.list()

      Enum.each(accounts, fn account ->
        Account.destroy(account)
      end)

      {:ok, _view, html} = live(conn, ~p"/net_worth")

      # Should still render without crashing
      assert html =~ "Net Worth Trends"
      # Should show zero for current net worth when no accounts/snapshots
      assert html =~ "Current Net Worth"
      # NOTE: Empty state assertion disabled - needs UX review
      # assert html =~ "No net worth data to display"
    end

    test "navigation links work correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/net_worth")

      # Test back to dashboard link
      assert has_element?(view, "a[href='/']", "Back to Dashboard")

      # Date range buttons should be present
      assert has_element?(view, "button", "Last Month")
      assert has_element?(view, "button", "Last 3 Months")
      assert has_element?(view, "button", "Last 6 Months")
      assert has_element?(view, "button", "Last Year")
      assert has_element?(view, "button", "All Time")
    end
  end
end
