defmodule Ashfolio.FinancialManagement.Expense do
  @moduledoc """
  Expense resource for tracking spending and categorizing expenses.

  Enables comprehensive expense tracking for financial planning, budgeting,
  and FIRE calculations. Links expenses to categories and payment accounts.
  """

  use Ash.Resource,
    domain: Ashfolio.FinancialManagement,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table("expenses")
    repo(Ashfolio.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :description, :string do
      allow_nil?(false)
      description("Description of the expense")
    end

    attribute :amount, :decimal do
      allow_nil?(false)
      description("Amount of the expense (always positive)")
    end

    attribute :date, :date do
      allow_nil?(false)
      description("Date when the expense occurred")
    end

    attribute :merchant, :string do
      description("Merchant or vendor name")
    end

    attribute :notes, :string do
      description("Additional notes or details about the expense")
    end

    attribute :is_recurring, :boolean do
      default(false)
      allow_nil?(false)
      description("Whether this is a recurring expense")
    end

    attribute :frequency, :atom do
      constraints(one_of: [:monthly, :quarterly, :annual, :weekly, :biweekly])
      description("Frequency of recurring expense")
    end

    timestamps()
  end

  relationships do
    belongs_to :category, Ashfolio.FinancialManagement.TransactionCategory do
      allow_nil?(true)
      description("Category for this expense")
    end

    belongs_to :account, Ashfolio.Portfolio.Account do
      allow_nil?(true)
      description("Account used to pay for this expense")
    end
  end

  validations do
    validate(present(:description), message: "is required")
    validate(present(:amount), message: "is required")
    validate(present(:date), message: "is required")

    # Validate amount is positive
    validate(compare(:amount, greater_than: 0),
      message: "must be greater than 0"
    )

    # Validate reasonable amount limits
    validate(compare(:amount, less_than_or_equal_to: Decimal.new("1000000.00")),
      message: "cannot exceed $1,000,000.00"
    )

    # Validate description length
    validate(string_length(:description, min: 1, max: 500))

    # Validate merchant length if present
    validate(string_length(:merchant, max: 200),
      where: present(:merchant)
    )

    # Validate frequency is set if recurring
    validate(present(:frequency),
      where: attribute_equals(:is_recurring, true),
      message: "is required for recurring expenses"
    )

    # Validate frequency is not set if not recurring
    validate(absent(:frequency),
      where: attribute_equals(:is_recurring, false),
      message: "should not be set for non-recurring expenses"
    )
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :description,
        :amount,
        :date,
        :merchant,
        :notes,
        :is_recurring,
        :frequency,
        :category_id,
        :account_id
      ])

      primary?(true)
    end

    update :update do
      accept([
        :description,
        :amount,
        :date,
        :merchant,
        :notes,
        :is_recurring,
        :frequency,
        :category_id,
        :account_id
      ])

      primary?(true)
      require_atomic?(false)
    end

    read :by_month do
      argument(:year, :integer, allow_nil?: false)
      argument(:month, :integer, allow_nil?: false)

      filter(
        expr(
          fragment("strftime('%Y', ?)", date) == type(^arg(:year), :string) and
            fragment("strftime('%m', ?)", date) == fragment("printf('%02d', ?)", ^arg(:month))
        )
      )
    end

    read :by_category do
      argument(:category_id, :uuid, allow_nil?: false)
      filter(expr(category_id == ^arg(:category_id)))
    end

    read :by_date_range do
      argument(:start_date, :date, allow_nil?: false)
      argument(:end_date, :date, allow_nil?: false)

      filter(expr(date >= ^arg(:start_date) and date <= ^arg(:end_date)))
    end

    read :recurring do
      filter(expr(is_recurring == true))
    end
  end

  calculations do
    calculate(:month_year, :string, expr(fragment("strftime('%Y-%m', ?)", date)))
  end

  code_interface do
    domain(Ashfolio.FinancialManagement)

    define(:create, action: :create)
    define(:list, action: :read)
    define(:get_by_id, action: :read, get_by: [:id])
    define(:update, action: :update)
    define(:destroy, action: :destroy)
    define(:by_month, action: :by_month, args: [:year, :month])
    define(:by_category, action: :by_category, args: [:category_id])
    define(:by_date_range, action: :by_date_range, args: [:start_date, :end_date])
    define(:recurring, action: :recurring)

    # Helper functions for aggregations - simplified for now
    def monthly_totals!(year) do
      require Ash.Query

      year_str = to_string(year)

      __MODULE__
      |> Ash.Query.filter(fragment("strftime('%Y', ?)", date) == ^year_str)
      |> Ash.Query.load(:month_year)
      |> Ash.read!()
      |> Enum.group_by(& &1.month_year)
      |> Map.new(fn {month, expenses} ->
        total = expenses |> Enum.map(& &1.amount) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
        {month, total}
      end)
    end

    def category_totals!(start_date, end_date) do
      require Ash.Query

      __MODULE__
      |> Ash.Query.filter(date >= ^start_date and date <= ^end_date)
      |> Ash.read!()
      |> Enum.group_by(& &1.category_id)
      |> Map.new(fn {category_id, expenses} ->
        total = expenses |> Enum.map(& &1.amount) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
        {category_id, total}
      end)
    end
  end
end
