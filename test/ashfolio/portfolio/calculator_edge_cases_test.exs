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
      _buy =
        SQLiteHelpers.create_test_transaction(user, account, symbol, %{
          type: :buy,
          quantity: Decimal.new("10"),
          price: Decimal.new("100.00")
        })

      _sell =
        SQLiteHelpers.create_test_transaction(user, account, symbol, %{
          type: :sell,
          quantity: Decimal.new("-10"),
          price: Decimal.new("100.00")
        })

      assert {:ok, portfolio_value} = Calculator.calculate_portfolio_value(user.id)
      assert Decimal.equal?(portfolio_value, Decimal.new("0.00"))
    end

    test "handles symbols with nil current price", %{user: user} do
      account = SQLiteHelpers.get_or_create_account(user, %{name: "Test Account"})

      symbol =
        SQLiteHelpers.get_or_create_symbol("NOPRICE", %{name: "No Price Corp", current_price: nil})

      _transaction =
        SQLiteHelpers.create_test_transaction(user, account, symbol, %{
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
  end

  describe "error handling edge cases" do
    test "handles invalid user ID gracefully" do
      invalid_user_id = "non-existent-user-id"

      assert {:error, _reason} = Calculator.calculate_portfolio_value(invalid_user_id)
      assert {:error, _reason} = Calculator.calculate_position_returns(invalid_user_id)
      assert {:error, _reason} = Calculator.calculate_total_return(invalid_user_id)
    end
  end
end
