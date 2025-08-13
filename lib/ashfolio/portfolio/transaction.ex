defmodule Ashfolio.Portfolio.Transaction do
  @moduledoc """
  Transaction resource for Ashfolio portfolio management.

  Represents financial transactions (buy, sell, dividend, fee) that occur within accounts.
  Each transaction is linked to an account and symbol, forming the core of portfolio tracking.
  """

  use Ash.Resource,
    domain: Ashfolio.Portfolio,
    data_layer: AshSqlite.DataLayer

  require Ash.Query

  sqlite do
    table("transactions")
    repo(Ashfolio.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :type, :atom do
      constraints(one_of: [:buy, :sell, :dividend, :fee, :interest, :liability])
      allow_nil?(false)
      description("Transaction type")
    end

    attribute :quantity, :decimal do
      allow_nil?(false)
      description("Number of shares/units (positive for buy/dividend, negative for sell)")
    end

    attribute :price, :decimal do
      allow_nil?(false)
      description("Price per share/unit in USD")
    end

    attribute :total_amount, :decimal do
      allow_nil?(false)
      description("Total transaction amount (quantity * price + fees)")
    end

    attribute :fee, :decimal do
      default(Decimal.new(0))
      allow_nil?(false)
      description("Transaction fee in USD")
    end

    attribute :date, :date do
      allow_nil?(false)
      description("Transaction date")
    end

    attribute :notes, :string do
      description("Optional notes about the transaction")
      # Security: Limit notes to 500 characters
      constraints(max_length: 500)
    end

    timestamps()
  end

  relationships do
    belongs_to :account, Ashfolio.Portfolio.Account do
      allow_nil?(false)
      description("The account where this transaction occurred")
    end

    belongs_to :symbol, Ashfolio.Portfolio.Symbol do
      allow_nil?(false)
      description("The symbol/security involved in this transaction")
    end

    belongs_to :category, Ashfolio.FinancialManagement.TransactionCategory do
      allow_nil?(true)
      description("Optional category for investment organization")
    end
  end

  validations do
    validate(present(:type), message: "Transaction type is required")
    validate(present(:quantity), message: "Quantity is required")
    validate(present(:price), message: "Price is required")
    validate(present(:total_amount), message: "Total amount is required")
    validate(present(:date), message: "Transaction date is required")

    # Price must be non-negative (can be 0 for fee transactions)
    validate(compare(:price, greater_than_or_equal_to: 0),
      message: "Price cannot be negative"
    )

    # Fee must be non-negative
    validate(compare(:fee, greater_than_or_equal_to: 0),
      message: "Fee cannot be negative"
    )

    # Date cannot be in the future
    validate(fn changeset, _context ->
      date = Ash.Changeset.get_attribute(changeset, :date)

      if date && Date.compare(date, Date.utc_today()) == :gt do
        {:error, field: :date, message: "Transaction date cannot be in the future"}
      else
        :ok
      end
    end)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      description("Create a new transaction")

      accept([
        :type,
        :quantity,
        :price,
        :total_amount,
        :fee,
        :date,
        :notes,
        :account_id,
        :symbol_id,
        :category_id
      ])

      primary?(true)

      change(fn changeset, _context ->
        validate_quantity_for_type(changeset)
      end)
    end

    update :update do
      description("Update transaction details")
      accept([:type, :quantity, :price, :total_amount, :fee, :date, :notes, :category_id])
      primary?(true)
      require_atomic?(false)

      change(fn changeset, _context ->
        validate_quantity_for_type(changeset)
      end)
    end

    read :by_account do
      description("Get transactions for a specific account")
      argument(:account_id, :uuid, allow_nil?: false)
      filter(expr(account_id == ^arg(:account_id)))
    end

    read :by_symbol do
      description("Get transactions for a specific symbol")
      argument(:symbol_id, :uuid, allow_nil?: false)
      filter(expr(symbol_id == ^arg(:symbol_id)))
    end

    read :by_type do
      description("Get transactions by type")
      argument(:type, :atom, allow_nil?: false)
      filter(expr(type == ^arg(:type)))
    end

    read :by_category do
      description("Get transactions for a specific category")
      argument(:category_id, :uuid, allow_nil?: false)
      filter(expr(category_id == ^arg(:category_id)))
    end

    read :uncategorized do
      description("Get transactions without a category")
      filter(expr(is_nil(category_id)))
    end

    read :by_date_range do
      description("Get transactions within a date range")
      argument(:start_date, :date, allow_nil?: false)
      argument(:end_date, :date, allow_nil?: false)

      prepare(fn query, _context ->
        start_date = Ash.Query.get_argument(query, :start_date)
        end_date = Ash.Query.get_argument(query, :end_date)

        Ash.Query.filter(query, expr(date >= ^start_date and date <= ^end_date))
      end)
    end

    read :recent do
      description("Get recent transactions (last 30 days)")

      prepare(fn query, _context ->
        thirty_days_ago = Date.utc_today() |> Date.add(-30)
        Ash.Query.filter(query, expr(date >= ^thirty_days_ago))
      end)
    end

    read :holdings do
      description("Calculate current holdings by symbol for portfolio calculations")

      prepare(fn query, _context ->
        # Group by symbol and sum quantities for buy/sell transactions
        # This will be used for portfolio calculations
        query
        |> Ash.Query.filter(expr(type in [:buy, :sell]))
        |> Ash.Query.sort(date: :desc)
      end)
    end
  end

  code_interface do
    domain(Ashfolio.Portfolio)

    define(:create, action: :create)
    define(:list, action: :read)
    define(:get_by_id, action: :read, get_by: [:id])
    define(:by_account, action: :by_account, args: [:account_id])
    define(:by_symbol, action: :by_symbol, args: [:symbol_id])
    define(:by_type, action: :by_type, args: [:type])
    define(:by_category, action: :by_category, args: [:category_id])
    define(:uncategorized_transactions, action: :uncategorized)
    define(:by_date_range, action: :by_date_range, args: [:start_date, :end_date])
    define(:recent_transactions, action: :recent)
    define(:holdings_data, action: :holdings)
    define(:update, action: :update)
    define(:destroy, action: :destroy)
  end

  # Custom validation function for quantity based on transaction type
  defp validate_quantity_for_type(changeset) do
    type = Ash.Changeset.get_attribute(changeset, :type)
    quantity = Ash.Changeset.get_attribute(changeset, :quantity)

    cond do
      type == :buy and (is_nil(quantity) or Decimal.compare(quantity, 0) != :gt) ->
        Ash.Changeset.add_error(changeset,
          field: :quantity,
          message: "Quantity must be positive for buy transactions"
        )

      type == :sell and (is_nil(quantity) or Decimal.compare(quantity, 0) != :lt) ->
        Ash.Changeset.add_error(changeset,
          field: :quantity,
          message: "Quantity must be negative for sell transactions"
        )

      type == :dividend and (is_nil(quantity) or Decimal.compare(quantity, 0) != :gt) ->
        Ash.Changeset.add_error(changeset,
          field: :quantity,
          message: "Quantity must be positive for dividend transactions"
        )

      type == :interest and (is_nil(quantity) or Decimal.compare(quantity, 0) != :gt) ->
        Ash.Changeset.add_error(changeset,
          field: :quantity,
          message: "Quantity must be positive for interest transactions"
        )

      type == :liability and (is_nil(quantity) or Decimal.compare(quantity, 0) != :lt) ->
        Ash.Changeset.add_error(changeset,
          field: :quantity,
          message: "Quantity must be negative for liability transactions"
        )

      type == :fee and not is_nil(quantity) and Decimal.compare(quantity, 0) == :lt ->
        Ash.Changeset.add_error(changeset,
          field: :quantity,
          message: "Quantity cannot be negative for fee transactions"
        )

      true ->
        changeset
    end
  end
end
