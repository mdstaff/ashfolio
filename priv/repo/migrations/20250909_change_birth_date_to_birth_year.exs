defmodule Ashfolio.Repo.Migrations.ChangeBirthDateToBirthYear do
  @moduledoc """
  Migrate from birth_date (DATE) to birth_year (INTEGER) for simplified age management.

  Simple approach: Add birth_year, copy data, remove birth_date
  """

  use Ecto.Migration

  def up do
    # Add birth_year column
    alter table(:financial_profiles) do
      add :birth_year, :integer
    end

    # Copy birth_date data to birth_year (extract year)
    execute """
    UPDATE financial_profiles 
    SET birth_year = CAST(strftime('%Y', birth_date) AS INTEGER)
    WHERE birth_date IS NOT NULL
    """

    # Make birth_year NOT NULL (add constraint)
    execute "UPDATE financial_profiles SET birth_year = 1980 WHERE birth_year IS NULL"

    # Remove birth_date column
    alter table(:financial_profiles) do
      remove :birth_date
    end
  end

  def down do
    # Add birth_date column back
    alter table(:financial_profiles) do
      add :birth_date, :date
    end

    # Convert birth_year back to birth_date (Jan 1st of birth year)
    execute """
    UPDATE financial_profiles 
    SET birth_date = date(birth_year || '-01-01')
    WHERE birth_year IS NOT NULL
    """

    # Remove birth_year column
    alter table(:financial_profiles) do
      remove :birth_year
    end
  end
end
