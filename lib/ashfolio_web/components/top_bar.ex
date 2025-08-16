defmodule AshfolioWeb.Components.TopBar do
  use AshfolioWeb, :html

  attr :current_page, :atom, required: true
  attr :page_title, :string, required: true
  attr :page_subtitle, :string, default: nil
  attr :id, :string, default: nil

  def top_bar(assigns) do
    assigns = assign(assigns, :mobile_menu_id, assigns[:id] && "#{assigns.id}-mobile-menu" || "mobile-menu")
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
          
    <!-- Navigation -->
          <nav class="hidden md:flex space-x-8" role="navigation" aria-label="Main navigation">
            <.nav_link navigate={~p"/"} current={@current_page == :dashboard}>
              <.icon name="hero-chart-bar" class="w-4 h-4 mr-2" /> Dashboard
            </.nav_link>
            <.nav_link navigate={~p"/accounts"} current={@current_page == :accounts}>
              <.icon name="hero-building-library" class="w-4 h-4 mr-2" /> Accounts
            </.nav_link>
            <.nav_link navigate={~p"/transactions"} current={@current_page == :transactions}>
              <.icon name="hero-arrow-right-left" class="w-4 h-4 mr-2" /> Transactions
            </.nav_link>
          </nav>
          
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
          </div>
        </div>
      </div>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 border-t border-gray-200">
        <h2 class="text-2xl font-bold text-gray-900">{@page_title}</h2>
        <p class="text-sm text-gray-500">{@page_subtitle}</p>
      </div>
    </header>
    """
  end
end
