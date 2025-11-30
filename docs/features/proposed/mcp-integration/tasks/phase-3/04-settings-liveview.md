# Task: AI Settings LiveView

**Phase**: 3 - Legal & Consent
**Priority**: P2
**Estimate**: 4-6 hours
**Status**: Not Started

## Objective

Create a settings page for managing AI/MCP features including privacy mode configuration, consent review, and audit log viewing.

## Prerequisites

- [ ] Tasks P3-01, P3-02, P3-03 complete
- [ ] UI design for settings page

## Acceptance Criteria

### Functional Requirements

1. View current consent status per feature
2. Change privacy mode (with confirmation)
3. Revoke consent with confirmation
4. View recent audit log entries
5. Export consent data (GDPR)

### Non-Functional Requirements

1. Real-time updates via PubSub
2. Accessible (WCAG 2.1 AA)
3. Mobile responsive

## TDD Test Cases

### Test File: `test/ashfolio_web/live/settings/ai_settings_live_test.exs`

```elixir
defmodule AshfolioWeb.Settings.AiSettingsLiveTest do
  use AshfolioWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Ashfolio.Legal.AiConsent
  alias AshfolioWeb.Mcp.AuditLog

  describe "settings page navigation" do
    test "settings page is accessible", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      assert html =~ "AI Settings"
    end

    test "shows link from main settings", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      html = view |> element("a[href='/settings/ai']") |> render()
      assert html =~ "AI Assistant"
    end
  end

  describe "consent status display" do
    test "shows 'Not Enabled' when no consent", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      assert html =~ "Not Enabled"
      assert html =~ "Enable AI Assistant"
    end

    test "shows consent details when enabled", %{conn: conn} do
      AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0",
        privacy_mode: :anonymized
      })

      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      assert html =~ "Enabled"
      assert html =~ "Anonymized"
      assert html =~ "Version 1.0"
    end

    test "shows consent date", %{conn: conn} do
      {:ok, consent} = AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0"
      })

      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      # Date should be formatted
      date_str = Calendar.strftime(consent.granted_at, "%B %d, %Y")
      assert html =~ date_str or html =~ "today"
    end
  end

  describe "privacy mode management" do
    setup do
      AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0",
        privacy_mode: :anonymized
      })
      :ok
    end

    test "displays current privacy mode", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      assert html =~ "data-test=\"current-privacy-mode\""
      assert html =~ "Anonymized"
    end

    test "allows changing privacy mode", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      # Click change button
      view |> element("[data-test=change-privacy-mode]") |> render_click()

      # Modal should appear
      assert has_element?(view, "[data-test=privacy-mode-modal]")
    end

    test "changing privacy mode requires confirmation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      view |> element("[data-test=change-privacy-mode]") |> render_click()
      view |> element("[data-test=privacy-option-full]") |> render_click()

      # Confirmation should appear
      assert has_element?(view, "[data-test=confirm-privacy-change]")
      html = render(view)
      assert html =~ "Are you sure"
    end

    test "confirmed privacy change updates consent", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      view |> element("[data-test=change-privacy-mode]") |> render_click()
      view |> element("[data-test=privacy-option-standard]") |> render_click()
      view |> element("[data-test=confirm-privacy-change]") |> render_click()

      # Consent should be updated
      consent = AiConsent.current_consent(:mcp_tools)
      assert consent.privacy_mode == :standard
    end
  end

  describe "consent revocation" do
    setup do
      AiConsent.grant(%{
        feature: :mcp_tools,
        consent_version: "1.0"
      })
      :ok
    end

    test "shows revoke button when enabled", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      assert html =~ "data-test=\"revoke-consent\""
    end

    test "revoke requires confirmation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      view |> element("[data-test=revoke-consent]") |> render_click()

      assert has_element?(view, "[data-test=revoke-confirmation-modal]")
      html = render(view)
      assert html =~ "Are you sure you want to disable"
    end

    test "confirmed revoke withdraws consent", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      view |> element("[data-test=revoke-consent]") |> render_click()
      view |> element("[data-test=confirm-revoke]") |> render_click()

      assert AiConsent.current_consent(:mcp_tools) == nil
    end

    test "UI updates after revocation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      view |> element("[data-test=revoke-consent]") |> render_click()
      html = view |> element("[data-test=confirm-revoke]") |> render_click()

      assert html =~ "Not Enabled"
      assert html =~ "Enable AI Assistant"
    end
  end

  describe "audit log viewing" do
    setup do
      AiConsent.grant(%{feature: :mcp_tools, consent_version: "1.0"})

      # Create some audit entries
      for i <- 1..5 do
        AuditLog.log_invocation(%{
          tool_name: "list_accounts",
          arguments: %{},
          privacy_mode: :anonymized,
          session_id: "session-#{i}"
        })
      end

      :ok
    end

    test "shows recent activity section", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      assert html =~ "Recent Activity"
      assert html =~ "list_accounts"
    end

    test "limits displayed entries", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      # Should show limited entries with "View All" link
      assert html =~ "View All"
    end

    test "view all link navigates to full log", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      {:ok, _view, html} = view
        |> element("a[href='/settings/ai/audit-log']")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "AI Activity Log"
    end

    test "shows invocation details", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      assert html =~ "list_accounts"
      assert html =~ "anonymized" or html =~ "Anonymized"
    end
  end

  describe "GDPR data export" do
    setup do
      AiConsent.grant(%{feature: :mcp_tools, consent_version: "1.0"})
      :ok
    end

    test "shows export button", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      assert html =~ "Export My Data"
    end

    test "export downloads JSON file", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      # Click export
      view |> element("[data-test=export-data]") |> render_click()

      # Should trigger download (check for download event)
      assert_push_event(view, "download", %{filename: filename, content: _})
      assert filename =~ "ai-consent-export"
      assert filename =~ ".json"
    end

    test "export includes consent and audit data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      view |> element("[data-test=export-data]") |> render_click()

      assert_push_event(view, "download", %{content: content})
      data = Jason.decode!(content)

      assert Map.has_key?(data, "consents")
      assert Map.has_key?(data, "audits")
      assert Map.has_key?(data, "exported_at")
    end
  end

  describe "enable flow" do
    test "enable button opens consent modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      html = view |> element("[data-test=enable-ai]") |> render_click()

      assert html =~ "consent-modal"
    end

    test "after consent, page shows enabled state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      # Trigger enable flow
      view |> element("[data-test=enable-ai]") |> render_click()
      view |> element("[data-test=terms-checkbox]") |> render_click()
      html = view |> element("[data-test=grant-consent-button]") |> render_click()

      assert html =~ "Enabled"
      refute html =~ "Enable AI Assistant"
    end
  end
end
```

