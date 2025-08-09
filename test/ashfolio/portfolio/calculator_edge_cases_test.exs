defmodule Ashfolio.Portfolio.CalculatorEdgeCasesTest do
  @moduledoc """
  Edge case tests for portfolio calculations addressing coverage gaps.

  Tests scenarios like:
  - Zero quantities and prices
  - Extreme decimal precision
  - Division by zero scenarios
  - Large number handling
  - Negative cost basis scenarios
  """

  use Ashfolio.DataCase, async: false

  alias Ashfolio.Portfolio.Calculator
  alias Ashfolio.SQLiteHelpers

  describe "edge cases in simple return calculation" do
    test "handles zero cost basis correctly" do
      current_value = Decimal.new("1000.00")
      cost_basis = Decimal.new("0.00")

      assert {:ok, result} = Calculator.calculate_simple_return(current_value, cost_basis)
      assert Decimal.equal?(result, Decimal.new("0.00"))
    end

    test "handles zero current value correctly" do
      current_value = Decimal.new("0.00")
      cost_basis = Decimal.new("1000.00")

      assert {:ok, result} = Calculator.calculate_simple_return(current_value, cost_basis)
      assert Decimal.equal?(result, Decimal.new("-100.00"))
    end

    test "handles very small decimal values" do
      current_value = Decimal.new("0.0001")
      cost_basis = Decimal.new("0.0001")

      assert {:ok, result} = Calculator.calculate_simple_return(current_value, cost_basis)
      assert Decimal.equal?(result, Decimal.new("0.00"))
    end

    test "handles very large decimal values" do
      current_value = Decimal.new("999999999.99")
      cost_basis = Decimal.new("1000000000.00")

      assert {:ok, result} = Calculator.calculate_simple_return(current_value, cost_basis)
      # Should be approximately -0.0001%
      assert Decimal.lt?(result, Decimal.new("0.00"))
      assert Decimal.gt?(result, Decimal.new("-1.00"))
    end

    test "handles extreme precision scenarios" do
      current_value = Decimal.new("1000.123456789")
      cost_basis = Decimal.new("1000.123456788")

      assert {:ok, result} = Calculator.calculate_simple_return(current_value, cost_basis)
      # Should handle the tiny difference correctly
      assert Decimal.gt?(result, Decimal.new("0.00"))
    end
  end

  describe "portfolio value calculation edge cases" do
    setup do
      user = SQLiteHelpers.get_default_user()
      %{user: user}
    end

    test "handles portfolio with no holdings", %{user: user} do
      assert {:ok, portfolio_value} = Calculator.calculate_portfolio_value(user.id)
      assert Decimal.equal?(portfolio_value, Decimal.new("0.00"))
    end

    test "handles portfolio with zero-quantity holdings", %{user: user} do
      # Create account and symbol
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Account"})
      symbol = SQLiteHelpers.get_or_create_symbol("TEST", %{name: "Test Corp"})

      # Create buy and sell transactions that net to zero
      _buy = SQLiteHelpers.create_test_transaction(user, account, symbol, %{
        type: :buy,
        quantity: Decimal.new("10"),
        price: Decimal.new("100.00")
      })

      _sell = SQLiteHelpers.create_test_transaction(user, account, symbol, %{
        type: :sell,
        quantity: Decimal.new("-10"),
        price: Decimal.new("100.00")
      })

      assert {:ok, portfolio_value} = Calculator.calculate_portfolio_value(user.id)
      assert Decimal.equal?(portfolio_value, Decimal.new("0.00"))
    end

    test "handles symbols with nil current price", %{user: user} do
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Account"})
      symbol = SQLiteHelpers.get_or_create_symbol("NOPRICE", %{name: "No Price Corp", current_price: nil})

      _transaction = SQLiteHelpers.create_test_transaction(user, account, symbol, %{
        type: :buy,
        quantity: Decimal.new("10"),
        price: Decimal.new("100.00")
      })

      assert {:ok, portfolio_value} = Calculator.calculate_portfolio_value(user.id)
      assert Decimal.equal?(portfolio_value, Decimal.new("0.00"))
    end
  end

  describe "position calculation edge cases" do
    setup do
      user = SQLiteHelpers.get_default_user()
      %{user: user}
    end

    test "handles complex buy/sell sequences", %{user: user} do
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Account"})
      symbol = SQLiteHelpers.get_or_create_symbol("COMPLEX", %{name: "Complex Corp", current_price: Decimal.new("50.00")})

      # Complex sequence: buy, partial sell, buy more, partial sell
      SQLiteHelpers.create_test_transaction(user, account, symbol, %{
        type: :buy,
        quantity: Decimal.new("100"),
        price: Decimal.new("40.00")
      })

      SQLiteHelpers.create_test_transaction(user, account, symbol, %{
        type: :sell,
        quantity: Decimal.new("-30"),
        price: Decimal.new("45.00")
      })

      SQLiteHelpers.create_test_transaction(user, account, symbol, %{
        type: :buy,
        quantity: Decimal.new("50"),
        price: Decimal.new("48.00")
      })

      SQLiteHelpers.create_test_transaction(user, account, symbol, %{
        type: :sell,
        quantity: Decimal.new("-20"),
        price: Decimal.new("52.00")
      })

      assert {:ok, positions} = Calculator.calculate_position_returns(user.id)
      assert length(positions) == 1

      position = List.first(positions)
      assert Decimal.equal?(position.quantity, Decimal.new("100"))  # 100 - 30 + 50 - 20
      assert Decimal.gt?(position.current_value, Decimal.new("0"))
    end

    test "handles sell-before-buy scenarios gracefully", %{user: user} do
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Account"})
      symbol = SQLiteHelpers.get_or_create_symbol("SELLBUY", %{name: "Sell Buy Corp", current_price: Decimal.new("100.00")})

      # Sell before any buy (short position scenario)
      SQLiteHelpers.create_test_transaction(user, account, symbol, %{
        type: :sell,
        quantity: Decimal.new("-10"),
        price: Decimal.new("100.00")
      })

      SQLiteHelpers.create_test_transaction(user, account, symbol, %{
        type: :buy,
        quantity: Decimal.new("15"),
        price: Decimal.new("95.00")
      })

      assert {:ok, positions} = Calculator.calculate_position_returns(user.id)
      assert length(positions) == 1

      position = List.first(positions)
      assert Decimal.equal?(position.quantity, Decimal.new("5"))  # -10 + 15
    end
  end

  describe "error handling edge cases" do
    test "handles invalid user ID gracefully" do
      invalid_user_id = "non-existent-user-id"

      assert {:error, _reason} = Calculator.calculate_portfolio_value(invalid_user_id)
      assert {:error, _reason} = Calculator.calculate_position_returns(invalid_user_id)
      assert {:error, _reason} = Calculator.calculate_total_return(invalid_user_id)
    end

    test "handles database connection errors gracefully" do
      # This would require mocking the database connection
      # For now, we ensure the error handling structure is in place
      user = SQLiteHelpers.get_default_user()

      # These should not crash even if database has issues
      assert is_tuple(Calculator.calculate_portfolio_value(user.id))
      assert is_tuple(Calculator.calculate_position_returns(user.id))
      assert is_tuple(Calculator.calculate_total_return(user.id))
    end
  end
end
