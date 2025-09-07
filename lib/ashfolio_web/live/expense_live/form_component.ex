defmodule AshfolioWeb.ExpenseLive.FormComponent do
  @moduledoc false
  use AshfolioWeb, :live_component

  alias Ash.Error.Invalid
  alias Ashfolio.FinancialManagement.Expense
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Portfolio.Account
  alias AshfolioWeb.FormHelpers
  alias AshfolioWeb.Live.ErrorHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
      <div class="bg-white rounded-lg shadow-xl max-w-lg w-full max-h-[90vh] flex flex-col">
        <!-- Fixed Header -->
        <div class="flex justify-between items-center p-6 pb-4 border-b border-gray-200">
          <h3 class="text-lg font-medium text-gray-900">
            {if @action == :new, do: "Add Expense", else: "Edit Expense"}
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
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>
        
    <!-- Scrollable Content Area -->
        <div class="flex-1 overflow-y-auto px-6 py-4">
          <!-- Form-level error display -->
          <div :if={@form_errors != []} class="mb-4">
            <ErrorHelpers.error_list
              errors={@form_errors}
              title="Please correct the following errors:"
            />
          </div>

          <.simple_form
            for={@form}
            id="expense-form"
            phx-target={@myself}
            phx-change="validate"
            phx-submit="save"
          >
            <!-- Description Field -->
            <.input
              field={@form[:description]}
              type="text"
              label="Description"
              required
              placeholder="e.g., Weekly groceries, Gas station"
              disabled={@saving}
            />
            
    <!-- Amount Field -->
            <.input
              field={@form[:amount]}
              type="number"
              label="Amount"
              required
              step="0.01"
              min="0.01"
              placeholder="0.00"
              disabled={@saving}
            />
            
    <!-- Date Field -->
            <.input
              field={@form[:date]}
              type="date"
              label="Date"
              required
              disabled={@saving}
            />
            
    <!-- Merchant Field -->
            <.input
              field={@form[:merchant]}
              type="text"
              label="Merchant"
              placeholder="e.g., Whole Foods, Shell"
              disabled={@saving}
            />
            
    <!-- Category Dropdown -->
            <.input
              field={@form[:category_id]}
              type="select"
              label="Category"
              prompt="Select a category"
              options={@categories}
              disabled={@saving}
            />
            
    <!-- Account Dropdown -->
            <.input
              field={@form[:account_id]}
              type="select"
              label="Account"
              prompt="Select an account"
              options={@accounts}
              disabled={@saving}
            />
            
    <!-- Notes Field -->
            <.input
              field={@form[:notes]}
              type="textarea"
              label="Notes"
              placeholder="Additional details (optional)"
              disabled={@saving}
            />
          </.simple_form>
        </div>
        
    <!-- Fixed Footer -->
        <div class="border-t border-gray-200 px-6 py-4">
          <div class="flex justify-end space-x-3">
            <button
              type="button"
              phx-click="cancel"
              phx-target={@myself}
              class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              disabled={@saving}
            >
              Cancel
            </button>
            <button
              type="submit"
              form="expense-form"
              disabled={@saving || !@form_valid}
              class={[
                "px-4 py-2 text-sm font-medium rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500",
                if(@saving || !@form_valid,
                  do: "text-gray-400 bg-gray-100 cursor-not-allowed",
                  else: "text-white bg-blue-600 hover:bg-blue-700"
                )
              ]}
            >
              <%= if @saving do %>
                <svg
                  class="animate-spin -ml-1 mr-2 h-4 w-4 text-gray-400 inline"
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
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 714 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  >
                  </path>
                </svg>
                {if @action == :new, do: "Creating...", else: "Updating..."}
              <% else %>
                Save Expense
              <% end %>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{action: action, expense: expense} = assigns, socket) do
    form_data = prepare_form_data(action, expense)
    form = to_form(form_data)

    # Load categories and accounts for dropdowns
    categories = load_categories()
    accounts = load_accounts()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, form)
     |> assign(:form_data, form_data)
     |> assign(:form_valid, action == :edit)
     |> assign(:form_errors, [])
     |> assign(:saving, false)
     |> assign(:categories, categories)
     |> assign(:accounts, accounts)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    expense_params = params

    form_data = %{
      "description" => expense_params["description"] || "",
      "amount" => expense_params["amount"] || "",
      "date" => expense_params["date"] || "",
      "merchant" => expense_params["merchant"] || "",
      "notes" => expense_params["notes"] || "",
      "category_id" => expense_params["category_id"] || "",
      "account_id" => expense_params["account_id"] || ""
    }

    # Validate the form
    {form_valid, form_errors} = validate_expense_form(form_data)

    form = to_form(form_data)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:form_data, form_data)
     |> assign(:form_valid, form_valid)
     |> assign(:form_errors, form_errors)}
  end

  @impl true
  def handle_event("save", expense_params, socket) do
    socket = assign(socket, :saving, true)
    form_data = sanitize_expense_params(expense_params)
    {form_valid, form_errors} = validate_expense_form(form_data)

    if form_valid do
      handle_valid_save(socket, form_data)
    else
      handle_invalid_save(socket, form_errors)
    end
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    notify_parent(:cancelled)
    {:noreply, socket}
  end

  defp sanitize_expense_params(params) do
    %{
      "description" => sanitize_string(params["description"]),
      "amount" => sanitize_string(params["amount"]),
      "date" => params["date"] || "",
      "merchant" => sanitize_string(params["merchant"]),
      "notes" => sanitize_string(params["notes"]),
      "category_id" => params["category_id"] || "",
      "account_id" => params["account_id"] || ""
    }
  end

  defp sanitize_string(value), do: String.trim(value || "")

  defp handle_valid_save(socket, form_data) do
    case socket.assigns.action do
      :new -> create_expense(socket, form_data)
      :edit -> update_expense(socket, form_data)
    end
  end

  defp handle_invalid_save(socket, form_errors) do
    {:noreply,
     socket
     |> assign(:saving, false)
     |> assign(:form_errors, form_errors)}
  end

  # Private functions

  defp prepare_form_data(action, expense) do
    case {action, expense} do
      {:new, _} -> default_form_data()
      {:edit, expense} when not is_nil(expense) -> expense_to_form_data(expense)
      _ -> default_form_data()
    end
  end

  defp default_form_data do
    %{
      "description" => "",
      "amount" => "",
      "date" => Date.to_iso8601(Date.utc_today()),
      "merchant" => "",
      "notes" => "",
      "category_id" => "",
      "account_id" => ""
    }
  end

  defp expense_to_form_data(expense) do
    %{
      "description" => expense.description || "",
      "amount" => if(expense.amount, do: Decimal.to_string(expense.amount), else: ""),
      "date" => if(expense.date, do: Date.to_iso8601(expense.date), else: ""),
      "merchant" => expense.merchant || "",
      "notes" => expense.notes || "",
      "category_id" => expense.category_id || "",
      "account_id" => expense.account_id || ""
    }
  end

  defp create_expense(socket, form_data) do
    expense_params = build_expense_params(form_data)

    case Expense.create(expense_params) do
      {:ok, expense} ->
        notify_parent({:saved, expense})
        {:noreply, assign(socket, :saving, false)}

      {:error, %Invalid{} = error} ->
        errors = extract_ash_errors(error)

        {:noreply,
         socket
         |> assign(:saving, false)
         |> assign(:form_errors, errors)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:saving, false)
         |> assign(:form_errors, ["Failed to create expense: #{inspect(reason)}"])}
    end
  end

  defp update_expense(socket, form_data) do
    expense_params = build_expense_params(form_data)

    case Expense.update(socket.assigns.expense, expense_params) do
      {:ok, expense} ->
        notify_parent({:saved, expense})
        {:noreply, assign(socket, :saving, false)}

      {:error, %Invalid{} = error} ->
        errors = extract_ash_errors(error)

        {:noreply,
         socket
         |> assign(:saving, false)
         |> assign(:form_errors, errors)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:saving, false)
         |> assign(:form_errors, ["Failed to update expense: #{inspect(reason)}"])}
    end
  end

  defp build_expense_params(form_data) do
    %{
      description: form_data["description"],
      amount: FormHelpers.parse_decimal_unsafe(form_data["amount"]),
      date: FormHelpers.parse_date_unsafe(form_data["date"]),
      merchant: FormHelpers.empty_to_nil(form_data["merchant"]),
      notes: FormHelpers.empty_to_nil(form_data["notes"]),
      category_id: FormHelpers.empty_to_nil(form_data["category_id"]),
      account_id: FormHelpers.empty_to_nil(form_data["account_id"])
    }
  end

  defp validate_expense_form(form_data) do
    errors = []
    errors = validate_description(form_data["description"], errors)
    errors = validate_amount(form_data["amount"], errors)
    errors = validate_date(form_data["date"], errors)

    form_valid = errors == []
    {form_valid, Enum.reverse(errors)}
  end

  defp load_categories do
    TransactionCategory
    |> Ash.Query.for_read(:read)
    |> Ash.Query.sort(:name)
    |> Ash.read!()
    |> Enum.map(&{&1.name, &1.id})
  end

  defp load_accounts do
    Account
    |> Ash.Query.for_read(:read)
    |> Ash.Query.sort(:name)
    |> Ash.read!()
    |> Enum.map(&{&1.name, &1.id})
  end

  # Validation helper functions

  defp validate_description(description, errors) do
    case String.trim(description) do
      "" -> ["Description can't be blank" | errors]
      _ -> errors
    end
  end

  defp validate_amount(amount_str, errors) do
    case String.trim(amount_str) do
      "" -> ["Amount can't be blank" | errors]
      trimmed_amount -> validate_amount_value(trimmed_amount, errors)
    end
  end

  defp validate_amount_value(amount_str, errors) do
    case FormHelpers.parse_decimal(amount_str) do
      {:ok, nil} -> ["Amount must be a valid number" | errors]
      {:ok, amount} -> validate_amount_positive(amount, errors)
      {:error, _} -> ["Amount must be a valid number" | errors]
    end
  end

  defp validate_amount_positive(amount, errors) do
    if Decimal.compare(amount, Decimal.new("0")) == :gt do
      errors
    else
      ["Amount must be greater than 0" | errors]
    end
  end

  defp validate_date(date_str, errors) do
    case date_str do
      "" -> ["Date can't be blank" | errors]
      date -> validate_date_format(date, errors)
    end
  end

  defp validate_date_format(date_str, errors) do
    case FormHelpers.parse_date(date_str) do
      {:ok, _} -> errors
      {:error, _} -> ["Date must be valid" | errors]
    end
  end

  # Parsing functions removed - now using FormHelpers module for:
  # - parse_decimal/1 -> FormHelpers.parse_decimal/1 or parse_decimal_unsafe/1
  # - parse_date/1 -> FormHelpers.parse_date/1 or parse_date_unsafe/1
  # - empty_to_nil/1 -> FormHelpers.empty_to_nil/1

  defp extract_ash_errors(%Invalid{errors: errors}) do
    Enum.map(errors, fn
      %{message: message} -> message
      error -> inspect(error)
    end)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
