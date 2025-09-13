defmodule Ashfolio.Portfolio.Services.CorporateActionApplierTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.Portfolio.CorporateAction
  alias Ashfolio.Portfolio.Services.CorporateActionApplier
  alias Ashfolio.Portfolio.TransactionAdjustment

  @moduletag :services
  @moduletag :corporate_actions
  @moduletag :unit

  describe "apply_corporate_action/1" do
    setup do
      account = Ashfolio.SQLiteHelpers.get_default_account()
      symbol = Ashfolio.SQLiteHelpers.get_or_create_symbol("TEST", %{name: "Test Corp"})

      # Create test transactions
      tx1 =
        Ashfolio.SQLiteHelpers.create_test_transaction(account, symbol, %{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("200.00"),
          date: ~D[2024-01-15]
        })

      tx2 =
        Ashfolio.SQLiteHelpers.create_test_transaction(account, symbol, %{
          type: :buy,
          quantity: Decimal.new("50"),
          price: Decimal.new("220.00"),
          date: ~D[2024-02-15]
        })

      {:ok, account: account, symbol: symbol, transactions: [tx1, tx2]}
    end

    test "applies stock split to all transactions", %{symbol: symbol, transactions: _transactions} do
      # Create pending stock split
      {:ok, corporate_action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          ex_date: ~D[2024-06-01],
          description: "2:1 stock split",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("2"),
          status: :pending
        })

      result = CorporateActionApplier.apply_corporate_action(corporate_action)

      assert {:ok, results} = result
      assert results.corporate_action_id == corporate_action.id
      assert results.adjustments_created == 2
      assert results.status == :applied

      # Verify corporate action status was updated
      {:ok, updated_action} = Ash.get(CorporateAction, corporate_action.id, domain: Ashfolio.Portfolio)
      assert updated_action.status == :applied
      assert updated_action.applied_by == "corporate_action_applier"

      # Verify adjustments were created
      {:ok, adjustments} = TransactionAdjustment.by_corporate_action(corporate_action.id)
      assert length(adjustments) == 2

      # Verify adjustment values
      [adj1, adj2] = Enum.sort_by(adjustments, & &1.fifo_lot_order)

      # First transaction: 100 @ $200 → 200 @ $100
      assert Decimal.equal?(adj1.adjusted_quantity, Decimal.new("200"))
      assert Decimal.equal?(adj1.adjusted_price, Decimal.new("100.00"))

      # Second transaction: 50 @ $220 → 100 @ $110
      assert Decimal.equal?(adj2.adjusted_quantity, Decimal.new("100"))
      assert Decimal.equal?(adj2.adjusted_price, Decimal.new("110.00"))
    end

    test "applies dividend to all transactions", %{symbol: symbol, transactions: _transactions} do
      # Create pending dividend
      {:ok, corporate_action} =
        CorporateAction.create(%{
          action_type: :cash_dividend,
          symbol_id: symbol.id,
          ex_date: ~D[2024-06-01],
          pay_date: ~D[2024-06-15],
          description: "$1.00 quarterly dividend",
          dividend_amount: Decimal.new("1.00"),
          dividend_currency: "USD",
          qualified_dividend: true,
          status: :pending
        })

      result = CorporateActionApplier.apply_corporate_action(corporate_action)

      assert {:ok, results} = result
      assert results.adjustments_created == 2

      # Verify dividend adjustments
      {:ok, adjustments} = TransactionAdjustment.by_corporate_action(corporate_action.id)
      assert length(adjustments) == 2

      [adj1, adj2] = Enum.sort_by(adjustments, & &1.fifo_lot_order)

      # First position: 100 shares * $1.00 = $100.00
      assert Decimal.equal?(adj1.total_dividend, Decimal.new("100.00"))
      assert adj1.dividend_tax_status == :qualified

      # Second position: 50 shares * $1.00 = $50.00
      assert Decimal.equal?(adj2.total_dividend, Decimal.new("50.00"))
    end

    test "handles already applied corporate action", %{symbol: symbol} do
      {:ok, corporate_action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          ex_date: ~D[2024-06-01],
          description: "Already applied split",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("2"),
          status: :applied
        })

      result = CorporateActionApplier.apply_corporate_action(corporate_action)

      assert {:error, reason} = result
      assert reason =~ "already applied"
    end

    test "handles unsupported action type", %{symbol: symbol} do
      {:ok, corporate_action} =
        CorporateAction.create(%{
          # Not yet implemented
          action_type: :spinoff,
          symbol_id: symbol.id,
          ex_date: ~D[2024-06-01],
          description: "Spinoff action",
          status: :pending
        })

      result = CorporateActionApplier.apply_corporate_action(corporate_action)

      assert {:error, reason} = result
      assert reason =~ "not supported"
    end
  end

  describe "batch_apply_pending/1" do
    setup do
      account = Ashfolio.SQLiteHelpers.get_default_account()
      symbol = Ashfolio.SQLiteHelpers.get_or_create_symbol("BATCH", %{name: "Batch Test"})

      # Create test transaction
      _tx =
        Ashfolio.SQLiteHelpers.create_test_transaction(account, symbol, %{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("50.00"),
          date: ~D[2024-01-01]
        })

      {:ok, symbol: symbol}
    end

    test "applies all pending actions for a symbol", %{symbol: symbol} do
      # Create multiple pending actions
      {:ok, split_action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          # Earlier date
          ex_date: ~D[2024-05-01],
          description: "2:1 split",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("2"),
          status: :pending
        })

      {:ok, dividend_action} =
        CorporateAction.create(%{
          action_type: :cash_dividend,
          symbol_id: symbol.id,
          # Later date
          ex_date: ~D[2024-06-01],
          description: "$0.50 dividend",
          dividend_amount: Decimal.new("0.50"),
          status: :pending
        })

      result = CorporateActionApplier.batch_apply_pending(symbol.id)

      assert {:ok, batch_results} = result
      assert batch_results.actions_processed == 2
      # Split + dividend
      assert batch_results.total_adjustments == 2

      # Verify both actions were applied in correct order (by ex_date)
      {:ok, updated_split} = Ash.get(CorporateAction, split_action.id, domain: Ashfolio.Portfolio)
      {:ok, updated_dividend} = Ash.get(CorporateAction, dividend_action.id, domain: Ashfolio.Portfolio)

      assert updated_split.status == :applied
      assert updated_dividend.status == :applied
    end

    test "applies actions in chronological order by ex_date", %{symbol: symbol} do
      # Create actions with different ex_dates (out of chronological order)
      {:ok, later_action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          ex_date: ~D[2024-06-01],
          description: "Later split",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("2"),
          status: :pending
        })

      {:ok, earlier_action} =
        CorporateAction.create(%{
          action_type: :cash_dividend,
          symbol_id: symbol.id,
          ex_date: ~D[2024-05-01],
          description: "Earlier dividend",
          dividend_amount: Decimal.new("1.00"),
          status: :pending
        })

      result = CorporateActionApplier.batch_apply_pending(symbol.id)

      assert {:ok, _batch_results} = result

      # Check that both were applied
      {:ok, updated_earlier} = Ash.get(CorporateAction, earlier_action.id, domain: Ashfolio.Portfolio)
      {:ok, updated_later} = Ash.get(CorporateAction, later_action.id, domain: Ashfolio.Portfolio)

      assert updated_earlier.status == :applied
      assert updated_later.status == :applied

      # Earlier action should have been applied first (applied_at should be <= later)
      # Note: May be equal if applied within the same millisecond
      assert DateTime.compare(updated_earlier.applied_at, updated_later.applied_at) in [:lt, :eq]
    end
  end

  describe "preview_application/1" do
    setup do
      account = Ashfolio.SQLiteHelpers.get_default_account()
      symbol = Ashfolio.SQLiteHelpers.get_or_create_symbol("PREV", %{name: "Preview Corp"})

      {:ok, account: account, symbol: symbol}
    end

    test "previews stock split application without applying", %{symbol: symbol, account: account} do
      # Create test transaction
      _tx =
        Ashfolio.SQLiteHelpers.create_test_transaction(account, symbol, %{
          type: :buy,
          quantity: Decimal.new("150"),
          price: Decimal.new("80.00"),
          date: ~D[2024-01-01]
        })

      {:ok, corporate_action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          ex_date: ~D[2024-06-01],
          description: "3:2 stock split",
          split_ratio_from: Decimal.new("2"),
          split_ratio_to: Decimal.new("3"),
          status: :pending
        })

      result = CorporateActionApplier.preview_application(corporate_action)

      assert {:ok, preview} = result
      assert preview.corporate_action_id == corporate_action.id
      assert preview.affected_transactions == 1
      assert preview.estimated_adjustments == 1

      # Verify corporate action wasn't actually applied
      {:ok, unchanged_action} = Ash.get(CorporateAction, corporate_action.id, domain: Ashfolio.Portfolio)
      assert unchanged_action.status == :pending

      # Verify no adjustments were created
      {:ok, adjustments} = TransactionAdjustment.by_corporate_action(corporate_action.id)
      assert adjustments == []
    end
  end

  describe "reverse_application/1" do
    setup do
      account = Ashfolio.SQLiteHelpers.get_default_account()
      symbol = Ashfolio.SQLiteHelpers.get_or_create_symbol("REV", %{name: "Reversal Corp"})

      tx =
        Ashfolio.SQLiteHelpers.create_test_transaction(account, symbol, %{
          type: :buy,
          quantity: Decimal.new("200"),
          price: Decimal.new("50.00"),
          date: ~D[2024-01-01]
        })

      {:ok, account: account, symbol: symbol, transactions: [tx]}
    end

    test "reverses applied corporate action", %{symbol: symbol, transactions: [_tx | _]} do
      # Create and apply a stock split
      {:ok, corporate_action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          ex_date: ~D[2024-06-01],
          description: "2:1 split to reverse",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("2"),
          status: :pending
        })

      # Apply it first
      {:ok, _apply_result} = CorporateActionApplier.apply_corporate_action(corporate_action)

      # Now reverse it
      result = CorporateActionApplier.reverse_application(corporate_action.id, "Testing reversal")

      assert {:ok, reversal_result} = result
      assert reversal_result.corporate_action_id == corporate_action.id
      assert reversal_result.adjustments_reversed > 0

      # Verify corporate action status
      {:ok, reversed_action} = Ash.get(CorporateAction, corporate_action.id, domain: Ashfolio.Portfolio)
      assert reversed_action.status == :reversed
      assert reversed_action.reversal_reason == "Testing reversal"

      # Verify adjustments are marked as reversed
      {:ok, adjustments} = TransactionAdjustment.by_corporate_action(corporate_action.id)
      assert Enum.all?(adjustments, &(&1.is_reversed == true))
    end
  end
end
