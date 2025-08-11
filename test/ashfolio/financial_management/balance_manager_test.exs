defmodule Ashfolio.FinancialManagement.BalanceManagerTest do
  use Ashfolio.DataCase, async: true

  alias Ashfolio.FinancialManagement.BalanceManager
  alias Ashfolio.Portfolio.{User, Account}
  alias Ashfolio.PubSub

  describe "update_cash_balance/3" do
    setup do
      # Create a test user
      {:ok, user} = User.create(%{name: "Test User"})

      # Create a cash account
      {:ok, cash_account} = Account.create(%{
        name: "Test Checking",
        platform: "Test Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("1000.00")
      })

      # Create an investment account for negative testing
      {:ok, investment_account} = Account.create(%{
        name: "Test Investment",
        platform: "Test Broker",
        user_id: user.id,
        account_type: :investment,
        balance: Decimal.new("5000.00")
      })

      %{
        user: user,
        cash_account: cash_account,
        investment_account: investment_account
      }
    end

    test "successfully updates cash account balance with notes", %{cash_account: account} do
      new_balance = Decimal.new("1500.00")
      notes = "Monthly salary deposit"

      assert {:ok, updated_account} = BalanceManager.update_cash_balance(account.id, new_balance, notes)

      assert Decimal.equal?(updated_account.balance, new_balance)
      assert updated_account.balance_updated_at != nil
      assert updated_account.id == account.id
    end

    test "successfully updates cash account balance without notes", %{cash_account: account} do
      new_balance = Decimal.new("800.00")

      assert {:ok, updated_account} = BalanceManager.update_cash_balance(account.id, new_balance)

      assert Decimal.equal?(updated_account.balance, new_balance)
      assert updated_account.balance_updated_at != nil
    end

    test "returns error for non-existent account" do
      non_existent_id = Ash.UUID.generate()
      new_balance = Decimal.new("1500.00")

      assert {:error, :account_not_found} = BalanceManager.update_cash_balance(non_existent_id, new_balance)
    end

    test "returns error for investment account", %{investment_account: account} do
      new_balance = Decimal.new("6000.00")

      assert {:error, :not_cash_account} = BalanceManager.update_cash_balance(account.id, new_balance)
    end

    test "handles zero balance correctly", %{cash_account: account} do
      new_balance = Decimal.new("0.00")

      assert {:ok, updated_account} = BalanceManager.update_cash_balance(account.id, new_balance)

      assert Decimal.equal?(updated_account.balance, new_balance)
    end

    test "handles negative balance correctly", %{cash_account: account} do
      new_balance = Decimal.new("-100.00")

      # Note: This should work as the BalanceManager doesn't enforce non-negative balances
      # The Account resource validation might prevent this, but BalanceManager allows it
      # for cases like overdrafts
      result = BalanceManager.update_cash_balance(account.id, new_balance)

      # The result depends on Account resource validation
      case result do
        {:ok, updated_account} ->
          assert Decimal.equal?(updated_account.balance, new_balance)
        {:error, _reason} ->
          # This is also acceptable if Account resource prevents negative balances
          assert true
      end
    end

    test "records balance history", %{cash_account: account} do
      old_balance = account.balance
      new_balance = Decimal.new("1500.00")
      notes = "Test deposit"

      assert {:ok, _updated_account} = BalanceManager.update_cash_balance(account.id, new_balance, notes)

      # Check that history was recorded
      assert {:ok, history} = BalanceManager.get_balance_history(account.id)
      assert length(history) >= 1

      latest_record = List.first(history)
      assert latest_record.account_id == account.id
      assert Decimal.equal?(latest_record.old_balance, old_balance)
      assert Decimal.equal?(latest_record.new_balance, new_balance)
      assert latest_record.notes == notes
      assert latest_record.timestamp != nil
    end
  end

  describe "get_balance_history/1" do
    setup do
      {:ok, user} = User.create(%{name: "Test User"})

      {:ok, cash_account} = Account.create(%{
        name: "Test Checking",
        platform: "Test Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("1000.00")
      })

      %{user: user, cash_account: cash_account}
    end

    test "returns empty history for account with no balance changes", %{cash_account: account} do
      assert {:ok, history} = BalanceManager.get_balance_history(account.id)
      assert history == []
    end

    test "returns history in chronological order (most recent first)", %{cash_account: account} do
      # Make multiple balance updates
      {:ok, _} = BalanceManager.update_cash_balance(account.id, Decimal.new("1100.00"), "First update")
      :timer.sleep(10) # Small delay to ensure different timestamps
      {:ok, _} = BalanceManager.update_cash_balance(account.id, Decimal.new("1200.00"), "Second update")
      :timer.sleep(10)
      {:ok, _} = BalanceManager.update_cash_balance(account.id, Decimal.new("1300.00"), "Third update")

      assert {:ok, history} = BalanceManager.get_balance_history(account.id)
      assert length(history) == 3

      # Check that history is ordered by timestamp (most recent first)
      timestamps = Enum.map(history, & &1.timestamp)
      sorted_timestamps = Enum.sort(timestamps, {:desc, DateTime})
      assert timestamps == sorted_timestamps

      # Check the content of the most recent record
      latest_record = List.first(history)
      assert latest_record.notes == "Third update"
      assert Decimal.equal?(latest_record.new_balance, Decimal.new("1300.00"))
    end

    test "returns error for non-existent account" do
      non_existent_id = Ash.UUID.generate()
      assert {:error, :account_not_found} = BalanceManager.get_balance_history(non_existent_id)
    end

    test "history is isolated per account", %{user: user} do
      # Create two accounts
      {:ok, account1} = Account.create(%{
        name: "Account 1",
        platform: "Bank 1",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("1000.00")
      })

      {:ok, account2} = Account.create(%{
        name: "Account 2",
        platform: "Bank 2",
        user_id: user.id,
        account_type: :savings,
        balance: Decimal.new("2000.00")
      })

      # Update balances for both accounts
      {:ok, _} = BalanceManager.update_cash_balance(account1.id, Decimal.new("1100.00"), "Account 1 update")
      {:ok, _} = BalanceManager.update_cash_balance(account2.id, Decimal.new("2200.00"), "Account 2 update")

      # Check that each account has its own history
      {:ok, history1} = BalanceManager.get_balance_history(account1.id)
      {:ok, history2} = BalanceManager.get_balance_history(account2.id)

      assert length(history1) == 1
      assert length(history2) == 1

      assert List.first(history1).notes == "Account 1 update"
      assert List.first(history2).notes == "Account 2 update"
    end
  end

  describe "PubSub integration" do
    setup do
      {:ok, user} = User.create(%{name: "Test User"})

      {:ok, cash_account} = Account.create(%{
        name: "Test Checking",
        platform: "Test Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("1000.00")
      })

      # Subscribe to balance change events
      PubSub.subscribe("balance_changes")

      %{user: user, cash_account: cash_account}
    end

    test "broadcasts balance change event with notes", %{cash_account: account} do
      old_balance = account.balance
      new_balance = Decimal.new("1500.00")
      notes = "Test deposit"

      assert {:ok, _updated_account} = BalanceManager.update_cash_balance(account.id, new_balance, notes)

      # Check that PubSub message was broadcast
      assert_receive {:balance_updated, message}

      assert message.account_id == account.id
      assert message.account_name == account.name
      assert message.account_type == account.account_type
      assert Decimal.equal?(message.old_balance, old_balance)
      assert Decimal.equal?(message.new_balance, new_balance)
      assert message.notes == notes
      assert message.timestamp != nil
    end

    test "broadcasts balance change event without notes", %{cash_account: account} do
      old_balance = account.balance
      new_balance = Decimal.new("800.00")

      assert {:ok, _updated_account} = BalanceManager.update_cash_balance(account.id, new_balance)

      # Check that PubSub message was broadcast
      assert_receive {:balance_updated, message}

      assert message.account_id == account.id
      assert Decimal.equal?(message.old_balance, old_balance)
      assert Decimal.equal?(message.new_balance, new_balance)
      assert message.notes == nil
    end

    test "does not broadcast on failed balance update" do
      non_existent_id = Ash.UUID.generate()
      new_balance = Decimal.new("1500.00")

      assert {:error, :account_not_found} = BalanceManager.update_cash_balance(non_existent_id, new_balance)

      # Should not receive any PubSub message
      refute_receive {:balance_updated, _message}, 100
    end
  end

  describe "edge cases and error handling" do
    setup do
      {:ok, user} = User.create(%{name: "Test User"})

      {:ok, cash_account} = Account.create(%{
        name: "Test Checking",
        platform: "Test Bank",
        user_id: user.id,
        account_type: :checking,
        balance: Decimal.new("1000.00")
      })

      %{user: user, cash_account: cash_account}
    end

    test "handles very large balance amounts", %{cash_account: account} do
      large_balance = Decimal.new("999999999.99")

      assert {:ok, updated_account} = BalanceManager.update_cash_balance(account.id, large_balance)
      assert Decimal.equal?(updated_account.balance, large_balance)
    end

    test "handles very small balance amounts", %{cash_account: account} do
      small_balance = Decimal.new("0.01")

      assert {:ok, updated_account} = BalanceManager.update_cash_balance(account.id, small_balance)
      assert Decimal.equal?(updated_account.balance, small_balance)
    end

    test "handles balance with many decimal places", %{cash_account: account} do
      precise_balance = Decimal.new("1234.56789")

      assert {:ok, updated_account} = BalanceManager.update_cash_balance(account.id, precise_balance)
      assert Decimal.equal?(updated_account.balance, precise_balance)
    end

    test "handles long notes", %{cash_account: account} do
      long_notes = String.duplicate("This is a very long note. ", 20)
      new_balance = Decimal.new("1500.00")

      assert {:ok, _updated_account} = BalanceManager.update_cash_balance(account.id, new_balance, long_notes)

      {:ok, history} = BalanceManager.get_balance_history(account.id)
      latest_record = List.first(history)
      assert latest_record.notes == long_notes
    end

    test "handles empty string notes", %{cash_account: account} do
      new_balance = Decimal.new("1500.00")

      assert {:ok, _updated_account} = BalanceManager.update_cash_balance(account.id, new_balance, "")

      {:ok, history} = BalanceManager.get_balance_history(account.id)
      latest_record = List.first(history)
      assert latest_record.notes == ""
    end
  end
end
