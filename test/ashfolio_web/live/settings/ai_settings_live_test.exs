defmodule AshfolioWeb.Settings.AiSettingsLiveTest do
  use AshfolioWeb.LiveViewCase, async: false

  import Phoenix.LiveViewTest

  alias Ashfolio.Legal.AiConsent

  @moduletag :liveview

  @consent_attrs %{
    features: [:mcp_tools, :ai_analysis],
    privacy_mode: :anonymized,
    terms_version: "1.0.0",
    terms_hash: AiConsent.hash_terms("Test terms")
  }

  describe "AiSettingsLive without consent" do
    test "renders empty state when no consent exists", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/settings/ai")

      assert html =~ "AI Settings"
      assert html =~ "Manage AI feature access and privacy"
      assert html =~ "AI Features Not Enabled"
      assert has_element?(view, "button", "Enable AI Features")
      assert has_element?(view, "button", "Get Started")
    end

    test "shows consent modal when clicking enable", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      # Click the first enable button (there are two, but either works)
      view |> element("button", "Enable AI Features") |> render_click()

      # Modal should appear
      assert has_element?(view, "[role='dialog']")
      assert has_element?(view, "h3", "Enable AI Features")
    end

    test "does not show privacy mode or features sections without consent", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      refute html =~ "Privacy Mode"
      refute html =~ "Enabled Features"
      # Note: & is HTML escaped to &amp;
      refute html =~ "Data &amp; Privacy"
    end
  end

  describe "AiSettingsLive with consent" do
    setup do
      {:ok, consent} = AiConsent.grant(@consent_attrs)
      %{consent: consent}
    end

    test "shows consent status when consent exists", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      assert html =~ "AI Settings"
      # Status should show enabled
      refute html =~ "AI Features Not Enabled"
      assert html =~ "Enabled"
    end

    test "displays privacy mode section", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      assert html =~ "Privacy Mode"
      assert html =~ "Control how much data AI assistants can access"
      assert html =~ "Strict Privacy"
      assert html =~ "Anonymized"
      assert html =~ "Standard"
      assert html =~ "Full Access"
    end

    test "highlights current privacy mode", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      # Anonymized should be selected (from @consent_attrs)
      anonymized_option = element(view, "[phx-value-mode='anonymized']")
      html = render(anonymized_option)
      assert html =~ "ring-blue-600"
      assert html =~ "hero-check-circle-solid"
    end

    test "displays enabled features section", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      assert html =~ "Enabled Features"
      assert html =~ "MCP Tools"
      assert html =~ "AI Analysis"
      assert html =~ "Cloud AI"
    end

    test "shows correct feature status", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      # MCP Tools and AI Analysis should be enabled
      # Cloud AI should be disabled
      # Check for Enabled badges
      assert html =~ "Enabled"
      assert html =~ "Disabled"
    end

    test "displays GDPR section", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/settings/ai")

      # Note: & is HTML escaped to &amp;
      assert html =~ "Data &amp; Privacy"
      assert html =~ "Manage your data under GDPR"
      assert has_element?(view, "button", "Export My Data")
      assert has_element?(view, "button", "Revoke Consent")
    end

    test "opens privacy mode change modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      # Click to change to full mode
      view |> element("[phx-value-mode='full']") |> render_click()

      # Modal should appear
      assert has_element?(view, "[role='dialog']")
      assert has_element?(view, "h3", "Change Privacy Mode")
      assert has_element?(view, "button", "Confirm Change")
      assert has_element?(view, "button", "Cancel")
    end

    test "confirms privacy mode change", %{conn: conn, consent: consent} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      # Click to change to full mode
      view |> element("[phx-value-mode='full']") |> render_click()

      # Confirm the change
      view |> element("button", "Confirm Change") |> render_click()

      # Modal should close and mode should update
      refute has_element?(view, "h3", "Change Privacy Mode")

      # Verify in database
      {:ok, [updated_consent]} = AiConsent.get_active()
      assert updated_consent.id == consent.id
      assert updated_consent.privacy_mode == :full
    end

    test "cancels privacy mode change", %{conn: conn, consent: consent} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      # Click to change to full mode
      view |> element("[phx-value-mode='full']") |> render_click()

      # Cancel the change
      view |> element("button", "Cancel") |> render_click()

      # Modal should close, mode should remain unchanged
      refute has_element?(view, "h3", "Change Privacy Mode")

      # Verify unchanged in database
      {:ok, [unchanged_consent]} = AiConsent.get_active()
      assert unchanged_consent.id == consent.id
      assert unchanged_consent.privacy_mode == :anonymized
    end

    test "opens revoke confirmation modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      view |> element("button", "Revoke Consent") |> render_click()

      assert has_element?(view, "h3", "Revoke AI Consent")
      assert has_element?(view, "button", "Revoke Consent")
      assert render(view) =~ "immediately disable all AI features"
    end

    test "revokes consent", %{conn: conn, consent: consent} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      # Open modal
      view |> element("button[phx-click='show_revoke_confirm']") |> render_click()

      # Confirm revocation
      view |> element("button[phx-click='confirm_revoke']") |> render_click()

      # Should show empty state now
      assert has_element?(view, "h3", "AI Features Not Enabled")

      # Verify in database
      {:ok, []} = AiConsent.get_active()

      # Original consent should be withdrawn
      {:ok, withdrawn} = Ash.get(AiConsent, consent.id)
      assert withdrawn.withdrawn_at
    end

    test "cancels revoke confirmation", %{conn: conn, consent: consent} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      # Open modal
      view |> element("button[phx-click='show_revoke_confirm']") |> render_click()

      # Cancel
      view |> element("button", "Cancel") |> render_click()

      # Modal should close
      refute has_element?(view, "h3", "Revoke AI Consent")

      # Consent should remain active
      {:ok, [active]} = AiConsent.get_active()
      assert active.id == consent.id
    end

    test "triggers data export", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      # Click export button - should complete without error
      view |> element("button", "Export My Data") |> render_click()

      # The button should still exist (page did not crash)
      assert has_element?(view, "button", "Export My Data")
    end
  end

  describe "AiSettingsLive consent flow" do
    test "can grant consent through modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      # Click enable on main page (use specific text to get first button)
      view |> element("button", "Enable AI Features") |> render_click()

      # Modal should be visible
      assert has_element?(view, "[role='dialog']")

      # Accept terms and grant (use the modal button with phx-target)
      view |> element("#terms-checkbox") |> render_click()
      view |> element("button[phx-click='grant_consent']") |> render_click()

      # Wait for async update
      :timer.sleep(50)

      # Re-render to see updated state
      html = render(view)

      # Should now show enabled state
      refute html =~ "AI Features Not Enabled"

      # Verify in database
      {:ok, [consent]} = AiConsent.get_active()
      assert consent.privacy_mode == :anonymized
    end

    test "can decline consent through modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/ai")

      # Click enable (use specific text)
      view |> element("button", "Enable AI Features") |> render_click()

      # Decline
      view |> element("button[phx-click='decline_consent']") |> render_click()

      # Should still show empty state
      assert has_element?(view, "h3", "AI Features Not Enabled")

      # No consent in database
      {:ok, []} = AiConsent.get_active()
    end
  end

  describe "AiSettingsLive navigation" do
    test "renders page title in document", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      # Check page title is set
      assert html =~ "AI Settings"
    end

    test "renders page header correctly", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/ai")

      # Check header is rendered
      assert html =~ "Manage AI feature access and privacy"
    end
  end
end
