defmodule Ashfolio.Legal.AiConsentTest do
  use Ashfolio.DataCase, async: true

  alias Ashfolio.Legal.AiConsent

  @valid_attrs %{
    features: [:mcp_tools, :ai_analysis],
    privacy_mode: :anonymized,
    terms_version: "1.0.0",
    terms_hash: AiConsent.hash_terms("Sample terms text")
  }

  describe "grant/1" do
    test "creates consent with valid attributes" do
      assert {:ok, consent} = AiConsent.grant(@valid_attrs)

      assert consent.features == [:mcp_tools, :ai_analysis]
      assert consent.privacy_mode == :anonymized
      assert consent.terms_version == "1.0.0"
      assert consent.granted_at != nil
      assert consent.withdrawn_at == nil
    end

    test "creates consent with all features" do
      attrs = %{@valid_attrs | features: [:mcp_tools, :ai_analysis, :cloud_llm]}
      assert {:ok, consent} = AiConsent.grant(attrs)
      assert length(consent.features) == 3
    end

    test "creates consent with empty features" do
      attrs = %{@valid_attrs | features: []}
      assert {:ok, consent} = AiConsent.grant(attrs)
      assert consent.features == []
    end

    test "stores IP address and user agent" do
      attrs = Map.merge(@valid_attrs, %{
        ip_address: "192.168.1.1",
        user_agent: "Mozilla/5.0"
      })
      assert {:ok, consent} = AiConsent.grant(attrs)
      assert consent.ip_address == "192.168.1.1"
      assert consent.user_agent == "Mozilla/5.0"
    end
  end

  describe "privacy_mode validation" do
    test "accepts :strict mode" do
      attrs = %{@valid_attrs | privacy_mode: :strict}
      assert {:ok, consent} = AiConsent.grant(attrs)
      assert consent.privacy_mode == :strict
    end

    test "accepts :anonymized mode" do
      attrs = %{@valid_attrs | privacy_mode: :anonymized}
      assert {:ok, consent} = AiConsent.grant(attrs)
      assert consent.privacy_mode == :anonymized
    end

    test "accepts :standard mode" do
      attrs = %{@valid_attrs | privacy_mode: :standard}
      assert {:ok, consent} = AiConsent.grant(attrs)
      assert consent.privacy_mode == :standard
    end

    test "accepts :full mode" do
      attrs = %{@valid_attrs | privacy_mode: :full}
      assert {:ok, consent} = AiConsent.grant(attrs)
      assert consent.privacy_mode == :full
    end

    test "rejects invalid privacy mode" do
      attrs = %{@valid_attrs | privacy_mode: :invalid}
      assert {:error, _} = AiConsent.grant(attrs)
    end
  end

  describe "withdraw/1" do
    test "marks consent as withdrawn" do
      {:ok, consent} = AiConsent.grant(@valid_attrs)

      assert {:ok, withdrawn} = AiConsent.withdraw(consent)

      assert withdrawn.withdrawn_at != nil
      assert withdrawn.features == []
    end

    test "withdrawn consent is no longer active" do
      {:ok, consent} = AiConsent.grant(@valid_attrs)
      {:ok, _withdrawn} = AiConsent.withdraw(consent)

      # get_active should return empty
      assert {:ok, []} = AiConsent.get_active()
    end
  end

  describe "update_privacy_mode/2" do
    test "changes privacy mode" do
      {:ok, consent} = AiConsent.grant(@valid_attrs)

      assert {:ok, updated} = AiConsent.update_privacy_mode(consent, %{privacy_mode: :full})

      assert updated.privacy_mode == :full
    end
  end

  describe "update_features/2" do
    test "adds new features" do
      {:ok, consent} = AiConsent.grant(%{@valid_attrs | features: [:mcp_tools]})

      assert {:ok, updated} = AiConsent.update_features(consent, %{
        features: [:mcp_tools, :ai_analysis, :cloud_llm]
      })

      assert :cloud_llm in updated.features
    end

    test "removes features" do
      {:ok, consent} = AiConsent.grant(@valid_attrs)

      assert {:ok, updated} = AiConsent.update_features(consent, %{features: [:mcp_tools]})

      assert updated.features == [:mcp_tools]
    end
  end

  describe "get_active/0" do
    test "returns active consent" do
      {:ok, consent} = AiConsent.grant(@valid_attrs)

      assert {:ok, [active]} = AiConsent.get_active()
      assert active.id == consent.id
    end

    test "returns empty list when no active consent" do
      assert {:ok, []} = AiConsent.get_active()
    end

    test "excludes withdrawn consent" do
      {:ok, consent} = AiConsent.grant(@valid_attrs)
      {:ok, _withdrawn} = AiConsent.withdraw(consent)

      assert {:ok, []} = AiConsent.get_active()
    end
  end

  describe "hash_terms/1" do
    test "generates consistent hash for same text" do
      hash1 = AiConsent.hash_terms("Terms and conditions")
      hash2 = AiConsent.hash_terms("Terms and conditions")

      assert hash1 == hash2
    end

    test "generates different hash for different text" do
      hash1 = AiConsent.hash_terms("Terms v1")
      hash2 = AiConsent.hash_terms("Terms v2")

      refute hash1 == hash2
    end

    test "returns lowercase hex string" do
      hash = AiConsent.hash_terms("Test")

      assert String.match?(hash, ~r/^[a-f0-9]+$/)
      assert String.length(hash) == 64
    end
  end

  describe "privacy_modes/0" do
    test "returns all valid privacy modes" do
      modes = AiConsent.privacy_modes()

      assert :strict in modes
      assert :anonymized in modes
      assert :standard in modes
      assert :full in modes
      assert length(modes) == 4
    end
  end

  describe "features/0" do
    test "returns all valid features" do
      features = AiConsent.features()

      assert :mcp_tools in features
      assert :ai_analysis in features
      assert :cloud_llm in features
      assert length(features) == 3
    end
  end
end
