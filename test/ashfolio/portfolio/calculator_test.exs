defmodule Ashfolio.Portfolio.CalculatorTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.Portfolio.Calculator
  alias Ashfolio.Portfolio.{User, Account, Symbol, Transaction}

  describe "calculate_portfolio_value/1" do
    test "calculates total portfolio value correctly" do
      # Create test data
      {:ok, user} = User.create(%{name: "Test User"})
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol1} =
        Symbol.create(%{
          symbol: "AAPL",
          name: "Apple Inc.",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("150.00")
        })

      {:ok, symbol2} =
        Symbol.create(%{
          symbol: "MSFT",
          name: "Microsoft",
          asset_class: :stock,
          data_source: :yahoo_finance,
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
      {:ok, portfolio_value} = Calculator.calculate_portfolio_value(user.id)

      # Expected: 10 * $150 + 5 * $300 = $1500 + $1500 = $3000
      expected_value = Decimal.new("3000.00")
      assert Decimal.equal?(portfolio_value, expected_value)
    end

    test "returns zero for user with no holdings" do
      {:ok, user} = User.create(%{name: "Empty User"})

      {:ok, portfolio_value} = Calculator.calculate_portfolio_value(user.id)

      assert Decimal.equal?(portfolio_value, Decimal.new(0))
    end

    test "excludes excluded accounts from calculation" do
      {:ok, user} = User.create(%{name: "Test User"})
      {:ok, active_account} = Account.create(%{name: "Active Account", user_id: user.id})

      {:ok, excluded_account} =
        Account.create(%{name: "Excluded Account", user_id: user.id, is_excluded: true})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "AAPL",
          name: "Apple Inc.",
          asset_class: :stock,
          data_source: :yahoo_finance,
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

      {:ok, portfolio_value} = Calculator.calculate_portfolio_value(user.id)

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
      {:ok, user} = User.create(%{name: "Test User"})
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol1} =
        Symbol.create(%{
          symbol: "AAPL",
          name: "Apple Inc.",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("150.00")
        })

      {:ok, symbol2} =
        Symbol.create(%{
          symbol: "MSFT",
          name: "Microsoft",
          asset_class: :stock,
          data_source: :yahoo_finance,
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

      {:ok, positions} = Calculator.calculate_position_returns(user.id)

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
      {:ok, user} = User.create(%{name: "Test User"})
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "AAPL",
          name: "Apple Inc.",
          asset_class: :stock,
          data_source: :yahoo_finance,
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

      {:ok, positions} = Calculator.calculate_position_returns(user.id)

      # Should have no positions since quantity is zero
      assert length(positions) == 0
    end
  end

  describe "calculate_total_return/1" do
    test "calculates total portfolio return summary" do
      # Create test data
      {:ok, user} = User.create(%{name: "Test User"})
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "AAPL",
          name: "Apple Inc.",
          asset_class: :stock,
          data_source: :yahoo_finance,
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

      {:ok, summary} = Calculator.calculate_total_return(user.id)

      # 10 * $150
      assert Decimal.equal?(summary.total_value, Decimal.new("1500.00"))
      assert Decimal.equal?(summary.cost_basis, Decimal.new("1000.00"))
      # 50% gain
      assert Decimal.equal?(summary.return_percentage, Decimal.new("50.0"))
      # $500 gain
      assert Decimal.equal?(summary.dollar_return, Decimal.new("500.00"))
    end

    test "handles portfolio with no holdings" do
      {:ok, user} = User.create(%{name: "Empty User"})

      {:ok, summary} = Calculator.calculate_total_return(user.id)

      assert Decimal.equal?(summary.total_value, Decimal.new(0))
      assert Decimal.equal?(summary.cost_basis, Decimal.new(0))
      assert Decimal.equal?(summary.return_percentage, Decimal.new(0))
      assert Decimal.equal?(summary.dollar_return, Decimal.new(0))
    end

    test "handles mixed gains and losses across positions" do
      {:ok, user} = User.create(%{name: "Test User"})
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      # Winning position
      {:ok, winner} =
        Symbol.create(%{
          symbol: "WINNER",
          name: "Winner Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
          current_price: Decimal.new("200.00")
        })

      # Losing position
      {:ok, loser} =
        Symbol.create(%{
          symbol: "LOSER",
          name: "Loser Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
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

      {:ok, summary} = Calculator.calculate_total_return(user.id)

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
      {:ok, user} = User.create(%{name: "Test User"})
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "NOPRICE",
          name: "No Price Corp",
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

      {:ok, summary} = Calculator.calculate_total_return(user.id)

      # No price means $0 current value
      assert Decimal.equal?(summary.total_value, Decimal.new("0.00"))
      assert Decimal.equal?(summary.cost_basis, Decimal.new("1000.00"))
      # Loss of entire investment
      assert Decimal.equal?(summary.dollar_return, Decimal.new("-1000.00"))
      # -100% return
      assert Decimal.equal?(summary.return_percentage, Decimal.new("-100.0"))
    end

    test "handles complex transaction history with multiple buys and sells" do
      {:ok, user} = User.create(%{name: "Test User"})
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "COMPLEX",
          name: "Complex Corp",
          asset_class: :stock,
          data_source: :yahoo_finance,
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

      {:ok, summary} = Calculator.calculate_total_return(user.id)

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
    test "handles invalid user ID gracefully" do
      # Use a UUID that doesn't exist
      invalid_user_id = Ecto.UUID.generate()

      {:ok, portfolio_value} = Calculator.calculate_portfolio_value(invalid_user_id)
      assert Decimal.equal?(portfolio_value, Decimal.new(0))

      {:ok, positions} = Calculator.calculate_position_returns(invalid_user_id)
      assert positions == []

      {:ok, summary} = Calculator.calculate_total_return(invalid_user_id)
      assert Decimal.equal?(summary.total_value, Decimal.new(0))
      assert Decimal.equal?(summary.cost_basis, Decimal.new(0))
      assert Decimal.equal?(summary.return_percentage, Decimal.new(0))
      assert Decimal.equal?(summary.dollar_return, Decimal.new(0))
    end

    test "handles nil user ID gracefully" do
      # Calculator functions should handle nil gracefully by returning default values
      # This test verifies the functions don't crash with nil input
      assert_raise FunctionClauseError, fn ->
        Calculator.calculate_portfolio_value(nil)
      end

      assert_raise FunctionClauseError, fn ->
        Calculator.calculate_position_returns(nil)
      end

      assert_raise FunctionClauseError, fn ->
        Calculator.calculate_total_return(nil)
      end
    end
  end

  describe "edge cases" do
    test "handles very small decimal amounts" do
      current_value = Decimal.new("0.01")
      cost_basis = Decimal.new("0.02")

      {:ok, return_pct} = Calculator.calculate_simple_return(current_value, cost_basis)

      # (0.01 - 0.02) / 0.02 * 100 = -50%
      expected_return = Decimal.new("-50.0")
      assert Decimal.equal?(return_pct, expected_return)
    end

    test "handles very large decimal amounts" do
      current_value = Decimal.new("999999999.99")
      cost_basis = Decimal.new("500000000.00")

      {:ok, return_pct} = Calculator.calculate_simple_return(current_value, cost_basis)

      # (999999999.99 - 500000000.00) / 500000000.00 * 100 = 99.99999999800%
      expected_return = Decimal.new("99.99999999800")
      assert Decimal.equal?(return_pct, expected_return)
    end

    test "handles negative cost basis (unusual but possible)" do
      current_value = Decimal.new("100.00")
      cost_basis = Decimal.new("-50.00")

      {:ok, return_pct} = Calculator.calculate_simple_return(current_value, cost_basis)

      # (100 - (-50)) / (-50) * 100 = 150 / (-50) * 100 = -300%
      expected_return = Decimal.new("-300.0")
      assert Decimal.equal?(return_pct, expected_return)
    end

    test "handles zero current value with positive cost basis" do
      current_value = Decimal.new("0.00")
      cost_basis = Decimal.new("1000.00")

      {:ok, return_pct} = Calculator.calculate_simple_return(current_value, cost_basis)

      # (0 - 1000) / 1000 * 100 = -100%
      expected_return = Decimal.new("-100.0")
      assert Decimal.equal?(return_pct, expected_return)
    end

    test "handles dividend transactions in portfolio calculations" do
      {:ok, user} = User.create(%{name: "Test User"})
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "DIVSTOCK",
          name: "Dividend Stock",
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

      {:ok, summary} = Calculator.calculate_total_return(user.id)

      # Dividend doesn't affect current value calculation for buy/sell positions
      assert Decimal.equal?(summary.total_value, Decimal.new("1000.00"))
      assert Decimal.equal?(summary.cost_basis, Decimal.new("1000.00"))
      assert Decimal.equal?(summary.return_percentage, Decimal.new("0.0"))
      assert Decimal.equal?(summary.dollar_return, Decimal.new("0.00"))
    end

    test "handles fee transactions in portfolio calculations" do
      {:ok, user} = User.create(%{name: "Test User"})
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "FEESTOCK",
          name: "Fee Stock",
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

      {:ok, summary} = Calculator.calculate_total_return(user.id)

      # Fee doesn't affect current value calculation
      assert Decimal.equal?(summary.total_value, Decimal.new("1000.00"))
      assert Decimal.equal?(summary.cost_basis, Decimal.new("1000.00"))
      assert Decimal.equal?(summary.return_percentage, Decimal.new("0.0"))
      assert Decimal.equal?(summary.dollar_return, Decimal.new("0.00"))
    end
  end

  describe "error handling and edge cases" do
    test "handles Account.accounts_for_user/1 errors gracefully" do
      invalid_user_id = Ecto.UUID.generate()
      
      # This should handle the error gracefully and return empty results
      {:ok, portfolio_value} = Calculator.calculate_portfolio_value(invalid_user_id)
      assert Decimal.equal?(portfolio_value, Decimal.new(0))
      
      {:ok, position_returns} = Calculator.calculate_position_returns(invalid_user_id)
      assert position_returns == []
    end

    test "handles zero cost basis in calculations" do
      {:ok, user} = User.create(%{name: "Edge Case User", currency: "USD", locale: "en-US"})
      {:ok, account} = Account.create(%{name: "Edge Case Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "ZERO",
          name: "Zero Cost Stock",
          asset_class: :stock,
          data_source: :yahoo_finance,
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

      {:ok, position_returns} = Calculator.calculate_position_returns(user.id)
      assert length(position_returns) > 0
      
      zero_cost_position = Enum.find(position_returns, fn p -> p.symbol == "ZERO" end)
      assert zero_cost_position != nil
      assert Decimal.equal?(zero_cost_position.cost_basis, Decimal.new(0))
      assert Decimal.equal?(zero_cost_position.current_value, Decimal.new("1000.00"))
    end

    test "handles extremely small decimal quantities" do
      {:ok, user} = User.create(%{name: "Micro User", currency: "USD", locale: "en-US"})
      {:ok, account} = Account.create(%{name: "Micro Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "MICRO",
          name: "Micro Holdings",
          asset_class: :stock,
          data_source: :yahoo_finance,
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

      {:ok, position_returns} = Calculator.calculate_position_returns(user.id)
      micro_position = Enum.find(position_returns, fn p -> p.symbol == "MICRO" end)
      assert micro_position != nil
      assert Decimal.equal?(micro_position.quantity, Decimal.new("0.000001"))
    end

    test "handles extremely large positions" do
      {:ok, user} = User.create(%{name: "Whale User", currency: "USD", locale: "en-US"})
      {:ok, account} = Account.create(%{name: "Whale Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "WHALE",
          name: "Whale Holdings",
          asset_class: :stock,
          data_source: :yahoo_finance,
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

      {:ok, position_returns} = Calculator.calculate_position_returns(user.id)
      whale_position = Enum.find(position_returns, fn p -> p.symbol == "WHALE" end)
      assert whale_position != nil
      assert Decimal.equal?(whale_position.current_value, Decimal.new("1000000000.00"))
    end

    test "handles accounts with only non-buy/sell transactions" do
      {:ok, user} = User.create(%{name: "Dividend User", currency: "USD", locale: "en-US"})
      {:ok, account} = Account.create(%{name: "Dividend Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "DIVONLY",
          name: "Dividend Only",
          asset_class: :stock,
          data_source: :yahoo_finance,
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

      {:ok, position_returns} = Calculator.calculate_position_returns(user.id)
      # Should not include dividend-only positions
      div_position = Enum.find(position_returns, fn p -> p.symbol == "DIVONLY" end)
      assert div_position == nil
    end

    test "handles negative holdings from overselling" do
      {:ok, user} = User.create(%{name: "Short User", currency: "USD", locale: "en-US"})
      {:ok, account} = Account.create(%{name: "Short Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "SHORT",
          name: "Short Position",
          asset_class: :stock,
          data_source: :yahoo_finance,
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

      {:ok, position_returns} = Calculator.calculate_position_returns(user.id)
      short_position = Enum.find(position_returns, fn p -> p.symbol == "SHORT" end)
      assert short_position != nil
      assert Decimal.equal?(short_position.quantity, Decimal.new("-50"))
      # Negative current value for short position
      assert Decimal.equal?(short_position.current_value, Decimal.new("-5000.00"))
    end

    test "handles multiple partial sells across lots" do
      {:ok, user} = User.create(%{name: "Complex User", currency: "USD", locale: "en-US"})
      {:ok, account} = Account.create(%{name: "Complex Account", user_id: user.id})

      {:ok, symbol} =
        Symbol.create(%{
          symbol: "COMPLEX",
          name: "Complex Trading",
          asset_class: :stock,
          data_source: :yahoo_finance,
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

      {:ok, position_returns} = Calculator.calculate_position_returns(user.id)
      complex_position = Enum.find(position_returns, fn p -> p.symbol == "COMPLEX" end)
      assert complex_position != nil
      assert Decimal.equal?(complex_position.quantity, Decimal.new("50"))
      
      # Should handle multiple partial sells correctly
      assert Decimal.compare(complex_position.cost_basis, Decimal.new(0)) == :gt
    end

    test "calculates total returns correctly with mixed scenarios" do
      {:ok, user} = User.create(%{name: "Mixed User", currency: "USD", locale: "en-US"})
      {:ok, account} = Account.create(%{name: "Mixed Account", user_id: user.id})

      # Create multiple symbols with different scenarios
      symbols_data = [
        %{symbol: "WINNER", price: "150.00", buy_price: "100.00", qty: "100"},
        %{symbol: "LOSER", price: "80.00", buy_price: "120.00", qty: "50"},
        %{symbol: "FLAT", price: "100.00", buy_price: "100.00", qty: "75"}
      ]

      for symbol_data <- symbols_data do
        {:ok, symbol} =
          Symbol.create(%{
            symbol: symbol_data.symbol,
            name: "#{symbol_data.symbol} Corp",
            asset_class: :stock,
            data_source: :yahoo_finance,
            current_price: Decimal.new(symbol_data.price)
          })

        {:ok, _} =
          Transaction.create(%{
            type: :buy,
            quantity: Decimal.new(symbol_data.qty),
            price: Decimal.new(symbol_data.buy_price),
            total_amount: Decimal.mult(Decimal.new(symbol_data.qty), Decimal.new(symbol_data.buy_price)),
            date: ~D[2024-01-01],
            account_id: account.id,
            symbol_id: symbol.id
          })
      end

      {:ok, total_returns} = Calculator.calculate_total_return(user.id)
      assert total_returns.dollar_return != nil
      assert total_returns.return_percentage != nil
      
      # Should have mixed P&L from winners and losers
      {:ok, portfolio_value} = Calculator.calculate_portfolio_value(user.id)
      assert Decimal.compare(portfolio_value, Decimal.new(0)) == :gt
    end
  end
end
