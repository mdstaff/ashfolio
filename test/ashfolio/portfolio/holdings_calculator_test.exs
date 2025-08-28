defmodule Ashfolio.Portfolio.HoldingsCalculatorTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.Portfolio.Account
  alias Ashfolio.Portfolio.HoldingsCalculator
  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Portfolio.Transaction
  alias Ashfolio.SQLiteHelpers

  @moduletag :calculations
  @moduletag :unit
  @moduletag :fast

  describe "calculate_holding_values/0" do
    test "calculates holding values for multiple positions" do
      # Database-as-user architecture: No user needed
      account = SQLiteHelpers.get_default_account()

      symbol1 =
        SQLiteHelpers.get_or_create_symbol("AAPL", %{
          current_price: Decimal.new("150.00")
        })

      symbol2 =
        SQLiteHelpers.get_or_create_symbol("MSFT", %{
          current_price: Decimal.new("300.00")
        })

      # Create transactions
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol1.id
        })

      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("5"),
          price: Decimal.new("200.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-02],
          account_id: account.id,
          symbol_id: symbol2.id
        })

      # Calculate holding values
      {:ok, holdings} = HoldingsCalculator.calculate_holding_values()

      assert length(holdings) == 2

      # Find AAPL holding
      aapl_holding = Enum.find(holdings, fn h -> h.symbol == "AAPL" end)
      assert aapl_holding
      assert Decimal.equal?(aapl_holding.quantity, Decimal.new("10"))
      # 10 * $150
      assert Decimal.equal?(aapl_holding.current_value, Decimal.new("1500.00"))
      assert Decimal.equal?(aapl_holding.cost_basis, Decimal.new("1000.00"))
      # $1500 - $1000
      assert Decimal.equal?(aapl_holding.unrealized_pnl, Decimal.new("500.00"))
      # 50% gain
      assert Decimal.equal?(aapl_holding.unrealized_pnl_pct, Decimal.new("50.0"))

      # Find MSFT holding
      msft_holding = Enum.find(holdings, fn h -> h.symbol == "MSFT" end)
      assert msft_holding
      assert Decimal.equal?(msft_holding.quantity, Decimal.new("5"))
      # 5 * $300
      assert Decimal.equal?(msft_holding.current_value, Decimal.new("1500.00"))
      assert Decimal.equal?(msft_holding.cost_basis, Decimal.new("1000.00"))
      # $1500 - $1000
      assert Decimal.equal?(msft_holding.unrealized_pnl, Decimal.new("500.00"))
      # 50% gain
      assert Decimal.equal?(msft_holding.unrealized_pnl_pct, Decimal.new("50.0"))
    end

    test "filters out positions with zero quantity" do
      # Database-as-user architecture: No user needed
      account = SQLiteHelpers.get_default_account()

      symbol =
        SQLiteHelpers.get_or_create_symbol("AAPL", %{
          current_price: Decimal.new("150.00")
        })

      # Buy and then sell all shares
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, _} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("-10"),
          price: Decimal.new("150.00"),
          total_amount: Decimal.new("1500.00"),
          date: ~D[2024-01-02],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, holdings} = HoldingsCalculator.calculate_holding_values()

      # Should have no holdings since quantity is zero
      assert Enum.empty?(holdings)
    end

    test "returns empty list for empty portfolio" do
      # Database-as-user architecture: test empty portfolio
      {:ok, holdings} = HoldingsCalculator.calculate_holding_values()

      assert holdings == []
    end
  end

  describe "calculate_cost_basis/2" do
    test "calculates cost basis for single buy transaction" do
      # Database-as-user architecture: No user needed
      account = SQLiteHelpers.get_default_account()

      symbol = SQLiteHelpers.get_or_create_symbol("SINGLE", %{})

      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, cost_basis} = HoldingsCalculator.calculate_cost_basis(symbol.id)

      assert Decimal.equal?(cost_basis.quantity, Decimal.new("10"))
      assert Decimal.equal?(cost_basis.total_cost, Decimal.new("1000.00"))
      assert Decimal.equal?(cost_basis.average_cost, Decimal.new("100.00"))
    end

    test "calculates cost basis for multiple buy transactions" do
      # Database-as-user architecture: No user needed
      account = SQLiteHelpers.get_default_account()

      symbol = SQLiteHelpers.get_or_create_symbol("MULTIPLE", %{})

      # First buy
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Second buy at different price
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("5"),
          price: Decimal.new("120.00"),
          total_amount: Decimal.new("600.00"),
          date: ~D[2024-01-02],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, cost_basis} = HoldingsCalculator.calculate_cost_basis(symbol.id)

      assert Decimal.equal?(cost_basis.quantity, Decimal.new("15"))
      # $1000 + $600
      assert Decimal.equal?(cost_basis.total_cost, Decimal.new("1600.00"))
      # Average cost: $1600 / 15 shares = $106.67 (rounded)
      expected_avg = Decimal.div(Decimal.new("1600.00"), Decimal.new("15"))
      assert Decimal.equal?(cost_basis.average_cost, expected_avg)
    end

    test "handles buy and sell transactions" do
      # Database-as-user architecture: No user needed
      account = SQLiteHelpers.get_default_account()

      symbol = SQLiteHelpers.get_or_create_symbol("BUYSELL", %{})

      # Buy 20 shares
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("20"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("2000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Sell 5 shares
      {:ok, _} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("-5"),
          price: Decimal.new("120.00"),
          total_amount: Decimal.new("600.00"),
          date: ~D[2024-01-02],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, cost_basis} = HoldingsCalculator.calculate_cost_basis(symbol.id)

      # 20 - 5
      assert Decimal.equal?(cost_basis.quantity, Decimal.new("15"))
      # Cost basis should be reduced proportionally: $2000 - ($2000 * 5/20) = $2000 - $500 = $1500
      assert Decimal.equal?(cost_basis.total_cost, Decimal.new("1500.00"))
      # Average cost: $1500 / 15 = $100
      assert Decimal.equal?(cost_basis.average_cost, Decimal.new("100.00"))
    end
  end

  describe "calculate_holding_pnl/2" do
    test "calculates profit and loss for a holding" do
      # Database-as-user architecture: No user needed
      account = SQLiteHelpers.get_default_account()

      symbol =
        SQLiteHelpers.get_or_create_symbol("PNL", %{
          current_price: Decimal.new("150.00")
        })

      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, pnl} = HoldingsCalculator.calculate_holding_pnl(symbol.id)

      assert pnl.symbol == "PNL"
      assert Decimal.equal?(pnl.quantity, Decimal.new("10"))
      assert Decimal.equal?(pnl.current_price, Decimal.new("150.00"))
      # 10 * $150
      assert Decimal.equal?(pnl.current_value, Decimal.new("1500.00"))
      assert Decimal.equal?(pnl.cost_basis, Decimal.new("1000.00"))
      assert Decimal.equal?(pnl.average_cost, Decimal.new("100.00"))
      # $1500 - $1000
      assert Decimal.equal?(pnl.unrealized_pnl, Decimal.new("500.00"))
    end

    test "handles holdings with no current price" do
      # Database-as-user architecture: No user needed
      {:ok, account} = Account.create(%{name: "Test Account"})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "NOPRICE",
          name: "No Price Corp.",
          asset_class: :stock,
          data_source: :yahoo_finance
          # No current_price set
        })

      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, pnl} = HoldingsCalculator.calculate_holding_pnl(symbol.id)

      assert pnl.symbol == "NOPRICE"
      assert pnl.current_price == nil
      # No price = $0 value
      assert Decimal.equal?(pnl.current_value, Decimal.new("0"))
      assert Decimal.equal?(pnl.cost_basis, Decimal.new("1000.00"))
      # $0 - $1000
      assert Decimal.equal?(pnl.unrealized_pnl, Decimal.new("-1000.00"))
    end
  end

  describe "aggregate_portfolio_value/1" do
    test "aggregates total portfolio value from all holdings" do
      # Database-as-user architecture: No user needed
      account = SQLiteHelpers.get_default_account()

      symbol1 =
        SQLiteHelpers.get_or_create_symbol("AAPL", %{
          current_price: Decimal.new("150.00")
        })

      symbol2 =
        SQLiteHelpers.get_or_create_symbol("MSFT", %{
          current_price: Decimal.new("300.00")
        })

      # Create transactions
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol1.id
        })

      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("5"),
          price: Decimal.new("200.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-02],
          account_id: account.id,
          symbol_id: symbol2.id
        })

      {:ok, total_value} = HoldingsCalculator.aggregate_portfolio_value()

      # Expected: 10 * $150 + 5 * $300 = $1500 + $1500 = $3000
      expected_value = Decimal.new("3000.00")
      assert Decimal.equal?(total_value, expected_value)
    end

    test "returns zero for empty portfolio" do
      # Database-as-user architecture: test empty portfolio
      {:ok, total_value} = HoldingsCalculator.aggregate_portfolio_value()

      assert Decimal.equal?(total_value, Decimal.new(0))
    end
  end

  describe "get_holdings_summary/1" do
    test "provides comprehensive holdings summary" do
      # Database-as-user architecture: No user needed
      account = SQLiteHelpers.get_default_account()

      symbol =
        SQLiteHelpers.get_or_create_symbol("SUMMARY", %{
          current_price: Decimal.new("150.00")
        })

      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, summary} = HoldingsCalculator.get_holdings_summary()

      assert summary.holdings_count == 1
      # 10 * $150
      assert Decimal.equal?(summary.total_value, Decimal.new("1500.00"))
      assert Decimal.equal?(summary.total_cost_basis, Decimal.new("1000.00"))
      # $1500 - $1000
      assert Decimal.equal?(summary.total_pnl, Decimal.new("500.00"))
      # 50% gain
      assert Decimal.equal?(summary.total_pnl_pct, Decimal.new("50.0"))

      # Check individual holding in summary
      holding = List.first(summary.holdings)
      assert holding.symbol == "SUMMARY"
      assert Decimal.equal?(holding.quantity, Decimal.new("10"))
      assert Decimal.equal?(holding.current_value, Decimal.new("1500.00"))
    end

    test "handles empty portfolio" do
      # Database-as-user architecture: test empty portfolio
      {:ok, summary} = HoldingsCalculator.get_holdings_summary()

      assert summary.holdings_count == 0
      assert summary.holdings == []
      assert Decimal.equal?(summary.total_value, Decimal.new(0))
      assert Decimal.equal?(summary.total_cost_basis, Decimal.new(0))
      assert Decimal.equal?(summary.total_pnl, Decimal.new(0))
      assert Decimal.equal?(summary.total_pnl_pct, Decimal.new(0))
    end
  end

  describe "error handling" do
    test "handles empty portfolio gracefully" do
      # In database-as-user architecture, test empty portfolio instead of invalid user
      {:ok, holdings} = HoldingsCalculator.calculate_holding_values()
      assert holdings == []

      {:ok, total_value} = HoldingsCalculator.aggregate_portfolio_value()
      assert Decimal.equal?(total_value, Decimal.new(0))

      {:ok, summary} = HoldingsCalculator.get_holdings_summary()
      assert summary.holdings_count == 0
      assert summary.holdings == []
      assert Decimal.equal?(summary.total_value, Decimal.new(0))
    end

    test "handles invalid symbol ID in cost basis calculation" do
      # Database-as-user architecture: No user needed
      invalid_symbol_id = Ecto.UUID.generate()

      {:ok, cost_basis} = HoldingsCalculator.calculate_cost_basis(invalid_symbol_id)

      assert Decimal.equal?(cost_basis.quantity, Decimal.new(0))
      assert Decimal.equal?(cost_basis.total_cost, Decimal.new(0))
      assert Decimal.equal?(cost_basis.average_cost, Decimal.new(0))
    end

    test "handles invalid symbol ID in holding P&L calculation" do
      # Database-as-user architecture: No user needed
      invalid_symbol_id = Ecto.UUID.generate()

      # Invalid symbol ID should return an error
      {:error, _reason} = HoldingsCalculator.calculate_holding_pnl(invalid_symbol_id)
    end
  end
end
