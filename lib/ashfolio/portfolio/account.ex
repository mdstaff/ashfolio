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

    timestamps()
  end

  relationships do
    belongs_to :user, Ashfolio.Portfolio.User do
      allow_nil?(false)
      description("The user who owns this account")
    end

    has_many :transactions, Ashfolio.Portfolio.Transaction do
      description("Transactions that occurred in this account")
    end
  end

  validations do
    validate(present(:name), message: "Account name is required")
    validate(present(:currency), message: "Currency is required")

    # Phase 1: USD-only validation
    validate(match(:currency, ~r/^USD$/), message: "Only USD currency is supported in Phase 1")

    # Validate balance is not negative
    validate(compare(:balance, greater_than_or_equal_to: 0),
      message: "Account balance cannot be negative"
    )

    # Validate name length
    validate(string_length(:name, min: 2, max: 100))

    # Validate platform length
    validate(string_length(:platform, max: 50))

    # Validate name format
    validate(match(:name, ~r/^[a-zA-Z0-9\s\-_]+$/),
      message: "Account name can only contain letters, numbers, spaces, hyphens, and underscores"
    )
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      description("Create a new account")
      accept([:name, :platform, :currency, :is_excluded, :balance, :user_id])
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
      accept([:name, :platform, :currency, :is_excluded, :balance])
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

    read :by_user do
      description("Returns accounts for a specific user")
      argument(:user_id, :uuid, allow_nil?: false)
      filter(expr(user_id == ^arg(:user_id)))
    end

    update :toggle_exclusion do
      description("Toggle whether account is excluded from calculations")
      accept([:is_excluded])
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
    define(:accounts_for_user, action: :by_user, args: [:user_id])
    define(:update, action: :update)
    define(:toggle_exclusion, action: :toggle_exclusion)
    define(:update_balance, action: :update_balance)
    define(:destroy, action: :destroy)

    def get_by_name_for_user(user_id, name) do
      require Ash.Query

      Ashfolio.Portfolio.Account
      |> Ash.Query.filter(user_id: user_id, name: name)
      |> Ash.read_first()
    end
  end
end
