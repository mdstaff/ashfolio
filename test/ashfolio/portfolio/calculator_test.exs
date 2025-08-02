defmodule Ashfolio.Portfolio.CalculatorTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.Portfolio.Calculator
  alias Ashfolio.Portfolio.{User, Account, Symbol, Transaction}

  describe "calculate_portfolio_value/1" do
    test "calculates total portfolio value correctly" do
      # Create test data
      {:ok, user} = User.create(%{name: "Test User"})
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol1} = Symbol.create(%{
        symbol: "AAPL",
        name: "Apple Inc.",
        asset_class: :stock,
        data_source: :yahoo_finance,
        current_price: Decimal.new("150.00")
      })

      {:ok, symbol2} = Symbol.create(%{
        symbol: "MSFT",
        name: "Microsoft",
        asset_class: :stock,
        data_source: :yahoo_finance,
        current_price: Decimal.new("300.00")
      })

      # Create transactions
      {:ok, _} = Transaction.create(%{
        type: :buy,
        quantity: Decimal.new("10"),
        price: Decimal.new("100.00"),
        total_amount: Decimal.new("1000.00"),
        date: ~D[2024-01-01],
        account_id: account.id,
        symbol_id: symbol1.id
      })

      {:ok, _} = Transaction.create(%{
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
      {:ok, excluded_account} = Account.create(%{name: "Excluded Account", user_id: user.id, is_excluded: true})

      {:ok, symbol} = Symbol.create(%{
        symbol: "AAPL",
        name: "Apple Inc.",
        asset_class: :stock,
        data_source: :yahoo_finance,
        current_price: Decimal.new("150.00")
      })

      # Transaction in active account
      {:ok, _} = Transaction.create(%{
        type: :buy,
        quantity: Decimal.new("10"),
        price: Decimal.new("100.00"),
        total_amount: Decimal.new("1000.00"),
        date: ~D[2024-01-01],
        account_id: active_account.id,
        symbol_id: symbol.id
      })

      # Transaction in excluded account
      {:ok, _} = Transaction.create(%{
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

      {:ok, symbol1} = Symbol.create(%{
        symbol: "AAPL",
        name: "Apple Inc.",
        asset_class: :stock,
        data_source: :yahoo_finance,
        current_price: Decimal.new("150.00")
      })

      {:ok, symbol2} = Symbol.create(%{
        symbol: "MSFT",
        name: "Microsoft",
        asset_class: :stock,
        data_source: :yahoo_finance,
        current_price: Decimal.new("200.00")
      })

      # Create transactions
      {:ok, _} = Transaction.create(%{
        type: :buy,
        quantity: Decimal.new("10"),
        price: Decimal.new("100.00"),
        total_amount: Decimal.new("1000.00"),
        date: ~D[2024-01-01],
        account_id: account.id,
        symbol_id: symbol1.id
      })

      {:ok, _} = Transaction.create(%{
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
      assert Decimal.equal?(aapl_position.current_value, Decimal.new("1500.00"))  # 10 * $150
      assert Decimal.equal?(aapl_position.cost_basis, Decimal.new("1000.00"))
      assert Decimal.equal?(aapl_position.return_percentage, Decimal.new("50.0"))  # 50% gain

      # Find MSFT position
      msft_position = Enum.find(positions, fn p -> p.symbol == "MSFT" end)
      assert msft_position != nil
      assert Decimal.equal?(msft_position.quantity, Decimal.new("5"))
      assert Decimal.equal?(msft_position.current_value, Decimal.new("1000.00"))  # 5 * $200
      assert Decimal.equal?(msft_position.cost_basis, Decimal.new("1250.00"))
      assert Decimal.equal?(msft_position.return_percentage, Decimal.new("-20.0"))  # 20% loss
    end

    test "filters out positions with zero quantity" do
      {:ok, user} = User.create(%{name: "Test User"})
      {:ok, account} = Account.create(%{name: "Test Account", user_id: user.id})

      {:ok, symbol} = Symbol.create(%{
        symbol: "AAPL",
        name: "Apple Inc.",
        asset_class: :stock,
        data_source: :yahoo_finance,
        current_price: Decimal.new("150.00")
      })

      # Buy and then sell all shares
      {:ok, _} = Transaction.create(%{
        type: :buy,
        quantity: Decimal.new("10"),
        price: Decimal.new("100.00"),
        total_amount: Decimal.new("1000.00"),
        date: ~D[2024-01-01],
        account_id: account.id,
        symbol_id: symbol.id
      })

      {:ok, _} = Transaction.create(%{
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

      {:ok, symbol} = Symbol.create(%{
        symbol: "AAPL",
        name: "Apple Inc.",
        asset_class: :stock,
        data_source: :yahoo_finance,
        current_price: Decimal.new("150.00")
      })

      {:ok, _} = Transaction.create(%{
        type: :buy,
        quantity: Decimal.new("10"),
        price: Decimal.new("100.00"),
        total_amount: Decimal.new("1000.00"),
        date: ~D[2024-01-01],
        account_id: account.id,
        symbol_id: symbol.id
      })

      {:ok, summary} = Calculator.calculate_total_return(user.id)

      assert Decimal.equal?(summary.total_value, Decimal.new("1500.00"))  # 10 * $150
      assert Decimal.equal?(summary.cost_basis, Decimal.new("1000.00"))
      assert Decimal.equal?(summary.return_percentage, Decimal.new("50.0"))  # 50% gain
      assert Decimal.equal?(summary.dollar_return, Decimal.new("500.00"))  # $500 gain
    end

    test "handles portfolio with no holdings" do
      {:ok, user} = User.create(%{name: "Empty User"})

      {:ok, summary} = Calculator.calculate_total_return(user.id)

      assert Decimal.equal?(summary.total_value, Decimal.new(0))
      assert Decimal.equal?(summary.cost_basis, Decimal.new(0))
      assert Decimal.equal?(summary.return_percentage, Decimal.new(0))
      assert Decimal.equal?(summary.dollar_return, Decimal.new(0))
    end
  end
end
