defmodule Ashfolio.Portfolio.TransactionAdjustment do
  @moduledoc """
  Transaction Adjustment resource for tracking modifications to transactions due to corporate actions.

  This resource maintains an immutable audit trail of how corporate actions affect individual
  transactions while preserving the original transaction data and ensuring FIFO cost basis
  integrity is maintained throughout the adjustment process.
  """

  use Ash.Resource,
    domain: Ashfolio.Portfolio,
    data_layer: AshSqlite.DataLayer

  import Ash.Expr

  sqlite do
    table("transaction_adjustments")
    repo(Ashfolio.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    # Adjustment classification
    attribute :adjustment_type, :atom do
      constraints(one_of: [:quantity_price, :cash_receipt, :symbol_change, :basis_adjustment, :lot_split])
      allow_nil?(false)
      description("Type of adjustment being made")
    end

    attribute :reason, :string do
      constraints(max_length: 500)
      allow_nil?(false)
      description("Human-readable explanation of the adjustment")
    end

    # Original transaction values (for audit trail)
    attribute :original_quantity, :decimal do
      allow_nil?(true)
      description("Original quantity before adjustment")
    end

    attribute :original_price, :decimal do
      allow_nil?(true)
      description("Original price before adjustment")
    end

    # Adjusted transaction values
    attribute :adjusted_quantity, :decimal do
      allow_nil?(true)
      description("New quantity after adjustment")
    end

    attribute :adjusted_price, :decimal do
      allow_nil?(true)
      description("New price after adjustment")
    end

    # Dividend-specific fields
    attribute :dividend_per_share, :decimal do
      allow_nil?(true)
      description("Dividend amount per share")
    end

    attribute :shares_eligible, :decimal do
      allow_nil?(true)
      description("Number of shares eligible for dividend")
    end

    attribute :total_dividend, :decimal do
      allow_nil?(true)
      description("Total dividend received (shares × dividend per share)")
    end

    attribute :dividend_tax_status, :atom do
      constraints(one_of: [:qualified, :ordinary, :return_of_capital, :capital_gain])
      allow_nil?(true)
      description("Tax classification of dividend")
    end

    # FIFO and cost basis preservation
    attribute :fifo_lot_order, :integer do
      allow_nil?(true)
      description("FIFO ordering sequence for this adjustment")
    end

    attribute :cost_basis_method, :atom do
      constraints(one_of: [:fifo, :lifo, :average_cost, :specific_identification])
      default(:fifo)
      description("Cost basis calculation method used")
    end

    # Reversal and correction support
    attribute :is_reversed, :boolean do
      default(false)
      allow_nil?(false)
      description("Whether this adjustment has been reversed")
    end

    attribute :reversed_at, :utc_datetime do
      allow_nil?(true)
      description("When this adjustment was reversed")
    end

    attribute :reversal_reason, :string do
      constraints(max_length: 500)
      allow_nil?(true)
      description("Reason for reversing this adjustment")
    end

    attribute :reversed_by, :string do
      constraints(max_length: 100)
      allow_nil?(true)
      description("Who reversed this adjustment")
    end

    # Audit trail
    attribute :created_by, :string do
      constraints(max_length: 100)
      default("system")
      description("Who or what created this adjustment")
    end

    attribute :notes, :string do
      constraints(max_length: 1000)
      allow_nil?(true)
      description("Additional notes about this adjustment")
    end

    timestamps()
  end

  relationships do
    belongs_to :transaction, Ashfolio.Portfolio.Transaction do
      allow_nil?(false)
      description("The transaction being adjusted")
    end

    belongs_to :corporate_action, Ashfolio.Portfolio.CorporateAction do
      allow_nil?(false)
      description("The corporate action causing this adjustment")
    end
  end

  validations do
    validate(present(:transaction_id), message: "Transaction is required")
    validate(present(:corporate_action_id), message: "Corporate action is required")
    validate(present(:adjustment_type), message: "Adjustment type is required")
    validate(present(:reason), message: "Reason is required")

    # Basic positive number validations
    validate(compare(:adjusted_quantity, greater_than: 0),
      message: "Adjusted quantity must be positive"
    )

    validate(compare(:dividend_per_share, greater_than: 0),
      message: "Dividend per share must be positive"
    )

    validate(compare(:shares_eligible, greater_than: 0),
      message: "Eligible shares must be positive"
    )

    validate(compare(:total_dividend, greater_than_or_equal_to: 0),
      message: "Total dividend cannot be negative"
    )

    # Value preservation validation for quantity/price adjustments
    validate(fn changeset, _context ->
      adjustment_type = Ash.Changeset.get_attribute(changeset, :adjustment_type)

      if adjustment_type == :quantity_price do
        original_qty = Ash.Changeset.get_attribute(changeset, :original_quantity)
        original_price = Ash.Changeset.get_attribute(changeset, :original_price)
        adjusted_qty = Ash.Changeset.get_attribute(changeset, :adjusted_quantity)
        adjusted_price = Ash.Changeset.get_attribute(changeset, :adjusted_price)

        if original_qty && original_price && adjusted_qty && adjusted_price do
          original_value = Decimal.mult(original_qty, original_price)
          adjusted_value = Decimal.mult(adjusted_qty, adjusted_price)

          # Allow for small rounding differences (0.01%)
          tolerance = Decimal.mult(original_value, Decimal.new("0.0001"))
          diff = Decimal.abs(Decimal.sub(original_value, adjusted_value))

          if Decimal.compare(diff, tolerance) == :gt do
            {:error, field: :adjusted_price, message: "Total value must be preserved in quantity/price adjustments"}
          else
            :ok
          end
        else
          :ok
        end
      else
        :ok
      end
    end)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      description("Create a new transaction adjustment")
      primary?(true)

      accept([
        :adjustment_type,
        :reason,
        :original_quantity,
        :original_price,
        :adjusted_quantity,
        :adjusted_price,
        :dividend_per_share,
        :shares_eligible,
        :total_dividend,
        :dividend_tax_status,
        :fifo_lot_order,
        :cost_basis_method,
        :created_by,
        :notes,
        :transaction_id,
        :corporate_action_id
      ])
    end

    update :update do
      description("Update transaction adjustment - limited to audit fields only")
      primary?(true)
      require_atomic?(false)

      # Only allow updating audit/reversal fields, not core adjustment data
      accept([
        :notes,
        :is_reversed,
        :reversed_at,
        :reversal_reason,
        :reversed_by
      ])
    end

    update :reverse do
      description("Reverse this adjustment")
      accept([:reversal_reason, :reversed_by])
      require_atomic?(false)

      change(set_attribute(:is_reversed, true))
      change(set_attribute(:reversed_at, &DateTime.utc_now/0))
    end

    read :by_transaction do
      description("Find all adjustments for a specific transaction")
      argument(:transaction_id, :uuid, allow_nil?: false)

      filter(expr(transaction_id == ^arg(:transaction_id)))
      prepare(build(sort: [inserted_at: :asc]))
    end

    read :by_corporate_action do
      description("Find all adjustments for a specific corporate action")
      argument(:corporate_action_id, :uuid, allow_nil?: false)

      filter(expr(corporate_action_id == ^arg(:corporate_action_id)))
      prepare(build(sort: [fifo_lot_order: :asc, inserted_at: :asc]))
    end

    read :active do
      description("Find active (non-reversed) adjustments")

      filter(expr(is_reversed == false))
      prepare(build(sort: [inserted_at: :desc]))
    end

    read :reversed do
      description("Find reversed adjustments")

      filter(expr(is_reversed == true))
      prepare(build(sort: [reversed_at: :desc]))
    end
  end

  code_interface do
    domain(Ashfolio.Portfolio)
    define(:create)
    define(:read)
    define(:update)
    define(:reverse, args: [:reversal_reason, :reversed_by])
    define(:destroy)
    define(:by_transaction, args: [:transaction_id])
    define(:by_corporate_action, args: [:corporate_action_id])
    define(:active)
    define(:reversed)
  end
end
