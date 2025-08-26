defmodule Ashfolio.Repo.Migrations.CreateFinancialGoalsTable do
  use Ecto.Migration

  def change do
    create table(:financial_goals, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :target_amount, :decimal, null: false
      add :current_amount, :decimal, default: 0, null: false
      add :target_date, :date
      add :goal_type, :string, null: false
      add :monthly_contribution, :decimal
      add :is_active, :boolean, default: true, null: false

      timestamps()
    end

    # Performance indexes following the specification
    # Active goals query optimization
    create index(:financial_goals, [:is_active], where: "is_active = true")

    # Goal type filtering (dashboard widgets)
    create index(:financial_goals, [:goal_type])

    # Target date range queries (upcoming goals)
    create index(:financial_goals, [:target_date])
  end
end
