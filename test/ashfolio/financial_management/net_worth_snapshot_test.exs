defmodule Ashfolio.FinancialManagement.NetWorthSnapshotTest do
  use Ashfolio.DataCase

  alias Ashfolio.FinancialManagement.NetWorthCalculator
  alias Ashfolio.FinancialManagement.NetWorthSnapshot
  alias Ashfolio.Portfolio.Account

  describe "net worth snapshot creation" do
    setup do
      # Create test accounts with balances
      {:ok, investment_account} =
        Account.create(%{
          name: "Investment Account",
          account_type: :investment,
          currency: "USD",
          balance: Decimal.new("50000.00")
        })

      {:ok, checking_account} =
        Account.create(%{
          name: "Checking Account",
          account_type: :checking,
          currency: "USD",
          balance: Decimal.new("5000.00")
        })

      {:ok, savings_account} =
        Account.create(%{
          name: "Savings Account",
          account_type: :savings,
          currency: "USD",
          balance: Decimal.new("25000.00")
        })

      %{
        investment_account: investment_account,
        checking_account: checking_account,
        savings_account: savings_account
      }
    end

    test "creates snapshot with calculated net worth" do
      attrs = %{
        snapshot_date: ~D[2024-01-15],
        total_assets: Decimal.new("80000.00"),
        total_liabilities: Decimal.new("0.00"),
        net_worth: Decimal.new("80000.00"),
        investment_value: Decimal.new("50000.00"),
        cash_value: Decimal.new("30000.00"),
        other_assets_value: Decimal.new("0.00"),
        is_automated: false,
        notes: "Manual snapshot for testing"
      }

      assert {:ok, snapshot} = NetWorthSnapshot.create(attrs)
      assert snapshot.snapshot_date == ~D[2024-01-15]
      assert Decimal.equal?(snapshot.net_worth, Decimal.new("80000.00"))
      assert Decimal.equal?(snapshot.total_assets, Decimal.new("80000.00"))
      assert Decimal.equal?(snapshot.investment_value, Decimal.new("50000.00"))
      assert Decimal.equal?(snapshot.cash_value, Decimal.new("30000.00"))
      assert snapshot.is_automated == false
    end

    test "requires snapshot_date" do
      attrs = %{
        total_assets: Decimal.new("80000.00"),
        net_worth: Decimal.new("80000.00")
      }

      assert {:error, changeset} = NetWorthSnapshot.create(attrs)
      assert "is required" in errors_on(changeset).snapshot_date
    end

    test "requires total_assets" do
      attrs = %{
        snapshot_date: ~D[2024-01-15],
        net_worth: Decimal.new("80000.00")
      }

      assert {:error, changeset} = NetWorthSnapshot.create(attrs)
      assert "is required" in errors_on(changeset).total_assets
    end

    test "requires net_worth" do
      attrs = %{
        snapshot_date: ~D[2024-01-15],
        total_assets: Decimal.new("80000.00")
      }

      assert {:error, changeset} = NetWorthSnapshot.create(attrs)
      assert "is required" in errors_on(changeset).net_worth
    end

    test "enforces unique snapshot_date" do
      attrs = %{
        snapshot_date: ~D[2024-01-15],
        total_assets: Decimal.new("80000.00"),
        net_worth: Decimal.new("80000.00")
      }

      assert {:ok, _} = NetWorthSnapshot.create(attrs)
      assert {:error, changeset} = NetWorthSnapshot.create(attrs)
      assert "has already been taken" in errors_on(changeset).snapshot_date
    end
  end

  describe "net worth calculations" do
    setup do
      # Reset all existing accounts to zero balance first
      require Ash.Query

      Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(fn account ->
        Account.update(account, %{balance: Decimal.new("0.00")})
      end)

      # Create accounts with different types and balances
      {:ok, investment1} =
        Account.create(%{
          name: "Test Schwab Brokerage",
          account_type: :investment,
          currency: "USD",
          balance: Decimal.new("75000.00")
        })

      {:ok, investment2} =
        Account.create(%{
          name: "Test Fidelity 401k",
          account_type: :investment,
          currency: "USD",
          balance: Decimal.new("125000.00")
        })

      {:ok, checking} =
        Account.create(%{
          name: "Test Main Checking",
          account_type: :checking,
          currency: "USD",
          balance: Decimal.new("8000.00")
        })

      {:ok, savings} =
        Account.create(%{
          name: "Test High Yield Savings",
          account_type: :savings,
          currency: "USD",
          balance: Decimal.new("50000.00")
        })

      %{
        investment1: investment1,
        investment2: investment2,
        checking: checking,
        savings: savings
      }
    end

    test "calculates current net worth from all accounts" do
      {:ok, calculation} = NetWorthCalculator.calculate_current_net_worth()

      assert Decimal.equal?(calculation.investment_value, Decimal.new("200000.00"))
      assert Decimal.equal?(calculation.cash_value, Decimal.new("58000.00"))
      assert Decimal.equal?(calculation.total_assets, Decimal.new("258000.00"))
      assert Decimal.equal?(calculation.total_liabilities, Decimal.new("0.00"))
      assert Decimal.equal?(calculation.net_worth, Decimal.new("258000.00"))
    end

    test "creates snapshot from current calculation" do
      snapshot_date = ~D[2024-02-01]

      assert {:ok, snapshot} = NetWorthCalculator.create_snapshot(snapshot_date)
      assert snapshot.snapshot_date == snapshot_date
      assert Decimal.equal?(snapshot.net_worth, Decimal.new("258000.00"))
      assert snapshot.is_automated == true
    end

    test "creates snapshot with default date (today)" do
      assert {:ok, snapshot} = NetWorthCalculator.create_snapshot()
      assert snapshot.snapshot_date == Date.utc_today()
      assert snapshot.is_automated == true
    end
  end

  describe "net worth queries" do
    setup do
      # Create test snapshots across different dates
      dates_and_values = [
        {~D[2024-01-01], "100000.00"},
        {~D[2024-02-01], "105000.00"},
        {~D[2024-03-01], "110000.00"},
        {~D[2024-04-01], "95000.00"},
        {~D[2024-05-01], "120000.00"}
      ]

      snapshots =
        for {date, value} <- dates_and_values do
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

      %{snapshots: snapshots}
    end

    test "lists all snapshots" do
      snapshots = NetWorthSnapshot.list!()
      assert length(snapshots) == 5
    end

    test "gets snapshots by date range" do
      snapshots = NetWorthSnapshot.by_date_range!(~D[2024-02-01], ~D[2024-04-01])
      assert length(snapshots) == 3

      dates = Enum.map(snapshots, & &1.snapshot_date)
      assert ~D[2024-02-01] in dates
      assert ~D[2024-03-01] in dates
      assert ~D[2024-04-01] in dates
    end

    test "gets snapshots by year" do
      snapshots = NetWorthSnapshot.by_year!(2024)
      assert length(snapshots) == 5
    end

    test "orders snapshots by date descending" do
      snapshots = NetWorthSnapshot.recent_first!()
      dates = Enum.map(snapshots, & &1.snapshot_date)

      assert dates == [
               ~D[2024-05-01],
               ~D[2024-04-01],
               ~D[2024-03-01],
               ~D[2024-02-01],
               ~D[2024-01-01]
             ]
    end
  end

  describe "net worth analytics" do
    setup do
      # Create snapshots for year-over-year analysis
      snapshots_data = [
        {~D[2023-01-01], "50000.00"},
        {~D[2023-06-01], "60000.00"},
        {~D[2023-12-01], "75000.00"},
        {~D[2024-01-01], "80000.00"},
        {~D[2024-06-01], "95000.00"},
        {~D[2024-12-01], "110000.00"}
      ]

      for {date, value} <- snapshots_data do
        NetWorthSnapshot.create(%{
          snapshot_date: date,
          total_assets: Decimal.new(value),
          total_liabilities: Decimal.new("0.00"),
          net_worth: Decimal.new(value),
          investment_value: Decimal.new(value),
          cash_value: Decimal.new("0.00"),
          other_assets_value: Decimal.new("0.00")
        })
      end

      :ok
    end

    test "calculates year-over-year growth" do
      growth = NetWorthSnapshot.year_over_year_growth!(2024, 2023)

      # 110000 vs 75000 = 46.67% growth
      assert_in_delta Decimal.to_float(growth), 46.67, 0.1
    end

    test "calculates monthly growth rate" do
      growth = NetWorthSnapshot.monthly_growth_rate!(~D[2024-01-01], ~D[2024-12-01])

      # 80000 to 110000 over 11 months
      expected_monthly_rate = :math.pow(110_000 / 80_000, 1 / 11) - 1
      assert_in_delta Decimal.to_float(growth), expected_monthly_rate * 100, 1.0
    end

    test "gets latest snapshot" do
      snapshot = NetWorthSnapshot.latest!()
      assert snapshot.snapshot_date == ~D[2024-12-01]
      assert Decimal.equal?(snapshot.net_worth, Decimal.new("110000.00"))
    end
  end

  describe "net worth updates" do
    setup do
      {:ok, snapshot} =
        NetWorthSnapshot.create(%{
          snapshot_date: ~D[2024-01-15],
          total_assets: Decimal.new("100000.00"),
          total_liabilities: Decimal.new("0.00"),
          net_worth: Decimal.new("100000.00"),
          investment_value: Decimal.new("80000.00"),
          cash_value: Decimal.new("20000.00"),
          notes: "Original snapshot"
        })

      %{snapshot: snapshot}
    end

    test "updates snapshot values", %{snapshot: snapshot} do
      {:ok, updated} =
        NetWorthSnapshot.update(snapshot, %{
          total_assets: Decimal.new("105000.00"),
          net_worth: Decimal.new("105000.00"),
          notes: "Updated values"
        })

      assert Decimal.equal?(updated.net_worth, Decimal.new("105000.00"))
      assert updated.notes == "Updated values"
    end

    test "validates updated values", %{snapshot: snapshot} do
      {:error, changeset} =
        NetWorthSnapshot.update(snapshot, %{
          total_assets: Decimal.new("-1000.00")
        })

      assert "must be greater than or equal to 0" in errors_on(changeset).total_assets
    end
  end

  describe "net worth deletion" do
    setup do
      {:ok, snapshot} =
        NetWorthSnapshot.create(%{
          snapshot_date: ~D[2024-01-15],
          total_assets: Decimal.new("100000.00"),
          net_worth: Decimal.new("100000.00")
        })

      %{snapshot: snapshot}
    end

    test "deletes snapshot", %{snapshot: snapshot} do
      assert :ok = NetWorthSnapshot.destroy(snapshot)
      assert NetWorthSnapshot.list!() == []
    end
  end
end
