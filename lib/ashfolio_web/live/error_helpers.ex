defmodule AshfolioWeb.Live.ErrorHelpers do
  @moduledoc """
  Helper functions for displaying errors in LiveView components.

  Provides consistent error message display and flash message handling
  for the Ashfolio application.
  """

  use Phoenix.Component
  use Gettext, backend: AshfolioWeb.Gettext

  @doc """
  Displays error messages in LiveView using flash messages.

  ## Parameters
  - socket: Phoenix LiveView socket
  - error: Error to display (can be string or error tuple)
  - title: Optional title for the error message

  ## Returns
  - Updated socket with flash message

  ## Examples
      socket = put_error_flash(socket, "Something went wrong")
      socket = put_error_flash(socket, {:error, "Validation failed"}, "Form Error")
  """
  def put_error_flash(socket, error, title \\ nil)

  def put_error_flash(socket, {:error, message}, title) do
    put_error_flash(socket, message, title)
  end

  def put_error_flash(socket, message, _title) when is_binary(message) do
    Phoenix.LiveView.put_flash(socket, :error, message)
  end

  def put_error_flash(socket, error, title) do
    {:error, message} = Ashfolio.ErrorHandler.handle_error(error)
    put_error_flash(socket, message, title)
  end

  @doc """
  Displays success messages in LiveView using flash messages.

  ## Parameters
  - socket: Phoenix LiveView socket
  - message: Success message to display
  - title: Optional title for the success message

  ## Returns
  - Updated socket with flash message
  """
  def put_success_flash(socket, message, _title \\ nil) do
    Phoenix.LiveView.put_flash(socket, :info, message)
  end

  @doc """
  Clears all flash messages from the socket.

  ## Parameters
  - socket: Phoenix LiveView socket

  ## Returns
  - Updated socket with cleared flash messages
  """
  def clear_flash(socket) do
    socket
    |> Phoenix.LiveView.clear_flash(:error)
    |> Phoenix.LiveView.clear_flash(:info)
  end

  @doc """
  Handles form validation errors and updates the socket with error messages.

  ## Parameters
  - socket: Phoenix LiveView socket
  - changeset: Ecto.Changeset with validation errors

  ## Returns
  - Updated socket with validation error flash message
  """
  def handle_form_errors(socket, %Ecto.Changeset{valid?: false} = changeset) do
    error_message = Ashfolio.ErrorHandler.format_changeset_errors(changeset)
    |> format_validation_errors()

    put_error_flash(socket, error_message, gettext("Validation Error"))
  end

  def handle_form_errors(socket, _changeset), do: socket

  @doc """
  Component for displaying inline form field errors.

  ## Attributes
  - field: Phoenix.HTML.FormField with errors
  - class: Additional CSS classes

  ## Examples
      <.field_errors field={@form[:email]} />
  """
  attr :field, Phoenix.HTML.FormField, required: true
  attr :class, :string, default: ""

  def field_errors(assigns) do
    ~H"""
    <div :if={@field.errors != []} class={["mt-1 text-sm text-red-600", @class]}>
      <p :for={error <- @field.errors} class="flex items-center gap-1">
        <.icon name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {translate_error(error)}
      </p>
    </div>
    """
  end

  @doc """
  Component for displaying general error messages.

  ## Attributes
  - errors: List of error messages
  - title: Optional title for the error section
  - class: Additional CSS classes

  ## Examples
      <.error_list errors={["Email is required", "Password is too short"]} />
  """
  attr :errors, :list, default: []
  attr :title, :string, default: nil
  attr :class, :string, default: ""

  def error_list(assigns) do
    ~H"""
    <div :if={@errors != []} class={["rounded-md bg-red-50 p-4 border border-red-200", @class]}>
      <div class="flex">
        <div class="flex-shrink-0">
          <.icon name="hero-exclamation-circle" class="h-5 w-5 text-red-400" />
        </div>
        <div class="ml-3">
          <h3 :if={@title} class="text-sm font-medium text-red-800">
            {@title}
          </h3>
          <div class="mt-2 text-sm text-red-700">
            <ul class="list-disc space-y-1 pl-5">
              <li :for={error <- @errors}>{error}</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Private helper functions

  defp format_validation_errors(errors) when is_map(errors) do
    errors
    |> Enum.map(fn {field, messages} ->
      field_name = humanize_field(field)
      message_list = Enum.join(messages, ", ")
      "#{field_name}: #{message_list}"
    end)
    |> Enum.join("; ")
  end

  defp format_validation_errors(errors) when is_list(errors) do
    Enum.join(errors, "; ")
  end

  defp format_validation_errors(error) when is_binary(error), do: error

  defp humanize_field(field) when is_atom(field) do
    field
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp humanize_field(field), do: to_string(field)

  # Import the translate_error function from Phoenix.HTML.Form
  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp translate_error(msg), do: msg

  # Import icon component from core components
  defdelegate icon(assigns), to: AshfolioWeb.CoreComponents
end
