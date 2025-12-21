# Task: Consent Resource Implementation

**Phase**: 3 - Legal & Consent
**Priority**: P1
**Estimate**: 4-6 hours
**Status**: Not Started

## Objective

Create an Ash resource to track user consent for third-party LLM features, supporting GDPR/CCPA compliance and consent versioning for terms updates.

## Prerequisites

- [ ] Phase 1 complete
- [ ] Understanding of GDPR/CCPA consent requirements
- [ ] Legal review of consent language (pending)

## Acceptance Criteria

### Functional Requirements

1. `AiConsent` Ash resource with versioning
2. Consent tracks: feature scope, date, version, withdrawal
3. Queries for current consent status
4. Consent withdrawal invalidates future sessions
5. Audit trail for consent changes

### Non-Functional Requirements

1. Consent checks < 5ms
2. Immutable consent records (append-only)
3. Data export capability (GDPR Article 20)
4. Deletion capability with audit note (GDPR Article 17)

## TDD Test Cases

### Test File: `test/ashfolio/legal/ai_consent_test.exs`

```elixir
defmodule Ashfolio.Legal.AiConsentTest do
  use Ashfolio.DataCase, async: true

  alias Ashfolio.Legal.AiConsent

  describe "consent creation" do
    test "creates consent record with required fields" do
      {:ok, consent} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0",
        privacy_mode: :anonymized,
        terms_hash: "sha256:abc123"
      })

      assert consent.feature == :mcp_tools
      assert consent.consent_version == "1.0"
      assert consent.privacy_mode == :anonymized
      assert consent.granted_at != nil
      assert consent.withdrawn_at == nil
    end

    test "validates feature is known" do
      {:error, changeset} = AiConsent.grant(%{
        feature: :unknown_feature,
        consent_version: "1.0"
      })

      assert errors_on(changeset).feature
    end

    test "validates privacy_mode is valid" do
      {:error, changeset} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0",
        privacy_mode: :invalid_mode
      })

      assert errors_on(changeset).privacy_mode
    end

    test "stores terms hash for verification" do
      {:ok, consent} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0",
        terms_hash: "sha256:abc123def456"
      })

      assert consent.terms_hash == "sha256:abc123def456"
    end
  end

  describe "consent queries" do
    test "current_consent returns latest active consent" do
      # Grant consent
      {:ok, _old} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0"
      })

      # Grant newer consent
      {:ok, newer} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.1"
      })

      current = AiConsent.current_consent(:mcp_tools)

      assert current.id == newer.id
      assert current.consent_version == "1.1"
    end

    test "current_consent returns nil when withdrawn" do
      {:ok, consent} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0"
      })

      {:ok, _} = AiConsent.withdraw(consent)

      assert AiConsent.current_consent(:mcp_tools) == nil
    end

    test "has_valid_consent? checks version" do
      {:ok, _} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0"
      })

      assert AiConsent.has_valid_consent?(:mcp_tools, "1.0")
      refute AiConsent.has_valid_consent?(:mcp_tools, "2.0")
    end

    test "consent_history returns all records" do
      {:ok, c1} = AiConsent.grant(%{feature: :mcp_tools, consent_version: "1.0"})
      {:ok, _} = AiConsent.withdraw(c1)
      {:ok, _c2} = AiConsent.grant(%{feature: :mcp_tools, consent_version: "1.1"})

      history = AiConsent.consent_history(:mcp_tools)

      assert length(history) == 2
      # Newest first
      assert hd(history).consent_version == "1.1"
    end
  end

  describe "consent withdrawal" do
    test "withdraw sets withdrawn_at" do
      {:ok, consent} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0"
      })

      {:ok, withdrawn} = AiConsent.withdraw(consent)

      assert withdrawn.withdrawn_at != nil
    end

    test "withdraw requires reason" do
      {:ok, consent} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0"
      })

      {:ok, withdrawn} = AiConsent.withdraw(consent, reason: "User requested via settings")

      assert withdrawn.withdrawal_reason == "User requested via settings"
    end

    test "cannot withdraw already withdrawn consent" do
      {:ok, consent} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0"
      })

      {:ok, withdrawn} = AiConsent.withdraw(consent)
      {:error, changeset} = AiConsent.withdraw(withdrawn)

      assert errors_on(changeset).withdrawn_at
    end

    test "withdrawal creates audit record" do
      {:ok, consent} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0"
      })

      {:ok, _} = AiConsent.withdraw(consent, reason: "Testing")

      # Check audit log exists
      audits = Ashfolio.Legal.ConsentAudit.for_consent(consent.id)
      assert length(audits) >= 1
      assert hd(audits).action == :withdrawn
    end
  end

  describe "consent versioning" do
    test "new version invalidates old consent" do
      {:ok, old_consent} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0"
      })

      # Simulate terms update requiring re-consent
      refute AiConsent.has_valid_consent?(:mcp_tools, "2.0")

      # User grants new consent
      {:ok, _new} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "2.0"
      })

      assert AiConsent.has_valid_consent?(:mcp_tools, "2.0")

      # Old consent still exists in history
      history = AiConsent.consent_history(:mcp_tools)
      assert Enum.any?(history, &(&1.id == old_consent.id))
    end

    test "minimum_version returns lowest acceptable version" do
      current_min = AiConsent.minimum_version(:mcp_tools)

      assert current_min == "1.0"  # Or whatever is configured
    end
  end

  describe "GDPR compliance" do
    test "export_consent_data returns all user consent data" do
      {:ok, _} = AiConsent.grant(%{feature: :mcp_tools, consent_version: "1.0"})
      {:ok, _} = AiConsent.grant(%{feature: :ai_analysis, consent_version: "1.0"})

      export = AiConsent.export_consent_data()

      assert Map.has_key?(export, :consents)
      assert Map.has_key?(export, :audits)
      assert Map.has_key?(export, :exported_at)
    end

    test "delete_consent_data removes records with audit" do
      {:ok, consent} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0"
      })

      {:ok, deletion_audit} = AiConsent.delete_consent_data(
        reason: "GDPR Article 17 request"
      )

      # Consent data removed
      assert AiConsent.current_consent(:mcp_tools) == nil
      assert AiConsent.consent_history(:mcp_tools) == []

      # Audit record remains
      assert deletion_audit.action == :gdpr_deletion
      assert deletion_audit.reason == "GDPR Article 17 request"
    end
  end

  describe "feature scopes" do
    test "consent is feature-scoped" do
      {:ok, _} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0"
      })

      assert AiConsent.has_valid_consent?(:mcp_tools, "1.0")
      refute AiConsent.has_valid_consent?(:ai_analysis, "1.0")
    end

    test "all features can be consented independently" do
      features = [:mcp_tools, :ai_analysis, :cloud_llm]

      for feature <- features do
        {:ok, _} = AiConsent.grant(%{
          feature: feature,
          consent_version: "1.0"
        })
      end

      for feature <- features do
        assert AiConsent.has_valid_consent?(feature, "1.0")
      end
    end
  end
end
```

