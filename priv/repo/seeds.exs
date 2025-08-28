# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# This script creates sample data for the database-as-user architecture.

alias Ashfolio.FinancialManagement.CategorySeeder
alias Ashfolio.FinancialManagement.TransactionCategory
alias Ashfolio.Portfolio.Account
alias Ashfolio.Portfolio.Symbol
alias Ashfolio.Portfolio.Transaction
alias Ashfolio.Portfolio.UserSettings

# Create user settings if they don't exist (database-as-user architecture)
# Temporarily disabled during migration to database-as-user architecture
user_settings = %{
  id: "seed-user-1",
  name: "Seed User",
  currency: "USD",
  locale: "en-US"
}

IO.puts("✅ User settings ready (temporary): #{user_settings.name}")

# Create investment system categories if they don't exist
{:ok, existing_categories} = TransactionCategory.list()

if Enum.empty?(existing_categories) do
  # Create investment categories
  IO.puts("🏷️  Creating investment system categories...")

  case CategorySeeder.seed_system_categories() do
    {:ok, categories} ->
      IO.puts("  ✅ Created #{length(categories)} investment categories:")

      Enum.each(categories, fn category ->
        IO.puts("    - #{category.name} (#{category.color})")
      end)

    {:error, error} ->
      IO.puts("  ❌ Error creating categories: #{inspect(error)}")
  end
else
  IO.puts("ℹ️  Investment categories already exist (#{length(existing_categories)} categories found)")
end

# Create sample accounts if they don't exist
sample_accounts = [
  %{
    name: "Schwab Brokerage",
    platform: "Schwab",
    balance: Decimal.new("50000.00"),
    is_excluded: false
  },
  %{
    name: "Fidelity 401k",
    platform: "Fidelity",
    balance: Decimal.new("75000.00"),
    is_excluded: false
  },
  %{
    name: "Crypto Wallet",
    platform: "Manual",
    balance: Decimal.new("5000.00"),
    is_excluded: false
  }
]

# Check if accounts already exist
{:ok, existing_accounts} = Account.list()

if Enum.empty?(existing_accounts) do
  # Create sample accounts
  IO.puts("🏦 Creating sample accounts...")

  Enum.each(sample_accounts, fn account_attrs ->
    case Account.create(account_attrs) do
      {:ok, account} ->
        IO.puts("  ✅ Created account: #{account.name} (#{account.platform}) - $#{account.balance}")

      {:error, error} ->
        IO.puts("  ❌ Error creating account #{account_attrs.name}: #{inspect(error)}")
    end
  end)
else
  IO.puts("ℹ️  Sample accounts already exist (#{length(existing_accounts)} accounts found)")
end

# Create sample symbols if they don't exist
sample_symbols = [
  %{
    symbol: "AAPL",
    name: "Apple Inc.",
    asset_class: :stock,
    data_source: :yahoo_finance,
    sectors: ["Technology", "Consumer Electronics"],
    countries: ["United States"],
    current_price: Decimal.new("150.00"),
    price_updated_at: DateTime.utc_now()
  },
  %{
    symbol: "MSFT",
    name: "Microsoft Corporation",
    asset_class: :stock,
    data_source: :yahoo_finance,
    sectors: ["Technology", "Software"],
    countries: ["United States"],
    current_price: Decimal.new("300.00"),
    price_updated_at: DateTime.utc_now()
  },
  %{
    symbol: "GOOGL",
    name: "Alphabet Inc.",
    asset_class: :stock,
    data_source: :yahoo_finance,
    sectors: ["Technology", "Internet"],
    countries: ["United States"],
    current_price: Decimal.new("2500.00"),
    price_updated_at: DateTime.utc_now()
  },
  %{
    symbol: "SPY",
    name: "SPDR S&P 500 ETF Trust",
    asset_class: :etf,
    data_source: :yahoo_finance,
    sectors: ["Diversified"],
    countries: ["United States"],
    current_price: Decimal.new("400.00"),
    price_updated_at: DateTime.utc_now()
  },
  %{
    symbol: "VTI",
    name: "Vanguard Total Stock Market ETF",
    asset_class: :etf,
    data_source: :yahoo_finance,
    sectors: ["Diversified"],
    countries: ["United States"],
    current_price: Decimal.new("200.00"),
    price_updated_at: DateTime.utc_now()
  },
  %{
    symbol: "TSLA",
    name: "Tesla, Inc.",
    asset_class: :stock,
    data_source: :yahoo_finance,
    sectors: ["Automotive", "Clean Energy"],
    countries: ["United States"],
    current_price: Decimal.new("200.00"),
    price_updated_at: DateTime.utc_now()
  },
  %{
    symbol: "NVDA",
    name: "NVIDIA Corporation",
    asset_class: :stock,
    data_source: :yahoo_finance,
    sectors: ["Technology", "Semiconductors"],
    countries: ["United States"],
    current_price: Decimal.new("800.00"),
    price_updated_at: DateTime.utc_now()
  },
  %{
    symbol: "BTC-USD",
    name: "Bitcoin",
    asset_class: :crypto,
    data_source: :coingecko,
    sectors: ["Cryptocurrency"],
    countries: ["Global"],
    current_price: Decimal.new("45000.00"),
    price_updated_at: DateTime.utc_now()
  }
]

