defmodule AshfolioWeb.AccountLive.FormComponent do
  use AshfolioWeb, :live_component

  alias Ashfolio.Portfolio.Account
  alias AshfolioWeb.Live.{FormatHelpers, ErrorHelpers}

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
            disabled={@saving}
          >
            <span class="sr-only">Close</span>
            <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Form-level error display -->
        <div :if={@form_errors != []} class="mb-4">
          <ErrorHelpers.error_list errors={@form_errors} title="Please correct the following errors:" />
        </div>

        <!-- Network error display -->
        <div :if={@network_error} class="mb-4">
          <ErrorHelpers.warning_banner
            message={@network_error}
            title="Connection Issue"
          />
          <div class="mt-2 flex gap-2">
            <button
              type="button"
              phx-click="retry_save"
              phx-target={@myself}
              class="text-sm bg-yellow-100 hover:bg-yellow-200 text-yellow-800 px-3 py-1 rounded-md border border-yellow-300"
              disabled={@saving}
            >
              Retry
            </button>
            <button
              type="button"
              phx-click="clear_network_error"
              phx-target={@myself}
              class="text-sm bg-gray-100 hover:bg-gray-200 text-gray-800 px-3 py-1 rounded-md border border-gray-300"
            >
              Dismiss
            </button>
          </div>
        </div>

        <.simple_form
          for={@form}
          id="account-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <!-- Account Name Field with Enhanced Validation -->
          <div class="space-y-1">
            <.input
              field={@form[:name]}
              type="text"
              label="Account Name"
              required
              placeholder="e.g., Schwab Brokerage, Fidelity 401k"
              disabled={@saving}
            />
            <div :if={@validation_messages[:name]} class="text-xs text-blue-600">
              <.icon name="hero-information-circle-mini" class="h-3 w-3 inline mr-1" />
              {@validation_messages[:name]}
            </div>
          </div>

          <!-- Platform Field with Enhanced Validation -->
          <div class="space-y-1">
            <.input
              field={@form[:platform]}
              type="text"
              label="Platform"
              placeholder="e.g., Schwab, Fidelity, Vanguard"
              disabled={@saving}
            />
            <div :if={@validation_messages[:platform]} class="text-xs text-blue-600">
              <.icon name="hero-information-circle-mini" class="h-3 w-3 inline mr-1" />
              {@validation_messages[:platform]}
            </div>
          </div>

          <!-- Balance Field with Enhanced Validation -->
          <div class="space-y-2">
            <div class="space-y-1">
              <.input
                field={@form[:balance]}
                type="number"
                label="Current Balance"
                step="0.01"
                min="0"
                placeholder="0.00"
                disabled={@saving}
              />
              <div :if={@validation_messages[:balance]} class="text-xs text-blue-600">
                <.icon name="hero-information-circle-mini" class="h-3 w-3 inline mr-1" />
                {@validation_messages[:balance]}
              </div>
            </div>

            <div class="bg-blue-50 border border-blue-200 rounded-md p-3">
              <p class="text-sm text-blue-800">
                <.icon name="hero-information-circle" class="h-4 w-4 inline mr-1" />
                <span class="font-medium">Phase 1 Manual Entry:</span>
                Enter your current account balance manually. Future versions will calculate this automatically from transactions.
              </p>
              <%= if @action == :edit and @account.balance_updated_at do %>
                <p class="text-xs text-blue-600 mt-1">
                  Balance last updated: <%= FormatHelpers.format_relative_time(@account.balance_updated_at) %>
                </p>
              <% end %>
            </div>
          </div>

          <!-- Exclusion Checkbox with Enhanced Validation -->
          <div class="space-y-1">
            <.input
              field={@form[:is_excluded]}
              type="checkbox"
              label="Exclude from portfolio calculations"
              disabled={@saving}
            />
            <div :if={@validation_messages[:is_excluded]} class="text-xs text-blue-600">
              <.icon name="hero-information-circle-mini" class="h-3 w-3 inline mr-1" />
              {@validation_messages[:is_excluded]}
            </div>
            <p class="text-xs text-gray-500">
              Excluded accounts won't be included in portfolio totals and calculations.
            </p>
          </div>

          <:actions>
            <div class="w-full">
              <.button
                type="submit"
                disabled={@saving or not @form.valid?}
                class={"w-full relative #{(@saving or not @form.valid?) && "opacity-50 cursor-not-allowed"}"}
              >
                <%= if @saving do %>
                  <div class="flex items-center justify-center">
                    <svg class="animate-spin -ml-1 mr-3 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Saving...
                  </div>
                <% else %>
                  <%= if @action == :new, do: "Create Account", else: "Update Account" %>
                <% end %>
              </.button>

              <!-- Form validation status -->
              <div :if={not @form.valid? and @form.submitted?} class="mt-2 text-center">
                <p class="text-xs text-red-600">
                  <.icon name="hero-exclamation-triangle-mini" class="h-3 w-3 inline mr-1" />
                  Please fix the errors above before submitting
                </p>
              </div>

              <!-- Save shortcut hint -->
              <div :if={@form.valid? and not @saving} class="mt-2 text-center">
                <p class="text-xs text-gray-500">
                  Press <kbd class="px-1 py-0.5 text-xs font-mono bg-gray-100 border border-gray-300 rounded">Enter</kbd> to save
                </p>
              </div>
            </div>
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
     |> assign(:form, to_form(form))
     |> assign(:saving, false)
     |> assign(:form_errors, [])
     |> assign(:network_error, nil)
     |> assign(:validation_messages, %{})
     |> assign(:last_form_params, %{})}
  end

  @impl true
  def handle_event("validate", %{"form" => form_params}, socket) do
    # Clear network errors on new validation
    socket = assign(socket, :network_error, nil)

    # Validate balance format and precision
    form_params = validate_balance_input(form_params)
    form = AshPhoenix.Form.validate(socket.assigns.form, form_params)

    # Generate validation messages and form-level errors
    validation_messages = generate_validation_messages(form_params, form)
    form_errors = extract_form_errors(form)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:validation_messages, validation_messages)
     |> assign(:form_errors, form_errors)
     |> assign(:last_form_params, form_params)}
  end

  @impl true
  def handle_event("save", %{"form" => form_params}, socket) do
    # Set saving state and clear errors
    socket = socket
    |> assign(:saving, true)
    |> assign(:network_error, nil)
    |> assign(:form_errors, [])

    current_account_id = if socket.assigns.action == :edit, do: socket.assigns.account.id, else: nil

    case check_name_uniqueness(form_params, socket.assigns.user_id, current_account_id) do
      {:ok, _} ->
        save_account(socket, socket.assigns.action, form_params)
      {:error, error_message} ->
        {:noreply,
         socket
         |> assign(:saving, false)
         |> assign(:form_errors, [error_message])}
    end
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    notify_parent(:cancel)
    {:noreply, socket}
  end

  @impl true
  def handle_event("retry_save", _params, socket) do
    # Retry the last save attempt
    form_params = socket.assigns.last_form_params

    socket = socket
    |> assign(:saving, true)
    |> assign(:network_error, nil)
    |> assign(:form_errors, [])

    save_account(socket, socket.assigns.action, form_params)
  end

  @impl true
  def handle_event("clear_network_error", _params, socket) do
    {:noreply, assign(socket, :network_error, nil)}
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
        {:noreply, assign(socket, :saving, false)}

      {:error, form} ->
        form_errors = extract_form_errors(form)
        network_error = detect_network_error(form)

        {:noreply,
         socket
         |> assign(:form, form)
         |> assign(:saving, false)
         |> assign(:form_errors, form_errors)
         |> assign(:network_error, network_error)}
    end
  rescue
    error ->
      handle_save_exception(socket, error)
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
        {:noreply, assign(socket, :saving, false)}

      {:error, form} ->
        form_errors = extract_form_errors(form)
        network_error = detect_network_error(form)

        {:noreply,
         socket
         |> assign(:form, form)
         |> assign(:saving, false)
         |> assign(:form_errors, form_errors)
         |> assign(:network_error, network_error)}
    end
  rescue
    error ->
      handle_save_exception(socket, error)
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

  defp generate_validation_messages(form_params, _form) do
    messages = %{}

    # Name field validation messages
    messages = case Map.get(form_params, "name") do
      nil -> messages
      "" -> messages
      name when byte_size(name) < 2 ->
        Map.put(messages, :name, "Account name should be at least 2 characters long")
      name when byte_size(name) > 100 ->
        Map.put(messages, :name, "Account name should be less than 100 characters")
      name ->
        if String.match?(name, ~r/^[a-zA-Z0-9\s\-_]+$/) do
          Map.put(messages, :name, "Good! Account name looks valid")
        else
          Map.put(messages, :name, "Use only letters, numbers, spaces, hyphens, and underscores")
        end
    end

    # Platform field validation messages
    messages = case Map.get(form_params, "platform") do
      nil -> messages
      "" -> messages
      platform when byte_size(platform) > 50 ->
        Map.put(messages, :platform, "Platform name should be less than 50 characters")
      platform ->
        common_platforms = ["Schwab", "Fidelity", "Vanguard", "TD Ameritrade", "E*TRADE", "Robinhood", "Interactive Brokers"]
        if Enum.any?(common_platforms, &String.contains?(String.downcase(platform), String.downcase(&1))) do
          Map.put(messages, :platform, "Great! We recognize this platform")
        else
          Map.put(messages, :platform, "Platform name looks good")
        end
    end

    # Balance field validation messages
    messages = case Map.get(form_params, "balance") do
      nil -> messages
      "" -> messages
      balance_string ->
        case Float.parse(balance_string) do
          {balance, ""} when balance < 0 ->
            Map.put(messages, :balance, "Balance cannot be negative")
          {balance, ""} when balance > 10_000_000 ->
            Map.put(messages, :balance, "That's a lot! Please verify this amount is correct")
          {balance, ""} when balance > 0 ->
            formatted = FormatHelpers.format_currency(Decimal.new(balance))
            Map.put(messages, :balance, "Balance will be set to #{formatted}")
          {+0.0, ""} ->
            Map.put(messages, :balance, "Account will be created with zero balance")
          _ ->
            Map.put(messages, :balance, "Please enter a valid number (e.g., 1000.50)")
        end
    end

    # Exclusion field validation messages
    messages = case Map.get(form_params, "is_excluded") do
      "true" ->
        Map.put(messages, :is_excluded, "This account will be excluded from portfolio calculations")
      _ ->
        Map.put(messages, :is_excluded, "This account will be included in portfolio calculations")
    end

    messages
  end

  defp extract_form_errors(form) do
    case form.errors do
      [] -> []
      errors ->
        errors
        |> Enum.map(fn {field, {message, _opts}} ->
          field_name = humanize_field(field)
          "#{field_name}: #{message}"
        end)
        |> Enum.uniq()
    end
  end

  defp detect_network_error(form) do
    # Check if the error might be network-related
    error_messages = extract_form_errors(form)

    network_indicators = [
      "timeout", "connection", "network", "unreachable",
      "dns", "socket", "refused", "unavailable"
    ]

    if Enum.any?(error_messages, fn msg ->
      Enum.any?(network_indicators, &String.contains?(String.downcase(msg), &1))
    end) do
      "Unable to save due to a connection issue. Please check your internet connection and try again."
    else
      nil
    end
  end

  defp handle_save_exception(socket, error) do
    error_message = case error do
      %{message: msg} when is_binary(msg) -> msg
      _ -> "An unexpected error occurred while saving the account"
    end

    network_error = if String.contains?(String.downcase(error_message), "timeout") or
                       String.contains?(String.downcase(error_message), "connection") do
      "Connection timeout occurred. Please try again."
    else
      "System error occurred. Please try again or contact support if the problem persists."
    end

    {:noreply,
     socket
     |> assign(:saving, false)
     |> assign(:network_error, network_error)
     |> assign(:form_errors, [error_message])}
  end

  defp humanize_field(field) when is_atom(field) do
    field
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp humanize_field(field), do: to_string(field)

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp check_name_uniqueness(form_params, user_id, current_account_id) do
    name = Map.get(form_params, "name")
    return_value = {:ok, form_params}

    if name do
      existing_account = Account.get_by_name_for_user(user_id, name)

      if existing_account && existing_account.id != current_account_id do
        _return_value = {:error, "Account name '#{name}' is already taken. Please choose another."}
      end
    end

    return_value
  end
end