## Implementation Steps

### Step 1: Create AiConsent Resource

```elixir
# lib/ashfolio/legal/ai_consent.ex

defmodule Ashfolio.Legal.AiConsent do
  @moduledoc """
  Tracks user consent for AI/LLM features.

  ## Features

  - `:mcp_tools` - MCP tool execution with privacy filtering
  - `:ai_analysis` - Portfolio analysis by cloud LLM
  - `:cloud_llm` - Any data sent to cloud LLM providers

  ## Consent Versioning

  When terms change, a new consent version is required. Old consents
  remain in history for audit purposes but are not valid for the new version.

  ## GDPR Compliance

  - Explicit consent required before data processing
  - Consent can be withdrawn at any time
  - Full data export available via `export_consent_data/0`
  - Data deletion with audit trail via `delete_consent_data/1`
  """

  use Ash.Resource,
    domain: Ashfolio.Legal,
    data_layer: AshSqlite.DataLayer

  alias Ashfolio.Legal.ConsentAudit

  @features [:mcp_tools, :ai_analysis, :cloud_llm]
  @privacy_modes [:strict, :anonymized, :standard, :full]
  @current_versions %{
    mcp_tools: "1.0",
    ai_analysis: "1.0",
    cloud_llm: "1.0"
  }

  sqlite do
    table "ai_consents"
    repo Ashfolio.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :feature, :atom do
      allow_nil? false
      constraints one_of: @features
    end

    attribute :consent_version, :string do
      allow_nil? false
    end

    attribute :privacy_mode, :atom do
      constraints one_of: @privacy_modes
      default :anonymized
    end

    attribute :terms_hash, :string do
      description "SHA256 hash of consented terms for verification"
    end

    attribute :granted_at, :utc_datetime_usec do
      allow_nil? false
      default &DateTime.utc_now/0
    end

    attribute :withdrawn_at, :utc_datetime_usec

    attribute :withdrawal_reason, :string

    timestamps()
  end

  actions do
    defaults [:read]

    create :grant do
      description "Grant consent for an AI feature"

      accept [:feature, :consent_version, :privacy_mode, :terms_hash]

      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.change_attribute(:granted_at, DateTime.utc_now())
      end

      change after_action(fn changeset, consent, _context ->
        ConsentAudit.create!(%{
          consent_id: consent.id,
          action: :granted,
          metadata: %{
            feature: consent.feature,
            version: consent.consent_version,
            privacy_mode: consent.privacy_mode
          }
        })
        {:ok, consent}
      end)
    end

    update :withdraw do
      description "Withdraw previously granted consent"

      accept [:withdrawal_reason]

      validate present(:withdrawn_at, negate: true, message: "Consent already withdrawn")

      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.change_attribute(:withdrawn_at, DateTime.utc_now())
      end

      change after_action(fn changeset, consent, _context ->
        ConsentAudit.create!(%{
          consent_id: consent.id,
          action: :withdrawn,
          metadata: %{
            reason: consent.withdrawal_reason
          }
        })
        {:ok, consent}
      end)
    end

    action :current_consent, :struct do
      description "Get current active consent for a feature"
      argument :feature, :atom, allow_nil?: false

      run fn input, _context ->
        feature = input.arguments.feature

        consent =
          __MODULE__
          |> Ash.Query.filter(feature == ^feature and is_nil(withdrawn_at))
          |> Ash.Query.sort(granted_at: :desc)
          |> Ash.Query.limit(1)
          |> Ash.read_one!()

        {:ok, consent}
      end
    end

    action :has_valid_consent?, :boolean do
      description "Check if valid consent exists for feature and version"
      argument :feature, :atom, allow_nil?: false
      argument :version, :string, allow_nil?: false

      run fn input, _context ->
        feature = input.arguments.feature
        version = input.arguments.version

        consent =
          __MODULE__
          |> Ash.Query.filter(feature == ^feature and is_nil(withdrawn_at))
          |> Ash.Query.filter(consent_version == ^version)
          |> Ash.Query.limit(1)
          |> Ash.read_one!()

        {:ok, consent != nil}
      end
    end

    action :consent_history, {:array, :struct} do
      description "Get consent history for a feature"
      argument :feature, :atom, allow_nil?: false

      run fn input, _context ->
        feature = input.arguments.feature

        history =
          __MODULE__
          |> Ash.Query.filter(feature == ^feature)
          |> Ash.Query.sort(granted_at: :desc)
          |> Ash.read!()

        {:ok, history}
      end
    end
  end

  code_interface do
    define :grant, args: [:input]
    define :withdraw, args: [:consent]
    define :current_consent, args: [:feature]
    define :has_valid_consent?, args: [:feature, :version]
    define :consent_history, args: [:feature]
  end

  # Class methods

  def minimum_version(feature) do
    Map.get(@current_versions, feature, "1.0")
  end

  def export_consent_data do
    consents = Ash.read!(__MODULE__)
    audits = ConsentAudit.all!()

    %{
      consents: Enum.map(consents, &Map.from_struct/1),
      audits: Enum.map(audits, &Map.from_struct/1),
      exported_at: DateTime.utc_now()
    }
  end

  def delete_consent_data(opts \\ []) do
    reason = Keyword.get(opts, :reason, "User requested deletion")

    # Delete all consent records
    Ash.bulk_destroy!(__MODULE__, :destroy, %{})

    # Create audit record
    ConsentAudit.create!(%{
      consent_id: nil,
      action: :gdpr_deletion,
      metadata: %{reason: reason}
    })
  end
end
```

