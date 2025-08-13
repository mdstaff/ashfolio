defmodule Ashfolio.Repo.Migrations.AddV020Indexes do
  @moduledoc """
  Adds critical performance indexes for v0.2.0 features identified in PR review.

  These indexes optimize:
  - Account type filtering (cash vs investment accounts) - heavily queried
  - Transaction category lookups - new v0.2.0 feature
  - Performance-critical queries for financial management features
  """

  use Ecto.Migration

  def up do
    # Critical index for account_type - heavily queried for cash vs investment filtering
    create index(:accounts, [:account_type], name: :idx_accounts_account_type)

    # Index for new transaction categories feature
    create index(:transactions, [:category_id], name: :idx_transactions_category_id)

    # Composite index for user + account_type filtering (common in Context API)
    create index(:accounts, [:user_id, :account_type], name: :idx_accounts_user_type)

    # Index for cash account balance queries (balance != 0 filters)
    create index(:accounts, [:account_type, :balance], name: :idx_accounts_type_balance)
  end

  def down do
    # Drop indexes in reverse order
    drop index(:accounts, [:account_type, :balance], name: :idx_accounts_type_balance)
    drop index(:accounts, [:user_id, :account_type], name: :idx_accounts_user_type)
    drop index(:transactions, [:category_id], name: :idx_transactions_category_id)
    drop index(:accounts, [:account_type], name: :idx_accounts_account_type)
  end
end
