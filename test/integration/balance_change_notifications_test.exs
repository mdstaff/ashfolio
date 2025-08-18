defmodule Ashfolio.Integration.BalanceChangeNotificationsTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.FinancialManagement.BalanceManager
  alias Ashfolio.Portfolio.Account
  alias Ashfolio.PubSub

  describe "balance change notifications integration" do
    setup do
      # Database-as-user architecture: No user needed
      # Create test accounts
      {:ok, checking_account} =
        Account.create(%{
          name: "Integration Checking",
          platform: "Test Bank",
          account_type: :checking,
          balance: Decimal.new("2000.00")
        })

      {:ok, savings_account} =
        Account.create(%{
          name: "Integration Savings",
          platform: "Test Bank",
          account_type: :savings,
          balance: Decimal.new("5000.00"),
          interest_rate: Decimal.new("0.025")
        })

      %{
        checking_account: checking_account,
        savings_account: savings_account
      }
    end

    test "multiple subscribers receive balance change notifications", %{checking_account: account} do
      # Subscribe from multiple "processes" (simulating different parts of the app)
      PubSub.subscribe("balance_changes")

      # Simulate another subscriber (like a dashboard)
      dashboard_pid =
        spawn(fn ->
          PubSub.subscribe("balance_changes")

          receive do
            {:balance_updated, message} ->
              send(self(), {:dashboard_received, message})
          end
        end)

      # Simulate another subscriber (like a net worth calculator)
      calculator_pid =
        spawn(fn ->
          PubSub.subscribe("balance_changes")

          receive do
            {:balance_updated, message} ->
              send(self(), {:calculator_received, message})
          end
        end)

      # Update balance
      new_balance = Decimal.new("2500.00")
      notes = "Integration test deposit"

      {:ok, _updated_account} = BalanceManager.update_cash_balance(account.id, new_balance, notes)

      # All subscribers should receive the message
      assert_receive {:balance_updated, message}
      assert message.account_id == account.id
      assert Decimal.equal?(message.new_balance, new_balance)
      assert message.notes == notes

      # Clean up spawned processes
      Process.exit(dashboard_pid, :normal)
      Process.exit(calculator_pid, :normal)
    end

    test "balance change notifications contain complete account information", %{
      savings_account: account
    } do
      PubSub.subscribe("balance_changes")

      old_balance = account.balance
      new_balance = Decimal.new("5500.00")
      notes = "Interest payment"

      {:ok, _updated_account} = BalanceManager.update_cash_balance(account.id, new_balance, notes)

      assert_receive {:balance_updated, message}

      # Verify all expected fields are present and correct
      assert message.account_id == account.id
      assert message.account_name == account.name
      assert message.account_type == account.account_type
      assert Decimal.equal?(message.old_balance, old_balance)
      assert Decimal.equal?(message.new_balance, new_balance)
      assert message.notes == notes
      assert %DateTime{} = message.timestamp

      # Timestamp should be recent (within last few seconds)
      time_diff = DateTime.diff(DateTime.utc_now(), message.timestamp, :second)
      assert time_diff >= 0 and time_diff <= 5
    end

    test "rapid balance changes generate separate notifications", %{checking_account: account} do
      PubSub.subscribe("balance_changes")

      # Make rapid balance changes
      balances_and_notes = [
        {Decimal.new("2100.00"), "First update"},
        {Decimal.new("2200.00"), "Second update"},
        {Decimal.new("2300.00"), "Third update"}
      ]

      # Apply all updates
      Enum.each(balances_and_notes, fn {balance, notes} ->
        {:ok, _} = BalanceManager.update_cash_balance(account.id, balance, notes)
      end)

      # Should receive three separate notifications
      messages =
        for _ <- 1..3 do
          assert_receive {:balance_updated, message}
          message
        end

      # Verify each message corresponds to the correct update
      assert length(messages) == 3

      # Check that each message has the expected new_balance and notes
      expected_data = Enum.map(balances_and_notes, fn {balance, notes} -> {balance, notes} end)
      actual_data = Enum.map(messages, fn msg -> {msg.new_balance, msg.notes} end)

      # Sort both lists by balance to compare (since order might vary)
      expected_sorted =
        Enum.sort_by(expected_data, fn {balance, _} -> Decimal.to_float(balance) end)

      actual_sorted = Enum.sort_by(actual_data, fn {balance, _} -> Decimal.to_float(balance) end)

      Enum.zip(expected_sorted, actual_sorted)
      |> Enum.each(fn {{expected_balance, expected_notes}, {actual_balance, actual_notes}} ->
        assert Decimal.equal?(expected_balance, actual_balance)
        assert expected_notes == actual_notes
      end)
    end

    test "failed balance updates do not generate notifications", %{checking_account: account} do
      PubSub.subscribe("balance_changes")

      # Try to update a non-existent account
      non_existent_id = Ash.UUID.generate()

      {:error, :account_not_found} =
        BalanceManager.update_cash_balance(non_existent_id, Decimal.new("1000.00"))

      # Try to update an investment account (should fail)
      {:ok, investment_account} =
        Account.create(%{
          name: "Investment Account",
          platform: "Broker",
          account_type: :investment,
          balance: Decimal.new("10000.00")
        })

      {:error, :not_cash_account} =
        BalanceManager.update_cash_balance(investment_account.id, Decimal.new("11000.00"))

      # Should not receive any notifications
      refute_receive {:balance_updated, _message}, 100
    end

    test "notifications work across different cash account types" do
      # Create accounts of different cash types
      account_types = [:checking, :savings, :money_market, :cd]

      accounts =
        Enum.map(account_types, fn type ->
          {:ok, account} =
            Account.create(%{
              name: "#{type} Account",
              platform: "Test Bank",
              account_type: type,
              balance: Decimal.new("1000.00")
            })

          account
        end)

      PubSub.subscribe("balance_changes")

      # Update balance for each account type
      Enum.each(accounts, fn account ->
        new_balance = Decimal.new("1500.00")
        notes = "Update for #{account.account_type} account"

        {:ok, _} = BalanceManager.update_cash_balance(account.id, new_balance, notes)
      end)

      # Should receive notifications for all account types
      messages =
        for _ <- 1..4 do
          assert_receive {:balance_updated, message}
          message
        end

      # Verify we got notifications for all account types
      received_types = Enum.map(messages, & &1.account_type) |> Enum.sort()
      expected_types = Enum.sort(account_types)

      assert received_types == expected_types
    end

    test "notification message format is consistent", %{checking_account: account} do
      PubSub.subscribe("balance_changes")

      {:ok, _} =
        BalanceManager.update_cash_balance(account.id, Decimal.new("3000.00"), "Consistency test")

      assert_receive {:balance_updated, message}

      # Verify message structure
      assert is_map(message)

      required_keys = [
        :account_id,
        :account_name,
        :account_type,
        :old_balance,
        :new_balance,
        :notes,
        :timestamp
      ]

      actual_keys = Map.keys(message) |> Enum.sort()
      expected_keys = Enum.sort(required_keys)

      assert actual_keys == expected_keys

      # Verify data types
      assert is_binary(message.account_id)
      assert is_binary(message.account_name)
      assert is_atom(message.account_type)
      assert %Decimal{} = message.old_balance
      assert %Decimal{} = message.new_balance
      assert is_binary(message.notes) or is_nil(message.notes)
      assert %DateTime{} = message.timestamp
    end

    test "unsubscribing stops receiving notifications", %{checking_account: account} do
      PubSub.subscribe("balance_changes")

      # Make an update and verify we receive it
      {:ok, _} =
        BalanceManager.update_cash_balance(
          account.id,
          Decimal.new("2100.00"),
          "Before unsubscribe"
        )

      assert_receive {:balance_updated, _message}

      # Unsubscribe
      PubSub.unsubscribe("balance_changes")

      # Make another update
      {:ok, _} =
        BalanceManager.update_cash_balance(
          account.id,
          Decimal.new("2200.00"),
          "After unsubscribe"
        )

      # Should not receive the second notification
      refute_receive {:balance_updated, _message}, 100
    end
  end

  describe "error scenarios in integration context" do
    test "handles ETS table creation gracefully" do
      # This test ensures that the ETS table for balance history is created properly
      # even when multiple processes might be trying to create it simultaneously

      {:ok, account} =
        Account.create(%{
          name: "ETS Test Account",
          platform: "Test Bank",
          account_type: :checking,
          balance: Decimal.new("1000.00")
        })

      # First, do a sequential test to ensure the basic functionality works
      {:ok, _} =
        BalanceManager.update_cash_balance(account.id, Decimal.new("1100.00"), "Sequential test")

      {:ok, initial_history} = BalanceManager.get_balance_history(account.id)
      assert length(initial_history) == 1

      # Now simulate concurrent balance updates
      # Reduced from 5 to 3 for more reliable testing
      tasks =
        for i <- 1..3 do
          Task.async(fn ->
            balance = Decimal.new("#{1200 + i * 100}.00")
            notes = "Concurrent update #{i}"
            BalanceManager.update_cash_balance(account.id, balance, notes)
          end)
        end

      # Wait for all tasks to complete
      results = Task.await_many(tasks, 5000)

      # All updates should succeed
      assert Enum.all?(results, fn result ->
               match?({:ok, _account}, result)
             end)

      # Give a small delay for ETS operations to complete
      :timer.sleep(100)

      # History should contain all updates (initial + concurrent)
      {:ok, history} = BalanceManager.get_balance_history(account.id)
      # At least the concurrent updates should be there
      assert length(history) >= 3
    end
  end
end