### Step 2: Create ConsentAudit Resource

```elixir
# lib/ashfolio/legal/consent_audit.ex

defmodule Ashfolio.Legal.ConsentAudit do
  use Ash.Resource,
    domain: Ashfolio.Legal,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "consent_audits"
    repo Ashfolio.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :consent_id, :uuid do
      description "May be nil for bulk operations like GDPR deletion"
    end

    attribute :action, :atom do
      allow_nil? false
      constraints one_of: [:granted, :withdrawn, :gdpr_deletion, :gdpr_export]
    end

    attribute :metadata, :map do
      default %{}
    end

    attribute :ip_address, :string
    attribute :user_agent, :string

    create_timestamp :created_at
  end

  actions do
    defaults [:read, :create]

    read :for_consent do
      argument :consent_id, :uuid, allow_nil?: false
      filter expr(consent_id == ^arg(:consent_id))
    end

    read :all
  end

  code_interface do
    define :create, args: [:input]
    define :for_consent, args: [:consent_id]
    define :all
  end
end
```

### Step 3: Create Legal Domain

```elixir
# lib/ashfolio/legal.ex

defmodule Ashfolio.Legal do
  use Ash.Domain

  resources do
    resource Ashfolio.Legal.AiConsent
    resource Ashfolio.Legal.ConsentAudit
  end
end
```

