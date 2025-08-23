defmodule AshfolioWeb.ExpenseLive.Import do
  use AshfolioWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_current_page(:expenses)
     |> assign(:page_title, "Import Expenses")
     |> assign(:uploaded_files, [])
     |> assign(:csv_data, nil)
     |> assign(:preview_data, [])
     |> assign(:column_mapping, %{})
     |> assign(:category_mapping, %{})
     |> assign(:validation_errors, [])
     |> assign(:duplicate_warnings, [])
     |> assign(:import_step, :upload)
     |> allow_upload(:csv_file, accept: ~w(.csv), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("upload", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :csv_file, fn %{path: path}, _entry ->
        csv_content = File.read!(path)
        {:ok, csv_content}
      end)

    case uploaded_files do
      [csv_content] ->
        preview_data = parse_csv_preview(csv_content)
        
        {:noreply,
         socket
         |> assign(:csv_data, csv_content)
         |> assign(:preview_data, preview_data)
         |> assign(:import_step, :preview)}

      [] ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("import", _params, socket) do
    # TODO: Implement actual import logic
    {:noreply, redirect(socket, to: ~p"/expenses")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6">
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4 border-b border-gray-200">
          <h1 class="text-xl font-semibold text-gray-900">Import Expenses</h1>
          <p class="mt-1 text-sm text-gray-600">
            Upload a CSV file to import your expenses in bulk
          </p>
        </div>

        <div class="p-6">
          <%= if @import_step == :upload do %>
            <!-- File Upload Step -->
            <.form
              for={%{}}
              phx-submit="upload"
              phx-change="validate"
              id="upload-form"
              class="space-y-4"
            >
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Select CSV File
                </label>
                <.live_file_input
                  upload={@uploads.csv_file}
                  class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
                />
              </div>

              <button
                type="submit"
                class="btn-primary"
                disabled={length(@uploads.csv_file.entries) == 0}
              >
                Upload CSV
              </button>
            </.form>

          <% else %>
            <!-- Preview Step -->
            <div class="space-y-6">
              <div>
                <h3 class="text-lg font-medium text-gray-900">Preview & Map Columns</h3>
                <p class="text-sm text-gray-600">
                  <%= length(@preview_data) %> expenses found
                </p>
              </div>

              <!-- Column Mapping Controls -->
              <div class="bg-gray-50 p-4 rounded-lg">
                <h4 class="text-md font-medium text-gray-900 mb-3">Column Mapping</h4>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Date Column</label>
                    <select name="column_mapping[date]" class="mt-1 block w-full border-gray-300 rounded-md">
                      <option>Date</option>
                    </select>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Description Column</label>
                    <select name="column_mapping[description]" class="mt-1 block w-full border-gray-300 rounded-md">
                      <option>Description</option>
                    </select>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Amount Column</label>
                    <select name="column_mapping[amount]" class="mt-1 block w-full border-gray-300 rounded-md">
                      <option>Amount</option>
                    </select>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Category Column</label>
                    <select name="column_mapping[category]" class="mt-1 block w-full border-gray-300 rounded-md">
                      <option>Category</option>
                    </select>
                  </div>
                </div>
              </div>

              <!-- Preview Data Table -->
              <div class="bg-white border rounded-lg overflow-hidden">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                      <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Description</th>
                      <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Amount</th>
                      <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Category</th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for row <- Enum.take(@preview_data, 5) do %>
                      <tr>
                        <td class="px-4 py-2 text-sm text-gray-900"><%= row["Date"] || row[:date] %></td>
                        <td class="px-4 py-2 text-sm text-gray-900"><%= row["Description"] || row[:description] %></td>
                        <td class="px-4 py-2 text-sm text-gray-900"><%= row["Amount"] || row[:amount] %></td>
                        <td class="px-4 py-2 text-sm text-gray-900"><%= row["Category"] || row[:category] %></td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>

              <!-- Category Mapping Section -->
              <div class="bg-blue-50 p-4 rounded-lg">
                <h4 class="text-md font-medium text-gray-900 mb-3">Map Categories</h4>
                <p class="text-sm text-gray-600 mb-3">
                  Map CSV categories to existing categories in your system
                </p>
                <!-- Category mapping will be added here -->
              </div>

              <!-- Action Buttons -->
              <div class="flex space-x-4">
                <button
                  phx-click="import"
                  class="btn-primary"
                  id="import-form"
                >
                  Import Expenses
                </button>
                <button
                  phx-click="cancel"
                  class="btn-secondary"
                >
                  Cancel
                </button>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp parse_csv_preview(csv_content) do
    try do
      csv_content
      |> String.split("\n")
      |> Enum.reject(&(&1 == "" || String.trim(&1) == ""))
      |> CSV.decode(headers: true)
      |> Enum.to_list()
    rescue
      _ -> []
    end
  end
end