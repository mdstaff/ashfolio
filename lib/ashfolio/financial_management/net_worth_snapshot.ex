defmodule Ashfolio.FinancialManagement.NetWorthSnapshot do
  @moduledoc """
  NetWorthSnapshot resource for tracking net worth over time.

  Stores point-in-time calculations of net worth across all accounts,
  enabling historical tracking, trending analysis, and progress monitoring
  for financial independence planning.
  """

  use Ash.Resource,
    domain: Ashfolio.FinancialManagement,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table("net_worth_snapshots")
    repo(Ashfolio.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :snapshot_date, :date do
      allow_nil?(false)
      description("Date when this snapshot was taken")
    end

    attribute :total_assets, :decimal do
      allow_nil?(false)
      description("Total value of all assets")
    end

    attribute :total_liabilities, :decimal do
      default(Decimal.new(0))
      allow_nil?(false)
      description("Total liabilities/debt")
    end

    attribute :net_worth, :decimal do
      allow_nil?(false)
      description("Net worth (assets - liabilities)")
    end

    attribute :investment_value, :decimal do
      description("Total value of investment accounts")
    end

    attribute :cash_value, :decimal do
      description("Total value of cash accounts")
    end

    attribute :other_assets_value, :decimal do
      description("Total value of other assets (real estate, etc.)")
    end

    attribute :is_automated, :boolean do
      default(true)
      allow_nil?(false)
      description("Whether this snapshot was created automatically")
    end

    attribute :notes, :string do
      description("Optional notes about this snapshot")
    end

    timestamps()
  end

  validations do
    validate(present(:snapshot_date), message: "is required")
    validate(present(:total_assets), message: "is required")
    validate(present(:net_worth), message: "is required")

    # Validate amounts are not negative
    validate(compare(:total_assets, greater_than_or_equal_to: 0),
      message: "must be greater than or equal to 0"
    )

    validate(compare(:total_liabilities, greater_than_or_equal_to: 0),
      message: "must be greater than or equal to 0"
    )

    # Validate net worth calculation
    validate(fn changeset, _context ->
      total_assets = Ash.Changeset.get_attribute(changeset, :total_assets)
      total_liabilities = Ash.Changeset.get_attribute(changeset, :total_liabilities)
      net_worth = Ash.Changeset.get_attribute(changeset, :net_worth)

      if total_assets && total_liabilities && net_worth do
        expected_net_worth = Decimal.sub(total_assets, total_liabilities)

        if Decimal.equal?(net_worth, expected_net_worth) do
          :ok
        else
          {:error, field: :net_worth, message: "must equal total_assets minus total_liabilities"}
        end
      else
        :ok
      end
    end)

    # Validate notes length if present
    validate(string_length(:notes, max: 1000),
      where: present(:notes)
    )
  end

  identities do
    identity(:unique_snapshot_date, [:snapshot_date])
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :snapshot_date,
        :total_assets,
        :total_liabilities,
        :net_worth,
        :investment_value,
        :cash_value,
        :other_assets_value,
        :is_automated,
        :notes
      ])

      primary?(true)
    end

    update :update do
      accept([
        :total_assets,
        :total_liabilities,
        :net_worth,
        :investment_value,
        :cash_value,
        :other_assets_value,
        :notes
      ])

      primary?(true)
      require_atomic?(false)
    end

    read :by_date_range do
      argument(:start_date, :date, allow_nil?: false)
      argument(:end_date, :date, allow_nil?: false)

      filter(expr(snapshot_date >= ^arg(:start_date) and snapshot_date <= ^arg(:end_date)))
    end

    read :by_year do
      argument(:year, :integer, allow_nil?: false)

      filter(expr(fragment("strftime('%Y', ?)", snapshot_date) == type(^arg(:year), :string)))
    end

    read :recent_first do
      prepare(fn query, _ ->
        Ash.Query.sort(query, snapshot_date: :desc)
      end)
    end

    read :latest do
      prepare(fn query, _ ->
        query
        |> Ash.Query.sort(snapshot_date: :desc)
        |> Ash.Query.limit(1)
      end)
    end

    read :automated do
      filter(expr(is_automated == true))
    end

    read :manual do
      filter(expr(is_automated == false))
    end
  end

  code_interface do
    domain(Ashfolio.FinancialManagement)

    define(:create, action: :create)
    define(:list, action: :read)
    define(:get_by_id, action: :read, get_by: [:id])
    define(:update, action: :update)
    define(:destroy, action: :destroy)
    define(:by_date_range, action: :by_date_range, args: [:start_date, :end_date])
    define(:by_year, action: :by_year, args: [:year])
    define(:recent_first, action: :recent_first)
    define(:latest, action: :latest)
    define(:automated, action: :automated)
    define(:manual, action: :manual)

    # Analytics functions
    def year_over_year_growth!(current_year, previous_year) do
      require Ash.Query

      current_snapshots = current_year |> by_year!() |> List.last()
      previous_snapshots = previous_year |> by_year!() |> List.last()

      if current_snapshots && previous_snapshots do
        current_value = current_snapshots.net_worth
        previous_value = previous_snapshots.net_worth

        if Decimal.gt?(previous_value, 0) do
          growth = Decimal.sub(current_value, previous_value)
          percentage = Decimal.div(growth, previous_value)
          Decimal.mult(percentage, Decimal.new(100))
        else
          Decimal.new(0)
        end
      else
        Decimal.new(0)
      end
    end

    def monthly_growth_rate!(start_date, end_date) do
      require Ash.Query

      snapshots = by_date_range!(start_date, end_date)

      if length(snapshots) >= 2 do
        first = List.first(snapshots)
        last = List.last(snapshots)

        months = Date.diff(end_date, start_date) / 30

        if months > 0 && Decimal.gt?(first.net_worth, 0) do
          ratio = Decimal.div(last.net_worth, first.net_worth)
          monthly_rate = :math.pow(Decimal.to_float(ratio), 1 / months) - 1

          # Convert float to string then to Decimal to avoid precision issues
          monthly_rate_str = Float.to_string(monthly_rate * 100)
          Decimal.new(monthly_rate_str)
        else
          Decimal.new(0)
        end
      else
        Decimal.new(0)
      end
    end

    def latest! do
      case latest() do
        {:ok, [snapshot]} -> snapshot
        {:ok, []} -> nil
        {:error, _} -> nil
      end
    end
  end
end
