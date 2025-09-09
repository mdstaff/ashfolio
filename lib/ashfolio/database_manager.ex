defmodule Ashfolio.DatabaseManager do
  @moduledoc """
  Database management utilities for local development and data operations.

  Provides functions for:
  - Truncating and re-seeding tables for local development
  - Database backup and restore operations
  - Future: Prod > Staging > Dev data replication (when Prod exists)
  """

  alias Ashfolio.Portfolio.Account
  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Portfolio.Transaction
  alias Ashfolio.Portfolio.User
  alias Ashfolio.Repo

  require Logger

  @doc """
  Truncates all tables and re-seeds with fresh sample data.

  WARNING: This will delete ALL data in the database!
  Only use in development environment.
  """
  def reset_and_reseed! do
    if Application.get_env(:ashfolio, :environment, :prod) != :dev do
      raise "reset_and_reseed!/0 can only be run in development environment"
    end

    Logger.info("🗃️  Truncating all tables and re-seeding...")

    # Truncate tables in dependency order (children first)
    truncate_table("transactions")
    truncate_table("accounts")
    truncate_table("symbols")
    truncate_table("users")

    # Re-seed with fresh data
    seed_database()

    Logger.info("✅ Database reset and re-seeded successfully")
  end

  @doc """
  Truncates a specific table.

  WARNING: This will delete ALL data in the specified table!
  """
  def truncate_table(table_name) when is_binary(table_name) do
    if Application.get_env(:ashfolio, :environment, :prod) != :dev do
      raise "truncate_table/1 can only be run in development environment"
    end

    Logger.info("🗑️  Truncating table: #{table_name}")

    # SQLite doesn't support TRUNCATE, so we use DELETE
    Repo.query!("DELETE FROM #{table_name}")

    # Note: sqlite_sequence is only created for tables with INTEGER PRIMARY KEY AUTOINCREMENT
    # Since we use UUIDs, we don't need to reset any sequence

    Logger.info("✅ Table #{table_name} truncated")
  end

  @doc """
  Seeds the database with sample data for development.
  """
  def seed_database do
    Logger.info("🌱 Seeding database with sample data...")

    # Create default user
    {:ok, user} = create_default_user()

    # Create sample accounts
    accounts = create_sample_accounts(user)

    # Create sample symbols
    symbols = create_sample_symbols()

    # Create sample transactions
    create_sample_transactions(user, accounts, symbols)

    Logger.info("✅ Database seeded successfully")
  end

  @doc """
  Creates a backup of the current database.

  Returns the path to the backup file.
  """
  def create_backup do
    timestamp = DateTime.to_iso8601(DateTime.utc_now(), :basic)
    backup_path = "data/backups/ashfolio_backup_#{timestamp}.db"

    # Ensure backup directory exists
    File.mkdir_p!("data/backups")

    # Copy the database file
    source_path = Application.get_env(:ashfolio, Repo)[:database]
    File.cp!(source_path, backup_path)

    Logger.info("💾 Database backup created: #{backup_path}")
    backup_path
  end

  @doc """
  Restores database from a backup file.

  WARNING: This will overwrite the current database!
  """
  def restore_backup(backup_path) do
    if Application.get_env(:ashfolio, :environment, :prod) == :prod do
      raise "restore_backup/1 cannot be run in production environment"
    end

    if !File.exists?(backup_path) do
      raise "Backup file not found: #{backup_path}"
    end

    target_path = Application.get_env(:ashfolio, Repo)[:database]

    Logger.info("🔄 Restoring database from backup: #{backup_path}")
    File.cp!(backup_path, target_path)
    Logger.info("✅ Database restored successfully")
  end

  @doc """
  Lists available backup files.
  """
  def list_backups do
    backup_dir = "data/backups"

    if File.exists?(backup_dir) do
      backup_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".db"))
      |> Enum.sort(:desc)
      |> Enum.map(&Path.join(backup_dir, &1))
    else
      []
    end
  end

  # NOTE: Future enhancement for Prod > Staging > Dev replication
  @doc """
  Replicates data from production to staging environment.

  NOTE: This is a placeholder for future implementation when we have a production database.
  """
  def replicate_prod_to_staging do
    Logger.info("📋 Prod > Staging replication not yet implemented (no Prod DB)")
    {:error, :not_implemented}
  end

  @doc """
  Replicates data from staging to development environment.

  NOTE: This is a placeholder for future implementation when we have staging/prod databases.
  """
  def replicate_staging_to_dev do
    Logger.info("📋 Staging > Dev replication not yet implemented (no Staging DB)")
    {:error, :not_implemented}
  end

  # Private helper functions

  defp create_default_user do
    Ash.create(User, %{
      name: "Local User",
      currency: "USD",
      locale: "en-US"
    })
  end

  defp create_sample_accounts(_user) do
    accounts = [
      %{name: "Schwab Brokerage", platform: "Charles Schwab", balance: Decimal.new("50000.00")},
      %{name: "Fidelity 401k", platform: "Fidelity", balance: Decimal.new("25000.00")},
      %{name: "Crypto Wallet", platform: "Manual", balance: Decimal.new("5000.00")}
    ]

    Enum.map(accounts, fn account_attrs ->
      {:ok, account} = Account.create(account_attrs)
      account
    end)
  end

  defp create_sample_symbols do
    symbols = [
      %{
        symbol: "AAPL",
        name: "Apple Inc.",
        asset_class: :stock,
        data_source: :yahoo_finance,
        sectors: ["Technology", "Consumer Electronics"],
        countries: ["United States"],
        current_price: Decimal.new("150.00")
      },
      %{
        symbol: "MSFT",
        name: "Microsoft Corporation",
        asset_class: :stock,
        data_source: :yahoo_finance,
        sectors: ["Technology", "Software"],
        countries: ["United States"],
        current_price: Decimal.new("300.00")
      },
      %{
        symbol: "GOOGL",
        name: "Alphabet Inc.",
        asset_class: :stock,
        data_source: :yahoo_finance,
        sectors: ["Technology", "Internet"],
        countries: ["United States"],
        current_price: Decimal.new("2500.00")
      },
      %{
        symbol: "SPY",
        name: "SPDR S&P 500 ETF Trust",
        asset_class: :etf,
        data_source: :yahoo_finance,
        sectors: ["Diversified"],
        countries: ["United States"],
        current_price: Decimal.new("400.00")
      },
      %{
        symbol: "VTI",
        name: "Vanguard Total Stock Market ETF",
        asset_class: :etf,
        data_source: :yahoo_finance,
        sectors: ["Diversified"],
        countries: ["United States"],
        current_price: Decimal.new("200.00")
      },
      %{
        symbol: "TSLA",
        name: "Tesla, Inc.",
        asset_class: :stock,
        data_source: :yahoo_finance,
        sectors: ["Automotive", "Clean Energy"],
        countries: ["United States"],
        current_price: Decimal.new("200.00")
      },
      %{
        symbol: "NVDA",
        name: "NVIDIA Corporation",
        asset_class: :stock,
        data_source: :yahoo_finance,
        sectors: ["Technology", "Semiconductors"],
        countries: ["United States"],
        current_price: Decimal.new("800.00")
      },
      %{
        symbol: "BTC-USD",
        name: "Bitcoin",
        asset_class: :crypto,
        data_source: :coingecko,
        sectors: ["Cryptocurrency"],
        countries: ["Global"],
        current_price: Decimal.new("45000.00")
      }
    ]

    Enum.map(symbols, fn symbol_attrs ->
      attrs_with_timestamp = Map.put(symbol_attrs, :price_updated_at, DateTime.utc_now())
      {:ok, symbol} = Ash.create(Symbol, attrs_with_timestamp)
      symbol
    end)
  end

  defp create_sample_transactions(_user, accounts, symbols) do
    # Create some sample transactions across different accounts and symbols
    [schwab, fidelity, crypto] = accounts
    [aapl, msft, _googl, spy, vti, tsla, _nvda, btc] = symbols

    sample_transactions = [
      # Schwab account transactions
      %{
        account_id: schwab.id,
        symbol_id: aapl.id,
        type: :buy,
        quantity: Decimal.new("100"),
        price: Decimal.new("145.00"),
        total_amount: Decimal.new("14500.00"),
        date: ~D[2024-01-15]
      },
      %{
        account_id: schwab.id,
        symbol_id: msft.id,
        type: :buy,
        quantity: Decimal.new("50"),
        price: Decimal.new("290.00"),
        total_amount: Decimal.new("14500.00"),
        date: ~D[2024-02-01]
      },
      %{
        account_id: schwab.id,
        symbol_id: aapl.id,
        type: :dividend,
        quantity: Decimal.new("100"),
        price: Decimal.new("0.25"),
        total_amount: Decimal.new("25.00"),
        date: ~D[2024-03-15]
      },

      # Fidelity account transactions
      %{
        account_id: fidelity.id,
        symbol_id: spy.id,
        type: :buy,
        quantity: Decimal.new("50"),
        price: Decimal.new("380.00"),
        total_amount: Decimal.new("19000.00"),
        date: ~D[2024-01-20]
      },
      %{
        account_id: fidelity.id,
        symbol_id: vti.id,
        type: :buy,
        quantity: Decimal.new("25"),
        price: Decimal.new("190.00"),
        total_amount: Decimal.new("4750.00"),
        date: ~D[2024-02-15]
      },

      # Crypto account transactions
      %{
        account_id: crypto.id,
        symbol_id: btc.id,
        type: :buy,
        quantity: Decimal.new("0.1"),
        price: Decimal.new("45000.00"),
        total_amount: Decimal.new("4500.00"),
        fee: Decimal.new("25.00"),
        date: ~D[2024-03-01]
      },

      # Additional Schwab transactions
      %{
        account_id: schwab.id,
        symbol_id: tsla.id,
        type: :buy,
        quantity: Decimal.new("25"),
        price: Decimal.new("180.00"),
        total_amount: Decimal.new("4500.00"),
        date: ~D[2024-02-20]
      },

      # Some fees
      %{
        account_id: schwab.id,
        symbol_id: aapl.id,
        type: :fee,
        quantity: Decimal.new("0"),
        price: Decimal.new("0"),
        total_amount: Decimal.new("12.95"),
        fee: Decimal.new("12.95"),
        date: ~D[2024-01-15]
      }
    ]

    Enum.each(sample_transactions, fn transaction_attrs ->
      attrs_with_defaults = Map.merge(%{fee: Decimal.new("0")}, transaction_attrs)
      {:ok, _transaction} = Ash.create(Transaction, attrs_with_defaults)
    end)
  end
end
