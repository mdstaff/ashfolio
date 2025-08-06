defmodule AshfolioWeb.TransactionLive.Index do
  use AshfolioWeb, :live_view

  alias Ashfolio.Portfolio.Transaction
  alias AshfolioWeb.TransactionLive.FormComponent
  alias AshfolioWeb.Live.{ErrorHelpers, FormatHelpers}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_current_page(:transactions)
      |> assign(:page_title, "Transactions")
      |> assign(:page_subtitle, "Manage your investment transactions")
      |> assign(:transactions, list_transactions())
      |> assign(:show_form, false)
      |> assign(:form_action, :new)
      |> assign(:selected_transaction, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("new_transaction", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:form_action, :new)
     |> assign(:selected_transaction, nil)}
  end

  @impl true
  def handle_event("edit_transaction", %{"id" => id}, socket) do
    transaction = Ashfolio.Portfolio.Transaction.get_by_id!(id)

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:form_action, :edit)
     |> assign(:selected_transaction, transaction)}
  end

  @impl true
  def handle_event("delete_transaction", %{"id" => id}, socket) do
    case Ashfolio.Portfolio.Transaction.destroy(id) do
      :ok ->
        {:noreply,
         socket
         |> ErrorHelpers.put_success_flash("Transaction deleted successfully")
         |> assign(:transactions, list_transactions())}

      {:error, reason} ->
        {:noreply,
         socket
         |> ErrorHelpers.put_error_flash(reason, "Failed to delete transaction")}
    end
  end

  @impl true
  def handle_info({FormComponent, {:saved, _transaction, message}}, socket) do
    {:noreply,
     socket
     |> ErrorHelpers.put_success_flash(message)
     |> assign(:show_form, false)
     |> assign(:transactions, list_transactions())}
  end

  @impl true
  def handle_info({FormComponent, :cancel}, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  defp list_transactions() do
    Ashfolio.Portfolio.Transaction.list() |> Ash.Query.load([:account, :symbol])
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header with New Transaction Button -->
      <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 class="text-2xl font-bold text-gray-900"><%= @page_title %></h1>
          <p class="text-gray-600"><%= @page_subtitle %></p>
        </div>
        <.button phx-click="new_transaction" class="w-full sm:w-auto">
          <.icon name="hero-plus" class="w-4 h-4 mr-2" />
          New Transaction
        </.button>
      </div>

      <!-- Transaction List (Placeholder) -->
      <.card>
        <:header>
          <h2 class="text-lg font-medium text-gray-900">All Transactions</h2>
        </:header>
        <%= if Enum.empty?(@transactions) do %>
          <div class="text-center py-12">
            <.icon name="hero-document-text" class="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-900 mb-2">No transactions yet</h3>
            <p class="text-gray-600 mb-4">Start by adding your first transaction.</p>
            <.button phx-click="new_transaction">
              <.icon name="hero-plus" class="w-4 h-4 mr-2" />
              Add First Transaction
            </.button>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="min-w-full mt-4" role="table" aria-label="Investment transactions">
              <thead class="text-sm text-left leading-6 text-zinc-500">
                <tr>
                  <th class="p-0 pb-4 pr-6 font-normal">Date</th>
                  <th class="p-0 pb-4 pr-6 font-normal">Type</th>
                  <th class="p-0 pb-4 pr-6 font-normal">Symbol</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Quantity</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Price</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Fee</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Total Amount</th>
                  <th class="p-0 pb-4 pr-6 font-normal">Account</th>
                  <th class="p-0 pb-4 pr-6 font-normal">Actions</th>
                </tr>
              </thead>
              <tbody class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700">
                <tr :for={transaction <- @transactions} class="group hover:bg-zinc-50" role="row">
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                      <span class="relative font-semibold text-zinc-900">
                        {FormatHelpers.format_date(transaction.date)}
                      </span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">{String.capitalize(Atom.to_string(transaction.type))}</span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">{transaction.symbol.symbol}</span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">{FormatHelpers.format_quantity(transaction.quantity)}</span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">{FormatHelpers.format_currency(transaction.price)}</span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">{FormatHelpers.format_currency(transaction.fee)}</span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">{FormatHelpers.format_currency(transaction.total_amount)}</span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">{transaction.account.name}</span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                      <div class="flex flex-col sm:flex-row justify-end gap-2">
                        <.button
                          class="text-sm px-3 py-2 w-full sm:w-auto"
                          phx-click="edit_transaction"
                          phx-value-id={transaction.id}
                          title="Edit transaction"
                          aria-label={"Edit transaction for #{transaction.symbol.symbol}"}
                        >
                          <.icon name="hero-pencil" class="w-4 h-4 sm:mr-1" />
                          <span class="hidden sm:inline">Edit</span>
                        </.button>
                        <.button
                          class="text-sm px-3 py-2 w-full sm:w-auto text-red-600 hover:text-red-700 bg-red-50 hover:bg-red-100 border border-red-200 rounded-md"
                          phx-click="delete_transaction"
                          phx-value-id={transaction.id}
                          data-confirm="Are you sure you want to delete this transaction? This action cannot be undone."
                          title="Delete transaction"
                          aria-label={"Delete transaction for #{transaction.symbol.symbol}"}
                        >
                          <.icon name="hero-trash" class="w-4 h-4 sm:mr-1" />
                          <span class="hidden sm:inline">Delete</span>
                        </.button>
                      </div>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        <% end %>
      </.card>

      <!-- Form Modal -->
      <%= if @show_form do %>
        <.live_component
          module={FormComponent}
          id="transaction-form"
          action={@form_action}
          transaction={@selected_transaction || %Transaction{}}
        />
      <% end %>
    </div>
    """
  end
end