# Check if symbols already exist
{:ok, existing_symbols} = Symbol.list()

if Enum.empty?(existing_symbols) do
  # Create sample symbols
  IO.puts("📈 Creating sample symbols...")

  Enum.each(sample_symbols, fn symbol_attrs ->
    case Symbol.create(symbol_attrs) do
      {:ok, symbol} ->
        IO.puts("  ✅ Created symbol: #{symbol.symbol} (#{symbol.name}) - $#{symbol.current_price}")

      {:error, error} ->
        IO.puts("  ❌ Error creating symbol #{symbol_attrs.symbol}: #{inspect(error)}")
    end
  end)
else
  IO.puts("ℹ️  Sample symbols already exist (#{length(existing_symbols)} symbols found)")
end

# Create sample transactions if they don't exist
{:ok, existing_transactions} = Transaction.list()

if Enum.empty?(existing_transactions) do
  # Get the created accounts and symbols for transaction creation
  {:ok, accounts} = Account.list()
  {:ok, symbols} = Symbol.list()

  # Find specific accounts and symbols
  schwab_account = Enum.find(accounts, fn acc -> acc.name == "Schwab Brokerage" end)
  fidelity_account = Enum.find(accounts, fn acc -> acc.name == "Fidelity 401k" end)
  crypto_account = Enum.find(accounts, fn acc -> acc.name == "Crypto Wallet" end)

  aapl_symbol = Enum.find(symbols, fn sym -> sym.symbol == "AAPL" end)
  msft_symbol = Enum.find(symbols, fn sym -> sym.symbol == "MSFT" end)
  spy_symbol = Enum.find(symbols, fn sym -> sym.symbol == "SPY" end)
  vti_symbol = Enum.find(symbols, fn sym -> sym.symbol == "VTI" end)
  tsla_symbol = Enum.find(symbols, fn sym -> sym.symbol == "TSLA" end)
  btc_symbol = Enum.find(symbols, fn sym -> sym.symbol == "BTC-USD" end)

  # Sample transactions with realistic data
  sample_transactions = [
    # Schwab Brokerage transactions
    %{
      type: :buy,
      quantity: Decimal.new("100"),
      price: Decimal.new("150.00"),
      total_amount: Decimal.new("15000.00"),
      fee: Decimal.new("0.00"),
      date: Date.add(Date.utc_today(), -30),
      notes: "Initial AAPL purchase",
      account_id: schwab_account && schwab_account.id,
      symbol_id: aapl_symbol && aapl_symbol.id
    },
    %{
      type: :buy,
      quantity: Decimal.new("50"),
      price: Decimal.new("300.00"),
      total_amount: Decimal.new("15000.00"),
      fee: Decimal.new("0.00"),
      date: Date.add(Date.utc_today(), -25),
      notes: "MSFT purchase",
      account_id: schwab_account && schwab_account.id,
      symbol_id: msft_symbol && msft_symbol.id
    },
    %{
      type: :sell,
      quantity: Decimal.new("-25"),
      price: Decimal.new("160.00"),
      total_amount: Decimal.new("4000.00"),
      fee: Decimal.new("0.00"),
      date: Date.add(Date.utc_today(), -10),
      notes: "Partial AAPL sale",
      account_id: schwab_account && schwab_account.id,
      symbol_id: aapl_symbol && aapl_symbol.id
    },
    %{
      type: :dividend,
      quantity: Decimal.new("75"),
      price: Decimal.new("0.25"),
      total_amount: Decimal.new("18.75"),
      fee: Decimal.new("0.00"),
      date: Date.add(Date.utc_today(), -5),
      notes: "AAPL quarterly dividend",
      account_id: schwab_account && schwab_account.id,
      symbol_id: aapl_symbol && aapl_symbol.id
    },

    # Fidelity 401k transactions
    %{
      type: :buy,
      quantity: Decimal.new("200"),
      price: Decimal.new("400.00"),
      total_amount: Decimal.new("80000.00"),
      fee: Decimal.new("0.00"),
      date: Date.add(Date.utc_today(), -60),
      notes: "401k SPY purchase",
      account_id: fidelity_account && fidelity_account.id,
      symbol_id: spy_symbol && spy_symbol.id
    },
    %{
      type: :buy,
      quantity: Decimal.new("100"),
      price: Decimal.new("220.00"),
      total_amount: Decimal.new("22000.00"),
      fee: Decimal.new("0.00"),
      date: Date.add(Date.utc_today(), -45),
      notes: "401k VTI purchase",
      account_id: fidelity_account && fidelity_account.id,
      symbol_id: vti_symbol && vti_symbol.id
    },

    # Crypto Wallet transactions
    %{
      type: :buy,
      quantity: Decimal.new("0.1"),
      price: Decimal.new("45000.00"),
      total_amount: Decimal.new("4500.00"),
      fee: Decimal.new("25.00"),
      date: Date.add(Date.utc_today(), -20),
      notes: "Bitcoin purchase",
      account_id: crypto_account && crypto_account.id,
      symbol_id: btc_symbol && btc_symbol.id
    },

    # Additional Schwab transactions
    %{
      type: :buy,
      quantity: Decimal.new("25"),
      price: Decimal.new("180.00"),
      total_amount: Decimal.new("4500.00"),
      fee: Decimal.new("0.00"),
      date: Date.add(Date.utc_today(), -12),
      notes: "TSLA purchase",
      account_id: schwab_account && schwab_account.id,
      symbol_id: tsla_symbol && tsla_symbol.id
    },

    # Fee transaction example
    %{
      type: :fee,
      quantity: Decimal.new("0"),
      price: Decimal.new("0.00"),
      total_amount: Decimal.new("12.95"),
      fee: Decimal.new("12.95"),
      date: Date.add(Date.utc_today(), -15),
      notes: "Account maintenance fee",
      account_id: schwab_account && schwab_account.id,
      symbol_id: aapl_symbol && aapl_symbol.id
    }
  ]

  # Create sample transactions
  IO.puts("💰 Creating sample transactions...")

  Enum.each(sample_transactions, fn transaction_attrs ->
    # Only create transaction if all required IDs are present
    if transaction_attrs.account_id && transaction_attrs.symbol_id do
      case Transaction.create(transaction_attrs) do
        {:ok, transaction} ->
          IO.puts(
            "  ✅ Created #{transaction.type} transaction: #{transaction.quantity} shares - #{transaction_attrs[:notes] || ""}"
          )

        {:error, error} ->
          IO.puts("  ❌ Error creating transaction: #{inspect(error)}")
      end
    else
      IO.puts("  ⚠️  Skipping transaction due to missing account or symbol")
    end
  end)
else
  IO.puts("ℹ️  Sample transactions already exist (#{length(existing_transactions)} transactions found)")
end

IO.puts("\n✅ Database seeding completed!")
IO.puts("📊 Summary:")
IO.puts("   - User: #{user_settings.name}")

{:ok, final_accounts} = Account.list()
{:ok, final_symbols} = Symbol.list()
{:ok, final_transactions} = Transaction.list()
{:ok, final_categories} = TransactionCategory.list()

IO.puts("   - Accounts: #{length(final_accounts)}")
IO.puts("   - Symbols: #{length(final_symbols)}")
IO.puts("   - Transactions: #{length(final_transactions)}")
IO.puts("   - Categories: #{length(final_categories)}")
IO.puts("\n🚀 Ready to start the application with: mix phx.server")
