defmodule AshfolioWeb.MoneyRatiosLive.FormComponent do
  @moduledoc false
  use AshfolioWeb, :live_component

  alias Ashfolio.FinancialManagement.FinancialProfile

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg">
      <.form
        for={@form}
        as={:financial_profile}
        id="financial-profile-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="p-6 space-y-6 max-h-[60vh] overflow-y-auto">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Income Information -->
            <div class="space-y-4">
              <h3 class="text-lg font-medium text-gray-900">Income Information</h3>

              <.input
                field={@form[:gross_annual_income]}
                type="number"
                label="Gross Annual Income"
                step="1000"
                min="0"
                placeholder="100000"
                required
              />

              <.input
                field={@form[:birth_year]}
                type="number"
                label="Birth Year"
                min="1900"
                max={Date.utc_today().year}
                placeholder="1985"
                required
              />

              <.input
                field={@form[:household_members]}
                type="number"
                label="Household Members"
                min="1"
                max="10"
                placeholder="1"
              />
            </div>
            
    <!-- Assets & Debts -->
            <div class="space-y-4">
              <h3 class="text-lg font-medium text-gray-900">Assets & Debts</h3>

              <.input
                field={@form[:primary_residence_value]}
                type="number"
                label="Primary Residence Value (Optional)"
                step="1000"
                min="0"
                placeholder="300000"
              />

              <.input
                field={@form[:mortgage_balance]}
                type="number"
                label="Mortgage Balance (Optional)"
                step="1000"
                min="0"
                placeholder="200000"
              />

              <.input
                field={@form[:student_loan_balance]}
                type="number"
                label="Student Loan Balance (Optional)"
                step="1000"
                min="0"
                placeholder="25000"
              />
            </div>
          </div>
        </div>
        
    <!-- Form Actions - Outside scrollable area -->
        <div class="flex items-center justify-end space-x-3 p-6 border-t border-gray-200 bg-gray-50">
          <.button
            type="submit"
            phx-disable-with="Saving..."
            class="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-md"
          >
            {if @action == :new, do: "Create Profile", else: "Update Profile"}
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{financial_profile: financial_profile, action: action} = assigns, socket) do
    form =
      case {financial_profile, action} do
        {nil, :new} ->
          FinancialProfile |> AshPhoenix.Form.for_create(:create) |> to_form()

        {profile, :edit} ->
          profile |> AshPhoenix.Form.for_update(:update) |> to_form()
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, form)}
  end

  @impl true
  def handle_event("validate", %{"form" => profile_params}, socket) do
    # Handle form parameters with "form" key - delegate to financial_profile handler
    handle_event("validate", %{"financial_profile" => profile_params}, socket)
  end

  @impl true
  def handle_event("save", %{"form" => profile_params}, socket) do
    # Handle form parameters with "form" key - delegate to financial_profile handler
    handle_event("save", %{"financial_profile" => profile_params}, socket)
  end

  @impl true
  def handle_event("validate", %{"financial_profile" => financial_profile_params}, socket) do
    form = socket.assigns.form |> AshPhoenix.Form.validate(financial_profile_params) |> to_form()
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"financial_profile" => financial_profile_params}, socket) do
    save_financial_profile(socket, socket.assigns.action, financial_profile_params)
  end

  defp save_financial_profile(socket, _action, financial_profile_params) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: financial_profile_params) do
      {:ok, financial_profile} ->
        notify_parent({:saved, financial_profile})
        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
