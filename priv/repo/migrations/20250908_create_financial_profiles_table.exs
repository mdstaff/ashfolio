defmodule Ashfolio.Repo.Migrations.CreateFinancialProfilesTable do
  use Ecto.Migration

  def change do
    create table(:financial_profiles, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :gross_annual_income, :decimal, null: false
      add :birth_date, :date, null: false
      add :household_members, :integer, null: false, default: 1
      add :primary_residence_value, :decimal
      add :mortgage_balance, :decimal
      add :student_loan_balance, :decimal

      timestamps(type: :utc_datetime_usec)
    end
  end
end
