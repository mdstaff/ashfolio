defmodule AshfolioWeb.Hooks.ConsentCheckTest do
  use Ashfolio.DataCase, async: true

  alias Ashfolio.Legal.AiConsent
  alias AshfolioWeb.Hooks.ConsentCheck

  @consent_attrs %{
    features: [:mcp_tools],
    privacy_mode: :anonymized,
    terms_version: "1.0.0",
    terms_hash: AiConsent.hash_terms("Test terms")
  }

  # Helper to create a test socket with proper internal state
  defp test_socket(assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      assigns: Map.merge(%{__changed__: %{}, flash: %{}}, assigns),
      private: %{assign_new: %{}, live_temp: %{}}
    }
  end

  describe "check_consent_status/1" do
    test "returns consent info when consent exists" do
      {:ok, consent} = AiConsent.grant(@consent_attrs)

      socket = test_socket()
      result = ConsentCheck.check_consent_status(socket)

      assert result.assigns.has_ai_consent == true
      assert result.assigns.ai_privacy_mode == :anonymized
      assert result.assigns.ai_features == [:mcp_tools]
      assert result.assigns.ai_consent_id == consent.id
      assert result.assigns.show_consent_modal == false
    end

    test "returns no consent when none exists" do
      socket = test_socket()
      result = ConsentCheck.check_consent_status(socket)

      assert result.assigns.has_ai_consent == false
      assert result.assigns.ai_privacy_mode == nil
      assert result.assigns.ai_features == []
      assert result.assigns.ai_consent_id == nil
      assert result.assigns.show_consent_modal == false
    end

    test "returns no consent when consent is withdrawn" do
      {:ok, consent} = AiConsent.grant(@consent_attrs)
      {:ok, _withdrawn} = AiConsent.withdraw(consent)

      socket = test_socket()
      result = ConsentCheck.check_consent_status(socket)

      assert result.assigns.has_ai_consent == false
    end
  end

  describe "has_feature?/2" do
    test "returns true when feature is enabled" do
      socket = test_socket(%{ai_features: [:mcp_tools, :ai_analysis]})

      assert ConsentCheck.has_feature?(socket, :mcp_tools) == true
      assert ConsentCheck.has_feature?(socket, :ai_analysis) == true
    end

    test "returns false when feature is not enabled" do
      socket = test_socket(%{ai_features: [:mcp_tools]})

      assert ConsentCheck.has_feature?(socket, :cloud_llm) == false
    end

    test "returns false when no features set" do
      socket = test_socket()

      assert ConsentCheck.has_feature?(socket, :mcp_tools) == false
    end
  end

  describe "privacy_mode/1" do
    test "returns privacy mode when set" do
      socket = test_socket(%{ai_privacy_mode: :full})

      assert ConsentCheck.privacy_mode(socket) == :full
    end

    test "returns :strict when not set" do
      socket = test_socket()

      assert ConsentCheck.privacy_mode(socket) == :strict
    end
  end

  describe "on_mount :require_consent" do
    test "continues with modal when no consent" do
      socket = test_socket()

      {:cont, result} = ConsentCheck.on_mount(:require_consent, %{}, %{}, socket)

      assert result.assigns.show_consent_modal == true
    end

    test "continues without modal when consent exists" do
      {:ok, _consent} = AiConsent.grant(@consent_attrs)

      socket = test_socket()

      {:cont, result} = ConsentCheck.on_mount(:require_consent, %{}, %{}, socket)

      assert result.assigns.has_ai_consent == true
      assert result.assigns.show_consent_modal == false
    end
  end

  describe "on_mount :check_consent" do
    test "sets assigns without showing modal when no consent" do
      socket = test_socket()

      {:cont, result} = ConsentCheck.on_mount(:check_consent, %{}, %{}, socket)

      assert result.assigns.has_ai_consent == false
      # check_consent doesn't set show_consent_modal to true
      assert result.assigns.show_consent_modal == false
    end

    test "sets assigns when consent exists" do
      {:ok, _consent} = AiConsent.grant(@consent_attrs)

      socket = test_socket()

      {:cont, result} = ConsentCheck.on_mount(:check_consent, %{}, %{}, socket)

      assert result.assigns.has_ai_consent == true
      assert result.assigns.ai_privacy_mode == :anonymized
    end
  end

  describe "handle_consent_granted/2" do
    test "creates consent and updates socket" do
      socket = test_socket()

      consent_data = %{
        privacy_mode: :full,
        features: [:mcp_tools, :ai_analysis],
        terms_version: "1.0.0",
        terms_hash: AiConsent.hash_terms("Terms")
      }

      result = ConsentCheck.handle_consent_granted(socket, consent_data)

      assert result.assigns.has_ai_consent == true
      assert result.assigns.ai_privacy_mode == :full
      assert :mcp_tools in result.assigns.ai_features
      assert result.assigns.show_consent_modal == false
    end
  end

  describe "handle_consent_declined/1" do
    test "hides modal and shows info message" do
      socket = test_socket(%{show_consent_modal: true})

      result = ConsentCheck.handle_consent_declined(socket)

      assert result.assigns.show_consent_modal == false
    end
  end

  describe "withdraw_consent/1" do
    test "withdraws consent and clears assigns" do
      {:ok, consent} = AiConsent.grant(@consent_attrs)

      socket = test_socket(%{ai_consent_id: consent.id, has_ai_consent: true})

      result = ConsentCheck.withdraw_consent(socket)

      assert result.assigns.has_ai_consent == false
      assert result.assigns.ai_privacy_mode == nil
      assert result.assigns.ai_features == []
    end

    test "handles nil consent_id gracefully" do
      socket = test_socket(%{ai_consent_id: nil})

      result = ConsentCheck.withdraw_consent(socket)

      assert result == socket
    end
  end
end
