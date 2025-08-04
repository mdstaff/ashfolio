defmodule AshfolioWeb.AccountLive.Index do
  use AshfolioWeb, :live_view

  alias Ashfolio.Portfolio.{Account, User}
  alias AshfolioWeb.Live.FormatHelpers
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
     |> assign(:selected_account, nil)}
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
    case Account.destroy(id) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Account deleted successfully")
         |> assign(:accounts, list_accounts(socket.assigns.user_id))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete account: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("toggle_exclusion", %{"id" => id}, socket) do
    account = Enum.find(socket.assigns.accounts, &(&1.id == id))

    case Account.toggle_exclusion(account, %{is_excluded: !account.is_excluded}) do
      {:ok, _updated_account} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account exclusion updated")
         |> assign(:accounts, list_accounts(socket.assigns.user_id))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to update account: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_info({FormComponent, {:saved, _account}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Account saved successfully")
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
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Investment Accounts</h1>
          <p class="text-gray-600">Manage your investment accounts and balances</p>
        </div>
        <.button phx-click="new_account" class="bg-blue-600 hover:bg-blue-700">
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          New Account
        </.button>
      </div>

      <!-- Accounts Table -->
      <%= if Enum.empty?(@accounts) do %>
        <div class="text-center py-12">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No accounts</h3>
          <p class="mt-1 text-sm text-gray-500">Get started by creating your first investment account.</p>
          <div class="mt-6">
            <.button phx-click="new_account" class="bg-blue-600 hover:bg-blue-700">
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              New Account
            </.button>
          </div>
        </div>
      <% else %>
        <div class="bg-white shadow rounded-lg overflow-hidden">
          <.table id="accounts-table" rows={@accounts}>
            <:col :let={account} label="Account">
              <div class="flex items-center">
                <div>
                  <div class="font-medium text-gray-900">{account.name}</div>
                  <div class="text-sm text-gray-500">{account.platform || "No platform"}</div>
                </div>
                <%= if account.is_excluded do %>
                  <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                    Excluded
                  </span>
                <% end %>
              </div>
            </:col>

            <:col :let={account} label="Balance">
              <div class="text-right">
                <span class="font-medium text-gray-900">
                  {FormatHelpers.format_currency(account.balance)}
                </span>
              </div>
            </:col>

            <:col :let={account} label="Actions">
              <div class="flex justify-end space-x-2">
                <.button
                  class="text-sm px-3 py-1 bg-gray-100 hover:bg-gray-200 text-gray-700"
                  phx-click="edit_account"
                  phx-value-id={account.id}
                >
                  Edit
                </.button>

                <.button
                  class="text-sm px-3 py-1 bg-gray-100 hover:bg-gray-200 text-gray-700"
                  phx-click="toggle_exclusion"
                  phx-value-id={account.id}
                >
                  <%= if account.is_excluded, do: "Include", else: "Exclude" %>
                </.button>

                <.button
                  class="text-sm px-3 py-1 bg-red-100 hover:bg-red-200 text-red-700"
                  phx-click="delete_account"
                  phx-value-id={account.id}
                  data-confirm="Are you sure you want to delete this account?"
                >
                  Delete
                </.button>
              </div>
            </:col>
          </.table>
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

  defp get_default_user_id do
    case User.get_default_user!() do
      [user] -> user.id
      [] ->
        # Create default user if none exists
        {:ok, user} = User.create(%{name: "Local User", currency: "USD", locale: "en-US"})
        user.id
    end
  end

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
end
