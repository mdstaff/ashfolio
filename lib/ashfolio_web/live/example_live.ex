defmodule AshfolioWeb.ExampleLive do
  @moduledoc """
  Example LiveView demonstrating error handling usage.

  This is a simple example showing how to use the error handling
  system in a LiveView context. This file can be removed once
  real LiveView pages are implemented.
  """

  use AshfolioWeb, :live_view
  alias AshfolioWeb.Live.ErrorHelpers

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :form_data, %{})}
  end

  def handle_event("simulate_error", %{"type" => error_type}, socket) do
    # Simulate different types of errors for demonstration
    error =
      case error_type do
        "network" -> {:error, :network_timeout}
        "validation" -> %Ecto.Changeset{valid?: false, errors: [name: {"can't be blank", []}]}
        "system" -> {:error, :unknown_system_error}
        _ -> {:error, :generic_error}
      end

    socket = ErrorHelpers.put_error_flash(socket, error)
    {:noreply, socket}
  end

  def handle_event("simulate_success", _params, socket) do
    socket = ErrorHelpers.put_success_flash(socket, "Operation completed successfully!")
    {:noreply, socket}
  end

  def handle_event("clear_flash", _params, socket) do
    socket = ErrorHelpers.clear_flash(socket)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-6">
      <h1 class="text-2xl font-bold mb-6">Error Handling Demo</h1>

      <div class="space-y-4">
        <div class="bg-gray-50 p-4 rounded-lg">
          <h2 class="text-lg font-semibold mb-3">Test Error Types</h2>
          <div class="space-x-2">
            <button
              phx-click="simulate_error"
              phx-value-type="network"
              class="px-4 py-2 bg-yellow-500 text-white rounded hover:bg-yellow-600"
            >
              Network Error
            </button>
            <button
              phx-click="simulate_error"
              phx-value-type="validation"
              class="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
            >
              Validation Error
            </button>
            <button
              phx-click="simulate_error"
              phx-value-type="system"
              class="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600"
            >
              System Error
            </button>
          </div>
        </div>

        <div class="bg-gray-50 p-4 rounded-lg">
          <h2 class="text-lg font-semibold mb-3">Test Success Messages</h2>
          <button
            phx-click="simulate_success"
            class="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
          >
            Success Message
          </button>
        </div>

        <div class="bg-gray-50 p-4 rounded-lg">
          <h2 class="text-lg font-semibold mb-3">Clear Messages</h2>
          <button
            phx-click="clear_flash"
            class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
          >
            Clear All Flash Messages
          </button>
        </div>
      </div>

      <div class="mt-8 p-4 bg-blue-50 rounded-lg">
        <h3 class="font-semibold text-blue-800 mb-2">How to Use Error Handling:</h3>
        <ul class="text-sm text-blue-700 space-y-1">
          <li>• Use <code>ErrorHandler.handle_error/2</code> to process errors</li>
          <li>• Use <code>ErrorHelpers.put_error_flash/3</code> in LiveView</li>
          <li>• Use <code>Validation</code> module functions for form validation</li>
          <li>• All errors are logged with appropriate severity levels</li>
        </ul>
      </div>
    </div>
    """
  end
end
