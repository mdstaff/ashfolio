defmodule AshfolioWeb.Settings.AiSettingsLive do
  @moduledoc """
  LiveView for managing AI feature settings.

  Provides:
  - Consent status display
  - Privacy mode change with confirmation
  - Consent revocation
  - GDPR data export
  """

  use AshfolioWeb, :live_view

  alias Ashfolio.Legal.AiConsent
  alias Ashfolio.Legal.ConsentAudit
  alias AshfolioWeb.Components.ConsentModal
  alias AshfolioWeb.Hooks.ConsentCheck

  @privacy_mode_labels %{
    strict: "Strict Privacy",
    anonymized: "Anonymized",
    standard: "Standard",
    full: "Full Access"
  }

  @privacy_mode_descriptions %{
    strict: "Only aggregate data shared. No individual accounts, transactions, or amounts.",
    anonymized: "Accounts shown as letters (A, B, C). Amounts shown as relative weights.",
    standard: "Account names visible, but exact dollar amounts remain hidden.",
    full: "Complete data access including exact amounts. Best for detailed analysis."
  }

  @feature_labels %{
    mcp_tools: "MCP Tools",
    ai_analysis: "AI Analysis",
    cloud_llm: "Cloud AI"
  }

  # Expose module attributes for template use
  defp privacy_mode_labels, do: @privacy_mode_labels
  defp privacy_mode_descriptions, do: @privacy_mode_descriptions
  defp feature_labels, do: @feature_labels

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_current_page(:settings)
      |> assign(:page_title, "AI Settings")
      |> assign(:page_subtitle, "Manage AI feature access and privacy")
      |> assign(:show_consent_modal, false)
      |> assign(:show_privacy_change_modal, false)
      |> assign(:show_revoke_confirm, false)
      |> assign(:new_privacy_mode, nil)
      |> assign(:exporting, false)
      |> assign(:privacy_mode_labels, privacy_mode_labels())
      |> assign(:privacy_mode_descriptions, privacy_mode_descriptions())
      |> assign(:feature_labels, feature_labels())
      |> load_consent_status()

    {:ok, socket}
  end

  @impl true
  def handle_event("enable_ai", _params, socket) do
    {:noreply, assign(socket, :show_consent_modal, true)}
  end

  @impl true
  def handle_event("close_consent_modal", _params, socket) do
    {:noreply, assign(socket, :show_consent_modal, false)}
  end

  @impl true
  def handle_event("change_privacy_mode", %{"mode" => mode}, socket) do
    new_mode = String.to_existing_atom(mode)

    {:noreply,
     socket
     |> assign(:show_privacy_change_modal, true)
     |> assign(:new_privacy_mode, new_mode)}
  end

  @impl true
  def handle_event("confirm_privacy_change", _params, socket) do
    new_mode = socket.assigns.new_privacy_mode
    consent_id = socket.assigns.ai_consent_id

    case Ash.get(AiConsent, consent_id) do
      {:ok, consent} ->
        old_mode = consent.privacy_mode

        case AiConsent.update_privacy_mode(consent, %{privacy_mode: new_mode}) do
          {:ok, updated_consent} ->
            ConsentAudit.record_privacy_mode_change(consent, old_mode, new_mode)

            {:noreply,
             socket
             |> assign(:show_privacy_change_modal, false)
             |> assign(:new_privacy_mode, nil)
             |> assign(:ai_privacy_mode, updated_consent.privacy_mode)
             |> put_flash(:info, "Privacy mode updated to #{@privacy_mode_labels[new_mode]}")}

          {:error, _reason} ->
            {:noreply,
             socket
             |> assign(:show_privacy_change_modal, false)
             |> put_flash(:error, "Failed to update privacy mode")}
        end

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:show_privacy_change_modal, false)
         |> put_flash(:error, "Consent record not found")}
    end
  end

  @impl true
  def handle_event("cancel_privacy_change", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_privacy_change_modal, false)
     |> assign(:new_privacy_mode, nil)}
  end

  @impl true
  def handle_event("show_revoke_confirm", _params, socket) do
    {:noreply, assign(socket, :show_revoke_confirm, true)}
  end

  @impl true
  def handle_event("cancel_revoke", _params, socket) do
    {:noreply, assign(socket, :show_revoke_confirm, false)}
  end

  @impl true
  def handle_event("confirm_revoke", _params, socket) do
    socket = ConsentCheck.withdraw_consent(socket)

    {:noreply,
     socket
     |> assign(:show_revoke_confirm, false)
     |> load_consent_status()}
  end

  @impl true
  def handle_event("export_data", _params, socket) do
    socket = assign(socket, :exporting, true)

    # Record the export request
    ConsentAudit.record_gdpr_export()

    # Generate export data
    export_data = generate_export_data(socket.assigns.ai_consent_id)

    # In a real implementation, this would trigger a download
    # For now, we'll show a success message with the data summary
    {:noreply,
     socket
     |> assign(:exporting, false)
     |> assign(:export_data, export_data)
     |> put_flash(:info, "Data export generated. #{export_data.record_count} records included.")}
  end

  @impl true
  def handle_info({:consent_granted, consent_data}, socket) do
    socket = ConsentCheck.handle_consent_granted(socket, consent_data)

    {:noreply,
     socket
     |> assign(:show_consent_modal, false)
     |> load_consent_status()}
  end

  @impl true
  def handle_info(:consent_declined, socket) do
    {:noreply,
     socket
     |> assign(:show_consent_modal, false)
     |> put_flash(:info, "AI features remain disabled")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="py-6">
        <!-- Header -->
        <div class="mb-8">
          <h1 class="text-2xl font-bold text-gray-900">{@page_title}</h1>
          <p class="mt-1 text-sm text-gray-600">{@page_subtitle}</p>
        </div>
        
    <!-- Consent Status Card -->
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 mb-6">
          <div class="px-6 py-5">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-4">
                <div class={[
                  "w-12 h-12 rounded-full flex items-center justify-center",
                  if(@has_ai_consent, do: "bg-green-100", else: "bg-gray-100")
                ]}>
                  <.icon
                    name={if(@has_ai_consent, do: "hero-check-circle", else: "hero-x-circle")}
                    class={"h-7 w-7 #{if(@has_ai_consent, do: "text-green-600", else: "text-gray-400")}"}
                  />
                </div>
                <div>
                  <h2 class="text-lg font-semibold text-gray-900">
                    AI Features
                  </h2>
                  <p class="text-sm text-gray-500">
                    {if @has_ai_consent, do: "Enabled", else: "Disabled"}
                  </p>
                </div>
              </div>

              <button
                :if={!@has_ai_consent}
                type="button"
                phx-click="enable_ai"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                <.icon name="hero-cpu-chip" class="h-4 w-4 mr-2" /> Enable AI Features
              </button>
            </div>
          </div>
        </div>
        
    <!-- Active Consent Details -->
        <div :if={@has_ai_consent} class="space-y-6">
          <!-- Privacy Mode Section -->
          <div class="bg-white rounded-lg shadow-sm border border-gray-200">
            <div class="px-6 py-5 border-b border-gray-200">
              <h3 class="text-lg font-medium text-gray-900">Privacy Mode</h3>
              <p class="mt-1 text-sm text-gray-500">
                Control how much data AI assistants can access
              </p>
            </div>
            <div class="px-6 py-5">
              <div class="grid gap-4 sm:grid-cols-2">
                <.privacy_mode_option
                  :for={mode <- [:strict, :anonymized, :standard, :full]}
                  mode={mode}
                  current={@ai_privacy_mode}
                  label={@privacy_mode_labels[mode]}
                  description={@privacy_mode_descriptions[mode]}
                />
              </div>
            </div>
          </div>
          
    <!-- Enabled Features Section -->
          <div class="bg-white rounded-lg shadow-sm border border-gray-200">
            <div class="px-6 py-5 border-b border-gray-200">
              <h3 class="text-lg font-medium text-gray-900">Enabled Features</h3>
              <p class="mt-1 text-sm text-gray-500">
                Features currently available to AI assistants
              </p>
            </div>
            <div class="px-6 py-5">
              <div class="space-y-3">
                <.feature_badge
                  :for={feature <- [:mcp_tools, :ai_analysis, :cloud_llm]}
                  feature={feature}
                  enabled={feature in (@ai_features || [])}
                  label={@feature_labels[feature]}
                />
              </div>
            </div>
          </div>
          
    <!-- GDPR Section -->
          <div class="bg-white rounded-lg shadow-sm border border-gray-200">
            <div class="px-6 py-5 border-b border-gray-200">
              <h3 class="text-lg font-medium text-gray-900">Data & Privacy</h3>
              <p class="mt-1 text-sm text-gray-500">
                Manage your data under GDPR
              </p>
            </div>
            <div class="px-6 py-5">
              <div class="flex flex-col sm:flex-row gap-4">
                <button
                  type="button"
                  phx-click="export_data"
                  disabled={@exporting}
                  class="inline-flex items-center justify-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
                >
                  <%= if @exporting do %>
                    <svg
                      class="animate-spin -ml-1 mr-2 h-4 w-4 text-gray-500"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                    >
                      <circle
                        class="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        stroke-width="4"
                      >
                      </circle>
                      <path
                        class="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      >
                      </path>
                    </svg>
                    Exporting...
                  <% else %>
                    <.icon name="hero-arrow-down-tray" class="h-4 w-4 mr-2" /> Export My Data
                  <% end %>
                </button>

                <button
                  type="button"
                  phx-click="show_revoke_confirm"
                  class="inline-flex items-center justify-center px-4 py-2 border border-red-300 shadow-sm text-sm font-medium rounded-md text-red-700 bg-white hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                >
                  <.icon name="hero-shield-exclamation" class="h-4 w-4 mr-2" /> Revoke Consent
                </button>
              </div>

              <p class="mt-4 text-xs text-gray-500">
                Revoking consent will immediately disable all AI features and stop data sharing.
              </p>
            </div>
          </div>
        </div>
        
    <!-- No Consent State -->
        <div
          :if={!@has_ai_consent}
          class="bg-gray-50 rounded-lg border-2 border-dashed border-gray-300 p-8 text-center"
        >
          <.icon name="hero-cpu-chip" class="mx-auto h-12 w-12 text-gray-400" />
          <h3 class="mt-4 text-lg font-medium text-gray-900">AI Features Not Enabled</h3>
          <p class="mt-2 text-sm text-gray-500 max-w-md mx-auto">
            Enable AI features to get intelligent insights, use MCP tools, and more.
            You'll choose your privacy level and which features to enable.
          </p>
          <button
            type="button"
            phx-click="enable_ai"
            class="mt-6 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            Get Started
          </button>
        </div>
      </div>
    </div>

    <!-- Consent Modal -->
    <.live_component
      :if={@show_consent_modal}
      module={ConsentModal}
      id="ai-consent-modal"
      on_grant={true}
      on_decline={true}
    />

    <!-- Privacy Change Confirmation Modal -->
    <.privacy_change_modal
      :if={@show_privacy_change_modal}
      current_mode={@ai_privacy_mode}
      new_mode={@new_privacy_mode}
      current_label={@privacy_mode_labels[@ai_privacy_mode]}
      new_label={@privacy_mode_labels[@new_privacy_mode]}
    />

    <!-- Revoke Confirmation Modal -->
    <.revoke_confirm_modal :if={@show_revoke_confirm} />
    """
  end

  attr :mode, :atom, required: true
  attr :current, :atom, required: true
  attr :label, :string, required: true
  attr :description, :string, required: true

  defp privacy_mode_option(assigns) do
    ~H"""
    <div
      phx-click="change_privacy_mode"
      phx-value-mode={@mode}
      class={[
        "relative flex cursor-pointer rounded-lg border p-4 focus:outline-none",
        if(@current == @mode,
          do: "border-blue-600 ring-2 ring-blue-600 bg-blue-50",
          else: "border-gray-300 hover:border-gray-400 bg-white"
        )
      ]}
    >
      <div class="flex w-full items-center justify-between">
        <div class="text-sm">
          <p class={[
            "font-medium",
            if(@current == @mode, do: "text-blue-900", else: "text-gray-900")
          ]}>
            {@label}
          </p>
          <p class={[
            "mt-1 text-xs",
            if(@current == @mode, do: "text-blue-700", else: "text-gray-500")
          ]}>
            {@description}
          </p>
        </div>
        <div :if={@current == @mode} class="flex-shrink-0">
          <.icon name="hero-check-circle-solid" class="h-5 w-5 text-blue-600" />
        </div>
      </div>
    </div>
    """
  end

  attr :feature, :atom, required: true
  attr :enabled, :boolean, required: true
  attr :label, :string, required: true

  defp feature_badge(assigns) do
    ~H"""
    <div class="flex items-center justify-between py-2">
      <span class="text-sm text-gray-700">{@label}</span>
      <span class={[
        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
        if(@enabled,
          do: "bg-green-100 text-green-800",
          else: "bg-gray-100 text-gray-600"
        )
      ]}>
        {if @enabled, do: "Enabled", else: "Disabled"}
      </span>
    </div>
    """
  end

  attr :current_mode, :atom, required: true
  attr :new_mode, :atom, required: true
  attr :current_label, :string, required: true
  attr :new_label, :string, required: true

  defp privacy_change_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 overflow-y-auto" role="dialog" aria-modal="true">
      <div class="flex min-h-full items-center justify-center p-4">
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true" />

        <div class="relative transform overflow-hidden rounded-lg bg-white shadow-xl transition-all sm:w-full sm:max-w-lg">
          <div class="bg-white px-4 pb-4 pt-5 sm:p-6">
            <div class="sm:flex sm:items-start">
              <div class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-blue-100 sm:mx-0 sm:h-10 sm:w-10">
                <.icon name="hero-shield-check" class="h-6 w-6 text-blue-600" />
              </div>
              <div class="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left">
                <h3 class="text-lg font-semibold leading-6 text-gray-900">
                  Change Privacy Mode
                </h3>
                <div class="mt-2">
                  <p class="text-sm text-gray-500">
                    Change privacy mode from <strong>{@current_label}</strong>
                    to <strong>{@new_label}</strong>?
                  </p>
                  <p class="mt-2 text-sm text-gray-500">
                    This will affect how much data AI assistants can access.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-gray-50 px-4 py-3 sm:flex sm:flex-row-reverse sm:px-6 gap-3">
            <button
              type="button"
              phx-click="confirm_privacy_change"
              class="inline-flex w-full justify-center rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 sm:w-auto"
            >
              Confirm Change
            </button>
            <button
              type="button"
              phx-click="cancel_privacy_change"
              class="mt-3 inline-flex w-full justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 sm:mt-0 sm:w-auto"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp revoke_confirm_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 overflow-y-auto" role="dialog" aria-modal="true">
      <div class="flex min-h-full items-center justify-center p-4">
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true" />

        <div class="relative transform overflow-hidden rounded-lg bg-white shadow-xl transition-all sm:w-full sm:max-w-lg">
          <div class="bg-white px-4 pb-4 pt-5 sm:p-6">
            <div class="sm:flex sm:items-start">
              <div class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10">
                <.icon name="hero-exclamation-triangle" class="h-6 w-6 text-red-600" />
              </div>
              <div class="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left">
                <h3 class="text-lg font-semibold leading-6 text-gray-900">
                  Revoke AI Consent
                </h3>
                <div class="mt-2">
                  <p class="text-sm text-gray-500">
                    Are you sure you want to revoke consent for AI features?
                    This will:
                  </p>
                  <ul class="mt-2 text-sm text-gray-500 list-disc pl-5 space-y-1">
                    <li>Immediately disable all AI features</li>
                    <li>Stop all data sharing with AI systems</li>
                    <li>Remove your current privacy settings</li>
                  </ul>
                  <p class="mt-2 text-sm text-gray-500">
                    You can re-enable AI features at any time by granting consent again.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-gray-50 px-4 py-3 sm:flex sm:flex-row-reverse sm:px-6 gap-3">
            <button
              type="button"
              phx-click="confirm_revoke"
              class="inline-flex w-full justify-center rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 sm:w-auto"
            >
              Revoke Consent
            </button>
            <button
              type="button"
              phx-click="cancel_revoke"
              class="mt-3 inline-flex w-full justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 sm:mt-0 sm:w-auto"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp load_consent_status(socket) do
    case AiConsent.get_active() do
      {:ok, [consent]} ->
        socket
        |> assign(:has_ai_consent, true)
        |> assign(:ai_privacy_mode, consent.privacy_mode)
        |> assign(:ai_features, consent.features)
        |> assign(:ai_consent_id, consent.id)
        |> assign(:consent_granted_at, consent.inserted_at)

      {:ok, []} ->
        socket
        |> assign(:has_ai_consent, false)
        |> assign(:ai_privacy_mode, nil)
        |> assign(:ai_features, [])
        |> assign(:ai_consent_id, nil)
        |> assign(:consent_granted_at, nil)

      {:error, _reason} ->
        socket
        |> assign(:has_ai_consent, false)
        |> assign(:ai_privacy_mode, nil)
        |> assign(:ai_features, [])
        |> assign(:ai_consent_id, nil)
        |> assign(:consent_granted_at, nil)
    end
  end

  defp generate_export_data(consent_id) when is_nil(consent_id) do
    %{
      record_count: 0,
      consent: nil,
      audit_records: []
    }
  end

  defp generate_export_data(consent_id) do
    consent =
      case Ash.get(AiConsent, consent_id) do
        {:ok, c} -> c
        _ -> nil
      end

    audit_records =
      case ConsentAudit.for_consent(consent_id) do
        {:ok, records} -> records
        _ -> []
      end

    %{
      record_count: length(audit_records) + if(consent, do: 1, else: 0),
      consent: consent,
      audit_records: audit_records
    }
  end
end
