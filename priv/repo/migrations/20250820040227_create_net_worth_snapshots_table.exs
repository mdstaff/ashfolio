defmodule Ashfolio.Repo.Migrations.CreateNetWorthSnapshotsTable do
  use Ecto.Migration

  def change do
    create table(:net_worth_snapshots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :snapshot_date, :date, null: false
      add :total_assets, :decimal, null: false
      add :total_liabilities, :decimal, default: 0, null: false
      add :net_worth, :decimal, null: false
      add :investment_value, :decimal
      add :cash_value, :decimal
      add :other_assets_value, :decimal
      add :is_automated, :boolean, default: true, null: false
      add :notes, :text

      timestamps()
    end

    # Critical performance indexes for time-series queries
    create unique_index(:net_worth_snapshots, [:snapshot_date])

    # Index for automated vs manual snapshots
    create index(:net_worth_snapshots, [:is_automated])

    # Index for date range queries (compound index)
    create index(:net_worth_snapshots, [:snapshot_date, :net_worth])
  end
end
