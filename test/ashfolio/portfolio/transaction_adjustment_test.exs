defmodule Ashfolio.Portfolio.TransactionAdjustmentTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.Portfolio.CorporateAction
  alias Ashfolio.Portfolio.TransactionAdjustment

  @moduletag :ash_resources
  @moduletag :corporate_actions
  @moduletag :unit

  describe "TransactionAdjustment resource" do
    setup do
      account = Ashfolio.SQLiteHelpers.get_default_account()
      symbol = Ashfolio.SQLiteHelpers.get_or_create_symbol("TSLA", %{name: "Tesla Inc."})

      # Create a test transaction that will be adjusted
      transaction =
        Ashfolio.SQLiteHelpers.create_test_transaction(account, symbol, %{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("200.00"),
          date: ~D[2024-01-15]
        })

      # Create a corporate action
      {:ok, corporate_action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          ex_date: ~D[2024-02-01],
          description: "2:1 stock split",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("2"),
          status: :applied
        })

      {:ok, account: account, symbol: symbol, transaction: transaction, corporate_action: corporate_action}
    end

    test "creates adjustment for stock split", %{transaction: transaction, corporate_action: corporate_action} do
      adjustment_attrs = %{
        transaction_id: transaction.id,
        corporate_action_id: corporate_action.id,
        adjustment_type: :quantity_price,
        reason: "2:1 stock split adjustment",
        original_quantity: Decimal.new("100"),
        adjusted_quantity: Decimal.new("200"),
        original_price: Decimal.new("200.00"),
        adjusted_price: Decimal.new("100.00"),
      }

      assert {:ok, adjustment} = TransactionAdjustment.create(adjustment_attrs)

      assert adjustment.transaction_id == transaction.id
      assert adjustment.corporate_action_id == corporate_action.id
      assert adjustment.adjustment_type == :quantity_price
      assert Decimal.equal?(adjustment.original_quantity, Decimal.new("100"))
      assert Decimal.equal?(adjustment.adjusted_quantity, Decimal.new("200"))
      assert Decimal.equal?(adjustment.original_price, Decimal.new("200.00"))
      assert Decimal.equal?(adjustment.adjusted_price, Decimal.new("100.00"))
    end

    test "validates total value preservation in adjustment", %{
      transaction: transaction,
      corporate_action: corporate_action
    } do
      # Invalid adjustment that changes total value
      invalid_attrs = %{
        transaction_id: transaction.id,
        corporate_action_id: corporate_action.id,
        adjustment_type: :quantity_price,
        reason: "Invalid split adjustment",
        original_quantity: Decimal.new("100"),
        adjusted_quantity: Decimal.new("200"),
        original_price: Decimal.new("200.00"),
        # This would increase total value
        adjusted_price: Decimal.new("150.00"),
      }

      # Should fail validation because 100 * $200 != 200 * $150
      assert {:error, changeset} = TransactionAdjustment.create(invalid_attrs)
      # Value preservation error shows up on adjusted_price field
      assert Enum.any?(changeset.errors, fn error ->
        error.field == :adjusted_price &&
        error.message =~ "value must be preserved"
      end)
    end

    test "creates adjustment for dividend payment", %{transaction: transaction} do
      # Create a dividend corporate action
      {:ok, dividend_action} =
        CorporateAction.create(%{
          action_type: :cash_dividend,
          symbol_id: transaction.symbol_id,
          ex_date: ~D[2024-03-01],
          pay_date: ~D[2024-03-15],
          description: "$5.00 special dividend",
          dividend_amount: Decimal.new("5.00"),
          status: :applied
        })

      adjustment_attrs = %{
        transaction_id: transaction.id,
        corporate_action_id: dividend_action.id,
        adjustment_type: :cash_receipt,
        reason: "$5.00 dividend payment for 100 shares",
        dividend_per_share: Decimal.new("5.00"),
        shares_eligible: Decimal.new("100"),
        total_dividend: Decimal.new("500.00"),
      }

      assert {:ok, adjustment} = TransactionAdjustment.create(adjustment_attrs)

      assert adjustment.adjustment_type == :cash_receipt
      assert Decimal.equal?(adjustment.dividend_per_share, Decimal.new("5.00"))
      assert Decimal.equal?(adjustment.shares_eligible, Decimal.new("100"))
      assert Decimal.equal?(adjustment.total_dividend, Decimal.new("500.00"))
    end

    test "prevents duplicate adjustments for same transaction and corporate action", %{
      transaction: transaction,
      corporate_action: corporate_action
    } do
      adjustment_attrs = %{
        transaction_id: transaction.id,
        corporate_action_id: corporate_action.id,
        adjustment_type: :quantity_price,
        reason: "2:1 stock split adjustment",
        original_quantity: Decimal.new("100"),
        adjusted_quantity: Decimal.new("200"),
        original_price: Decimal.new("200.00"),
        adjusted_price: Decimal.new("100.00"),
      }

      # Create first adjustment
      assert {:ok, _adjustment1} = TransactionAdjustment.create(adjustment_attrs)

      # Try to create duplicate - should fail
      assert {:error, changeset} = TransactionAdjustment.create(adjustment_attrs)
      # The unique constraint shows up as "has already been taken" on the individual fields
      assert Enum.any?(changeset.errors, fn error ->
        error.field in [:transaction_id, :corporate_action_id] &&
        error.message =~ "already been taken"
      end)
    end
  end

  describe "TransactionAdjustment queries and relationships" do
    setup do
      account = Ashfolio.SQLiteHelpers.get_default_account()
      symbol = Ashfolio.SQLiteHelpers.get_or_create_symbol("NVDA", %{name: "NVIDIA Corp."})

      # Create multiple transactions
      transaction1 =
        Ashfolio.SQLiteHelpers.create_test_transaction(account, symbol, %{
          type: :buy,
          quantity: Decimal.new("50"),
          price: Decimal.new("400.00"),
          date: ~D[2024-01-10]
        })

      transaction2 =
        Ashfolio.SQLiteHelpers.create_test_transaction(account, symbol, %{
          type: :buy,
          quantity: Decimal.new("25"),
          price: Decimal.new("450.00"),
          date: ~D[2024-01-20]
        })

      {:ok, corporate_action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          ex_date: ~D[2024-02-01],
          description: "4:1 stock split",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("4"),
          status: :applied
        })

      {:ok,
       account: account, symbol: symbol, transactions: [transaction1, transaction2], corporate_action: corporate_action}
    end

    test "finds all adjustments for a corporate action", %{transactions: [tx1, tx2], corporate_action: corporate_action} do
      # Create adjustments for both transactions
      {:ok, _adj1} =
        TransactionAdjustment.create(%{
          transaction_id: tx1.id,
          corporate_action_id: corporate_action.id,
          adjustment_type: :quantity_price,
          reason: "4:1 split - transaction 1",
          original_quantity: Decimal.new("50"),
          adjusted_quantity: Decimal.new("200"),
          original_price: Decimal.new("400.00"),
          adjusted_price: Decimal.new("100.00"),
          })

      {:ok, _adj2} =
        TransactionAdjustment.create(%{
          transaction_id: tx2.id,
          corporate_action_id: corporate_action.id,
          adjustment_type: :quantity_price,
          reason: "4:1 split - transaction 2",
          original_quantity: Decimal.new("25"),
          adjusted_quantity: Decimal.new("100"),
          original_price: Decimal.new("450.00"),
          adjusted_price: Decimal.new("112.50"),
          })

      # Query adjustments for the corporate action
      {:ok, adjustments} = TransactionAdjustment.by_corporate_action(corporate_action.id)

      assert length(adjustments) == 2
    end

    test "finds all adjustments for a transaction", %{transactions: [tx1, _tx2], corporate_action: corporate_action} do
      {:ok, adjustment} =
        TransactionAdjustment.create(%{
          transaction_id: tx1.id,
          corporate_action_id: corporate_action.id,
          adjustment_type: :quantity_price,
          reason: "4:1 split adjustment",
          original_quantity: Decimal.new("50"),
          adjusted_quantity: Decimal.new("200"),
          original_price: Decimal.new("400.00"),
          adjusted_price: Decimal.new("100.00"),
          })

      # Query adjustments for the specific transaction
      {:ok, adjustments} = TransactionAdjustment.by_transaction(tx1.id)

      assert length(adjustments) == 1
      assert List.first(adjustments).id == adjustment.id
    end

    test "calculates adjustment impact on FIFO cost basis", %{transactions: [tx1, tx2]} do
      # This test validates that adjustments maintain proper FIFO ordering
      # and cost basis calculations after corporate actions

      {:ok, corporate_action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: tx1.symbol_id,
          ex_date: ~D[2024-02-01],
          description: "2:1 stock split",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("2"),
          status: :applied
        })

      # Create adjustments that preserve FIFO order
      {:ok, adj1} =
        TransactionAdjustment.create(%{
          # Earlier transaction - first in FIFO
          transaction_id: tx1.id,
          corporate_action_id: corporate_action.id,
          adjustment_type: :quantity_price,
          reason: "2:1 split - lot 1",
          original_quantity: Decimal.new("50"),
          adjusted_quantity: Decimal.new("100"),
          original_price: Decimal.new("400.00"),
          adjusted_price: Decimal.new("200.00"),
          fifo_lot_order: 1,
          })

      {:ok, adj2} =
        TransactionAdjustment.create(%{
          # Later transaction - second in FIFO
          transaction_id: tx2.id,
          corporate_action_id: corporate_action.id,
          adjustment_type: :quantity_price,
          reason: "2:1 split - lot 2",
          original_quantity: Decimal.new("25"),
          adjusted_quantity: Decimal.new("50"),
          original_price: Decimal.new("450.00"),
          adjusted_price: Decimal.new("225.00"),
          fifo_lot_order: 2,
          })

      # Verify FIFO ordering is preserved
      assert adj1.fifo_lot_order < adj2.fifo_lot_order

      # Verify total value is preserved
      original_value1 = Decimal.mult(adj1.original_quantity, adj1.original_price)
      adjusted_value1 = Decimal.mult(adj1.adjusted_quantity, adj1.adjusted_price)
      assert Decimal.equal?(original_value1, adjusted_value1)

      original_value2 = Decimal.mult(adj2.original_quantity, adj2.original_price)
      adjusted_value2 = Decimal.mult(adj2.adjusted_quantity, adj2.adjusted_price)
      assert Decimal.equal?(original_value2, adjusted_value2)
    end
  end

  describe "TransactionAdjustment reversibility" do
    setup do
      account = Ashfolio.SQLiteHelpers.get_default_account()
      symbol = Ashfolio.SQLiteHelpers.get_or_create_symbol("AMD", %{name: "Advanced Micro Devices"})

      transaction =
        Ashfolio.SQLiteHelpers.create_test_transaction(account, symbol, %{
          type: :buy,
          quantity: Decimal.new("200"),
          price: Decimal.new("100.00"),
          date: ~D[2024-01-01]
        })

      {:ok, corporate_action} =
        CorporateAction.create(%{
          action_type: :stock_split,
          symbol_id: symbol.id,
          ex_date: ~D[2024-02-01],
          description: "2:1 stock split",
          split_ratio_from: Decimal.new("1"),
          split_ratio_to: Decimal.new("2"),
          status: :applied
        })

      {:ok, transaction: transaction, corporate_action: corporate_action}
    end

    test "supports reversal of adjustments", %{transaction: transaction, corporate_action: corporate_action} do
      # Create original adjustment
      {:ok, adjustment} =
        TransactionAdjustment.create(%{
          transaction_id: transaction.id,
          corporate_action_id: corporate_action.id,
          adjustment_type: :quantity_price,
          reason: "2:1 stock split",
          original_quantity: Decimal.new("200"),
          adjusted_quantity: Decimal.new("400"),
          original_price: Decimal.new("100.00"),
          adjusted_price: Decimal.new("50.00"),
          })

      # Mark as reversed (for corrections)
      {:ok, reversed_adjustment} =
        TransactionAdjustment.update(adjustment, %{
          is_reversed: true,
          reversed_at: DateTime.utc_now(),
          reversal_reason: "Corporate action correction"
        })

      assert reversed_adjustment.is_reversed == true
      assert %DateTime{} = reversed_adjustment.reversed_at
      assert reversed_adjustment.reversal_reason == "Corporate action correction"
    end

    test "tracks adjustment history and audit trail", %{transaction: transaction, corporate_action: corporate_action} do
      {:ok, adjustment} =
        TransactionAdjustment.create(%{
          transaction_id: transaction.id,
          corporate_action_id: corporate_action.id,
          adjustment_type: :quantity_price,
          reason: "2:1 stock split",
          original_quantity: Decimal.new("200"),
          adjusted_quantity: Decimal.new("400"),
          original_price: Decimal.new("100.00"),
          adjusted_price: Decimal.new("50.00"),
          created_by: "system_processor",
          })

      assert adjustment.created_by == "system_processor"
      assert %DateTime{} = adjustment.inserted_at

      # Verify immutability - adjustments should not be updateable once created
      # Only reversal flag and audit fields should be updatable
      assert {:error, _} =
               TransactionAdjustment.update(adjustment, %{
                 # Should not be allowed
                 adjusted_quantity: Decimal.new("500")
               })
    end
  end
end
