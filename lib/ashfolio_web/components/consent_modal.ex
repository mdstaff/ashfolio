defmodule AshfolioWeb.Components.ConsentModal do
  @moduledoc """
  Modal component for AI feature consent management.

  Provides a user-friendly interface for:
  - Selecting privacy mode with clear explanations
  - Choosing which AI features to enable
  - Accepting terms and conditions
  - Granting or declining consent

  ARIA accessible with proper focus management.
  """

  use Phoenix.Component
  use Phoenix.LiveComponent

  import AshfolioWeb.CoreComponents, only: [icon: 1]

  alias Ashfolio.Legal.AiConsent

  @privacy_mode_info %{
    strict: %{
      title: "Strict Privacy",
      description: "Only aggregate data shared. No individual accounts, transactions, or amounts.",
      icon: "hero-shield-check",
      examples: ["Total portfolio value tier", "Account count", "Asset class percentages"]
    },
    anonymized: %{
      title: "Anonymized",
      description: "Accounts shown as letters (A, B, C). Amounts shown as relative weights.",
      icon: "hero-eye-slash",
      examples: ["Account A: 45% of portfolio", "Recent activity patterns", "Diversification score"]
    },
    standard: %{
      title: "Standard",
      description: "Account names visible, but exact dollar amounts remain hidden.",
      icon: "hero-eye",
      examples: ["Fidelity 401k: Large allocation", "Recent buy in Account B", "Monthly expense trends"]
    },
    full: %{
      title: "Full Access",
      description: "Complete data access including exact amounts. Best for detailed analysis.",
      icon: "hero-lock-open",
      examples: ["Fidelity 401k: $125,432", "Bought 10 AAPL @ $150", "Monthly expenses: $4,200"]
    }
  }

  @feature_info %{
    mcp_tools: %{
      title: "MCP Tools",
      description: "Allow AI assistants to query your portfolio data via the Model Context Protocol.",
      icon: "hero-wrench-screwdriver"
    },
    ai_analysis: %{
      title: "AI Analysis",
      description: "Enable AI-powered insights, recommendations, and portfolio analysis.",
      icon: "hero-chart-bar"
    },
    cloud_llm: %{
      title: "Cloud AI",
      description: "Use cloud-based AI models. When disabled, only local models are used.",
      icon: "hero-cloud"
    }
  }

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:selected_mode, :anonymized)
     |> assign(:selected_features, [:mcp_tools])
     |> assign(:terms_accepted, false)
     |> assign(:show_terms, false)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:on_grant, fn -> nil end)
     |> assign_new(:on_decline, fn -> nil end)
     |> assign_new(:terms_version, fn -> "1.0.0" end)
     |> assign_new(:terms_text, fn -> default_terms_text() end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class="fixed inset-0 z-50 overflow-y-auto"
      role="dialog"
      aria-modal="true"
      aria-labelledby={"#{@id}-title"}
    >
      <div class="flex min-h-full items-center justify-center p-4">
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true" />

        <div class="relative transform overflow-hidden rounded-lg bg-white shadow-xl transition-all sm:w-full sm:max-w-2xl">
          <div class="bg-white px-4 pb-4 pt-5 sm:p-6">
            <div class="sm:flex sm:items-start">
              <div class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-blue-100 sm:mx-0 sm:h-10 sm:w-10">
                <.icon name="hero-cpu-chip" class="h-6 w-6 text-blue-600" />
              </div>
              <div class="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left flex-1">
                <h3 class="text-lg font-semibold leading-6 text-gray-900" id={"#{@id}-title"}>
                  Enable AI Features
                </h3>
                <p class="mt-2 text-sm text-gray-500">
                  Choose how AI assistants can access your portfolio data.
                  You can change these settings anytime.
                </p>
              </div>
            </div>

            <div class="mt-6 space-y-6">
              <.privacy_mode_selector
                id={"#{@id}-privacy"}
                selected={@selected_mode}
                target={@myself}
              />

              <.feature_selector
                id={"#{@id}-features"}
                selected={@selected_features}
                target={@myself}
              />

              <.terms_section
                id={"#{@id}-terms"}
                accepted={@terms_accepted}
                show_terms={@show_terms}
                terms_text={@terms_text}
                target={@myself}
              />
            </div>
          </div>

          <div class="bg-gray-50 px-4 py-3 sm:flex sm:flex-row-reverse sm:px-6 gap-3">
            <button
              type="button"
              phx-click="grant_consent"
              phx-target={@myself}
              disabled={not @terms_accepted or @selected_features == []}
              class={[
                "inline-flex w-full justify-center rounded-md px-3 py-2 text-sm font-semibold shadow-sm sm:w-auto",
                if(@terms_accepted and @selected_features != [],
                  do: "bg-blue-600 text-white hover:bg-blue-500",
                  else: "bg-gray-300 text-gray-500 cursor-not-allowed"
                )
              ]}
            >
              Enable AI Features
            </button>
            <button
              type="button"
              phx-click="decline_consent"
              phx-target={@myself}
              class="mt-3 inline-flex w-full justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 sm:mt-0 sm:w-auto"
            >
              Not Now
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :selected, :atom, required: true
  attr :target, :any, required: true

  defp privacy_mode_selector(assigns) do
    assigns = assign(assigns, :modes, @privacy_mode_info)

    ~H"""
    <fieldset id={@id}>
      <legend class="text-sm font-medium text-gray-900">Privacy Level</legend>
      <p class="text-xs text-gray-500 mt-1">Choose how much data AI can access</p>

      <div class="mt-3 grid grid-cols-2 gap-3">
        <div
          :for={{mode, info} <- @modes}
          phx-click="select_mode"
          phx-value-mode={mode}
          phx-target={@target}
          role="radio"
          aria-checked={@selected == mode}
          tabindex="0"
          class={[
            "relative flex cursor-pointer rounded-lg border p-4 focus:outline-none",
            if(@selected == mode,
              do: "border-blue-600 ring-2 ring-blue-600",
              else: "border-gray-300 hover:border-gray-400"
            )
          ]}
        >
          <div class="flex w-full items-center justify-between">
            <div class="flex items-center">
              <div class="text-sm">
                <div class="flex items-center gap-2">
                  <.icon name={info.icon} class="h-5 w-5 text-gray-600" />
                  <span class="font-medium text-gray-900">{info.title}</span>
                </div>
                <p class="mt-1 text-xs text-gray-500">{info.description}</p>
              </div>
            </div>
            <div
              :if={@selected == mode}
              class="h-5 w-5 flex-shrink-0 text-blue-600"
            >
              <.icon name="hero-check-circle-solid" class="h-5 w-5" />
            </div>
          </div>
        </div>
      </div>
    </fieldset>
    """
  end

  attr :id, :string, required: true
  attr :selected, :list, required: true
  attr :target, :any, required: true

  defp feature_selector(assigns) do
    assigns = assign(assigns, :features, @feature_info)

    ~H"""
    <fieldset id={@id}>
      <legend class="text-sm font-medium text-gray-900">AI Features</legend>
      <p class="text-xs text-gray-500 mt-1">Select which features to enable</p>

      <div class="mt-3 space-y-3">
        <div
          :for={{feature, info} <- @features}
          class="relative flex items-start"
        >
          <div class="flex h-6 items-center">
            <input
              type="checkbox"
              id={"feature-#{feature}"}
              name={"feature-#{feature}"}
              checked={feature in @selected}
              phx-click="toggle_feature"
              phx-value-feature={feature}
              phx-target={@target}
              class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-600"
            />
          </div>
          <div class="ml-3">
            <label for={"feature-#{feature}"} class="flex items-center gap-2 text-sm font-medium text-gray-900">
              <.icon name={info.icon} class="h-4 w-4 text-gray-500" />
              {info.title}
            </label>
            <p class="text-xs text-gray-500">{info.description}</p>
          </div>
        </div>
      </div>
    </fieldset>
    """
  end

  attr :id, :string, required: true
  attr :accepted, :boolean, required: true
  attr :show_terms, :boolean, required: true
  attr :terms_text, :string, required: true
  attr :target, :any, required: true

  defp terms_section(assigns) do
    ~H"""
    <div id={@id} class="border-t pt-4">
      <div class="flex items-start">
        <div class="flex h-6 items-center">
          <input
            type="checkbox"
            id="terms-checkbox"
            name="terms-checkbox"
            checked={@accepted}
            phx-click="toggle_terms"
            phx-target={@target}
            class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-600"
            aria-describedby="terms-description"
          />
        </div>
        <div class="ml-3">
          <label for="terms-checkbox" class="text-sm font-medium text-gray-900">
            I accept the AI usage terms
          </label>
          <p id="terms-description" class="text-xs text-gray-500">
            Your data is processed according to our privacy policy.
            <button
              type="button"
              phx-click="toggle_show_terms"
              phx-target={@target}
              class="text-blue-600 hover:text-blue-500 underline ml-1"
            >
              {if @show_terms, do: "Hide terms", else: "View terms"}
            </button>
          </p>
        </div>
      </div>

      <div
        :if={@show_terms}
        class="mt-3 max-h-40 overflow-y-auto rounded-md bg-gray-50 p-3 text-xs text-gray-600"
      >
        <pre class="whitespace-pre-wrap font-sans">{@terms_text}</pre>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("select_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :selected_mode, String.to_existing_atom(mode))}
  end

  def handle_event("toggle_feature", %{"feature" => feature}, socket) do
    feature_atom = String.to_existing_atom(feature)
    current = socket.assigns.selected_features

    new_features =
      if feature_atom in current do
        List.delete(current, feature_atom)
      else
        [feature_atom | current]
      end

    {:noreply, assign(socket, :selected_features, new_features)}
  end

  def handle_event("toggle_terms", _params, socket) do
    {:noreply, assign(socket, :terms_accepted, not socket.assigns.terms_accepted)}
  end

  def handle_event("toggle_show_terms", _params, socket) do
    {:noreply, assign(socket, :show_terms, not socket.assigns.show_terms)}
  end

  def handle_event("grant_consent", _params, socket) do
    %{
      selected_mode: mode,
      selected_features: features,
      terms_version: version,
      terms_text: text,
      on_grant: callback
    } = socket.assigns

    consent_data = %{
      privacy_mode: mode,
      features: features,
      terms_version: version,
      terms_hash: AiConsent.hash_terms(text)
    }

    if callback do
      send(self(), {:consent_granted, consent_data})
    end

    {:noreply, socket}
  end

  def handle_event("decline_consent", _params, socket) do
    if socket.assigns.on_decline do
      send(self(), :consent_declined)
    end

    {:noreply, socket}
  end

  defp default_terms_text do
    """
    AI Feature Terms of Use

    By enabling AI features, you agree to the following:

    1. DATA ACCESS
    Your portfolio data will be accessible to AI systems according to your selected privacy level. You can change this setting at any time.

    2. DATA PROCESSING
    - Strict: Only aggregate statistics are processed
    - Anonymized: Data is processed without identifying information
    - Standard: Names visible, amounts hidden
    - Full: Complete data access for detailed analysis

    3. DATA STORAGE
    AI interactions may be temporarily cached to improve response times. No personal data is permanently stored by AI systems.

    4. THIRD-PARTY SERVICES
    If "Cloud AI" is enabled, data may be sent to third-party AI providers. All transfers are encrypted and providers are contractually bound to data protection standards.

    5. YOUR RIGHTS
    You can withdraw consent at any time through Settings > AI Settings. Upon withdrawal, all AI access will be immediately revoked.

    6. GDPR COMPLIANCE
    You may request data export or deletion at any time through the AI Settings page.
    """
  end
end
