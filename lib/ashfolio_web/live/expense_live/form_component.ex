defmodule AshfolioWeb.ExpenseLive.FormComponent do
  @moduledoc false
  use AshfolioWeb, :live_component

  alias Ash.Error.Invalid
  alias Ashfolio.FinancialManagement.Expense
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Portfolio.Account
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
    # Prepare initial data
    form_data =
      case {action, expense} do
        {:new, _} ->
          %{
            "description" => "",
            "amount" => "",
            "date" => Date.to_iso8601(Date.utc_today()),
            "merchant" => "",
            "notes" => "",
            "category_id" => "",
            "account_id" => ""
          }

        {:edit, expense} when not is_nil(expense) ->
          %{
            "description" => expense.description || "",
            "amount" => if(expense.amount, do: Decimal.to_string(expense.amount), else: ""),
            "date" => if(expense.date, do: Date.to_iso8601(expense.date), else: ""),
            "merchant" => expense.merchant || "",
            "notes" => expense.notes || "",
            "category_id" => expense.category_id || "",
            "account_id" => expense.account_id || ""
          }

        _ ->
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

    form_data = %{
      "description" => String.trim(expense_params["description"] || ""),
      "amount" => String.trim(expense_params["amount"] || ""),
      "date" => expense_params["date"] || "",
      "merchant" => String.trim(expense_params["merchant"] || ""),
      "notes" => String.trim(expense_params["notes"] || ""),
      "category_id" => expense_params["category_id"] || "",
      "account_id" => expense_params["account_id"] || ""
    }

    # Final validation
    {form_valid, form_errors} = validate_expense_form(form_data)

    if form_valid do
      case socket.assigns.action do
        :new ->
          create_expense(socket, form_data)

        :edit ->
          update_expense(socket, form_data)
      end
    else
      {:noreply,
       socket
       |> assign(:saving, false)
       |> assign(:form_errors, form_errors)}
    end
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    notify_parent(:cancelled)
    {:noreply, socket}
  end

  # Private functions

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
      amount: parse_decimal(form_data["amount"]),
      date: parse_date(form_data["date"]),
      merchant: empty_to_nil(form_data["merchant"]),
      notes: empty_to_nil(form_data["notes"]),
      category_id: empty_to_nil(form_data["category_id"]),
      account_id: empty_to_nil(form_data["account_id"])
    }
  end

  defp validate_expense_form(form_data) do
    errors = []

    # Validate description
    errors =
      case String.trim(form_data["description"]) do
        "" -> ["Description can't be blank" | errors]
        _ -> errors
      end

    # Validate amount
    errors =
      case String.trim(form_data["amount"]) do
        "" ->
          ["Amount can't be blank" | errors]

        amount_str ->
          case parse_decimal(amount_str) do
            nil ->
              ["Amount must be a valid number" | errors]

            amount ->
              if Decimal.compare(amount, Decimal.new("0")) == :gt do
                errors
              else
                ["Amount must be greater than 0" | errors]
              end
          end
      end

    # Validate date
    errors =
      case form_data["date"] do
        "" ->
          ["Date can't be blank" | errors]

        date_str ->
          case parse_date(date_str) do
            nil -> ["Date must be valid" | errors]
            _ -> errors
          end
      end

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

  defp parse_decimal(nil), do: nil
  defp parse_decimal(""), do: nil

  defp parse_decimal(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, ""} -> decimal
      _ -> nil
    end
  end

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp empty_to_nil(""), do: nil
  defp empty_to_nil(value), do: value

  defp extract_ash_errors(%Invalid{errors: errors}) do
    Enum.map(errors, fn
      %{message: message} -> message
      error -> inspect(error)
    end)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
