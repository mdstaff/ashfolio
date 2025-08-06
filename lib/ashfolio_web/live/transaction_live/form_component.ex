defmodule AshfolioWeb.TransactionLive.FormComponent do
  use AshfolioWeb, :live_component

  alias Ashfolio.Portfolio.{Account, Symbol, Transaction}

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
            label="Type"
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

          <.input
            field={@form[:symbol_id]}
            type="select"
            label="Symbol"
            options={Enum.map(@symbols, fn s -> {s.symbol, s.id} end)}
            prompt="Select symbol"
            required
          />

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
    user_id = Ashfolio.Portfolio.User.get_default_user!() |> List.first() |> Map.get(:id)
    accounts = Account.accounts_for_user!(user_id)
    symbols = Symbol.list!()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:accounts, accounts)
     |> assign(:symbols, symbols)
     |> assign_new(:form, fn ->
       to_form(AshPhoenix.Form.for_create(Transaction, :create, as: "transaction"))
     end)}
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

  defp save_transaction(socket, :new, transaction_params) do
    # Need to calculate total_amount before saving
    quantity = Decimal.new(transaction_params["quantity"] || "0")
    price = Decimal.new(transaction_params["price"] || "0")
    fee = Decimal.new(transaction_params["fee"] || "0")

    total_amount = Decimal.add(Decimal.mult(quantity, price), fee)

    transaction_params =
      Map.put(transaction_params, "total_amount", Decimal.to_string(total_amount))

    user_id = Ashfolio.Portfolio.User.get_default_user!() |> List.first() |> Map.get(:id)
    transaction_params = Map.put(transaction_params, "user_id", user_id)

    case Transaction.create(transaction_params) do
      {:ok, transaction} ->
        notify_parent({:saved, transaction, "Transaction created successfully"})
        {:noreply, socket}

      {:error, %Ash.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_transaction(socket, :edit, transaction_params) do
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
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
