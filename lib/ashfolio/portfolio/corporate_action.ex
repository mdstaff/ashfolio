defmodule Ashfolio.Portfolio.CorporateAction do
  @moduledoc """
  Corporate Action resource for tracking stock splits, dividends, mergers, and other corporate events.

  This resource maintains immutable records of corporate actions and provides the foundation
  for transaction adjustments that preserve FIFO cost basis integrity while reflecting
  the economic reality of corporate events.
  """

  use Ash.Resource,
    domain: Ashfolio.Portfolio,
    data_layer: AshSqlite.DataLayer

  import Ash.Expr

  alias Ashfolio.Portfolio.Symbol

  sqlite do
    table("corporate_actions")
    repo(Ashfolio.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    # Core identification
    attribute :action_type, :atom do
      constraints(one_of: [:stock_split, :cash_dividend, :stock_dividend, :merger, :spinoff, :return_of_capital])
      allow_nil?(false)
      description("Type of corporate action")
    end

    # Date information
    attribute :ex_date, :date do
      allow_nil?(false)
      description("Ex-dividend/ex-split date - when the action takes effect")
    end

    attribute :record_date, :date do
      allow_nil?(true)
      description("Record date - who is eligible for the action")
    end

    attribute :pay_date, :date do
      allow_nil?(true)
      description("Payment date for dividends")
    end

    # Description and documentation
    attribute :description, :string do
      constraints(max_length: 500)
      allow_nil?(false)
      description("Human-readable description of the corporate action")
    end

    attribute :source, :string do
      constraints(max_length: 100)
      default("manual")
      description("Source of the corporate action data (e.g., 'yahoo_finance', 'manual', 'broker')")
    end

    # Stock split specific fields
    attribute :split_ratio_from, :decimal do
      allow_nil?(true)
      description("Split ratio from (e.g., 1 in a 2:1 split)")
    end

    attribute :split_ratio_to, :decimal do
      allow_nil?(true)
      description("Split ratio to (e.g., 2 in a 2:1 split)")
    end

    # Dividend specific fields
    attribute :dividend_amount, :decimal do
      allow_nil?(true)
      description("Dividend amount per share")
    end

    attribute :dividend_currency, :string do
      constraints(max_length: 3)
      default("USD")
      allow_nil?(true)
      description("Currency of dividend payment")
    end

    attribute :qualified_dividend, :boolean do
      default(false)
      allow_nil?(true)
      description("Whether dividend qualifies for preferential tax treatment")
    end

    # Merger/acquisition specific fields
    attribute :merger_type, :atom do
      constraints(one_of: [:stock_for_stock, :cash_for_stock, :mixed_consideration])
      allow_nil?(true)
      description("Type of merger or acquisition")
    end

    attribute :exchange_ratio, :decimal do
      allow_nil?(true)
      description("Exchange ratio for mergers (e.g., 1.5 new shares per old share)")
    end

    attribute :cash_consideration, :decimal do
      allow_nil?(true)
      description("Cash component in mixed consideration mergers")
    end

    # Status and processing
    attribute :status, :atom do
      constraints(one_of: [:pending, :applied, :reversed, :cancelled])
      default(:pending)
      allow_nil?(false)
      description("Processing status of the corporate action")
    end

    # Audit and tracking fields
    attribute :applied_at, :utc_datetime do
      allow_nil?(true)
      description("When the corporate action was applied")
    end

    attribute :applied_by, :string do
      constraints(max_length: 100)
      allow_nil?(true)
      description("Who or what applied the corporate action")
    end

    attribute :reversal_reason, :string do
      constraints(max_length: 500)
      allow_nil?(true)
      description("Reason for reversing the corporate action")
    end

    timestamps()
  end

  relationships do
    belongs_to :symbol, Symbol do
      allow_nil?(false)
      description("The symbol affected by this action")
    end

    belongs_to :new_symbol, Symbol do
      allow_nil?(true)
      description("New symbol in case of merger/conversion")
    end

    has_many :transaction_adjustments, Ashfolio.Portfolio.TransactionAdjustment do
      destination_attribute(:corporate_action_id)
    end
  end

  validations do
    validate(present(:action_type), message: "Action type is required")
    validate(present(:symbol_id), message: "Symbol is required")
    validate(present(:ex_date), message: "Ex-date is required")
    validate(present(:description), message: "Description is required")

    # Conditional validations based on action type
    validate(fn changeset, _context ->
      action_type = Ash.Changeset.get_attribute(changeset, :action_type)

      case action_type do
        :stock_split ->
          # Validate split ratios for stock splits
          from_ratio = Ash.Changeset.get_attribute(changeset, :split_ratio_from)
          to_ratio = Ash.Changeset.get_attribute(changeset, :split_ratio_to)

          cond do
            is_nil(from_ratio) ->
              {:error, field: :split_ratio_from, message: "Split ratio from is required for stock splits"}

            is_nil(to_ratio) ->
              {:error, field: :split_ratio_to, message: "Split ratio to is required for stock splits"}

            not positive_decimal?(from_ratio) ->
              {:error, field: :split_ratio_from, message: "Split ratio from must be positive"}

            not positive_decimal?(to_ratio) ->
              {:error, field: :split_ratio_to, message: "Split ratio to must be positive"}

            true ->
              :ok
          end

        type when type in [:cash_dividend, :stock_dividend, :return_of_capital] ->
          # Validate dividend amount for dividend actions
          amount = Ash.Changeset.get_attribute(changeset, :dividend_amount)

          cond do
            is_nil(amount) ->
              {:error, field: :dividend_amount, message: "Dividend amount is required for #{type}"}

            not positive_decimal?(amount) ->
              {:error, field: :dividend_amount, message: "Dividend amount must be positive"}

            true ->
              :ok
          end

        :merger ->
          # Validate merger fields
          exchange_ratio = Ash.Changeset.get_attribute(changeset, :exchange_ratio)
          cash = Ash.Changeset.get_attribute(changeset, :cash_consideration)

          cond do
            is_nil(exchange_ratio) && is_nil(cash) ->
              {:error, message: "Merger must have either exchange ratio or cash consideration"}

            not is_nil(exchange_ratio) && not positive_decimal?(exchange_ratio) ->
              {:error, field: :exchange_ratio, message: "Exchange ratio must be positive"}

            not is_nil(cash) && not non_negative_decimal?(cash) ->
              {:error, field: :cash_consideration, message: "Cash consideration cannot be negative"}

            true ->
              :ok
          end

        _ ->
          :ok
      end
    end)

    # Custom validation for future ex_date with applied status
    validate(fn changeset, _context ->
      status = Ash.Changeset.get_attribute(changeset, :status)
      ex_date = Ash.Changeset.get_attribute(changeset, :ex_date)

      if status == :applied && ex_date && Date.after?(ex_date, Date.utc_today()) do
        {:error, field: :ex_date, message: "Ex-date cannot be in the future for applied actions"}
      else
        :ok
      end
    end)
  end

  actions do
    defaults([:read, :destroy])

    update :update do
      description("Update corporate action (limited fields)")
      primary?(true)
      require_atomic?(false)

      accept([:status, :applied_at, :applied_by, :reversal_reason])
    end

    create :create do
      description("Create a new corporate action")
      primary?(true)

      accept([
        :action_type,
        :symbol_id,
        :ex_date,
        :record_date,
        :pay_date,
        :description,
        :source,
        :split_ratio_from,
        :split_ratio_to,
        :dividend_amount,
        :dividend_currency,
        :qualified_dividend,
        :merger_type,
        :new_symbol_id,
        :exchange_ratio,
        :cash_consideration,
        :status,
        :applied_at,
        :applied_by,
        :reversal_reason
      ])
    end

    update :apply do
      description("Mark corporate action as applied")
      accept([:applied_by])
      require_atomic?(false)

      change(set_attribute(:status, :applied))
      change(set_attribute(:applied_at, &DateTime.utc_now/0))
    end

    update :reverse do
      description("Reverse a corporate action")
      accept([:reversal_reason])
      require_atomic?(false)

      change(set_attribute(:status, :reversed))
    end

    read :by_symbol do
      description("Find corporate actions by symbol")
      argument(:symbol_id, :uuid, allow_nil?: false)

      filter(expr(symbol_id == ^arg(:symbol_id)))
      prepare(build(sort: [ex_date: :desc]))
    end

    read :by_date_range do
      description("Find corporate actions within date range")
      argument(:start_date, :date, allow_nil?: false)
      argument(:end_date, :date, allow_nil?: false)

      filter(expr(ex_date >= ^arg(:start_date) and ex_date <= ^arg(:end_date)))
      prepare(build(sort: [ex_date: :desc]))
    end

    read :pending do
      description("Find pending corporate actions that need processing")

      filter(expr(status == :pending and ex_date <= ^Date.utc_today()))
      prepare(build(sort: [ex_date: :asc]))
    end

    read :by_status do
      description("Find corporate actions by status")
      argument(:status, :atom, allow_nil?: false)

      filter(expr(status == ^arg(:status)))
      prepare(build(sort: [ex_date: :desc]))
    end
  end

  code_interface do
    domain(Ashfolio.Portfolio)
    define(:create)
    define(:read)
    define(:update)
    define(:apply, args: [:applied_by])
    define(:reverse, args: [:reversal_reason])
    define(:destroy)
    define(:by_symbol, args: [:symbol_id])
    define(:by_date_range, args: [:start_date, :end_date])
    define(:pending)
    define(:by_status, args: [:status])
  end

  # Private helper functions for validations
  defp positive_decimal?(nil), do: false

  defp positive_decimal?(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, ""} -> Decimal.compare(decimal, 0) == :gt
      _ -> false
    end
  end

  defp positive_decimal?(%Decimal{} = value), do: Decimal.compare(value, 0) == :gt
  defp positive_decimal?(_), do: false

  defp non_negative_decimal?(nil), do: false

  defp non_negative_decimal?(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, ""} -> Decimal.compare(decimal, 0) != :lt
      _ -> false
    end
  end

  defp non_negative_decimal?(%Decimal{} = value), do: Decimal.compare(value, 0) != :lt
  defp non_negative_decimal?(_), do: false
end
