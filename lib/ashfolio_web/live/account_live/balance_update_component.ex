defmodule AshfolioWeb.AccountLive.BalanceUpdateComponent do
  use AshfolioWeb, :live_component

  alias Ashfolio.Context
  alias AshfolioWeb.Live.{FormatHelpers, ErrorHelpers}

  @impl true
  def render(assigns) do
    ~H"""
    <div id="balance-update-modal" class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
      <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-medium text-gray-900">
            Update Cash Balance
          </h3>
          <button
            type="button"
            phx-click="cancel"
            phx-target={@myself}
            class="text-gray-400 hover:text-gray-600"
            disabled={@updating}
          >
            <span class="sr-only">Close</span>
            <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

    <!-- Account Info -->
        <div class="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-md">
          <div class="flex items-center space-x-3">
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
            <div>
              <p class="font-medium text-blue-900">{@account.name}</p>
              <p class="text-sm text-blue-600">
                {String.capitalize(to_string(@account.account_type))} Account
              </p>
            </div>
          </div>
        </div>

    <!-- Current Balance Display -->
        <div class="mb-6 p-4 bg-gray-50 border border-gray-200 rounded-md">
          <div class="text-center">
            <p class="text-sm font-medium text-gray-500 mb-1">Current Balance</p>
            <p class="text-2xl font-bold text-gray-900">
              {FormatHelpers.format_currency(@account.balance)}
            </p>
            <%= if @account.balance_updated_at do %>
              <p class="text-xs text-gray-500 mt-1">
                Last updated {FormatHelpers.format_relative_time(@account.balance_updated_at)}
              </p>
            <% end %>
          </div>
        </div>

    <!-- Error display -->
        <div :if={@error_message} class="mb-4">
          <ErrorHelpers.error_list errors={[@error_message]} title="Validation Error:" />
        </div>

    <!-- Update Form -->
        <.simple_form
          for={@form}
          id="balance-update-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="update_balance"
        >
          <!-- New Balance Field -->
          <div class="space-y-2">
            <.input
              field={@form[:new_balance]}
              type="number"
              label="New Balance"
              step="0.01"
              min={if @account.account_type in [:checking, :savings], do: "0", else: nil}
              placeholder="0.00"
              disabled={@updating}
              required
            />

    <!-- Balance Change Preview -->
            <%= if @form_params["new_balance"] && @form_params["new_balance"] != "" do %>
              <%= case Float.parse(@form_params["new_balance"]) do %>
                <% {new_balance_float, _} -> %>
                  <% new_balance_decimal = Decimal.new(to_string(new_balance_float)) %>
                  <% current_balance = @account.balance || Decimal.new(0) %>
                  <% change = Decimal.sub(new_balance_decimal, current_balance) %>
                  <% is_increase = Decimal.positive?(change) %>

                  <div class="bg-blue-50 border border-blue-200 rounded-md p-3">
                    <div class="flex items-center justify-between">
                      <span class="text-sm text-blue-800">Balance Change:</span>
                      <span class={"text-sm font-medium #{if is_increase, do: "text-green-600", else: "text-red-600"}"}>
                        {if is_increase, do: "+", else: ""}{FormatHelpers.format_currency(change)}
                      </span>
                    </div>
                    <div class="flex items-center justify-between mt-1">
                      <span class="text-sm text-blue-800">New Balance:</span>
                      <span class="text-sm font-bold text-blue-900">
                        {FormatHelpers.format_currency(new_balance_decimal)}
                      </span>
                    </div>
                  </div>
                <% _ -> %>
                  <!-- Invalid number format, don't show preview -->
              <% end %>
            <% end %>
          </div>

    <!-- Notes Field -->
          <div class="space-y-1">
            <.input
              field={@form[:notes]}
              type="textarea"
              label="Notes (Optional)"
              placeholder="e.g., Monthly deposit, ATM withdrawal, etc."
              disabled={@updating}
              rows="3"
            />
            <p class="text-xs text-gray-500">
              Add a note to help track why this balance was updated.
            </p>
          </div>

          <:actions>
            <div class="w-full space-y-3">
              <.button
                type="submit"
                disabled={@updating || !@form_valid}
                class={"w-full relative #{(@updating || !@form_valid) && "opacity-50 cursor-not-allowed"}"}
              >
                <%= if @updating do %>
                  <div class="flex items-center justify-center">
                    <svg
                      class="animate-spin -ml-1 mr-3 h-4 w-4 text-white"
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
                      />
                      <path
                        class="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      />
                    </svg>
                    Updating Balance...
                  </div>
                <% else %>
                  Update Balance
                <% end %>
              </.button>

              <button
                type="button"
                phx-click="cancel"
                phx-target={@myself}
                class="w-full btn-secondary"
                disabled={@updating}
              >
                Cancel
              </button>
            </div>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{account: _account} = assigns, socket) do
    form = to_form(%{"new_balance" => "", "notes" => ""})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, form)
     |> assign(:form_params, %{})
     |> assign(:form_valid, false)
     |> assign(:updating, false)
     |> assign(:error_message, nil)}
  end

  @impl true
  def handle_event("validate", %{"new_balance" => new_balance, "notes" => notes}, socket) do
    form_params = %{"new_balance" => new_balance, "notes" => notes}
    form = to_form(form_params)

    # Validate the new balance
    {form_valid, error_message} = validate_balance(new_balance, socket.assigns.account)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:form_params, form_params)
     |> assign(:form_valid, form_valid)
     |> assign(:error_message, error_message)}
  end

  @impl true
  def handle_event(
        "update_balance",
        %{"new_balance" => new_balance_str, "notes" => notes},
        socket
      ) do
    # Set updating state
    socket = assign(socket, :updating, true)

    case parse_and_validate_balance(new_balance_str, socket.assigns.account) do
      {:ok, new_balance} ->
        notes = if String.trim(notes) == "", do: nil, else: String.trim(notes)

        case Context.update_cash_balance(socket.assigns.account.id, new_balance, notes) do
          {:ok, updated_account} ->
            notify_parent({:balance_updated, updated_account, new_balance, notes})
            {:noreply, assign(socket, :updating, false)}

          {:error, :not_cash_account} ->
            {:noreply,
             socket
             |> assign(:updating, false)
             |> assign(:error_message, "Balance updates are only available for cash accounts")}

          {:error, :account_not_found} ->
            {:noreply,
             socket
             |> assign(:updating, false)
             |> assign(:error_message, "Account not found")}

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:updating, false)
             |> assign(:error_message, "Failed to update balance: #{inspect(reason)}")}
        end

      {:error, error_message} ->
        {:noreply,
         socket
         |> assign(:updating, false)
         |> assign(:error_message, error_message)}
    end
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    notify_parent(:cancel)
    {:noreply, socket}
  end

  # Private helper functions

  defp validate_balance(balance_str, account) do
    case parse_and_validate_balance(balance_str, account) do
      {:ok, _balance} -> {true, nil}
      {:error, error_message} -> {false, error_message}
    end
  end

  defp parse_and_validate_balance(balance_str, account) do
    case String.trim(balance_str) do
      "" ->
        {:error, "Balance is required"}

      trimmed_balance ->
        case Float.parse(trimmed_balance) do
          {balance_float, ""} ->
            new_balance = Decimal.new(to_string(balance_float))

            # Validate non-negative for savings/checking accounts
            if account.account_type in [:checking, :savings] && Decimal.negative?(new_balance) do
              {:error,
               "#{String.capitalize(to_string(account.account_type))} accounts cannot have negative balances"}
            else
              {:ok, new_balance}
            end

          _ ->
            {:error, "Please enter a valid number"}
        end
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
