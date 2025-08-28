defmodule AshfolioWeb.CategoryLive.FormComponent do
  @moduledoc false
  use AshfolioWeb, :live_component

  alias Ash.Error.Invalid
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias AshfolioWeb.Live.ErrorHelpers

  @default_colors [
    # Red
    "#EF4444",
    # Orange
    "#F97316",
    # Amber
    "#F59E0B",
    # Yellow
    "#EAB308",
    # Lime
    "#84CC16",
    # Green
    "#22C55E",
    # Emerald
    "#10B981",
    # Teal
    "#14B8A6",
    # Cyan
    "#06B6D4",
    # Sky
    "#0EA5E9",
    # Blue
    "#3B82F6",
    # Indigo
    "#6366F1",
    # Violet
    "#8B5CF6",
    # Purple
    "#A855F7",
    # Fuchsia
    "#D946EF",
    # Pink
    "#EC4899",
    # Rose
    "#F43F5E",
    # Gray
    "#6B7280"
  ]

  @investment_category_suggestions [
    %{name: "Growth", color: "#22C55E", description: "High-growth potential investments"},
    %{name: "Income", color: "#3B82F6", description: "Dividend-focused investments"},
    %{name: "Speculative", color: "#EF4444", description: "High-risk, high-reward investments"},
    %{name: "Index", color: "#6366F1", description: "Broad market index funds"},
    %{name: "Value", color: "#8B5CF6", description: "Undervalued stocks and funds"},
    %{name: "Bonds", color: "#14B8A6", description: "Fixed-income securities"},
    %{name: "REITs", color: "#F59E0B", description: "Real Estate Investment Trusts"},
    %{name: "International", color: "#EC4899", description: "Foreign market investments"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
      <div class="bg-white rounded-lg shadow-xl max-w-lg w-full p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-medium text-gray-900">
            {if @action == :new, do: "New Investment Category", else: "Edit Category"}
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
        
    <!-- Form-level error display -->
        <div :if={@form_errors != []} class="mb-4">
          <ErrorHelpers.error_list errors={@form_errors} title="Please correct the following errors:" />
        </div>
        
    <!-- Category suggestions (only for new categories) -->
        <div :if={@action == :new && @show_suggestions} class="mb-6">
          <div class="flex items-center justify-between mb-3">
            <h4 class="text-sm font-medium text-gray-900">Popular Investment Categories</h4>
            <button
              type="button"
              phx-click="hide_suggestions"
              phx-target={@myself}
              class="text-xs text-gray-500 hover:text-gray-700"
            >
              Hide suggestions
            </button>
          </div>
          <div class="grid grid-cols-2 gap-2 mb-4">
            <%= for suggestion <- @investment_category_suggestions do %>
              <button
                type="button"
                phx-click="use_suggestion"
                phx-target={@myself}
                phx-value-name={suggestion.name}
                phx-value-color={suggestion.color}
                class="flex items-center p-2 text-left border border-gray-200 rounded hover:bg-gray-50 transition-colors"
              >
                <div
                  class="w-3 h-3 rounded-full flex-shrink-0 mr-2"
                  style={"background-color: #{suggestion.color}"}
                >
                </div>
                <div>
                  <div class="text-sm font-medium text-gray-900">{suggestion.name}</div>
                  <div class="text-xs text-gray-500">{suggestion.description}</div>
                </div>
              </button>
            <% end %>
          </div>
          <div class="border-t border-gray-200 pt-4">
            <button
              type="button"
              phx-click="hide_suggestions"
              phx-target={@myself}
              class="text-sm text-blue-600 hover:text-blue-800"
            >
              Create custom category instead
            </button>
          </div>
        </div>
        
    <!-- Custom category form -->
        <div :if={@action == :edit || !@show_suggestions}>
          <.simple_form
            for={@form}
            id="category-form"
            phx-target={@myself}
            phx-change="validate"
            phx-submit="save"
          >
            <!-- Category Name Field -->
            <div class="space-y-1">
              <.input
                field={@form[:name]}
                type="text"
                label="Category Name"
                required
                placeholder="e.g., Growth, Income, Speculative"
                disabled={@saving}
              />
              <div :if={@validation_messages[:name]} class="text-xs text-blue-600">
                <.icon name="hero-information-circle-mini" class="h-3 w-3 inline mr-1" />
                {@validation_messages[:name]}
              </div>
            </div>
            
    <!-- Color Picker -->
            <div class="space-y-3">
              <label class="block text-sm font-medium text-gray-700">
                Category Color
              </label>
              
    <!-- Current color preview -->
              <div class="flex items-center space-x-3">
                <div
                  class="w-8 h-8 rounded-full border-2 border-gray-300"
                  style={"background-color: #{@selected_color}"}
                >
                </div>
                <div>
                  <div class="text-sm font-medium text-gray-900">Selected Color</div>
                  <div class="text-xs text-gray-500 uppercase">{@selected_color}</div>
                </div>
              </div>
              
    <!-- Color palette -->
              <div class="grid grid-cols-9 gap-2">
                <%= for color <- @default_colors do %>
                  <button
                    type="button"
                    phx-click="select_color"
                    phx-target={@myself}
                    phx-value-color={color}
                    class={[
                      "w-8 h-8 rounded-full border-2 transition-all",
                      if(color == @selected_color,
                        do: "border-gray-800 scale-110",
                        else: "border-gray-300 hover:border-gray-400 hover:scale-105"
                      )
                    ]}
                    style={"background-color: #{color}"}
                    title={color}
                  >
                  </button>
                <% end %>
              </div>
              
    <!-- Custom color input -->
              <div class="flex items-center space-x-2">
                <.input
                  field={@form[:color]}
                  type="text"
                  placeholder="#3B82F6"
                  class="flex-1 text-sm"
                  disabled={@saving}
                />
                <button
                  type="button"
                  phx-click="validate_custom_color"
                  phx-target={@myself}
                  class="px-3 py-2 text-xs font-medium text-gray-700 bg-gray-100 border border-gray-300 rounded hover:bg-gray-200"
                  disabled={@saving}
                >
                  Preview
                </button>
              </div>
              <div :if={@validation_messages[:color]} class="text-xs text-blue-600">
                <.icon name="hero-information-circle-mini" class="h-3 w-3 inline mr-1" />
                {@validation_messages[:color]}
              </div>
            </div>
            
    <!-- Parent Category (optional) -->
            <div :if={@available_parent_categories != []} class="space-y-1">
              <.input
                field={@form[:parent_category_id]}
                type="select"
                label="Parent Category (Optional)"
                prompt="None"
                options={@available_parent_categories}
                disabled={@saving}
              />
              <div class="text-xs text-gray-500">
                Create a hierarchy by selecting a parent category
              </div>
            </div>

            <:actions>
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
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      >
                      </path>
                    </svg>
                    {if @action == :new, do: "Creating...", else: "Updating..."}
                  <% else %>
                    {if @action == :new, do: "Create Category", else: "Update Category"}
                  <% end %>
                </button>
              </div>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{action: action, category: category} = assigns, socket) do
    # Prepare initial data
    {form_data, selected_color} =
      case {action, category} do
        {:new, _} ->
          {%{"name" => "", "color" => "#3B82F6"}, "#3B82F6"}

        {:edit, category} when not is_nil(category) ->
          {%{
             "name" => category.name,
             "color" => category.color || "#3B82F6",
             "parent_category_id" => category.parent_category_id
           }, category.color || "#3B82F6"}

        _ ->
          {%{"name" => "", "color" => "#3B82F6"}, "#3B82F6"}
      end

    form = to_form(form_data)

    # Get available parent categories (exclude current category if editing)
    available_parent_categories =
      get_available_parent_categories(assigns[:categories] || [], category)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, form)
     |> assign(:form_data, form_data)
     # Allow editing existing valid categories
     |> assign(:form_valid, action == :edit)
     |> assign(:form_errors, [])
     |> assign(:validation_messages, %{})
     |> assign(:saving, false)
     |> assign(:selected_color, selected_color)
     |> assign(:show_suggestions, action == :new)
     |> assign(:default_colors, @default_colors)
     |> assign(:investment_category_suggestions, @investment_category_suggestions)
     |> assign(:available_parent_categories, available_parent_categories)}
  end

  @impl true
  def handle_event("validate", %{"name" => name, "color" => color} = params, socket) do
    form_data = %{
      "name" => name,
      "color" => color,
      "parent_category_id" => params["parent_category_id"]
    }

    # Validate the form
    {form_valid, form_errors, validation_messages} =
      validate_category_form(form_data, socket.assigns)

    # Update selected color if valid
    selected_color =
      if valid_hex_color?(color) do
        color
      else
        socket.assigns.selected_color
      end

    form = to_form(form_data)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:form_data, form_data)
     |> assign(:form_valid, form_valid)
     |> assign(:form_errors, form_errors)
     |> assign(:validation_messages, validation_messages)
     |> assign(:selected_color, selected_color)}
  end

  @impl true
  def handle_event("select_color", %{"color" => color}, socket) do
    form_data = Map.put(socket.assigns.form_data, "color", color)
    form = to_form(form_data)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:form_data, form_data)
     |> assign(:selected_color, color)}
  end

  @impl true
  def handle_event("validate_custom_color", _params, socket) do
    color = socket.assigns.form_data["color"]

    if valid_hex_color?(color) do
      {:noreply, assign(socket, :selected_color, color)}
    else
      validation_messages =
        Map.put(
          socket.assigns.validation_messages,
          :color,
          "Invalid hex color format (e.g., #3B82F6)"
        )

      {:noreply, assign(socket, :validation_messages, validation_messages)}
    end
  end

  @impl true
  def handle_event("use_suggestion", %{"name" => name, "color" => color}, socket) do
    form_data = %{
      socket.assigns.form_data
      | "name" => name,
        "color" => color
    }

    form = to_form(form_data)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:form_data, form_data)
     |> assign(:selected_color, color)
     |> assign(:show_suggestions, false)}
  end

  @impl true
  def handle_event("hide_suggestions", _params, socket) do
    {:noreply, assign(socket, :show_suggestions, false)}
  end

  @impl true
  def handle_event("save", %{"name" => name, "color" => color} = params, socket) do
    socket = assign(socket, :saving, true)

    form_data = %{
      "name" => String.trim(name),
      "color" => String.trim(color),
      "parent_category_id" => params["parent_category_id"]
    }

    # Final validation
    {form_valid, form_errors, _validation_messages} =
      validate_category_form(form_data, socket.assigns)

    if form_valid do
      case socket.assigns.action do
        :new ->
          create_category(socket, form_data)

        :edit ->
          update_category(socket, form_data)
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

  defp create_category(socket, form_data) do
    category_params = %{
      name: form_data["name"],
      color: form_data["color"],
      parent_category_id: parse_parent_category_id(form_data["parent_category_id"])
    }

    case TransactionCategory.create(category_params) do
      {:ok, category} ->
        notify_parent({:saved, category})
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
         |> assign(:form_errors, ["Failed to create category: #{inspect(reason)}"])}
    end
  end

  defp update_category(socket, form_data) do
    category_params = %{
      name: form_data["name"],
      color: form_data["color"],
      parent_category_id: parse_parent_category_id(form_data["parent_category_id"])
    }

    case TransactionCategory.update(socket.assigns.category, category_params) do
      {:ok, category} ->
        notify_parent({:saved, category})
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
         |> assign(:form_errors, ["Failed to update category: #{inspect(reason)}"])}
    end
  end

  defp validate_category_form(form_data, assigns) do
    errors = []
    validation_messages = %{}

    # Validate name
    {errors, validation_messages} =
      case String.trim(form_data["name"]) do
        "" ->
          {["Category name is required" | errors], validation_messages}

        name when byte_size(name) < 2 ->
          {["Category name must be at least 2 characters" | errors], validation_messages}

        name when byte_size(name) > 50 ->
          {["Category name must be less than 50 characters" | errors], validation_messages}

        name ->
          # Check for name uniqueness
          if name_already_exists?(name, assigns) do
            {["Category name must be unique" | errors],
             Map.put(validation_messages, :name, "A category with this name already exists")}
          else
            {errors, Map.put(validation_messages, :name, "Available category name")}
          end
      end

    # Validate color
    {errors, validation_messages} =
      case String.trim(form_data["color"]) do
        "" ->
          {["Category color is required" | errors], validation_messages}

        color ->
          if valid_hex_color?(color) do
            {errors, Map.put(validation_messages, :color, "Valid color format")}
          else
            {["Color must be a valid hex color code (e.g., #3B82F6)" | errors],
             Map.put(validation_messages, :color, "Invalid hex color format")}
          end
      end

    form_valid = errors == []

    {form_valid, Enum.reverse(errors), validation_messages}
  end

  defp name_already_exists?(name, %{categories: categories, category: current_category}) do
    existing_category =
      Enum.find(categories, &(String.downcase(&1.name) == String.downcase(name)))

    case {existing_category, current_category} do
      {nil, _} -> false
      {existing, current} when not is_nil(current) -> existing.id != current.id
      {_existing, _} -> true
    end
  end

  defp name_already_exists?(_name, _assigns), do: false

  defp valid_hex_color?(color) do
    Regex.match?(~r/^#[0-9A-Fa-f]{6}$/, color)
  end

  defp parse_parent_category_id(""), do: nil
  defp parse_parent_category_id(id) when is_binary(id), do: id
  defp parse_parent_category_id(_), do: nil

  defp get_available_parent_categories(categories, current_category) do
    categories
    |> Enum.filter(fn cat ->
      # Exclude current category and system categories from parent options
      (!current_category || cat.id != current_category.id) && !cat.is_system
    end)
    |> Enum.map(&{&1.name, &1.id})
  end

  defp extract_ash_errors(%Invalid{errors: errors}) do
    Enum.map(errors, fn
      %{message: message} -> message
      error -> inspect(error)
    end)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
