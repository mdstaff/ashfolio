defmodule Ashfolio.FinancialManagement.FinancialGoal do
  @moduledoc """
  Financial goal tracking resource following Expense.ex patterns.

  Enables goal setting, progress tracking, and timeline calculations
  for emergency funds, retirement planning, and custom savings goals.
  """

  use Ash.Resource,
    domain: Ashfolio.FinancialManagement,
    data_layer: AshSqlite.DataLayer

  # Follow existing patterns from expense.ex:14-16
  sqlite do
    table("financial_goals")
    repo(Ashfolio.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      description("Name of the financial goal")
    end

    attribute :target_amount, :decimal do
      allow_nil?(false)
      description("Target amount to achieve")
    end

    attribute :current_amount, :decimal do
      default(Decimal.new("0"))
      allow_nil?(false)
      description("Current progress toward goal")
    end

    attribute :target_date, :date do
      description("Target completion date")
    end

    attribute :goal_type, :atom do
      constraints(one_of: [:emergency_fund, :retirement, :house_down_payment, :vacation, :custom])
      allow_nil?(false)
      description("Type of financial goal")
    end

    attribute :monthly_contribution, :decimal do
      description("Planned monthly contribution")
    end

    attribute :is_active, :boolean do
      default(true)
      allow_nil?(false)
      description("Whether goal is actively being tracked")
    end

    timestamps()
  end

  # Follow validation patterns from expense.ex:70-103
  validations do
    validate(present(:name), message: "is required")
    validate(present(:target_amount), message: "is required")
    validate(present(:goal_type), message: "is required")

    # Validate amounts are positive
    validate(compare(:target_amount, greater_than: 0),
      message: "must be greater than 0"
    )

    validate(compare(:current_amount, greater_than_or_equal_to: 0),
      message: "cannot be negative"
    )

    # Validate reasonable limits
    validate(compare(:target_amount, less_than_or_equal_to: Decimal.new("10000000.00")),
      message: "cannot exceed $10,000,000.00"
    )

    validate(string_length(:name, min: 1, max: 200))

    # Validate monthly contribution if present
    validate(compare(:monthly_contribution, greater_than: 0),
      where: present(:monthly_contribution),
      message: "must be greater than 0"
    )

    validate(compare(:monthly_contribution, less_than_or_equal_to: Decimal.new("100000.00")),
      where: present(:monthly_contribution),
      message: "cannot exceed $100,000.00 per month"
    )
  end

  # Follow action patterns from expense.ex:106-169
  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :name,
        :target_amount,
        :current_amount,
        :target_date,
        :goal_type,
        :monthly_contribution,
        :is_active
      ])

      primary?(true)
    end

    update :update do
      accept([
        :name,
        :target_amount,
        :current_amount,
        :target_date,
        :monthly_contribution,
        :is_active
      ])

      primary?(true)
      require_atomic?(false)
    end

    read :active do
      filter(expr(is_active == true))
    end

    read :by_type do
      argument(:goal_type, :atom, allow_nil?: false)
      filter(expr(goal_type == ^arg(:goal_type)))
    end

    read :by_target_date_range do
      argument(:start_date, :date, allow_nil?: false)
      argument(:end_date, :date, allow_nil?: false)

      filter(expr(target_date >= ^arg(:start_date) and target_date <= ^arg(:end_date)))
    end
  end

  calculations do
    calculate(
      :progress_percentage,
      :decimal,
      expr(
        fragment(
          "CASE WHEN ? > 0 THEN ROUND((? / ? * 100), 2) ELSE 0 END",
          target_amount,
          current_amount,
          target_amount
        )
      )
    )

    calculate(
      :months_to_goal,
      :integer,
      expr(
        fragment(
          "CASE WHEN ? > 0 AND ? > ? THEN CAST((? - ?) / ? AS INTEGER) ELSE NULL END",
          monthly_contribution,
          target_amount,
          current_amount,
          target_amount,
          current_amount,
          monthly_contribution
        )
      )
    )

    calculate(
      :amount_remaining,
      :decimal,
      expr(
        fragment(
          "CASE WHEN ? > ? THEN (? - ?) ELSE 0 END",
          target_amount,
          current_amount,
          target_amount,
          current_amount
        )
      )
    )

    calculate(:is_complete, :boolean, expr(current_amount >= target_amount))
  end

  # Follow code_interface pattern from expense.ex:175-219
  code_interface do
    domain(Ashfolio.FinancialManagement)

    define(:create, action: :create)
    define(:list, action: :read)
    define(:get_by_id, action: :read, get_by: [:id])
    define(:update, action: :update)
    define(:destroy, action: :destroy)
    define(:active, action: :active)
    define(:by_type, action: :by_type, args: [:goal_type])
    define(:by_target_date_range, action: :by_target_date_range, args: [:start_date, :end_date])

    # Helper functions for aggregations - following expense.ex pattern
    def goal_progress_summary! do
      require Ash.Query

      __MODULE__
      |> Ash.Query.filter(is_active == true)
      |> Ash.Query.load([:progress_percentage, :amount_remaining, :months_to_goal, :is_complete])
      |> Ash.read!()
      |> Enum.group_by(& &1.goal_type)
      |> Map.new(fn {goal_type, goals} ->
        total_target =
          goals |> Enum.map(& &1.target_amount) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        total_current =
          goals |> Enum.map(& &1.current_amount) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        completed_count = Enum.count(goals, & &1.is_complete)

        {goal_type,
         %{
           total_target: total_target,
           total_current: total_current,
           goal_count: length(goals),
           completed_count: completed_count,
           overall_progress:
             if(Decimal.gt?(total_target, Decimal.new(0)),
               do:
                 total_current
                 |> Decimal.div(total_target)
                 |> Decimal.mult(Decimal.new(100))
                 |> Decimal.round(2),
               else: Decimal.new(0)
             )
         }}
      end)
    end

    def emergency_fund_status!(monthly_expenses) do
      emergency_goals = by_type!(:emergency_fund)

      case emergency_goals do
        [] ->
          {:no_goal, "No emergency fund goal set"}

        [goal | _] ->
          current_months =
            if Decimal.gt?(monthly_expenses, Decimal.new(0)) do
              goal.current_amount |> Decimal.div(monthly_expenses) |> Decimal.round(1)
            else
              Decimal.new(0)
            end

          cond do
            Decimal.gte?(current_months, Decimal.new(6)) -> {:adequate, current_months}
            Decimal.gte?(current_months, Decimal.new(3)) -> {:partial, current_months}
            true -> {:insufficient, current_months}
          end
      end
    end

    @doc """
    Creates or updates an emergency fund goal using EmergencyFundCalculator.

    Integrates with expense history to automatically calculate target amount
    and suggested monthly contribution for emergency fund planning.
    """
    def setup_emergency_fund_goal!(months \\ 6) do
      existing_goals = by_type!(:emergency_fund)

      case existing_goals do
        [] -> create_new_emergency_fund_goal(months)
        [goal | _] -> update_existing_emergency_fund_goal(goal, months)
      end
    end

    defp create_new_emergency_fund_goal(months) do
      alias Ashfolio.FinancialManagement.EmergencyFundCalculator

      case EmergencyFundCalculator.auto_create_emergency_fund_goal(months) do
        {:ok, goal} -> {:created, goal}
        {:error, reason} -> {:error, reason}
      end
    end

    defp update_existing_emergency_fund_goal(goal, months) do
      alias Ashfolio.FinancialManagement.EmergencyFundCalculator

      with {:ok, monthly_expenses} <- EmergencyFundCalculator.calculate_monthly_expenses_from_period(12),
           {:ok, new_target} <- EmergencyFundCalculator.calculate_emergency_fund_target(monthly_expenses, months),
           {:ok, updated_goal} <- update(goal, %{target_amount: new_target}) do
        {:updated, updated_goal}
      end
    end

    @doc """
    Gets comprehensive emergency fund analysis using EmergencyFundCalculator.

    Returns detailed status including progress, timeline, and recommendations
    for emergency fund planning integrated with current expense patterns.
    """
    def analyze_emergency_fund_readiness! do
      alias Ashfolio.FinancialManagement.EmergencyFundCalculator

      emergency_goals = by_type!(:emergency_fund)

      case EmergencyFundCalculator.calculate_monthly_expenses_from_period(12) do
        {:ok, monthly_expenses} ->
          analyze_emergency_fund_with_expenses(emergency_goals, monthly_expenses)

        {:error, reason} ->
          {:error, reason}
      end
    end

    # Helper function to reduce nesting depth
    defp analyze_emergency_fund_with_expenses([], monthly_expenses) do
      alias Ashfolio.FinancialManagement.EmergencyFundCalculator

      # No goal exists, provide recommendation to create one
      {:ok, target_amount} =
        EmergencyFundCalculator.calculate_emergency_fund_target(monthly_expenses, 6)

      {:no_goal,
       %{
         recommended_target: target_amount,
         monthly_expenses: monthly_expenses,
         months_coverage: 6,
         status: :no_goal,
         message: "No emergency fund goal set. Consider creating one."
       }}
    end

    defp analyze_emergency_fund_with_expenses([goal | _], monthly_expenses) do
      analyze_existing_emergency_fund_goal(goal, monthly_expenses)
    end

    # Helper function to reduce nesting depth
    defp analyze_existing_emergency_fund_goal(goal, monthly_expenses) do
      alias Ashfolio.FinancialManagement.EmergencyFundCalculator

      # Emergency fund status calculation (always returns {:ok, status})
      {:ok, status} =
        EmergencyFundCalculator.emergency_fund_status(
          goal.target_amount,
          goal.current_amount,
          goal.monthly_contribution || Decimal.new("0.00")
        )

      readiness_level = determine_readiness_level(status.progress_percentage, status.goal_achieved)

      months_coverage =
        if Decimal.gt?(monthly_expenses, Decimal.new("0.00")) do
          goal.target_amount |> Decimal.div(monthly_expenses) |> Decimal.round(1)
        else
          Decimal.new("0.00")
        end

      {:analysis,
       Map.merge(status, %{
         goal: goal,
         monthly_expenses: monthly_expenses,
         readiness_level: readiness_level,
         recommended_target: goal.target_amount,
         months_coverage: months_coverage
       })}
    end

    # Helper function to reduce nesting depth
    defp determine_readiness_level(progress_percentage, goal_achieved) do
      cond do
        goal_achieved ->
          :fully_funded

        Decimal.gte?(progress_percentage, Decimal.new("75.00")) ->
          :mostly_funded

        Decimal.gte?(progress_percentage, Decimal.new("25.00")) ->
          :partially_funded

        true ->
          :underfunded
      end
    end
  end
end
