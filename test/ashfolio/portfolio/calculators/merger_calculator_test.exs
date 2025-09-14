defmodule Ashfolio.Portfolio.Calculators.MergerCalculatorTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Portfolio.Calculators.MergerCalculator
  alias Decimal, as: D

  @moduletag :calculators
  @moduletag :unit

  describe "calculate_stock_merger/3" do
    test "calculates stock-for-stock merger correctly" do
      # 100 shares @ $50 basis → 150 shares @ $33.33 basis (1.5:1 exchange)
      original_quantity = D.new("100")
      original_basis = D.new("50.00")
      exchange_ratio = D.new("1.5")

      {:ok, result} = MergerCalculator.calculate_stock_merger(original_quantity, original_basis, exchange_ratio)

      assert D.equal?(result.quantity, D.new("150"))
      # Basis per share: $5000 total basis / 150 shares = $33.333...
      expected_basis = D.div(D.mult(original_quantity, original_basis), result.quantity)
      assert D.equal?(result.basis_per_share, expected_basis)
      assert D.equal?(result.gain_loss, D.new("0"))
      assert result.tax_event == false
    end

    test "handles reverse exchange ratio" do
      # 200 shares @ $25 basis → 100 shares @ $50 basis (0.5:1 exchange)
      original_quantity = D.new("200")
      original_basis = D.new("25.00")
      exchange_ratio = D.new("0.5")

      {:ok, result} = MergerCalculator.calculate_stock_merger(original_quantity, original_basis, exchange_ratio)

      assert D.equal?(result.quantity, D.new("100"))
      assert D.equal?(result.basis_per_share, D.new("50.00"))
      assert D.equal?(result.gain_loss, D.new("0"))
    end

    test "validates input parameters" do
      assert {:error, reason} = MergerCalculator.calculate_stock_merger(D.new("0"), D.new("50"), D.new("1.5"))
      assert reason =~ "Quantity must be positive"

      assert {:error, reason} = MergerCalculator.calculate_stock_merger(D.new("100"), D.new("0"), D.new("1.5"))
      assert reason =~ "Basis per share must be positive"

      assert {:error, reason} = MergerCalculator.calculate_stock_merger(D.new("100"), D.new("50"), D.new("0"))
      assert reason =~ "Exchange ratio must be positive"
    end
  end

  describe "calculate_cash_merger/3" do
    test "calculates cash merger with gain" do
      # 100 shares @ $40 basis, receive $60 per share = $20 gain per share
      original_quantity = D.new("100")
      original_basis = D.new("40.00")
      cash_per_share = D.new("60.00")

      {:ok, result} = MergerCalculator.calculate_cash_merger(original_quantity, original_basis, cash_per_share)

      assert D.equal?(result.cash_received, D.new("6000.00"))
      assert D.equal?(result.original_basis, D.new("4000.00"))
      assert D.equal?(result.gain_loss, D.new("2000.00"))
      assert result.tax_event == true
      assert D.equal?(result.quantity, D.new("0"))
    end

    test "calculates cash merger with loss" do
      # 50 shares @ $80 basis, receive $60 per share = $20 loss per share
      original_quantity = D.new("50")
      original_basis = D.new("80.00")
      cash_per_share = D.new("60.00")

      {:ok, result} = MergerCalculator.calculate_cash_merger(original_quantity, original_basis, cash_per_share)

      assert D.equal?(result.cash_received, D.new("3000.00"))
      assert D.equal?(result.original_basis, D.new("4000.00"))
      assert D.equal?(result.gain_loss, D.new("-1000.00"))
      assert result.tax_event == true
    end

    test "validates input parameters" do
      assert {:error, reason} = MergerCalculator.calculate_cash_merger(D.new("-1"), D.new("50"), D.new("60"))
      assert reason =~ "Quantity must be positive"

      assert {:error, reason} = MergerCalculator.calculate_cash_merger(D.new("100"), D.new("-1"), D.new("60"))
      assert reason =~ "Basis per share must be positive"

      assert {:error, reason} = MergerCalculator.calculate_cash_merger(D.new("100"), D.new("50"), D.new("-1"))
      assert reason =~ "Cash per share cannot be negative"
    end
  end

  describe "calculate_mixed_merger/4" do
    test "calculates mixed consideration correctly" do
      # 100 shares @ $50 basis, 1.2:1 ratio + $10 cash per share
      original_quantity = D.new("100")
      original_basis = D.new("50.00")
      exchange_ratio = D.new("1.2")
      cash_per_share = D.new("10.00")

      {:ok, result} =
        MergerCalculator.calculate_mixed_merger(original_quantity, original_basis, exchange_ratio, cash_per_share)

      # 100 * 1.2
      assert D.equal?(result.quantity, D.new("120"))
      # 100 * $10
      assert D.equal?(result.cash_received, D.new("1000.00"))
      # Partial gain recognition on cash portion
      assert D.gte?(result.recognized_gain_loss, D.new("0"))
      assert result.tax_event == true
    end

    test "validates input parameters" do
      assert {:error, reason} =
               MergerCalculator.calculate_mixed_merger(D.new("0"), D.new("50"), D.new("1.2"), D.new("10"))

      assert reason =~ "Quantity must be positive"

      assert {:error, reason} =
               MergerCalculator.calculate_mixed_merger(D.new("100"), D.new("0"), D.new("1.2"), D.new("10"))

      assert reason =~ "Basis per share must be positive"

      assert {:error, reason} =
               MergerCalculator.calculate_mixed_merger(D.new("100"), D.new("50"), D.new("0"), D.new("10"))

      assert reason =~ "Exchange ratio must be positive"

      assert {:error, reason} =
               MergerCalculator.calculate_mixed_merger(D.new("100"), D.new("50"), D.new("1.2"), D.new("-1"))

      assert reason =~ "Cash per share cannot be negative"
    end
  end

  describe "calculate_spinoff/4" do
    test "calculates spinoff with basis allocation" do
      # 100 shares @ $100 basis, 1:1 spinoff ratio, 20% allocation to spinoff
      original_quantity = D.new("100")
      original_basis = D.new("100.00")
      spinoff_ratio = D.new("1")
      allocation_percentage = D.new("20")

      {:ok, result} =
        MergerCalculator.calculate_spinoff(original_quantity, original_basis, spinoff_ratio, allocation_percentage)

      assert D.equal?(result.original_quantity, D.new("100"))
      # 80% of original basis
      assert D.equal?(result.original_basis_per_share, D.new("80.00"))
      # 1:1 ratio
      assert D.equal?(result.spinoff_quantity, D.new("100"))
      # 20% of original basis
      assert D.equal?(result.spinoff_basis_per_share, D.new("20.00"))
      assert result.tax_event == false
    end

    test "calculates spinoff with different ratio" do
      # 200 shares @ $50 basis, 0.5:1 spinoff ratio, 25% allocation
      original_quantity = D.new("200")
      original_basis = D.new("50.00")
      spinoff_ratio = D.new("0.5")
      allocation_percentage = D.new("25")

      {:ok, result} =
        MergerCalculator.calculate_spinoff(original_quantity, original_basis, spinoff_ratio, allocation_percentage)

      assert D.equal?(result.original_quantity, D.new("200"))
      # 75% of $50
      assert D.equal?(result.original_basis_per_share, D.new("37.50"))
      # 200 * 0.5
      assert D.equal?(result.spinoff_quantity, D.new("100"))
      # (25% * 200 * $50) / 100
      assert D.equal?(result.spinoff_basis_per_share, D.new("25.00"))
    end

    test "validates input parameters" do
      assert {:error, reason} = MergerCalculator.calculate_spinoff(D.new("0"), D.new("50"), D.new("1"), D.new("20"))
      assert reason =~ "Quantity must be positive"

      assert {:error, reason} = MergerCalculator.calculate_spinoff(D.new("100"), D.new("0"), D.new("1"), D.new("20"))
      assert reason =~ "Basis per share must be positive"

      assert {:error, reason} = MergerCalculator.calculate_spinoff(D.new("100"), D.new("50"), D.new("0"), D.new("20"))
      assert reason =~ "Spinoff ratio must be positive"

      assert {:error, reason} = MergerCalculator.calculate_spinoff(D.new("100"), D.new("50"), D.new("1"), D.new("0"))
      assert reason =~ "Allocation percentage must be positive"

      assert {:error, reason} = MergerCalculator.calculate_spinoff(D.new("100"), D.new("50"), D.new("1"), D.new("150"))
      assert reason =~ "Allocation percentage cannot exceed 100%"
    end
  end

  describe "batch_apply_merger/2" do
    setup do
      # Create mock transactions
      tx1 = %{id: "tx1", quantity: D.new("100"), price: D.new("50.00")}
      tx2 = %{id: "tx2", quantity: D.new("200"), price: D.new("75.00")}
      transactions = [tx1, tx2]

      {:ok, transactions: transactions}
    end

    test "applies stock-for-stock merger to multiple transactions", %{transactions: transactions} do
      corporate_action = %{
        id: "ca1",
        merger_type: :stock_for_stock,
        exchange_ratio: D.new("1.5"),
        cash_consideration: nil
      }

      {:ok, adjustments} = MergerCalculator.batch_apply_merger(transactions, corporate_action)

      assert length(adjustments) == 2

      [adj1, adj2] = adjustments

      # First transaction: 100 @ $50 → 150 @ $33.333...
      assert adj1.transaction_id == "tx1"
      assert adj1.adjustment_type == :merger_stock_for_stock
      assert D.equal?(adj1.adjusted_quantity, D.new("150"))
      # Calculate expected basis: $5000 total / 150 shares
      expected_basis_1 = D.div(D.mult(D.new("100"), D.new("50.00")), D.new("150"))
      assert D.equal?(adj1.adjusted_price, expected_basis_1)
      assert D.equal?(adj1.gain_loss_amount, D.new("0"))

      # Second transaction: 200 @ $75 → 300 @ $50
      assert adj2.transaction_id == "tx2"
      assert D.equal?(adj2.adjusted_quantity, D.new("300"))
      assert D.equal?(adj2.adjusted_price, D.new("50.00"))
    end

    test "applies cash merger to multiple transactions", %{transactions: transactions} do
      corporate_action = %{
        id: "ca2",
        merger_type: :cash_for_stock,
        exchange_ratio: nil,
        cash_consideration: D.new("80.00")
      }

      {:ok, adjustments} = MergerCalculator.batch_apply_merger(transactions, corporate_action)

      assert length(adjustments) == 2

      [adj1, adj2] = adjustments

      # First transaction: 100 @ $50 basis, $80 cash = $30 gain per share
      assert adj1.transaction_id == "tx1"
      assert adj1.adjustment_type == :merger_cash_for_stock
      # Position closed
      assert D.equal?(adj1.adjusted_quantity, D.new("0"))
      # 100 * $80
      assert D.equal?(adj1.cash_received, D.new("8000.00"))
      # 100 * ($80 - $50)
      assert D.equal?(adj1.gain_loss_amount, D.new("3000.00"))

      # Second transaction: 200 @ $75 basis, $80 cash = $5 gain per share
      assert adj2.transaction_id == "tx2"
      # 200 * $80
      assert D.equal?(adj2.cash_received, D.new("16000.00"))
      # 200 * ($80 - $75)
      assert D.equal?(adj2.gain_loss_amount, D.new("1000.00"))
    end

    test "applies mixed consideration merger", %{transactions: transactions} do
      corporate_action = %{
        id: "ca3",
        merger_type: :mixed_consideration,
        exchange_ratio: D.new("1.2"),
        cash_consideration: D.new("10.00")
      }

      {:ok, adjustments} = MergerCalculator.batch_apply_merger(transactions, corporate_action)

      assert length(adjustments) == 2

      [adj1, adj2] = adjustments

      assert adj1.adjustment_type == :merger_mixed_consideration
      # 100 * 1.2
      assert D.equal?(adj1.adjusted_quantity, D.new("120"))
      # 100 * $10
      assert D.equal?(adj1.cash_received, D.new("1000.00"))

      assert adj2.adjustment_type == :merger_mixed_consideration
      # 200 * 1.2
      assert D.equal?(adj2.adjusted_quantity, D.new("240"))
      # 200 * $10
      assert D.equal?(adj2.cash_received, D.new("2000.00"))
    end

    test "handles missing merger type" do
      corporate_action = %{
        id: "ca4",
        merger_type: nil,
        exchange_ratio: D.new("1.5")
      }

      assert {:error, reason} = MergerCalculator.batch_apply_merger([], corporate_action)
      assert reason == "Merger type is required"
    end

    test "handles unsupported merger type" do
      corporate_action = %{
        id: "ca5",
        merger_type: :unsupported_type,
        exchange_ratio: D.new("1.5")
      }

      assert {:error, reason} = MergerCalculator.batch_apply_merger([], corporate_action)
      assert reason == "Unsupported merger type: unsupported_type"
    end

    test "validates required fields for stock merger" do
      corporate_action = %{
        id: "ca6",
        merger_type: :stock_for_stock,
        exchange_ratio: nil
      }

      assert {:error, reason} = MergerCalculator.batch_apply_merger([], corporate_action)
      assert reason == "Exchange ratio is required for stock-for-stock merger"
    end

    test "validates required fields for cash merger" do
      corporate_action = %{
        id: "ca7",
        merger_type: :cash_for_stock,
        cash_consideration: nil
      }

      assert {:error, reason} = MergerCalculator.batch_apply_merger([], corporate_action)
      assert reason == "Cash consideration is required for cash merger"
    end
  end

  describe "batch_apply_spinoff/2" do
    setup do
      new_symbol_id = "new_symbol_123"

      # Create mock transactions
      tx1 = %{id: "tx1", quantity: D.new("100"), price: D.new("80.00")}
      tx2 = %{id: "tx2", quantity: D.new("50"), price: D.new("120.00")}
      transactions = [tx1, tx2]

      corporate_action = %{
        id: "ca_spinoff",
        new_symbol_id: new_symbol_id,
        # 1:1 spinoff ratio
        exchange_ratio: D.new("1")
      }

      {:ok, transactions: transactions, corporate_action: corporate_action, new_symbol_id: new_symbol_id}
    end

    test "applies spinoff to multiple transactions", %{
      transactions: transactions,
      corporate_action: corporate_action,
      new_symbol_id: new_symbol_id
    } do
      {:ok, adjustments} = MergerCalculator.batch_apply_spinoff(transactions, corporate_action)

      # Should create 2 adjustments per transaction (original + spinoff)
      assert length(adjustments) == 4

      [original1, spinoff1, original2, spinoff2] = adjustments

      # First transaction original adjustment (reduced basis)
      assert original1.transaction_id == "tx1"
      assert original1.adjustment_type == :spinoff_original
      # Same quantity
      assert D.equal?(original1.adjusted_quantity, D.new("100"))
      # 80% of $80 original basis
      assert D.equal?(original1.adjusted_price, D.new("64.00"))

      # First transaction spinoff adjustment (new shares)
      # New transaction
      assert spinoff1.transaction_id == nil
      assert spinoff1.adjustment_type == :spinoff_new_shares
      # 1:1 ratio
      assert D.equal?(spinoff1.adjusted_quantity, D.new("100"))
      # 20% of $80 original basis
      assert D.equal?(spinoff1.adjusted_price, D.new("16.00"))
      assert spinoff1.new_symbol_id == new_symbol_id

      # Second transaction original adjustment
      assert original2.transaction_id == "tx2"
      assert D.equal?(original2.adjusted_quantity, D.new("50"))
      # 80% of $120
      assert D.equal?(original2.adjusted_price, D.new("96.00"))

      # Second transaction spinoff adjustment
      assert spinoff2.transaction_id == nil
      assert D.equal?(spinoff2.adjusted_quantity, D.new("50"))
      # 20% of $120
      assert D.equal?(spinoff2.adjusted_price, D.new("24.00"))
    end

    test "handles missing new_symbol_id" do
      corporate_action = %{
        id: "ca_bad_spinoff",
        new_symbol_id: nil,
        exchange_ratio: D.new("1")
      }

      assert {:error, reason} = MergerCalculator.batch_apply_spinoff([], corporate_action)
      assert reason == "New symbol is required for spinoff"
    end

    test "handles different spinoff ratios", %{transactions: transactions} do
      corporate_action = %{
        id: "ca_spinoff_2to1",
        new_symbol_id: "new_symbol_456",
        # 0.5:1 spinoff ratio (1 spinoff per 2 original)
        exchange_ratio: D.new("0.5")
      }

      {:ok, adjustments} = MergerCalculator.batch_apply_spinoff(transactions, corporate_action)

      [_original1, spinoff1, _original2, spinoff2] = adjustments

      # First transaction: 100 original → 50 spinoff shares
      assert D.equal?(spinoff1.adjusted_quantity, D.new("50"))

      # Second transaction: 50 original → 25 spinoff shares
      assert D.equal?(spinoff2.adjusted_quantity, D.new("25"))
    end
  end
end
