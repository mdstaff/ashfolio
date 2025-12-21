# Task: Consent UI Implementation

**Phase**: 3 - Legal & Consent
**Priority**: P1
**Estimate**: 4-6 hours
**Status**: Not Started

## Objective

Create a LiveView modal and flow for obtaining informed consent before enabling cloud LLM features, with clear disclosure of data handling practices.

## Prerequisites

- [ ] Task P3-01 (Consent Resource) complete
- [ ] UI/UX design for consent flow
- [ ] Legal-approved consent text

## Acceptance Criteria

### Functional Requirements

1. Modal appears on first AI feature access attempt
2. Clear explanation of data handling
3. Privacy mode selection with explanations
4. Checkbox for terms acceptance
5. Grant/Decline actions
6. Settings page for reviewing/revoking consent

### Non-Functional Requirements

1. Accessible (WCAG 2.1 AA)
2. Mobile responsive
3. Non-dismissible without action
4. Clear visual hierarchy

## TDD Test Cases

### Test File: `test/ashfolio_web/live/consent_modal_test.exs`

```elixir
defmodule AshfolioWeb.ConsentModalTest do
  use AshfolioWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Ashfolio.Legal.AiConsent

  describe "consent modal display" do
    test "modal appears when AI feature accessed without consent", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      # Attempt to access AI feature
      html = view
        |> element("[data-test=ai-assistant-button]")
        |> render_click()

      assert html =~ "AI Assistant Consent Required"
      assert html =~ "data-test=\"consent-modal\""
    end

    test "modal does not appear if consent already granted", %{conn: conn} do
      # Pre-grant consent
      AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: AiConsent.minimum_version(:mcp_tools)
      })

      {:ok, view, _html} = live(conn, ~p"/portfolio")

      html = view
        |> element("[data-test=ai-assistant-button]")
        |> render_click()

      refute html =~ "AI Assistant Consent Required"
    end

    test "modal appears if consent version outdated", %{conn: conn} do
      # Grant old version consent
      AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "0.9"  # Old version
      })

      {:ok, view, _html} = live(conn, ~p"/portfolio")

      html = view
        |> element("[data-test=ai-assistant-button]")
        |> render_click()

      assert html =~ "Updated Terms"
      assert html =~ "consent-modal"
    end
  end

  describe "consent modal content" do
    test "displays feature explanation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      html = view
        |> element("[data-test=ai-assistant-button]")
        |> render_click()

      assert html =~ "What this means"
      assert html =~ "Claude"
      assert html =~ "Anthropic"
    end

    test "displays privacy mode options", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      html = view
        |> element("[data-test=ai-assistant-button]")
        |> render_click()

      assert html =~ "Privacy Mode"
      assert html =~ "Anonymized"
      assert html =~ "Standard"
      assert html =~ "Full Access"
    end

    test "displays data handling explanation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      html = view
        |> element("[data-test=ai-assistant-button]")
        |> render_click()

      assert html =~ "What data is shared"
      assert html =~ "Tool results are sent to Anthropic"
    end

    test "has terms checkbox", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      html = view
        |> element("[data-test=ai-assistant-button]")
        |> render_click()

      assert html =~ "I have read and agree"
      assert html =~ ~r/<input[^>]*type="checkbox"[^>]*data-test="terms-checkbox"/
    end

    test "displays link to full terms", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      html = view
        |> element("[data-test=ai-assistant-button]")
        |> render_click()

      assert html =~ ~r/<a[^>]*href="[^"]*terms[^"]*"/
    end
  end

  describe "privacy mode selection" do
    test "default selection is anonymized", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      view |> element("[data-test=ai-assistant-button]") |> render_click()

      assert has_element?(view, "[data-test=privacy-mode-anonymized][checked]")
    end

    test "selecting privacy mode updates explanation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      view |> element("[data-test=ai-assistant-button]") |> render_click()

      # Select full mode
      html = view
        |> element("[data-test=privacy-mode-full]")
        |> render_click()

      assert html =~ "all your portfolio data"
      assert html =~ "including actual balances"
    end

    test "strict mode shows warning about limited functionality", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      view |> element("[data-test=ai-assistant-button]") |> render_click()

      html = view
        |> element("[data-test=privacy-mode-strict]")
        |> render_click()

      assert html =~ "limited to aggregate"
      assert html =~ "detailed analysis will not be available"
    end
  end

  describe "consent granting" do
    test "grant button disabled until terms accepted", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      view |> element("[data-test=ai-assistant-button]") |> render_click()

      assert has_element?(view, "[data-test=grant-consent-button][disabled]")
    end

    test "grant button enabled after terms accepted", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      view |> element("[data-test=ai-assistant-button]") |> render_click()

      view |> element("[data-test=terms-checkbox]") |> render_click()

      refute has_element?(view, "[data-test=grant-consent-button][disabled]")
    end

    test "granting consent creates record", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      view |> element("[data-test=ai-assistant-button]") |> render_click()
      view |> element("[data-test=terms-checkbox]") |> render_click()
      view |> element("[data-test=grant-consent-button]") |> render_click()

      consent = AiConsent.current_consent(:mcp_tools)
      assert consent != nil
      assert consent.privacy_mode == :anonymized
    end

    test "granting consent with selected privacy mode", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      view |> element("[data-test=ai-assistant-button]") |> render_click()
      view |> element("[data-test=privacy-mode-standard]") |> render_click()
      view |> element("[data-test=terms-checkbox]") |> render_click()
      view |> element("[data-test=grant-consent-button]") |> render_click()

      consent = AiConsent.current_consent(:mcp_tools)
      assert consent.privacy_mode == :standard
    end

    test "modal closes after consent granted", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      view |> element("[data-test=ai-assistant-button]") |> render_click()
      view |> element("[data-test=terms-checkbox]") |> render_click()
      html = view |> element("[data-test=grant-consent-button]") |> render_click()

      refute html =~ "consent-modal"
    end

    test "AI feature becomes available after consent", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      view |> element("[data-test=ai-assistant-button]") |> render_click()
      view |> element("[data-test=terms-checkbox]") |> render_click()
      view |> element("[data-test=grant-consent-button]") |> render_click()

      # Now AI assistant should open
      html = render(view)
      assert html =~ "AI Assistant" or html =~ "data-test=\"ai-panel\""
    end
  end

  describe "consent declining" do
    test "decline button closes modal without consent", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      view |> element("[data-test=ai-assistant-button]") |> render_click()
      html = view |> element("[data-test=decline-consent-button]") |> render_click()

      refute html =~ "consent-modal"
      assert AiConsent.current_consent(:mcp_tools) == nil
    end

    test "AI feature remains unavailable after decline", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      view |> element("[data-test=ai-assistant-button]") |> render_click()
      view |> element("[data-test=decline-consent-button]") |> render_click()

      # Try to access AI again
      html = view |> element("[data-test=ai-assistant-button]") |> render_click()

      # Modal should appear again
      assert html =~ "consent-modal"
    end
  end

  describe "modal accessibility" do
    test "modal has proper ARIA attributes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      html = view |> element("[data-test=ai-assistant-button]") |> render_click()

      assert html =~ ~r/role="dialog"/
      assert html =~ ~r/aria-labelledby=/
      assert html =~ ~r/aria-modal="true"/
    end

    test "focus is trapped in modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      view |> element("[data-test=ai-assistant-button]") |> render_click()

      assert has_element?(view, "[data-test=consent-modal][data-focus-trap]")
    end

    test "escape key does not close modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/portfolio")

      view |> element("[data-test=ai-assistant-button]") |> render_click()

      html = render_keydown(view, "Escape")

      # Modal should still be present
      assert html =~ "consent-modal"
    end
  end
end
```

