defmodule AshfolioWeb.MoneyRatiosLive.Index do
  @moduledoc """
  LiveView for Charles Farrell's "Your Money Ratios" financial health assessment.

  Provides a comprehensive dashboard with 5 tabs:
  1. Overview - All 8 ratios with status indicators
  2. Capital Analysis - Detailed capital-to-income breakdown
  3. Debt Management - Mortgage and education debt analysis
  4. Financial Profile - Income and demographic management
  5. Action Plan - Personalized recommendations

  Features real-time ratio calculations, age-based benchmarks, and professional
  financial guidance based on industry-standard methodology.
  """

  use AshfolioWeb, :live_view

  alias Ashfolio.Financial.MoneyRatios
  alias Ashfolio.FinancialManagement.FinancialProfile

  @tab_names ~w(overview capital debt profile action)a

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_current_page(:money_ratios)
      |> assign(:page_title, "Money Ratios")
      |> assign(:current_tab, :overview)
      |> assign(:financial_profile, nil)
      |> assign(:ratios, %{})
      |> assign(:recommendations, [])
      |> load_financial_profile()
      |> calculate_ratios()

    {:ok, socket}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    tab_atom = String.to_existing_atom(tab)

    if tab_atom in @tab_names do
      {:noreply, assign(socket, :current_tab, tab_atom)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("save_profile", %{"financial_profile" => profile_params}, socket) do
    case save_or_update_profile(socket.assigns.financial_profile, profile_params) do
      {:ok, profile} ->
        socket =
          socket
          |> assign(:financial_profile, profile)
          |> calculate_ratios()
          |> put_flash(:info, "Financial profile saved successfully")

        {:noreply, socket}

      {:error, _changeset} ->
        socket = put_flash(socket, :error, "Please correct the errors below")
        {:noreply, socket}
    end
  end

  def handle_info({AshfolioWeb.MoneyRatiosLive.FormComponent, {:saved, financial_profile}}, socket) do
    socket =
      socket
      |> assign(:financial_profile, financial_profile)
      |> calculate_ratios()
      |> put_flash(:info, "Financial profile saved successfully!")

    {:noreply, socket}
  end

  # Private functions

  defp load_financial_profile(socket) do
    # In a single-user system, we get the first (and only) profile
    case FinancialProfile.read_all() do
      {:ok, [profile | _]} ->
        assign(socket, :financial_profile, profile)

      {:ok, []} ->
        assign(socket, :financial_profile, nil)

      _error ->
        assign(socket, :financial_profile, nil)
    end
  end

  defp calculate_ratios(socket) do
    profile = socket.assigns.financial_profile

    if profile do
      # Get net worth data (simplified for now - would integrate with existing NetWorth system)
      net_worth = get_net_worth()
      annual_savings = get_annual_savings()

      case MoneyRatios.calculate_all_ratios(profile, net_worth, annual_savings) do
        {:ok, ratios} ->
          recommendations = MoneyRatios.get_recommendations(ratios)

          socket
          |> assign(:ratios, ratios)
          |> assign(:recommendations, recommendations)

        _error ->
          socket
          |> assign(:ratios, %{})
          |> assign(:recommendations, ["Unable to calculate ratios. Please check your data."])
      end
    else
      assign(socket, :ratios, %{})
    end
  end

  defp save_or_update_profile(nil, params) do
    # Create new profile
    FinancialProfile.create(params)
  end

  defp save_or_update_profile(existing_profile, params) do
    # Update existing profile
    FinancialProfile.update(existing_profile, params)
  end

  # Temporary helpers for net worth and savings - would integrate with existing systems
  defp get_net_worth do
    # TODO: Integrate with existing NetWorthSnapshot system
    # Default for demo
    Decimal.new("200000")
  end

  defp get_annual_savings do
    # TODO: Calculate from expense/income tracking
    # Default for demo
    Decimal.new("12000")
  end

  # Helper functions for templates

  defp format_ratio(ratio) when is_map(ratio) do
    current = ratio.current_ratio
    target = ratio.target_ratio

    current_formatted = format_decimal_as_ratio(current)
    target_formatted = format_decimal_as_ratio(target)

    "#{current_formatted} (Target: #{target_formatted})"
  end

  defp format_decimal_as_ratio(decimal) do
    decimal
    |> Decimal.round(1)
    |> Decimal.to_string()
    |> Kernel.<>("x")
  end

  defp ratio_status_class(%{status: :on_track}), do: "text-green-600 bg-green-50"
  defp ratio_status_class(%{status: :ahead}), do: "text-blue-600 bg-blue-50"
  defp ratio_status_class(%{status: :behind}), do: "text-red-600 bg-red-50"
  defp ratio_status_class(%{status: :critical}), do: "text-red-800 bg-red-100"
  defp ratio_status_class(_), do: "text-gray-600 bg-gray-50"

  defp ratio_status_icon(%{status: :on_track}), do: "✅"
  defp ratio_status_icon(%{status: :ahead}), do: "🚀"
  defp ratio_status_icon(%{status: :behind}), do: "⚠️"
  defp ratio_status_icon(%{status: :critical}), do: "❌"
  defp ratio_status_icon(_), do: "➖"

  defp tab_active_class(:overview, :overview), do: "border-blue-500 text-blue-600"
  defp tab_active_class(tab, tab), do: "border-blue-500 text-blue-600"
  defp tab_active_class(_, _), do: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
end
