defmodule AshfolioWeb.AccountLive.Index do
  use AshfolioWeb, :live_view

  alias Ashfolio.Portfolio.{Account, Transaction}
  alias Ashfolio.Context
  alias AshfolioWeb.Live.{FormatHelpers, ErrorHelpers}
  alias AshfolioWeb.AccountLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_current_page(:accounts)
      |> assign(:page_title, "Accounts")
      |> assign(:page_subtitle, "Manage your investment and cash accounts")
      |> assign(:show_form, false)
      |> assign(:form_action, :new)
      |> assign(:selected_account, nil)
      |> assign(:toggling_account_id, nil)
      |> assign(:deleting_account_id, nil)
      |> assign(:account_filter, :all)
      |> assign(:loading_dashboard, true)

    # Load dashboard data using Context API
    socket = assign_dashboard_data(socket)

    # Subscribe to account updates for real-time changes
    Ashfolio.PubSub.subscribe("accounts")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("new_account", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:form_action, :new)
     |> assign(:selected_account, nil)}
  end

  @impl true
  def handle_event("filter_accounts", %{"filter" => filter}, socket) do
    filter_atom = String.to_existing_atom(filter)

    {:noreply,
     socket
     |> assign(:account_filter, filter_atom)
     |> assign(:filtered_accounts, get_filtered_accounts(socket.assigns.accounts, filter_atom))}
  end

  @impl true
  def handle_event("edit_account", %{"id" => id}, socket) do
    # Find account in the Context API data structure
    accounts_list =
      if is_map(socket.assigns.accounts),
        do: socket.assigns.accounts.all,
        else: socket.assigns.accounts

    account = Enum.find(accounts_list, &(&1.id == id))

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:form_action, :edit)
     |> assign(:selected_account, account)}
  end

  @impl true
  def handle_event("delete_account", %{"id" => id}, socket) do
    # Set loading state for visual feedback
    socket = assign(socket, :deleting_account_id, id)

    # Check if account has any transactions before allowing deletion
    case Transaction.by_account!(id) do
      [] ->
        # Safe to delete - no transactions
        case Account.destroy(id) do
          :ok ->
            Ashfolio.PubSub.broadcast!("accounts", {:account_deleted, id})
            socket = assign_dashboard_data(socket)

            {:noreply,
             socket
             |> ErrorHelpers.put_success_flash("Account deleted successfully")
             |> assign(:deleting_account_id, nil)}

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:deleting_account_id, nil)
             |> ErrorHelpers.put_error_flash(reason, "Failed to delete account")}
        end

      _transactions ->
        # Has transactions - prevent deletion
        {:noreply,
         socket
         |> assign(:deleting_account_id, nil)
         |> ErrorHelpers.put_error_flash(
           "Cannot delete account with transactions. Consider excluding it instead.",
           "Account has associated transactions"
         )}
    end
  end

  @impl true
  def handle_event("toggle_exclusion", %{"id" => id}, socket) do
    # Check if already toggling this account to prevent concurrent operations
    if socket.assigns.toggling_account_id == id do
      {:noreply, socket}
    else
      # Store original accounts for potential rollback
      accounts_list =
        if is_map(socket.assigns.accounts),
          do: socket.assigns.accounts.all,
          else: socket.assigns.accounts

      account_index = Enum.find_index(accounts_list, &(&1.id == id))

      case account_index do
        nil ->
          {:noreply,
           socket
           |> ErrorHelpers.put_error_flash(:not_found, "Account not found")}

        _ ->
          account = Enum.at(accounts_list, account_index)

          # Since we're using Context API, we'll just mark the toggling state
          # and let the Context API reload handle the actual update
          socket =
            socket
            |> assign(:toggling_account_id, id)

          case Account.toggle_exclusion(account, %{is_excluded: !account.is_excluded}) do
            {:ok, updated_account_from_db} ->
              Ashfolio.PubSub.broadcast!("accounts", {:account_updated, updated_account_from_db})

              # Reload accounts to ensure consistency using Context API
              socket = assign_dashboard_data(socket)

              socket =
                socket
                |> assign(:toggling_account_id, nil)
                |> ErrorHelpers.put_success_flash("Account exclusion updated successfully")

              {:noreply, socket}

            {:error, reason} ->
              # Clear the toggling state on failure
              {:noreply,
               socket
               |> assign(:toggling_account_id, nil)
               |> ErrorHelpers.put_error_flash(reason, "Failed to update account exclusion")}
          end
      end
    end
  end

  @impl true
  def handle_info({FormComponent, {:saved, _account}}, socket) do
    socket = assign_dashboard_data(socket)

    {:noreply,
     socket
     |> ErrorHelpers.put_success_flash("Account saved successfully")
     |> assign(:show_form, false)}
  end

  @impl true
  def handle_info({FormComponent, {:saved, account, message}}, socket) do
    Ashfolio.PubSub.broadcast!("accounts", {:account_saved, account})

    socket = assign_dashboard_data(socket)

    {:noreply,
     socket
     |> ErrorHelpers.put_success_flash(message)
     |> assign(:show_form, false)}
  end

  @impl true
  def handle_info({FormComponent, :cancel}, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  @impl true
  def handle_info({FormComponent, {:failed, _form}}, socket) do
    {:noreply,
     socket
     |> ErrorHelpers.put_error_flash(
       "Please correct the errors in the form.",
       "Failed to save account"
     )
     # Keep the form open
     |> assign(:show_form, true)}
  end

  # PubSub handlers for real-time updates
  @impl true
  def handle_info({:account_updated, _account}, socket) do
    socket = assign_dashboard_data(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:account_deleted, _account_id}, socket) do
    socket = assign_dashboard_data(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:account_saved, _account}, socket) do
    socket = assign_dashboard_data(socket)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header with New Account Button -->
      <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Accounts</h1>
          <p class="text-gray-600">Manage your investment and cash accounts</p>
        </div>
        <.button phx-click="new_account" class="btn-primary inline-flex items-center">
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          New Account
        </.button>
      </div>
      
    <!-- Account Filter Tabs -->
      <%= if @accounts && Map.has_key?(@accounts, :all) do %>
        <div class="bg-white shadow rounded-lg">
          <div class="px-6 py-4 border-b border-gray-200">
            <div class="flex space-x-1">
              <button
                class={
                  if @account_filter == :all,
                    do: "btn-primary text-sm px-4 py-2",
                    else: "btn-secondary text-sm px-4 py-2"
                }
                phx-click="filter_accounts"
                phx-value-filter="all"
              >
                All Accounts ({length(@accounts.all)})
              </button>
              <button
                class={
                  if @account_filter == :investment,
                    do: "btn-primary text-sm px-4 py-2",
                    else: "btn-secondary text-sm px-4 py-2"
                }
                phx-click="filter_accounts"
                phx-value-filter="investment"
              >
                Investment ({length(@accounts.investment)})
              </button>
              <button
                class={
                  if @account_filter == :cash,
                    do: "btn-primary text-sm px-4 py-2",
                    else: "btn-secondary text-sm px-4 py-2"
                }
                phx-click="filter_accounts"
                phx-value-filter="cash"
              >
                Cash ({length(@accounts.cash)})
              </button>
            </div>
          </div>
          
    <!-- Summary Stats -->
          <%= if @summary do %>
            <div class="px-6 py-4 bg-gray-50">
              <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div class="text-center">
                  <div class="text-2xl font-bold text-gray-900">
                    {FormatHelpers.format_currency(@summary.total_balance)}
                  </div>
                  <div class="text-sm text-gray-500">Total Balance</div>
                </div>
                <div class="text-center">
                  <div class="text-2xl font-bold text-blue-600">
                    {FormatHelpers.format_currency(@summary.investment_balance)}
                  </div>
                  <div class="text-sm text-gray-500">Investment Value</div>
                </div>
                <div class="text-center">
                  <div class="text-2xl font-bold text-green-600">
                    {FormatHelpers.format_currency(@summary.cash_balance)}
                  </div>
                  <div class="text-sm text-gray-500">Cash Balance</div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
      
    <!-- Accounts Table or Empty State -->
      <%= if @loading_dashboard do %>
        <div class="bg-white shadow rounded-lg">
          <div class="text-center py-16 px-6">
            <.loading_spinner class="mx-auto w-8 h-8 text-blue-600 mb-4" />
            <p class="text-gray-500">Loading accounts...</p>
          </div>
        </div>
      <% else %>
        <% display_accounts =
          if assigns[:filtered_accounts],
            do: @filtered_accounts,
            else: get_display_accounts(@accounts, @account_filter) %>
        <%= if Enum.empty?(display_accounts) do %>
          <!-- Enhanced Empty State -->
          <div class="bg-white shadow rounded-lg">
            <div class="text-center py-16 px-6">
              <div class="mx-auto h-16 w-16 text-gray-400 mb-4">
                <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-full h-full">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                  />
                </svg>
              </div>
              <h3 class="text-lg font-medium text-gray-900 mb-2">No accounts</h3>
              <p class="text-gray-500 mb-6 max-w-sm mx-auto">
                Get started by creating your first investment account to track your portfolio and transactions.
              </p>
              <.button phx-click="new_account" class="btn-primary inline-flex items-center">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                Create Your First Account
              </.button>
            </div>
          </div>
        <% else %>
          <!-- Enhanced Accounts Table with Responsive Design -->
          <div class="bg-white shadow rounded-lg overflow-hidden">
            <div class="overflow-x-auto">
              <.table id="accounts-table" rows={display_accounts} class="min-w-full">
                <:col :let={account} label="Account" class="min-w-0 w-full sm:w-auto">
                  <div class="flex items-center space-x-3">
                    <!-- Account Icon -->
                    <div class="flex-shrink-0">
                      <div class="h-8 w-8 rounded-full bg-blue-100 flex items-center justify-center">
                        <svg
                          class="h-4 w-4 text-blue-600"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                          />
                        </svg>
                      </div>
                    </div>
                    
    <!-- Account Details -->
                    <div class="min-w-0 flex-1">
                      <div class="flex items-center space-x-2">
                        <p class="font-medium text-gray-900 truncate">{account.name}</p>
                        <%= if account.is_excluded do %>
                          <span class="status-badge status-badge-warning flex-shrink-0">
                            <svg
                              class="w-3 h-3 mr-1"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke="currentColor"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728L5.636 5.636m12.728 12.728L18.364 5.636M5.636 18.364l12.728-12.728"
                              />
                            </svg>
                            Excluded
                          </span>
                        <% else %>
                          <span class="status-badge status-badge-success flex-shrink-0">
                            <svg
                              class="w-3 h-3 mr-1"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke="currentColor"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M5 13l4 4L19 7"
                              />
                            </svg>
                            Active
                          </span>
                        <% end %>
                      </div>
                      <p class="text-sm text-gray-500 truncate">
                        {account.platform || "No platform specified"}
                      </p>
                    </div>
                  </div>
                </:col>

                <:col :let={account} label="Balance" class="text-right">
                  <div class="text-right">
                    <span class={"font-mono font-semibold text-lg #{if account.is_excluded, do: "text-gray-500", else: "text-gray-900"}"}>
                      {FormatHelpers.format_currency(account.balance)}
                    </span>
                    <div class="text-xs text-gray-500 mt-1">
                      <%= if account.is_excluded do %>
                        <p>Excluded from calculations</p>
                      <% end %>
                      <%= if account.balance_updated_at do %>
                        <p>
                          Updated {FormatHelpers.format_relative_time(account.balance_updated_at)}
                        </p>
                      <% else %>
                        <p>Balance not yet updated</p>
                      <% end %>
                    </div>
                  </div>
                </:col>

                <:col :let={account} label="Actions" class="text-right">
                  <div class="account-actions">
                    <!-- View Button -->
                    <.link
                      navigate={~p"/accounts/#{account.id}"}
                      class="btn-view text-xs sm:text-sm px-2 sm:px-3 py-1 inline-flex items-center"
                      title="View account details"
                      aria-label={"View account details for #{account.name}"}
                    >
                      <svg
                        class="w-3 h-3 sm:w-4 sm:h-4 sm:mr-1"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                        />
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                        />
                      </svg>
                      <span class="hidden sm:inline">View</span>
                    </.link>
                    
    <!-- Edit Button -->
                    <.button
                      class="btn-secondary text-xs sm:text-sm px-2 sm:px-3 py-1 inline-flex items-center"
                      phx-click="edit_account"
                      phx-value-id={account.id}
                      title="Edit account"
                      aria-label={"Edit account #{account.name}"}
                    >
                      <svg
                        class="w-3 h-3 sm:w-4 sm:h-4 sm:mr-1"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                        />
                      </svg>
                      <span class="hidden sm:inline">Edit</span>
                    </.button>
                    
    <!-- Toggle Exclusion Button -->
                    <.button
                      class={
                        if account.is_excluded,
                          do:
                            "btn-success text-xs sm:text-sm px-2 sm:px-3 py-1 inline-flex items-center",
                          else:
                            "bg-yellow-100 hover:bg-yellow-200 text-yellow-800 text-xs sm:text-sm px-2 sm:px-3 py-1 rounded-md transition-colors duration-200 inline-flex items-center"
                      }
                      phx-click="toggle_exclusion"
                      phx-value-id={account.id}
                      disabled={@toggling_account_id == account.id}
                      title={
                        if account.is_excluded,
                          do: "Include in calculations",
                          else: "Exclude from calculations"
                      }
                      aria-label={"Toggle exclusion for #{account.name}"}
                    >
                      <%= if @toggling_account_id == account.id do %>
                        <!-- Loading spinner -->
                        <.loading_spinner class="w-3 h-3 sm:w-4 sm:h-4 sm:mr-1" />
                        <span class="hidden sm:inline">Updating...</span>
                      <% else %>
                        <%= if account.is_excluded do %>
                          <svg
                            class="w-3 h-3 sm:w-4 sm:h-4 sm:mr-1"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M5 13l4 4L19 7"
                            />
                          </svg>
                          <span class="hidden sm:inline">Include</span>
                        <% else %>
                          <svg
                            class="w-3 h-3 sm:w-4 sm:h-4 sm:mr-1"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728L5.636 5.636m12.728 12.728L18.364 5.636M5.636 18.364l12.728-12.728"
                            />
                          </svg>
                          <span class="hidden sm:inline">Exclude</span>
                        <% end %>
                      <% end %>
                    </.button>
                    
    <!-- Delete Button -->
                    <.button
                      class="btn-danger text-xs sm:text-sm px-2 sm:px-3 py-1 inline-flex items-center"
                      phx-click="delete_account"
                      phx-value-id={account.id}
                      data-confirm="Are you sure you want to delete this account? This action cannot be undone."
                      title="Delete account"
                      aria-label={"Delete account #{account.name}"}
                      disabled={@deleting_account_id == account.id}
                    >
                      <%= if @deleting_account_id == account.id do %>
                        <.loading_spinner class="w-3 h-3 sm:w-4 sm:h-4 sm:mr-1" />
                        <span class="hidden sm:inline">Deleting...</span>
                      <% else %>
                        <svg
                          class="w-3 h-3 sm:w-4 sm:h-4 sm:mr-1"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                          />
                        </svg>
                        <span class="hidden sm:inline">Delete</span>
                      <% end %>
                    </.button>
                  </div>
                </:col>
              </.table>
            </div>
            
    <!-- Table Footer with Summary -->
            <div class="bg-gray-50 px-6 py-3 border-t border-gray-200">
              <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-2">
                <p class="text-sm text-gray-600">
                  {length(display_accounts)} account{if length(display_accounts) == 1,
                    do: "",
                    else: "s"} displayed
                </p>
                <p class="text-sm font-medium text-gray-900">
                  Filtered Balance:
                  <span class="font-mono">
                    {FormatHelpers.format_currency(calculate_total_balance(display_accounts))}
                  </span>
                </p>
              </div>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>

    <!-- Form Modal -->
    <%= if @show_form do %>
      <.live_component
        module={FormComponent}
        id="account-form"
        action={@form_action}
        account={@selected_account || %Account{}}
      />
    <% end %>
    """
  end

  # Context API integration helpers

  defp assign_dashboard_data(socket) do
    socket = assign(socket, :loading_dashboard, true)

    case Context.get_dashboard_data() do
      {:ok, data} ->
        socket
        |> assign(:user, data.user)
        |> assign(:accounts, data.accounts)
        |> assign(:summary, data.summary)
        |> assign(
          :filtered_accounts,
          get_filtered_accounts(data.accounts, socket.assigns.account_filter)
        )
        |> assign(:loading_dashboard, false)

      {:error, reason} ->
        socket
        |> put_flash(:error, format_error_message(reason))
        |> assign(:loading_dashboard, false)
        |> assign(:accounts, %{all: [], investment: [], cash: []})
        |> assign(:summary, %{
          total_balance: Decimal.new(0),
          investment_balance: Decimal.new(0),
          cash_balance: Decimal.new(0)
        })
    end
  end

  defp get_display_accounts(accounts, filter) when is_map(accounts) do
    case filter do
      :all -> accounts.all
      :investment -> accounts.investment
      :cash -> accounts.cash
      _ -> accounts.all
    end
  end

  defp get_display_accounts(accounts, _filter) when is_list(accounts), do: accounts

  defp get_filtered_accounts(accounts, filter) when is_map(accounts) do
    get_display_accounts(accounts, filter)
  end

  defp get_filtered_accounts(accounts, _filter) when is_list(accounts), do: accounts

  defp format_error_message(:user_not_found), do: "User not found"
  defp format_error_message(reason), do: "Failed to load dashboard data: #{inspect(reason)}"

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:show_form, false)
    |> assign(:selected_account, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:show_form, true)
    |> assign(:form_action, :new)
    |> assign(:selected_account, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    # Use Context API to get account with additional context data
    case Context.get_account_with_transactions(id, 1) do
      {:ok, account_data} ->
        socket
        |> assign(:show_form, true)
        |> assign(:form_action, :edit)
        |> assign(:selected_account, account_data.account)

      {:error, _reason} ->
        socket
        |> put_flash(:error, "Account not found")
        |> assign(:show_form, false)
        |> assign(:selected_account, nil)
    end
  end

  defp calculate_total_balance(accounts) do
    accounts
    |> Enum.filter(fn account -> !account.is_excluded end)
    |> Enum.reduce(Decimal.new(0), fn account, acc ->
      Decimal.add(acc, account.balance || Decimal.new(0))
    end)
  end
end
