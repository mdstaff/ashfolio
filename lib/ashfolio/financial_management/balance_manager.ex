defmodule Ashfolio.FinancialManagement.BalanceManager do
  @moduledoc """
  BalanceManager for manual cash balance updates.

  This module provides functionality for manually updating cash account balances
  with optional notes and maintains a simple balance history for audit purposes.
  It also broadcasts balance change events via PubSub for real-time updates.
  """

  alias Ashfolio.Portfolio.Account
  alias Ashfolio.PubSub

  @doc """
  Updates the cash balance for a given account with optional notes.

  This function:
  1. Validates that the account exists and is a cash account type
  2. Records the balance change in history
  3. Updates the account balance
  4. Broadcasts the balance change event via PubSub

  ## Parameters

  - `account_id` - UUID of the account to update
  - `new_balance` - The new balance as a Decimal
  - `notes` - Optional notes about the balance change

  ## Returns

  - `{:ok, account}` - Successfully updated account
  - `{:error, reason}` - Error occurred during update

  ## Examples

      iex> BalanceManager.update_cash_balance(account_id, Decimal.new("1500.00"), "Monthly deposit")
      {:ok, %Account{balance: #Decimal<1500.00>}}

      iex> BalanceManager.update_cash_balance(account_id, Decimal.new("1500.00"))
      {:ok, %Account{balance: #Decimal<1500.00>}}
  """
  def update_cash_balance(account_id, new_balance, notes \\ nil) do
    with {:ok, account} <- get_account(account_id),
         :ok <- validate_cash_account(account),
         {:ok, old_balance} <- get_current_balance(account),
         :ok <- record_balance_history(account_id, old_balance, new_balance, notes),
         {:ok, updated_account} <- update_account_balance(account, new_balance) do
      # Broadcast balance change event
      broadcast_balance_change(updated_account, old_balance, new_balance, notes)

      {:ok, updated_account}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets the balance history for an account.

  Returns a list of balance change records for the specified account,
  ordered by timestamp (most recent first).

  ## Parameters

  - `account_id` - UUID of the account

  ## Returns

  - `{:ok, history}` - List of balance history records
  - `{:error, reason}` - Error occurred during retrieval
  """
  def get_balance_history(account_id) do
    case get_account(account_id) do
      {:ok, _account} ->
        history = get_balance_history_records(account_id)
        {:ok, history}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private functions

  defp get_account(account_id) do
    case Account.get_by_id(account_id) do
      {:ok, account} ->
        {:ok, account}

      {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{} | _]}} ->
        {:error, :account_not_found}

      {:error, %Ash.Error.Query.NotFound{}} ->
        {:error, :account_not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_cash_account(account) do
    if account.account_type in [:checking, :savings, :money_market, :cd] do
      :ok
    else
      {:error, :not_cash_account}
    end
  end

  defp get_current_balance(account) do
    {:ok, account.balance || Decimal.new(0)}
  end

  defp record_balance_history(account_id, old_balance, new_balance, notes) do
    history_record = %{
      account_id: account_id,
      timestamp: DateTime.utc_now(),
      old_balance: old_balance,
      new_balance: new_balance,
      notes: notes
    }

    # Store in ETS table for simple history tracking
    # This is a simple implementation - in a production system you might want
    # to use a proper database table for persistence
    table_name = balance_history_table()
    :ets.insert(table_name, {account_id, DateTime.utc_now(), history_record})
    :ok
  end

  defp update_account_balance(account, new_balance) do
    Account.update_balance(account, %{balance: new_balance})
  end

  defp broadcast_balance_change(account, old_balance, new_balance, notes) do
    message = %{
      account_id: account.id,
      account_name: account.name,
      account_type: account.account_type,
      old_balance: old_balance,
      new_balance: new_balance,
      notes: notes,
      timestamp: DateTime.utc_now()
    }

    PubSub.broadcast("balance_changes", {:balance_updated, message})
  end

  defp get_balance_history_records(account_id) do
    table_name = balance_history_table()

    # Get all records for this account
    records = :ets.match(table_name, {account_id, :"$1", :"$2"})

    # Sort by timestamp (most recent first) and extract the history records
    records
    |> Enum.sort_by(fn [timestamp, _record] -> timestamp end, {:desc, DateTime})
    |> Enum.map(fn [_timestamp, record] -> record end)
  end

  defp balance_history_table do
    table_name = :balance_history

    # Create table if it doesn't exist, handle race conditions
    case :ets.whereis(table_name) do
      :undefined ->
        try do
          :ets.new(table_name, [:named_table, :protected, :bag])
        rescue
          ArgumentError ->
            # Table was created by another process, just return the name
            table_name
        end

      _ ->
        table_name
    end

    table_name
  end
end
