defmodule AshfolioWeb.ExpenseLive.Import do
  @moduledoc false
  use AshfolioWeb, :live_view

  alias Ashfolio.FinancialManagement.Expense
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Portfolio.Account
  alias Ashfolio.Portfolio.Symbol
  alias Ashfolio.Portfolio.Transaction

  @impl true
  def mount(_params, _session, socket) do
    categories = TransactionCategory.list!()
    accounts = Account.list!()

    {:ok,
     socket
     |> assign_current_page(:expenses)
     |> assign(:page_title, "Import Expenses")
     |> assign(:import_type, :expenses)
     |> assign(:uploaded_files, [])
     |> assign(:csv_data, nil)
     |> assign(:preview_data, [])
     |> assign(:column_mapping, %{})
     |> assign(:category_mapping, %{})
     |> assign(:validation_errors, [])
     |> assign(:duplicate_warnings, [])
     |> assign(:import_step, :upload)
     |> assign(:existing_categories, categories)
     |> assign(:accounts, accounts)
     |> allow_upload(:csv_file, accept: ~w(.csv), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_import_type", %{"import_type" => type}, socket) do
    import_type = String.to_existing_atom(type)
    title = if import_type == :expenses, do: "Import Expenses", else: "Import Portfolio Holdings"

    {:noreply,
     socket
     |> assign(:import_type, import_type)
     |> assign(:page_title, title)
     |> assign(:import_step, :upload)
     |> assign(:preview_data, [])}
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

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate_import", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("import", params, socket) do
    account_id = params["account_id"]
    category_mapping = params["category_mapping"] || %{}

    if account_id && account_id != "" do
      result =
        case socket.assigns.import_type do
          :expenses ->
            import_expenses(socket.assigns.preview_data, account_id, category_mapping)

          :holdings ->
            import_portfolio_holdings(socket.assigns.preview_data, account_id)
        end

      case result do
        {:ok, count} ->
          type_name = if socket.assigns.import_type == :expenses, do: "expenses", else: "holdings"

          redirect_path =
            if socket.assigns.import_type == :expenses,
              do: ~p"/expenses",
              else: ~p"/accounts/#{account_id}"

          {:noreply,
           socket
           |> put_flash(:info, "Successfully imported #{count} #{type_name}!")
           |> redirect(to: redirect_path)}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Import failed: #{reason}")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please select an account for import")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6">
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4 border-b border-gray-200">
          <h1 class="text-xl font-semibold text-gray-900">{@page_title}</h1>
          <p class="mt-1 text-sm text-gray-600">
            <%= if @import_type == :expenses do %>
              Upload a CSV file containing your expense transactions (Date, Description, Amount, Category)
            <% else %>
              Upload a CSV file containing your portfolio holdings (Ticker, Description, Quantity, Asset Class)
            <% end %>
          </p>
        </div>

        <div class="p-6">
          <%= if @import_step == :upload do %>
            <!-- Import Type Selection -->
            <div class="mb-6">
              <label class="block text-sm font-medium text-gray-700 mb-3">
                What type of data are you importing?
              </label>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <button
                  phx-click="select_import_type"
                  phx-value-import_type="expenses"
                  class={"p-4 border-2 rounded-lg text-left hover:bg-gray-50 #{if @import_type == :expenses, do: "border-blue-500 bg-blue-50", else: "border-gray-300"}"}
                >
                  <div class="font-medium">Expenses</div>
                  <div class="text-sm text-gray-600">
                    Bank transactions, credit card statements
                  </div>
                  <div class="text-xs text-gray-500 mt-1">
                    Format: Date, Description, Amount, Category
                  </div>
                </button>
                <button
                  phx-click="select_import_type"
                  phx-value-import_type="holdings"
                  class={"p-4 border-2 rounded-lg text-left hover:bg-gray-50 #{if @import_type == :holdings, do: "border-blue-500 bg-blue-50", else: "border-gray-300"}"}
                >
                  <div class="font-medium">Portfolio Holdings</div>
                  <div class="text-sm text-gray-600">
                    Investment positions, stock holdings
                  </div>
                  <div class="text-xs text-gray-500 mt-1">
                    Format: Ticker, Description, Quantity, Asset Class
                  </div>
                </button>
              </div>
            </div>
            
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
                  {length(@preview_data)} expenses found
                </p>
              </div>
              
    <!-- Column Mapping Controls -->
              <div class="bg-gray-50 p-4 rounded-lg">
                <h4 class="text-md font-medium text-gray-900 mb-3">Column Mapping</h4>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Date Column</label>
                    <select
                      name="column_mapping[date]"
                      class="mt-1 block w-full border-gray-300 rounded-md"
                    >
                      <option>Date</option>
                    </select>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Description Column</label>
                    <select
                      name="column_mapping[description]"
                      class="mt-1 block w-full border-gray-300 rounded-md"
                    >
                      <option>Description</option>
                    </select>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Amount Column</label>
                    <select
                      name="column_mapping[amount]"
                      class="mt-1 block w-full border-gray-300 rounded-md"
                    >
                      <option>Amount</option>
                    </select>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Category Column</label>
                    <select
                      name="column_mapping[category]"
                      class="mt-1 block w-full border-gray-300 rounded-md"
                    >
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
                      <%= if @import_type == :expenses do %>
                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">
                          Date
                        </th>
                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">
                          Description
                        </th>
                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">
                          Amount
                        </th>
                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">
                          Category
                        </th>
                      <% else %>
                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">
                          Ticker
                        </th>
                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">
                          Description
                        </th>
                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">
                          Quantity
                        </th>
                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">
                          Asset Class
                        </th>
                      <% end %>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for row <- Enum.take(@preview_data, 5) do %>
                      <tr>
                        <%= if @import_type == :expenses do %>
                          <td class="px-4 py-2 text-sm text-gray-900">
                            {row["Transaction Date"] || row["Date"] || ""}
                          </td>
                          <td class="px-4 py-2 text-sm text-gray-900">
                            {row["Description"] || ""}
                          </td>
                          <td class="px-4 py-2 text-sm text-gray-900 text-right">
                            {row["Amount"] || ""}
                          </td>
                          <td class="px-4 py-2 text-sm text-gray-900">
                            {row["Category"] || ""}
                          </td>
                        <% else %>
                          <td class="px-4 py-2 text-sm text-gray-900 font-mono">
                            {row["Ticker"] || ""}
                          </td>
                          <td class="px-4 py-2 text-sm text-gray-900">
                            {row["Description"] || ""}
                          </td>
                          <td class="px-4 py-2 text-sm text-gray-900 text-right">
                            {row["Quantity"] || ""}
                          </td>
                          <td class="px-4 py-2 text-sm text-gray-900">
                            {row["Asset Class"] || ""}
                          </td>
                        <% end %>
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

                <%= if @existing_categories != [] do %>
                  <div class="space-y-3">
                    <div class="text-sm font-medium text-gray-700">Existing categories:</div>
                    <div class="flex flex-wrap gap-2">
                      <%= for category <- @existing_categories do %>
                        <span class="px-3 py-1 bg-white text-sm rounded-md border">
                          {category.name}
                        </span>
                      <% end %>
                    </div>

                    <div class="text-sm font-medium text-gray-700 mt-4">
                      CSV categories needing mapping:
                    </div>
                    <%= for csv_category <- get_csv_categories(@preview_data) do %>
                      <div class="flex items-center space-x-3 py-2">
                        <span class="text-sm font-medium w-24">{csv_category}</span>
                        <span class="text-sm text-gray-500">→</span>
                        <select
                          name={"category_mapping[#{csv_category}]"}
                          class="text-sm border-gray-300 rounded-md"
                          form="import-form"
                        >
                          <option value="">Select category</option>
                          <%= for category <- @existing_categories do %>
                            <option value={category.id}>{category.name}</option>
                          <% end %>
                        </select>
                      </div>
                    <% end %>
                  </div>
                <% else %>
                  <p class="text-sm text-gray-600">
                    No existing categories. Create some categories first.
                  </p>
                <% end %>
              </div>
              
    <!-- Import Form -->
              <.form
                for={%{}}
                phx-submit="import"
                phx-change="validate_import"
                id="import-form"
                class="space-y-4"
              >
                <!-- Account Selection -->
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    Select Account
                  </label>
                  <select name="account_id" class="block w-full border-gray-300 rounded-md">
                    <option value="">Choose account</option>
                    <%= for account <- @accounts do %>
                      <option value={account.id}>{account.name}</option>
                    <% end %>
                  </select>
                </div>
                
    <!-- Action Buttons -->
                <div class="flex space-x-4">
                  <button
                    type="button"
                    phx-click="import"
                    class="btn-primary"
                  >
                    <%= if @import_type == :expenses do %>
                      Import Expenses
                    <% else %>
                      Import Holdings
                    <% end %>
                  </button>
                  <button
                    type="button"
                    phx-click="cancel"
                    class="btn-secondary"
                  >
                    Cancel
                  </button>
                </div>
              </.form>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp parse_csv_preview(csv_content) do
    # Handle the specific CSV format with proper parsing
    lines = String.split(csv_content, "\n", trim: true)

    case lines do
      [header_line | data_lines] ->
        headers = String.split(header_line, ",")

        Enum.map(data_lines, fn line ->
          values = String.split(line, ",")
          # Pad values if row has fewer columns than headers
          padded_values = values ++ List.duplicate("", length(headers) - length(values))
          headers |> Enum.zip(padded_values) |> Map.new()
        end)

      _ ->
        []
    end
  rescue
    _e ->
      []
  end

  defp get_csv_categories(preview_data) do
    preview_data
    |> Enum.map(fn row -> row["Category"] || row[:category] end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp import_expenses(preview_data, account_id, category_mapping) do
    imported_count =
      preview_data
      |> Enum.filter(&valid_expense_row?/1)
      |> Enum.map(&create_expense_from_row(&1, account_id, category_mapping))
      |> Enum.count(fn result -> match?({:ok, _}, result) end)

    {:ok, imported_count}
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  defp valid_expense_row?(row) do
    description = row["Description"] || ""
    amount_str = row["Amount"] || ""
    date_str = row["Transaction Date"] || row["Date"] || ""

    description != "" && amount_str != "" && date_str != "" &&
      String.match?(amount_str, ~r/^-?\d+(\.\d+)?$/)
  end

  defp create_expense_from_row(row, account_id, category_mapping) do
    # Extract data from CSV row
    description = row["Description"] || ""
    amount_str = row["Amount"] || "0"
    date_str = row["Transaction Date"] || row["Date"] || ""
    csv_category = row["Category"] || ""

    # Parse amount (remove negative sign for expenses)
    {amount_float, _} = Float.parse(amount_str)
    amount = Decimal.from_float(abs(amount_float))

    # Parse date
    date = parse_date(date_str)

    # Map category
    category_id = find_or_create_category(csv_category, category_mapping)

    # Create expense
    expense_params = %{
      description: description,
      amount: amount,
      date: date,
      account_id: account_id,
      category_id: category_id,
      notes: "Imported from CSV"
    }

    Expense.create(expense_params)
  end

  defp parse_date(date_str) do
    # Handle MM/DD/YYYY format from Chase CSV
    case String.split(date_str, "/") do
      [month, day, year] ->
        {:ok, date} =
          Date.new(String.to_integer(year), String.to_integer(month), String.to_integer(day))

        date

      _ ->
        Date.utc_today()
    end
  end

  defp find_or_create_category(csv_category_name, category_mapping) do
    # First check if there's a mapping
    case category_mapping[csv_category_name] do
      nil ->
        # No mapping, try to find existing category by name
        find_or_create_category_by_name(csv_category_name)

      category_id ->
        category_id
    end
  end

  defp find_or_create_category_by_name(name) when name == "" or is_nil(name) do
    nil
  end

  defp find_or_create_category_by_name(name) do
    case TransactionCategory.get_by_name(name) do
      {:ok, category} ->
        category.id

      {:error, _} ->
        # Create new category
        case TransactionCategory.create(%{
               name: name,
               color: "#6B7280"
             }) do
          {:ok, category} -> category.id
          {:error, _} -> nil
        end
    end
  end

  # Portfolio Holdings Import Functions
  defp import_portfolio_holdings(preview_data, account_id) do
    imported_count =
      preview_data
      |> Enum.filter(&valid_holding_row?/1)
      |> Enum.map(&create_transaction_from_holding(&1, account_id))
      |> Enum.count(fn result -> match?({:ok, _}, result) end)

    {:ok, imported_count}
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  defp valid_holding_row?(row) do
    ticker = row["Ticker"] || ""
    quantity = row["Quantity"] || ""

    ticker != "" && quantity != "" &&
      String.match?(quantity, ~r/^\d+(\.\d+)?$/)
  end

  defp create_transaction_from_holding(row, account_id) do
    # Extract data from CSV row
    ticker = row["Ticker"] || ""
    quantity_str = row["Quantity"] || "0"
    description = row["Description"] || ticker

    # Parse quantity
    {quantity, _} = Float.parse(quantity_str)

    # Find or create symbol
    symbol_id = find_or_create_symbol(ticker, description)

    # Create buy transaction for this holding
    transaction_params = %{
      account_id: account_id,
      symbol_id: symbol_id,
      transaction_type: :buy,
      quantity: Decimal.from_float(quantity),
      # Default price - user can edit later
      price: Decimal.new("1.00"),
      transaction_date: Date.utc_today(),
      notes: "Imported from CSV: #{description}"
    }

    Transaction.create(transaction_params)
  end

  defp find_or_create_symbol(ticker, description) do
    case Symbol.find_by_symbol(ticker) do
      {:ok, symbol} ->
        symbol.id

      {:error, _} ->
        # Create new symbol
        symbol_params = %{
          symbol: ticker,
          name: description,
          # Default to stock
          asset_class: :stock,
          data_source: :manual
        }

        case Symbol.create(symbol_params) do
          {:ok, symbol} -> symbol.id
          {:error, _} -> nil
        end
    end
  end
end
