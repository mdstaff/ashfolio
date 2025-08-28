defmodule AshfolioWeb.Components.ErrorDisplay do
  @moduledoc """
  LiveView components for displaying user-friendly error messages.

  Provides consistent error display across all v0.2.0 features:
  - Cash balance management errors
  - Symbol search errors
  - Category management errors
  - Net worth calculation errors
  - Context API errors
  """

  use Phoenix.Component
  use Phoenix.LiveView

  import AshfolioWeb.CoreComponents, only: [icon: 1]

  alias Ashfolio.ErrorHandler

  @doc """
  Displays an error message with appropriate styling and context.

  ## Examples

      <.error_message error={@error} />
      <.error_message error={@error} dismissible={true} />
      <.error_message error={@error} context="balance update" />
  """
  attr :error, :any, required: true, doc: "The error to display (can be error tuple or string)"
  attr :dismissible, :boolean, default: false, doc: "Whether the error can be dismissed"
  attr :context, :string, default: nil, doc: "Additional context for the error"
  attr :class, :string, default: "", doc: "Additional CSS classes"

  def error_message(assigns) do
    ~H"""
    <div class={["rounded-md bg-red-50 p-4 mb-4", @class]} role="alert" aria-live="polite">
      <div class="flex">
        <div class="flex-shrink-0">
          <.icon name="hero-exclamation-circle" class="h-5 w-5 text-red-400" />
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium text-red-800">
            {format_error_message(@error)}
          </p>
          <%= if @context do %>
            <p class="mt-1 text-xs text-red-600">
              Context: {@context}
            </p>
          <% end %>
        </div>
        <%= if @dismissible do %>
          <div class="ml-auto pl-3">
            <div class="-mx-1.5 -my-1.5">
              <button
                type="button"
                phx-click="dismiss_error"
                class="inline-flex rounded-md bg-red-50 p-1.5 text-red-500 hover:bg-red-100 focus:outline-none focus:ring-2 focus:ring-red-600 focus:ring-offset-2 focus:ring-offset-red-50"
                aria-label="Dismiss error"
              >
                <.icon name="hero-x-mark" class="h-4 w-4" />
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Displays a warning message for less critical errors.

  ## Examples

      <.warning_message message="Symbol search is using cached data" />
      <.warning_message message={@warning} dismissible={true} />
  """
  attr :message, :string, required: true, doc: "The warning message to display"
  attr :dismissible, :boolean, default: false, doc: "Whether the warning can be dismissed"
  attr :class, :string, default: "", doc: "Additional CSS classes"

  def warning_message(assigns) do
    ~H"""
    <div class={["rounded-md bg-yellow-50 p-4 mb-4", @class]} role="alert" aria-live="polite">
      <div class="flex">
        <div class="flex-shrink-0">
          <.icon name="hero-exclamation-triangle" class="h-5 w-5 text-yellow-400" />
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium text-yellow-800">
            {@message}
          </p>
        </div>
        <%= if @dismissible do %>
          <div class="ml-auto pl-3">
            <div class="-mx-1.5 -my-1.5">
              <button
                type="button"
                phx-click="dismiss_warning"
                class="inline-flex rounded-md bg-yellow-50 p-1.5 text-yellow-500 hover:bg-yellow-100 focus:outline-none focus:ring-2 focus:ring-yellow-600 focus:ring-offset-2 focus:ring-offset-yellow-50"
                aria-label="Dismiss warning"
              >
                <.icon name="hero-x-mark" class="h-4 w-4" />
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Displays an inline error message for form fields.

  ## Examples

      <.inline_error error="Balance cannot be negative" />
      <.inline_error error={@field_error} />
  """
  attr :error, :string, required: true, doc: "The error message to display"
  attr :class, :string, default: "", doc: "Additional CSS classes"

  def inline_error(assigns) do
    ~H"""
    <p class={["mt-1 text-sm text-red-600", @class]} role="alert">
      {@error}
    </p>
    """
  end

  @doc """
  Displays a success message for completed operations.

  ## Examples

      <.success_message message="Balance updated successfully" />
      <.success_message message={@success} dismissible={true} />
  """
  attr :message, :string, required: true, doc: "The success message to display"
  attr :dismissible, :boolean, default: true, doc: "Whether the message can be dismissed"
  attr :class, :string, default: "", doc: "Additional CSS classes"

  def success_message(assigns) do
    ~H"""
    <div class={["rounded-md bg-green-50 p-4 mb-4", @class]} role="alert" aria-live="polite">
      <div class="flex">
        <div class="flex-shrink-0">
          <.icon name="hero-check-circle" class="h-5 w-5 text-green-400" />
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium text-green-800">
            {@message}
          </p>
        </div>
        <%= if @dismissible do %>
          <div class="ml-auto pl-3">
            <div class="-mx-1.5 -my-1.5">
              <button
                type="button"
                phx-click="dismiss_success"
                class="inline-flex rounded-md bg-green-50 p-1.5 text-green-500 hover:bg-green-100 focus:outline-none focus:ring-2 focus:ring-green-600 focus:ring-offset-2 focus:ring-offset-green-50"
                aria-label="Dismiss success message"
              >
                <.icon name="hero-x-mark" class="h-4 w-4" />
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Displays a loading state with error fallback for async operations.

  ## Examples

      <.async_error_boundary loading={@loading} error={@error}>
        <p>Content loaded successfully!</p>
      </.async_error_boundary>
  """
  attr :loading, :boolean, default: false, doc: "Whether content is still loading"
  attr :error, :any, default: nil, doc: "Error to display if operation failed"
  attr :retry_event, :string, default: "retry", doc: "Event to send when retry is clicked"
  slot :inner_block, required: true, doc: "Content to display when loaded successfully"

  def async_error_boundary(assigns) do
    ~H"""
    <%= cond do %>
      <% @loading -> %>
        <div class="flex items-center justify-center p-8">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
          <span class="ml-2 text-gray-600">Loading...</span>
        </div>
      <% @error -> %>
        <div class="text-center p-8">
          <.error_message error={@error} />
          <button
            type="button"
            phx-click={@retry_event}
            class="mt-4 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            <.icon name="hero-arrow-path" class="h-4 w-4 mr-2" /> Try Again
          </button>
        </div>
      <% true -> %>
        {render_slot(@inner_block)}
    <% end %>
    """
  end

  # Private helper functions

  defp format_error_message(error) when is_binary(error), do: error

  defp format_error_message(error_tuple) do
    case ErrorHandler.handle_error(error_tuple) do
      {:error, message} -> message
      _ -> "An unexpected error occurred. Please try again."
    end
  end
end