### Step 4: Register Domain in Application Config

```elixir
# config/config.exs - add Legal domain to ash_domains list

config :ashfolio,
  ash_domains: [
    Ashfolio.Portfolio,
    Ashfolio.FinancialManagement,
    Ashfolio.Legal  # Add this
  ]
```

### Step 5: Create Database Migration

```bash
# Generate migration for new tables
mix ash.codegen create_legal_tables

# Review the generated migration, then run:
mix ash.migrate
```

The migration should create:
- `ai_consents` table with columns: id, feature, consent_version, privacy_mode, terms_hash, granted_at, withdrawn_at, withdrawal_reason, inserted_at, updated_at
- `consent_audits` table with columns: id, consent_id, action, metadata, ip_address, user_agent, created_at

### Step 6: Run Tests

```bash
mix test test/ashfolio/legal/ai_consent_test.exs --trace
```

## Definition of Done

- [ ] AiConsent resource created
- [ ] ConsentAudit resource created
- [ ] Legal domain created
- [ ] Legal domain registered in `config/config.exs` (ash_domains list)
- [ ] Database migrations created and run
- [ ] Consent versioning works
- [ ] GDPR export/delete implemented
- [ ] All TDD tests pass
- [ ] `mix test` passes (no regressions)

## Dependencies

**Blocked By**: Phase 2 complete (conceptually)
**Blocks**: Task P3-02 (Consent UI)

## Notes

- Legal review pending for consent language
- Consider adding IP geolocation for regional compliance
- Future: Consent analytics dashboard

---

*Parent: [../README.md](../README.md)*