## Implementation Steps

### Step 1: Create Settings LiveView

```elixir
# lib/ashfolio_web/live/settings/ai_settings_live.ex

defmodule AshfolioWeb.Settings.AiSettingsLive do
  use AshfolioWeb, :live_view

  alias Ashfolio.Legal.AiConsent
  alias AshfolioWeb.Mcp.AuditLog
  alias AshfolioWeb.Components.ConsentModal

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Ashfolio.PubSub, "ai_settings")
    end

    consent = AiConsent.current_consent(:mcp_tools)
    recent_activity = AuditLog.query(limit: 5)

    {:ok,
     socket
     |> assign(:consent, consent)
     |> assign(:recent_activity, recent_activity)
     |> assign(:show_consent_modal, false)
     |> assign(:show_privacy_modal, false)
     |> assign(:show_revoke_modal, false)
     |> assign(:selected_privacy_mode, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8 px-4">
      <h1 class="text-2xl font-bold text-gray-900 mb-8">AI Settings</h1>

      <!-- Consent Status Card -->
      <div class="bg-white rounded-lg shadow p-6 mb-6">
        <div class="flex items-start justify-between">
          <div>
            <h2 class="text-lg font-medium text-gray-900">AI Assistant</h2>
            <p class="text-sm text-gray-500 mt-1">
              Portfolio analysis powered by Claude
            </p>
          </div>

          <.status_badge consent={@consent} />
        </div>

        <%= if @consent do %>
          <.consent_details consent={@consent} />
        <% else %>
          <.enable_prompt />
        <% end %>
      </div>

      <!-- Privacy Mode Card (only when enabled) -->
      <%= if @consent do %>
        <.privacy_mode_card
          consent={@consent}
          on_change="show_privacy_modal"
        />
      <% end %>

      <!-- Recent Activity Card (only when enabled) -->
      <%= if @consent do %>
        <.recent_activity_card
          activity={@recent_activity}
        />
      <% end %>

      <!-- GDPR Actions Card -->
      <.gdpr_actions_card consent={@consent} />

      <!-- Modals -->
      <%= if @show_consent_modal do %>
        <.live_component
          module={ConsentModal}
          id="consent-modal"
          feature={:mcp_tools}
          version_update={false}
        />
      <% end %>

      <%= if @show_privacy_modal do %>
        <.privacy_mode_modal
          current_mode={@consent.privacy_mode}
          selected_mode={@selected_privacy_mode}
        />
      <% end %>

      <%= if @show_revoke_modal do %>
        <.revoke_confirmation_modal />
      <% end %>
    </div>
    """
  end

  defp status_badge(assigns) do
    ~H"""
    <span class={[
      "px-3 py-1 rounded-full text-sm font-medium",
      if(@consent, do: "bg-green-100 text-green-800", else: "bg-gray-100 text-gray-800")
    ]}>
      <%= if @consent, do: "Enabled", else: "Not Enabled" %>
    </span>
    """
  end

  defp consent_details(assigns) do
    ~H"""
    <div class="mt-6 border-t border-gray-200 pt-4">
      <dl class="grid grid-cols-2 gap-4">
        <div>
          <dt class="text-sm text-gray-500">Privacy Mode</dt>
          <dd class="text-sm font-medium text-gray-900" data-test="current-privacy-mode">
            <%= humanize_mode(@consent.privacy_mode) %>
          </dd>
        </div>
        <div>
          <dt class="text-sm text-gray-500">Consent Version</dt>
          <dd class="text-sm font-medium text-gray-900">
            Version <%= @consent.consent_version %>
          </dd>
        </div>
        <div>
          <dt class="text-sm text-gray-500">Enabled On</dt>
          <dd class="text-sm font-medium text-gray-900">
            <%= format_date(@consent.granted_at) %>
          </dd>
        </div>
      </dl>

      <div class="mt-4 flex space-x-3">
        <button
          type="button"
          data-test="change-privacy-mode"
          class="text-sm text-blue-600 hover:text-blue-800"
          phx-click="show_privacy_modal"
        >
          Change Privacy Mode
        </button>
        <button
          type="button"
          data-test="revoke-consent"
          class="text-sm text-red-600 hover:text-red-800"
          phx-click="show_revoke_modal"
        >
          Disable AI Assistant
        </button>
      </div>
    </div>
    """
  end

  defp enable_prompt(assigns) do
    ~H"""
    <div class="mt-6">
      <p class="text-sm text-gray-600 mb-4">
        Enable the AI Assistant to get help analyzing your portfolio,
        understanding your investments, and planning for the future.
      </p>
      <button
        type="button"
        data-test="enable-ai"
        class="bg-blue-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-blue-700"
        phx-click="show_consent_modal"
      >
        Enable AI Assistant
      </button>
    </div>
    """
  end

  defp privacy_mode_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-6 mb-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Privacy Mode</h2>

      <div class="space-y-3">
        <.privacy_mode_option
          mode={:strict}
          current={@consent.privacy_mode}
          title="Strict"
          description="Only aggregate data shared. Limited functionality."
        />
        <.privacy_mode_option
          mode={:anonymized}
          current={@consent.privacy_mode}
          title="Anonymized"
          description="Account names and balances anonymized."
        />
        <.privacy_mode_option
          mode={:standard}
          current={@consent.privacy_mode}
          title="Standard"
          description="Names visible, exact balances hidden."
        />
        <.privacy_mode_option
          mode={:full}
          current={@consent.privacy_mode}
          title="Full Access"
          description="All data shared with Claude."
        />
      </div>
    </div>
    """
  end

  defp privacy_mode_option(assigns) do
    ~H"""
    <div class={[
      "p-3 rounded-lg border",
      if(@current == @mode, do: "border-blue-500 bg-blue-50", else: "border-gray-200")
    ]}>
      <div class="flex items-center justify-between">
        <div>
          <span class="font-medium text-gray-900"><%= @title %></span>
          <%= if @current == @mode do %>
            <span class="ml-2 text-xs text-blue-600">(Current)</span>
          <% end %>
          <p class="text-sm text-gray-500"><%= @description %></p>
        </div>
      </div>
    </div>
    """
  end

  defp recent_activity_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-6 mb-6">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-medium text-gray-900">Recent Activity</h2>
        <a href="/settings/ai/audit-log" class="text-sm text-blue-600 hover:underline">
          View All
        </a>
      </div>

      <%= if Enum.empty?(@activity) do %>
        <p class="text-sm text-gray-500">No AI activity yet.</p>
      <% else %>
        <div class="space-y-2">
          <%= for log <- @activity do %>
            <div class="flex items-center justify-between py-2 border-b border-gray-100 last:border-0">
              <div>
                <span class="text-sm font-medium text-gray-900"><%= log.tool_name %></span>
                <span class="text-xs text-gray-500 ml-2">
                  <%= humanize_mode(log.privacy_mode) %>
                </span>
              </div>
              <span class="text-xs text-gray-400">
                <%= format_relative_time(log.invoked_at) %>
              </span>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp gdpr_actions_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Your Data</h2>
      <p class="text-sm text-gray-600 mb-4">
        Export or delete your AI-related data in compliance with GDPR.
      </p>
      <div class="flex space-x-3">
        <button
          type="button"
          data-test="export-data"
          class="text-sm text-blue-600 hover:text-blue-800"
          phx-click="export_data"
        >
          Export My Data
        </button>
        <%= if @consent do %>
          <button
            type="button"
            class="text-sm text-red-600 hover:text-red-800"
            phx-click="show_delete_modal"
          >
            Delete All AI Data
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  # Event handlers

  @impl true
  def handle_event("show_consent_modal", _, socket) do
    {:noreply, assign(socket, :show_consent_modal, true)}
  end

  @impl true
  def handle_event("show_privacy_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_privacy_modal, true)
     |> assign(:selected_privacy_mode, socket.assigns.consent.privacy_mode)}
  end

  @impl true
  def handle_event("show_revoke_modal", _, socket) do
    {:noreply, assign(socket, :show_revoke_modal, true)}
  end

  @impl true
  def handle_event("select_privacy_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :selected_privacy_mode, String.to_existing_atom(mode))}
  end

  @impl true
  def handle_event("confirm_privacy_change", _, socket) do
    consent = socket.assigns.consent
    new_mode = socket.assigns.selected_privacy_mode

    # Create new consent with updated mode
    {:ok, new_consent} = AiConsent.grant(%{
      feature: :mcp_tools,
      consent_version: consent.consent_version,
      privacy_mode: new_mode
    })

    {:noreply,
     socket
     |> assign(:consent, new_consent)
     |> assign(:show_privacy_modal, false)}
  end

  @impl true
  def handle_event("confirm_revoke", _, socket) do
    consent = socket.assigns.consent
    {:ok, _} = AiConsent.withdraw(consent, reason: "User revoked via settings")

    {:noreply,
     socket
     |> assign(:consent, nil)
     |> assign(:show_revoke_modal, false)}
  end

  @impl true
  def handle_event("export_data", _, socket) do
    export = AiConsent.export_consent_data()
    content = Jason.encode!(export, pretty: true)
    filename = "ai-consent-export-#{Date.to_string(Date.utc_today())}.json"

    {:noreply, push_event(socket, "download", %{filename: filename, content: content})}
  end

  @impl true
  def handle_info({:consent_granted, :mcp_tools, privacy_mode}, socket) do
    consent = AiConsent.current_consent(:mcp_tools)

    {:noreply,
     socket
     |> assign(:consent, consent)
     |> assign(:show_consent_modal, false)}
  end

  @impl true
  def handle_info({:consent_declined, :mcp_tools}, socket) do
    {:noreply, assign(socket, :show_consent_modal, false)}
  end

  # Helper functions

  defp humanize_mode(:strict), do: "Strict"
  defp humanize_mode(:anonymized), do: "Anonymized"
  defp humanize_mode(:standard), do: "Standard"
  defp humanize_mode(:full), do: "Full Access"

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end

  defp format_relative_time(datetime) do
    # Simple relative time formatting
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      true -> format_date(datetime)
    end
  end
end
```

### Step 2: Add Route

```elixir
# lib/ashfolio_web/router.ex

scope "/settings", AshfolioWeb.Settings do
  pipe_through [:browser]

  live "/ai", AiSettingsLive, :index
  live "/ai/audit-log", AiAuditLogLive, :index
end
```

### Step 3: Run Tests

```bash
mix test test/ashfolio_web/live/settings/ai_settings_live_test.exs --trace
```

## Definition of Done

- [ ] Settings LiveView created
- [ ] Consent status displayed
- [ ] Privacy mode changeable
- [ ] Consent revocation works
- [ ] Recent activity displayed
- [ ] GDPR export works
- [ ] All TDD tests pass
- [ ] `mix test` passes (no regressions)

## Dependencies

**Blocked By**: Tasks P3-01, P3-02, P3-03
**Blocks**: None (Final Phase 3 task)

## Notes

- Consider adding consent expiry notifications
- Add email notification for consent changes
- Future: Dark mode support

---

*Parent: [../README.md](../README.md)*
