defmodule Ashfolio.FinancialManagement.FinancialProfile do
  @moduledoc """
  Financial profile resource for storing user demographic and income data.

  Enables Charles Farrell's "Your Money Ratios" methodology by tracking:
  - Gross annual household income (baseline for all ratios)
  - Birth year (for age-based benchmarking in single-user system)
  - Household composition
  - Debt balances (mortgage, student loans)
  - Primary residence value
  """

  use Ash.Resource,
    domain: Ashfolio.FinancialManagement,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table("financial_profiles")
    repo(Ashfolio.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :gross_annual_income, :decimal do
      allow_nil?(false)
      description("Gross annual household income")
    end

    attribute :birth_year, :integer do
      allow_nil?(false)
      description("Birth year for age calculations")
    end

    attribute :household_members, :integer do
      default(1)
      allow_nil?(false)
      description("Number of household members")
    end

    attribute :primary_residence_value, :decimal do
      description("Current value of primary residence")
    end

    attribute :mortgage_balance, :decimal do
      description("Current mortgage balance")
    end

    attribute :student_loan_balance, :decimal do
      description("Current student loan balance")
    end

    timestamps()
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :gross_annual_income,
        :birth_year,
        :household_members,
        :primary_residence_value,
        :mortgage_balance,
        :student_loan_balance
      ])

      primary?(true)
    end

    update :update do
      accept([
        :gross_annual_income,
        :birth_year,
        :household_members,
        :primary_residence_value,
        :mortgage_balance,
        :student_loan_balance
      ])

      primary?(true)
      require_atomic?(false)
    end

    read :by_id do
      argument(:id, :uuid, allow_nil?: false)
      get?(true)
      filter(expr(id == ^arg(:id)))
    end

    read :read_all do
      primary?(true)
    end
  end

  validations do
    validate(compare(:gross_annual_income, greater_than: 0),
      message: "must be greater than 0"
    )

    validate(compare(:mortgage_balance, greater_than_or_equal_to: 0),
      message: "must be greater than or equal to 0",
      where: [present(:mortgage_balance)]
    )

    validate(compare(:student_loan_balance, greater_than_or_equal_to: 0),
      message: "must be greater than or equal to 0",
      where: [present(:student_loan_balance)]
    )

    validate(compare(:primary_residence_value, greater_than_or_equal_to: 0),
      message: "must be greater than or equal to 0",
      where: [present(:primary_residence_value)]
    )

    # Age validation: 18 to 100 years old (dynamic based on current year)
    validate(compare(:birth_year, greater_than_or_equal_to: 1925),
      message: "age must be between 18 and 100"
    )

    validate(compare(:birth_year, less_than_or_equal_to: 2007),
      message: "age must be between 18 and 100"
    )
  end

  @doc """
  Calculate current age from birth year.
  """
  def calculate_age_from_year(birth_year) do
    Date.utc_today().year - birth_year
  end

  @doc """
  Calculate current age for a profile.
  """
  def calculate_age(profile) do
    calculate_age_from_year(profile.birth_year)
  end

  # Convenience functions for common operations
  def create(attrs), do: Ash.create(__MODULE__, attrs, domain: Ashfolio.FinancialManagement)
  def update(profile, attrs), do: Ash.update(profile, attrs, domain: Ashfolio.FinancialManagement)
  def by_id(id), do: Ash.get(__MODULE__, id, domain: Ashfolio.FinancialManagement)
  def read_all, do: Ash.read(__MODULE__, domain: Ashfolio.FinancialManagement)
  def destroy(profile), do: Ash.destroy(profile, domain: Ashfolio.FinancialManagement)
end
