defmodule AshfolioWeb.Hooks.ConsentCheck do
  @moduledoc """
  LiveView hook for checking AI feature consent.

  This hook can be used with `on_mount` to intercept access to AI features
  and show a consent modal if the user hasn't granted consent yet.

  ## Usage

  In your LiveView:

      use Phoenix.LiveView

      on_mount {AshfolioWeb.Hooks.ConsentCheck, :require_consent}

  Or for optional consent check (doesn't block, just sets assigns):

      on_mount {AshfolioWeb.Hooks.ConsentCheck, :check_consent}

  ## Assigns Set

  - `:has_ai_consent` - boolean, whether user has active consent
  - `:ai_privacy_mode` - atom, current privacy mode (or nil)
  - `:ai_features` - list of enabled features (or [])
  - `:show_consent_modal` - boolean, whether to show consent modal
  """

  import Phoenix.Component
  import Phoenix.LiveView

  alias Ashfolio.Legal.AiConsent
  alias Ashfolio.Legal.ConsentAudit

  @doc """
  Mount callback for checking AI feature consent.

  ## Modes

  - `:require_consent` - If no consent exists, sets `show_consent_modal: true`
    so the LiveView can display the consent modal.
  - `:check_consent` - Sets consent-related assigns but doesn't block or show modal.
  """
  def on_mount(mode, params, session, socket)

  def on_mount(:require_consent, _params, _session, socket) do
    socket = check_consent_status(socket)

    if socket.assigns.has_ai_consent do
      {:cont, socket}
    else
      {:cont, assign(socket, :show_consent_modal, true)}
    end
  end

  def on_mount(:check_consent, _params, _session, socket) do
    {:cont, check_consent_status(socket)}
  end

  @doc """
  Checks if the current user has granted consent for a specific feature.
  """
  def has_feature?(socket, feature) when is_atom(feature) do
    features = socket.assigns[:ai_features] || []
    feature in features
  end

  @doc """
  Gets the current privacy mode, defaulting to :strict if no consent.
  """
  def privacy_mode(socket) do
    socket.assigns[:ai_privacy_mode] || :strict
  end

  @doc """
  Checks consent status and returns updated socket with assigns.

  Can be called manually to refresh consent status.
  """
  def check_consent_status(socket) do
    case AiConsent.get_active() do
      {:ok, [consent]} ->
        socket
        |> assign(:has_ai_consent, true)
        |> assign(:ai_privacy_mode, consent.privacy_mode)
        |> assign(:ai_features, consent.features)
        |> assign(:ai_consent_id, consent.id)
        |> assign(:show_consent_modal, false)

      {:ok, []} ->
        socket
        |> assign(:has_ai_consent, false)
        |> assign(:ai_privacy_mode, nil)
        |> assign(:ai_features, [])
        |> assign(:ai_consent_id, nil)
        |> assign(:show_consent_modal, false)

      {:error, _reason} ->
        socket
        |> assign(:has_ai_consent, false)
        |> assign(:ai_privacy_mode, nil)
        |> assign(:ai_features, [])
        |> assign(:ai_consent_id, nil)
        |> assign(:show_consent_modal, false)
    end
  end

  @doc """
  Handles the consent granted message from ConsentModal.

  Call this from your LiveView's handle_info:

      def handle_info({:consent_granted, consent_data}, socket) do
        AshfolioWeb.Hooks.ConsentCheck.handle_consent_granted(socket, consent_data)
      end
  """
  def handle_consent_granted(socket, consent_data) do
    case AiConsent.grant(consent_data) do
      {:ok, consent} ->
        # Record in audit log
        ConsentAudit.record_grant(consent)

        socket
        |> assign(:has_ai_consent, true)
        |> assign(:ai_privacy_mode, consent.privacy_mode)
        |> assign(:ai_features, consent.features)
        |> assign(:ai_consent_id, consent.id)
        |> assign(:show_consent_modal, false)
        |> put_flash(:info, "AI features enabled successfully")

      {:error, _reason} ->
        put_flash(socket, :error, "Failed to save consent. Please try again.")
    end
  end

  @doc """
  Handles the consent declined message from ConsentModal.

  Call this from your LiveView's handle_info:

      def handle_info(:consent_declined, socket) do
        AshfolioWeb.Hooks.ConsentCheck.handle_consent_declined(socket)
      end
  """
  def handle_consent_declined(socket) do
    socket
    |> assign(:show_consent_modal, false)
    |> put_flash(:info, "AI features remain disabled. You can enable them anytime in Settings.")
  end

  @doc """
  Withdraws consent and updates socket assigns.
  """
  def withdraw_consent(socket) do
    consent_id = socket.assigns[:ai_consent_id]

    with {:ok, consent_id} <- ensure_consent_id(consent_id),
         {:ok, consent} <- Ash.get(AiConsent, consent_id),
         :ok <- do_withdraw(consent) do
      socket
      |> assign(:has_ai_consent, false)
      |> assign(:ai_privacy_mode, nil)
      |> assign(:ai_features, [])
      |> assign(:ai_consent_id, nil)
      |> put_flash(:info, "AI features disabled")
    else
      {:error, :no_consent} -> socket
      {:error, :not_found} -> socket
      {:error, :withdraw_failed} -> put_flash(socket, :error, "Failed to withdraw consent")
    end
  end

  defp ensure_consent_id(nil), do: {:error, :no_consent}
  defp ensure_consent_id(id), do: {:ok, id}

  defp do_withdraw(consent) do
    ConsentAudit.record_withdrawal(consent)

    case AiConsent.withdraw(consent) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :withdraw_failed}
    end
  end
end
