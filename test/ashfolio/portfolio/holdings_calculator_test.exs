defmodule Ashfolio.Portfolio.HoldingsCalculatorTest do
  use Ashfolio.DataCase, async: false

  @moduletag :calculations
  @moduletag :unit
  @moduletag :fast

  alias Ashfolio.Portfolio.HoldingsCalculator
  alias Ashfolio.Portfolio.{User, Account, Symbol, Transaction}
  alias Ashfolio.SQLiteHelpers

  # Helper function to create user - use global setup
  defp create_test_user(_attrs \\ %{}) do
    # Use the global user from SQLiteHelpers, ignore custom attrs for consistency
    {:ok, SQLiteHelpers.get_default_user()}
  end

  describe "calculate_holding_values/1" do
    test "calculates holding values for multiple positions" do
      # Create test data
      {:ok, user} = create_test_user()
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Account"})

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
      {:ok, holdings} = HoldingsCalculator.calculate_holding_values(user.id)

      assert length(holdings) == 2

      # Find AAPL holding
      aapl_holding = Enum.find(holdings, fn h -> h.symbol == "AAPL" end)
      assert aapl_holding != nil
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
      assert msft_holding != nil
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
      {:ok, user} = create_test_user()
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Account"})

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

      {:ok, holdings} = HoldingsCalculator.calculate_holding_values(user.id)

      # Should have no holdings since quantity is zero
      assert length(holdings) == 0
    end

    test "returns empty list for user with no holdings" do
      {:ok, user} = User.create(%{name: "Empty User"})

      {:ok, holdings} = HoldingsCalculator.calculate_holding_values(user.id)

      assert holdings == []
    end
  end

  describe "calculate_cost_basis/2" do
    test "calculates cost basis for single buy transaction" do
      {:ok, user} = create_test_user()
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Account"})

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

      {:ok, cost_basis} = HoldingsCalculator.calculate_cost_basis(user.id, symbol.id)

      assert Decimal.equal?(cost_basis.quantity, Decimal.new("10"))
      assert Decimal.equal?(cost_basis.total_cost, Decimal.new("1000.00"))
      assert Decimal.equal?(cost_basis.average_cost, Decimal.new("100.00"))
    end

    test "calculates cost basis for multiple buy transactions" do
      {:ok, user} = create_test_user()
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Account"})

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

      {:ok, cost_basis} = HoldingsCalculator.calculate_cost_basis(user.id, symbol.id)

      assert Decimal.equal?(cost_basis.quantity, Decimal.new("15"))
      # $1000 + $600
      assert Decimal.equal?(cost_basis.total_cost, Decimal.new("1600.00"))
      # Average cost: $1600 / 15 shares = $106.67 (rounded)
      expected_avg = Decimal.div(Decimal.new("1600.00"), Decimal.new("15"))
      assert Decimal.equal?(cost_basis.average_cost, expected_avg)
    end

    test "handles buy and sell transactions" do
      {:ok, user} = create_test_user()
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Account"})

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

      {:ok, cost_basis} = HoldingsCalculator.calculate_cost_basis(user.id, symbol.id)

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
      {:ok, user} = create_test_user()
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Account"})

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

      {:ok, pnl} = HoldingsCalculator.calculate_holding_pnl(user.id, symbol.id)

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
      {:ok, user} = create_test_user()
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

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

      {:ok, pnl} = HoldingsCalculator.calculate_holding_pnl(user.id, symbol.id)

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
      {:ok, user} = create_test_user()
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Account"})

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

      {:ok, total_value} = HoldingsCalculator.aggregate_portfolio_value(user.id)

      # Expected: 10 * $150 + 5 * $300 = $1500 + $1500 = $3000
      expected_value = Decimal.new("3000.00")
      assert Decimal.equal?(total_value, expected_value)
    end

    test "returns zero for user with no holdings" do
      {:ok, user} = User.create(%{name: "Empty User"})

      {:ok, total_value} = HoldingsCalculator.aggregate_portfolio_value(user.id)

      assert Decimal.equal?(total_value, Decimal.new(0))
    end
  end

  describe "get_holdings_summary/1" do
    test "provides comprehensive holdings summary" do
      {:ok, user} = create_test_user()
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Account"})

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

      {:ok, summary} = HoldingsCalculator.get_holdings_summary(user.id)

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
      {:ok, user} = User.create(%{name: "Empty User"})

      {:ok, summary} = HoldingsCalculator.get_holdings_summary(user.id)

      assert summary.holdings_count == 0
      assert summary.holdings == []
      assert Decimal.equal?(summary.total_value, Decimal.new(0))
      assert Decimal.equal?(summary.total_cost_basis, Decimal.new(0))
      assert Decimal.equal?(summary.total_pnl, Decimal.new(0))
      assert Decimal.equal?(summary.total_pnl_pct, Decimal.new(0))
    end

    test "handles multiple holdings with mixed performance" do
      {:ok, user} = create_test_user()
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      # Winner stock
      {:ok, winner} =
        Symbol.create(%{
          symbol: "WINNER",
          name: "Winner Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("200.00")
        })

      # Loser stock
      {:ok, loser} =
        Symbol.create(%{
          symbol: "LOSER",
          name: "Loser Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("50.00")
        })

      # Buy winner at $100 (now $200 = 100% gain)
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: winner.id
        })

      # Buy loser at $100 (now $50 = 50% loss)
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("20"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("2000.00"),
          date: ~D[2024-01-02],
          account_id: account.id,
          symbol_id: loser.id
        })

      {:ok, summary} = HoldingsCalculator.get_holdings_summary(user.id)

      assert summary.holdings_count == 2
      # Total value: 10 * $200 + 20 * $50 = $2000 + $1000 = $3000
      assert Decimal.equal?(summary.total_value, Decimal.new("3000.00"))
      # Total cost: $1000 + $2000 = $3000
      assert Decimal.equal?(summary.total_cost_basis, Decimal.new("3000.00"))
      # Net P&L: $3000 - $3000 = $0
      assert Decimal.equal?(summary.total_pnl, Decimal.new("0.00"))
      # Net percentage: 0%
      assert Decimal.equal?(summary.total_pnl_pct, Decimal.new("0.0"))

      # Verify individual holdings
      winner_holding = Enum.find(summary.holdings, fn h -> h.symbol == "WINNER" end)
      assert winner_holding != nil
      assert Decimal.equal?(winner_holding.unrealized_pnl, Decimal.new("1000.00"))
      assert Decimal.equal?(winner_holding.unrealized_pnl_pct, Decimal.new("100.0"))

      loser_holding = Enum.find(summary.holdings, fn h -> h.symbol == "LOSER" end)
      assert loser_holding != nil
      assert Decimal.equal?(loser_holding.unrealized_pnl, Decimal.new("-1000.00"))
      assert Decimal.equal?(loser_holding.unrealized_pnl_pct, Decimal.new("-50.0"))
    end

    test "handles holdings with zero cost basis" do
      {:ok, user} = User.create(%{name: "Test User", currency: "USD", locale: "en-US"})
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "FREE",
          name: "Free Stock",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("50.00")
        })

      # Buy free stock (promotional, zero cost)
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("0.00"),
          total_amount: Decimal.new("0.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, summary} = HoldingsCalculator.get_holdings_summary(user.id)

      assert summary.holdings_count == 1
      # 10 * $50
      assert Decimal.equal?(summary.total_value, Decimal.new("500.00"))
      # Zero cost basis
      assert Decimal.equal?(summary.total_cost_basis, Decimal.new("0.00"))
      # All value is profit
      assert Decimal.equal?(summary.total_pnl, Decimal.new("500.00"))
      # Infinite percentage gain, but should handle gracefully
      assert Decimal.equal?(summary.total_pnl_pct, Decimal.new("0.0"))
    end
  end

  describe "error handling" do
    test "handles invalid user ID gracefully" do
      invalid_user_id = Ecto.UUID.generate()

      {:ok, holdings} = HoldingsCalculator.calculate_holding_values(invalid_user_id)
      assert holdings == []

      {:ok, total_value} = HoldingsCalculator.aggregate_portfolio_value(invalid_user_id)
      assert Decimal.equal?(total_value, Decimal.new(0))

      {:ok, summary} = HoldingsCalculator.get_holdings_summary(invalid_user_id)
      assert summary.holdings_count == 0
      assert summary.holdings == []
      assert Decimal.equal?(summary.total_value, Decimal.new(0))
    end

    test "handles nil user ID gracefully" do
      # HoldingsCalculator functions expect binary user_id, so nil will cause function clause error
      assert_raise FunctionClauseError, fn ->
        HoldingsCalculator.calculate_holding_values(nil)
      end

      assert_raise FunctionClauseError, fn ->
        HoldingsCalculator.aggregate_portfolio_value(nil)
      end

      assert_raise FunctionClauseError, fn ->
        HoldingsCalculator.get_holdings_summary(nil)
      end
    end

    test "handles invalid symbol ID in cost basis calculation" do
      {:ok, user} = create_test_user()
      invalid_symbol_id = Ecto.UUID.generate()

      {:ok, cost_basis} = HoldingsCalculator.calculate_cost_basis(user.id, invalid_symbol_id)

      assert Decimal.equal?(cost_basis.quantity, Decimal.new(0))
      assert Decimal.equal?(cost_basis.total_cost, Decimal.new(0))
      assert Decimal.equal?(cost_basis.average_cost, Decimal.new(0))
    end

    test "handles invalid symbol ID in holding P&L calculation" do
      {:ok, user} = create_test_user()
      invalid_symbol_id = Ecto.UUID.generate()

      # Invalid symbol ID should return an error
      {:error, _reason} = HoldingsCalculator.calculate_holding_pnl(user.id, invalid_symbol_id)
    end
  end

  describe "edge cases" do
    test "handles fractional shares correctly" do
      {:ok, user} = create_test_user()
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "FRACTIONAL",
          name: "Fractional Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("100.00")
        })

      # Buy fractional shares
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("1.5"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("150.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, holdings} = HoldingsCalculator.calculate_holding_values(user.id)

      assert length(holdings) == 1
      holding = List.first(holdings)
      assert Decimal.equal?(holding.quantity, Decimal.new("1.5"))
      # 1.5 * $100
      assert Decimal.equal?(holding.current_value, Decimal.new("150.00"))
      assert Decimal.equal?(holding.cost_basis, Decimal.new("150.00"))
      assert Decimal.equal?(holding.unrealized_pnl, Decimal.new("0.00"))
    end

    test "handles very large quantities" do
      {:ok, user} = create_test_user()
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "LARGE",
          name: "Large Holdings Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("1.00")
        })

      # Buy a million shares
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("1000000"),
          price: Decimal.new("1.00"),
          total_amount: Decimal.new("1000000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, holdings} = HoldingsCalculator.calculate_holding_values(user.id)

      assert length(holdings) == 1
      holding = List.first(holdings)
      assert Decimal.equal?(holding.quantity, Decimal.new("1000000"))
      assert Decimal.equal?(holding.current_value, Decimal.new("1000000.00"))
      assert Decimal.equal?(holding.cost_basis, Decimal.new("1000000.00"))
    end

    test "handles complex cost basis with multiple transactions" do
      {:ok, user} = User.create(%{name: "Test User", currency: "USD", locale: "en-US"})
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "COMPLEX",
          name: "Complex Test Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("120.00")
        })

      # First buy: 100 shares at $80
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("80.00"),
          total_amount: Decimal.new("8000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Second buy: 50 shares at $100
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("50"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("5000.00"),
          date: ~D[2024-01-02],
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Sell 75 shares at $110 (proportional cost reduction)
      {:ok, _} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("-75"),
          price: Decimal.new("110.00"),
          total_amount: Decimal.new("8250.00"),
          date: ~D[2024-01-03],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, cost_basis} = HoldingsCalculator.calculate_cost_basis(user.id, symbol.id)

      # Remaining: 75 shares (150 - 75)
      assert Decimal.equal?(cost_basis.quantity, Decimal.new("75"))
      # Cost: Proportional reduction: 75/150 * $13000 = $6500
      assert Decimal.equal?(cost_basis.total_cost, Decimal.new("6500.0"))
      # Average: $6500 / 75 = $86.67 (rounded)
      expected_avg = Decimal.div(Decimal.new("6500.0"), Decimal.new("75"))
      assert Decimal.equal?(cost_basis.average_cost, expected_avg)
    end

    test "handles symbols with extremely high prices" do
      {:ok, user} = create_test_user()
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "EXPENSIVE",
          name: "Expensive Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("999999.99")
        })

      # Buy fractional share of expensive stock
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("0.001"),
          price: Decimal.new("500000.00"),
          total_amount: Decimal.new("500.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, pnl} = HoldingsCalculator.calculate_holding_pnl(user.id, symbol.id)

      assert Decimal.equal?(pnl.quantity, Decimal.new("0.001"))
      assert Decimal.equal?(pnl.current_price, Decimal.new("999999.99"))
      # 0.001 * $999999.99 = $999.99999
      expected_value = Decimal.mult(Decimal.new("0.001"), Decimal.new("999999.99"))
      assert Decimal.equal?(pnl.current_value, expected_value)
      assert Decimal.equal?(pnl.cost_basis, Decimal.new("500.00"))
    end

    test "handles dividend and fee transactions in cost basis" do
      {:ok, user} = create_test_user()
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "DIVFEE",
          name: "Dividend Fee Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("100.00")
        })

      # Buy shares
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

      # Receive dividend (doesn't affect cost basis, must have positive quantity)
      {:ok, _} =
        Transaction.create(%{
          type: :dividend,
          quantity: Decimal.new("1"),
          price: Decimal.new("5.00"),
          total_amount: Decimal.new("50.00"),
          date: ~D[2024-01-15],
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Pay fee (doesn't affect cost basis, must have positive quantity for fee transactions)
      {:ok, _} =
        Transaction.create(%{
          type: :fee,
          quantity: Decimal.new("1"),
          price: Decimal.new("0.00"),
          total_amount: Decimal.new("10.00"),
          date: ~D[2024-01-20],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, cost_basis} = HoldingsCalculator.calculate_cost_basis(user.id, symbol.id)

      # Only buy transactions should affect cost basis
      assert Decimal.equal?(cost_basis.quantity, Decimal.new("10"))
      assert Decimal.equal?(cost_basis.total_cost, Decimal.new("1000.00"))
      assert Decimal.equal?(cost_basis.average_cost, Decimal.new("100.00"))
    end
  end

  describe "comprehensive edge cases and error scenarios" do
    test "handles accounts with is_excluded flag" do
      {:ok, user} = create_test_user()
      {:ok, active_account} = Account.create(%{name: "Active Account", user_id: user.id})

      {:ok, excluded_account} =
        Account.create(%{name: "Excluded Account", user_id: user.id, is_excluded: true})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "EXCLUDED",
          name: "Excluded Test Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("100.00")
        })

      # Transaction in active account
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-01],
          account_id: active_account.id,
          symbol_id: symbol.id
        })

      # Transaction in excluded account (should be ignored)
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("10000.00"),
          date: ~D[2024-01-01],
          account_id: excluded_account.id,
          symbol_id: symbol.id
        })

      {:ok, holdings} = HoldingsCalculator.calculate_holding_values(user.id)

      # Should only see the active account transaction
      assert length(holdings) == 1
      holding = List.first(holdings)
      assert Decimal.equal?(holding.quantity, Decimal.new("10"))
      assert Decimal.equal?(holding.cost_basis, Decimal.new("1000.00"))
    end

    test "handles zero cost basis scenarios in portfolio summary" do
      {:ok, user} = create_test_user()
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, free_symbol} =
        Symbol.create(%{
          symbol: "FREEBIES",
          name: "Free Stock Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("25.00")
        })

      {:ok, regular_symbol} =
        Symbol.create(%{
          symbol: "REGULAR",
          name: "Regular Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("100.00")
        })

      # Free stock
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("4"),
          price: Decimal.new("0.00"),
          total_amount: Decimal.new("0.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: free_symbol.id
        })

      # Regular stock
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("80.00"),
          total_amount: Decimal.new("800.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: regular_symbol.id
        })

      {:ok, summary} = HoldingsCalculator.get_holdings_summary(user.id)

      assert summary.holdings_count == 2
      # Total value: 4 * $25 + 10 * $100 = $100 + $1000 = $1100
      assert Decimal.equal?(summary.total_value, Decimal.new("1100.00"))
      # Total cost: $0 + $800 = $800
      assert Decimal.equal?(summary.total_cost_basis, Decimal.new("800.00"))
      # Net P&L: $1100 - $800 = $300
      assert Decimal.equal?(summary.total_pnl, Decimal.new("300.00"))
      # Percentage: $300 / $800 * 100 = 37.5%
      assert Decimal.equal?(summary.total_pnl_pct, Decimal.new("37.5"))
    end

    test "handles portfolio with only zero cost basis holdings" do
      {:ok, user} = create_test_user()
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "ALLFREE",
          name: "All Free Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("50.00")
        })

      # All free stock
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("20"),
          price: Decimal.new("0.00"),
          total_amount: Decimal.new("0.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, summary} = HoldingsCalculator.get_holdings_summary(user.id)

      assert summary.holdings_count == 1
      # 20 * $50
      assert Decimal.equal?(summary.total_value, Decimal.new("1000.00"))
      # Zero total cost
      assert Decimal.equal?(summary.total_cost_basis, Decimal.new("0.00"))
      # All profit
      assert Decimal.equal?(summary.total_pnl, Decimal.new("1000.00"))
      # Division by zero should be handled gracefully
      assert Decimal.equal?(summary.total_pnl_pct, Decimal.new("0.0"))
    end

    test "handles complex sell scenarios with overselling" do
      {:ok, user} = create_test_user()
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "OVERSOLD",
          name: "Oversold Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("90.00")
        })

      # Buy 100 shares
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("80.00"),
          total_amount: Decimal.new("8000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Sell all 100 shares
      {:ok, _} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("-100"),
          price: Decimal.new("90.00"),
          total_amount: Decimal.new("9000.00"),
          date: ~D[2024-01-02],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, holdings} = HoldingsCalculator.calculate_holding_values(user.id)

      # Should filter out zero quantity holdings
      assert length(holdings) == 0

      {:ok, summary} = HoldingsCalculator.get_holdings_summary(user.id)
      assert summary.holdings_count == 0
      assert Decimal.equal?(summary.total_value, Decimal.new("0.00"))
      assert Decimal.equal?(summary.total_cost_basis, Decimal.new("0.00"))
    end

    test "handles mixed transaction types in filtering" do
      {:ok, user} = create_test_user()
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "MIXED",
          name: "Mixed Transactions Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("100.00")
        })

      # Buy transaction (should be included)
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("90.00"),
          total_amount: Decimal.new("900.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Dividend transaction (should be filtered out)
      {:ok, _} =
        Transaction.create(%{
          type: :dividend,
          quantity: Decimal.new("1"),
          price: Decimal.new("0.00"),
          total_amount: Decimal.new("50.00"),
          date: ~D[2024-01-15],
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Fee transaction (should be filtered out)
      {:ok, _} =
        Transaction.create(%{
          type: :fee,
          quantity: Decimal.new("1"),
          price: Decimal.new("0.00"),
          total_amount: Decimal.new("10.00"),
          date: ~D[2024-01-20],
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Interest transaction (should be filtered out)
      {:ok, _} =
        Transaction.create(%{
          type: :interest,
          quantity: Decimal.new("1"),
          price: Decimal.new("0.00"),
          total_amount: Decimal.new("25.00"),
          date: ~D[2024-01-25],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, cost_basis} = HoldingsCalculator.calculate_cost_basis(user.id, symbol.id)

      # Should only consider buy transactions
      assert Decimal.equal?(cost_basis.quantity, Decimal.new("10"))
      assert Decimal.equal?(cost_basis.total_cost, Decimal.new("900.00"))
      assert Decimal.equal?(cost_basis.average_cost, Decimal.new("90.00"))
    end

    test "handles multiple accounts with same symbol" do
      {:ok, user} = create_test_user()
      {:ok, account1} = Account.create(%{name: "Account 1", user_id: user.id})
      {:ok, account2} = Account.create(%{name: "Account 2", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "MULTI",
          name: "Multi Account Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("100.00")
        })

      # Buy in first account
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("80.00"),
          total_amount: Decimal.new("800.00"),
          date: ~D[2024-01-01],
          account_id: account1.id,
          symbol_id: symbol.id
        })

      # Buy in second account
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("5"),
          price: Decimal.new("90.00"),
          total_amount: Decimal.new("450.00"),
          date: ~D[2024-01-02],
          account_id: account2.id,
          symbol_id: symbol.id
        })

      {:ok, cost_basis} = HoldingsCalculator.calculate_cost_basis(user.id, symbol.id)

      # Should aggregate across accounts
      assert Decimal.equal?(cost_basis.quantity, Decimal.new("15"))
      assert Decimal.equal?(cost_basis.total_cost, Decimal.new("1250.00"))
      # Average: $1250 / 15 = $83.33...
      expected_avg = Decimal.div(Decimal.new("1250.00"), Decimal.new("15"))
      assert Decimal.equal?(cost_basis.average_cost, expected_avg)
    end
  end
end
