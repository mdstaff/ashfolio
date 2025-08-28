#!/usr/bin/env elixir

# Database Setup Script for Ashfolio
# Creates a clean database-as-user architecture
# Each SQLite database represents a single user's complete portfolio
#
# Run with: mix run scripts/setup-database.exs
# Options:  mix run scripts/setup-database.exs -- --force  (overwrites existing database)
#           mix run scripts/setup-database.exs -- data/custom.db --force

defmodule DatabaseSetup do
  @moduledoc """
  Database setup script for Ashfolio.

  This script creates a clean database schema following the database-as-user
  architecture where each SQLite database represents a single user's portfolio.

  Benefits of running with Mix:
  - Automatic access to all project dependencies (Exqlite, Ecto, etc.)
  - Consistent with project configuration
  - Can use project modules if needed
  - Proper dependency resolution

  Safety features:
  - Checks for existing database before overwriting
  - Requires --force flag to overwrite existing data
  - Creates backups before overwriting (optional)
  """

  def run(database_path, options \\ %{}) do
    IO.puts("🔍 Checking database at: #{database_path}")

    # Ensure directory exists
    database_dir = Path.dirname(database_path)
    File.mkdir_p!(database_dir)

    # Check if database already exists
    cond do
      File.exists?(database_path) && !options[:force] ->
        IO.puts("❌ Database already exists at: #{database_path}")
        IO.puts("")
        IO.puts("Options:")
        IO.puts("  1. Use --force flag to overwrite: mix run scripts/setup-database.exs -- --force")
        IO.puts("  2. Remove the existing database manually: rm #{database_path}")
        IO.puts("  3. Use a different database path")
        IO.puts("")
        IO.puts("⚠️  Warning: Overwriting will delete all existing data!")
        System.halt(1)

      File.exists?(database_path) && options[:force] ->
        IO.puts("⚠️  Force flag detected - backing up existing database...")
        backup_path = "#{database_path}.backup.#{System.system_time(:second)}"
        File.copy!(database_path, backup_path)
        IO.puts("✅ Backup created at: #{backup_path}")

        # Remove existing database and related files
        IO.puts("🗑️  Removing existing database...")
        File.rm_rf(database_path)
        File.rm_rf("#{database_path}-wal")
        File.rm_rf("#{database_path}-shm")
        setup_new_database(database_path)

      true ->
        # Database doesn't exist, proceed with setup
        setup_new_database(database_path)
    end
  end

  defp setup_new_database(database_path) do
    IO.puts("✨ Setting up new database at: #{database_path}")

    # Setup database connection
    {:ok, conn} = Exqlite.Sqlite3.open(database_path)

    try do
      # Configure SQLite pragmas for performance
      :ok = Exqlite.Sqlite3.execute(conn, "PRAGMA journal_mode = WAL")
      :ok = Exqlite.Sqlite3.execute(conn, "PRAGMA cache_size = -64000")
      :ok = Exqlite.Sqlite3.execute(conn, "PRAGMA temp_store = MEMORY")
      :ok = Exqlite.Sqlite3.execute(conn, "PRAGMA synchronous = NORMAL")
      :ok = Exqlite.Sqlite3.execute(conn, "PRAGMA foreign_keys = ON")

      # Create all tables
      create_schema(conn)

      # Seed with default data
      seed_default_data(conn)

      IO.puts("✅ Database setup completed successfully!")
      IO.puts("📍 Database location: #{database_path}")
      :ok
    rescue
      error ->
        IO.puts("❌ Setup failed: #{inspect(error)}")
        # Clean up on failure
        File.rm_rf(database_path)
        reraise error, __STACKTRACE__
    after
      Exqlite.Sqlite3.close(conn)
    end
  end

  defp create_schema(conn) do
    IO.puts("📋 Creating database schema...")

    # Create UserSettings table (singleton user preferences)
    # Note: Only core fields that match the Ash resource
    execute(conn, """
    CREATE TABLE IF NOT EXISTS user_settings (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL DEFAULT 'Local User',
      currency TEXT NOT NULL DEFAULT 'USD',
      locale TEXT NOT NULL DEFAULT 'en-US',
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """)

    # Create symbols table (market data)
    execute(conn, """
    CREATE TABLE IF NOT EXISTS symbols (
      id TEXT PRIMARY KEY NOT NULL,
      symbol TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      current_price DECIMAL,
      last_updated TEXT,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """)

    # Create accounts table (no user_id - all accounts belong to this database)
    execute(conn, """
    CREATE TABLE IF NOT EXISTS accounts (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL,
      platform TEXT,
      currency TEXT NOT NULL DEFAULT 'USD',
      is_excluded INTEGER NOT NULL DEFAULT 0,
      balance DECIMAL NOT NULL DEFAULT 0,
      balance_updated_at TEXT,
      account_type TEXT NOT NULL DEFAULT 'investment',
      interest_rate DECIMAL,
      minimum_balance DECIMAL,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """)

    # Create transaction_categories table (no user_id - all categories belong to this database)
    execute(conn, """
    CREATE TABLE IF NOT EXISTS transaction_categories (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL,
      color TEXT,
      is_system INTEGER NOT NULL DEFAULT 0,
      parent_category_id TEXT REFERENCES transaction_categories(id),
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """)

    # Create transactions table (references accounts and symbols, no user_id)
    execute(conn, """
    CREATE TABLE IF NOT EXISTS transactions (
      id TEXT PRIMARY KEY NOT NULL,
      type TEXT NOT NULL,
      quantity DECIMAL NOT NULL,
      price DECIMAL NOT NULL,
      total_amount DECIMAL NOT NULL,
      fee DECIMAL NOT NULL DEFAULT 0,
      date TEXT NOT NULL,
      notes TEXT,
      account_id TEXT NOT NULL REFERENCES accounts(id),
      symbol_id TEXT NOT NULL REFERENCES symbols(id),
      category_id TEXT REFERENCES transaction_categories(id),
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """)

    create_indexes(conn)
  end

  defp create_indexes(conn) do
    IO.puts("🔍 Creating database indexes...")

    # Symbols indexes
    execute(conn, "CREATE UNIQUE INDEX IF NOT EXISTS idx_symbols_symbol_unique ON symbols (symbol)")

    # Accounts indexes
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_accounts_name ON accounts (name)")
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_accounts_account_type ON accounts (account_type)")
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_accounts_is_excluded ON accounts (is_excluded)")
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_accounts_balance_updated_at ON accounts (balance_updated_at)")

    # Transaction categories indexes
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_transaction_categories_name ON transaction_categories (name)")
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_transaction_categories_is_system ON transaction_categories (is_system)")

    # Transactions indexes
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON transactions (account_id)")
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_transactions_symbol_id ON transactions (symbol_id)")
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_transactions_category_id ON transactions (category_id)")
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions (date)")
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions (type)")

    # Performance indexes
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_accounts_name_type ON accounts (name, account_type)")
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_transactions_account_date ON transactions (account_id, date)")
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_transactions_symbol_type ON transactions (symbol_id, type)")
    execute(conn, "CREATE INDEX IF NOT EXISTS idx_transaction_categories_system_name ON transaction_categories (is_system, name)")
  end

  defp seed_default_data(conn) do
    IO.puts("🌱 Seeding default data...")

    # Create default user settings (simplified to match Ash resource)
    user_id = Ecto.UUID.generate()
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    execute(conn, """
    INSERT OR IGNORE INTO user_settings (id, name, currency, locale, inserted_at, updated_at)
    VALUES ('#{user_id}', 'Local User', 'USD', 'en-US', '#{now}', '#{now}')
    """)

    # Create default system categories
    categories = [
      {Ecto.UUID.generate(), "Growth", "#10B981"},
      {Ecto.UUID.generate(), "Income", "#3B82F6"},
      {Ecto.UUID.generate(), "Speculative", "#F59E0B"},
      {Ecto.UUID.generate(), "Index", "#8B5CF6"},
      {Ecto.UUID.generate(), "Cash", "#6B7280"},
      {Ecto.UUID.generate(), "Bonds", "#059669"}
    ]

    Enum.each(categories, fn {id, name, color} ->
      execute(conn, """
      INSERT OR IGNORE INTO transaction_categories (id, name, color, is_system, inserted_at, updated_at)
      VALUES ('#{id}', '#{name}', '#{color}', 1, '#{now}', '#{now}')
      """)
    end)

    IO.puts("✅ Created default user settings and #{length(categories)} transaction categories")
  end

  defp execute(conn, sql) do
    case Exqlite.Sqlite3.execute(conn, sql) do
      :ok -> :ok
      {:error, error} ->
        IO.puts("SQL Error: #{inspect(error)}")
        IO.puts("SQL: #{sql}")
        raise "Database setup failed: #{inspect(error)}"
    end
  end

  def parse_args(args) do
    # Remove the first "--" if it exists (from mix run script -- args)
    clean_args = case args do
      ["--" | rest] -> rest
      other -> other
    end

    {opts, positional_args, _} = OptionParser.parse(clean_args,
      switches: [force: :boolean, help: :boolean],
      aliases: [f: :force, h: :help]
    )

    options = Enum.into(opts, %{})

    # Filter out flag arguments from positional args
    paths = Enum.filter(positional_args, fn arg ->
      not String.starts_with?(arg, "-")
    end)

    cond do
      options[:help] ->
        print_help()
        System.halt(0)

      length(paths) > 1 ->
        IO.puts("❌ Too many database paths provided")
        print_help()
        System.halt(1)

      true ->
        database_path = List.first(paths) || "data/ashfolio_dev.db"
        {database_path, options}
    end
  end

  defp print_help do
    IO.puts("""

    Database Setup Script for Ashfolio
    ===================================

    Usage: mix run scripts/setup-database.exs -- [options] [database_path]

    Options:
      --force, -f     Force overwrite of existing database (creates backup)
      --help, -h      Show this help message

    Examples:
      mix run scripts/setup-database.exs                    # Setup default dev database
      mix run scripts/setup-database.exs -- --force         # Overwrite existing database
      mix run scripts/setup-database.exs -- data/test.db    # Use custom database path
      mix run scripts/setup-database.exs -- data/test.db --force  # Force with custom path

    Default database path: data/ashfolio_dev.db

    ⚠️  Warning: Using --force will backup and then delete the existing database!
    """)
  end
end

# Main execution
{database_path, options} = DatabaseSetup.parse_args(System.argv())
DatabaseSetup.run(database_path, options)
