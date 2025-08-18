defmodule Ashfolio.Portfolio.Account do
  @moduledoc """
  Account resource for Ashfolio portfolio management.

  Represents investment accounts (e.g., Schwab, Fidelity, etc.) that hold transactions.
  Each account belongs to the single default user and can be excluded from calculations.
  """

  use Ash.Resource,
    domain: Ashfolio.Portfolio,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table("accounts")
    repo(Ashfolio.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      description("Account name (e.g., 'Schwab Brokerage', 'Fidelity 401k')")
    end

    attribute :platform, :string do
      description("Platform or broker name (e.g., 'Schwab', 'Fidelity', 'Manual')")
    end

    attribute :currency, :string do
      default("USD")
      allow_nil?(false)
      description("Account currency (USD-only in Phase 1)")
    end

    attribute :is_excluded, :boolean do
      default(false)
      allow_nil?(false)
      description("Whether to exclude this account from portfolio calculations")
    end

    attribute :balance, :decimal do
      default(Decimal.new(0))
      allow_nil?(false)
      description("Current account balance")
    end

    attribute :balance_updated_at, :utc_datetime do
      description("Timestamp when balance was last updated")
    end

    attribute :account_type, :atom do
      constraints(one_of: [:investment, :checking, :savings, :money_market, :cd])
      default(:investment)
      allow_nil?(false)
      description("Type of account - investment or cash account types")
    end

    attribute :interest_rate, :decimal do
      description(
        "Annual interest rate for savings/CD accounts (as decimal, e.g., 0.025 for 2.5%)"
      )
    end

    attribute :minimum_balance, :decimal do
      description("Minimum balance requirement for the account")
    end

    timestamps()
  end

  relationships do
    has_many :transactions, Ashfolio.Portfolio.Transaction do
      description("Transactions that occurred in this account")
    end
  end

  validations do
    validate(present(:name), message: "Account name is required")
    validate(present(:currency), message: "Currency is required")
    validate(present(:account_type), message: "Account type is required")

    # Phase 1: USD-only validation
    validate(match(:currency, ~r/^USD$/), message: "Only USD currency is supported in Phase 1")

    # Validate balance is not negative
    validate(compare(:balance, greater_than_or_equal_to: 0),
      message: "Account balance cannot be negative"
    )

    # Security: Validate maximum reasonable balance
    validate(compare(:balance, less_than_or_equal_to: Decimal.new("1000000000.00")),
      message: "Account balance cannot exceed $1,000,000,000.00 (security limit)"
    )

    # Validate name length
    validate(string_length(:name, min: 2, max: 100))

    # Validate platform length
    validate(string_length(:platform, max: 50))

    # Validate name format
    validate(match(:name, ~r/^[a-zA-Z0-9\s\-_]+$/),
      message: "Account name can only contain letters, numbers, spaces, hyphens, and underscores"
    )

    # Cash account specific validations
    validate(compare(:interest_rate, greater_than_or_equal_to: 0),
      where: present(:interest_rate),
      message: "Interest rate cannot be negative"
    )

    validate(compare(:minimum_balance, greater_than_or_equal_to: 0),
      where: present(:minimum_balance),
      message: "Minimum balance cannot be negative"
    )

    # Interest rate should only be set for savings/CD accounts
    validate(fn changeset, _context ->
      account_type = Ash.Changeset.get_attribute(changeset, :account_type)
      interest_rate = Ash.Changeset.get_attribute(changeset, :interest_rate)

      if interest_rate && account_type not in [:savings, :money_market, :cd] do
        {:error,
         field: :interest_rate,
         message: "Interest rate can only be set for savings, money market, or CD accounts"}
      else
        :ok
      end
    end)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      description("Create a new account")

      accept([
        :name,
        :platform,
        :currency,
        :is_excluded,
        :balance,
        :account_type,
        :interest_rate,
        :minimum_balance
      ])

      primary?(true)

      change(fn changeset, _context ->
        # Set balance_updated_at when creating with a balance
        if Ash.Changeset.get_attribute(changeset, :balance) do
          Ash.Changeset.change_attribute(changeset, :balance_updated_at, DateTime.utc_now())
        else
          changeset
        end
      end)
    end

    update :update do
      description("Update account attributes")

      accept([
        :name,
        :platform,
        :currency,
        :is_excluded,
        :balance,
        :account_type,
        :interest_rate,
        :minimum_balance
      ])

      primary?(true)
      require_atomic?(false)

      change(fn changeset, _context ->
        # Set balance_updated_at when balance is being updated
        if Ash.Changeset.changing_attribute?(changeset, :balance) do
          Ash.Changeset.change_attribute(changeset, :balance_updated_at, DateTime.utc_now())
        else
          changeset
        end
      end)
    end

    read :active do
      description("Returns only accounts that are not excluded from calculations")
      filter(expr(is_excluded == false))
    end


    read :by_type do
      description("Returns accounts of a specific type")
      argument(:account_type, :atom, allow_nil?: false)
      filter(expr(account_type == ^arg(:account_type)))
    end

    read :cash_accounts do
      description("Returns only cash accounts (checking, savings, money_market, cd)")
      filter(expr(account_type in [:checking, :savings, :money_market, :cd]))
    end

    read :investment_accounts do
      description("Returns only investment accounts")
      filter(expr(account_type == :investment))
    end

    update :toggle_exclusion do
      description("Toggle whether account is excluded from calculations")
      accept([:is_excluded])
      require_atomic?(false)
    end

    update :update_balance do
      description("Update account balance")
      accept([:balance])
      require_atomic?(false)

      change(fn changeset, _context ->
        # Always set balance_updated_at when updating balance
        Ash.Changeset.change_attribute(changeset, :balance_updated_at, DateTime.utc_now())
      end)
    end
  end

  code_interface do
    domain(Ashfolio.Portfolio)

    define(:create, action: :create)
    define(:list, action: :read)
    define(:get_by_id, action: :read, get_by: [:id])
    define(:active_accounts, action: :active)
    define(:accounts_by_type, action: :by_type, args: [:account_type])
    define(:cash_accounts, action: :cash_accounts)
    define(:investment_accounts, action: :investment_accounts)
    define(:update, action: :update)
    define(:toggle_exclusion, action: :toggle_exclusion)
    define(:update_balance, action: :update_balance)
    define(:destroy, action: :destroy)

    def get_by_name(name) do
      require Ash.Query

      Ashfolio.Portfolio.Account
      |> Ash.Query.filter(name: name)
      |> Ash.read_first()
    end
  end
end
