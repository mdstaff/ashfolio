defmodule AshfolioWeb.AccountLive.Index do
  use AshfolioWeb, :live_view

  alias Ashfolio.Portfolio.{Account, User, Transaction}
  alias AshfolioWeb.Live.{FormatHelpers, ErrorHelpers}
  alias AshfolioWeb.AccountLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    user_id = get_default_user_id()

    {:ok,
     socket
     |> assign_current_page(:accounts)
     |> assign(:page_title, "Investment Accounts")
     |> assign(:page_subtitle, "Manage your investment accounts and balances")
     |> assign(:user_id, user_id)
     |> assign(:accounts, list_accounts(user_id))
     |> assign(:show_form, false)
     |> assign(:form_action, :new)
     |> assign(:selected_account, nil)
     |> assign(:toggling_account_id, nil)
     |> assign(:deleting_account_id, nil)}
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
  def handle_event("edit_account", %{"id" => id}, socket) do
    account = Enum.find(socket.assigns.accounts, &(&1.id == id))

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

            {:noreply,
             socket
             |> ErrorHelpers.put_success_flash("Account deleted successfully")
             |> assign(:accounts, list_accounts(socket.assigns.user_id))
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
      original_accounts = socket.assigns.accounts
      account_index = Enum.find_index(original_accounts, &(&1.id == id))

      case account_index do
        nil ->
          {:noreply,
           socket
           |> ErrorHelpers.put_error_flash(:not_found, "Account not found")}

        _ ->
          account = Enum.at(original_accounts, account_index)

          # Optimistically update the UI
          updated_account = %{account | is_excluded: !account.is_excluded}
          updated_accounts = List.replace_at(original_accounts, account_index, updated_account)

          socket =
            socket
            |> assign(:accounts, updated_accounts)
            |> assign(:toggling_account_id, id)

          case Account.toggle_exclusion(account, %{is_excluded: !account.is_excluded}) do
            {:ok, updated_account_from_db} ->
              Ashfolio.PubSub.broadcast!("accounts", {:account_updated, updated_account_from_db})

              # Reload accounts to ensure consistency
              user_id = socket.assigns.user_id
              accounts = list_accounts(user_id)
              socket =
                socket
                |> assign(:toggling_account_id, nil)
                |> assign(:accounts, accounts)
                |> ErrorHelpers.put_success_flash("Account exclusion updated successfully")

              {:noreply, socket}

            {:error, reason} ->
              # Revert the optimistic update on failure
              {:noreply,
               socket
               |> assign(:accounts, original_accounts)
               |> assign(:toggling_account_id, nil)
               |> ErrorHelpers.put_error_flash(reason, "Failed to update account exclusion")}
          end
      end
    end
  end

  @impl true
  def handle_info({FormComponent, {:saved, _account}}, socket) do
    {:noreply,
     socket
     |> ErrorHelpers.put_success_flash("Account saved successfully")
     |> assign(:show_form, false)
     |> assign(:accounts, list_accounts(socket.assigns.user_id))}
  end

  @impl true
  def handle_info({FormComponent, {:saved, account, message}}, socket) do
    Ashfolio.PubSub.broadcast!("accounts", {:account_saved, account})

    {:noreply,
     socket
     |> ErrorHelpers.put_success_flash(message)
     |> assign(:show_form, false)
     |> assign(:accounts, list_accounts(socket.assigns.user_id))}
  end

  @impl true
  def handle_info({FormComponent, :cancel}, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header with New Account Button -->
      <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Investment Accounts</h1>
          <p class="text-gray-600">Manage your investment accounts and balances</p>
        </div>
        <.button phx-click="new_account" class="btn-primary inline-flex items-center">
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          New Account
        </.button>
      </div>

    <!-- Accounts Table or Empty State -->
      <%= if Enum.empty?(@accounts) do %>
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
            <.table id="accounts-table" rows={@accounts} class="min-w-full">
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
                      <p>Updated {FormatHelpers.format_relative_time(account.balance_updated_at)}</p>
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
                    class="btn-secondary text-xs sm:text-sm px-2 sm:px-3 py-1 inline-flex items-center"
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
                {length(@accounts)} account{if length(@accounts) == 1, do: "", else: "s"} total
              </p>
              <p class="text-sm font-medium text-gray-900">
                Total Balance:
                <span class="font-mono">
                  {FormatHelpers.format_currency(calculate_total_balance(@accounts))}
                </span>
              </p>
            </div>
          </div>
        </div>
      <% end %>
    </div>

    <!-- Form Modal -->
    <%= if @show_form do %>
      <.live_component
        module={FormComponent}
        id="account-form"
        action={@form_action}
        account={@selected_account || %Account{}}
        user_id={@user_id}
      />
    <% end %>
    """
  end

  # Defensive user creation for single-user application
  defp get_default_user_id do
    case User.get_default_user() do
      {:ok, [user]} -> user.id
      {:ok, []} ->
        create_user_with_retry()
    end
  end

  # SQLite retry helper for user creation
  defp create_user_with_retry(max_attempts \\ 3, delay_ms \\ 100) do
    do_create_user_with_retry(max_attempts, delay_ms, 1)
  end

  defp do_create_user_with_retry(max_attempts, delay_ms, attempt) do
    case User.create(%{name: "Local User", currency: "USD", locale: "en-US"}) do
      {:ok, user} -> user.id
      {:error, error} ->
        if sqlite_busy_error?(error) and attempt < max_attempts do
          # Exponential backoff with jitter
          sleep_time = delay_ms * attempt + :rand.uniform(50)
          Process.sleep(sleep_time)
          do_create_user_with_retry(max_attempts, delay_ms, attempt + 1)
        else
          # If it's still failing, maybe the user was created by another process
          case User.get_default_user() do
            {:ok, [user]} -> user.id
            _ -> raise "Failed to create or retrieve default user: #{inspect(error)}"
          end
        end
    end
  end

  defp sqlite_busy_error?(%Ash.Error.Unknown{errors: errors}) do
    Enum.any?(errors, fn
      %Ash.Error.Unknown.UnknownError{error: error} when is_binary(error) ->
        String.contains?(error, "Database busy")
      _ -> false
    end)
  end

  defp sqlite_busy_error?(_), do: false



  defp list_accounts(user_id) do
    Account.accounts_for_user!(user_id)
  end

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
    account = Account.get_by_id!(id)

    socket
    |> assign(:show_form, true)
    |> assign(:form_action, :edit)
    |> assign(:selected_account, account)
  end

  defp calculate_total_balance(accounts) do
    accounts
    |> Enum.filter(fn account -> !account.is_excluded end)
    |> Enum.reduce(Decimal.new(0), fn account, acc ->
      Decimal.add(acc, account.balance || Decimal.new(0))
    end)
  end
end
