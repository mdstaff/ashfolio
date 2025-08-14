defmodule AshfolioWeb.TransactionLive.Index do
  use AshfolioWeb, :live_view

  alias Ashfolio.Portfolio.{Transaction, User}
  alias Ashfolio.FinancialManagement.{TransactionCategory, TransactionFiltering}
  alias AshfolioWeb.TransactionLive.FormComponent
  alias AshfolioWeb.Live.{ErrorHelpers, FormatHelpers}

  import AshfolioWeb.Components.CategoryTag
  import AshfolioWeb.Components.TransactionFilter
  import AshfolioWeb.Components.TransactionStats
  import AshfolioWeb.Components.TransactionGroup

  @impl true
  def mount(params, _session, socket) do
    user_id = get_default_user_id()

    # Load categories for filtering
    categories =
      case TransactionCategory.get_user_categories_with_children(user_id) do
        {:ok, cats} -> cats
        {:error, _} -> []
      end

    # Initialize enhanced filter state from URL parameters
    initial_filters = parse_url_filters(params)
    all_transactions = list_transactions()

    # Apply initial filters
    {:ok, filtered_transactions} = TransactionFiltering.apply_filters(initial_filters)

    socket =
      socket
      |> assign_current_page(:transactions)
      |> assign(:page_title, "Transactions")
      |> assign(:page_subtitle, "Manage your investment transactions")
      |> assign(:user_id, user_id)
      |> assign(:categories, categories)
      # Enhanced filter state management
      |> assign(:filters, initial_filters)
      |> assign(:category_filter, initial_filters.category || :all)
      |> assign(:transactions, all_transactions)
      |> assign(:filtered_transactions, filtered_transactions)
      |> assign(:filter_stats, calculate_filter_stats(filtered_transactions, all_transactions))
      # Form state
      |> assign(:show_form, false)
      |> assign(:form_action, :new)
      |> assign(:selected_transaction, nil)
      |> assign(:editing_transaction_id, nil)
      |> assign(:deleting_transaction_id, nil)
      # Debounce state
      |> assign(:filter_timer, nil)

    # Subscribe to transaction and category updates
    Ashfolio.PubSub.subscribe("transactions")
    Ashfolio.PubSub.subscribe("categories")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # Handle URL parameter changes for filter state restoration
    new_filters = parse_url_filters(params)

    if Map.equal?(new_filters, socket.assigns.filters) do
      {:noreply, socket}
    else
      case TransactionFiltering.apply_filters(new_filters) do
        {:ok, filtered_transactions} ->
          filter_stats =
            calculate_filter_stats(filtered_transactions, socket.assigns.transactions)

          {:noreply,
           socket
           |> assign(:filters, new_filters)
           |> assign(:category_filter, new_filters[:category] || :all)
           |> assign(:filtered_transactions, filtered_transactions)
           |> assign(:filter_stats, filter_stats)}

        {:error, _reason} ->
          {:noreply, socket}
      end
    end
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

    # Enhanced filter handling with new TransactionFiltering module
    new_filters = Map.put(socket.assigns.filters, :category, category_filter)

    case TransactionFiltering.apply_filters(new_filters) do
      {:ok, filtered_transactions} ->
        filter_stats = calculate_filter_stats(filtered_transactions, socket.assigns.transactions)

        # Update URL parameters
        filter_params = build_filter_params(new_filters)

        {:noreply,
         socket
         |> assign(:filters, new_filters)
         |> assign(:category_filter, category_filter)
         |> assign(:filtered_transactions, filtered_transactions)
         |> assign(:filter_stats, filter_stats)
         |> push_patch(to: ~p"/transactions?#{filter_params}")}

      {:error, _reason} ->
        # Fall back to existing behavior on error
        filtered_transactions =
          get_filtered_transactions(socket.assigns.transactions, category_filter)

        {:noreply,
         socket
         |> assign(:category_filter, category_filter)
         |> assign(:filtered_transactions, filtered_transactions)}
    end
  end

  # Enhanced event handlers for composite filtering
  @impl true
  def handle_event("apply_composite_filters", params, socket) do
    new_filters = parse_form_filters(params)

    socket =
      if Map.equal?(new_filters, socket.assigns.filters) do
        socket
      else
        apply_filters_with_debounce(socket, new_filters)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    default_filters = %{category: :all}

    case TransactionFiltering.apply_filters(default_filters) do
      {:ok, filtered_transactions} ->
        filter_stats = calculate_filter_stats(filtered_transactions, socket.assigns.transactions)

        {:noreply,
         socket
         |> assign(:filters, default_filters)
         |> assign(:category_filter, :all)
         |> assign(:filtered_transactions, filtered_transactions)
         |> assign(:filter_stats, filter_stats)
         |> push_patch(to: ~p"/transactions")}

      {:error, _reason} ->
        {:noreply, assign(socket, :category_filter, :all)}
    end
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

  # Handle debounced filter application
  @impl true
  def handle_info({:apply_filters, new_filters}, socket) do
    case TransactionFiltering.apply_filters(new_filters) do
      {:ok, filtered_transactions} ->
        filter_stats = calculate_filter_stats(filtered_transactions, socket.assigns.transactions)
        filter_params = build_filter_params(new_filters)

        {:noreply,
         socket
         |> assign(:filters, new_filters)
         |> assign(:category_filter, new_filters[:category] || :all)
         |> assign(:filtered_transactions, filtered_transactions)
         |> assign(:filter_stats, filter_stats)
         |> assign(:filter_timer, nil)
         |> push_patch(to: ~p"/transactions?#{filter_params}")}

      {:error, _reason} ->
        {:noreply, assign(socket, :filter_timer, nil)}
    end
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

  # Enhanced filter state management functions

  defp parse_url_filters(params) do
    %{
      category: parse_category_filter(params["category"]),
      transaction_type: parse_transaction_type_filter(params["type"]),
      date_range: parse_date_range_filter(params["date_from"], params["date_to"]),
      amount_range: parse_amount_range_filter(params["amount_min"], params["amount_max"])
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.into(%{})
  end

  defp parse_category_filter(nil), do: :all
  defp parse_category_filter(""), do: :all
  defp parse_category_filter("all"), do: :all
  defp parse_category_filter("uncategorized"), do: :uncategorized

  defp parse_category_filter(category_id) when is_binary(category_id) do
    case Ecto.UUID.cast(category_id) do
      {:ok, _} -> category_id
      :error -> :all
    end
  end

  defp parse_transaction_type_filter(nil), do: nil
  defp parse_transaction_type_filter(""), do: nil
  defp parse_transaction_type_filter("all"), do: nil

  defp parse_transaction_type_filter(type) when is_binary(type) do
    try do
      String.to_existing_atom(type)
    rescue
      ArgumentError -> nil
    end
  end

  defp parse_date_range_filter(nil, nil), do: nil

  defp parse_date_range_filter(date_from, date_to)
       when is_binary(date_from) and is_binary(date_to) do
    with {:ok, from_date} <- Date.from_iso8601(date_from),
         {:ok, to_date} <- Date.from_iso8601(date_to) do
      {from_date, to_date}
    else
      _ -> nil
    end
  end

  defp parse_date_range_filter(_, _), do: nil

  defp parse_amount_range_filter(nil, nil), do: nil

  defp parse_amount_range_filter(min_str, max_str)
       when is_binary(min_str) and is_binary(max_str) do
    with {min_amount, ""} <- Float.parse(min_str),
         {max_amount, ""} <- Float.parse(max_str) do
      {Decimal.new(min_amount), Decimal.new(max_amount)}
    else
      _ -> nil
    end
  end

  defp parse_amount_range_filter(_, _), do: nil

  defp calculate_filter_stats(filtered_transactions, all_transactions) do
    %{
      total_count: length(all_transactions),
      filtered_count: length(filtered_transactions),
      filter_percentage:
        if(length(all_transactions) > 0,
          do: Float.round(length(filtered_transactions) / length(all_transactions) * 100, 1),
          else: 0
        ),
      category_breakdown: calculate_category_breakdown(filtered_transactions)
    }
  end

  defp calculate_category_breakdown(transactions) do
    transactions
    |> Enum.group_by(fn tx ->
      cond do
        # Handle properly loaded category
        is_struct(tx.category) && Map.has_key?(tx.category, :name) ->
          tx.category.name

        # Handle case where category_id exists but category not loaded
        tx.category_id != nil ->
          "Unknown Category"

        # Handle uncategorized
        true ->
          "Uncategorized"
      end
    end)
    |> Enum.map(fn {category_name, txns} ->
      total_amount =
        Enum.reduce(txns, Decimal.new(0), fn tx, acc ->
          Decimal.add(acc, tx.total_amount)
        end)

      %{
        name: category_name,
        count: length(txns),
        total_amount: total_amount
      }
    end)
    |> Enum.sort_by(& &1.count, :desc)
  end

  # Enhanced filter debouncing
  @filter_debounce_ms 300

  defp apply_filters_with_debounce(socket, new_filters) do
    # Cancel existing timer
    if socket.assigns[:filter_timer] do
      Process.cancel_timer(socket.assigns.filter_timer)
    end

    # Set new timer
    timer = Process.send_after(self(), {:apply_filters, new_filters}, @filter_debounce_ms)

    assign(socket, :filter_timer, timer)
  end

  defp parse_form_filters(params) do
    %{
      category: parse_category_filter(params["category_id"]),
      transaction_type: parse_transaction_type_filter(params["transaction_type"]),
      date_range: parse_date_range_filter(params["date_from"], params["date_to"]),
      amount_range: parse_amount_range_filter(params["amount_min"], params["amount_max"])
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.into(%{})
  end

  defp build_filter_params(filters) do
    filters
    |> Enum.reduce(%{}, fn
      {:category, :all}, acc ->
        acc

      {:category, value}, acc ->
        Map.put(acc, :category, value)

      {:transaction_type, value}, acc ->
        Map.put(acc, :type, value)

      {:date_range, {from_date, to_date}}, acc ->
        acc
        |> Map.put(:date_from, Date.to_iso8601(from_date))
        |> Map.put(:date_to, Date.to_iso8601(to_date))

      {:amount_range, {min_amount, max_amount}}, acc ->
        acc
        |> Map.put(:amount_min, Decimal.to_string(min_amount))
        |> Map.put(:amount_max, Decimal.to_string(max_amount))

      _, acc ->
        acc
    end)
  end

  defp build_filter_active_string(filters) do
    active_filters =
      filters
      |> Enum.filter(fn {_key, value} ->
        case value do
          nil -> false
          :all -> false
          "" -> false
          [] -> false
          %{} when map_size(value) == 0 -> false
          _ -> true
        end
      end)
      |> Enum.map(fn {key, value} ->
        case {key, value} do
          {:category, :uncategorized} ->
            "category:uncategorized"

          {:category, category_id} when is_binary(category_id) ->
            "category:#{category_id}"

          {:transaction_type, type} ->
            "type:#{type}"

          {:date_range, {from_date, to_date}} ->
            "date:#{Date.to_iso8601(from_date)}_#{Date.to_iso8601(to_date)}"

          {:amount_range, {min_amount, max_amount}} ->
            "amount:#{Decimal.to_string(min_amount)}_#{Decimal.to_string(max_amount)}"

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    case active_filters do
      [] -> "filters:none"
      filters -> "filters:" <> Enum.join(filters, ",")
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
      
    <!-- Advanced Transaction Filter Component -->
      <.transaction_filter
        :if={@categories != []}
        categories={@categories}
        filters={@filters}
        target={@myself}
        show_filter_summary={true}
        class="mb-6"
      />
      
    <!-- Transaction Statistics -->
      <.transaction_stats
        :if={length(@filtered_transactions) > 0}
        transactions={@filtered_transactions}
        show_breakdown={true}
        show_categories={true}
        show_averages={true}
        show_time_analysis={true}
        compact={false}
        class="mb-6"
      />
      
    <!-- Transaction Grouping View -->
      <.transaction_group
        :if={length(@filtered_transactions) > 0}
        transactions={@filtered_transactions}
        group_by={:category}
        show_group_stats={true}
        collapsible={true}
        compact={false}
        class="mb-6"
      />
      
    <!-- Filter Results Summary -->
      <div
        :if={@filter_stats}
        class="mb-4 text-sm text-gray-600"
        data-filter-count={@filter_stats.filtered_count}
        data-filter-active={build_filter_active_string(@filters)}
      >
        <div class="flex items-center justify-between">
          <span>
            Showing {@filter_stats.filtered_count} of {@filter_stats.total_count} transactions
            <span :if={@filter_stats.filter_percentage < 100} class="font-medium">
              ({@filter_stats.filter_percentage}% of total)
            </span>
          </span>

          <button
            :if={@filter_stats.filtered_count < @filter_stats.total_count}
            type="button"
            phx-click="clear_filters"
            class="text-blue-600 hover:text-blue-800 underline text-sm"
          >
            Show All Transactions
          </button>
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
                  data-transaction-id={transaction.id}
                  data-transaction-category={transaction.category_id || "uncategorized"}
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
                        <.category_tag
                          category={transaction.category}
                          size={:small}
                          clickable={true}
                          click_event="filter_by_category"
                          click_value={transaction.category_id}
                        />
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
