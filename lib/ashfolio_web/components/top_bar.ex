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
      <div class="w-full mx-auto px-4 sm:px-6 lg:px-8 xl:px-16 2xl:px-24">
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
              <.icon name="hero-credit-card" class="w-4 h-4 mr-3" /> Transactions
            </.mobile_nav_link>
            <.mobile_nav_link
              navigate={~p"/corporate-actions"}
              current={@current_page == :corporate_actions}
            >
              <.icon name="hero-building-office" class="w-4 h-4 mr-3" /> Corporate Actions
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/expenses"} current={@current_page == :expenses}>
              <.icon name="hero-currency-dollar" class="w-4 h-4 mr-3" /> Expenses
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/expenses/analytics"} current={@current_page == :analytics}>
              <.icon name="hero-chart-pie" class="w-4 h-4 mr-3" /> Analytics
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/net_worth"} current={@current_page == :net_worth}>
              <.icon name="hero-presentation-chart-line" class="w-4 h-4 mr-3" /> Net Worth
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/goals"} current={@current_page == :goals}>
              <.icon name="hero-flag" class="w-4 h-4 mr-3" /> Goals
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/money-ratios"} current={@current_page == :money_ratios}>
              <.icon name="hero-scale" class="w-4 h-4 mr-3" /> Money Ratios
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/forecast"} current={@current_page == :forecast}>
              <.icon name="hero-presentation-chart-bar" class="w-4 h-4 mr-3" /> Forecast
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/retirement"} current={@current_page == :retirement}>
              <.icon name="hero-shield-check" class="w-4 h-4 mr-3" /> Retirement
            </.mobile_nav_link>
            <.mobile_nav_link
              navigate={~p"/advanced_analytics"}
              current={@current_page == :advanced_analytics}
            >
              <.icon name="hero-calculator" class="w-4 h-4 mr-3" /> Adv. Analytics
            </.mobile_nav_link>
            <.mobile_nav_link navigate={~p"/settings/ai"} current={@current_page == :settings}>
              <.icon name="hero-cog-6-tooth" class="w-4 h-4 mr-3" /> Settings
            </.mobile_nav_link>
          </div>
        </div>
      </div>
      <!-- Main Navigation Subheader -->
      <div class="w-full mx-auto px-4 sm:px-6 lg:px-8 xl:px-16 2xl:px-24 border-t border-gray-200 bg-white">
        <nav
          class="flex -mb-px min-h-[52px]"
          aria-label="Main navigation"
        >
          <!-- Dashboard (Single Link) -->
          <.subheader_nav_link navigate={~p"/"} current={@current_page == :dashboard}>
            <.icon name="hero-chart-bar" class="w-4 h-4 mr-1.5" /> Dashboard
          </.subheader_nav_link>
          
    <!-- Portfolio Group -->
          <.nav_dropdown
            id="portfolio-menu"
            label="Portfolio"
            icon="hero-briefcase"
            active={
              Enum.member?([:accounts, :transactions, :corporate_actions, :net_worth], @current_page)
            }
          >
            <.dropdown_link navigate={~p"/accounts"} current={@current_page == :accounts}>
              <.icon name="hero-building-library" class="w-4 h-4 mr-2" /> Accounts
            </.dropdown_link>
            <.dropdown_link navigate={~p"/transactions"} current={@current_page == :transactions}>
              <.icon name="hero-credit-card" class="w-4 h-4 mr-2" /> Transactions
            </.dropdown_link>
            <.dropdown_link
              navigate={~p"/corporate-actions"}
              current={@current_page == :corporate_actions}
            >
              <.icon name="hero-building-office" class="w-4 h-4 mr-2" /> Corp. Actions
            </.dropdown_link>
            <.dropdown_link navigate={~p"/net_worth"} current={@current_page == :net_worth}>
              <.icon name="hero-presentation-chart-line" class="w-4 h-4 mr-2" /> Net Worth
            </.dropdown_link>
          </.nav_dropdown>
          
    <!-- Planning Group -->
          <.nav_dropdown
            id="planning-menu"
            label="Planning"
            icon="hero-map"
            active={Enum.member?([:forecast, :retirement, :goals, :tax_planning], @current_page)}
          >
            <.dropdown_link navigate={~p"/forecast"} current={@current_page == :forecast}>
              <.icon name="hero-presentation-chart-bar" class="w-4 h-4 mr-2" /> Forecast
            </.dropdown_link>
            <.dropdown_link navigate={~p"/retirement"} current={@current_page == :retirement}>
              <.icon name="hero-shield-check" class="w-4 h-4 mr-2" /> Retirement
            </.dropdown_link>
            <.dropdown_link navigate={~p"/goals"} current={@current_page == :goals}>
              <.icon name="hero-flag" class="w-4 h-4 mr-2" /> Goals
            </.dropdown_link>
            <.dropdown_link navigate={~p"/tax-planning"} current={@current_page == :tax_planning}>
              <.icon name="hero-document-text" class="w-4 h-4 mr-2" /> Tax Planning
            </.dropdown_link>
          </.nav_dropdown>
          
    <!-- Analysis Group -->
          <.nav_dropdown
            id="analysis-menu"
            label="Analysis"
            icon="hero-chart-pie"
            active={Enum.member?([:advanced_analytics, :money_ratios], @current_page)}
          >
            <.dropdown_link
              navigate={~p"/advanced_analytics"}
              current={@current_page == :advanced_analytics}
            >
              <.icon name="hero-calculator" class="w-4 h-4 mr-2" /> Adv. Analytics
            </.dropdown_link>
            <.dropdown_link navigate={~p"/money-ratios"} current={@current_page == :money_ratios}>
              <.icon name="hero-scale" class="w-4 h-4 mr-2" /> Money Ratios
            </.dropdown_link>
          </.nav_dropdown>
          
    <!-- Expenses Group -->
          <.nav_dropdown
            id="expenses-menu"
            label="Expenses"
            icon="hero-currency-dollar"
            active={Enum.member?([:expenses, :analytics], @current_page)}
          >
            <.dropdown_link navigate={~p"/expenses"} current={@current_page == :expenses}>
              <.icon name="hero-list-bullet" class="w-4 h-4 mr-2" /> Expense List
            </.dropdown_link>
            <.dropdown_link navigate={~p"/expenses/analytics"} current={@current_page == :analytics}>
              <.icon name="hero-chart-pie" class="w-4 h-4 mr-2" /> Expense Analytics
            </.dropdown_link>
          </.nav_dropdown>
          
    <!-- Settings Group -->
          <.nav_dropdown
            id="settings-menu"
            label="Settings"
            icon="hero-cog-6-tooth"
            active={Enum.member?([:settings, :categories], @current_page)}
          >
            <.dropdown_link navigate={~p"/settings/ai"} current={@current_page == :settings}>
              <.icon name="hero-sparkles" class="w-4 h-4 mr-2" /> AI Settings
            </.dropdown_link>
            <.dropdown_link navigate={~p"/categories"} current={@current_page == :categories}>
              <.icon name="hero-tag" class="w-4 h-4 mr-2" /> Categories
            </.dropdown_link>
          </.nav_dropdown>
        </nav>
      </div>
    </header>
    """
  end

  # Component Definitions

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :active, :boolean, default: false
  slot :inner_block, required: true

  def nav_dropdown(assigns) do
    ~H"""
    <div class="relative group nav-item-group" id={"#{@id}-container"}>
      <details class="group relative top-nav-accordion" id={@id}>
        <summary
          class={[
            "flex items-center px-4 py-4 text-sm font-medium border-b-2 cursor-pointer transition-colors duration-200 list-none relative z-20",
            "focus:outline-none focus:ring-2 focus:ring-inset focus:ring-blue-500",
            @active && "border-blue-500 text-blue-600",
            !@active && "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
          ]}
          aria-expanded="false"
          aria-controls={"#{@id}-menu"}
          onclick="event.preventDefault(); var d = this.closest('details'); var wasOpen = d.hasAttribute('open'); document.querySelectorAll('details.top-nav-accordion[open]').forEach(el => el.removeAttribute('open')); if (!wasOpen) d.setAttribute('open', '');"
        >
          <.icon name={@icon} class="w-4 h-4 mr-2" />
          {@label}
          <.icon
            name="hero-chevron-down"
            class="w-3 h-3 ml-1 text-gray-400 group-open:rotate-180 transition-transform duration-200"
          />
        </summary>
        
    <!-- Dropdown Menu -->
        <div
          id={"#{@id}-menu"}
          class="absolute left-0 top-full z-10 w-56 origin-top-left rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none hidden group-open:block animate-fade-in-down"
          role="menu"
          aria-orientation="vertical"
          aria-labelledby={@id}
        >
          <div class="py-1" role="none">
            {render_slot(@inner_block)}
          </div>
        </div>
        
    <!-- Click outside to close (backdrop) - Simple version -->
        <div
          class="fixed inset-0 z-0 hidden group-open:block"
          onclick="this.previousElementSibling.previousElementSibling.parentElement.removeAttribute('open')"
          aria-hidden="true"
        >
        </div>
      </details>
    </div>
    """
  end

  attr :navigate, :any, required: true
  attr :current, :boolean, default: false
  slot :inner_block, required: true

  def dropdown_link(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "flex items-center px-4 py-2 text-sm",
        @current && "bg-gray-100 text-gray-900 font-medium",
        !@current && "text-gray-700 hover:bg-gray-50 hover:text-gray-900"
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end
end
