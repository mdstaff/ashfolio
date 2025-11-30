defmodule Ashfolio.Legal.ConsentAudit do
  @moduledoc """
  Append-only audit trail for consent changes.

  Records all consent-related actions for GDPR compliance and auditing.
  This resource is append-only - records cannot be modified or deleted.

  ## Actions Tracked

  - `:granted` - Initial consent granted
  - `:withdrawn` - Consent withdrawn
  - `:privacy_mode_changed` - Privacy mode updated
  - `:features_changed` - Features list updated
  - `:gdpr_export` - Data export requested
  - `:gdpr_deletion` - Data deletion requested
  """

  use Ash.Resource,
    domain: Ashfolio.Legal,
    data_layer: AshSqlite.DataLayer

  @action_types [:granted, :withdrawn, :privacy_mode_changed, :features_changed, :gdpr_export, :gdpr_deletion]

  sqlite do
    table("consent_audits")
    repo(Ashfolio.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :action, :atom do
      allow_nil?(false)
      description("Type of consent action performed")
      constraints(one_of: @action_types)
    end

    attribute :consent_id, :uuid do
      allow_nil?(true)
      description("Reference to the consent record (if applicable)")
    end

    attribute :previous_state, :map do
      allow_nil?(true)
      description("State before the action (for change tracking)")
    end

    attribute :new_state, :map do
      allow_nil?(true)
      description("State after the action")
    end

    attribute :metadata, :map do
      default(%{})
      allow_nil?(false)
      description("Additional context about the action")
    end

    attribute :ip_address, :string do
      allow_nil?(true)
      description("IP address at time of action")
    end

    attribute :user_agent, :string do
      allow_nil?(true)
      description("Browser user agent at time of action")
    end

    create_timestamp(:recorded_at)
  end

  actions do
    defaults([:read])

    create :record do
      description("Record a consent audit entry")
      accept([:action, :consent_id, :previous_state, :new_state, :metadata, :ip_address, :user_agent])
      primary?(true)
    end

    read :for_consent do
      description("Get all audit entries for a consent record")
      argument(:consent_id, :uuid, allow_nil?: false)
      filter(expr(consent_id == ^arg(:consent_id)))
    end

    read :by_action do
      description("Get all audit entries of a specific action type")
      argument(:action, :atom, allow_nil?: false)
      filter(expr(action == ^arg(:action)))
    end

    read :recent do
      description("Get recent audit entries")
      argument(:limit, :integer, default: 50)

      prepare(fn query, _context ->
        limit = Ash.Query.get_argument(query, :limit) || 50

        query
        |> Ash.Query.sort(recorded_at: :desc)
        |> Ash.Query.limit(limit)
      end)
    end
  end

  code_interface do
    define(:record, action: :record)
    define(:for_consent, action: :for_consent, args: [:consent_id])
    define(:by_action, action: :by_action, args: [:action])
    define(:recent, action: :recent)
  end

  @doc """
  Returns all valid action types.
  """
  def action_types, do: @action_types

  @doc """
  Records a consent grant action.
  """
  def record_grant(consent, opts \\ []) do
    record(%{
      action: :granted,
      consent_id: consent.id,
      new_state: %{
        features: consent.features,
        privacy_mode: consent.privacy_mode,
        terms_version: consent.terms_version
      },
      ip_address: Keyword.get(opts, :ip_address),
      user_agent: Keyword.get(opts, :user_agent)
    })
  end

  @doc """
  Records a consent withdrawal action.
  """
  def record_withdrawal(consent, opts \\ []) do
    record(%{
      action: :withdrawn,
      consent_id: consent.id,
      previous_state: %{
        features: consent.features,
        privacy_mode: consent.privacy_mode
      },
      ip_address: Keyword.get(opts, :ip_address),
      user_agent: Keyword.get(opts, :user_agent)
    })
  end

  @doc """
  Records a privacy mode change action.
  """
  def record_privacy_mode_change(consent, old_mode, new_mode, opts \\ []) do
    record(%{
      action: :privacy_mode_changed,
      consent_id: consent.id,
      previous_state: %{privacy_mode: old_mode},
      new_state: %{privacy_mode: new_mode},
      ip_address: Keyword.get(opts, :ip_address),
      user_agent: Keyword.get(opts, :user_agent)
    })
  end

  @doc """
  Records a features change action.
  """
  def record_features_change(consent, old_features, new_features, opts \\ []) do
    record(%{
      action: :features_changed,
      consent_id: consent.id,
      previous_state: %{features: old_features},
      new_state: %{features: new_features},
      ip_address: Keyword.get(opts, :ip_address),
      user_agent: Keyword.get(opts, :user_agent)
    })
  end

  @doc """
  Records a GDPR data export request.
  """
  def record_gdpr_export(opts \\ []) do
    record(%{
      action: :gdpr_export,
      metadata: %{requested_at: DateTime.utc_now()},
      ip_address: Keyword.get(opts, :ip_address),
      user_agent: Keyword.get(opts, :user_agent)
    })
  end

  @doc """
  Records a GDPR data deletion request.
  """
  def record_gdpr_deletion(opts \\ []) do
    record(%{
      action: :gdpr_deletion,
      metadata: %{requested_at: DateTime.utc_now()},
      ip_address: Keyword.get(opts, :ip_address),
      user_agent: Keyword.get(opts, :user_agent)
    })
  end
end
