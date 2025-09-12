defmodule Ashfolio.Repo.Migrations.AddCorporateActionsAndAdjustments do
  @moduledoc """
  Add corporate actions and transaction adjustments tables for v0.6.0
  """

  use Ecto.Migration

  def up do
    # Create corporate_actions table
    create table(:corporate_actions, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      # Core identification
      add :action_type, :text, null: false
      add :ex_date, :date, null: false
      add :record_date, :date
      add :pay_date, :date
      add :description, :text, null: false
      add :source, :text, default: "manual"

      # Stock split fields
      add :split_ratio_from, :decimal
      add :split_ratio_to, :decimal

      # Dividend fields  
      add :dividend_amount, :decimal
      add :dividend_currency, :text, default: "USD"
      add :qualified_dividend, :boolean, default: false

      # Merger fields
      add :merger_type, :text
      add :exchange_ratio, :decimal
      add :cash_consideration, :decimal

      # Status and audit
      add :status, :text, null: false, default: "pending"
      add :applied_at, :utc_datetime
      add :applied_by, :text
      add :reversal_reason, :text

      # Relationships
      add :symbol_id, references(:symbols, type: :uuid, on_delete: :restrict), null: false
      add :new_symbol_id, references(:symbols, type: :uuid, on_delete: :restrict)

      timestamps()
    end

    # Create transaction_adjustments table
    create table(:transaction_adjustments, primary_key: false) do
      add :id, :uuid, null: false, primary_key: true

      # Core fields
      add :adjustment_type, :text, null: false
      add :reason, :text, null: false

      # Original values
      add :original_quantity, :decimal
      add :original_price, :decimal

      # Adjusted values  
      add :adjusted_quantity, :decimal
      add :adjusted_price, :decimal

      # Dividend fields
      add :dividend_per_share, :decimal
      add :shares_eligible, :decimal
      add :total_dividend, :decimal
      add :dividend_tax_status, :text

      # FIFO and basis
      add :fifo_lot_order, :integer
      add :cost_basis_method, :text, default: "fifo"

      # Reversal support
      add :is_reversed, :boolean, null: false, default: false
      add :reversed_at, :utc_datetime
      add :reversal_reason, :text
      add :reversed_by, :text

      # Audit
      add :created_by, :text, default: "system"
      add :notes, :text

      # Relationships
      add :transaction_id, references(:transactions, type: :uuid, on_delete: :restrict),
        null: false

      add :corporate_action_id, references(:corporate_actions, type: :uuid, on_delete: :restrict),
        null: false

      timestamps()
    end

    # Create indexes for performance
    create index(:corporate_actions, [:symbol_id])
    create index(:corporate_actions, [:ex_date])
    create index(:corporate_actions, [:status])
    create index(:corporate_actions, [:action_type])

    create index(:transaction_adjustments, [:transaction_id])
    create index(:transaction_adjustments, [:corporate_action_id])
    create index(:transaction_adjustments, [:is_reversed])
    create index(:transaction_adjustments, [:adjustment_type])
    create index(:transaction_adjustments, [:fifo_lot_order])

    # Create unique constraint to prevent duplicate adjustments
    create unique_index(:transaction_adjustments, [:transaction_id, :corporate_action_id],
             name: :transaction_adjustments_unique_tx_action
           )
  end

  def down do
    drop table(:transaction_adjustments)
    drop table(:corporate_actions)
  end
end
