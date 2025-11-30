defmodule Ashfolio.Legal.AiConsent do
  @moduledoc """
  AI Consent resource for managing user consent to AI features.

  Tracks which AI features the user has consented to, the privacy mode
  they've selected, and provides versioning via terms hash for re-consent
  when terms change.

  ## Features

  The user can consent to:
  - `:mcp_tools` - MCP tool access for AI assistants
  - `:ai_analysis` - AI-powered portfolio analysis
  - `:cloud_llm` - Cloud LLM API usage (vs local-only)

  ## Privacy Modes

  - `:strict` - Aggregate data only, no individual records
  - `:anonymized` - Letter IDs, relative weights, no exact amounts
  - `:standard` - Names visible, amounts hidden
  - `:full` - Complete data access

  ## Database-as-User Architecture

  Like UserSettings, this uses singleton pattern per database file.
  Each SQLite database = one user, so we track a single consent record.
  """

  use Ash.Resource,
    domain: Ashfolio.Legal,
    data_layer: AshSqlite.DataLayer

  @privacy_modes [:strict, :anonymized, :standard, :full]
  @features [:mcp_tools, :ai_analysis, :cloud_llm]

  sqlite do
    table("ai_consents")
    repo(Ashfolio.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :features, {:array, :atom} do
      default([])
      allow_nil?(false)
      description("List of AI features the user has consented to")
      constraints(items: [one_of: @features])
    end

    attribute :privacy_mode, :atom do
      default(:anonymized)
      allow_nil?(false)
      description("Privacy level for AI data access")
      constraints(one_of: @privacy_modes)
    end

    attribute :terms_version, :string do
      allow_nil?(false)
      description("Version identifier for the terms the user accepted")
    end

    attribute :terms_hash, :string do
      allow_nil?(false)
      description("SHA256 hash of terms text for detecting changes")
    end

    attribute :granted_at, :utc_datetime_usec do
      allow_nil?(true)
      description("When consent was granted")
    end

    attribute :withdrawn_at, :utc_datetime_usec do
      allow_nil?(true)
      description("When consent was withdrawn (null if active)")
    end

    attribute :ip_address, :string do
      allow_nil?(true)
      description("IP address at time of consent (for audit)")
    end

    attribute :user_agent, :string do
      allow_nil?(true)
      description("Browser user agent at time of consent (for audit)")
    end

    timestamps()
  end

  identities do
    identity(:singleton, [:id], pre_check?: false)
  end

  actions do
    defaults([:read])

    create :grant do
      description("Grant consent to AI features")
      accept([:features, :privacy_mode, :terms_version, :terms_hash, :ip_address, :user_agent])

      change(fn changeset, _context ->
        Ash.Changeset.change_attribute(changeset, :granted_at, DateTime.utc_now())
      end)
    end

    update :update_privacy_mode do
      description("Change privacy mode for existing consent")
      accept([:privacy_mode])
      require_atomic?(false)
    end

    update :update_features do
      description("Update consented features")
      accept([:features])
      require_atomic?(false)
    end

    update :withdraw do
      description("Withdraw consent")
      accept([])
      require_atomic?(false)

      change(fn changeset, _context ->
        changeset
        |> Ash.Changeset.change_attribute(:withdrawn_at, DateTime.utc_now())
        |> Ash.Changeset.change_attribute(:features, [])
      end)
    end

    read :get_active do
      description("Get the active consent record (not withdrawn)")

      filter(expr(is_nil(withdrawn_at)))

      prepare(fn query, _context ->
        Ash.Query.limit(query, 1)
      end)
    end
  end

  calculations do
    calculate :active?, :boolean do
      description("Whether consent is currently active")
      calculation(fn record, _context ->
        {:ok, is_nil(record.withdrawn_at)}
      end)
    end

    calculate :has_feature?, :boolean, {Ashfolio.Legal.AiConsent.HasFeatureCalculation, []} do
      description("Check if a specific feature is consented")
      argument(:feature, :atom, allow_nil?: false)
    end
  end

  code_interface do
    define(:grant, action: :grant)
    define(:withdraw, action: :withdraw)
    define(:update_privacy_mode, action: :update_privacy_mode)
    define(:update_features, action: :update_features)
    define(:get_active, action: :get_active)
  end

  @doc """
  Returns all valid privacy modes.
  """
  def privacy_modes, do: @privacy_modes

  @doc """
  Returns all valid features.
  """
  def features, do: @features

  @doc """
  Generates a terms hash from the terms text.
  """
  def hash_terms(terms_text) when is_binary(terms_text) do
    :crypto.hash(:sha256, terms_text)
    |> Base.encode16(case: :lower)
  end
end

defmodule Ashfolio.Legal.AiConsent.HasFeatureCalculation do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def calculate(records, _opts, %{arguments: %{feature: feature}}) do
    Enum.map(records, fn record ->
      feature in (record.features || [])
    end)
  end
end
