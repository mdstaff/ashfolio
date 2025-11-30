defmodule Ashfolio.Repo.Migrations.CreateConsentTables do
  use Ecto.Migration

  def change do
    # AI Consents table - stores user consent to AI features
    create table(:ai_consents, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :features, {:array, :string}, null: false, default: []
      add :privacy_mode, :string, null: false, default: "anonymized"
      add :terms_version, :string, null: false
      add :terms_hash, :string, null: false
      add :granted_at, :utc_datetime_usec
      add :withdrawn_at, :utc_datetime_usec
      add :ip_address, :string
      add :user_agent, :string

      timestamps(type: :utc_datetime_usec)
    end

    # Consent Audits table - append-only audit trail
    create table(:consent_audits, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :action, :string, null: false
      add :consent_id, :uuid
      add :previous_state, :map
      add :new_state, :map
      add :metadata, :map, null: false, default: %{}
      add :ip_address, :string
      add :user_agent, :string
      add :recorded_at, :utc_datetime_usec, null: false, default: fragment("CURRENT_TIMESTAMP")
    end

    create index(:consent_audits, [:consent_id])
    create index(:consent_audits, [:action])
    create index(:consent_audits, [:recorded_at])
  end
end
