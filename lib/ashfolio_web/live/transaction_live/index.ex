defmodule AshfolioWeb.TransactionLive.Index do
  use AshfolioWeb, :live_view

  alias Ashfolio.Portfolio.{Transaction, User}
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias AshfolioWeb.TransactionLive.FormComponent
  alias AshfolioWeb.Live.{ErrorHelpers, FormatHelpers}

  @impl true
  def mount(_params, _session, socket) do
    user_id = get_default_user_id()

    # Load categories for filtering
    categories =
      case TransactionCategory.get_user_categories_with_children(user_id) do
        {:ok, cats} -> cats
        {:error, _} -> []
      end

    socket =
      socket
      |> assign_current_page(:transactions)
      |> assign(:page_title, "Transactions")
      |> assign(:page_subtitle, "Manage your investment transactions")
      |> assign(:user_id, user_id)
      |> assign(:categories, categories)
      |> assign(:category_filter, :all)
      |> assign(:transactions, list_transactions())
      |> assign(:filtered_transactions, list_transactions())
      |> assign(:show_form, false)
      |> assign(:form_action, :new)
      |> assign(:selected_transaction, nil)
      |> assign(:editing_transaction_id, nil)
      |> assign(:deleting_transaction_id, nil)

    # Subscribe to transaction and category updates
    Ashfolio.PubSub.subscribe("transactions")
    Ashfolio.PubSub.subscribe("categories")

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
     |> assign(:selected_transaction, transaction)
     |> assign(:editing_transaction_id, id)}
  end

  @impl true
  def handle_event("filter_transactions", %{"filter" => filter}, socket) do
    filter_atom = String.to_existing_atom(filter)
    filtered_transactions = get_filtered_transactions(socket.assigns.transactions, filter_atom)

    {:noreply,
     socket
     |> assign(:category_filter, filter_atom)
     |> assign(:filtered_transactions, filtered_transactions)}
  end

  @impl true
  def handle_event("filter_by_category", %{"category_id" => category_id}, socket) do
    category_filter = if category_id == "", do: :all, else: category_id

    filtered_transactions =
      get_filtered_transactions(socket.assigns.transactions, category_filter)

    {:noreply,
     socket
     |> assign(:category_filter, category_filter)
     |> assign(:filtered_transactions, filtered_transactions)}
  end

  @impl true
  def handle_event("delete_transaction", %{"id" => id}, socket) do
    socket = assign(socket, :deleting_transaction_id, id)

    case Ashfolio.Portfolio.Transaction.destroy(id) do
      :ok ->
        # Broadcast transaction deleted event
        Ashfolio.PubSub.broadcast!("transactions", {:transaction_deleted, id})

        transactions = list_transactions()

        filtered_transactions =
          get_filtered_transactions(transactions, socket.assigns.category_filter)

        {:noreply,
         socket
         |> ErrorHelpers.put_success_flash("Transaction deleted successfully")
         |> assign(:transactions, transactions)
         |> assign(:filtered_transactions, filtered_transactions)
         |> assign(:deleting_transaction_id, nil)}

      {:error, reason} ->
        {:noreply,
         socket
         |> ErrorHelpers.put_error_flash(reason, "Failed to delete transaction")
         |> assign(:deleting_transaction_id, nil)}
    end
  end

  @impl true
  def handle_info({FormComponent, {:saved, transaction, message}}, socket) do
    # Broadcast transaction saved event
    Ashfolio.PubSub.broadcast!("transactions", {:transaction_saved, transaction})

    transactions = list_transactions()

    filtered_transactions =
      get_filtered_transactions(transactions, socket.assigns.category_filter)

    {:noreply,
     socket
     |> ErrorHelpers.put_success_flash(message)
     |> assign(:show_form, false)
     |> assign(:transactions, transactions)
     |> assign(:filtered_transactions, filtered_transactions)
     |> assign(:editing_transaction_id, nil)}
  end

  @impl true
  def handle_info({FormComponent, :cancel}, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> assign(:editing_transaction_id, nil)}
  end

  # Handle real-time updates from PubSub
  @impl true
  def handle_info({:transaction_saved, _transaction}, socket) do
    transactions = list_transactions()

    filtered_transactions =
      get_filtered_transactions(transactions, socket.assigns.category_filter)

    {:noreply,
     socket
     |> assign(:transactions, transactions)
     |> assign(:filtered_transactions, filtered_transactions)}
  end

  @impl true
  def handle_info({:transaction_deleted, _transaction_id}, socket) do
    transactions = list_transactions()

    filtered_transactions =
      get_filtered_transactions(transactions, socket.assigns.category_filter)

    {:noreply,
     socket
     |> assign(:transactions, transactions)
     |> assign(:filtered_transactions, filtered_transactions)}
  end

  @impl true
  def handle_info({:category_created, _category}, socket) do
    {:noreply, reload_categories(socket)}
  end

  @impl true
  def handle_info({:category_updated, _category}, socket) do
    {:noreply, reload_categories(socket)}
  end

  @impl true
  def handle_info({:category_deleted, _category_id}, socket) do
    {:noreply, reload_categories(socket)}
  end

  @impl true
  def handle_info({:symbol_selected, symbol_data}, socket) do
    # Forward the symbol selection to the form component
    send_update(FormComponent, id: "transaction-form", symbol_selected: symbol_data)
    {:noreply, socket}
  end

  defp list_transactions() do
    case Ashfolio.Portfolio.Transaction.list() do
      {:ok, transactions} ->
        transactions |> Ash.load!([:account, :symbol, :category])

      {:error, _error} ->
        []
    end
  end

  defp get_filtered_transactions(transactions, :all), do: transactions

  defp get_filtered_transactions(transactions, :uncategorized) do
    Enum.filter(transactions, &is_nil(&1.category_id))
  end

  defp get_filtered_transactions(transactions, category_id) when is_binary(category_id) do
    Enum.filter(transactions, &(&1.category_id == category_id))
  end

  defp reload_categories(socket) do
    categories =
      case TransactionCategory.get_user_categories_with_children(socket.assigns.user_id) do
        {:ok, cats} -> cats
        {:error, _} -> []
      end

    assign(socket, :categories, categories)
  end

  defp get_default_user_id do
    case User.get_default_user() do
      {:ok, [user]} -> user.id
      {:ok, user} when is_struct(user) -> user.id
      _ -> nil
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header with New Transaction Button -->
      <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">{@page_title}</h1>
          <p class="text-gray-600">{@page_subtitle}</p>
        </div>
        <.button phx-click="new_transaction" class="w-full sm:w-auto">
          <.icon name="hero-plus" class="w-4 h-4 mr-2" /> New Transaction
        </.button>
      </div>
      
    <!-- Category Filter Controls -->
      <div :if={@categories != []} class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <div class="flex flex-col sm:flex-row sm:items-center gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Filter by Category
            </label>
            <select
              phx-change="filter_by_category"
              name="category_id"
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
            >
              <option value="" selected={@category_filter == :all}>All Categories</option>
              <option value="uncategorized" selected={@category_filter == :uncategorized}>
                Uncategorized
              </option>
              <%= for category <- @categories do %>
                <option value={category.id} selected={@category_filter == category.id}>
                  {category.name}
                </option>
              <% end %>
            </select>
          </div>
          
    <!-- Filter Summary -->
          <div class="flex-1 text-sm text-gray-600">
            Showing {length(@filtered_transactions)} of {length(@transactions)} transactions
            <%= case @category_filter do %>
              <% :all -> %>
                <span class="font-medium">(All categories)</span>
              <% :uncategorized -> %>
                <span class="font-medium">(Uncategorized only)</span>
              <% filter_id when is_binary(filter_id) -> %>
                <% category = Enum.find(@categories, &(&1.id == filter_id)) %>
                <span :if={category} class="font-medium">
                  in "<span style={"color: #{category.color}"}>●</span> {category.name}"
                </span>
            <% end %>
          </div>
        </div>
      </div>
      
    <!-- Transaction List (Placeholder) -->
      <.card>
        <:header>
          <h2 class="text-lg font-medium text-gray-900">All Transactions</h2>
        </:header>
        <%= if Enum.empty?(@filtered_transactions) do %>
          <div class="text-center py-12">
            <.icon name="hero-document-text" class="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-900 mb-2">No transactions yet</h3>
            <p class="text-gray-600 mb-4">Start by adding your first transaction.</p>
            <.button phx-click="new_transaction">
              <.icon name="hero-plus" class="w-4 h-4 mr-2" /> Add First Transaction
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
                  <th class="p-0 pb-4 pr-6 font-normal">Category</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Quantity</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Price</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Fee</th>
                  <th class="p-0 pb-4 pr-6 font-normal text-right">Total Amount</th>
                  <th class="p-0 pb-4 pr-6 font-normal">Account</th>
                  <th class="p-0 pb-4 pr-6 font-normal">Actions</th>
                </tr>
              </thead>
              <tbody class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700">
                <tr
                  :for={transaction <- @filtered_transactions}
                  class="group hover:bg-zinc-50"
                  role="row"
                >
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
                      <span class="relative">
                        {String.capitalize(Atom.to_string(transaction.type))}
                      </span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">{transaction.symbol.symbol}</span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">
                        <%= if transaction.category do %>
                          <span
                            class="inline-flex items-center px-2 py-1 rounded text-xs font-medium"
                            style={"background-color: #{transaction.category.color}20; color: #{transaction.category.color}"}
                          >
                            <span
                              class="w-2 h-2 rounded-full mr-1"
                              style={"background-color: #{transaction.category.color}"}
                            >
                            </span>
                            {transaction.category.name}
                          </span>
                        <% else %>
                          <span class="text-gray-400 text-xs">Uncategorized</span>
                        <% end %>
                      </span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6 text-right">
                      <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50" />
                      <span class="relative">
                        {FormatHelpers.format_quantity(transaction.quantity)}
                      </span>
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
                      <span class="relative">
                        {FormatHelpers.format_currency(transaction.total_amount)}
                      </span>
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
                          phx-disable-with="Opening..."
                          title="Edit transaction"
                          aria-label={"Edit transaction for #{transaction.symbol.symbol}"}
                          disabled={@editing_transaction_id == transaction.id}
                        >
                          <%= if @editing_transaction_id == transaction.id do %>
                            <.icon name="hero-arrow-path" class="w-4 h-4 sm:mr-1 animate-spin" />
                            <span class="hidden sm:inline">Opening...</span>
                          <% else %>
                            <.icon name="hero-pencil" class="w-4 h-4 sm:mr-1" />
                            <span class="hidden sm:inline">Edit</span>
                          <% end %>
                        </.button>
                        <.button
                          class="text-sm px-3 py-2 w-full sm:w-auto text-red-600 hover:text-red-700 bg-red-50 hover:bg-red-100 border border-red-200 rounded-md"
                          phx-click="delete_transaction"
                          phx-value-id={transaction.id}
                          phx-disable-with="Deleting..."
                          data-confirm="Are you sure you want to delete this transaction? This action cannot be undone."
                          title="Delete transaction"
                          aria-label={"Delete transaction for #{transaction.symbol.symbol}"}
                          disabled={@deleting_transaction_id == transaction.id}
                        >
                          <%= if @deleting_transaction_id == transaction.id do %>
                            <.icon name="hero-arrow-path" class="w-4 h-4 sm:mr-1 animate-spin" />
                            <span class="hidden sm:inline">Deleting...</span>
                          <% else %>
                            <.icon name="hero-trash" class="w-4 h-4 sm:mr-1" />
                            <span class="hidden sm:inline">Delete</span>
                          <% end %>
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
