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
  end

  describe "portfolio value calculation edge cases" do
    test "handles portfolio with no holdings" do
      # Database-as-user architecture: No user needed
      assert {:ok, portfolio_value} = Calculator.calculate_portfolio_value()
      assert Decimal.equal?(portfolio_value, Decimal.new("0.00"))
    end

    test "handles portfolio with zero-quantity holdings" do
      # Database-as-user architecture: No user needed
      # Create account and symbol
      account = SQLiteHelpers.get_default_account()
      symbol = SQLiteHelpers.get_or_create_symbol("TEST", %{name: "Test Corp"})

      # Create buy and sell transactions that net to zero
      _buy =
        SQLiteHelpers.create_test_transaction(account, symbol, %{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00")
        })

      _sell =
        SQLiteHelpers.create_test_transaction(account, symbol, %{
          type: :sell,
          quantity: Decimal.new("-10"),
          price: Decimal.new("100.00")
        })

      assert {:ok, portfolio_value} = Calculator.calculate_portfolio_value()
      assert Decimal.equal?(portfolio_value, Decimal.new("0.00"))
    end

    test "handles symbols with nil current price" do
      # Database-as-user architecture: No user needed
      account = SQLiteHelpers.get_default_account()

      symbol =
        SQLiteHelpers.get_or_create_symbol("NOPRICE", %{name: "No Price Corp", current_price: nil})

      _transaction =
        SQLiteHelpers.create_test_transaction(account, symbol, %{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00")
        })

      assert {:ok, portfolio_value} = Calculator.calculate_portfolio_value()
      assert Decimal.equal?(portfolio_value, Decimal.new("0.00"))
    end
  end

  describe "position calculation edge cases" do
    # Database-as-user architecture: No setup needed
  end

  describe "error handling edge cases" do
    test "handles empty portfolio gracefully" do
      # In database-as-user architecture, test empty portfolio instead of invalid user
      # This should return zero values, not errors
      assert {:ok, portfolio_value} = Calculator.calculate_portfolio_value()
      assert Decimal.equal?(portfolio_value, Decimal.new("0.00"))

      assert {:ok, position_returns} = Calculator.calculate_position_returns()
      assert position_returns == []

      assert {:ok, total_return_data} = Calculator.calculate_total_return()
      assert Decimal.equal?(total_return_data.total_value, Decimal.new("0.00"))
      assert Decimal.equal?(total_return_data.cost_basis, Decimal.new("0.00"))
      assert Decimal.equal?(total_return_data.dollar_return, Decimal.new("0.00"))
    end
  end
end
