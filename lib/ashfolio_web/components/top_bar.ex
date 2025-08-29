defmodule AshfolioWeb.Components.TopBar do
  @moduledoc """
  Navigation top bar component for the Ashfolio web application.

  Provides consistent top navigation with current page highlighting
  and page title display functionality.
  """
  use AshfolioWeb, :html

  attr :current_page, :atom, required: true
  attr :page_title, :string, required: true
  attr :page_subtitle, :string, default: nil
  attr :id, :string, default: nil

  def top_bar(assigns) do
    assigns =
      assign(
        assigns,
        :mobile_menu_id,
        (assigns[:id] && "#{assigns.id}-mobile-menu") || "mobile-menu"
      )

    ~H"""
    <header class="bg-white shadow-sm border-b border-gray-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center py-4">
          <!-- Logo and App Name -->
          <div class="flex items-center">
            <.link navigate={~p"/"} class="flex items-center space-x-3">
              <div class="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
                <span class="text-white font-bold text-lg">A</span>
              </div>
              <h1 class="text-xl font-semibold text-gray-900">Ashfolio</h1>
            </.link>
          </div>
          
    <!-- Navigation moved to subheader -->

    <!-- Mobile menu button -->
          <div class="md:hidden">
            <button
              type="button"
              class="text-gray-500 hover:text-gray-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded-md p-2"
              phx-click={JS.toggle(to: "##{@mobile_menu_id}")}
              aria-expanded="false"
              aria-controls={@mobile_menu_id}
              aria-label="Toggle mobile menu"
            >
              <.icon name="hero-bars-3" class="w-6 h-6" />
            </button>
          </div>
        </div>
        
    <!-- Mobile Navigation -->
        <div
          id={@mobile_menu_id}
          class="md:hidden hidden pb-4"
          role="navigation"
          data-testid="mobile-nav"
          aria-label="Mobile navigation"
        >
          <div class="space-y-1">
            <.mobile_nav_link navigate={~p"/"} current={@current_page == :dashboard}>
              <.icon name="hero-chart-bar" class="w-4 h-4 mr-3" /> Dashboard
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/accounts"} current={@current_page == :accounts}>
              <.icon name="hero-building-library" class="w-4 h-4 mr-3" /> Accounts
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/transactions"} current={@current_page == :transactions}>
              <.icon name="hero-arrow-right-left" class="w-4 h-4 mr-3" /> Transactions
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/expenses"} current={@current_page == :expenses}>
              <.icon name="hero-currency-dollar" class="w-4 h-4 mr-3" /> Expenses
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/expenses/analytics"} current={@current_page == :analytics}>
              <.icon name="hero-chart-pie" class="w-4 h-4 mr-3" /> Analytics
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/net_worth"} current={@current_page == :net_worth}>
              <.icon name="hero-trending-up" class="w-4 h-4 mr-3" /> Net Worth
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/goals"} current={@current_page == :goals}>
              <.icon name="hero-flag" class="w-4 h-4 mr-3" /> Goals
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/forecast"} current={@current_page == :forecast}>
              <.icon name="hero-chart-line" class="w-4 h-4 mr-3" /> Forecast
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/retirement"} current={@current_page == :retirement}>
              <.icon name="hero-shield-check" class="w-4 h-4 mr-3" /> Retirement
            </.mobile_nav_link>
          </div>
        </div>
      </div>
      <!-- Main Navigation Subheader -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 border-t border-gray-200 bg-white">
        <nav class="flex -mb-px overflow-x-auto scrollbar-hide min-h-[52px]">
          <.subheader_nav_link navigate={~p"/"} current={@current_page == :dashboard}>
            <.icon name="hero-chart-bar" class="w-4 h-4 mr-1.5" /> Dashboard
          </.subheader_nav_link>
          <.subheader_nav_link navigate={~p"/accounts"} current={@current_page == :accounts}>
            <.icon name="hero-building-library" class="w-4 h-4 mr-1.5" /> Accounts
          </.subheader_nav_link>
          <.subheader_nav_link navigate={~p"/transactions"} current={@current_page == :transactions}>
            <.icon name="hero-arrow-right-left" class="w-4 h-4 mr-1.5" /> Transactions
          </.subheader_nav_link>
          <.subheader_nav_link navigate={~p"/expenses"} current={@current_page == :expenses}>
            <.icon name="hero-currency-dollar" class="w-4 h-4 mr-1.5" /> Expenses
          </.subheader_nav_link>
          <.subheader_nav_link
            navigate={~p"/expenses/analytics"}
            current={@current_page == :analytics}
          >
            <.icon name="hero-chart-pie" class="w-4 h-4 mr-1.5" /> Analytics
          </.subheader_nav_link>
          <.subheader_nav_link navigate={~p"/net_worth"} current={@current_page == :net_worth}>
            <.icon name="hero-trending-up" class="w-4 h-4 mr-1.5" /> Net Worth
          </.subheader_nav_link>
          <.subheader_nav_link navigate={~p"/goals"} current={@current_page == :goals}>
            <.icon name="hero-flag" class="w-4 h-4 mr-1.5" /> Goals
          </.subheader_nav_link>
          <.subheader_nav_link navigate={~p"/forecast"} current={@current_page == :forecast}>
            <.icon name="hero-chart-line" class="w-4 h-4 mr-1.5" /> Forecast
          </.subheader_nav_link>
          <.subheader_nav_link navigate={~p"/retirement"} current={@current_page == :retirement}>
            <.icon name="hero-shield-check" class="w-4 h-4 mr-1.5" /> Retirement
          </.subheader_nav_link>
        </nav>
      </div>
    </header>
    """
  end
end
