defmodule AshfolioWeb.FinancialGoalLive.FormComponent do
  @moduledoc false
  use AshfolioWeb, :live_component

  alias Ashfolio.Financial.Formatters
  alias Ashfolio.FinancialManagement.FinancialGoal
  alias AshfolioWeb.Live.ErrorHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
      <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] flex flex-col">
        <!-- Fixed Header -->
        <div class="flex justify-between items-center p-6 pb-4 border-b border-gray-200">
          <h3 class="text-lg font-medium text-gray-900">
            {if @action == :new, do: "Add Financial Goal", else: "Edit Financial Goal"}
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
        
    <!-- Scrollable Content Area -->
        <div class="flex-1 overflow-y-auto px-6 py-4">
          <!-- Form-level error display -->
          <div :if={@form_errors != []} class="mb-4">
            <ErrorHelpers.error_list
              errors={@form_errors}
              title="Please correct the following errors:"
            />
          </div>
          
    <!-- Emergency Fund Quick Setup -->
          <%= if @action == :new && @show_emergency_fund_setup do %>
            <div class="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <h4 class="text-sm font-medium text-blue-900 mb-3">Quick Emergency Fund Setup</h4>
              <%= if @emergency_fund_suggestion do %>
                <div class="space-y-3">
                  <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-sm">
                    <div>
                      <span class="text-blue-800 font-medium">Monthly Expenses:</span>
                      <div class="text-blue-700">
                        {Formatters.format_currency_with_cents(
                          @emergency_fund_suggestion.monthly_expenses
                        )}
                      </div>
                    </div>
                    <div>
                      <span class="text-blue-800 font-medium">Suggested Target:</span>
                      <div class="text-blue-700">
                        {Formatters.format_currency_with_cents(
                          @emergency_fund_suggestion.recommended_target
                        )}
                      </div>
                    </div>
                    <div>
                      <span class="text-blue-800 font-medium">Coverage:</span>
                      <div class="text-blue-700">6 months</div>
                    </div>
                  </div>
                  <button
                    type="button"
                    phx-click="use_emergency_fund_template"
                    phx-target={@myself}
                    class="btn-primary text-sm"
                  >
                    Use Emergency Fund Template
                  </button>
                </div>
              <% else %>
                <p class="text-sm text-blue-700">Loading emergency fund calculations...</p>
              <% end %>
            </div>
          <% end %>

          <.simple_form
            for={@form}
            id="financial-goal-form"
            phx-target={@myself}
            phx-change="validate"
            phx-submit="save"
          >
            <!-- Goal Name -->
            <.input
              field={@form[:name]}
              type="text"
              label="Goal Name"
              required
              placeholder="e.g., Emergency Fund, Vacation to Japan"
              disabled={@saving}
            />
            
    <!-- Goal Type -->
            <.input
              field={@form[:goal_type]}
              type="select"
              label="Goal Type"
              required
              options={goal_type_options()}
              disabled={@saving}
            />
            
    <!-- Description -->
            <.input
              field={@form[:description]}
              type="textarea"
              label="Description"
              placeholder="Describe your goal and why it matters to you (optional)"
              disabled={@saving}
            />

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Current Amount -->
              <.input
                field={@form[:current_amount]}
                type="number"
                label="Current Amount"
                required
                step="0.01"
                min="0"
                placeholder="0.00"
                disabled={@saving}
              />
              
    <!-- Target Amount -->
              <.input
                field={@form[:target_amount]}
                type="number"
                label="Target Amount"
                required
                step="0.01"
                min="0.01"
                placeholder="0.00"
                disabled={@saving}
              />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Target Date -->
              <.input
                field={@form[:target_date]}
                type="date"
                label="Target Date"
                placeholder="When do you want to achieve this goal?"
                disabled={@saving}
              />
              
    <!-- Monthly Contribution -->
              <.input
                field={@form[:monthly_contribution_amount]}
                type="number"
                label="Monthly Contribution"
                step="0.01"
                min="0"
                placeholder="0.00"
                disabled={@saving}
              />
            </div>
            
    <!-- Goal Progress Calculation Display -->
            <%= if @goal_calculations do %>
              <div class="mt-6 p-4 bg-gray-50 rounded-lg">
                <h4 class="text-sm font-medium text-gray-900 mb-3">Goal Analysis</h4>
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-sm">
                  <div>
                    <span class="text-gray-600 font-medium">Progress:</span>
                    <div class="text-gray-900">
                      {Formatters.format_percentage(@goal_calculations.progress_percentage)}%
                    </div>
                  </div>
                  <div>
                    <span class="text-gray-600 font-medium">Remaining:</span>
                    <div class="text-gray-900">
                      {Formatters.format_currency_with_cents(@goal_calculations.amount_remaining)}
                    </div>
                  </div>
                  <%= if @goal_calculations.months_to_goal do %>
                    <div>
                      <span class="text-gray-600 font-medium">Time Left:</span>
                      <div class="text-gray-900">
                        {format_months(@goal_calculations.months_to_goal)} months
                      </div>
                    </div>
                  <% end %>
                </div>

                <%= if @monthly_contribution_needed do %>
                  <div class="mt-3 p-3 bg-blue-50 rounded border border-blue-200">
                    <p class="text-sm text-blue-800">
                      <strong>Recommended monthly contribution:</strong>
                      {Formatters.format_currency_with_cents(@monthly_contribution_needed)} to reach your goal by the target date.
                    </p>
                  </div>
                <% end %>
              </div>
            <% end %>
            
    <!-- Active Status -->
            <div class="flex items-center">
              <.input
                field={@form[:is_active]}
                type="checkbox"
                label="Active goal"
                disabled={@saving}
              />
              <div class="ml-3">
                <p class="text-sm text-gray-600">
                  Active goals appear in dashboard widgets and analytics
                </p>
              </div>
            </div>
          </.simple_form>
        </div>
        
    <!-- Fixed Footer -->
        <div class="border-t border-gray-200 px-6 py-4">
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
              form="financial-goal-form"
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
                  class="animate-spin -ml-1 mr-2 h-4 w-4 text-gray-400"
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
                Saving...
              <% else %>
                {if @action == :new, do: "Create Goal", else: "Update Goal"}
              <% end %>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{goal: goal, action: action}, socket) do
    # Set up initial state
    socket =
      socket
      |> assign(:action, action)
      |> assign(:goal, goal)
      |> assign(:saving, false)
      |> assign(:form_valid, false)
      |> assign(:form_errors, [])
      |> assign(:goal_calculations, nil)
      |> assign(:monthly_contribution_needed, nil)
      |> assign(:show_emergency_fund_setup, action == :new)
      |> assign(:emergency_fund_suggestion, nil)

    # Load emergency fund analysis if creating new goal
    socket =
      if action == :new do
        case FinancialGoal.analyze_emergency_fund_readiness!() do
          {:analysis, analysis} -> assign(socket, :emergency_fund_suggestion, analysis)
          {:no_goal, recommendation} -> assign(socket, :emergency_fund_suggestion, recommendation)
          {:error, _} -> assign(socket, :emergency_fund_suggestion, nil)
        end
      else
        socket
      end

    # Initialize form using AshPhoenix.Form pattern
    form =
      case action do
        :new ->
          AshPhoenix.Form.for_create(FinancialGoal, :create)

        :edit ->
          AshPhoenix.Form.for_update(goal, :update)
      end

    socket = assign_form(socket, form)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"financial_goal" => goal_params}, socket) do
    # Parse decimal fields
    goal_params = parse_decimal_fields(goal_params)

    # Validate using AshPhoenix.Form
    form = AshPhoenix.Form.validate(socket.assigns.form, goal_params)

    form_valid = form.valid?
    form_errors = if form_valid, do: [], else: format_errors(form)

    socket =
      socket
      |> assign_form(form)
      |> assign(:form_valid, form_valid)
      |> assign(:form_errors, form_errors)

    # Calculate goal analytics if we have valid target and current amounts
    socket = update_goal_calculations(socket, goal_params)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"form" => goal_params}, socket) do
    # Handle form parameters with "form" key - delegate to financial_goal handler
    handle_event("validate", %{"financial_goal" => goal_params}, socket)
  end

  @impl true
  def handle_event("save", %{"financial_goal" => goal_params}, socket) do
    socket = assign(socket, :saving, true)

    goal_params = parse_decimal_fields(goal_params)

    case AshPhoenix.Form.submit(socket.assigns.form, params: goal_params) do
      {:ok, goal} ->
        # Notify parent component
        send(self(), {__MODULE__, {:saved, goal}})

        # Publish PubSub event
        Ashfolio.PubSub.broadcast("financial_goals", {:financial_goal_saved, goal})

        {:noreply, assign(socket, :saving, false)}

      {:error, form} ->
        form_errors = format_errors(form)

        {:noreply,
         socket
         |> assign(:saving, false)
         |> assign(:form_errors, form_errors)
         |> assign_form(form)}
    end
  end

  @impl true
  def handle_event("save", %{"form" => goal_params}, socket) do
    # Handle form parameters with "form" key - delegate to financial_goal handler
    handle_event("save", %{"financial_goal" => goal_params}, socket)
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    send(self(), {__MODULE__, :cancelled})
    {:noreply, socket}
  end

  @impl true
  def handle_event("use_emergency_fund_template", _params, socket) do
    case socket.assigns.emergency_fund_suggestion do
      nil ->
        {:noreply, socket}

      suggestion ->
        goal_params = %{
          "name" => "Emergency Fund (6 months)",
          "goal_type" => "emergency_fund",
          "description" => "Emergency fund to cover 6 months of expenses for financial security",
          "target_amount" => Decimal.to_string(suggestion.recommended_target),
          "current_amount" => "0.00",
          "is_active" => true
        }

        form = AshPhoenix.Form.for_create(FinancialGoal, :create)
        validated_form = AshPhoenix.Form.validate(form, parse_decimal_fields(goal_params))

        form_valid = validated_form.valid?
        form_errors = if form_valid, do: [], else: format_errors(validated_form)

        socket =
          socket
          |> assign_form(validated_form)
          |> assign(:form_valid, form_valid)
          |> assign(:form_errors, form_errors)
          |> assign(:show_emergency_fund_setup, false)
          |> update_goal_calculations(goal_params)

        {:noreply, socket}
    end
  end

  # Private functions

  defp assign_form(socket, form) do
    # Expect AshPhoenix.Form - no conversion needed
    assign(socket, :form, to_form(form, as: :financial_goal))
  end

  defp parse_decimal_fields(params) do
    params
    |> parse_decimal_field("target_amount")
    |> parse_decimal_field("current_amount")
    |> parse_decimal_field("monthly_contribution_amount")
  end

  defp parse_decimal_field(params, field) do
    case Map.get(params, field) do
      value when is_binary(value) and value != "" ->
        case Decimal.parse(value) do
          {decimal_value, ""} -> Map.put(params, field, decimal_value)
          _ -> params
        end

      _ ->
        params
    end
  end

  defp format_errors(form_or_changeset) do
    errors =
      case form_or_changeset do
        %AshPhoenix.Form{} = form -> AshPhoenix.Form.errors(form)
        %Phoenix.HTML.Form{} = form -> form.errors
      end

    errors
    |> Ash.Error.to_error_class()
    |> case do
      %{errors: errors} -> Enum.map(errors, &to_string/1)
      error -> [to_string(error)]
    end
  end

  defp update_goal_calculations(socket, goal_params) do
    with target_amount when target_amount != "" <- Map.get(goal_params, "target_amount"),
         current_amount when current_amount != "" <- Map.get(goal_params, "current_amount"),
         {:ok, target_decimal} <- parse_decimal_safe(target_amount),
         {:ok, current_decimal} <- parse_decimal_safe(current_amount) do
      # Calculate basic goal metrics
      amount_remaining = Decimal.sub(target_decimal, current_decimal)

      progress_percentage =
        if Decimal.gt?(target_decimal, Decimal.new("0")) do
          current_decimal
          |> Decimal.div(target_decimal)
          |> Decimal.mult(Decimal.new("100"))
        else
          Decimal.new("0")
        end

      calculations = %{
        progress_percentage: progress_percentage,
        amount_remaining: amount_remaining,
        months_to_goal: calculate_months_to_goal(goal_params)
      }

      monthly_needed = calculate_monthly_contribution_needed(goal_params, amount_remaining)

      socket
      |> assign(:goal_calculations, calculations)
      |> assign(:monthly_contribution_needed, monthly_needed)
    else
      _ ->
        socket
        |> assign(:goal_calculations, nil)
        |> assign(:monthly_contribution_needed, nil)
    end
  end

  defp parse_decimal_safe(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, ""} -> {:ok, decimal}
      _ -> :error
    end
  end

  defp parse_decimal_safe(%Decimal{} = value), do: {:ok, value}
  defp parse_decimal_safe(_), do: :error

  defp calculate_months_to_goal(goal_params) do
    case Map.get(goal_params, "target_date") do
      target_date when is_binary(target_date) and target_date != "" ->
        calculate_months_from_date(target_date)

      _ ->
        nil
    end
  end

  defp calculate_months_from_date(target_date) do
    case Date.from_iso8601(target_date) do
      {:ok, date} ->
        days_to_goal(date)

      _ ->
        nil
    end
  end

  defp days_to_goal(date) do
    today = Date.utc_today()

    case Date.diff(date, today) do
      days when days > 0 -> Decimal.new(div(days, 30))
      _ -> Decimal.new("0")
    end
  end

  defp calculate_monthly_contribution_needed(goal_params, amount_remaining) do
    with months_to_goal when not is_nil(months_to_goal) <- calculate_months_to_goal(goal_params),
         true <- Decimal.gt?(months_to_goal, Decimal.new("0")),
         true <- Decimal.gt?(amount_remaining, Decimal.new("0")) do
      Decimal.div(amount_remaining, months_to_goal)
    else
      _ -> nil
    end
  end

  defp goal_type_options do
    [
      {"Emergency Fund", :emergency_fund},
      {"Retirement", :retirement},
      {"House Down Payment", :house_down_payment},
      {"Vacation", :vacation},
      {"Custom Goal", :custom}
    ]
  end

  defp format_months(decimal_months) when is_nil(decimal_months), do: "N/A"

  defp format_months(decimal_months) do
    decimal_months
    |> Decimal.round(1)
    |> Decimal.to_string()
  end
end