## Implementation Steps

### Step 1: Create Consent Modal Component

```elixir
# lib/ashfolio_web/components/consent_modal.ex

defmodule AshfolioWeb.Components.ConsentModal do
  @moduledoc """
  Modal component for obtaining informed consent for AI features.
  """

  use AshfolioWeb, :live_component

  alias Ashfolio.Legal.AiConsent

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:privacy_mode, :anonymized)
     |> assign(:terms_accepted, false)
     |> assign(:show_mode_details, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="consent-modal"
      data-test="consent-modal"
      role="dialog"
      aria-labelledby="consent-title"
      aria-modal="true"
      data-focus-trap
      class="fixed inset-0 z-50 flex items-center justify-center"
      phx-window-keydown="noop"
      phx-key="Escape"
    >
      <!-- Backdrop -->
      <div class="absolute inset-0 bg-gray-900/50" />

      <!-- Modal -->
      <div class="relative bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <!-- Header -->
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 id="consent-title" class="text-xl font-semibold text-gray-900">
            <%= if @version_update do %>
              Updated Terms - AI Assistant Consent Required
            <% else %>
              AI Assistant Consent Required
            <% end %>
          </h2>
        </div>

        <!-- Content -->
        <div class="px-6 py-4 space-y-6">
          <!-- What this means -->
          <section>
            <h3 class="font-medium text-gray-900 mb-2">What this means</h3>
            <p class="text-gray-600 text-sm">
              The AI Assistant uses Claude, an AI model by Anthropic, to help you
              analyze your portfolio and answer financial questions. To provide
              helpful responses, some of your portfolio data may be shared with
              Anthropic's servers.
            </p>
          </section>

          <!-- What data is shared -->
          <section>
            <h3 class="font-medium text-gray-900 mb-2">What data is shared</h3>
            <p class="text-gray-600 text-sm mb-2">
              Tool results are sent to Anthropic as part of the conversation context.
              The privacy mode you select determines what data is included:
            </p>
          </section>

          <!-- Privacy Mode Selection -->
          <section class="bg-gray-50 rounded-lg p-4">
            <h3 class="font-medium text-gray-900 mb-3">Privacy Mode</h3>

            <div class="space-y-3">
              <.privacy_option
                mode={:anonymized}
                selected={@privacy_mode}
                title="Anonymized (Recommended)"
                description="Account names become letters (A, B, C), balances become percentages, symbols become asset classes."
                target={@myself}
              />

              <.privacy_option
                mode={:standard}
                selected={@privacy_mode}
                title="Standard"
                description="Account names and symbols visible, but exact balances hidden."
                target={@myself}
              />

              <.privacy_option
                mode={:full}
                selected={@privacy_mode}
                title="Full Access"
                description="All portfolio data shared including actual balances and account details."
                target={@myself}
              />

              <.privacy_option
                mode={:strict}
                selected={@privacy_mode}
                title="Strict (Limited)"
                description="Only aggregate summaries shared. Detailed analysis not available."
                target={@myself}
              />
            </div>

            <!-- Mode-specific explanation -->
            <div class="mt-4 p-3 bg-white rounded border border-gray-200">
              <.mode_explanation mode={@privacy_mode} />
            </div>
          </section>

          <!-- Terms acceptance -->
          <section class="flex items-start space-x-3">
            <input
              type="checkbox"
              id="terms-checkbox"
              data-test="terms-checkbox"
              class="mt-1 h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              checked={@terms_accepted}
              phx-click="toggle_terms"
              phx-target={@myself}
            />
            <label for="terms-checkbox" class="text-sm text-gray-600">
              I have read and agree to the
              <a href="/terms/ai" target="_blank" class="text-blue-600 hover:underline">
                AI Feature Terms of Service
              </a>
              and understand how my data will be processed.
            </label>
          </section>
        </div>

        <!-- Footer -->
        <div class="px-6 py-4 border-t border-gray-200 flex justify-end space-x-3">
          <button
            type="button"
            data-test="decline-consent-button"
            class="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-md"
            phx-click="decline"
            phx-target={@myself}
          >
            No Thanks
          </button>

          <button
            type="button"
            data-test="grant-consent-button"
            class={[
              "px-4 py-2 text-sm font-medium rounded-md",
              if(@terms_accepted,
                do: "bg-blue-600 text-white hover:bg-blue-700",
                else: "bg-gray-200 text-gray-500 cursor-not-allowed"
              )
            ]}
            disabled={not @terms_accepted}
            phx-click="grant"
            phx-target={@myself}
          >
            Enable AI Assistant
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp privacy_option(assigns) do
    ~H"""
    <label class={[
      "flex items-start space-x-3 p-3 rounded-lg border cursor-pointer transition-colors",
      if(@selected == @mode, do: "border-blue-500 bg-blue-50", else: "border-gray-200 hover:bg-gray-50")
    ]}>
      <input
        type="radio"
        name="privacy_mode"
        data-test={"privacy-mode-#{@mode}"}
        class="mt-1 h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500"
        checked={@selected == @mode}
        phx-click="select_mode"
        phx-value-mode={@mode}
        phx-target={@target}
      />
      <div>
        <span class="font-medium text-gray-900"><%= @title %></span>
        <p class="text-sm text-gray-600"><%= @description %></p>
      </div>
    </label>
    """
  end

  defp mode_explanation(%{mode: :anonymized} = assigns) do
    ~H"""
    <p class="text-sm text-gray-600">
      <strong>Example:</strong> Instead of "Fidelity 401k: $125,432", Claude sees
      "Account A: 75% of portfolio (investment account)". Ratios and percentages
      remain accurate for analysis.
    </p>
    """
  end

  defp mode_explanation(%{mode: :standard} = assigns) do
    ~H"""
    <p class="text-sm text-gray-600">
      <strong>Example:</strong> Claude sees "Fidelity 401k: 75% of portfolio" with
      holdings like "VTI, VXUS" but not exact dollar amounts.
    </p>
    """
  end

  defp mode_explanation(%{mode: :full} = assigns) do
    ~H"""
    <p class="text-sm text-amber-700">
      <strong>Warning:</strong> All your portfolio data, including actual balances,
      account names, and transaction details will be shared with Anthropic.
    </p>
    """
  end

  defp mode_explanation(%{mode: :strict} = assigns) do
    ~H"""
    <p class="text-sm text-amber-700">
      <strong>Note:</strong> Only aggregate metrics like total account count and
      portfolio tier (e.g., "six figures") will be shared. Claude cannot provide
      detailed analysis in this mode.
    </p>
    """
  end

  @impl true
  def handle_event("select_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :privacy_mode, String.to_existing_atom(mode))}
  end

  @impl true
  def handle_event("toggle_terms", _, socket) do
    {:noreply, assign(socket, :terms_accepted, not socket.assigns.terms_accepted)}
  end

  @impl true
  def handle_event("grant", _, socket) do
    {:ok, _consent} = AiConsent.grant(%{
      feature: socket.assigns.feature,
      consent_version: AiConsent.minimum_version(socket.assigns.feature),
      privacy_mode: socket.assigns.privacy_mode,
      terms_hash: compute_terms_hash()
    })

    send(self(), {:consent_granted, socket.assigns.feature, socket.assigns.privacy_mode})
    {:noreply, socket}
  end

  @impl true
  def handle_event("decline", _, socket) do
    send(self(), {:consent_declined, socket.assigns.feature})
    {:noreply, socket}
  end

  @impl true
  def handle_event("noop", _, socket) do
    # Ignore escape key
    {:noreply, socket}
  end

  defp compute_terms_hash do
    # In production, hash the actual terms document
    :crypto.hash(:sha256, "AI Feature Terms v1.0")
    |> Base.encode16(case: :lower)
    |> then(&"sha256:#{&1}")
  end
end
```

