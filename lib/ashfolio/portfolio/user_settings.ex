defmodule Ashfolio.Portfolio.UserSettings do
  @moduledoc """
  Singleton UserSettings resource for database-as-user architecture.

  This represents user preferences and settings for the single-user application.
  Each SQLite database contains exactly one UserSettings record representing
  the "user" of that database file.

  ## Database-as-User Architecture

  In this design:
  - Each SQLite database file = one user's complete portfolio
  - No user_id foreign keys needed anywhere
  - All data in the database belongs to "the user"
  - UserSettings stores user preferences (name, currency, locale)
  """

  use Ash.Resource,
    domain: Ashfolio.Portfolio,
    data_layer: AshSqlite.DataLayer

  alias Ashfolio.Portfolio.UserSettings

  sqlite do
    table("user_settings")
    repo(Ashfolio.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      default("Local User")
      allow_nil?(false)
      description("Display name for the user")
    end

    attribute :currency, :string do
      default("USD")
      allow_nil?(false)
      description("Default currency for the portfolio")
    end

    attribute :locale, :string do
      default("en-US")
      allow_nil?(false)
      description("Locale for date/number formatting")
    end

    timestamps()
  end

  # No relationships needed - singleton pattern

  validations do
    validate(present(:name), message: "Name is required")
    validate(present(:currency), message: "Currency is required")
    validate(present(:locale), message: "Locale is required")

    validate(match(:currency, ~r/^[A-Z]{3}$/),
      message: "Currency must be a 3-letter code (e.g., USD)"
    )

    validate(string_length(:name, min: 1, max: 100))
  end

  actions do
    defaults([:read])

    create :create do
      description("Create initial user settings")
      accept([:name, :currency, :locale])
      primary?(true)
    end

    update :update do
      description("Update user settings")
      accept([:name, :currency, :locale])
      primary?(true)
    end

    read :get_singleton do
      description("Get the single UserSettings record")

      prepare(fn query, _context ->
        Ash.Query.limit(query, 1)
      end)
    end
  end

  # Convenience functions for singleton pattern
  defmodule Api do
    @moduledoc """
    Convenience API for singleton UserSettings operations.
    """

    @doc """
    Get the user settings. Creates default settings if none exist.
    """
    def get_settings do
      case Ash.read(UserSettings, action: :get_singleton) do
        {:ok, [settings]} ->
          {:ok, settings}

        {:ok, []} ->
          # Create default settings if none exist
          create_default_settings()

        {:error, reason} ->
          {:error, reason}
      end
    end

    @doc """
    Update the user settings.
    """
    def update_settings(attrs) do
      case get_settings() do
        {:ok, settings} ->
          Ash.update(settings, :update, attrs)

        {:error, reason} ->
          {:error, reason}
      end
    end

    @doc """
    Get the user's currency preference.
    """
    def get_currency do
      case get_settings() do
        {:ok, settings} -> {:ok, settings.currency}
        {:error, reason} -> {:error, reason}
      end
    end

    @doc """
    Get the user's locale preference.
    """
    def get_locale do
      case get_settings() do
        {:ok, settings} -> {:ok, settings.locale}
        {:error, reason} -> {:error, reason}
      end
    end

    @doc """
    Get the user's display name.
    """
    def get_name do
      case get_settings() do
        {:ok, settings} -> {:ok, settings.name}
        {:error, reason} -> {:error, reason}
      end
    end

    defp create_default_settings do
      Ash.create(UserSettings, %{
        name: "Local User",
        currency: "USD",
        locale: "en-US"
      })
    end
  end
end
