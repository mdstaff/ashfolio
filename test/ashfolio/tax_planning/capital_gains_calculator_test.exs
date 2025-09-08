defmodule Ashfolio.TaxPlanning.CapitalGainsCalculatorTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Portfolio.Transaction
  alias Ashfolio.SQLiteHelpers
  alias Ashfolio.TaxPlanning.CapitalGainsCalculator

  @moduletag :ash_resources
  @moduletag :unit
  @moduletag :calculations
  @moduletag :fast

  describe "calculate_realized_gains/3" do
    setup do
      account =
        SQLiteHelpers.get_or_create_account(%{
          name: "Tax Test Account",
          platform: "Test Platform"
        })

      symbol = SQLiteHelpers.get_common_symbol("AAPL")

      %{account: account, symbol: symbol}
    end

    test "calculates FIFO cost basis for single buy/sell transaction", %{account: account, symbol: symbol} do
      tax_year = 2024

      # Create buy transaction
      {:ok, _buy_txn} =
        Transaction.create(%{
          type: :buy,
          symbol_id: symbol.id,
          account_id: account.id,
          date: ~D[2024-01-15],
          quantity: Decimal.new("100"),
          price: Decimal.new("150.00"),
          total_amount: Decimal.new("15000.00"),
          fee: Decimal.new("0")
        })

      # Create sell transaction
      {:ok, _sell_txn} =
        Transaction.create(%{
          type: :sell,
          symbol_id: symbol.id,
          account_id: account.id,
          date: ~D[2024-06-15],
          quantity: Decimal.new("-50"),
          price: Decimal.new("160.00"),
          total_amount: Decimal.new("8000.00"),
          fee: Decimal.new("0")
        })

      assert {:ok, analysis} = CapitalGainsCalculator.calculate_realized_gains(symbol.id, tax_year)

      assert analysis.symbol == "AAPL"
      assert analysis.symbol_id == symbol.id
      # $8000 - $7500 (FIFO: sell half of the 100 shares at $150 cost basis)
      assert Decimal.equal?(analysis.total_realized_gains, Decimal.new("500.00"))
      # < 1 year holding (Jan to June 2024)
      assert Decimal.equal?(analysis.short_term_gains, Decimal.new("500.00"))
      assert Decimal.equal?(analysis.long_term_gains, Decimal.new("0.00"))
      assert analysis.transactions_processed == 1
    end

    test "handles multiple buy/sell transactions with FIFO ordering", %{account: account} do
      tax_year = 2024

      # Create a separate symbol for this test
      {:ok, msft_symbol} =
        Symbol.create(%{
          symbol: "MSFT",
          name: "Microsoft Corp.",
          asset_class: :stock,
          data_source: :manual,
          currency: "USD"
        })

      # Create two buy transactions
      {:ok, _buy1} =
        Transaction.create(%{
          type: :buy,
          symbol_id: msft_symbol.id,
          account_id: account.id,
          date: ~D[2023-01-15],
          quantity: Decimal.new("100"),
          price: Decimal.new("200.00"),
          total_amount: Decimal.new("20000.00"),
          fee: Decimal.new("0")
        })

      {:ok, _buy2} =
        Transaction.create(%{
          type: :buy,
          symbol_id: msft_symbol.id,
          account_id: account.id,
          date: ~D[2023-06-15],
          quantity: Decimal.new("100"),
          price: Decimal.new("250.00"),
          total_amount: Decimal.new("25000.00"),
          fee: Decimal.new("0")
        })

      {:ok, _sell1} =
        Transaction.create(%{
          type: :sell,
          symbol_id: msft_symbol.id,
          account_id: account.id,
          date: ~D[2024-03-15],
          quantity: Decimal.new("-150"),
          price: Decimal.new("280.00"),
          total_amount: Decimal.new("42000.00"),
          fee: Decimal.new("0")
        })

      assert {:ok, analysis} = CapitalGainsCalculator.calculate_realized_gains(msft_symbol.id, tax_year)

      assert analysis.symbol == "MSFT"
      # FIFO: Sells first 100 shares at $200 cost, then 50 shares at $250 cost
      # Total cost basis: $20,000 + $12,500 = $32,500
      # Proceeds: $42,000
      # Gain: $9,500
      assert Decimal.equal?(analysis.total_realized_gains, Decimal.new("9500.00"))
      assert analysis.transactions_processed == 1
    end

    test "differentiates between short-term and long-term gains", %{account: account} do
      tax_year = 2024

      # Create Tesla symbol
      {:ok, tsla_symbol} =
        Symbol.create(%{
          symbol: "TSLA",
          name: "Tesla Inc.",
          asset_class: :stock,
          data_source: :manual,
          currency: "USD"
        })

      # Create long-term position (> 1 year)
      {:ok, _buy1} =
        Transaction.create(%{
          type: :buy,
          symbol_id: tsla_symbol.id,
          account_id: account.id,
          date: ~D[2022-01-15],
          quantity: Decimal.new("50"),
          price: Decimal.new("800.00"),
          total_amount: Decimal.new("40000.00"),
          fee: Decimal.new("0")
        })

      # Create short-term position (< 1 year)
      {:ok, _buy2} =
        Transaction.create(%{
          type: :buy,
          symbol_id: tsla_symbol.id,
          account_id: account.id,
          date: ~D[2024-01-15],
          quantity: Decimal.new("50"),
          price: Decimal.new("900.00"),
          total_amount: Decimal.new("45000.00"),
          fee: Decimal.new("0")
        })

      # Sell using FIFO (long-term first)
      {:ok, _sell1} =
        Transaction.create(%{
          type: :sell,
          symbol_id: tsla_symbol.id,
          account_id: account.id,
          date: ~D[2024-03-15],
          quantity: Decimal.new("-75"),
          price: Decimal.new("850.00"),
          total_amount: Decimal.new("63750.00"),
          fee: Decimal.new("0")
        })

      assert {:ok, analysis} = CapitalGainsCalculator.calculate_realized_gains(tsla_symbol.id, tax_year)

      # Should have both long-term and short-term components
      assert Decimal.compare(analysis.long_term_gains, Decimal.new("0")) == :gt
      assert Decimal.compare(analysis.short_term_gains, Decimal.new("0")) == :gt
    end

    test "handles losses correctly", %{account: account} do
      tax_year = 2024

      # Create symbol for loss test
      {:ok, loss_symbol} =
        Symbol.create(%{
          symbol: "LOSS",
          name: "Loss Stock",
          asset_class: :stock,
          data_source: :manual,
          currency: "USD"
        })

      # Create buy transaction
      {:ok, _buy1} =
        Transaction.create(%{
          type: :buy,
          symbol_id: loss_symbol.id,
          account_id: account.id,
          date: ~D[2023-01-15],
          quantity: Decimal.new("100"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("10000.00"),
          fee: Decimal.new("0")
        })

      # Create loss sell transaction
      {:ok, _sell1} =
        Transaction.create(%{
          type: :sell,
          symbol_id: loss_symbol.id,
          account_id: account.id,
          date: ~D[2024-06-15],
          quantity: Decimal.new("-100"),
          price: Decimal.new("80.00"),
          total_amount: Decimal.new("8000.00"),
          fee: Decimal.new("0")
        })

      assert {:ok, analysis} = CapitalGainsCalculator.calculate_realized_gains(loss_symbol.id, tax_year)

      # Loss of $2,000
      assert Decimal.equal?(analysis.total_realized_gains, Decimal.new("-2000.00"))
      # > 1 year (bought Jan 2023, sold June 2024)
      assert Decimal.equal?(analysis.long_term_gains, Decimal.new("-2000.00"))
      assert Decimal.equal?(analysis.short_term_gains, Decimal.new("0.00"))
    end

    test "validates input parameters" do
      # Test with non-existent symbol
      fake_uuid = Ecto.UUID.generate()
      assert {:error, _} = CapitalGainsCalculator.calculate_realized_gains(fake_uuid, 2024)
    end

    test "filters transactions by tax year correctly", %{account: account} do
      tax_year = 2023

      # Create symbol for year filter test
      {:ok, year_symbol} =
        Symbol.create(%{
          symbol: "YEAR",
          name: "Year Filter Test",
          asset_class: :stock,
          data_source: :manual,
          currency: "USD"
        })

      # Create buy transaction in 2022
      {:ok, _buy1} =
        Transaction.create(%{
          type: :buy,
          symbol_id: year_symbol.id,
          account_id: account.id,
          date: ~D[2022-01-15],
          quantity: Decimal.new("100"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("10000.00"),
          fee: Decimal.new("0")
        })

      # Create sell transaction in 2023 (should be included)
      {:ok, _sell1} =
        Transaction.create(%{
          type: :sell,
          symbol_id: year_symbol.id,
          account_id: account.id,
          date: ~D[2023-06-15],
          quantity: Decimal.new("-50"),
          price: Decimal.new("120.00"),
          total_amount: Decimal.new("6000.00"),
          fee: Decimal.new("0")
        })

      # Create sell transaction in 2024 (should be excluded)
      {:ok, _sell2} =
        Transaction.create(%{
          type: :sell,
          symbol_id: year_symbol.id,
          account_id: account.id,
          date: ~D[2024-06-15],
          quantity: Decimal.new("-50"),
          price: Decimal.new("130.00"),
          total_amount: Decimal.new("6500.00"),
          fee: Decimal.new("0")
        })

      assert {:ok, analysis} = CapitalGainsCalculator.calculate_realized_gains(year_symbol.id, tax_year)

      # Should only include 2023 sale
      assert analysis.transactions_processed == 1
      # Gain from first sale: $6000 - $5000 = $1000
      assert Decimal.equal?(analysis.total_realized_gains, Decimal.new("1000.00"))
    end
  end

  describe "calculate_unrealized_gains/2" do
    test "returns error with stub implementation" do
      # This uses stub implementation that returns :no_holdings error
      assert {:error, :no_holdings} = CapitalGainsCalculator.calculate_unrealized_gains()
    end
  end

  describe "generate_tax_lot_report/2" do
    test "returns error with stub implementation" do
      # This uses stub implementation that returns :no_holdings error
      assert {:error, :no_holdings} = CapitalGainsCalculator.generate_tax_lot_report()
    end
  end

  describe "calculate_annual_summary/2" do
    test "returns error with stub implementation" do
      tax_year = 2024

      # Test with stub implementation that returns :no_transactions error
      assert {:error, :no_transactions} = CapitalGainsCalculator.calculate_annual_summary(tax_year)
    end
  end
end
