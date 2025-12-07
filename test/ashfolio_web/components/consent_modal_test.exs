defmodule AshfolioWeb.Components.ConsentModalTest do
  use AshfolioWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias AshfolioWeb.Components.ConsentModal

  @moduletag :liveview

  describe "ConsentModal component rendering" do
    test "renders with default values" do
      html = render_component(ConsentModal, id: "consent-modal")

      assert html =~ "Enable AI Features"
      assert html =~ "Privacy Level"
      assert html =~ "AI Features"
      assert html =~ "I accept the AI usage terms"
    end

    test "renders all privacy mode options" do
      html = render_component(ConsentModal, id: "consent-modal")

      assert html =~ "Strict Privacy"
      assert html =~ "Anonymized"
      assert html =~ "Standard"
      assert html =~ "Full Access"
    end

    test "renders all feature options" do
      html = render_component(ConsentModal, id: "consent-modal")

      assert html =~ "MCP Tools"
      assert html =~ "AI Analysis"
      assert html =~ "Cloud AI"
    end

    test "grant button is disabled when terms not accepted" do
      html = render_component(ConsentModal, id: "consent-modal")

      # Button should have disabled styling
      assert html =~ "bg-gray-300"
      assert html =~ "cursor-not-allowed"
    end

    test "has accessible ARIA attributes" do
      html = render_component(ConsentModal, id: "consent-modal")

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(aria-labelledby="consent-modal-title")
    end

    test "renders privacy mode descriptions" do
      html = render_component(ConsentModal, id: "consent-modal")

      assert html =~ "Only aggregate data shared"
      assert html =~ "Accounts shown as letters"
      assert html =~ "Account names visible"
      assert html =~ "Complete data access"
    end

    test "renders feature descriptions" do
      html = render_component(ConsentModal, id: "consent-modal")

      assert html =~ "Allow AI assistants to query your portfolio"
      assert html =~ "Enable AI-powered insights"
      assert html =~ "Use cloud-based AI models"
    end

    test "has view terms button" do
      html = render_component(ConsentModal, id: "consent-modal")

      assert html =~ "View terms"
    end

    test "has grant and decline buttons" do
      html = render_component(ConsentModal, id: "consent-modal")

      assert html =~ "Enable AI Features"
      assert html =~ "Not Now"
    end
  end
end
