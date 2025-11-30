defmodule Ashfolio.Legal.ConsentAuditTest do
  use Ashfolio.DataCase, async: true

  alias Ashfolio.Legal.AiConsent
  alias Ashfolio.Legal.ConsentAudit

  @consent_attrs %{
    features: [:mcp_tools],
    privacy_mode: :anonymized,
    terms_version: "1.0.0",
    terms_hash: AiConsent.hash_terms("Terms")
  }

  describe "record/1" do
    test "creates audit entry with valid attributes" do
      assert {:ok, audit} = ConsentAudit.record(%{
        action: :granted,
        consent_id: Ash.UUID.generate(),
        new_state: %{features: [:mcp_tools]}
      })

      assert audit.action == :granted
      assert audit.recorded_at != nil
    end

    test "accepts all action types" do
      for action <- ConsentAudit.action_types() do
        assert {:ok, audit} = ConsentAudit.record(%{action: action})
        assert audit.action == action
      end
    end

    test "stores previous and new state" do
      assert {:ok, audit} = ConsentAudit.record(%{
        action: :privacy_mode_changed,
        previous_state: %{privacy_mode: :strict},
        new_state: %{privacy_mode: :full}
      })

      # Maps serialize atoms to strings
      assert audit.previous_state["privacy_mode"] == "strict"
      assert audit.new_state["privacy_mode"] == "full"
    end

    test "stores IP and user agent" do
      assert {:ok, audit} = ConsentAudit.record(%{
        action: :granted,
        ip_address: "10.0.0.1",
        user_agent: "Test Agent"
      })

      assert audit.ip_address == "10.0.0.1"
      assert audit.user_agent == "Test Agent"
    end

    test "stores metadata" do
      assert {:ok, audit} = ConsentAudit.record(%{
        action: :gdpr_export,
        metadata: %{format: "json", requested_by: "user"}
      })

      assert audit.metadata["format"] == "json"
    end
  end

  describe "for_consent/1" do
    test "returns audits for specific consent" do
      consent_id = Ash.UUID.generate()

      {:ok, _} = ConsentAudit.record(%{action: :granted, consent_id: consent_id})
      {:ok, _} = ConsentAudit.record(%{action: :privacy_mode_changed, consent_id: consent_id})
      {:ok, _} = ConsentAudit.record(%{action: :granted, consent_id: Ash.UUID.generate()})

      assert {:ok, audits} = ConsentAudit.for_consent(consent_id)
      assert length(audits) == 2
      assert Enum.all?(audits, &(&1.consent_id == consent_id))
    end
  end

  describe "by_action/1" do
    test "filters by action type" do
      {:ok, _} = ConsentAudit.record(%{action: :granted})
      {:ok, _} = ConsentAudit.record(%{action: :granted})
      {:ok, _} = ConsentAudit.record(%{action: :withdrawn})

      assert {:ok, audits} = ConsentAudit.by_action(:granted)
      assert length(audits) == 2
      assert Enum.all?(audits, &(&1.action == :granted))
    end
  end

  describe "recent/0" do
    test "returns recent entries" do
      for _ <- 1..5 do
        {:ok, _} = ConsentAudit.record(%{action: :granted})
      end

      assert {:ok, audits} = ConsentAudit.recent()
      assert length(audits) == 5
    end
  end

  describe "record_grant/2" do
    test "records grant action with consent details" do
      {:ok, consent} = AiConsent.grant(@consent_attrs)

      assert {:ok, audit} = ConsentAudit.record_grant(consent)

      assert audit.action == :granted
      assert audit.consent_id == consent.id
      # Maps serialize atoms to strings
      assert audit.new_state["features"] == ["mcp_tools"]
      assert audit.new_state["privacy_mode"] == "anonymized"
    end

    test "includes IP and user agent" do
      {:ok, consent} = AiConsent.grant(@consent_attrs)

      assert {:ok, audit} = ConsentAudit.record_grant(consent,
        ip_address: "1.2.3.4",
        user_agent: "Mozilla"
      )

      assert audit.ip_address == "1.2.3.4"
      assert audit.user_agent == "Mozilla"
    end
  end

  describe "record_withdrawal/2" do
    test "records withdrawal action" do
      {:ok, consent} = AiConsent.grant(@consent_attrs)

      assert {:ok, audit} = ConsentAudit.record_withdrawal(consent)

      assert audit.action == :withdrawn
      assert audit.consent_id == consent.id
      # Maps serialize atoms to strings
      assert audit.previous_state["features"] == ["mcp_tools"]
    end
  end

  describe "record_privacy_mode_change/4" do
    test "records mode change with before/after" do
      {:ok, consent} = AiConsent.grant(@consent_attrs)

      assert {:ok, audit} = ConsentAudit.record_privacy_mode_change(
        consent,
        :anonymized,
        :full
      )

      assert audit.action == :privacy_mode_changed
      # Maps serialize atoms to strings
      assert audit.previous_state["privacy_mode"] == "anonymized"
      assert audit.new_state["privacy_mode"] == "full"
    end
  end

  describe "record_features_change/4" do
    test "records features change with before/after" do
      {:ok, consent} = AiConsent.grant(@consent_attrs)

      assert {:ok, audit} = ConsentAudit.record_features_change(
        consent,
        [:mcp_tools],
        [:mcp_tools, :ai_analysis]
      )

      assert audit.action == :features_changed
      # Maps serialize atoms to strings
      assert audit.previous_state["features"] == ["mcp_tools"]
      assert audit.new_state["features"] == ["mcp_tools", "ai_analysis"]
    end
  end

  describe "record_gdpr_export/1" do
    test "records GDPR export request" do
      assert {:ok, audit} = ConsentAudit.record_gdpr_export()

      assert audit.action == :gdpr_export
      assert audit.metadata["requested_at"] != nil
    end
  end

  describe "record_gdpr_deletion/1" do
    test "records GDPR deletion request" do
      assert {:ok, audit} = ConsentAudit.record_gdpr_deletion(
        ip_address: "8.8.8.8"
      )

      assert audit.action == :gdpr_deletion
      assert audit.ip_address == "8.8.8.8"
    end
  end

  describe "action_types/0" do
    test "returns all valid action types" do
      types = ConsentAudit.action_types()

      assert :granted in types
      assert :withdrawn in types
      assert :privacy_mode_changed in types
      assert :features_changed in types
      assert :gdpr_export in types
      assert :gdpr_deletion in types
    end
  end
end
