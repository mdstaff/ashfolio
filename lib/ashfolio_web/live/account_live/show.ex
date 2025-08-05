defmodule AshfolioWeb.AccountLive.Show do
  use AshfolioWeb, :live_view

  alias Ashfolio.Portfolio.{Account, Transaction}
  alias AshfolioWeb.Live.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_current_page(:accounts)
     |> assign(:page_title, "Account Details")
     |> assign(:page_subtitle, "View account information and transaction summary")}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    try do
      account = Account.get_by_id!(id)

      transactions = Transaction.by_account!(id)

      transaction_stats = calculate_transaction_stats(transactions)

      {:noreply,
       socket
       |> assign(:account, account)
       |> assign(:transactions, transactions)
       |> assign(:transaction_stats, transaction_stats)
       |> assign(:page_title, "#{account.name} - Account Details")}
    rescue
      Ash.Error.Query.NotFound ->
        {:noreply,
         socket
         |> put_flash(:error, "Account not found")
         |> push_navigate(to: ~p"/accounts")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Breadcrumb Navigation -->
      <nav class="flex" aria-label="Breadcrumb">
        <ol class="inline-flex items-center space-x-1 md:space-x-3">
          <li class="inline-flex items-center">
            <.link
              navigate={~p"/accounts"}
              class="inline-flex items-center text-sm font-medium text-gray-700 hover:text-blue-600"
            >
              <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20">
                <path d="M10.707 2.293a1 1 0 00-1.414 0l-7 7a1 1 0 001.414 1.414L4 10.414V17a1 1 0 001 1h2a1 1 0 001-1v-2a1 1 0 011-1h2a1 1 0 011 1v2a1 1 0 001 1h2a1 1 0 001-1v-6.586l.293.293a1 1 0 001.414-1.414l-7-7z" />
              </svg>
              Accounts
            </.link>
          </li>
          <li>
            <div class="flex items-center">
              <svg class="w-6 h-6 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
              </svg>
              <span class="ml-1 text-sm font-medium text-gray-500 md:ml-2">
                {@account.name}
              </span>
            </div>
          </li>
        </ol>
      </nav>

      <!-- Account Header -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4 border-b border-gray-200">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-3">
              <!-- Account Icon -->
              <div class="flex-shrink-0">
                <div class="h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center">
                  <svg class="h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                  </svg>
                </div>
              </div>

              <!-- Account Details -->
              <div>
                <h1 class="text-2xl font-bold text-gray-900">{@account.name}</h1>
                <div class="flex items-center space-x-4 mt-1">
                  <p class="text-gray-600">
                    {@account.platform || "No platform specified"}
                  </p>
                  <%= if @account.is_excluded do %>
                    <span class="status-badge status-badge-warning">
                      <svg class="w-3 h-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728L5.636 5.636m12.728 12.728L18.364 5.636M5.636 18.364l12.728-12.728" />
                      </svg>
                      Excluded from Portfolio
                    </span>
                  <% else %>
                    <span class="status-badge status-badge-success">
                      <svg class="w-3 h-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      Active
                    </span>
                  <% end %>
                </div>
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="flex space-x-2">
              <.link
                navigate={~p"/accounts/#{@account.id}/edit"}
                class="btn-secondary inline-flex items-center"
              >
                <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
                Edit Account
              </.link>
            </div>
          </div>
        </div>
      </div>

      <!-- Account Statistics -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <!-- Balance Card -->
        <div class="bg-white shadow rounded-lg p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <div class="h-8 w-8 rounded-md bg-green-100 flex items-center justify-center">
                <svg class="h-5 w-5 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
                </svg>
              </div>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Account Balance</p>
              <p class={"text-2xl font-bold #{if @account.is_excluded, do: "text-gray-500", else: "text-gray-900"}"}>
                {FormatHelpers.format_currency(@account.balance)}
              </p>
              <div class="text-xs text-gray-500 mt-1">
                <%= if @account.is_excluded do %>
                  <p>Excluded from calculations</p>
                <% end %>
                <%= if @account.balance_updated_at do %>
                  <p>Balance updated {FormatHelpers.format_relative_time(@account.balance_updated_at)}</p>
                <% else %>
                  <p class="text-yellow-600">Balance not yet updated - Phase 1 manual entry required</p>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <!-- Transaction Count Card -->
        <div class="bg-white shadow rounded-lg p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <div class="h-8 w-8 rounded-md bg-blue-100 flex items-center justify-center">
                <svg class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
                </svg>
              </div>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Total Transactions</p>
              <p class="text-2xl font-bold text-gray-900">
                {length(@transactions)}
              </p>
              <p class="text-xs text-gray-500 mt-1">
                All transaction types
              </p>
            </div>
          </div>
        </div>

        <!-- Status Card -->
        <div class="bg-white shadow rounded-lg p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <div class={"h-8 w-8 rounded-md flex items-center justify-center #{if @account.is_excluded, do: "bg-yellow-100", else: "bg-green-100"}"}>
                <%= if @account.is_excluded do %>
                  <svg class="h-5 w-5 text-yellow-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728L5.636 5.636m12.728 12.728L18.364 5.636M5.636 18.364l12.728-12.728" />
                  </svg>
                <% else %>
                  <svg class="h-5 w-5 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                <% end %>
              </div>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Account Status</p>
              <p class={"text-2xl font-bold #{if @account.is_excluded, do: "text-yellow-600", else: "text-green-600"}"}>
                {if @account.is_excluded, do: "Excluded", else: "Active"}
              </p>
              <p class="text-xs text-gray-500 mt-1">
                {if @account.is_excluded, do: "Not included in portfolio", else: "Included in portfolio"}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Transaction Summary -->
      <%= if not Enum.empty?(@transactions) do %>
        <div class="bg-white shadow rounded-lg">
          <div class="px-6 py-4 border-b border-gray-200">
            <h2 class="text-lg font-medium text-gray-900">Transaction Summary</h2>
            <p class="text-sm text-gray-600">Overview of transactions in this account</p>
          </div>
          <div class="p-6">
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
              <!-- Buy Transactions -->
              <div class="text-center">
                <div class="text-2xl font-bold text-green-600">
                  {@transaction_stats.buy_count}
                </div>
                <div class="text-sm text-gray-500">Buy Orders</div>
                <div class="text-xs text-gray-400 mt-1">
                  {FormatHelpers.format_currency(@transaction_stats.buy_total)}
                </div>
              </div>

              <!-- Sell Transactions -->
              <div class="text-center">
                <div class="text-2xl font-bold text-red-600">
                  {@transaction_stats.sell_count}
                </div>
                <div class="text-sm text-gray-500">Sell Orders</div>
                <div class="text-xs text-gray-400 mt-1">
                  {FormatHelpers.format_currency(@transaction_stats.sell_total)}
                </div>
              </div>

              <!-- Dividend Transactions -->
              <div class="text-center">
                <div class="text-2xl font-bold text-blue-600">
                  {@transaction_stats.dividend_count}
                </div>
                <div class="text-sm text-gray-500">Dividends</div>
                <div class="text-xs text-gray-400 mt-1">
                  {FormatHelpers.format_currency(@transaction_stats.dividend_total)}
                </div>
              </div>

              <!-- Fee Transactions -->
              <div class="text-center">
                <div class="text-2xl font-bold text-gray-600">
                  {@transaction_stats.fee_count}
                </div>
                <div class="text-sm text-gray-500">Fees</div>
                <div class="text-xs text-gray-400 mt-1">
                  {FormatHelpers.format_currency(@transaction_stats.fee_total)}
                </div>
              </div>
            </div>
          </div>
        </div>
      <% else %>
        <!-- No Transactions State -->
        <div class="bg-white shadow rounded-lg">
          <div class="text-center py-12 px-6">
            <div class="mx-auto h-12 w-12 text-gray-400 mb-4">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-full h-full">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
              </svg>
            </div>
            <h3 class="text-lg font-medium text-gray-900 mb-2">No transactions</h3>
            <p class="text-gray-500 mb-6 max-w-sm mx-auto">
              This account doesn't have any transactions yet. Start by adding your first transaction.
            </p>
            <.link
              navigate={~p"/transactions"}
              class="btn-primary inline-flex items-center"
            >
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              Add Transaction
            </.link>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp calculate_transaction_stats(transactions) do
    transactions
    |> Enum.reduce(
      %{
        buy_count: 0,
        buy_total: Decimal.new(0),
        sell_count: 0,
        sell_total: Decimal.new(0),
        dividend_count: 0,
        dividend_total: Decimal.new(0),
        fee_count: 0,
        fee_total: Decimal.new(0)
      },
      fn transaction, acc ->
        case transaction.type do
          :buy ->
            %{
              acc
              | buy_count: acc.buy_count + 1,
                buy_total: Decimal.add(acc.buy_total, transaction.total_amount || Decimal.new(0))
            }

          :sell ->
            %{
              acc
              | sell_count: acc.sell_count + 1,
                sell_total: Decimal.add(acc.sell_total, Decimal.abs(transaction.total_amount || Decimal.new(0)))
            }

          :dividend ->
            %{
              acc
              | dividend_count: acc.dividend_count + 1,
                dividend_total: Decimal.add(acc.dividend_total, transaction.total_amount || Decimal.new(0))
            }

          :fee ->
            %{
              acc
              | fee_count: acc.fee_count + 1,
                fee_total: Decimal.add(acc.fee_total, transaction.total_amount || Decimal.new(0))
            }
        end
      end
    )
  end
end
