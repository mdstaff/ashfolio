defmodule AshfolioWeb.TaxPlanningLive.Index do
  @moduledoc """
  LiveView for tax planning and capital gains analysis.

  Provides interactive interface for tax-loss harvesting opportunities,
  capital gains/losses analysis, and tax optimization strategies.
  Features comprehensive FIFO cost basis calculations and wash sale compliance.
  """

  use AshfolioWeb, :live_view

  alias Ashfolio.Portfolio.Account

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_current_page(:tax_planning)
      |> assign(:page_title, "Tax Planning & Optimization")
      |> assign(:loading, false)
      |> assign(:errors, [])
      |> assign(:active_tab, "capital_gains")
      |> assign(:tax_year, Date.utc_today().year)
      |> assign(:marginal_tax_rate, "22")
      |> assign(:selected_account, "all")
      |> assign(:capital_gains_results, nil)
      |> assign(:harvest_opportunities, nil)
      |> assign(:annual_summary, nil)
      |> assign(:tax_lot_report, nil)
      |> load_accounts()
      |> load_initial_data()

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Page Header -->
      <div class="bg-white shadow">
        <div class="px-6 py-4">
          <div class="sm:flex sm:items-center">
            <div class="sm:flex-auto">
              <h1 class="text-2xl font-semibold text-gray-900">Tax Planning & Optimization</h1>
              <p class="mt-2 text-sm text-gray-700">
                Analyze capital gains, identify tax-loss harvesting opportunities, and optimize your tax strategy.
              </p>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Tax Planning Controls -->
      <div class="bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <div class="grid grid-cols-1 gap-6 lg:grid-cols-4">
            <!-- Tax Year Selection -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Tax Year
              </label>
              <select
                phx-change="update_tax_year"
                name="tax_year"
                value={@tax_year}
                class="block w-full rounded-md border-gray-300 py-2 pl-3 pr-10 text-base focus:border-blue-500 focus:outline-none focus:ring-blue-500 sm:text-sm"
              >
                <%= for year <- (Date.utc_today().year - 5)..(Date.utc_today().year + 1) do %>
                  <option value={year}>{year}</option>
                <% end %>
              </select>
            </div>
            
    <!-- Account Filter -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Account
              </label>
              <select
                phx-change="update_account"
                name="account_id"
                value={@selected_account}
                class="block w-full rounded-md border-gray-300 py-2 pl-3 pr-10 text-base focus:border-blue-500 focus:outline-none focus:ring-blue-500 sm:text-sm"
              >
                <option value="all">All Accounts</option>
                <%= for account <- @accounts do %>
                  <option value={account.id}>{account.name}</option>
                <% end %>
              </select>
            </div>
            
    <!-- Tax Rate -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Marginal Tax Rate (%)
              </label>
              <select
                phx-change="update_tax_rate"
                name="tax_rate"
                value={@marginal_tax_rate}
                class="block w-full rounded-md border-gray-300 py-2 pl-3 pr-10 text-base focus:border-blue-500 focus:outline-none focus:ring-blue-500 sm:text-sm"
              >
                <option value="10">10%</option>
                <option value="12">12%</option>
                <option value="22">22%</option>
                <option value="24">24%</option>
                <option value="32">32%</option>
                <option value="35">35%</option>
                <option value="37">37%</option>
              </select>
            </div>
            
    <!-- Refresh Button -->
            <div class="flex items-end">
              <button
                phx-click="refresh_analysis"
                disabled={@loading}
                class="flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
              >
                <%= if @loading do %>
                  <svg
                    class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
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
                  Analyzing...
                <% else %>
                  Refresh Analysis
                <% end %>
              </button>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Tab Navigation -->
      <div class="bg-white shadow">
        <div class="border-b border-gray-200">
          <nav class="-mb-px flex space-x-8 px-6" aria-label="Tabs">
            <button
              phx-click="switch_tab"
              phx-value-tab="capital_gains"
              class={"py-4 px-1 border-b-2 font-medium text-sm " <> 
                if @active_tab == "capital_gains", 
                  do: "border-blue-500 text-blue-600", 
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}
            >
              Capital Gains Analysis
            </button>

            <button
              phx-click="switch_tab"
              phx-value-tab="harvest_opportunities"
              class={"py-4 px-1 border-b-2 font-medium text-sm " <> 
                if @active_tab == "harvest_opportunities", 
                  do: "border-blue-500 text-blue-600", 
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}
            >
              Tax-Loss Harvesting
            </button>

            <button
              phx-click="switch_tab"
              phx-value-tab="annual_summary"
              class={"py-4 px-1 border-b-2 font-medium text-sm " <> 
                if @active_tab == "annual_summary", 
                  do: "border-blue-500 text-blue-600", 
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}
            >
              Annual Summary
            </button>

            <button
              phx-click="switch_tab"
              phx-value-tab="tax_lots"
              class={"py-4 px-1 border-b-2 font-medium text-sm " <> 
                if @active_tab == "tax_lots", 
                  do: "border-blue-500 text-blue-600", 
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}
            >
              Tax Lot Report
            </button>
          </nav>
        </div>
      </div>
      
    <!-- Tab Content -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4">
          <%= case @active_tab do %>
            <% "capital_gains" -> %>
              {render_capital_gains_tab(assigns)}
            <% "harvest_opportunities" -> %>
              {render_harvest_opportunities_tab(assigns)}
            <% "annual_summary" -> %>
              {render_annual_summary_tab(assigns)}
            <% "tax_lots" -> %>
              {render_tax_lots_tab(assigns)}
          <% end %>
        </div>
      </div>
      
    <!-- Error Display -->
      <%= if length(@errors) > 0 do %>
        <div class="bg-red-50 border border-red-200 rounded-md p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm text-red-700">
                There were errors in your tax analysis:
              </p>
              <ul class="mt-2 text-sm text-red-700 list-disc list-inside">
                <%= for error <- @errors do %>
                  <li>{error}</li>
                <% end %>
              </ul>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Tab rendering functions
  defp render_capital_gains_tab(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="border-b border-gray-200 pb-4">
        <h3 class="text-lg leading-6 font-medium text-gray-900">Capital Gains & Losses Analysis</h3>
        <p class="mt-2 text-sm text-gray-700">
          FIFO cost basis calculations and realized/unrealized gains analysis for tax planning.
        </p>
      </div>

      <%= if @capital_gains_results do %>
        <!-- Realized Gains Summary -->
        <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          <div class="bg-gray-50 overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg
                    class="h-6 w-6 text-gray-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1"
                    />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Total Realized Gains</dt>
                    <dd class={"text-lg font-medium " <> 
                      if Decimal.compare(@capital_gains_results.total_realized_gains, Decimal.new("0")) == :gt, 
                        do: "text-green-600", 
                        else: "text-red-600"}>
                      ${Ashfolio.Financial.Formatters.currency(
                        @capital_gains_results.total_realized_gains
                      )}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-green-50 overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg
                    class="h-6 w-6 text-green-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"
                    />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Long-Term Gains</dt>
                    <dd class="text-lg font-medium text-green-600">
                      ${Ashfolio.Financial.Formatters.currency(@capital_gains_results.long_term_gains)}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-yellow-50 overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg
                    class="h-6 w-6 text-yellow-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Short-Term Gains</dt>
                    <dd class="text-lg font-medium text-yellow-600">
                      ${Ashfolio.Financial.Formatters.currency(
                        @capital_gains_results.short_term_gains
                      )}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-blue-50 overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg
                    class="h-6 w-6 text-blue-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                    />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Transactions Processed</dt>
                    <dd class="text-lg font-medium text-blue-600">
                      {@capital_gains_results.transactions_processed}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% else %>
        <div class="text-center py-12">
          <svg
            class="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No Capital Gains Analysis Available</h3>
          <p class="mt-1 text-sm text-gray-500">
            Click "Refresh Analysis" to generate capital gains and loss calculations.
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_harvest_opportunities_tab(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="border-b border-gray-200 pb-4">
        <h3 class="text-lg leading-6 font-medium text-gray-900">Tax-Loss Harvesting Opportunities</h3>
        <p class="mt-2 text-sm text-gray-700">
          Identify positions with unrealized losses that can be harvested for tax benefits.
        </p>
      </div>

      <%= if @harvest_opportunities do %>
        <!-- Harvest Summary -->
        <div class="grid grid-cols-1 gap-5 sm:grid-cols-3">
          <div class="bg-red-50 overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg
                    class="h-6 w-6 text-red-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 17h8m0 0V9m0 8l-8-8-4 4-6-6"
                    />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">
                      Total Harvestable Losses
                    </dt>
                    <dd class="text-lg font-medium text-red-600">
                      ${Ashfolio.Financial.Formatters.currency(
                        @harvest_opportunities.total_harvestable_losses
                      )}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-green-50 overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg
                    class="h-6 w-6 text-green-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1"
                    />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Estimated Tax Savings</dt>
                    <dd class="text-lg font-medium text-green-600">
                      ${Ashfolio.Financial.Formatters.currency(
                        @harvest_opportunities.estimated_tax_savings
                      )}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-blue-50 overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg
                    class="h-6 w-6 text-blue-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M7 4V2a1 1 0 011-1h4a1 1 0 011 1v2h4a1 1 0 011 1v1H3V5a1 1 0 011-1h3zM3 7h14l-1 10H4L3 7z"
                    />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Opportunities Found</dt>
                    <dd class="text-lg font-medium text-blue-600">
                      {@harvest_opportunities.opportunities_found}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Opportunities Table -->
        <%= if length(@harvest_opportunities.opportunities) > 0 do %>
          <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
            <table class="min-w-full divide-y divide-gray-300">
              <thead class="bg-gray-50">
                <tr>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wide"
                  >
                    Symbol
                  </th>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wide"
                  >
                    Unrealized Loss
                  </th>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wide"
                  >
                    Tax Benefit
                  </th>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wide"
                  >
                    Wash Sale Risk
                  </th>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wide"
                  >
                    Replacements
                  </th>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wide"
                  >
                    Priority
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for opportunity <- @harvest_opportunities.opportunities do %>
                  <tr>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {opportunity.symbol}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-red-600">
                      ${Ashfolio.Financial.Formatters.currency(opportunity.unrealized_loss)}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-green-600">
                      ${Ashfolio.Financial.Formatters.currency(opportunity.tax_benefit)}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <%= if opportunity.wash_sale_risk do %>
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                          High Risk
                        </span>
                      <% else %>
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                          Compliant
                        </span>
                      <% end %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {Enum.join(opportunity.replacement_options || [], ", ")}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {Decimal.to_string(opportunity.priority_score)}
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>
      <% else %>
        <div class="text-center py-12">
          <svg
            class="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M13 17h8m0 0V9m0 8l-8-8-4 4-6-6"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No Harvest Opportunities Available</h3>
          <p class="mt-1 text-sm text-gray-500">
            Click "Refresh Analysis" to identify tax-loss harvesting opportunities.
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_annual_summary_tab(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="border-b border-gray-200 pb-4">
        <h3 class="text-lg leading-6 font-medium text-gray-900">Annual Tax Summary ({@tax_year})</h3>
        <p class="mt-2 text-sm text-gray-700">
          Comprehensive year-to-date summary for tax preparation and planning.
        </p>
      </div>

      <%= if @annual_summary do %>
        <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          <div class="bg-blue-50 overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg
                    class="h-6 w-6 text-blue-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1"
                    />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Total Proceeds</dt>
                    <dd class="text-lg font-medium text-blue-600">
                      ${Ashfolio.Financial.Formatters.currency(@annual_summary.total_proceeds)}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div class={"overflow-hidden shadow rounded-lg " <> 
            if Decimal.compare(@annual_summary.net_capital_gains, Decimal.new("0")) == :gt, 
              do: "bg-green-50", 
              else: "bg-red-50"}>
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg
                    class={"h-6 w-6 " <> 
                    if Decimal.compare(@annual_summary.net_capital_gains, Decimal.new("0")) == :gt, 
                      do: "text-green-400", 
                      else: "text-red-400"}
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"
                    />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Net Capital Gains</dt>
                    <dd class={"text-lg font-medium " <> 
                      if Decimal.compare(@annual_summary.net_capital_gains, Decimal.new("0")) == :gt, 
                        do: "text-green-600", 
                        else: "text-red-600"}>
                      ${Ashfolio.Financial.Formatters.currency(@annual_summary.net_capital_gains)}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-yellow-50 overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg
                    class="h-6 w-6 text-yellow-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Short-Term Gains</dt>
                    <dd class="text-lg font-medium text-yellow-600">
                      ${Ashfolio.Financial.Formatters.currency(@annual_summary.short_term_gains)}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-green-50 overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg
                    class="h-6 w-6 text-green-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"
                    />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Long-Term Gains</dt>
                    <dd class="text-lg font-medium text-green-600">
                      ${Ashfolio.Financial.Formatters.currency(@annual_summary.long_term_gains)}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% else %>
        <div class="text-center py-12">
          <svg
            class="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No Annual Summary Available</h3>
          <p class="mt-1 text-sm text-gray-500">
            Click "Refresh Analysis" to generate annual tax summary.
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_tax_lots_tab(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="border-b border-gray-200 pb-4">
        <h3 class="text-lg leading-6 font-medium text-gray-900">Tax Lot Report</h3>
        <p class="mt-2 text-sm text-gray-700">
          Detailed breakdown of all tax lots with cost basis and holding periods.
        </p>
      </div>

      <%= if @tax_lot_report do %>
        <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
          <div class="bg-blue-50 overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg
                    class="h-6 w-6 text-blue-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M7 4V2a1 1 0 011-1h4a1 1 0 011 1v2h4a1 1 0 011 1v1H3V5a1 1 0 011-1h3zM3 7h14l-1 10H4L3 7z"
                    />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Total Tax Lots</dt>
                    <dd class="text-lg font-medium text-blue-600">
                      {@tax_lot_report.summary.total_lots}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-green-50 overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg
                    class="h-6 w-6 text-green-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                    />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Unique Positions</dt>
                    <dd class="text-lg font-medium text-green-600">
                      {@tax_lot_report.summary.total_positions}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Tax Lots Table would go here when data is available -->
        <div class="text-center py-8">
          <p class="text-sm text-gray-500">
            Tax lot detail table will be displayed here when tax lot data is available.
          </p>
        </div>
      <% else %>
        <div class="text-center py-12">
          <svg
            class="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No Tax Lot Report Available</h3>
          <p class="mt-1 text-sm text-gray-500">
            Click "Refresh Analysis" to generate detailed tax lot report.
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    socket = assign(socket, :active_tab, tab)
    {:noreply, socket}
  end

  def handle_event("update_tax_year", %{"tax_year" => tax_year}, socket) do
    socket = assign(socket, :tax_year, String.to_integer(tax_year))
    {:noreply, socket}
  end

  def handle_event("update_account", %{"account_id" => account_id}, socket) do
    socket = assign(socket, :selected_account, account_id)
    {:noreply, socket}
  end

  def handle_event("update_tax_rate", %{"tax_rate" => tax_rate}, socket) do
    socket = assign(socket, :marginal_tax_rate, tax_rate)
    {:noreply, socket}
  end

  def handle_event("refresh_analysis", _params, socket) do
    socket =
      socket
      |> assign(:loading, true)
      |> assign(:errors, [])

    send(self(), :perform_tax_analysis)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:perform_tax_analysis, socket) do
    account_id = if socket.assigns.selected_account == "all", do: nil, else: socket.assigns.selected_account
    tax_rate = socket.assigns.marginal_tax_rate |> Decimal.new() |> Decimal.div(Decimal.new("100"))

    # Perform tax analysis in background
    task_results =
      Task.async_stream(
        [
          {:capital_gains, fn -> calculate_mock_capital_gains(socket.assigns.tax_year, account_id) end},
          {:harvest_opportunities, fn -> identify_mock_harvest_opportunities(account_id, tax_rate) end},
          {:annual_summary, fn -> generate_mock_annual_summary(socket.assigns.tax_year, account_id) end},
          {:tax_lot_report, fn -> generate_mock_tax_lot_report(account_id) end}
        ],
        fn {key, func} -> {key, func.()} end,
        timeout: 30_000
      )

    # Process results
    results =
      task_results
      |> Enum.reduce(%{}, fn {:ok, {key, result}}, acc ->
        case result do
          {:ok, data} -> Map.put(acc, key, data)
          {:error, error} -> Map.put(acc, :errors, [error | Map.get(acc, :errors, [])])
        end
      end)

    socket =
      socket
      |> assign(:loading, false)
      |> assign(:errors, Map.get(results, :errors, []))
      |> assign(:capital_gains_results, Map.get(results, :capital_gains))
      |> assign(:harvest_opportunities, Map.get(results, :harvest_opportunities))
      |> assign(:annual_summary, Map.get(results, :annual_summary))
      |> assign(:tax_lot_report, Map.get(results, :tax_lot_report))

    {:noreply, socket}
  end

  # Private helper functions

  defp load_accounts(socket) do
    case Account.list_all_accounts() do
      {:ok, accounts} ->
        active_accounts = Enum.filter(accounts, &(not &1.is_excluded))
        assign(socket, :accounts, active_accounts)

      {:error, _} ->
        assign(socket, :accounts, [])
    end
  end

  defp load_initial_data(socket) do
    # Load initial data if needed
    socket
  end

  # Mock data functions for MVP (to be replaced with real calculations)
  defp calculate_mock_capital_gains(tax_year, _account_id) do
    {:ok,
     %{
       tax_year: tax_year,
       total_realized_gains: Decimal.new("2500.75"),
       short_term_gains: Decimal.new("800.25"),
       long_term_gains: Decimal.new("1700.50"),
       transactions_processed: 15
     }}
  end

  defp identify_mock_harvest_opportunities(_account_id, tax_rate) do
    opportunities = [
      %{
        symbol: "AAPL",
        unrealized_loss: Decimal.new("1500.50"),
        tax_benefit: Decimal.mult(Decimal.new("1500.50"), tax_rate),
        wash_sale_risk: false,
        replacement_options: ["VTI", "ITOT"],
        priority_score: Decimal.new("0.15")
      },
      %{
        symbol: "TSLA",
        unrealized_loss: Decimal.new("2200.25"),
        tax_benefit: Decimal.mult(Decimal.new("2200.25"), tax_rate),
        wash_sale_risk: true,
        replacement_options: ["QQQ", "VTI"],
        priority_score: Decimal.new("0.08")
      }
    ]

    total_losses =
      opportunities
      |> Enum.map(& &1.unrealized_loss)
      |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)

    tax_savings =
      opportunities
      |> Enum.map(& &1.tax_benefit)
      |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)

    {:ok,
     %{
       opportunities: opportunities,
       total_harvestable_losses: total_losses,
       estimated_tax_savings: tax_savings,
       opportunities_found: length(opportunities),
       positions_analyzed: 25
     }}
  end

  defp generate_mock_annual_summary(tax_year, _account_id) do
    {:ok,
     %{
       tax_year: tax_year,
       total_proceeds: Decimal.new("45000.00"),
       net_capital_gains: Decimal.new("3200.50"),
       short_term_gains: Decimal.new("1100.25"),
       long_term_gains: Decimal.new("2100.25"),
       transactions_analyzed: 28
     }}
  end

  defp generate_mock_tax_lot_report(_account_id) do
    {:ok,
     %{
       tax_lots: [],
       summary: %{
         total_lots: 42,
         total_positions: 18
       }
     }}
  end
end
