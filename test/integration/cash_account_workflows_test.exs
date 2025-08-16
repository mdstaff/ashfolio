defmodule Ashfolio.Integration.CashAccountWorkflowsTest do
  @moduledoc """
  Comprehensive integration tests for cash account workflows in v0.2.0.

  Tests the complete lifecycle of cash account management including:
  - Account creation with different cash types
  - Balance updates with history tracking
  - Net worth calculation integration
  - PubSub notifications for balance changes
  - Account exclusion from net worth calculations
  """

  use Ashfolio.DataCase, async: false

  @moduletag :integration
  @moduletag :v0_2_0

  alias Ashfolio.Context
  alias Ashfolio.Portfolio.{User, Account}
  alias Ashfolio.FinancialManagement.BalanceManager
  alias Phoenix.PubSub

  describe "complete cash account lifecycle" do
    setup do
      {:ok, user} =
        User.create(%{
          name: "Cash Account Test User",
          currency: "USD",
          locale: "en-US"
        })

      {:ok, user: user}
    end

    test "create cash account → update balance → view history → calculate net worth", %{
      user: user
    } do
      # Step 1: Create a checking account
      {:ok, checking_account} =
        Account.create(%{
          name: "Main Checking",
          account_type: :checking,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("5000.00")
        })

      assert checking_account.account_type == :checking
      assert Decimal.equal?(checking_account.balance, Decimal.new("5000.00"))

      # Step 2: Update balance with notes
      {:ok, updated_account} =
        BalanceManager.update_cash_balance(
          checking_account.id,
          Decimal.new("5500.00"),
          "Monthly salary deposit"
        )

      assert Decimal.equal?(updated_account.balance, Decimal.new("5500.00"))

      # Step 3: View balance history
      {:ok, history} = BalanceManager.get_balance_history(checking_account.id)

      assert length(history) > 0
      recent_update = hd(history)
      assert recent_update.notes == "Monthly salary deposit"
      assert Decimal.equal?(recent_update.new_balance, Decimal.new("5500.00"))

      # Step 4: Calculate net worth including cash account
      {:ok, net_worth_data} = Context.get_net_worth(user.id)

      assert Decimal.equal?(net_worth_data.cash_balance, Decimal.new("5500.00"))
      assert Decimal.equal?(net_worth_data.total_net_worth, Decimal.new("5500.00"))
      assert net_worth_data.breakdown.cash_accounts == 1
    end

    test "multiple cash accounts with different types (checking, savings, CD)", %{user: user} do
      # Create multiple cash account types
      {:ok, checking} =
        Account.create(%{
          name: "Checking Account",
          account_type: :checking,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("3000.00")
        })

      {:ok, savings} =
        Account.create(%{
          name: "High Yield Savings",
          account_type: :savings,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("10000.00"),
          interest_rate: Decimal.new("4.5")
        })

      {:ok, cd_account} =
        Account.create(%{
          name: "12-Month CD",
          account_type: :cd,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("25000.00"),
          interest_rate: Decimal.new("5.0"),
          minimum_balance: Decimal.new("25000.00")
        })

      # Verify account types and attributes
      assert checking.account_type == :checking
      assert savings.account_type == :savings
      assert cd_account.account_type == :cd

      assert Decimal.equal?(savings.interest_rate, Decimal.new("4.5"))
      assert Decimal.equal?(cd_account.minimum_balance, Decimal.new("25000.00"))

      # Calculate total cash balance across all accounts
      {:ok, net_worth} = Context.get_net_worth(user.id)

      # 3000 + 10000 + 25000
      expected_total = Decimal.new("38000.00")
      assert Decimal.equal?(net_worth.cash_balance, expected_total)
      assert net_worth.breakdown.cash_accounts == 3

      # Verify accounts are categorized correctly
      {:ok, dashboard_data} = Context.get_user_dashboard_data(user.id)

      assert length(dashboard_data.accounts.cash) == 3

      assert Enum.all?(dashboard_data.accounts.cash, fn acc ->
               acc.account_type in [:checking, :savings, :cd]
             end)
    end

    @tag :skip
    test "cash balance updates trigger PubSub notifications", %{user: user} do
      # TODO: PubSub functionality needs implementation
      # Subscribe to balance update notifications
      topic = "balance_updates:#{user.id}"
      PubSub.subscribe(Ashfolio.PubSub, topic)

      # Create cash account
      {:ok, account} =
        Account.create(%{
          name: "Notification Test Account",
          account_type: :savings,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("1000.00")
        })

      # Update balance and expect PubSub notification
      {:ok, _updated} =
        BalanceManager.update_cash_balance(
          account.id,
          Decimal.new("1500.00"),
          "Test deposit"
        )

      # Assert we receive the PubSub notification
      assert_receive {:balance_updated, payload}, 5000

      assert payload.account_id == account.id
      assert Decimal.equal?(payload.old_balance, Decimal.new("1000.00"))
      assert Decimal.equal?(payload.new_balance, Decimal.new("1500.00"))
      assert payload.notes == "Test deposit"
    end

    test "cash accounts excluded from net worth when toggled", %{user: user} do
      # Create included and excluded cash accounts
      {:ok, included_account} =
        Account.create(%{
          name: "Included Savings",
          account_type: :savings,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("5000.00"),
          is_excluded: false
        })

      {:ok, excluded_account} =
        Account.create(%{
          name: "Excluded Checking",
          account_type: :checking,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("2000.00"),
          is_excluded: true
        })

      # Calculate net worth
      {:ok, net_worth} = Context.get_net_worth(user.id)

      # Only included account should count
      assert Decimal.equal?(net_worth.cash_balance, Decimal.new("5000.00"))
      # Only counts non-excluded
      assert net_worth.breakdown.cash_accounts == 1

      # Toggle exclusion status
      {:ok, _updated} = Account.update(excluded_account, %{is_excluded: false})
      {:ok, updated_net_worth} = Context.get_net_worth(user.id)

      # Both accounts should now count
      assert Decimal.equal?(updated_net_worth.cash_balance, Decimal.new("7000.00"))

      # Toggle inclusion account to excluded
      {:ok, _updated} = Account.update(included_account, %{is_excluded: true})
      {:ok, final_net_worth} = Context.get_net_worth(user.id)

      # Only the previously excluded account counts now
      assert Decimal.equal?(final_net_worth.cash_balance, Decimal.new("2000.00"))
    end

    test "cash account balance updates with validation", %{user: user} do
      # Create a savings account with minimum balance
      {:ok, savings} =
        Account.create(%{
          name: "Minimum Balance Savings",
          account_type: :savings,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("1000.00"),
          minimum_balance: Decimal.new("500.00")
        })

      # Valid balance update
      {:ok, updated} =
        BalanceManager.update_cash_balance(
          savings.id,
          Decimal.new("750.00"),
          "Partial withdrawal"
        )

      assert Decimal.equal?(updated.balance, Decimal.new("750.00"))

      # Attempt to set balance below zero (should handle gracefully)
      result =
        BalanceManager.update_cash_balance(
          savings.id,
          Decimal.new("-100.00"),
          "Invalid negative balance"
        )

      # Depending on implementation, this might return an error or set to zero
      case result do
        {:error, _reason} ->
          # Expected error for negative balance
          assert true

        {:ok, account} ->
          # Some implementations might allow zero but not negative
          assert Decimal.compare(account.balance, Decimal.new("0")) != :lt
      end
    end
  end

  describe "cross-domain cash and investment integration" do
    setup do
      {:ok, user} =
        User.create(%{
          name: "Mixed Portfolio User",
          currency: "USD",
          locale: "en-US"
        })

      # Create an investment account for mixed testing
      {:ok, investment_account} =
        Account.create(%{
          name: "Brokerage Account",
          account_type: :investment,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("50000.00")
        })

      {:ok, user: user, investment_account: investment_account}
    end

    test "net worth combines cash and investment accounts correctly", %{
      user: user,
      investment_account: _investment_account
    } do
      # Create cash accounts
      {:ok, _checking} =
        Account.create(%{
          name: "Checking",
          account_type: :checking,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("5000.00")
        })

      {:ok, _savings} =
        Account.create(%{
          name: "Savings",
          account_type: :savings,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("15000.00")
        })

      # Calculate combined net worth
      {:ok, net_worth} = Context.get_net_worth(user.id)

      # Verify totals
      assert Decimal.equal?(net_worth.cash_balance, Decimal.new("20000.00"))
      assert Decimal.equal?(net_worth.investment_value, Decimal.new("50000.00"))
      assert Decimal.equal?(net_worth.total_net_worth, Decimal.new("70000.00"))

      # Verify breakdown
      assert net_worth.breakdown.cash_accounts == 2
      assert net_worth.breakdown.investment_accounts == 1

      # Verify percentages
      cash_percentage = net_worth.breakdown.cash_percentage
      investment_percentage = net_worth.breakdown.investment_percentage

      # Cash is ~28.57% of total
      assert Decimal.compare(cash_percentage, Decimal.new("28")) == :gt
      assert Decimal.compare(cash_percentage, Decimal.new("29")) == :lt

      # Investment is ~71.43% of total
      assert Decimal.compare(investment_percentage, Decimal.new("71")) == :gt
      assert Decimal.compare(investment_percentage, Decimal.new("72")) == :lt
    end

    test "dashboard data correctly categorizes mixed account types", %{
      user: user,
      investment_account: _investment_account
    } do
      # Create various account types
      {:ok, _checking} =
        Account.create(%{
          name: "Checking",
          account_type: :checking,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("3000.00")
        })

      {:ok, _money_market} =
        Account.create(%{
          name: "Money Market",
          account_type: :money_market,
          currency: "USD",
          user_id: user.id,
          balance: Decimal.new("8000.00")
        })

      # Get dashboard data
      {:ok, dashboard} = Context.get_user_dashboard_data(user.id)

      # Verify categorization
      assert length(dashboard.accounts.all) == 3
      assert length(dashboard.accounts.investment) == 1
      assert length(dashboard.accounts.cash) == 2

      # Verify summary calculations
      assert dashboard.summary.account_count == 3
      assert dashboard.summary.cash_accounts == 2
      assert dashboard.summary.investment_accounts == 1

      # Verify balance totals
      assert Decimal.equal?(dashboard.summary.cash_balance, Decimal.new("11000.00"))
      assert Decimal.equal?(dashboard.summary.investment_balance, Decimal.new("50000.00"))
      assert Decimal.equal?(dashboard.summary.total_balance, Decimal.new("61000.00"))
    end
  end
end
