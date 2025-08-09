defmodule Ashfolio.Repo.Migrations.AddPerformanceIndexes do
  @moduledoc """
  Adds performance indexes for common queries in the Ashfolio application.

  These indexes optimize:
  - Transaction queries by account, symbol, date, and type
  - Symbol lookups by symbol name
  - Account queries by user
  - User lookups (though single-user for now)
  """

  use Ecto.Migration

  def up do
    # Indexes for transactions table (most queried)
    create index(:transactions, [:account_id], name: :idx_transactions_account_id)
    create index(:transactions, [:symbol_id], name: :idx_transactions_symbol_id)
    create index(:transactions, [:date], name: :idx_transactions_date)
    create index(:transactions, [:type], name: :idx_transactions_type)
    create index(:transactions, [:date, :type], name: :idx_transactions_date_type)
    create index(:transactions, [:account_id, :symbol_id], name: :idx_transactions_account_symbol)

    # Indexes for symbols table
    create unique_index(:symbols, [:symbol], name: :idx_symbols_symbol_unique)
    create index(:symbols, [:asset_class], name: :idx_symbols_asset_class)
    create index(:symbols, [:data_source], name: :idx_symbols_data_source)
    create index(:symbols, [:price_updated_at], name: :idx_symbols_price_updated_at)

    # Indexes for accounts table
    create index(:accounts, [:user_id], name: :idx_accounts_user_id)
    create index(:accounts, [:is_excluded], name: :idx_accounts_is_excluded)
    create index(:accounts, [:user_id, :is_excluded], name: :idx_accounts_user_active)

    # Index for users table (future-proofing)
    create index(:users, [:currency], name: :idx_users_currency)
  end

  def down do
    # Drop indexes in reverse order
    drop index(:users, [:currency], name: :idx_users_currency)

    drop index(:accounts, [:user_id, :is_excluded], name: :idx_accounts_user_active)
    drop index(:accounts, [:is_excluded], name: :idx_accounts_is_excluded)
    drop index(:accounts, [:user_id], name: :idx_accounts_user_id)

    drop index(:symbols, [:price_updated_at], name: :idx_symbols_price_updated_at)
    drop index(:symbols, [:data_source], name: :idx_symbols_data_source)
    drop index(:symbols, [:asset_class], name: :idx_symbols_asset_class)
    drop index(:symbols, [:symbol], name: :idx_symbols_symbol_unique)

    drop index(:transactions, [:account_id, :symbol_id], name: :idx_transactions_account_symbol)
    drop index(:transactions, [:date, :type], name: :idx_transactions_date_type)
    drop index(:transactions, [:type], name: :idx_transactions_type)
    drop index(:transactions, [:date], name: :idx_transactions_date)
    drop index(:transactions, [:symbol_id], name: :idx_transactions_symbol_id)
    drop index(:transactions, [:account_id], name: :idx_transactions_account_id)
  end
end
