defmodule Ashfolio.FinancialManagement.NetWorthCalculatorTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.FinancialManagement.NetWorthCalculator
  alias Ashfolio.Portfolio.{User, Account, Symbol, Transaction}
  alias Ashfolio.SQLiteHelpers

  describe "calculate_net_worth/1" do
    test "calculates net worth with investment and cash accounts" do
      user = SQLiteHelpers.get_default_user()

      # Create investment account with transactions
      {:ok, investment_account} = Account.create(%{
        name: "Investment Account",
        platform: "Schwab",
        user_id: user.id,
        account_type: :investment,
        balance: Decimal.new("5000.00")
      })

      # Create cash accounts
      {:ok, checking_account} = Account.create(%{
        name: "Checking Account",
        platform: "Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("2500.00")
      })

      {:ok, savings_account} = Account.create(%{
        name: "Savings Account",
        platform: "Bank",
        user_id: user.id,
        account_type: :savings,
        balance: Decimal.new("10000.00"),
        interest_rate: Decimal.new("0.025")
      })

      # Create symbol and transactions for investment value
      symbol = SQLiteHelpers.get_or_create_symbol("AAPL", %{
        name: "Apple Inc.",
        current_price: Decimal.new("150.00")
      })

      {:ok, _transaction} = Transaction.create(%{
        type: :buy,
        symbol_id: symbol.id,
        account_id: investment_account.id,
        quantity: Decimal.new("10"),
        price: Decimal.new("100.00"),
        total_amount: Decimal.new("1000.00"),
        date: ~D[2024-01-15]
      })

      # Calculate net worth
      assert {:ok, result} = NetWorthCalculator.calculate_net_worth(user.id)

      # Investment value should be 10 shares * $150 = $1500
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

    test "handles user with only investment accounts" do
      user = SQLiteHelpers.get_default_user()

      {:ok, investment_account} = Account.create(%{
        name: "Investment Only",
        platform: "Schwab",
        user_id: user.id,
        account_type: :investment,
        balance: Decimal.new("3000.00")
      })

      symbol = SQLiteHelpers.get_or_create_symbol("MSFT", %{
        name: "Microsoft Corp.",
        current_price: Decimal.new("200.00")
      })

      {:ok, _transaction} = Transaction.create(%{
        type: :buy,
        symbol_id: symbol.id,
        account_id: investment_account.id,
        quantity: Decimal.new("5"),
        price: Decimal.new("180.00"),
        total_amount: Decimal.new("900.00"),
        date: ~D[2024-01-15]
      })

      assert {:ok, result} = NetWorthCalculator.calculate_net_worth(user.id)

      # Investment value: 5 shares * $200 = $1000
      assert Decimal.equal?(result.investment_value, Decimal.new("1000.00"))

      # No cash accounts
      assert Decimal.equal?(result.cash_value, Decimal.new("0.00"))

      # Net worth equals investment value
      assert Decimal.equal?(result.net_worth, Decimal.new("1000.00"))
    end

    test "handles user with only cash accounts" do
      user = SQLiteHelpers.get_default_user()

      {:ok, _checking} = Account.create(%{
        name: "Checking Only",
        platform: "Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("5000.00")
      })

      assert {:ok, result} = NetWorthCalculator.calculate_net_worth(user.id)

      # No investment value
      assert Decimal.equal?(result.investment_value, Decimal.new("0.00"))

      # Cash value from checking account
      assert Decimal.equal?(result.cash_value, Decimal.new("5000.00"))

      # Net worth equals cash value
      assert Decimal.equal?(result.net_worth, Decimal.new("5000.00"))
    end

    test "excludes excluded accounts from calculation" do
      user = SQLiteHelpers.get_default_user()

      # Active cash account
      {:ok, _active_account} = Account.create(%{
        name: "Active Account",
        platform: "Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("3000.00"),
        is_excluded: false
      })

      # Excluded cash account
      {:ok, _excluded_account} = Account.create(%{
        name: "Excluded Account",
        platform: "Bank",
        user_id: user.id,
        account_type: :savings,
        balance: Decimal.new("7000.00"),
        is_excluded: true
      })

      assert {:ok, result} = NetWorthCalculator.calculate_net_worth(user.id)

      # Should only include active account balance
      assert Decimal.equal?(result.cash_value, Decimal.new("3000.00"))
      assert Decimal.equal?(result.net_worth, Decimal.new("3000.00"))
    end

    test "handles user with no accounts" do
      user = SQLiteHelpers.get_default_user()

      assert {:ok, result} = NetWorthCalculator.calculate_net_worth(user.id)

      assert Decimal.equal?(result.investment_value, Decimal.new("0.00"))
      assert Decimal.equal?(result.cash_value, Decimal.new("0.00"))
      assert Decimal.equal?(result.net_worth, Decimal.new("0.00"))
    end

    test "returns zero values for invalid user_id" do
      invalid_user_id = Ecto.UUID.generate()

      assert {:ok, result} = NetWorthCalculator.calculate_net_worth(invalid_user_id)
      assert Decimal.equal?(result.investment_value, Decimal.new("0.00"))
      assert Decimal.equal?(result.cash_value, Decimal.new("0.00"))
      assert Decimal.equal?(result.net_worth, Decimal.new("0.00"))
    end
  end

  describe "calculate_total_cash_balances/1" do
    test "sums all cash account balances for user" do
      user = SQLiteHelpers.get_default_user()

      {:ok, _checking} = Account.create(%{
        name: "Checking",
        platform: "Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("1500.00")
      })

      {:ok, _savings} = Account.create(%{
        name: "Savings",
        platform: "Bank",
        user_id: user.id,
        account_type: :savings,
        balance: Decimal.new("8000.00")
      })

      {:ok, _money_market} = Account.create(%{
        name: "Money Market",
        platform: "Bank",
        user_id: user.id,
        account_type: :money_market,
        balance: Decimal.new("2500.00")
      })

      assert {:ok, total} = NetWorthCalculator.calculate_total_cash_balances(user.id)

      # $1500 + $8000 + $2500 = $12000
      assert Decimal.equal?(total, Decimal.new("12000.00"))
    end

    test "excludes investment accounts from cash balance calculation" do
      user = SQLiteHelpers.get_default_user()

      {:ok, _investment} = Account.create(%{
        name: "Investment",
        platform: "Schwab",
        user_id: user.id,
        account_type: :investment,
        balance: Decimal.new("5000.00")
      })

      {:ok, _checking} = Account.create(%{
        name: "Checking",
        platform: "Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("2000.00")
      })

      assert {:ok, total} = NetWorthCalculator.calculate_total_cash_balances(user.id)

      # Should only include checking account balance
      assert Decimal.equal?(total, Decimal.new("2000.00"))
    end

    test "excludes excluded cash accounts" do
      user = SQLiteHelpers.get_default_user()

      {:ok, _active} = Account.create(%{
        name: "Active Checking",
        platform: "Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("3000.00"),
        is_excluded: false
      })

      {:ok, _excluded} = Account.create(%{
        name: "Excluded Savings",
        platform: "Bank",
        user_id: user.id,
        account_type: :savings,
        balance: Decimal.new("5000.00"),
        is_excluded: true
      })

      assert {:ok, total} = NetWorthCalculator.calculate_total_cash_balances(user.id)

      # Should only include active account
      assert Decimal.equal?(total, Decimal.new("3000.00"))
    end

    test "returns zero for user with no cash accounts" do
      user = SQLiteHelpers.get_default_user()

      # Create only investment account
      {:ok, _investment} = Account.create(%{
        name: "Investment Only",
        platform: "Schwab",
        user_id: user.id,
        account_type: :investment,
        balance: Decimal.new("10000.00")
      })

      assert {:ok, total} = NetWorthCalculator.calculate_total_cash_balances(user.id)
      assert Decimal.equal?(total, Decimal.new("0.00"))
    end
  end

  describe "calculate_account_breakdown/1" do
    test "provides detailed breakdown by account type" do
      user = SQLiteHelpers.get_default_user()

      {:ok, investment_account} = Account.create(%{
        name: "Schwab Investment",
        platform: "Schwab",
        user_id: user.id,
        account_type: :investment,
        balance: Decimal.new("5000.00")
      })

      {:ok, checking_account} = Account.create(%{
        name: "Main Checking",
        platform: "Chase",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("2500.00")
      })

      {:ok, savings_account} = Account.create(%{
        name: "High Yield Savings",
        platform: "Marcus",
        user_id: user.id,
        account_type: :savings,
        balance: Decimal.new("15000.00"),
        interest_rate: Decimal.new("0.045")
      })

      assert {:ok, breakdown} = NetWorthCalculator.calculate_account_breakdown(user.id)

      # Should have investment accounts section (including default test account)
      assert length(breakdown.investment_accounts) == 2

      # Find our created investment account
      investment = Enum.find(breakdown.investment_accounts, &(&1.id == investment_account.id))
      assert investment.name == "Schwab Investment"
      assert investment.type == :investment
      assert Decimal.equal?(investment.balance, Decimal.new("5000.00"))

      # Should have cash accounts section
      assert length(breakdown.cash_accounts) == 2

      checking = Enum.find(breakdown.cash_accounts, &(&1.id == checking_account.id))
      assert checking.name == "Main Checking"
      assert checking.type == :checking
      assert Decimal.equal?(checking.balance, Decimal.new("2500.00"))

      savings = Enum.find(breakdown.cash_accounts, &(&1.id == savings_account.id))
      assert savings.name == "High Yield Savings"
      assert savings.type == :savings
      assert Decimal.equal?(savings.balance, Decimal.new("15000.00"))
      assert Decimal.equal?(savings.interest_rate, Decimal.new("0.045"))

      # Should have totals by type (including default test account balance)
      totals = breakdown.totals_by_type
      # Investment total includes default test account ($10,000) + new account ($5,000) = $15,000
      assert Decimal.equal?(totals.investment, Decimal.new("15000.00"))
      assert Decimal.equal?(totals.cash, Decimal.new("17500.00"))
      assert Decimal.equal?(totals.cash_by_type.checking, Decimal.new("2500.00"))
      assert Decimal.equal?(totals.cash_by_type.savings, Decimal.new("15000.00"))
    end

    test "handles user with only one account type" do
      user = SQLiteHelpers.get_default_user()

      {:ok, _checking} = Account.create(%{
        name: "Only Checking",
        platform: "Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("3000.00")
      })

      assert {:ok, breakdown} = NetWorthCalculator.calculate_account_breakdown(user.id)

      # Should include default test account (investment) + new cash account
      assert length(breakdown.investment_accounts) == 1  # Default test account
      assert length(breakdown.cash_accounts) == 1

      # Investment total includes default test account balance ($10,000)
      assert Decimal.equal?(breakdown.totals_by_type.investment, Decimal.new("10000.00"))
      assert Decimal.equal?(breakdown.totals_by_type.cash, Decimal.new("3000.00"))
    end

    test "excludes excluded accounts from breakdown" do
      user = SQLiteHelpers.get_default_user()

      {:ok, _active} = Account.create(%{
        name: "Active Account",
        platform: "Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("2000.00"),
        is_excluded: false
      })

      {:ok, _excluded} = Account.create(%{
        name: "Excluded Account",
        platform: "Bank",
        user_id: user.id,
        account_type: :savings,
        balance: Decimal.new("8000.00"),
        is_excluded: true
      })

      assert {:ok, breakdown} = NetWorthCalculator.calculate_account_breakdown(user.id)

      # Should only include active account
      assert length(breakdown.cash_accounts) == 1
      assert hd(breakdown.cash_accounts).name == "Active Account"

      # Totals should only reflect active accounts
      assert Decimal.equal?(breakdown.totals_by_type.cash, Decimal.new("2000.00"))
      assert Map.get(breakdown.totals_by_type.cash_by_type, :savings, Decimal.new("0.00")) == Decimal.new("0.00")
    end
  end

  describe "edge cases and error handling" do
    test "handles calculation errors gracefully" do
      # Test with non-existent user - should return zero values, not errors
      non_existent_user_id = Ecto.UUID.generate()

      assert {:ok, result} = NetWorthCalculator.calculate_net_worth(non_existent_user_id)
      assert Decimal.equal?(result.net_worth, Decimal.new("0.00"))

      assert {:ok, cash_total} = NetWorthCalculator.calculate_total_cash_balances(non_existent_user_id)
      assert Decimal.equal?(cash_total, Decimal.new("0.00"))

      assert {:ok, breakdown} = NetWorthCalculator.calculate_account_breakdown(non_existent_user_id)
      assert length(breakdown.investment_accounts) == 0
      assert length(breakdown.cash_accounts) == 0
    end

    test "handles accounts with zero balances" do
      user = SQLiteHelpers.get_default_user()

      {:ok, _zero_balance} = Account.create(%{
        name: "Zero Balance",
        platform: "Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("0.00")
      })

      assert {:ok, result} = NetWorthCalculator.calculate_net_worth(user.id)
      assert Decimal.equal?(result.net_worth, Decimal.new("0.00"))
      assert Decimal.equal?(result.cash_value, Decimal.new("0.00"))
    end

    test "handles mixed positive and negative scenarios" do
      user = SQLiteHelpers.get_default_user()

      # Positive cash balance
      {:ok, _positive} = Account.create(%{
        name: "Positive Account",
        platform: "Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("5000.00")
      })

      # Create investment account with loss scenario
      {:ok, investment_account} = Account.create(%{
        name: "Investment Account",
        platform: "Schwab",
        user_id: user.id,
        account_type: :investment,
        balance: Decimal.new("0.00")
      })

      # Symbol with lower current price than purchase price
      symbol = SQLiteHelpers.get_or_create_symbol("LOSS", %{
        name: "Loss Stock",
        current_price: Decimal.new("50.00")
      })

      {:ok, _transaction} = Transaction.create(%{
        type: :buy,
        symbol_id: symbol.id,
        account_id: investment_account.id,
        quantity: Decimal.new("10"),
        price: Decimal.new("100.00"),
        total_amount: Decimal.new("1000.00"),
        date: ~D[2024-01-15]
      })

      assert {:ok, result} = NetWorthCalculator.calculate_net_worth(user.id)

      # Investment value: 10 shares * $50 = $500 (loss from $1000 cost)
      assert Decimal.equal?(result.investment_value, Decimal.new("500.00"))

      # Cash value: $5000
      assert Decimal.equal?(result.cash_value, Decimal.new("5000.00"))

      # Net worth: $500 + $5000 = $5500
      assert Decimal.equal?(result.net_worth, Decimal.new("5500.00"))
    end
  end
end
