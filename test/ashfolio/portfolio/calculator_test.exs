defmodule Ashfolio.Portfolio.CalculatorTest do
  use Ashfolio.DataCase, async: false

  @moduletag :calculations
  @moduletag :unit
  @moduletag :fast
  @moduletag :smoke

  alias Ashfolio.Portfolio.Calculator
  alias Ashfolio.Portfolio.Transaction
  alias Ashfolio.SQLiteHelpers

  describe "calculate_portfolio_value/1" do
    test "calculates total portfolio value correctly" do
      # Create test data
      account = SQLiteHelpers.get_or_create_account(%{name: "Test Account"})

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

      # Calculate portfolio value
      {:ok, portfolio_value} = Calculator.calculate_portfolio_value()

      # Expected: 10 * $150 + 5 * $300 = $1500 + $1500 = $3000
      expected_value = Decimal.new("3000.00")
      assert Decimal.equal?(portfolio_value, expected_value)
    end

    test "returns zero for database with no holdings" do
      {:ok, portfolio_value} = Calculator.calculate_portfolio_value()

      assert Decimal.equal?(portfolio_value, Decimal.new(0))
    end

    test "excludes excluded accounts from calculation" do
      active_account = SQLiteHelpers.get_or_create_account(%{name: "Active Account"})

      excluded_account =
        SQLiteHelpers.get_or_create_account(%{name: "Excluded Account", is_excluded: true})

      symbol =
        SQLiteHelpers.get_or_create_symbol("AAPL", %{
          current_price: Decimal.new("150.00")
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

      # Transaction in excluded account
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("20"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("2000.00"),
          date: ~D[2024-01-01],
          account_id: excluded_account.id,
          symbol_id: symbol.id
        })

      {:ok, portfolio_value} = Calculator.calculate_portfolio_value()

      # Should only include active account: 10 * $150 = $1500
      expected_value = Decimal.new("1500.00")
      assert Decimal.equal?(portfolio_value, expected_value)
    end
  end

  describe "calculate_simple_return/2" do
    test "calculates positive return correctly" do
      current_value = Decimal.new("1500.00")
      cost_basis = Decimal.new("1000.00")

      {:ok, return_pct} = Calculator.calculate_simple_return(current_value, cost_basis)

      # (1500 - 1000) / 1000 * 100 = 50%
      expected_return = Decimal.new("50.0")
      assert Decimal.equal?(return_pct, expected_return)
    end

    test "calculates negative return correctly" do
      current_value = Decimal.new("800.00")
      cost_basis = Decimal.new("1000.00")

      {:ok, return_pct} = Calculator.calculate_simple_return(current_value, cost_basis)

      # (800 - 1000) / 1000 * 100 = -20%
      expected_return = Decimal.new("-20.0")
      assert Decimal.equal?(return_pct, expected_return)
    end

    test "handles zero cost basis" do
      current_value = Decimal.new("1000.00")
      cost_basis = Decimal.new("0.00")

      {:ok, return_pct} = Calculator.calculate_simple_return(current_value, cost_basis)

      # Should return 0% to avoid division by zero
      assert Decimal.equal?(return_pct, Decimal.new(0))
    end

    test "calculates zero return when values are equal" do
      current_value = Decimal.new("1000.00")
      cost_basis = Decimal.new("1000.00")

      {:ok, return_pct} = Calculator.calculate_simple_return(current_value, cost_basis)

      # (1000 - 1000) / 1000 * 100 = 0%
      assert Decimal.equal?(return_pct, Decimal.new(0))
    end
  end

  describe "calculate_position_returns/1" do
    test "calculates individual position returns" do
      # Create test data
      account = SQLiteHelpers.get_or_create_account(%{name: "Test Account"})

      symbol1 =
        SQLiteHelpers.get_or_create_symbol("AAPL", %{
          current_price: Decimal.new("150.00")
        })

      symbol2 =
        SQLiteHelpers.get_or_create_symbol("MSFT", %{
          current_price: Decimal.new("200.00")
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
          price: Decimal.new("250.00"),
          total_amount: Decimal.new("1250.00"),
          date: ~D[2024-01-02],
          account_id: account.id,
          symbol_id: symbol2.id
        })

      {:ok, positions} = Calculator.calculate_position_returns()

      assert length(positions) == 2

      # Find AAPL position
      aapl_position = Enum.find(positions, fn p -> p.symbol == "AAPL" end)
      assert aapl_position != nil
      assert Decimal.equal?(aapl_position.quantity, Decimal.new("10"))
      # 10 * $150
      assert Decimal.equal?(aapl_position.current_value, Decimal.new("1500.00"))
      assert Decimal.equal?(aapl_position.cost_basis, Decimal.new("1000.00"))
      # 50% gain
      assert Decimal.equal?(aapl_position.return_percentage, Decimal.new("50.0"))

      # Find MSFT position
      msft_position = Enum.find(positions, fn p -> p.symbol == "MSFT" end)
      assert msft_position != nil
      assert Decimal.equal?(msft_position.quantity, Decimal.new("5"))
      # 5 * $200
      assert Decimal.equal?(msft_position.current_value, Decimal.new("1000.00"))
      assert Decimal.equal?(msft_position.cost_basis, Decimal.new("1250.00"))
      # 20% loss
      assert Decimal.equal?(msft_position.return_percentage, Decimal.new("-20.0"))
    end

    test "filters out positions with zero quantity" do
      account = SQLiteHelpers.get_or_create_account(%{name: "Test Account"})

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

      {:ok, positions} = Calculator.calculate_position_returns()

      # Should have no positions since quantity is zero
      assert Enum.empty?(positions)
    end
  end

  describe "calculate_total_return/1" do
    test "calculates total portfolio return summary" do
      # Create test data
      account = SQLiteHelpers.get_or_create_account(%{name: "Test Account"})

      symbol =
        SQLiteHelpers.get_or_create_symbol("AAPL", %{
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

      {:ok, summary} = Calculator.calculate_total_return()

      # 10 * $150
      assert Decimal.equal?(summary.total_value, Decimal.new("1500.00"))
      assert Decimal.equal?(summary.cost_basis, Decimal.new("1000.00"))
      # 50% gain
      assert Decimal.equal?(summary.return_percentage, Decimal.new("50.0"))
      # $500 gain
      assert Decimal.equal?(summary.dollar_return, Decimal.new("500.00"))
    end

    test "handles portfolio with no holdings" do
      {:ok, summary} = Calculator.calculate_total_return()

      assert Decimal.equal?(summary.total_value, Decimal.new(0))
      assert Decimal.equal?(summary.cost_basis, Decimal.new(0))
      assert Decimal.equal?(summary.return_percentage, Decimal.new(0))
      assert Decimal.equal?(summary.dollar_return, Decimal.new(0))
    end

    test "handles mixed gains and losses across positions" do
      account = SQLiteHelpers.get_or_create_account(%{name: "Test Account"})

      # Winning position
      winner =
        SQLiteHelpers.get_or_create_symbol("WINNER", %{
          current_price: Decimal.new("200.00")
        })

      # Losing position
      loser =
        SQLiteHelpers.get_or_create_symbol("LOSER", %{
          current_price: Decimal.new("50.00")
        })

      # Buy winner at $100, now worth $200 (100% gain)
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

      # Buy loser at $100, now worth $50 (50% loss)
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("1000.00"),
          date: ~D[2024-01-02],
          account_id: account.id,
          symbol_id: loser.id
        })

      {:ok, summary} = Calculator.calculate_total_return()

      # Total value: 10 * $200 + 10 * $50 = $2000 + $500 = $2500
      assert Decimal.equal?(summary.total_value, Decimal.new("2500.00"))
      # Total cost: $1000 + $1000 = $2000
      assert Decimal.equal?(summary.cost_basis, Decimal.new("2000.00"))
      # Net gain: $2500 - $2000 = $500
      assert Decimal.equal?(summary.dollar_return, Decimal.new("500.00"))
      # Return percentage: $500 / $2000 * 100 = 25%
      assert Decimal.equal?(summary.return_percentage, Decimal.new("25.0"))
    end

    test "handles symbols with no current price" do
      account = SQLiteHelpers.get_or_create_account(%{name: "Test Account"})

      symbol =
        SQLiteHelpers.get_or_create_symbol("NOPRICE", %{
          # Explicitly set to nil for no price
          current_price: nil
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

      {:ok, summary} = Calculator.calculate_total_return()

      # No price means $0 current value
      assert Decimal.equal?(summary.total_value, Decimal.new("0.00"))
      assert Decimal.equal?(summary.cost_basis, Decimal.new("1000.00"))
      # Loss of entire investment
      assert Decimal.equal?(summary.dollar_return, Decimal.new("-1000.00"))
      # -100% return
      assert Decimal.equal?(summary.return_percentage, Decimal.new("-100.0"))
    end

    test "handles complex transaction history with multiple buys and sells" do
      account = SQLiteHelpers.get_or_create_account(%{name: "Test Account"})

      symbol =
        SQLiteHelpers.get_or_create_symbol("COMPLEX", %{
          current_price: Decimal.new("120.00")
        })

      # Buy 20 shares at $100
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

      # Sell 5 shares at $110
      {:ok, _} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("-5"),
          price: Decimal.new("110.00"),
          total_amount: Decimal.new("550.00"),
          date: ~D[2024-01-02],
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Buy 10 more shares at $90
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("90.00"),
          total_amount: Decimal.new("900.00"),
          date: ~D[2024-01-03],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, summary} = Calculator.calculate_total_return()

      # Current holdings: 20 - 5 + 10 = 25 shares
      # Current value: 25 * $120 = $3000
      assert Decimal.equal?(summary.total_value, Decimal.new("3000.00"))

      # Cost basis calculation (FIFO):
      # Remaining 15 shares from first buy: 15 * $100 = $1500
      # All 10 shares from third buy: 10 * $90 = $900
      # Total cost basis: $1500 + $900 = $2400
      assert Decimal.equal?(summary.cost_basis, Decimal.new("2400.00"))

      # Return: $3000 - $2400 = $600
      assert Decimal.equal?(summary.dollar_return, Decimal.new("600.00"))
      # Return percentage: $600 / $2400 * 100 = 25%
      assert Decimal.equal?(summary.return_percentage, Decimal.new("25.0"))
    end
  end

  describe "error handling" do
    test "handles empty portfolio gracefully" do
      # Database-as-user architecture: functions handle empty database gracefully
      # This test verifies the functions return appropriate zero values
      assert {:ok, portfolio_value} = Calculator.calculate_portfolio_value()
      assert Decimal.equal?(portfolio_value, Decimal.new("0.00"))

      assert {:ok, position_returns} = Calculator.calculate_position_returns()
      assert position_returns == []

      assert {:ok, total_return} = Calculator.calculate_total_return()
      assert Decimal.equal?(total_return.total_value, Decimal.new("0.00"))
    end
  end

  describe "edge cases" do
    test "handles zero current value with positive cost basis" do
      current_value = Decimal.new("0.00")
      cost_basis = Decimal.new("1000.00")

      {:ok, return_pct} = Calculator.calculate_simple_return(current_value, cost_basis)

      # (0 - 1000) / 1000 * 100 = -100%
      expected_return = Decimal.new("-100.0")
      assert Decimal.equal?(return_pct, expected_return)
    end

    test "handles dividend transactions in portfolio calculations" do
      account = SQLiteHelpers.get_or_create_account(%{name: "Test Account"})

      symbol =
        SQLiteHelpers.get_or_create_symbol("DIVSTOCK", %{
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

      # Receive dividend (must have positive quantity for dividend transactions)
      {:ok, _} =
        Transaction.create(%{
          type: :dividend,
          quantity: Decimal.new("1"),
          price: Decimal.new("2.50"),
          total_amount: Decimal.new("25.00"),
          date: ~D[2024-01-15],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, summary} = Calculator.calculate_total_return()

      # Dividend doesn't affect current value calculation for buy/sell positions
      assert Decimal.equal?(summary.total_value, Decimal.new("1000.00"))
      assert Decimal.equal?(summary.cost_basis, Decimal.new("1000.00"))
      assert Decimal.equal?(summary.return_percentage, Decimal.new("0.0"))
      assert Decimal.equal?(summary.dollar_return, Decimal.new("0.00"))
    end

    test "handles fee transactions in portfolio calculations" do
      account = SQLiteHelpers.get_or_create_account(%{name: "Test Account"})

      symbol =
        SQLiteHelpers.get_or_create_symbol("FEESTOCK", %{
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

      # Pay fee (doesn't affect quantity but might affect cost basis depending on implementation)
      {:ok, _} =
        Transaction.create(%{
          type: :fee,
          quantity: Decimal.new("0"),
          price: Decimal.new("0.00"),
          total_amount: Decimal.new("10.00"),
          date: ~D[2024-01-15],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, summary} = Calculator.calculate_total_return()

      # Fee doesn't affect current value calculation
      assert Decimal.equal?(summary.total_value, Decimal.new("1000.00"))
      assert Decimal.equal?(summary.cost_basis, Decimal.new("1000.00"))
      assert Decimal.equal?(summary.return_percentage, Decimal.new("0.0"))
      assert Decimal.equal?(summary.dollar_return, Decimal.new("0.00"))
    end
  end

  describe "error handling and edge cases" do
    test "handles zero cost basis in calculations" do
      account = SQLiteHelpers.get_or_create_account(%{name: "Edge Case Account"})

      symbol =
        SQLiteHelpers.get_or_create_symbol("ZERO", %{
          current_price: Decimal.new("100.00")
        })

      # Free stock with zero cost
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

      {:ok, position_returns} = Calculator.calculate_position_returns()
      assert length(position_returns) > 0

      zero_cost_position = Enum.find(position_returns, fn p -> p.symbol == "ZERO" end)
      assert zero_cost_position != nil
      assert Decimal.equal?(zero_cost_position.cost_basis, Decimal.new(0))
      assert Decimal.equal?(zero_cost_position.current_value, Decimal.new("1000.00"))
    end

    test "handles extremely small decimal quantities" do
      account = SQLiteHelpers.get_or_create_account(%{name: "Micro Account"})

      symbol =
        SQLiteHelpers.get_or_create_symbol("MICRO", %{
          current_price: Decimal.new("1000.00")
        })

      # Buy tiny fractional share
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("0.000001"),
          price: Decimal.new("1000.00"),
          total_amount: Decimal.new("0.001"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, position_returns} = Calculator.calculate_position_returns()
      micro_position = Enum.find(position_returns, fn p -> p.symbol == "MICRO" end)
      assert micro_position != nil
      assert Decimal.equal?(micro_position.quantity, Decimal.new("0.000001"))
    end

    test "handles extremely large positions" do
      account = SQLiteHelpers.get_or_create_account(%{name: "Whale Account"})

      symbol =
        SQLiteHelpers.get_or_create_symbol("WHALE", %{
          current_price: Decimal.new("1000.00")
        })

      # Large position
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("1000000"),
          price: Decimal.new("1000.00"),
          total_amount: Decimal.new("1000000000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, position_returns} = Calculator.calculate_position_returns()
      whale_position = Enum.find(position_returns, fn p -> p.symbol == "WHALE" end)
      assert whale_position != nil
      assert Decimal.equal?(whale_position.current_value, Decimal.new("1000000000.00"))
    end

    test "handles accounts with only non-buy/sell transactions" do
      account = SQLiteHelpers.get_or_create_account(%{name: "Dividend Account"})

      symbol =
        SQLiteHelpers.get_or_create_symbol("DIVONLY", %{
          current_price: Decimal.new("50.00")
        })

      # Only dividend transaction (should be ignored for position calculations)
      {:ok, _} =
        Transaction.create(%{
          type: :dividend,
          quantity: Decimal.new("10"),
          price: Decimal.new("2.50"),
          total_amount: Decimal.new("25.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, position_returns} = Calculator.calculate_position_returns()
      # Should not include dividend-only positions
      div_position = Enum.find(position_returns, fn p -> p.symbol == "DIVONLY" end)
      assert div_position == nil
    end

    test "handles negative holdings from overselling" do
      account = SQLiteHelpers.get_or_create_account(%{name: "Short Account"})

      symbol =
        SQLiteHelpers.get_or_create_symbol("SHORT", %{
          current_price: Decimal.new("100.00")
        })

      # Buy 100 shares
      {:ok, _} =
        Transaction.create(%{
          type: :buy,
          quantity: Decimal.new("100"),
          price: Decimal.new("90.00"),
          total_amount: Decimal.new("9000.00"),
          date: ~D[2024-01-01],
          account_id: account.id,
          symbol_id: symbol.id
        })

      # Sell 150 shares (overselling)
      {:ok, _} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("-150"),
          price: Decimal.new("100.00"),
          total_amount: Decimal.new("15000.00"),
          date: ~D[2024-01-02],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, position_returns} = Calculator.calculate_position_returns()
      short_position = Enum.find(position_returns, fn p -> p.symbol == "SHORT" end)
      assert short_position != nil
      assert Decimal.equal?(short_position.quantity, Decimal.new("-50"))
      # Negative current value for short position
      assert Decimal.equal?(short_position.current_value, Decimal.new("-5000.00"))
    end

    test "handles multiple partial sells across lots" do
      account = SQLiteHelpers.get_or_create_account(%{name: "Complex Account"})

      symbol =
        SQLiteHelpers.get_or_create_symbol("COMPLEX2", %{
          current_price: Decimal.new("120.00")
        })

      # Multiple buys and sells
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

      {:ok, _} =
        Transaction.create(%{
          type: :sell,
          quantity: Decimal.new("-25"),
          price: Decimal.new("115.00"),
          total_amount: Decimal.new("2875.00"),
          date: ~D[2024-01-04],
          account_id: account.id,
          symbol_id: symbol.id
        })

      {:ok, position_returns} = Calculator.calculate_position_returns()
      complex_position = Enum.find(position_returns, fn p -> p.symbol == "COMPLEX2" end)
      assert complex_position != nil
      assert Decimal.equal?(complex_position.quantity, Decimal.new("50"))

      # Should handle multiple partial sells correctly
      assert Decimal.compare(complex_position.cost_basis, Decimal.new(0)) == :gt
    end

    test "calculates total returns correctly with mixed scenarios" do
      account = SQLiteHelpers.get_or_create_account(%{name: "Mixed Account"})

      # Create multiple symbols with different scenarios
      symbols_data = [
        %{symbol: "WINNER2", price: "150.00", buy_price: "100.00", qty: "100"},
        %{symbol: "LOSER2", price: "80.00", buy_price: "120.00", qty: "50"},
        %{symbol: "FLAT2", price: "100.00", buy_price: "100.00", qty: "75"}
      ]

      for symbol_data <- symbols_data do
        symbol =
          SQLiteHelpers.get_or_create_symbol(symbol_data.symbol, %{
            current_price: Decimal.new(symbol_data.price)
          })

        {:ok, _} =
          Transaction.create(%{
            type: :buy,
            quantity: Decimal.new(symbol_data.qty),
            price: Decimal.new(symbol_data.buy_price),
            total_amount:
              Decimal.mult(Decimal.new(symbol_data.qty), Decimal.new(symbol_data.buy_price)),
            date: ~D[2024-01-01],
            account_id: account.id,
            symbol_id: symbol.id
          })
      end

      {:ok, total_returns} = Calculator.calculate_total_return()
      assert total_returns.dollar_return != nil
      assert total_returns.return_percentage != nil

      # Should have mixed P&L from winners and losers
      {:ok, portfolio_value} = Calculator.calculate_portfolio_value()
      assert Decimal.compare(portfolio_value, Decimal.new(0)) == :gt
    end
  end
end
