defmodule AshfolioWeb.FinancialGoalLive.Index do
  @moduledoc false
  use AshfolioWeb, :live_view

  alias Ashfolio.FinancialManagement.EmergencyFundStatus
  alias Ashfolio.FinancialManagement.FinancialGoal
  alias AshfolioWeb.FinancialGoalLive.FormComponent
  alias AshfolioWeb.Live.ErrorHelpers
  alias AshfolioWeb.Live.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Ashfolio.PubSub.subscribe("financial_goals")
    end

    socket =
      socket
      |> assign_current_page(:goals)
      |> assign(:page_title, "Financial Goals")
      |> assign(:page_subtitle, "Track your savings and financial objectives")
      |> assign(:goals, [])
      |> assign(:total_target_amount, Decimal.new(0))
      |> assign(:total_current_amount, Decimal.new(0))
      |> assign(:goals_count, 0)
      |> assign(:active_goals_count, 0)
      |> assign(:sort_by, :target_date)
      |> assign(:sort_dir, :asc)
      |> assign(:loading, true)
      |> assign(:show_form, false)
      |> assign(:form_action, nil)
      |> assign(:selected_goal, nil)
      |> assign(:emergency_fund_analysis, nil)
      |> assign(:filter_status, "")
      |> assign(:filter_goal_type, "")
      |> assign(:show_filters, false)

    socket = load_goals_and_analysis(socket)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("sort", %{"sort_by" => sort_by}, socket) do
    sort_by = String.to_existing_atom(sort_by)

    sort_dir =
      if socket.assigns.sort_by == sort_by and socket.assigns.sort_dir == :asc do
        :desc
      else
        :asc
      end

    {:noreply,
     socket
     |> assign(:sort_by, sort_by)
     |> assign(:sort_dir, sort_dir)
     |> load_goals_and_analysis()}
  end

  @impl true
  def handle_event("toggle_filters", _params, socket) do
    {:noreply, assign(socket, :show_filters, !socket.assigns.show_filters)}
  end

  @impl true
  def handle_event("filter", filters, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, filters["status"] || "")
     |> assign(:filter_goal_type, filters["goal_type"] || "")
     |> load_goals_and_analysis()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, "")
     |> assign(:filter_goal_type, "")
     |> load_goals_and_analysis()}
  end

  @impl true
  def handle_event("delete_goal", %{"id" => id}, socket) do
    case FinancialGoal.get_by_id(id) do
      {:ok, goal} ->
        case FinancialGoal.destroy(goal) do
          :ok ->
            {:noreply,
             socket
             |> load_goals_and_analysis()
             |> ErrorHelpers.put_success_flash("Goal \"#{goal.name}\" deleted successfully")}

          {:error, _error} ->
            {:noreply, ErrorHelpers.put_error_flash(socket, "Failed to delete goal")}
        end

      {:error, _} ->
        {:noreply, ErrorHelpers.put_error_flash(socket, "Goal not found")}
    end
  end

  @impl true
  def handle_event("setup_emergency_fund", _params, socket) do
    case FinancialGoal.setup_emergency_fund_goal!(6) do
      {:created, _goal} ->
        {:noreply,
         socket
         |> load_goals_and_analysis()
         |> ErrorHelpers.put_success_flash("Emergency fund goal created successfully")}

      {:updated, _goal} ->
        {:noreply,
         socket
         |> load_goals_and_analysis()
         |> ErrorHelpers.put_success_flash("Emergency fund goal updated successfully")}

      {:error, _error} ->
        {:noreply, ErrorHelpers.put_error_flash(socket, "Failed to create emergency fund goal")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Page Header -->
      <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Financial Goals</h1>
          <p class="text-gray-600">Track your savings and financial objectives</p>
        </div>
        <.link
          patch={~p"/goals/new"}
          class="btn-primary inline-flex items-center"
        >
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Add Goal
        </.link>
      </div>
      
    <!-- Emergency Fund Analysis -->
      <%= if @emergency_fund_analysis do %>
        <div class="bg-white shadow rounded-lg">
          <div class="px-6 py-4 bg-blue-50 border-b border-blue-200">
            <h3 class="text-lg font-medium text-blue-900 flex items-center">
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                />
              </svg>
              Emergency Fund Status
            </h3>
          </div>
          <div class="p-6">
            <.emergency_fund_status analysis={@emergency_fund_analysis} />
          </div>
        </div>
      <% end %>
      
    <!-- Summary Stats -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4 bg-gray-50">
          <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div class="text-center">
              <div class="text-2xl font-bold text-gray-900">
                {@goals_count}
              </div>
              <div class="text-sm text-gray-500">Total Goals</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-blue-600">
                {@active_goals_count}
              </div>
              <div class="text-sm text-gray-500">Active Goals</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-green-600">
                {FormatHelpers.format_currency(@total_current_amount)}
              </div>
              <div class="text-sm text-gray-500">Total Saved</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-purple-600">
                {FormatHelpers.format_currency(@total_target_amount)}
              </div>
              <div class="text-sm text-gray-500">Total Target</div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Filters -->
      <div class="bg-white shadow rounded-lg">
        <div class="p-6">
          <div class="flex flex-col sm:flex-row gap-4 mb-4">
            <button
              type="button"
              phx-click="toggle_filters"
              class={[
                "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium",
                if(@show_filters,
                  do: "bg-blue-50 text-blue-700 border-blue-300",
                  else: "bg-white text-gray-700 hover:bg-gray-50"
                )
              ]}
            >
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.707A1 1 0 013 7V4z"
                />
              </svg>
              Filters
            </button>
          </div>

          <%= if @show_filters do %>
            <div class="border-t border-gray-200 pt-4">
              <form phx-change="filter" phx-submit="filter">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label
                      for="filters_status"
                      class="block text-sm font-medium leading-6 text-zinc-800"
                    >
                      Status
                    </label>
                    <select
                      id="filters_status"
                      name="status"
                      value={@filter_status}
                      class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400"
                    >
                      <option value="">All Statuses</option>
                      <option value="active">Active</option>
                      <option value="paused">Paused</option>
                      <option value="completed">Completed</option>
                    </select>
                  </div>
                  <div>
                    <label
                      for="filters_goal_type"
                      class="block text-sm font-medium leading-6 text-zinc-800"
                    >
                      Goal Type
                    </label>
                    <select
                      id="filters_goal_type"
                      name="goal_type"
                      value={@filter_goal_type}
                      class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400"
                    >
                      <option value="">All Types</option>
                      <option value="emergency_fund">Emergency Fund</option>
                      <option value="retirement">Retirement</option>
                      <option value="house_down_payment">House Down Payment</option>
                      <option value="vacation">Vacation</option>
                      <option value="custom">Custom</option>
                    </select>
                  </div>
                </div>
                <div class="mt-4">
                  <button
                    type="button"
                    phx-click="clear_filters"
                    class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                  >
                    Clear Filters
                  </button>
                </div>
              </form>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Goals Table -->
      <%= if @loading do %>
        <div class="bg-white shadow rounded-lg">
          <div class="text-center py-16 px-6">
            <.loading_spinner class="mx-auto w-8 h-8 text-blue-600 mb-4" />
            <p class="text-gray-500">Loading goals...</p>
          </div>
        </div>
      <% else %>
        <%= if Enum.empty?(@goals) do %>
          <div class="bg-white shadow rounded-lg">
            <div class="text-center py-16 px-6">
              <div class="mx-auto h-16 w-16 text-gray-400 mb-4">
                <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-full h-full">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"
                  />
                </svg>
              </div>
              <h3 class="text-lg font-medium text-gray-900 mb-2">No financial goals yet</h3>
              <p class="text-gray-500 mb-6 max-w-sm mx-auto">
                Start building your financial future by setting up your first savings goal.
              </p>
              <div class="flex flex-col sm:flex-row gap-3 justify-center">
                <%= if @emergency_fund_analysis && @emergency_fund_analysis.status == :no_goal do %>
                  <button
                    type="button"
                    phx-click="setup_emergency_fund"
                    class="btn-primary inline-flex items-center"
                  >
                    <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                      />
                    </svg>
                    Create Emergency Fund
                  </button>
                <% end %>
                <.link
                  patch={~p"/goals/new"}
                  class="btn-secondary inline-flex items-center"
                >
                  <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 4v16m8-8H4"
                    />
                  </svg>
                  Add Custom Goal
                </.link>
              </div>
            </div>
          </div>
        <% else %>
          <div class="bg-white shadow rounded-lg overflow-hidden">
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th
                      phx-click="sort"
                      phx-value-sort_by="name"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    >
                      Goal
                      <%= if @sort_by == :name do %>
                        <span class="ml-1">
                          {if @sort_dir == :asc, do: "↑", else: "↓"}
                        </span>
                      <% end %>
                    </th>
                    <th
                      phx-click="sort"
                      phx-value-sort_by="goal_type"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    >
                      Type
                      <%= if @sort_by == :goal_type do %>
                        <span class="ml-1">
                          {if @sort_dir == :asc, do: "↑", else: "↓"}
                        </span>
                      <% end %>
                    </th>
                    <th
                      phx-click="sort"
                      phx-value-sort_by="current_amount"
                      class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    >
                      Progress
                      <%= if @sort_by == :current_amount do %>
                        <span class="ml-1">
                          {if @sort_dir == :asc, do: "↑", else: "↓"}
                        </span>
                      <% end %>
                    </th>
                    <th
                      phx-click="sort"
                      phx-value-sort_by="target_amount"
                      class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    >
                      Target
                      <%= if @sort_by == :target_amount do %>
                        <span class="ml-1">
                          {if @sort_dir == :asc, do: "↑", else: "↓"}
                        </span>
                      <% end %>
                    </th>
                    <th
                      phx-click="sort"
                      phx-value-sort_by="target_date"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    >
                      Target Date
                      <%= if @sort_by == :target_date do %>
                        <span class="ml-1">
                          {if @sort_dir == :asc, do: "↑", else: "↓"}
                        </span>
                      <% end %>
                    </th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for goal <- @goals do %>
                    <tr class="hover:bg-gray-50">
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div>
                            <div class="text-sm font-medium text-gray-900">{goal.name}</div>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <.goal_type_badge goal_type={goal.goal_type} />
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-right">
                        <div class="text-sm font-medium text-gray-900">
                          {FormatHelpers.format_currency(goal.current_amount)}
                        </div>
                        <div class="text-sm text-gray-500">
                          {FormatHelpers.format_percentage(goal.progress_percentage)}% complete
                        </div>
                        <div class="mt-1">
                          <.progress_bar percentage={goal.progress_percentage} />
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium text-gray-900">
                        {FormatHelpers.format_currency(goal.target_amount)}
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        <%= if goal.target_date do %>
                          <div class="font-medium">
                            {FormatHelpers.format_date(goal.target_date)}
                          </div>
                          <div class={[
                            "text-sm",
                            if(
                              goal.months_to_goal && Decimal.lt?(goal.months_to_goal, Decimal.new(3)),
                              do: "text-orange-600",
                              else: "text-gray-500"
                            )
                          ]}>
                            <%= if goal.months_to_goal do %>
                              {format_months_to_goal(goal.months_to_goal)}
                            <% else %>
                              "No timeline"
                            <% end %>
                          </div>
                        <% else %>
                          <span class="text-gray-400">No target date</span>
                        <% end %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
                        <div class="flex space-x-2 justify-end">
                          <.link
                            patch={~p"/goals/#{goal.id}/edit"}
                            class="btn-secondary text-xs px-2 py-1 inline-flex items-center"
                            title="Edit goal"
                          >
                            <svg
                              class="w-3 h-3 mr-1"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke="currentColor"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                              />
                            </svg>
                            Edit
                          </.link>
                          <button
                            type="button"
                            phx-click="delete_goal"
                            phx-value-id={goal.id}
                            onclick="return confirm('Are you sure you want to delete this goal? This action cannot be undone.')"
                            class="btn-danger text-xs px-2 py-1 inline-flex items-center"
                            title="Delete goal"
                          >
                            <svg
                              class="w-3 h-3 mr-1"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke="currentColor"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                              />
                            </svg>
                            Delete
                          </button>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>

    <!-- Form Modal -->
    <.live_component
      :if={@show_form}
      module={FormComponent}
      id="financial-goal-form"
      action={@form_action}
      goal={@selected_goal}
    />
    """
  end

  # Handle form component messages
  @impl true
  def handle_info({FormComponent, {:saved, goal}}, socket) do
    case socket.assigns.form_action do
      :new ->
        {:noreply,
         socket
         |> assign(:show_form, false)
         |> load_goals_and_analysis()
         |> ErrorHelpers.put_success_flash("Goal \"#{goal.name}\" created successfully")
         |> push_patch(to: ~p"/goals")}

      :edit ->
        {:noreply,
         socket
         |> assign(:show_form, false)
         |> load_goals_and_analysis()
         |> ErrorHelpers.put_success_flash("Goal \"#{goal.name}\" updated successfully")
         |> push_patch(to: ~p"/goals")}
    end
  end

  @impl true
  def handle_info({FormComponent, :cancelled}, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> push_patch(to: ~p"/goals")}
  end

  # Handle PubSub messages
  @impl true
  def handle_info({:financial_goal_saved, _goal}, socket) do
    {:noreply, load_goals_and_analysis(socket)}
  end

  @impl true
  def handle_info({:financial_goal_deleted, _goal_id}, socket) do
    {:noreply, load_goals_and_analysis(socket)}
  end

  # Private functions

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:show_form, false)
    |> assign(:form_action, nil)
    |> assign(:selected_goal, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:show_form, true)
    |> assign(:form_action, :new)
    |> assign(:selected_goal, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    goal =
      case Enum.find(socket.assigns.goals, &(&1.id == id)) do
        nil ->
          case FinancialGoal.get_by_id(id) do
            {:ok, goal} -> goal
            _ -> nil
          end

        goal ->
          goal
      end

    socket
    |> assign(:show_form, true)
    |> assign(:form_action, :edit)
    |> assign(:selected_goal, goal)
  end

  defp load_goals_and_analysis(socket) do
    socket = assign(socket, :loading, true)

    try do
      # Load all goals with calculations
      all_goals =
        FinancialGoal
        |> Ash.Query.for_read(:read)
        |> Ash.Query.load([
          :progress_percentage,
          :months_to_goal,
          :amount_remaining,
          :is_complete
        ])
        |> Ash.read!()

      # Apply filters
      filtered_goals = apply_filters(all_goals, socket.assigns)

      # Apply sorting
      goals = apply_sorting(filtered_goals, socket.assigns.sort_by, socket.assigns.sort_dir)

      # Calculate statistics
      {total_target, total_current, goals_count, active_count} =
        calculate_goal_statistics(all_goals)

      # Load emergency fund analysis
      emergency_analysis =
        case FinancialGoal.analyze_emergency_fund_readiness!() do
          {:analysis, analysis} ->
            # Ensure consistent field names for template
            Map.merge(analysis, %{
              status: analysis.readiness_level,
              current_coverage_months: analysis.months_coverage,
              recommendation: "Emergency fund analysis complete."
            })

          {:no_goal, recommendation} ->
            # Normalize structure to match template expectations
            Map.merge(recommendation, %{
              goal: nil,
              current_amount: Decimal.new("0.00"),
              current_coverage_months: Decimal.new("0.00"),
              recommendation: recommendation.message,
              # Template expects :status field
              status: recommendation.status
            })

          {:error, _} ->
            nil
        end

      socket
      |> assign(:goals, goals)
      |> assign(:total_target_amount, total_target)
      |> assign(:total_current_amount, total_current)
      |> assign(:goals_count, goals_count)
      |> assign(:active_goals_count, active_count)
      |> assign(:emergency_fund_analysis, emergency_analysis)
      |> assign(:loading, false)
    rescue
      error ->
        socket
        |> assign(:loading, false)
        |> ErrorHelpers.put_error_flash("Failed to load goals: #{inspect(error)}")
    end
  end

  defp apply_filters(goals, assigns) do
    goals
    |> apply_status_filter(assigns.filter_status)
    |> apply_goal_type_filter(assigns.filter_goal_type)
  end

  defp apply_status_filter(goals, ""), do: goals

  defp apply_status_filter(goals, "active") do
    Enum.filter(goals, fn goal -> goal.is_active end)
  end

  defp apply_status_filter(goals, "paused") do
    Enum.filter(goals, fn goal -> not goal.is_active end)
  end

  defp apply_status_filter(goals, "completed") do
    Enum.filter(goals, fn goal -> goal.is_complete end)
  end

  defp apply_status_filter(goals, _), do: goals

  defp apply_goal_type_filter(goals, ""), do: goals

  defp apply_goal_type_filter(goals, goal_type) do
    goal_type_atom = String.to_existing_atom(goal_type)
    Enum.filter(goals, fn goal -> goal.goal_type == goal_type_atom end)
  end

  defp apply_sorting(goals, sort_by, sort_dir) do
    Enum.sort_by(
      goals,
      fn goal ->
        case sort_by do
          :name -> goal.name || ""
          :goal_type -> Atom.to_string(goal.goal_type)
          :current_amount -> goal.current_amount
          :target_amount -> goal.target_amount
          :target_date -> goal.target_date || Date.utc_today()
          :progress_percentage -> goal.progress_percentage
          _ -> goal.target_date || Date.utc_today()
        end
      end,
      sort_dir
    )
  end

  defp calculate_goal_statistics(goals) do
    total_target =
      Enum.reduce(goals, Decimal.new(0), fn goal, acc ->
        Decimal.add(acc, goal.target_amount)
      end)

    total_current =
      Enum.reduce(goals, Decimal.new(0), fn goal, acc ->
        Decimal.add(acc, goal.current_amount)
      end)

    goals_count = length(goals)
    active_count = Enum.count(goals, fn goal -> goal.is_active end)

    {total_target, total_current, goals_count, active_count}
  end

  # UI Helper Components

  defp goal_type_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
      goal_type_color(@goal_type)
    ]}>
      {goal_type_label(@goal_type)}
    </span>
    """
  end

  defp goal_type_color(:emergency_fund), do: "bg-red-100 text-red-800"
  defp goal_type_color(:retirement), do: "bg-blue-100 text-blue-800"
  defp goal_type_color(:house_down_payment), do: "bg-green-100 text-green-800"
  defp goal_type_color(:vacation), do: "bg-purple-100 text-purple-800"
  defp goal_type_color(:custom), do: "bg-gray-100 text-gray-800"

  defp goal_type_label(:emergency_fund), do: "Emergency Fund"
  defp goal_type_label(:retirement), do: "Retirement"
  defp goal_type_label(:house_down_payment), do: "House Down Payment"
  defp goal_type_label(:vacation), do: "Vacation"
  defp goal_type_label(:custom), do: "Custom"

  defp progress_bar(assigns) do
    percentage_value = Decimal.to_float(assigns.percentage || Decimal.new(0))
    percentage_capped = min(percentage_value, 100.0)

    assigns = assign(assigns, :percentage_capped, percentage_capped)

    ~H"""
    <div class="w-full bg-gray-200 rounded-full h-2">
      <div
        class={[
          "h-2 rounded-full transition-all duration-300",
          progress_bar_color(@percentage_capped)
        ]}
        style={"width: #{@percentage_capped}%"}
      >
      </div>
    </div>
    """
  end

  defp progress_bar_color(percentage) when percentage >= 100, do: "bg-green-500"
  defp progress_bar_color(percentage) when percentage >= 75, do: "bg-green-400"
  defp progress_bar_color(percentage) when percentage >= 50, do: "bg-blue-500"
  defp progress_bar_color(percentage) when percentage >= 25, do: "bg-yellow-500"
  defp progress_bar_color(_), do: "bg-red-400"

  defp emergency_fund_status(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="text-center">
        <div class="text-3xl font-bold text-gray-900 mb-2">
          {FormatHelpers.format_currency(@analysis.monthly_expenses)}
        </div>
        <div class="text-sm text-gray-600">Monthly Expenses</div>
      </div>

      <%= if @analysis.goal do %>
        <div class="text-center">
          <div class="text-3xl font-bold text-blue-600 mb-2">
            {FormatHelpers.format_currency(@analysis.current_amount)}
          </div>
          <div class="text-sm text-gray-600">Current Emergency Fund</div>
          <div class="text-xs text-gray-500 mt-1">
            {Decimal.to_string(@analysis.current_coverage_months)} months coverage
          </div>
        </div>
      <% end %>

      <div class="text-center">
        <div class={[
          "text-3xl font-bold mb-2",
          status_color(@analysis.status)
        ]}>
          {status_label(@analysis.status)}
        </div>
        <div class="text-sm text-gray-600">Readiness Status</div>
      </div>
    </div>

    <div class="mt-6 p-4 bg-blue-50 rounded-lg">
      <p class="text-sm text-blue-800">{@analysis.recommendation}</p>
    </div>
    """
  end

  defp status_color(status), do: EmergencyFundStatus.status_color(status)
  defp status_label(status), do: EmergencyFundStatus.status_label(status)

  defp format_months_to_goal(nil), do: "No timeline"

  defp format_months_to_goal(months) do
    months_int = Decimal.to_integer(Decimal.round(months, 0))

    cond do
      months_int <= 0 ->
        "Past due"

      months_int == 1 ->
        "1 month left"

      months_int < 12 ->
        "#{months_int} months left"

      true ->
        years = div(months_int, 12)
        remaining_months = rem(months_int, 12)

        if remaining_months == 0 do
          "#{years} year#{if years == 1, do: "", else: "s"} left"
        else
          "#{years}y #{remaining_months}m left"
        end
    end
  end
end
