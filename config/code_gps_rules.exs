# Code GPS Integration Rules
#
# This file defines the rules for the suggestion engine. The engine will process
# these rules against the codebase analysis to generate integration hints.

[
  # Rule to ensure the Dashboard displays expense data.
  %{
    name: :expense_dashboard_integration,
    description: "Dashboard missing expense data integration",
    priority: "high",
    # Condition: This rule applies if a LiveView matching `DashboardLive` is found
    # and it does not have a PubSub subscription for the `expenses` topic.
    condition: %{
      live_view: "DashboardLive",
      missing_subscription: "expenses"
    },
    # Suggestion: The steps to take to fix the missing integration.
    suggestion: %{
      steps: [
        %{
          action: "Add PubSub subscription",
          type: :add_pubsub_subscription,
          topic: "expenses",
          target_module_slug: "dashboard_live"
        },
        %{
          action: "Load expense summary on mount",
          type: :add_to_function,
          function: :load_portfolio_data,
          code: "|> load_expense_summary()",
          target_module_slug: "dashboard_live"
        },
        %{
          action: "Add expense widget to render block",
          type: :add_to_render,
          component: "expense_summary_card",
          target_module_slug: "dashboard_live"
        }
      ]
    }
  },

  # Rule to ensure the Dashboard has a manual net worth snapshot button.
  %{
    name: :net_worth_snapshot_integration,
    description: "Add manual net worth snapshot button",
    priority: "medium",
    # Condition: This rule applies if a LiveView matching `DashboardLive` is found
    # and it does not handle the `create_snapshot` event.
    condition: %{
      live_view: "DashboardLive",
      missing_event: "create_snapshot"
    },
    # Suggestion: The steps to take to fix the missing integration.
    suggestion: %{
      steps: [
        %{
          action: "Add event handler for snapshot creation",
          type: :add_function,
          code: """
          def handle_event(\"create_snapshot\", _params, socket) do
            %{manual: true}
            |> Ashfolio.Workers.NetWorthSnapshotWorker.new()
            |> Oban.insert()

            {:noreply, put_flash(socket, :info, \"Creating snapshot...\")}
          end
          """,
          target_module_slug: "dashboard_live"
        }
      ]
    }
  }
]
