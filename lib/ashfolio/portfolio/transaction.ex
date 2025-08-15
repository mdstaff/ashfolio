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
      constraints(
        one_of: [:buy, :sell, :dividend, :fee, :interest, :liability, :deposit, :withdrawal]
      )

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

    read :by_accounts do
      description("Get transactions for multiple accounts (prevents N+1 queries)")
      argument(:account_ids, {:array, :uuid}, allow_nil?: false)
      filter(expr(account_id in ^arg(:account_ids)))
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

    read :for_user_by_category do
      description("Get transactions for a user filtered by category (optimized)")
      argument(:user_id, :uuid, allow_nil?: false)
      argument(:category_id, :uuid, allow_nil?: false)

      prepare(fn query, _context ->
        user_id = Ash.Query.get_argument(query, :user_id)
        category_id = Ash.Query.get_argument(query, :category_id)

        query
        |> Ash.Query.filter(expr(account.user_id == ^user_id and category_id == ^category_id))
        |> Ash.Query.load(:account)
        |> Ash.Query.sort(date: :desc)
      end)
    end

    read :for_user_by_date_range do
      description("Get transactions for a user within date range (optimized)")
      argument(:user_id, :uuid, allow_nil?: false)
      argument(:start_date, :date, allow_nil?: false)
      argument(:end_date, :date, allow_nil?: false)

      prepare(fn query, _context ->
        user_id = Ash.Query.get_argument(query, :user_id)
        start_date = Ash.Query.get_argument(query, :start_date)
        end_date = Ash.Query.get_argument(query, :end_date)

        query
        |> Ash.Query.filter(
          expr(account.user_id == ^user_id and date >= ^start_date and date <= ^end_date)
        )
        |> Ash.Query.load(:account)
        |> Ash.Query.sort(date: :desc)
      end)
    end

    read :for_account do
      description("Get transactions for specific account (optimized)")
      argument(:account_id, :uuid, allow_nil?: false)

      prepare(fn query, _context ->
        account_id = Ash.Query.get_argument(query, :account_id)

        query
        |> Ash.Query.filter(expr(account_id == ^account_id))
        |> Ash.Query.sort(date: :desc)
      end)
    end

    read :for_user_with_filters do
      description("Get transactions for user with multiple filter criteria (optimized)")
      argument(:user_id, :uuid, allow_nil?: false)
      argument(:account_id, :uuid, allow_nil?: true)
      argument(:category_id, :uuid, allow_nil?: true)
      argument(:start_date, :date, allow_nil?: true)
      argument(:end_date, :date, allow_nil?: true)
      argument(:transaction_type, :atom, allow_nil?: true)

      prepare(fn query, _context ->
        user_id = Ash.Query.get_argument(query, :user_id)
        account_id = Ash.Query.get_argument(query, :account_id)
        category_id = Ash.Query.get_argument(query, :category_id)
        start_date = Ash.Query.get_argument(query, :start_date)
        end_date = Ash.Query.get_argument(query, :end_date)
        transaction_type = Ash.Query.get_argument(query, :transaction_type)

        query = Ash.Query.filter(query, expr(account.user_id == ^user_id))

        query =
          if account_id do
            Ash.Query.filter(query, expr(account_id == ^account_id))
          else
            query
          end

        query =
          if category_id do
            Ash.Query.filter(query, expr(category_id == ^category_id))
          else
            query
          end

        query =
          if start_date do
            Ash.Query.filter(query, expr(date >= ^start_date))
          else
            query
          end

        query =
          if end_date do
            Ash.Query.filter(query, expr(date <= ^end_date))
          else
            query
          end

        query =
          if transaction_type do
            Ash.Query.filter(query, expr(type == ^transaction_type))
          else
            query
          end

        query
        |> Ash.Query.load(:account)
        |> Ash.Query.sort(date: :desc)
      end)
    end

    read :for_user_sorted do
      description("Get transactions for user with sorting options")
      argument(:user_id, :uuid, allow_nil?: false)
      argument(:sort_field, :atom, allow_nil?: false)
      argument(:sort_direction, :atom, allow_nil?: false)
      argument(:limit, :integer, allow_nil?: true)

      prepare(fn query, _context ->
        user_id = Ash.Query.get_argument(query, :user_id)
        sort_field = Ash.Query.get_argument(query, :sort_field)
        sort_direction = Ash.Query.get_argument(query, :sort_direction)
        limit = Ash.Query.get_argument(query, :limit)

        query =
          query
          |> Ash.Query.filter(expr(account.user_id == ^user_id))
          |> Ash.Query.load(:account)

        # Apply sorting
        query =
          case sort_field do
            :date -> Ash.Query.sort(query, [{:date, sort_direction}])
            :amount -> Ash.Query.sort(query, [{:total_amount, sort_direction}])
            :symbol -> Ash.Query.sort(query, [{:symbol, sort_direction}])
            _ -> Ash.Query.sort(query, [{:date, sort_direction}])
          end

        # Apply limit if specified
        if limit do
          Ash.Query.limit(query, limit)
        else
          query
        end
      end)
    end

    read :for_user_paginated do
      description("Get paginated transactions for user")
      argument(:user_id, :uuid, allow_nil?: false)
      argument(:page, :integer, allow_nil?: false)
      argument(:page_size, :integer, allow_nil?: false)

      prepare(fn query, _context ->
        user_id = Ash.Query.get_argument(query, :user_id)
        page = Ash.Query.get_argument(query, :page)
        page_size = Ash.Query.get_argument(query, :page_size)

        offset = (page - 1) * page_size

        query
        |> Ash.Query.filter(expr(account.user_id == ^user_id))
        |> Ash.Query.load(:account)
        |> Ash.Query.sort(date: :desc)
        |> Ash.Query.limit(page_size)
        |> Ash.Query.offset(offset)
      end)
    end
  end

  code_interface do
    domain(Ashfolio.Portfolio)

    define(:create, action: :create)
    define(:list, action: :read)
    define(:get_by_id, action: :read, get_by: [:id])
    define(:by_account, action: :by_account, args: [:account_id])
    define(:by_accounts, action: :by_accounts, args: [:account_ids])
    define(:by_symbol, action: :by_symbol, args: [:symbol_id])
    define(:by_type, action: :by_type, args: [:type])
    define(:by_category, action: :by_category, args: [:category_id])
    define(:uncategorized_transactions, action: :uncategorized)
    define(:by_date_range, action: :by_date_range, args: [:start_date, :end_date])
    define(:recent_transactions, action: :recent)
    define(:holdings_data, action: :holdings)
    define(:update, action: :update)
    define(:destroy, action: :destroy)

    # New optimized filtering functions for performance tests
    define(:list_for_user_by_category,
      action: :for_user_by_category,
      args: [:user_id, :category_id]
    )

    define(:list_for_user_by_date_range,
      action: :for_user_by_date_range,
      args: [:user_id, :start_date, :end_date]
    )

    define(:list_for_account, action: :for_account, args: [:account_id])
    define(:list_for_user_with_filters, action: :for_user_with_filters)
    define(:list_for_user_sorted, action: :for_user_sorted)

    define(:list_for_user_paginated,
      action: :for_user_paginated,
      args: [:user_id, :page, :page_size]
    )
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

      type == :deposit and (is_nil(quantity) or Decimal.compare(quantity, 0) != :gt) ->
        Ash.Changeset.add_error(changeset,
          field: :quantity,
          message: "Quantity must be positive for deposit transactions"
        )

      type == :withdrawal and (is_nil(quantity) or Decimal.compare(quantity, 0) != :lt) ->
        Ash.Changeset.add_error(changeset,
          field: :quantity,
          message: "Quantity must be negative for withdrawal transactions"
        )

      true ->
        changeset
    end
  end
end
