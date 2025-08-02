defmodule Ashfolio.Portfolio.User do
  @moduledoc """
  User resource for Ashfolio portfolio management.

  This represents a single default user for the local application.
  No registration/login required - user is automatically created on first startup.
  """

  use Ash.Resource,
    domain: Ashfolio.Portfolio,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "users"
    repo Ashfolio.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      default "Local User"
      allow_nil? false
    end

    attribute :currency, :string do
      default "USD"
      allow_nil? false
    end

    attribute :locale, :string do
      default "en-US"
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    has_many :accounts, Ashfolio.Portfolio.Account

    # Will be added when Transaction resource is implemented
    # has_many :transactions, Ashfolio.Portfolio.Transaction
  end

  validations do
    validate present(:name), message: "Name is required"
    validate present(:currency), message: "Currency is required"
    validate present(:locale), message: "Locale is required"

    # Phase 1: USD-only validation
    validate match(:currency, ~r/^USD$/), message: "Only USD currency is supported in Phase 1"
  end

  actions do
    defaults [:read, :update]

    # Create action for seeding the default user
    create :create do
      description "Create the default user (used only for seeding)"
      accept [:name, :currency, :locale]
      primary? true
    end

    read :default_user do
      description "Returns the single local user"

      prepare fn query, _context ->
        # Always return the first (and only) user
        Ash.Query.limit(query, 1)
      end
    end

    update :update_preferences do
      description "Update user preferences like name and locale"
      accept [:name, :locale]
    end
  end

  code_interface do
    domain Ashfolio.Portfolio

    define :create, action: :create
    define :get_default_user, action: :default_user
    define :update_preferences, action: :update_preferences
  end
end
