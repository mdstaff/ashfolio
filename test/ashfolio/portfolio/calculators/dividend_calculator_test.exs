defmodule Ashfolio.Portfolio.Calculators.DividendCalculatorTest do
  use Ashfolio.DataCase, async: true

  alias Ashfolio.Portfolio.Calculators.DividendCalculator

  @moduletag :calculators
  @moduletag :unit

  describe "calculate_dividend_payment/3" do
    test "calculates regular cash dividend correctly" do
      shares_owned = Decimal.new("100")
      dividend_per_share = Decimal.new("0.50")
      
      result = DividendCalculator.calculate_dividend_payment(
        shares_owned,
        dividend_per_share
      )

      assert {:ok, payment} = result
      assert Decimal.equal?(payment.total_dividend, Decimal.new("50.00"))
      assert payment.shares_eligible == shares_owned
      assert payment.dividend_per_share == dividend_per_share
    end

    test "handles fractional shares in dividend calculation" do
      shares_owned = Decimal.new("123.45")
      dividend_per_share = Decimal.new("1.25")
      
      result = DividendCalculator.calculate_dividend_payment(
        shares_owned,
        dividend_per_share
      )

      assert {:ok, payment} = result
      # 123.45 * 1.25 = 154.3125
      assert Decimal.equal?(payment.total_dividend, Decimal.new("154.3125"))
    end

    test "rounds to penny for dividend payments" do
      shares_owned = Decimal.new("100")
      dividend_per_share = Decimal.new("0.333")
      
      result = DividendCalculator.calculate_dividend_payment(
        shares_owned,
        dividend_per_share,
        round_to_penny: true
      )

      assert {:ok, payment} = result
      # 100 * 0.333 = 33.30 (rounded from 33.3)
      assert Decimal.equal?(payment.total_dividend, Decimal.new("33.30"))
    end

    test "returns error for negative shares" do
      shares_owned = Decimal.new("-100")
      dividend_per_share = Decimal.new("0.50")
      
      result = DividendCalculator.calculate_dividend_payment(
        shares_owned,
        dividend_per_share
      )

      assert {:error, reason} = result
      assert reason =~ "Shares must be positive"
    end

    test "returns error for negative dividend" do
      shares_owned = Decimal.new("100")
      dividend_per_share = Decimal.new("-0.50")
      
      result = DividendCalculator.calculate_dividend_payment(
        shares_owned,
        dividend_per_share
      )

      assert {:error, reason} = result
      assert reason =~ "Dividend per share must be positive"
    end

    test "handles zero dividend correctly" do
      shares_owned = Decimal.new("100")
      dividend_per_share = Decimal.new("0")
      
      result = DividendCalculator.calculate_dividend_payment(
        shares_owned,
        dividend_per_share
      )

      assert {:ok, payment} = result
      assert Decimal.equal?(payment.total_dividend, Decimal.new("0"))
    end
  end

  describe "classify_dividend_tax_status/2" do
    test "classifies qualified dividend" do
      dividend_attrs = %{
        qualified_dividend: true,
        pay_date: ~D[2024-06-15],
        ex_date: ~D[2024-06-01]
      }
      
      holding_period_days = 90 # Held for 90 days
      
      status = DividendCalculator.classify_dividend_tax_status(
        dividend_attrs,
        holding_period_days
      )
      
      assert status == :qualified
    end

    test "classifies ordinary dividend when not qualified" do
      dividend_attrs = %{
        qualified_dividend: false,
        pay_date: ~D[2024-06-15],
        ex_date: ~D[2024-06-01]
      }
      
      holding_period_days = 90
      
      status = DividendCalculator.classify_dividend_tax_status(
        dividend_attrs,
        holding_period_days
      )
      
      assert status == :ordinary
    end

    test "classifies ordinary dividend when holding period too short" do
      dividend_attrs = %{
        qualified_dividend: true,
        pay_date: ~D[2024-06-15],
        ex_date: ~D[2024-06-01]
      }
      
      holding_period_days = 30 # Less than 60 days required
      
      status = DividendCalculator.classify_dividend_tax_status(
        dividend_attrs,
        holding_period_days
      )
      
      assert status == :ordinary
    end
  end

  describe "apply_to_position/2" do
    test "creates dividend adjustment for position" do
      position = %{
        transaction_id: Ecto.UUID.generate(),
        quantity: Decimal.new("100"),
        purchase_date: ~D[2024-01-01]
      }
      
      corporate_action = %{
        id: Ecto.UUID.generate(),
        dividend_amount: Decimal.new("0.75"),
        dividend_currency: "USD",
        qualified_dividend: true,
        ex_date: ~D[2024-06-01],
        pay_date: ~D[2024-06-15],
        description: "$0.75 quarterly dividend"
      }
      
      result = DividendCalculator.apply_to_position(position, corporate_action)
      
      assert {:ok, adjustment_attrs} = result
      assert adjustment_attrs.transaction_id == position.transaction_id
      assert adjustment_attrs.corporate_action_id == corporate_action.id
      assert adjustment_attrs.adjustment_type == :cash_receipt
      assert adjustment_attrs.reason =~ "quarterly dividend"
      assert Decimal.equal?(adjustment_attrs.dividend_per_share, Decimal.new("0.75"))
      assert Decimal.equal?(adjustment_attrs.shares_eligible, Decimal.new("100"))
      assert Decimal.equal?(adjustment_attrs.total_dividend, Decimal.new("75.00"))
      assert adjustment_attrs.dividend_tax_status == :qualified
    end
  end

  describe "batch_apply_dividends/2" do
    test "applies dividends to multiple positions" do
      positions = [
        %{
          transaction_id: "tx1",
          quantity: Decimal.new("100"),
          purchase_date: ~D[2024-01-01]
        },
        %{
          transaction_id: "tx2",
          quantity: Decimal.new("50"),
          purchase_date: ~D[2024-02-01]
        },
        %{
          transaction_id: "tx3",
          quantity: Decimal.new("25.5"),
          purchase_date: ~D[2024-03-01]
        }
      ]
      
      corporate_action = %{
        id: "ca1",
        dividend_amount: Decimal.new("1.00"),
        dividend_currency: "USD",
        qualified_dividend: true,
        ex_date: ~D[2024-06-01],
        pay_date: ~D[2024-06-15],
        description: "$1.00 quarterly dividend"
      }
      
      result = DividendCalculator.batch_apply_dividends(positions, corporate_action)
      
      assert {:ok, adjustments} = result
      assert length(adjustments) == 3
      
      [adj1, adj2, adj3] = adjustments
      assert Decimal.equal?(adj1.total_dividend, Decimal.new("100.00"))
      assert Decimal.equal?(adj2.total_dividend, Decimal.new("50.00"))
      assert Decimal.equal?(adj3.total_dividend, Decimal.new("25.50"))
    end

    test "preserves FIFO ordering in dividend batch" do
      positions = [
        %{
          transaction_id: "tx1",
          quantity: Decimal.new("100"),
          purchase_date: ~D[2024-03-01]
        },
        %{
          transaction_id: "tx2", 
          quantity: Decimal.new("50"),
          purchase_date: ~D[2024-01-01]
        },
        %{
          transaction_id: "tx3",
          quantity: Decimal.new("75"),
          purchase_date: ~D[2024-02-01]
        }
      ]
      
      corporate_action = %{
        id: "ca1",
        dividend_amount: Decimal.new("0.50"),
        dividend_currency: "USD",
        qualified_dividend: true,
        ex_date: ~D[2024-06-01],
        pay_date: ~D[2024-06-15],
        description: "Dividend"
      }
      
      result = DividendCalculator.batch_apply_dividends(positions, corporate_action)
      
      assert {:ok, adjustments} = result
      
      # Should be sorted by purchase date (FIFO)
      sorted_adjustments = Enum.sort_by(adjustments, & &1.fifo_lot_order)
      
      assert sorted_adjustments |> Enum.at(0) |> Map.get(:transaction_id) == "tx2" # Earliest
      assert sorted_adjustments |> Enum.at(1) |> Map.get(:transaction_id) == "tx3" # Middle
      assert sorted_adjustments |> Enum.at(2) |> Map.get(:transaction_id) == "tx1" # Latest
    end
  end

  describe "calculate_tax_withholding/3" do
    test "calculates standard qualified dividend withholding" do
      total_dividend = Decimal.new("100.00")
      tax_status = :qualified
      
      withholding = DividendCalculator.calculate_tax_withholding(
        total_dividend,
        tax_status
      )
      
      # Default 15% for qualified dividends
      assert Decimal.equal?(withholding, Decimal.new("15.00"))
    end

    test "calculates ordinary dividend withholding" do
      total_dividend = Decimal.new("100.00")
      tax_status = :ordinary
      
      withholding = DividendCalculator.calculate_tax_withholding(
        total_dividend,
        tax_status
      )
      
      # Default 24% for ordinary dividends
      assert Decimal.equal?(withholding, Decimal.new("24.00"))
    end

    test "calculates custom withholding rate" do
      total_dividend = Decimal.new("100.00")
      tax_status = :qualified
      custom_rate = Decimal.new("0.20")
      
      withholding = DividendCalculator.calculate_tax_withholding(
        total_dividend,
        tax_status,
        withholding_rate: custom_rate
      )
      
      assert Decimal.equal?(withholding, Decimal.new("20.00"))
    end
  end
end