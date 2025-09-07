defmodule Ashfolio.TaxPlanning.CapitalGainsCalculatorTest do
  use ExUnit.Case, async: true

  import Mox

  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Portfolio.Transaction
  alias Ashfolio.TaxPlanning.CapitalGainsCalculator

  setup :verify_on_exit!
  setup :set_mox_from_context

  describe "calculate_realized_gains/3" do
    test "calculates FIFO cost basis for single buy/sell transaction" do
      symbol_id = "test-symbol-uuid"
      tax_year = 2024

      # Mock symbol lookup
      expect(Ashfolio.ContextMock, :get, fn Symbol, ^symbol_id ->
        {:ok, %{id: symbol_id, symbol: "AAPL", name: "Apple Inc."}}
      end)

      # Mock transaction lookup
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_symbol, args ->
        assert args[:symbol_id] == symbol_id

        {:ok,
         [
           %{
             id: "buy-1",
             type: :buy,
             symbol_id: symbol_id,
             date: ~D[2024-01-15],
             quantity: Decimal.new("100"),
             price: Decimal.new("150.00"),
             total_amount: Decimal.new("15000.00")
           },
           %{
             id: "sell-1",
             type: :sell,
             symbol_id: symbol_id,
             date: ~D[2024-06-15],
             quantity: Decimal.new("-50"),
             price: Decimal.new("160.00"),
             total_amount: Decimal.new("8000.00")
           }
         ]}
      end)

      assert {:ok, analysis} = CapitalGainsCalculator.calculate_realized_gains(symbol_id, tax_year)

      assert analysis.symbol == "AAPL"
      assert analysis.symbol_id == symbol_id
      # $8000 - $7500
      assert Decimal.equal?(analysis.total_realized_gains, Decimal.new("500.00"))
      # > 1 year holding
      assert Decimal.equal?(analysis.long_term_gains, Decimal.new("500.00"))
      assert Decimal.equal?(analysis.short_term_gains, Decimal.new("0.00"))
      assert analysis.transactions_processed == 1
    end

    test "handles multiple buy/sell transactions with FIFO ordering" do
      symbol_id = "test-symbol-uuid"
      tax_year = 2024

      # Mock symbol lookup
      expect(Ashfolio.ContextMock, :get, fn Symbol, ^symbol_id ->
        {:ok, %{id: symbol_id, symbol: "MSFT", name: "Microsoft Corp."}}
      end)

      # Mock transactions: two buys, one sell using FIFO
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_symbol, args ->
        assert args[:symbol_id] == symbol_id

        {:ok,
         [
           %{
             id: "buy-1",
             type: :buy,
             symbol_id: symbol_id,
             date: ~D[2023-01-15],
             quantity: Decimal.new("100"),
             price: Decimal.new("200.00"),
             total_amount: Decimal.new("20000.00")
           },
           %{
             id: "buy-2",
             type: :buy,
             symbol_id: symbol_id,
             date: ~D[2023-06-15],
             quantity: Decimal.new("100"),
             price: Decimal.new("250.00"),
             total_amount: Decimal.new("25000.00")
           },
           %{
             id: "sell-1",
             type: :sell,
             symbol_id: symbol_id,
             date: ~D[2024-03-15],
             quantity: Decimal.new("-150"),
             price: Decimal.new("280.00"),
             total_amount: Decimal.new("42000.00")
           }
         ]}
      end)

      assert {:ok, analysis} = CapitalGainsCalculator.calculate_realized_gains(symbol_id, tax_year)

      assert analysis.symbol == "MSFT"
      # FIFO: Sells first 100 shares at $200 cost, then 50 shares at $250 cost
      # Total cost basis: $20,000 + $12,500 = $32,500
      # Proceeds: $42,000
      # Gain: $9,500
      assert Decimal.equal?(analysis.total_realized_gains, Decimal.new("9500.00"))
      assert analysis.transactions_processed == 1
    end

    test "differentiates between short-term and long-term gains" do
      symbol_id = "test-symbol-uuid"
      tax_year = 2024

      # Mock symbol lookup
      expect(Ashfolio.ContextMock, :get, fn Symbol, ^symbol_id ->
        {:ok, %{id: symbol_id, symbol: "TSLA", name: "Tesla Inc."}}
      end)

      # Mock transactions with different holding periods
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_symbol, args ->
        assert args[:symbol_id] == symbol_id

        {:ok,
         [
           # Long-term position (> 1 year)
           %{
             id: "buy-1",
             type: :buy,
             symbol_id: symbol_id,
             date: ~D[2022-01-15],
             quantity: Decimal.new("50"),
             price: Decimal.new("800.00"),
             total_amount: Decimal.new("40000.00")
           },
           # Short-term position (< 1 year)
           %{
             id: "buy-2",
             type: :buy,
             symbol_id: symbol_id,
             date: ~D[2024-01-15],
             quantity: Decimal.new("50"),
             price: Decimal.new("900.00"),
             total_amount: Decimal.new("45000.00")
           },
           # Sell using FIFO (long-term first)
           %{
             id: "sell-1",
             type: :sell,
             symbol_id: symbol_id,
             date: ~D[2024-03-15],
             quantity: Decimal.new("-75"),
             price: Decimal.new("850.00"),
             total_amount: Decimal.new("63750.00")
           }
         ]}
      end)

      assert {:ok, analysis} = CapitalGainsCalculator.calculate_realized_gains(symbol_id, tax_year)

      # Should have both long-term and short-term components
      assert Decimal.compare(analysis.long_term_gains, Decimal.new("0")) == :gt
      assert Decimal.compare(analysis.short_term_gains, Decimal.new("0")) == :gt
    end

    test "handles losses correctly" do
      symbol_id = "test-symbol-uuid"
      tax_year = 2024

      # Mock symbol lookup
      expect(Ashfolio.ContextMock, :get, fn Symbol, ^symbol_id ->
        {:ok, %{id: symbol_id, symbol: "LOSS", name: "Loss Stock"}}
      end)

      # Mock loss transaction
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_symbol, args ->
        assert args[:symbol_id] == symbol_id

        {:ok,
         [
           %{
             id: "buy-1",
             type: :buy,
             symbol_id: symbol_id,
             date: ~D[2023-01-15],
             quantity: Decimal.new("100"),
             price: Decimal.new("100.00"),
             total_amount: Decimal.new("10000.00")
           },
           %{
             id: "sell-1",
             type: :sell,
             symbol_id: symbol_id,
             date: ~D[2024-06-15],
             quantity: Decimal.new("-100"),
             price: Decimal.new("80.00"),
             total_amount: Decimal.new("8000.00")
           }
         ]}
      end)

      assert {:ok, analysis} = CapitalGainsCalculator.calculate_realized_gains(symbol_id, tax_year)

      # Loss of $2,000
      assert Decimal.equal?(analysis.total_realized_gains, Decimal.new("-2000.00"))
      # > 1 year
      assert Decimal.equal?(analysis.long_term_gains, Decimal.new("-2000.00"))
      assert Decimal.equal?(analysis.short_term_gains, Decimal.new("0.00"))
    end

    test "validates input parameters" do
      assert {:error, :no_transactions} = CapitalGainsCalculator.calculate_realized_gains("empty-symbol", 2024)

      # Test invalid symbol
      expect(Ashfolio.ContextMock, :get, fn Symbol, "invalid-symbol" ->
        {:error, :not_found}
      end)

      assert {:error, :not_found} = CapitalGainsCalculator.calculate_realized_gains("invalid-symbol", 2024)
    end

    test "filters transactions by tax year correctly" do
      symbol_id = "test-symbol-uuid"
      tax_year = 2023

      # Mock symbol lookup
      expect(Ashfolio.ContextMock, :get, fn Symbol, ^symbol_id ->
        {:ok, %{id: symbol_id, symbol: "YEAR", name: "Year Filter Test"}}
      end)

      # Mock transactions spanning multiple years
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_symbol, args ->
        assert args[:symbol_id] == symbol_id

        {:ok,
         [
           %{
             id: "buy-1",
             type: :buy,
             symbol_id: symbol_id,
             date: ~D[2022-01-15],
             quantity: Decimal.new("100"),
             price: Decimal.new("100.00"),
             total_amount: Decimal.new("10000.00")
           },
           %{
             id: "sell-1",
             type: :sell,
             symbol_id: symbol_id,
             date: ~D[2023-06-15],
             quantity: Decimal.new("-50"),
             price: Decimal.new("120.00"),
             total_amount: Decimal.new("6000.00")
           },
           %{
             id: "sell-2",
             type: :sell,
             symbol_id: symbol_id,
             date: ~D[2024-06-15],
             quantity: Decimal.new("-50"),
             price: Decimal.new("130.00"),
             total_amount: Decimal.new("6500.00")
           }
         ]}
      end)

      assert {:ok, analysis} = CapitalGainsCalculator.calculate_realized_gains(symbol_id, tax_year)

      # Should only include 2023 sale
      assert analysis.transactions_processed == 1
      # Gain from first sale: $6000 - $5000 = $1000
      assert Decimal.equal?(analysis.total_realized_gains, Decimal.new("1000.00"))
    end
  end

  describe "calculate_unrealized_gains/2" do
    test "calculates unrealized gains for current holdings" do
      # This test would require integration with Portfolio.Calculator
      # For now, test the basic structure
      assert {:ok, analysis} = CapitalGainsCalculator.calculate_unrealized_gains()

      assert Map.has_key?(analysis, :total_unrealized_gains)
      assert Map.has_key?(analysis, :positions)
    end

    test "handles empty holdings" do
      assert {:error, :no_holdings} = CapitalGainsCalculator.calculate_unrealized_gains("empty-account")
    end
  end

  describe "generate_tax_lot_report/2" do
    test "generates basic tax lot report structure" do
      assert {:ok, report} = CapitalGainsCalculator.generate_tax_lot_report()

      assert Map.has_key?(report, :tax_lots)
      assert Map.has_key?(report, :summary)
      assert is_list(report.tax_lots)
    end

    test "handles empty account" do
      assert {:error, :no_holdings} = CapitalGainsCalculator.generate_tax_lot_report("empty-account")
    end
  end

  describe "calculate_annual_summary/2" do
    test "calculates annual summary for tax year" do
      tax_year = 2024

      # Mock date range transactions
      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, args ->
        assert args[:start_date] == Date.new!(tax_year, 1, 1)
        assert args[:end_date] == Date.new!(tax_year, 12, 31)

        {:ok,
         [
           %{id: "sell-1", type: :sell, date: ~D[2024-03-15], total_amount: Decimal.new("5000.00")},
           %{id: "sell-2", type: :sell, date: ~D[2024-08-15], total_amount: Decimal.new("3000.00")}
         ]}
      end)

      assert {:ok, summary} = CapitalGainsCalculator.calculate_annual_summary(tax_year)

      assert summary.tax_year == tax_year
      assert Decimal.equal?(summary.total_proceeds, Decimal.new("8000.00"))
      assert summary.transactions_analyzed == 2
    end

    test "filters by account when provided" do
      tax_year = 2024
      account_id = "test-account-uuid"

      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, args ->
        # Would filter by account in real implementation
        {:ok, []}
      end)

      assert {:ok, summary} = CapitalGainsCalculator.calculate_annual_summary(tax_year, account_id)
      assert summary.tax_year == tax_year
    end

    test "handles year with no transactions" do
      tax_year = 2020

      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_date_range, _args ->
        {:ok, []}
      end)

      assert {:ok, summary} = CapitalGainsCalculator.calculate_annual_summary(tax_year)

      assert summary.tax_year == tax_year
      assert Decimal.equal?(summary.total_proceeds, Decimal.new("0.00"))
      assert summary.transactions_analyzed == 0
    end
  end

  describe "FIFO cost basis calculation edge cases" do
    test "handles partial lot usage correctly" do
      # This tests the internal FIFO allocation logic
      # Implementation would test specific scenarios like:
      # - Selling partial quantities from multiple lots
      # - Handling remainder quantities correctly
      # - Proper cost basis allocation across lots

      # For MVP, we verify the structure is in place
      symbol_id = "partial-test"
      tax_year = 2024

      expect(Ashfolio.ContextMock, :get, fn Symbol, ^symbol_id ->
        {:ok, %{id: symbol_id, symbol: "PARTIAL", name: "Partial Lot Test"}}
      end)

      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_symbol, _args ->
        {:ok,
         [
           %{
             id: "buy-1",
             type: :buy,
             symbol_id: symbol_id,
             date: ~D[2023-01-15],
             quantity: Decimal.new("100"),
             price: Decimal.new("100.00"),
             total_amount: Decimal.new("10000.00")
           },
           %{
             id: "sell-1",
             type: :sell,
             symbol_id: symbol_id,
             date: ~D[2024-06-15],
             quantity: Decimal.new("-25"),
             price: Decimal.new("120.00"),
             total_amount: Decimal.new("3000.00")
           }
         ]}
      end)

      assert {:ok, analysis} = CapitalGainsCalculator.calculate_realized_gains(symbol_id, tax_year)

      # Should handle partial sale correctly
      assert analysis.transactions_processed == 1
      # Gain: $3000 - $2500 = $500
      assert Decimal.equal?(analysis.total_realized_gains, Decimal.new("500.00"))
    end

    test "handles wash sale scenarios" do
      # Test structure for wash sale detection
      # Real implementation would check for substantially identical securities
      # within 30-day windows

      symbol_id = "wash-test"
      tax_year = 2024

      expect(Ashfolio.ContextMock, :get, fn Symbol, ^symbol_id ->
        {:ok, %{id: symbol_id, symbol: "WASH", name: "Wash Sale Test"}}
      end)

      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_symbol, _args ->
        {:ok,
         [
           %{
             id: "buy-1",
             type: :buy,
             symbol_id: symbol_id,
             date: ~D[2024-01-15],
             quantity: Decimal.new("100"),
             price: Decimal.new("100.00"),
             total_amount: Decimal.new("10000.00")
           },
           %{
             id: "sell-1",
             type: :sell,
             symbol_id: symbol_id,
             date: ~D[2024-02-15],
             quantity: Decimal.new("-100"),
             price: Decimal.new("80.00"),
             total_amount: Decimal.new("8000.00")
           },
           %{
             id: "buy-2",
             type: :buy,
             symbol_id: symbol_id,
             date: ~D[2024-03-01],
             quantity: Decimal.new("100"),
             price: Decimal.new("85.00"),
             total_amount: Decimal.new("8500.00")
           }
         ]}
      end)

      assert {:ok, analysis} = CapitalGainsCalculator.calculate_realized_gains(symbol_id, tax_year)

      # For now, just verify structure - wash sale logic would be more complex
      assert analysis.transactions_processed >= 1
    end
  end

  describe "integration with existing Portfolio infrastructure" do
    test "integrates with Transaction.by_symbol/1" do
      # Verify proper integration with Ash resources
      symbol_id = "integration-test"

      expect(Ashfolio.ContextMock, :get, fn Symbol, ^symbol_id ->
        {:ok, %{id: symbol_id, symbol: "INTEG", name: "Integration Test"}}
      end)

      expect(Ashfolio.ContextMock, :read, fn Transaction, :by_symbol, args ->
        assert args[:symbol_id] == symbol_id
        {:ok, []}
      end)

      assert {:error, :no_transactions} = CapitalGainsCalculator.calculate_realized_gains(symbol_id, 2024)
    end

    test "integrates with Symbol.get_by_id/1" do
      symbol_id = "symbol-integration-test"

      expect(Ashfolio.ContextMock, :get, fn Symbol, ^symbol_id ->
        {:error, :not_found}
      end)

      assert {:error, :not_found} = CapitalGainsCalculator.calculate_realized_gains(symbol_id, 2024)
    end
  end
end
