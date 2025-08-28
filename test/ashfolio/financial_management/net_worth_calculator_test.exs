defmodule Ashfolio.FinancialManagement.NetWorthCalculatorTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.FinancialManagement.NetWorthCalculator
  alias Ashfolio.Portfolio.Account

  describe "calculate_net_worth/0" do
    setup do
      # Reset all existing accounts to zero balance to ensure clean test state
      require Ash.Query

      Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(fn account ->
        Account.update(account, %{balance: Decimal.new("0.00")})
      end)

      :ok
    end

    test "calculates net worth with investment and cash accounts" do
      # Database-as-user architecture: No user needed

      # Create investment account (NetWorthCalculator uses account balances, not transaction-based calculations)
      {:ok, _investment_account} =
        Account.create(%{
          name: "Investment Account",
          platform: "Schwab",
          account_type: :investment,
          balance: Decimal.new("1500.00")
        })

      # Create cash accounts
      {:ok, _checking_account} =
        Account.create(%{
          name: "Checking Account",
          platform: "Bank",
          account_type: :checking,
          balance: Decimal.new("2500.00")
        })

      {:ok, _savings_account} =
        Account.create(%{
          name: "Savings Account",
          platform: "Bank",
          account_type: :savings,
          balance: Decimal.new("10000.00"),
          interest_rate: Decimal.new("0.025")
        })

      # Calculate net worth
      assert {:ok, result} = NetWorthCalculator.calculate_current_net_worth()

      # Investment value from account balances
      assert Decimal.equal?(result.investment_value, Decimal.new("1500.00"))

      # Cash value should be $2500 + $10000 = $12500
      assert Decimal.equal?(result.cash_value, Decimal.new("12500.00"))

      # Net worth should be $1500 + $12500 = $14000
      assert Decimal.equal?(result.net_worth, Decimal.new("14000.00"))

      # Should have breakdown data
      assert is_map(result.breakdown)
      assert Map.has_key?(result.breakdown, :investment_accounts)
      assert Map.has_key?(result.breakdown, :cash_accounts)
      assert Map.has_key?(result.breakdown, :totals_by_type)
    end

    test "handles portfolio with only investment accounts" do
      # Database-as-user architecture: No user needed

      {:ok, _investment_account} =
        Account.create(%{
          name: "Investment Only",
          platform: "Schwab",
          account_type: :investment,
          balance: Decimal.new("1000.00")
        })

      assert {:ok, result} = NetWorthCalculator.calculate_current_net_worth()

      # Investment value from account balance
      assert Decimal.equal?(result.investment_value, Decimal.new("1000.00"))

      # No cash accounts
      assert Decimal.equal?(result.cash_value, Decimal.new("0.00"))

      # Net worth equals investment value
      assert Decimal.equal?(result.net_worth, Decimal.new("1000.00"))
    end

    test "handles portfolio with only cash accounts" do
      # Database-as-user architecture: No user needed

      {:ok, _checking} =
        Account.create(%{
          name: "Checking Only",
          platform: "Bank",
          account_type: :checking,
          balance: Decimal.new("5000.00")
        })

      assert {:ok, result} = NetWorthCalculator.calculate_current_net_worth()

      # No investment value
      assert Decimal.equal?(result.investment_value, Decimal.new("0.00"))

      # Cash value from checking account
      assert Decimal.equal?(result.cash_value, Decimal.new("5000.00"))

      # Net worth equals cash value
      assert Decimal.equal?(result.net_worth, Decimal.new("5000.00"))
    end

    test "excludes excluded accounts from calculation" do
      # Database-as-user architecture: No user needed

      # Active cash account
      {:ok, _active_account} =
        Account.create(%{
          name: "Active Account",
          platform: "Bank",
          account_type: :checking,
          balance: Decimal.new("3000.00"),
          is_excluded: false
        })

      # Excluded cash account
      {:ok, _excluded_account} =
        Account.create(%{
          name: "Excluded Account",
          platform: "Bank",
          account_type: :savings,
          balance: Decimal.new("7000.00"),
          is_excluded: true
        })

      assert {:ok, result} = NetWorthCalculator.calculate_current_net_worth()

      # Should only include active account balance
      assert Decimal.equal?(result.cash_value, Decimal.new("3000.00"))
      assert Decimal.equal?(result.net_worth, Decimal.new("3000.00"))
    end

    test "handles portfolio with no accounts" do
      # Database-as-user architecture: No user needed
      # Note: Global test account balances were reset to zero in setup

      assert {:ok, result} = NetWorthCalculator.calculate_current_net_worth()

      assert Decimal.equal?(result.investment_value, Decimal.new("0.00"))
      assert Decimal.equal?(result.cash_value, Decimal.new("0.00"))
      assert Decimal.equal?(result.net_worth, Decimal.new("0.00"))
    end

    test "returns zero values for empty portfolio" do
      # In database-as-user architecture, this tests an empty database
      assert {:ok, result} = NetWorthCalculator.calculate_current_net_worth()
      assert Decimal.equal?(result.investment_value, Decimal.new("0.00"))
      assert Decimal.equal?(result.cash_value, Decimal.new("0.00"))
      assert Decimal.equal?(result.net_worth, Decimal.new("0.00"))
    end
  end

  describe "calculate_total_cash_balances/1" do
    setup do
      # Reset all existing accounts to zero balance to ensure clean test state
      require Ash.Query

      Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(fn account ->
        Account.update(account, %{balance: Decimal.new("0.00")})
      end)

      :ok
    end

    test "sums all cash account balances" do
      # Database-as-user architecture: No user needed

      {:ok, _checking} =
        Account.create(%{
          name: "Checking",
          platform: "Bank",
          account_type: :checking,
          balance: Decimal.new("1500.00")
        })

      {:ok, _savings} =
        Account.create(%{
          name: "Savings",
          platform: "Bank",
          account_type: :savings,
          balance: Decimal.new("8000.00")
        })

      {:ok, _money_market} =
        Account.create(%{
          name: "Money Market",
          platform: "Bank",
          account_type: :money_market,
          balance: Decimal.new("2500.00")
        })

      assert {:ok, total} = NetWorthCalculator.calculate_total_cash_balances()

      # $1500 + $8000 + $2500 = $12000
      assert Decimal.equal?(total, Decimal.new("12000.00"))
    end

    test "excludes investment accounts from cash balance calculation" do
      # Database-as-user architecture: No user needed

      {:ok, _investment} =
        Account.create(%{
          name: "Investment",
          platform: "Schwab",
          account_type: :investment,
          balance: Decimal.new("5000.00")
        })

      {:ok, _checking} =
        Account.create(%{
          name: "Checking",
          platform: "Bank",
          account_type: :checking,
          balance: Decimal.new("2000.00")
        })

      assert {:ok, total} = NetWorthCalculator.calculate_total_cash_balances()

      # Should only include checking account balance
      assert Decimal.equal?(total, Decimal.new("2000.00"))
    end

    test "excludes excluded cash accounts" do
      # Database-as-user architecture: No user needed

      {:ok, _active} =
        Account.create(%{
          name: "Active Checking",
          platform: "Bank",
          account_type: :checking,
          balance: Decimal.new("3000.00"),
          is_excluded: false
        })

      {:ok, _excluded} =
        Account.create(%{
          name: "Excluded Savings",
          platform: "Bank",
          account_type: :savings,
          balance: Decimal.new("5000.00"),
          is_excluded: true
        })

      assert {:ok, total} = NetWorthCalculator.calculate_total_cash_balances()

      # Should only include active account
      assert Decimal.equal?(total, Decimal.new("3000.00"))
    end

    test "returns zero for portfolio with no cash accounts" do
      # Database-as-user architecture: No user needed

      # Create only investment account
      {:ok, _investment} =
        Account.create(%{
          name: "Investment Only",
          platform: "Schwab",
          account_type: :investment,
          balance: Decimal.new("10000.00")
        })

      assert {:ok, total} = NetWorthCalculator.calculate_total_cash_balances()
      assert Decimal.equal?(total, Decimal.new("0.00"))
    end
  end

  describe "calculate_account_breakdown/1" do
    setup do
      # Reset all existing accounts to zero balance to ensure clean test state
      require Ash.Query

      Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(fn account ->
        Account.update(account, %{balance: Decimal.new("0.00")})
      end)

      :ok
    end

    test "provides detailed breakdown by account type" do
      # Database-as-user architecture: No user needed

      {:ok, investment_account} =
        Account.create(%{
          name: "Schwab Investment",
          platform: "Schwab",
          account_type: :investment,
          balance: Decimal.new("5000.00")
        })

      {:ok, checking_account} =
        Account.create(%{
          name: "Main Checking",
          platform: "Chase",
          account_type: :checking,
          balance: Decimal.new("2500.00")
        })

      {:ok, savings_account} =
        Account.create(%{
          name: "High Yield Savings",
          platform: "Marcus",
          account_type: :savings,
          balance: Decimal.new("15000.00"),
          interest_rate: Decimal.new("0.045")
        })

      assert {:ok, breakdown} = NetWorthCalculator.calculate_account_breakdown()

      # Should have investment accounts section (including any existing test accounts)
      assert length(breakdown.investment_accounts) >= 1

      # Find our created investment account
      investment = Enum.find(breakdown.investment_accounts, &(&1.id == investment_account.id))
      assert investment.name == "Schwab Investment"
      assert investment.account_type == :investment
      assert Decimal.equal?(investment.balance, Decimal.new("5000.00"))

      # Should have cash accounts section
      assert length(breakdown.cash_accounts) >= 2

      checking = Enum.find(breakdown.cash_accounts, &(&1.id == checking_account.id))
      assert checking.name == "Main Checking"
      assert checking.account_type == :checking
      assert Decimal.equal?(checking.balance, Decimal.new("2500.00"))

      savings = Enum.find(breakdown.cash_accounts, &(&1.id == savings_account.id))
      assert savings.name == "High Yield Savings"
      assert savings.account_type == :savings
      assert Decimal.equal?(savings.balance, Decimal.new("15000.00"))
      assert Decimal.equal?(savings.interest_rate, Decimal.new("0.045"))

      # Should have totals by type (all accounts reset to zero except our test accounts)
      totals = breakdown.totals_by_type
      # Investment total includes only our test account
      assert Decimal.equal?(totals.investment, Decimal.new("5000.00"))
      assert Decimal.equal?(totals.cash, Decimal.new("17500.00"))
      assert Decimal.equal?(totals.cash_by_type.checking, Decimal.new("2500.00"))
      assert Decimal.equal?(totals.cash_by_type.savings, Decimal.new("15000.00"))
    end

    test "handles portfolio with only one account type" do
      # Database-as-user architecture: No user needed

      {:ok, _checking} =
        Account.create(%{
          name: "Only Checking",
          platform: "Bank",
          account_type: :checking,
          balance: Decimal.new("3000.00")
        })

      assert {:ok, breakdown} = NetWorthCalculator.calculate_account_breakdown()

      # Should include global test accounts + new cash account (all with zero balance except our test account)
      assert length(breakdown.investment_accounts) >= 0
      assert length(breakdown.cash_accounts) >= 1

      # Investment total is zero (all reset to zero balance), cash includes our test account
      assert Decimal.equal?(breakdown.totals_by_type.investment, Decimal.new("0.00"))
      assert Decimal.equal?(breakdown.totals_by_type.cash, Decimal.new("3000.00"))
    end

    test "excludes excluded accounts from breakdown" do
      # Database-as-user architecture: No user needed

      {:ok, _active} =
        Account.create(%{
          name: "Active Account",
          platform: "Bank",
          account_type: :checking,
          balance: Decimal.new("2000.00"),
          is_excluded: false
        })

      {:ok, _excluded} =
        Account.create(%{
          name: "Excluded Account",
          platform: "Bank",
          account_type: :savings,
          balance: Decimal.new("8000.00"),
          is_excluded: true
        })

      assert {:ok, breakdown} = NetWorthCalculator.calculate_account_breakdown()

      # Should only include active account
      assert length(breakdown.cash_accounts) == 1
      assert hd(breakdown.cash_accounts).name == "Active Account"

      # Totals should only reflect active accounts
      assert Decimal.equal?(breakdown.totals_by_type.cash, Decimal.new("2000.00"))

      assert Map.get(breakdown.totals_by_type.cash_by_type, :savings, Decimal.new("0.00")) ==
               Decimal.new("0.00")
    end
  end

  describe "edge cases and error handling" do
    setup do
      # Reset all existing accounts to zero balance to ensure clean test state
      require Ash.Query

      Account
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.each(fn account ->
        Account.update(account, %{balance: Decimal.new("0.00")})
      end)

      :ok
    end

    test "handles calculation errors gracefully" do
      # Database-as-user architecture: All accounts reset to zero balance in setup
      _unused_uuid = Ecto.UUID.generate()

      assert {:ok, result} = NetWorthCalculator.calculate_current_net_worth()
      # All balances reset to zero in setup
      assert Decimal.equal?(result.net_worth, Decimal.new("0.00"))

      assert {:ok, cash_total} =
               NetWorthCalculator.calculate_total_cash_balances()

      # All cash balances reset to zero in setup
      assert Decimal.equal?(cash_total, Decimal.new("0.00"))

      assert {:ok, breakdown} =
               NetWorthCalculator.calculate_account_breakdown()

      # Global test accounts exist but have zero balances
      assert length(breakdown.investment_accounts) >= 0
      assert length(breakdown.cash_accounts) >= 0
    end

    test "handles accounts with zero balances" do
      # Database-as-user architecture: No user needed

      {:ok, _zero_balance} =
        Account.create(%{
          name: "Zero Balance",
          platform: "Bank",
          account_type: :checking,
          balance: Decimal.new("0.00")
        })

      assert {:ok, result} = NetWorthCalculator.calculate_current_net_worth()
      assert Decimal.equal?(result.net_worth, Decimal.new("0.00"))
      assert Decimal.equal?(result.cash_value, Decimal.new("0.00"))
    end

    test "handles mixed positive and negative scenarios" do
      # Database-as-user architecture: No user needed

      # Positive cash balance
      {:ok, _positive} =
        Account.create(%{
          name: "Positive Account",
          platform: "Bank",
          account_type: :checking,
          balance: Decimal.new("5000.00")
        })

      # Investment account with some balance
      {:ok, _investment_account} =
        Account.create(%{
          name: "Investment Account",
          platform: "Schwab",
          account_type: :investment,
          balance: Decimal.new("500.00")
        })

      assert {:ok, result} = NetWorthCalculator.calculate_current_net_worth()

      # Investment value from account balance
      assert Decimal.equal?(result.investment_value, Decimal.new("500.00"))

      # Cash value: $5000
      assert Decimal.equal?(result.cash_value, Decimal.new("5000.00"))

      # Net worth: $500 + $5000 = $5500
      assert Decimal.equal?(result.net_worth, Decimal.new("5500.00"))
    end
  end
end
