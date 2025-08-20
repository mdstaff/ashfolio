defmodule Ashfolio.Repo.Migrations.CreateExpensesTable do
  use Ecto.Migration

  def change do
    create table(:expenses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :description, :string, null: false
      add :amount, :decimal, null: false
      add :date, :date, null: false
      add :merchant, :string
      add :notes, :text
      add :is_recurring, :boolean, default: false, null: false
      add :frequency, :string

      add :category_id,
          references(:transaction_categories, type: :binary_id, on_delete: :nilify_all)

      add :account_id, references(:accounts, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    # Critical performance indexes for time-series and aggregations
    create index(:expenses, [:date])
    create index(:expenses, [:category_id, :date])
    create index(:expenses, [:account_id, :date])

    # Index for monthly aggregations
    execute "CREATE INDEX expenses_monthly_idx ON expenses (date(date, 'start of month'))",
            "DROP INDEX expenses_monthly_idx"

    # Index for recurring expenses
    create index(:expenses, [:is_recurring])
  end
end
