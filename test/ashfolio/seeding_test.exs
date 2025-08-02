defmodule Ashfolio.SeedingTest do
  use Ashfolio.DataCase

  alias Ashfolio.Portfolio.{User, Account, Symbol, Transaction}

  describe "database seeding" do
    test "creates default user with proper attributes" do
      # Run the seeding script
      Code.eval_file("priv/repo/seeds.exs")

      # Verify default user was created
      assert {:ok, [user]} = Ash.read(User, action: :default_user)
      assert user.name == "Local User"
      assert user.currency == "USD"
      assert user.locale == "en-US"
    end

    test "creates sample accounts for the default user" do
      # Run the seeding script
      Code.eval_file("priv/repo/seeds.exs")

      # Get the default user
      {:ok, [user]} = Ash.read(User, action: :default_user)

      # Verify accounts were created
      {:ok, accounts} = Account.accounts_for_user(user.id)
      assert length(accounts) == 3

      # Check specific accounts
      account_names = Enum.map(accounts, & &1.name)
      assert "Schwab Brokerage" in account_names
      assert "Fidelity 401k" in account_names
      assert "Crypto Wallet" in account_names

      # Verify account details
      schwab = Enum.find(accounts, &(&1.name == "Schwab Brokerage"))
      assert schwab.platform == "Schwab"
      assert Decimal.equal?(schwab.balance, Decimal.new("50000.00"))
      assert schwab.is_excluded == false
    end

    test "creates sample symbols with current prices" do
      # Run the seeding script
      Code.eval_file("priv/repo/seeds.exs")

      # Verify symbols were created
      {:ok, symbols} = Symbol.list()
      assert length(symbols) == 8

      # Check for required symbols from task
      symbol_codes = Enum.map(symbols, & &1.symbol)
      assert "AAPL" in symbol_codes
      assert "MSFT" in symbol_codes
      assert "GOOGL" in symbol_codes

      # Check additional symbols
      assert "SPY" in symbol_codes
      assert "VTI" in symbol_codes
      assert "TSLA" in symbol_codes
      assert "NVDA" in symbol_codes
      assert "BTC-USD" in symbol_codes

      # Verify symbol details
      aapl = Enum.find(symbols, &(&1.symbol == "AAPL"))
      assert aapl.name == "Apple Inc."
      assert aapl.asset_class == :stock
      assert aapl.data_source == :yahoo_finance
      assert Decimal.equal?(aapl.current_price, Decimal.new("150.00"))
      assert aapl.price_updated_at != nil
      assert "Technology" in aapl.sectors
      assert "United States" in aapl.countries
    end

    test "creates sample transactions across accounts and symbols" do
      # Run the seeding script
      Code.eval_file("priv/repo/seeds.exs")

      # Verify transactions were created
      {:ok, transactions} = Transaction.list()
      assert length(transactions) == 9

      # Check transaction types
      transaction_types = Enum.map(transactions, & &1.type)
      assert :buy in transaction_types
      assert :sell in transaction_types
      assert :dividend in transaction_types
      assert :fee in transaction_types

      # Verify specific transaction
      aapl_buy = Enum.find(transactions, &(&1.notes == "Initial AAPL purchase"))
      assert aapl_buy.type == :buy
      assert Decimal.equal?(aapl_buy.quantity, Decimal.new("100"))
      assert Decimal.equal?(aapl_buy.price, Decimal.new("150.00"))
      assert Decimal.equal?(aapl_buy.total_amount, Decimal.new("15000.00"))
    end

    test "seeding is idempotent - running twice doesn't create duplicates" do
      # Run seeding twice
      Code.eval_file("priv/repo/seeds.exs")
      Code.eval_file("priv/repo/seeds.exs")

      # Verify counts remain the same
      {:ok, users} = Ash.read(User)
      {:ok, accounts} = Ash.read(Account)
      {:ok, symbols} = Ash.read(Symbol)
      {:ok, transactions} = Ash.read(Transaction)

      assert length(users) == 1
      assert length(accounts) == 3
      assert length(symbols) == 8
      assert length(transactions) == 9
    end
  end
end
