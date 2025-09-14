defmodule Ashfolio.Portfolio.Calculators.StockSplitCalculatorTest do
  use Ashfolio.DataCase, async: true

  alias Ashfolio.Portfolio.Calculators.StockSplitCalculator

  @moduletag :calculators
  @moduletag :unit

  describe "calculate_adjusted_values/3" do
    test "calculates 2:1 forward stock split correctly" do
      # 2:1 split means 1 share becomes 2 shares
      original_quantity = Decimal.new("100")
      original_price = Decimal.new("200.00")
      split_ratio = {Decimal.new("1"), Decimal.new("2")}

      result =
        StockSplitCalculator.calculate_adjusted_values(
          original_quantity,
          original_price,
          split_ratio
        )

      assert {:ok, adjusted} = result
      assert Decimal.equal?(adjusted.quantity, Decimal.new("200"))
      assert Decimal.equal?(adjusted.price, Decimal.new("100.00"))

      # Verify total value preservation
      original_value = Decimal.mult(original_quantity, original_price)
      adjusted_value = Decimal.mult(adjusted.quantity, adjusted.price)
      assert Decimal.equal?(original_value, adjusted_value)
    end

    test "calculates 1:2 reverse stock split correctly" do
      # 1:2 reverse split means 2 shares become 1 share
      original_quantity = Decimal.new("200")
      original_price = Decimal.new("50.00")
      split_ratio = {Decimal.new("2"), Decimal.new("1")}

      result =
        StockSplitCalculator.calculate_adjusted_values(
          original_quantity,
          original_price,
          split_ratio
        )

      assert {:ok, adjusted} = result
      assert Decimal.equal?(adjusted.quantity, Decimal.new("100"))
      assert Decimal.equal?(adjusted.price, Decimal.new("100.00"))

      # Verify total value preservation
      original_value = Decimal.mult(original_quantity, original_price)
      adjusted_value = Decimal.mult(adjusted.quantity, adjusted.price)
      assert Decimal.equal?(original_value, adjusted_value)
    end

    test "calculates 3:2 split correctly" do
      # 3:2 split means 2 shares become 3 shares
      original_quantity = Decimal.new("100")
      original_price = Decimal.new("150.00")
      split_ratio = {Decimal.new("2"), Decimal.new("3")}

      result =
        StockSplitCalculator.calculate_adjusted_values(
          original_quantity,
          original_price,
          split_ratio
        )

      assert {:ok, adjusted} = result
      assert Decimal.equal?(adjusted.quantity, Decimal.new("150"))
      assert Decimal.equal?(adjusted.price, Decimal.new("100.00"))
    end

    test "handles fractional shares from splits" do
      # 3:2 split with odd number of shares
      original_quantity = Decimal.new("7")
      original_price = Decimal.new("300.00")
      split_ratio = {Decimal.new("2"), Decimal.new("3")}

      result =
        StockSplitCalculator.calculate_adjusted_values(
          original_quantity,
          original_price,
          split_ratio
        )

      assert {:ok, adjusted} = result
      # 7 * (3/2) = 10.5 shares
      assert Decimal.equal?(adjusted.quantity, Decimal.new("10.5"))
      assert Decimal.equal?(adjusted.price, Decimal.new("200.00"))
    end

    test "returns error for zero split ratio" do
      original_quantity = Decimal.new("100")
      original_price = Decimal.new("200.00")
      invalid_ratio = {Decimal.new("0"), Decimal.new("2")}

      result =
        StockSplitCalculator.calculate_adjusted_values(
          original_quantity,
          original_price,
          invalid_ratio
        )

      assert {:error, reason} = result
      assert reason =~ "Invalid split ratio"
    end

    test "returns error for negative values" do
      negative_quantity = Decimal.new("-100")
      original_price = Decimal.new("200.00")
      split_ratio = {Decimal.new("1"), Decimal.new("2")}

      result =
        StockSplitCalculator.calculate_adjusted_values(
          negative_quantity,
          original_price,
          split_ratio
        )

      assert {:error, reason} = result
      assert reason =~ "must be positive"
    end
  end

  describe "apply_to_transaction/2" do
    test "creates proper adjustment record for transaction" do
      transaction = %{
        id: Ecto.UUID.generate(),
        quantity: Decimal.new("100"),
        price: Decimal.new("200.00")
      }

      corporate_action = %{
        id: Ecto.UUID.generate(),
        split_ratio_from: Decimal.new("1"),
        split_ratio_to: Decimal.new("2"),
        description: "2:1 stock split"
      }

      result = StockSplitCalculator.apply_to_transaction(transaction, corporate_action)

      assert {:ok, adjustment_attrs} = result
      assert adjustment_attrs.transaction_id == transaction.id
      assert adjustment_attrs.corporate_action_id == corporate_action.id
      assert adjustment_attrs.adjustment_type == :quantity_price
      assert adjustment_attrs.reason =~ "2:1 stock split"
      assert Decimal.equal?(adjustment_attrs.original_quantity, Decimal.new("100"))
      assert Decimal.equal?(adjustment_attrs.original_price, Decimal.new("200.00"))
      assert Decimal.equal?(adjustment_attrs.adjusted_quantity, Decimal.new("200"))
      assert Decimal.equal?(adjustment_attrs.adjusted_price, Decimal.new("100.00"))
    end
  end

  describe "batch_apply/2" do
    test "applies split to multiple transactions" do
      transactions = [
        %{id: "tx1", quantity: Decimal.new("100"), price: Decimal.new("200.00"), date: ~D[2024-01-01]},
        %{id: "tx2", quantity: Decimal.new("50"), price: Decimal.new("200.00"), date: ~D[2024-01-02]},
        %{id: "tx3", quantity: Decimal.new("75"), price: Decimal.new("200.00"), date: ~D[2024-01-03]}
      ]

      corporate_action = %{
        id: "ca1",
        split_ratio_from: Decimal.new("1"),
        split_ratio_to: Decimal.new("2"),
        description: "2:1 stock split"
      }

      results = StockSplitCalculator.batch_apply(transactions, corporate_action)

      assert {:ok, adjustments} = results
      assert length(adjustments) == 3

      # Verify each adjustment
      [adj1, adj2, adj3] = adjustments
      assert Decimal.equal?(adj1.adjusted_quantity, Decimal.new("200"))
      assert Decimal.equal?(adj2.adjusted_quantity, Decimal.new("100"))
      assert Decimal.equal?(adj3.adjusted_quantity, Decimal.new("150"))
    end

    test "preserves FIFO ordering in batch apply" do
      transactions = [
        %{id: "tx1", quantity: Decimal.new("100"), price: Decimal.new("200.00"), date: ~D[2024-01-01]},
        %{id: "tx2", quantity: Decimal.new("50"), price: Decimal.new("210.00"), date: ~D[2024-02-01]},
        %{id: "tx3", quantity: Decimal.new("75"), price: Decimal.new("190.00"), date: ~D[2024-03-01]}
      ]

      corporate_action = %{
        id: "ca1",
        split_ratio_from: Decimal.new("1"),
        split_ratio_to: Decimal.new("2"),
        description: "2:1 stock split"
      }

      results = StockSplitCalculator.batch_apply(transactions, corporate_action)

      assert {:ok, adjustments} = results

      # Verify FIFO ordering is preserved
      assert Enum.at(adjustments, 0).fifo_lot_order == 1
      assert Enum.at(adjustments, 1).fifo_lot_order == 2
      assert Enum.at(adjustments, 2).fifo_lot_order == 3
    end
  end
end
