defmodule AshfolioWeb.TransactionLive.FormComponent do
  use AshfolioWeb, :live_component

  alias Ashfolio.Portfolio.{Account, Symbol, Transaction}
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias AshfolioWeb.Components.SymbolAutocomplete

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
      <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-medium text-gray-900">
            {if @action == :new, do: "New Transaction", else: "Edit Transaction"}
          </h3>
          <button
            type="button"
            phx-click="cancel"
            phx-target={@myself}
            class="text-gray-400 hover:text-gray-600"
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

        <.simple_form
          for={@form}
          id="transaction-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <.input
            field={@form[:type]}
            type="select"
            label="Transaction Type"
            options={[
              {"Buy", :buy},
              {"Sell", :sell},
              {"Dividend", :dividend},
              {"Fee", :fee},
              {"Interest", :interest},
              {"Liability", :liability}
            ]}
            prompt="Select type"
            required
          />

          <.input
            field={@form[:account_id]}
            type="select"
            label="Account"
            options={Enum.map(@accounts, fn a -> {a.name, a.id} end)}
            prompt="Select account"
            required
          />
          
    <!-- Enhanced Symbol Selection with Autocomplete -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-700">
              Symbol <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <.live_component
                module={SymbolAutocomplete}
                id="transaction-symbol-autocomplete"
                field={@symbol_field}
              />
              <.input
                field={@form[:symbol_id]}
                type="text"
                value={@selected_symbol_id || ""}
                class="hidden"
              />
            </div>
            <div :if={@selected_symbol} class="text-sm text-gray-600">
              <div class="flex items-center space-x-2">
                <span class="font-medium">{@selected_symbol.symbol}</span>
                <span>-</span>
                <span>{@selected_symbol.name}</span>
                <button
                  type="button"
                  phx-click="clear_symbol"
                  phx-target={@myself}
                  class="text-red-600 hover:text-red-800"
                  title="Clear selection"
                >
                  <.icon name="hero-x-mark-mini" class="h-4 w-4" />
                </button>
              </div>
            </div>
          </div>
          
    <!-- Investment Category Selection -->
          <div :if={@categories != []} class="space-y-2">
            <.input
              field={@form[:category_id]}
              type="select"
              label="Investment Category (Optional)"
              options={Enum.map(@categories, fn c -> {c.name, c.id} end)}
              prompt="Select category"
            />
            <div class="text-xs text-gray-500">
              Organize your investment transactions by category
            </div>
          </div>

          <.input field={@form[:quantity]} type="number" label="Quantity" step="0.000001" required />
          <.input field={@form[:price]} type="number" label="Price" step="0.0001" required />
          <.input field={@form[:fee]} type="number" label="Fee" step="0.01" />
          <.input field={@form[:date]} type="date" label="Date" required />
          <.input field={@form[:notes]} type="textarea" label="Notes" />

          <:actions>
            <.button phx-disable-with="Saving..." class="w-full">
              {if @action == :new, do: "Create Transaction", else: "Update Transaction"}
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{transaction: _transaction} = assigns, socket) do
    # Database-as-user architecture - no user_id needed
    accounts = Account.list!()
    symbols = Symbol.list!()

    # Load transaction categories for investment organization
    categories =
      case TransactionCategory.list() do
        {:ok, cats} -> cats
        {:error, _} -> []
      end

    # Initialize symbol autocomplete field
    symbol_field = %Phoenix.HTML.FormField{
      form: %Phoenix.HTML.Form{},
      field: :symbol_search,
      id: "symbol_search",
      name: "symbol_search",
      value: "",
      errors: []
    }

    # Handle existing transaction for editing
    {selected_symbol, selected_symbol_id} =
      case assigns.transaction do
        %Transaction{symbol: %Symbol{} = symbol} ->
          {%{symbol: symbol.symbol, name: symbol.name}, symbol.id}

        %Transaction{symbol_id: symbol_id} when not is_nil(symbol_id) ->
          case Enum.find(symbols, &(&1.id == symbol_id)) do
            %Symbol{} = symbol ->
              {%{symbol: symbol.symbol, name: symbol.name}, symbol.id}

            _ ->
              {nil, nil}
          end

        _ ->
          {nil, nil}
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:accounts, accounts)
     |> assign(:symbols, symbols)
     |> assign(:categories, categories)
     |> assign(:symbol_field, symbol_field)
     |> assign(:selected_symbol, selected_symbol)
     |> assign(:selected_symbol_id, selected_symbol_id)
     |> assign_new(:form, fn ->
       to_form(AshPhoenix.Form.for_create(Transaction, :create, as: "transaction"))
     end)}
  end

  @impl true
  def update(%{symbol_selected: symbol_data} = _assigns, socket) when is_map(symbol_data) do
    # Handle symbol selection from autocomplete component via send_update
    case find_or_create_symbol(symbol_data) do
      {:ok, symbol} ->
        {:ok,
         socket
         |> assign(:selected_symbol, symbol_data)
         |> assign(:selected_symbol_id, symbol.id)}

      {:error, _reason} ->
        # Fallback: just show the symbol data without ID
        {:ok,
         socket
         |> assign(:selected_symbol, symbol_data)
         |> assign(:selected_symbol_id, nil)}
    end
  end

  @impl true
  def handle_event("validate", %{"transaction" => transaction_params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, transaction_params)
    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("save", %{"transaction" => transaction_params}, socket) do
    save_transaction(socket, socket.assigns.action, transaction_params)
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    notify_parent(:cancel)
    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_symbol", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_symbol, nil)
     |> assign(:selected_symbol_id, nil)}
  end

  defp save_transaction(socket, :new, transaction_params) do
    # Ensure symbol_id is set from autocomplete selection
    transaction_params =
      if socket.assigns.selected_symbol_id do
        Map.put(transaction_params, "symbol_id", socket.assigns.selected_symbol_id)
      else
        transaction_params
      end

    # Need to calculate total_amount before saving
    quantity = Decimal.new(transaction_params["quantity"] || "0")
    price = Decimal.new(transaction_params["price"] || "0")
    fee = Decimal.new(transaction_params["fee"] || "0")

    total_amount = Decimal.add(Decimal.mult(quantity, price), fee)

    transaction_params =
      Map.put(transaction_params, "total_amount", Decimal.to_string(total_amount))

    # User association is handled through the account relationship

    case Transaction.create(transaction_params) do
      {:ok, transaction} ->
        notify_parent({:saved, transaction, "Transaction created successfully"})
        {:noreply, socket}

      {:error, %Ash.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, %Ash.Error.Invalid{} = error} ->
        # Handle validation errors by creating a changeset from the error
        changeset = AshPhoenix.Form.for_create(Transaction, :create, as: "transaction")
        changeset = %{changeset | errors: error.errors}
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_transaction(socket, :edit, transaction_params) do
    # Ensure symbol_id is set from autocomplete selection
    transaction_params =
      if socket.assigns.selected_symbol_id do
        Map.put(transaction_params, "symbol_id", socket.assigns.selected_symbol_id)
      else
        transaction_params
      end

    # Need to calculate total_amount before saving
    quantity = Decimal.new(transaction_params["quantity"] || "0")
    price = Decimal.new(transaction_params["price"] || "0")
    fee = Decimal.new(transaction_params["fee"] || "0")

    total_amount = Decimal.add(Decimal.mult(quantity, price), fee)

    transaction_params =
      Map.put(transaction_params, "total_amount", Decimal.to_string(total_amount))

    case Transaction.update(socket.assigns.transaction, transaction_params) do
      {:ok, transaction} ->
        notify_parent({:saved, transaction, "Transaction updated successfully"})
        {:noreply, socket}

      {:error, %Ash.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, %Ash.Error.Invalid{} = error} ->
        # Handle validation errors by creating a changeset from the error
        changeset =
          AshPhoenix.Form.for_update(socket.assigns.transaction, :update, as: "transaction")

        changeset = %{changeset | errors: error.errors}
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  # Find existing symbol or create new one from autocomplete selection
  defp find_or_create_symbol(%{symbol: symbol_ticker, name: _name}) do
    # First try to find existing symbol
    case Symbol.find_by_symbol(symbol_ticker) do
      {:ok, [symbol]} ->
        {:ok, symbol}

      {:ok, []} ->
        # Symbol doesn't exist locally, for now just return an error
        # In a full implementation, this would create the symbol through Context API
        {:error, :symbol_not_found}

      {:error, _} ->
        {:error, :symbol_not_found}
    end
  end
end
