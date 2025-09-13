defmodule Ashfolio.Portfolio.Services.CorporateActionApplier do
  @moduledoc """
  Service for applying corporate actions to portfolio positions.
  
  This service orchestrates the application of corporate actions by:
  1. Finding all affected transactions for a symbol
  2. Using appropriate calculators to determine adjustments
  3. Creating transaction adjustment records
  4. Updating corporate action status
  5. Maintaining FIFO cost basis integrity
  
  ## Supported Actions
  - Stock splits (forward and reverse)
  - Cash dividends (qualified and ordinary)
  - Stock dividends (future)
  - Mergers and acquisitions (future)
  """

  alias Ashfolio.Portfolio.{CorporateAction, Transaction, TransactionAdjustment}
  alias Ashfolio.Portfolio.Calculators.{StockSplitCalculator, DividendCalculator}
  
  require Logger

  @doc """
  Applies a corporate action to all affected transactions.
  
  Returns `{:ok, %{corporate_action_id: String.t, adjustments_created: integer, status: atom}}`.
  """
  def apply_corporate_action(%CorporateAction{} = corporate_action) do
    case validate_action_for_application(corporate_action) do
      :ok ->
        do_apply_corporate_action(corporate_action)
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Applies all pending corporate actions for a symbol in chronological order.
  """
  def batch_apply_pending(symbol_id) do
    pending_actions = CorporateAction.pending!()
    
    # Filter by symbol and sort by ex_date
    symbol_actions = 
      pending_actions
      |> Enum.filter(&(&1.symbol_id == symbol_id))
      |> Enum.sort_by(& &1.ex_date)
    
    results = Enum.map(symbol_actions, &apply_corporate_action/1)
    
    # Check if any failed
    failures = Enum.filter(results, &match?({:error, _}, &1))
    
    if Enum.empty?(failures) do
      total_adjustments = 
        results
        |> Enum.map(fn {:ok, result} -> result.adjustments_created end)
        |> Enum.sum()
      
      {:ok, %{
        actions_processed: length(results),
        total_adjustments: total_adjustments
      }}
    else
      {:error, "Some actions failed to apply"}
    end
  end

  @doc """
  Previews the application of a corporate action without actually applying it.
  
  Useful for UI confirmation dialogs and impact analysis.
  """
  def preview_application(%CorporateAction{} = corporate_action) do
    case get_affected_transactions(corporate_action) do
      {:ok, transactions} ->
        preview = %{
          corporate_action_id: corporate_action.id,
          affected_transactions: length(transactions),
          estimated_adjustments: length(transactions),
          action_type: corporate_action.action_type,
          ex_date: corporate_action.ex_date
        }
        
        {:ok, preview}
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Reverses an applied corporate action by marking adjustments as reversed.
  """
  def reverse_application(corporate_action_id, reason) do
    with {:ok, corporate_action} <- Ash.get(CorporateAction, corporate_action_id, domain: Ashfolio.Portfolio),
         {:ok, adjustments} <- TransactionAdjustment.by_corporate_action(corporate_action_id) do
      
      # Reverse all adjustments
      reversal_results = Enum.map(adjustments, fn adjustment ->
        TransactionAdjustment.reverse(adjustment, reason, "corporate_action_applier")
      end)
      
      # Check for failures
      failures = Enum.filter(reversal_results, &match?({:error, _}, &1))
      
      if Enum.empty?(failures) do
        # Update corporate action status
        {:ok, _updated_action} = CorporateAction.reverse(corporate_action, reason)
        
        {:ok, %{
          corporate_action_id: corporate_action_id,
          adjustments_reversed: length(adjustments)
        }}
      else
        {:error, "Failed to reverse some adjustments"}
      end
    end
  end

  # Private functions

  defp validate_action_for_application(corporate_action) do
    cond do
      corporate_action.status != :pending ->
        {:error, "Corporate action is already applied or cancelled"}
      
      not action_type_supported?(corporate_action.action_type) ->
        {:error, "Action type #{corporate_action.action_type} is not supported yet"}
      
      Date.after?(corporate_action.ex_date, Date.utc_today()) ->
        {:error, "Ex-date is in the future"}
      
      true ->
        :ok
    end
  end

  defp action_type_supported?(:stock_split), do: true
  defp action_type_supported?(:cash_dividend), do: true
  defp action_type_supported?(_), do: false

  defp do_apply_corporate_action(corporate_action) do
    Logger.info("Applying corporate action: #{corporate_action.id} (#{corporate_action.action_type})")
    
    with {:ok, transactions} <- get_affected_transactions(corporate_action),
         {:ok, adjustments} <- calculate_adjustments(transactions, corporate_action),
         {:ok, _created_adjustments} <- create_adjustments(adjustments),
         {:ok, _updated_action} <- mark_action_applied(corporate_action) do
      
      {:ok, %{
        corporate_action_id: corporate_action.id,
        adjustments_created: length(adjustments),
        status: :applied
      }}
    else
      {:error, reason} ->
        Logger.error("Failed to apply corporate action #{corporate_action.id}: #{reason}")
        {:error, reason}
    end
  end

  defp get_affected_transactions(corporate_action) do
    # Get all buy transactions for the symbol before ex-date
    case Transaction.by_symbol(corporate_action.symbol_id) do
      {:ok, all_transactions} ->
        affected_transactions = 
          all_transactions
          |> Enum.filter(fn tx ->
            tx.type == :buy && 
            Date.compare(tx.date, corporate_action.ex_date) == :lt
          end)
          |> Enum.sort_by(& &1.date) # FIFO order
        
        {:ok, affected_transactions}
      
      {:error, reason} ->
        {:error, "Failed to find transactions: #{reason}"}
    end
  end

  defp calculate_adjustments(transactions, corporate_action) do
    case corporate_action.action_type do
      :stock_split ->
        calculate_stock_split_adjustments(transactions, corporate_action)
      
      :cash_dividend ->
        calculate_dividend_adjustments(transactions, corporate_action)
      
      unsupported_type ->
        {:error, "Calculator not implemented for #{unsupported_type}"}
    end
  end

  defp calculate_stock_split_adjustments(transactions, corporate_action) do
    case StockSplitCalculator.batch_apply(transactions, corporate_action) do
      {:ok, adjustments} ->
        {:ok, adjustments}
      
      {:error, reason} ->
        {:error, "Stock split calculation failed: #{reason}"}
    end
  end

  defp calculate_dividend_adjustments(transactions, corporate_action) do
    # Convert transactions to positions format for dividend calculator
    positions = Enum.map(transactions, fn tx ->
      %{
        transaction_id: tx.id,
        quantity: tx.quantity,
        purchase_date: tx.date
      }
    end)
    
    case DividendCalculator.batch_apply_dividends(positions, corporate_action) do
      {:ok, adjustments} ->
        {:ok, adjustments}
      
      {:error, reason} ->
        {:error, "Dividend calculation failed: #{reason}"}
    end
  end

  defp create_adjustments(adjustment_attrs_list) do
    results = Enum.map(adjustment_attrs_list, &TransactionAdjustment.create/1)
    
    # Check for any failures
    failures = Enum.filter(results, &match?({:error, _}, &1))
    
    if Enum.empty?(failures) do
      successes = Enum.map(results, fn {:ok, adj} -> adj end)
      {:ok, successes}
    else
      {:error, "Failed to create some adjustments"}
    end
  end

  defp mark_action_applied(corporate_action) do
    CorporateAction.apply(corporate_action, "corporate_action_applier")
  end
end