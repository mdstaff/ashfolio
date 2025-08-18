defmodule AshfolioWeb.CategoryLive.Index do
  use AshfolioWeb, :live_view

  alias Ashfolio.FinancialManagement.TransactionCategory
  alias AshfolioWeb.Live.{FormatHelpers, ErrorHelpers}
  alias AshfolioWeb.CategoryLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_current_page(:categories)
      |> assign(:page_title, "Investment Categories")
      |> assign(:page_subtitle, "Organize your investment transactions")
      |> assign(:show_form, false)
      |> assign(:form_action, :new)
      |> assign(:selected_category, nil)
      |> assign(:deleting_category_id, nil)
      |> assign(:category_filter, :all)
      |> assign(:loading, true)

    # Load categories
    socket = load_categories(socket)

    # Subscribe to category updates for real-time changes
    Ashfolio.PubSub.subscribe("categories")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("new_category", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:form_action, :new)
     |> assign(:selected_category, nil)}
  end

  @impl true
  def handle_event("filter_categories", %{"filter" => filter}, socket) do
    filter_atom = String.to_existing_atom(filter)

    {:noreply,
     socket
     |> assign(:category_filter, filter_atom)
     |> assign(
       :filtered_categories,
       get_filtered_categories(socket.assigns.categories, filter_atom)
     )}
  end

  @impl true
  def handle_event("edit_category", %{"id" => id}, socket) do
    category = Enum.find(socket.assigns.categories, &(&1.id == id))

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:form_action, :edit)
     |> assign(:selected_category, category)}
  end

  @impl true
  def handle_event("delete_category", %{"id" => id}, socket) do
    # Set loading state for visual feedback
    socket = assign(socket, :deleting_category_id, id)

    # Get category to check if it's a system category
    category = Enum.find(socket.assigns.categories, &(&1.id == id))

    if category && category.is_system do
      {:noreply,
       socket
       |> assign(:deleting_category_id, nil)
       |> ErrorHelpers.put_error_flash("System categories cannot be deleted")}
    else
      # Check if category has any transactions before allowing deletion
      case get_category_transaction_count(id) do
        0 ->
          # Safe to delete - no transactions
          case TransactionCategory.destroy(id) do
            :ok ->
              Ashfolio.PubSub.broadcast!("categories", {:category_deleted, id})
              socket = load_categories(socket)

              {:noreply,
               socket
               |> ErrorHelpers.put_success_flash("Category deleted successfully")
               |> assign(:deleting_category_id, nil)}

            {:error, reason} ->
              {:noreply,
               socket
               |> assign(:deleting_category_id, nil)
               |> ErrorHelpers.put_error_flash(reason, "Failed to delete category")}
          end

        count ->
          # Has transactions - cannot delete
          {:noreply,
           socket
           |> assign(:deleting_category_id, nil)
           |> ErrorHelpers.put_error_flash(
             "Cannot delete category that has #{count} transaction(s). Remove or reassign transactions first."
           )}
      end
    end
  end

  @impl true
  def handle_event("cancel_form", _params, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  @impl true
  def handle_info({FormComponent, {:saved, category}}, socket) do
    # Database-as-user architecture: No user_id needed

    case socket.assigns.form_action do
      :new ->
        Ashfolio.PubSub.broadcast!("categories", {:category_created, category})

        {:noreply,
         socket
         |> assign(:show_form, false)
         |> load_categories()
         |> ErrorHelpers.put_success_flash("Category \"#{category.name}\" created successfully")}

      :edit ->
        Ashfolio.PubSub.broadcast!("categories", {:category_updated, category})

        {:noreply,
         socket
         |> assign(:show_form, false)
         |> load_categories()
         |> ErrorHelpers.put_success_flash("Category \"#{category.name}\" updated successfully")}
    end
  end

  @impl true
  def handle_info({FormComponent, :cancelled}, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  @impl true
  def handle_info({:category_created, _category}, socket) do
    {:noreply, load_categories(socket)}
  end

  @impl true
  def handle_info({:category_updated, _category}, socket) do
    {:noreply, load_categories(socket)}
  end

  @impl true
  def handle_info({:category_deleted, _category_id}, socket) do
    {:noreply, load_categories(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="py-6">
        <!-- Header Section -->
        <div class="flex justify-between items-center mb-6">
          <div>
            <h1 class="text-2xl font-bold text-gray-900">{@page_title}</h1>
            <p class="mt-1 text-sm text-gray-600">{@page_subtitle}</p>
          </div>
          <button
            type="button"
            phx-click="new_category"
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            <.icon name="hero-plus-mini" class="h-4 w-4 mr-2" /> New Category
          </button>
        </div>
        
    <!-- Filter Controls -->
        <div class="mb-6">
          <div class="flex flex-wrap gap-2">
            <button
              phx-click="filter_categories"
              phx-value-filter="all"
              class={[
                "px-3 py-2 text-sm font-medium rounded-md border transition-colors",
                if(@category_filter == :all,
                  do: "bg-blue-100 text-blue-700 border-blue-300",
                  else: "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                )
              ]}
            >
              All Categories
              <span class="ml-2 text-xs bg-gray-200 text-gray-600 px-2 py-0.5 rounded-full">
                {length(@categories || [])}
              </span>
            </button>
            <button
              phx-click="filter_categories"
              phx-value-filter="user"
              class={[
                "px-3 py-2 text-sm font-medium rounded-md border transition-colors",
                if(@category_filter == :user,
                  do: "bg-green-100 text-green-700 border-green-300",
                  else: "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                )
              ]}
            >
              My Categories
              <span class="ml-2 text-xs bg-gray-200 text-gray-600 px-2 py-0.5 rounded-full">
                {length(Enum.filter(@categories || [], &(!&1.is_system)))}
              </span>
            </button>
            <button
              phx-click="filter_categories"
              phx-value-filter="system"
              class={[
                "px-3 py-2 text-sm font-medium rounded-md border transition-colors",
                if(@category_filter == :system,
                  do: "bg-purple-100 text-purple-700 border-purple-300",
                  else: "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                )
              ]}
            >
              System Categories
              <span class="ml-2 text-xs bg-gray-200 text-gray-600 px-2 py-0.5 rounded-full">
                {length(Enum.filter(@categories || [], & &1.is_system))}
              </span>
            </button>
          </div>
        </div>
        
    <!-- Loading State -->
        <div :if={@loading} class="text-center py-12">
          <div class="inline-flex items-center px-4 py-2 font-semibold leading-6 text-sm shadow rounded-md text-gray-500 bg-white transition ease-in-out duration-150">
            <svg
              class="animate-spin -ml-1 mr-3 h-5 w-5 text-gray-500"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
              </circle>
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              >
              </path>
            </svg>
            Loading categories...
          </div>
        </div>
        
    <!-- Categories Grid -->
        <div :if={!@loading} class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          <%= for category <- get_filtered_categories(@categories, @category_filter) do %>
            <div
              class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow"
              data-category-id={category.id}
            >
              <!-- Category Header -->
              <div class="flex items-start justify-between mb-4">
                <div class="flex items-center space-x-3">
                  <!-- Color indicator -->
                  <div
                    class="w-4 h-4 rounded-full flex-shrink-0"
                    style={"background-color: #{category.color || "#6B7280"}"}
                  >
                  </div>
                  <div>
                    <h3 class="text-lg font-medium text-gray-900">{category.name}</h3>
                    <div class="flex items-center space-x-2 mt-1">
                      <span
                        :if={category.is_system}
                        class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-800"
                      >
                        <.icon name="hero-shield-check-mini" class="h-3 w-3 mr-1" /> System
                      </span>
                      <span
                        :if={!category.is_system}
                        class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800"
                      >
                        <.icon name="hero-user-mini" class="h-3 w-3 mr-1" /> Custom
                      </span>
                    </div>
                  </div>
                </div>
                
    <!-- Actions Dropdown -->
                <div class="relative">
                  <button
                    type="button"
                    class="text-gray-400 hover:text-gray-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded-full p-1"
                    phx-click="edit_category"
                    phx-value-id={category.id}
                    disabled={category.is_system}
                  >
                    <.icon name="hero-pencil-mini" class="h-4 w-4" />
                  </button>
                </div>
              </div>
              
    <!-- Category Stats -->
              <div class="space-y-2">
                <div class="flex items-center justify-between text-sm">
                  <span class="text-gray-500">Transactions:</span>
                  <span class="font-medium text-gray-900">
                    {get_category_transaction_count(category.id)}
                  </span>
                </div>
                <div :if={category.parent_category} class="flex items-center justify-between text-sm">
                  <span class="text-gray-500">Parent:</span>
                  <span class="font-medium text-gray-900">
                    {category.parent_category.name}
                  </span>
                </div>
                <div :if={!category.is_system} class="flex items-center justify-between text-sm">
                  <span class="text-gray-500">Created:</span>
                  <span class="font-medium text-gray-900">
                    {FormatHelpers.format_date(category.inserted_at)}
                  </span>
                </div>
              </div>
              
    <!-- Actions -->
              <div :if={!category.is_system} class="mt-4 pt-4 border-t border-gray-200">
                <div class="flex justify-between">
                  <button
                    type="button"
                    phx-click="edit_category"
                    phx-value-id={category.id}
                    class="inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                  >
                    <.icon name="hero-pencil-mini" class="h-3 w-3 mr-1" /> Edit
                  </button>
                  <button
                    type="button"
                    phx-click="delete_category"
                    phx-value-id={category.id}
                    disabled={@deleting_category_id == category.id}
                    class="inline-flex items-center px-3 py-1.5 border border-red-300 shadow-sm text-xs font-medium rounded text-red-700 bg-white hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50 disabled:cursor-not-allowed"
                    data-confirm={"Are you sure you want to delete \"#{category.name}\"? This action cannot be undone."}
                  >
                    <%= if @deleting_category_id == category.id do %>
                      <svg
                        class="animate-spin h-3 w-3 mr-1"
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
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                        >
                        </path>
                      </svg>
                      Deleting...
                    <% else %>
                      <.icon name="hero-trash-mini" class="h-3 w-3 mr-1" /> Delete
                    <% end %>
                  </button>
                </div>
              </div>
              
    <!-- System category note -->
              <div :if={category.is_system} class="mt-4 pt-4 border-t border-gray-200">
                <p class="text-xs text-gray-500">
                  <.icon name="hero-information-circle-mini" class="h-3 w-3 inline mr-1" />
                  System categories cannot be edited or deleted
                </p>
              </div>
            </div>
          <% end %>
        </div>
        
    <!-- Empty State -->
        <div
          :if={!@loading && length(get_filtered_categories(@categories, @category_filter)) == 0}
          class="text-center py-12"
        >
          <.icon name="hero-tag" class="mx-auto h-12 w-12 text-gray-400" />
          <h3 class="mt-2 text-sm font-medium text-gray-900">No categories found</h3>
          <p class="mt-1 text-sm text-gray-500">
            <%= case @category_filter do %>
              <% :user -> %>
                You haven't created any custom categories yet.
              <% :system -> %>
                No system categories are available.
              <% _ -> %>
                No categories are available.
            <% end %>
          </p>
          <div :if={@category_filter != :system} class="mt-6">
            <button
              type="button"
              phx-click="new_category"
              class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <.icon name="hero-plus-mini" class="h-4 w-4 mr-2" /> Create your first category
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Form Modal -->
    <.live_component
      :if={@show_form}
      module={FormComponent}
      id="category-form"
      action={@form_action}
      category={@selected_category}
      categories={@categories}
    />
    """
  end

  # Private functions

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Investment Categories")
    |> assign(:show_form, false)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Category")
    |> assign(:show_form, true)
    |> assign(:form_action, :new)
    |> assign(:selected_category, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    category =
      case socket.assigns[:categories] do
        categories when is_list(categories) ->
          Enum.find(categories, &(&1.id == id))

        _ ->
          case TransactionCategory.get_by_id(id) do
            {:ok, category} -> category
            _ -> nil
          end
      end

    socket
    |> assign(:page_title, "Edit Category")
    |> assign(:show_form, true)
    |> assign(:form_action, :edit)
    |> assign(:selected_category, category)
  end

  defp load_categories(socket) do
    # Database-as-user architecture: No user_id needed
    case TransactionCategory.get_categories_with_children() do
      {:ok, categories} ->
        socket
        |> assign(:categories, categories)
        |> assign(
          :filtered_categories,
          get_filtered_categories(categories, socket.assigns.category_filter)
        )
        |> assign(:loading, false)

      {:error, _reason} ->
        socket
        |> assign(:categories, [])
        |> assign(:filtered_categories, [])
        |> assign(:loading, false)
        |> ErrorHelpers.put_error_flash("Failed to load categories")
    end
  end

  defp get_filtered_categories(categories, :all), do: categories
  defp get_filtered_categories(categories, :user), do: Enum.filter(categories, &(!&1.is_system))
  defp get_filtered_categories(categories, :system), do: Enum.filter(categories, & &1.is_system)

  defp get_category_transaction_count(_category_id) do
    # Placeholder - in a real implementation, this would query the transactions
    # For now, return 0 to allow deletion
    0
  end

end
