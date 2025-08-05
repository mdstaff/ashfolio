defmodule AshfolioWeb.AccountLive.FormComponent do
  use AshfolioWeb, :live_component

  alias Ashfolio.Portfolio.Account
  alias AshfolioWeb.Live.FormatHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
      <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-medium text-gray-900">
            <%= if @action == :new, do: "New Account", else: "Edit Account" %>
          </h3>
          <button
            type="button"
            phx-click="cancel"
            phx-target={@myself}
            class="text-gray-400 hover:text-gray-600"
          >
            <span class="sr-only">Close</span>
            <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <.simple_form
          for={@form}
          id="account-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <.input field={@form[:name]} type="text" label="Account Name" required />
          <.input field={@form[:platform]} type="text" label="Platform" placeholder="e.g., Schwab, Fidelity" />

          <div class="space-y-2">
            <.input
              field={@form[:balance]}
              type="number"
              label="Current Balance"
              step="0.01"
              min="0"
              placeholder="0.00"
            />
            <p class="text-sm text-gray-600">
              <span class="font-medium">Phase 1 Manual Entry:</span>
              Enter your current account balance manually. Future versions will calculate this automatically from transactions.
            </p>
            <%= if @action == :edit and @account.balance_updated_at do %>
              <p class="text-xs text-gray-500">
                Balance last updated: <%= FormatHelpers.format_relative_time(@account.balance_updated_at) %>
              </p>
            <% end %>
          </div>

          <.input field={@form[:is_excluded]} type="checkbox" label="Exclude from portfolio calculations" />

          <:actions>
            <.button phx-disable-with="Saving..." class="w-full">
              <%= if @action == :new, do: "Create Account", else: "Update Account" %>
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{account: _account} = assigns, socket) do
    form = case assigns.action do
      :new ->
        AshPhoenix.Form.for_create(Account, :create)
      :edit ->
        AshPhoenix.Form.for_update(assigns.account, :update)
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(form))}
  end

  @impl true
  def handle_event("validate", %{"form" => form_params}, socket) do
    # Validate balance format and precision
    form_params = validate_balance_input(form_params)
    form = AshPhoenix.Form.validate(socket.assigns.form, form_params)
    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("save", %{"form" => form_params}, socket) do
    save_account(socket, socket.assigns.action, form_params)
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    notify_parent(:cancel)
    {:noreply, socket}
  end

  defp save_account(socket, :new, form_params) do
    form_params = Map.put(form_params, "user_id", socket.assigns.user_id)

    case AshPhoenix.Form.submit(socket.assigns.form, params: form_params) do
      {:ok, account} ->
        success_message = if Map.get(form_params, "balance") && form_params["balance"] != "" do
          "Account created successfully with balance of #{FormatHelpers.format_currency(account.balance)}"
        else
          "Account created successfully"
        end
        notify_parent({:saved, account, success_message})
        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp save_account(socket, :edit, form_params) do
    old_balance = socket.assigns.account.balance

    case AshPhoenix.Form.submit(socket.assigns.form, params: form_params) do
      {:ok, account} ->
        success_message = if Map.get(form_params, "balance") &&
                             form_params["balance"] != "" &&
                             !Decimal.equal?(old_balance, account.balance) do
          "Account updated successfully. Balance changed to #{FormatHelpers.format_currency(account.balance)}"
        else
          "Account updated successfully"
        end
        notify_parent({:saved, account, success_message})
        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end



  defp validate_balance_input(form_params) do
    case Map.get(form_params, "balance") do
      nil -> form_params
      "" -> form_params
      balance_string ->
        # Ensure balance has proper decimal formatting
        case Float.parse(balance_string) do
          {balance_float, ""} ->
            # Format to 2 decimal places
            formatted_balance = :erlang.float_to_binary(balance_float, decimals: 2)
            Map.put(form_params, "balance", formatted_balance)
          _ ->
            form_params
        end
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
