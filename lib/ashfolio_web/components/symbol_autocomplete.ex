defmodule AshfolioWeb.Components.SymbolAutocomplete do
  @moduledoc """
  LiveView server-side autocomplete component for symbol search.

  Provides intelligent symbol search with debouncing, state management, and Context API integration.
  Features server-side debouncing (300ms), maximum 10 displayed results, and accessibility support.

  ## Usage

      <.live_component
        module={AshfolioWeb.Components.SymbolAutocomplete}
        id="symbol-autocomplete"
        field={@form[:symbol]}
        on_select={fn symbol -> send(self(), {:symbol_selected, symbol}) end}
      />

  ## Events

  The component sends the following events to the parent LiveView:
  - `{:symbol_selected, symbol}` - When a symbol is selected from the dropdown

  ## Accessibility

  - Proper ARIA attributes for screen readers
  - Keyboard navigation support (arrow keys, enter, escape)
  - Role and state announcements for assistive technology
  """

  use AshfolioWeb, :live_component

  require Logger

  # Component configuration
  # 300ms debounce as specified
  @debounce_timeout 300
  # Maximum 10 displayed results as specified
  @max_results 10
  # Minimum characters before searching
  @min_query_length 2

  # Configurable Context module for testing
  defp context_module do
    Application.get_env(:ashfolio, :context_module, Ashfolio.Context)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="relative"
      id={"#{@id}-container"}
      phx-hook="SymbolAutocomplete"
      data-testid="symbol-autocomplete"
    >
      <!-- Input field with ARIA attributes -->
      <div class="relative">
        <.input
          field={@field}
          type="text"
          placeholder="Search symbols (e.g., AAPL, Apple)"
          autocomplete="off"
          phx-target={@myself}
          phx-change="search_input"
          phx-keydown="keydown"
          phx-debounce={@debounce_timeout}
          aria-expanded={@show_dropdown}
          aria-haspopup="listbox"
          aria-owns={"#{@id}-results"}
          aria-describedby={@show_dropdown && "#{@id}-help"}
          role="combobox"
          class={[
            "block w-full rounded-md border-gray-300 shadow-sm",
            "focus:border-blue-500 focus:ring-blue-500",
            "transition-colors duration-150 ease-in-out",
            @loading && "pr-10"
          ]}
        />
        
    <!-- Loading indicator -->
        <div :if={@loading} class="absolute inset-y-0 right-0 flex items-center pr-3">
          <svg
            class="h-4 w-4 animate-spin text-gray-400"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
            <path
              class="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            />
          </svg>
        </div>
      </div>
      
    <!-- Dropdown results -->
      <div
        :if={@show_dropdown}
        id={"#{@id}-results"}
        role="listbox"
        aria-label="Symbol search results"
        class={[
          "absolute z-50 mt-1 w-full bg-white shadow-lg",
          "max-h-60 rounded-md py-1 text-base ring-1 ring-black ring-opacity-5",
          "overflow-auto focus:outline-none sm:text-sm",
          "transform transition-all duration-150 ease-in-out",
          "opacity-0 translate-y-[-8px]",
          @show_dropdown && "opacity-100 translate-y-0"
        ]}
        style="display: none;"
      >
        <!-- No results message -->
        <div
          :if={@results == [] and @query != "" and not @loading}
          class="px-4 py-2 text-sm text-gray-500"
          role="option"
          aria-selected="false"
        >
          No symbols found for "{@query}"
        </div>
        
    <!-- Error message -->
        <div :if={@error} class="px-4 py-2 text-sm text-red-600" role="option" aria-selected="false">
          <.icon name="hero-exclamation-triangle-mini" class="h-4 w-4 inline mr-1" />
          {@error}
        </div>
        
    <!-- Search results -->
        <div
          :for={{symbol, index} <- Enum.with_index(@results)}
          phx-click="select_symbol"
          phx-value-symbol={symbol.symbol}
          phx-value-name={symbol.name}
          phx-target={@myself}
          role="option"
          aria-selected={index == @selected_index}
          tabindex="-1"
          data-index={index}
          class={
            [
              "cursor-pointer select-none relative py-2 pl-3 pr-9",
              "hover:bg-blue-50 focus:bg-blue-50 active:bg-blue-100",
              "transition-colors duration-150 ease-in-out",
              # Better touch handling on mobile
              "touch-manipulation",
              index == @selected_index && "bg-blue-50 ring-2 ring-blue-200 ring-inset"
            ]
          }
        >
          <div class="flex items-center justify-between">
            <div class="flex-1 min-w-0">
              <div class="flex items-center space-x-2">
                <span class="font-medium text-gray-900 text-sm">
                  {symbol.symbol}
                </span>
                <span class="text-xs text-gray-500 bg-gray-100 px-1.5 py-0.5 rounded">
                  {format_asset_class(symbol.asset_class)}
                </span>
              </div>
              <div class="text-sm text-gray-600 truncate">
                {symbol.name}
              </div>
            </div>
            
    <!-- Current price if available -->
            <div :if={symbol.current_price} class="text-right">
              <div class="text-sm font-medium text-gray-900">
                ${format_price(symbol.current_price)}
              </div>
            </div>
          </div>
        </div>
        
    <!-- Show more indicator -->
        <div :if={@has_more_results} class="px-4 py-2 text-xs text-gray-500 border-t border-gray-100">
          Showing first {@max_results} results. Type more characters to refine search.
        </div>
      </div>
      
    <!-- Help text for keyboard navigation -->
      <div :if={@show_dropdown} id={"#{@id}-help"} class="sr-only">
        Use arrow keys to navigate, Enter to select, Escape to close
      </div>
      
    <!-- Screen reader announcements -->
      <div id={"#{@id}-announcements"} aria-live="polite" aria-atomic="true" class="sr-only">
        {@announcement}
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:debounce_timeout, fn -> @debounce_timeout end)
      |> assign_new(:max_results, fn -> @max_results end)
      |> assign_new(:min_query_length, fn -> @min_query_length end)
      |> assign_new(:loading, fn -> false end)
      |> assign_new(:show_dropdown, fn -> false end)
      |> assign_new(:results, fn -> [] end)
      |> assign_new(:query, fn -> "" end)
      |> assign_new(:error, fn -> nil end)
      |> assign_new(:selected_index, fn -> -1 end)
      |> assign_new(:has_more_results, fn -> false end)
      |> assign_new(:announcement, fn -> "" end)

    {:ok, socket}
  end

  @impl true
  def handle_event("search_input", %{"value" => query}, socket) do
    query = String.trim(query)

    socket =
      socket
      |> assign(:query, query)
      |> assign(:selected_index, -1)
      |> assign(:error, nil)

    if String.length(query) >= socket.assigns.min_query_length do
      {:noreply, perform_symbol_search(socket, query)}
    else
      {:noreply, clear_search_results(socket)}
    end
  end

  @impl true
  def handle_event("select_symbol", %{"symbol" => symbol, "name" => name}, socket) do
    selected_symbol = %{symbol: symbol, name: name}

    # Notify parent component
    if socket.assigns[:on_select] do
      socket.assigns.on_select.(selected_symbol)
    else
      send(self(), {:symbol_selected, selected_symbol})
    end

    # Close dropdown and announce selection
    {:noreply,
     socket
     |> assign(:show_dropdown, false)
     |> assign(:selected_index, -1)
     |> assign(:announcement, "Selected #{symbol} - #{name}")}
  end

  # Handle keyboard navigation
  @impl true
  def handle_event("keydown", %{"key" => "ArrowDown"}, socket) do
    if socket.assigns.show_dropdown and length(socket.assigns.results) > 0 do
      new_index = min(socket.assigns.selected_index + 1, length(socket.assigns.results) - 1)

      announcement =
        if new_index >= 0 do
          selected_symbol = Enum.at(socket.assigns.results, new_index)
          "#{selected_symbol.symbol} - #{selected_symbol.name}"
        else
          ""
        end

      {:noreply,
       socket
       |> assign(:selected_index, new_index)
       |> assign(:announcement, announcement)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("keydown", %{"key" => "ArrowUp"}, socket) do
    if socket.assigns.show_dropdown and length(socket.assigns.results) > 0 do
      new_index = max(socket.assigns.selected_index - 1, -1)

      announcement =
        if new_index >= 0 do
          selected_symbol = Enum.at(socket.assigns.results, new_index)
          "#{selected_symbol.symbol} - #{selected_symbol.name}"
        else
          "No selection"
        end

      {:noreply,
       socket
       |> assign(:selected_index, new_index)
       |> assign(:announcement, announcement)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("keydown", %{"key" => "Enter"}, socket) do
    if socket.assigns.show_dropdown and
         socket.assigns.selected_index >= 0 and
         socket.assigns.selected_index < length(socket.assigns.results) do
      selected_symbol = Enum.at(socket.assigns.results, socket.assigns.selected_index)

      handle_event(
        "select_symbol",
        %{"symbol" => selected_symbol.symbol, "name" => selected_symbol.name},
        socket
      )
    else
      {:noreply, socket}
    end
  end

  def handle_event("keydown", %{"key" => "Escape"}, socket) do
    {:noreply,
     socket
     |> assign(:show_dropdown, false)
     |> assign(:selected_index, -1)
     |> assign(:announcement, "Search closed")}
  end

  def handle_event("keydown", %{"key" => "Tab"}, socket) do
    # Allow tab to close dropdown naturally
    {:noreply,
     socket
     |> assign(:show_dropdown, false)
     |> assign(:selected_index, -1)}
  end

  def handle_event("keydown", _params, socket) do
    {:noreply, socket}
  end

  # Private helper functions

  defp perform_symbol_search(socket, query) do
    socket =
      socket
      |> assign(:loading, true)
      |> assign(:show_dropdown, true)

    case context_module().search_symbols(query, max_results: socket.assigns.max_results + 1) do
      {:ok, all_results} ->
        handle_successful_search(socket, all_results, query)

      {:error, reason} ->
        handle_failed_search(socket, reason, query)
    end
  end

  defp handle_successful_search(socket, all_results, query) do
    {results, has_more} = limit_results(all_results, socket.assigns.max_results)
    announcement = create_announcement(results, query)

    socket
    |> assign(:loading, false)
    |> assign(:results, results)
    |> assign(:has_more_results, has_more)
    |> assign(:announcement, announcement)
  end

  defp handle_failed_search(socket, reason, query) do
    error_message = format_search_error(reason)
    Logger.warning("Symbol search failed for query '#{query}': #{inspect(reason)}")

    socket
    |> assign(:loading, false)
    |> assign(:results, [])
    |> assign(:error, error_message)
    |> assign(:announcement, "Search failed: #{error_message}")
  end

  defp limit_results(all_results, max_results) do
    if length(all_results) > max_results do
      {Enum.take(all_results, max_results), true}
    else
      {all_results, false}
    end
  end

  defp create_announcement(results, query) do
    case length(results) do
      0 -> "No symbols found for #{query}"
      1 -> "1 symbol found"
      count -> "#{count} symbols found"
    end
  end

  defp clear_search_results(socket) do
    socket
    |> assign(:loading, false)
    |> assign(:show_dropdown, false)
    |> assign(:results, [])
    |> assign(:announcement, "")
  end

  defp format_asset_class(:stock), do: "Stock"
  defp format_asset_class(:etf), do: "ETF"
  defp format_asset_class(:mutual_fund), do: "Fund"
  defp format_asset_class(:crypto), do: "Crypto"
  defp format_asset_class(_), do: "Other"

  defp format_price(price) when is_struct(price, Decimal) do
    price
    |> Decimal.round(2)
    |> Decimal.to_string()
  end

  defp format_price(price) when is_number(price) do
    :erlang.float_to_binary(price, decimals: 2)
  end

  defp format_price(_), do: "N/A"

  defp format_search_error(:search_failed), do: "Search temporarily unavailable"
  defp format_search_error(:rate_limited), do: "Too many searches, please wait"
  defp format_search_error(:api_unavailable), do: "External search unavailable"
  defp format_search_error(:timeout), do: "Search timed out, please try again"
  defp format_search_error(_), do: "Search failed, please try again"
end