### Step 2: Add Consent Check Hook

```elixir
# lib/ashfolio_web/hooks/consent_check.ex

defmodule AshfolioWeb.Hooks.ConsentCheck do
  @moduledoc """
  LiveView hook to check for AI feature consent.
  """

  import Phoenix.LiveView
  alias Ashfolio.Legal.AiConsent

  def on_mount(:require_mcp_consent, _params, _session, socket) do
    socket =
      socket
      |> attach_hook(:consent_check, :handle_event, &check_consent/3)

    {:cont, socket}
  end

  defp check_consent("ai_feature_request", %{"feature" => feature}, socket) do
    feature_atom = String.to_existing_atom(feature)
    version = AiConsent.minimum_version(feature_atom)

    if AiConsent.has_valid_consent?(feature_atom, version) do
      # Consent valid, let event through
      {:cont, socket}
    else
      # Show consent modal
      {:halt, assign(socket, :show_consent_modal, true, consent_feature: feature_atom)}
    end
  end

  defp check_consent(_event, _params, socket) do
    {:cont, socket}
  end
end
```

### Step 3: Run Tests

```bash
mix test test/ashfolio_web/live/consent_modal_test.exs --trace
```

## Definition of Done

- [ ] Consent modal component created
- [ ] Privacy mode selection works
- [ ] Terms acceptance required
- [ ] Grant creates consent record
- [ ] Decline closes without consent
- [ ] Modal is accessible (ARIA)
- [ ] All TDD tests pass
- [ ] `mix test` passes (no regressions)

## Dependencies

**Blocked By**: Task P3-01 (Consent Resource)
**Blocks**: Task P3-04 (Settings LiveView)

## Notes

- Legal review needed for consent text
- Consider adding "remember my choice" for privacy mode
- Future: Add consent renewal reminders

---

*Parent: [../README.md](../README.md)*
