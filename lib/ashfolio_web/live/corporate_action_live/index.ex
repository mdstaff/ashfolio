defmodule AshfolioWeb.CorporateActionLive.Index do
  @moduledoc false
  use AshfolioWeb, :live_view

  alias Ashfolio.Portfolio.{CorporateAction, Symbol}
  alias Ashfolio.Portfolio.Services.CorporateActionApplier
  alias AshfolioWeb.CorporateActionLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    # Load all corporate actions
    corporate_actions = list_corporate_actions()
    symbols = list_symbols()

    socket =
      socket
      |> assign_current_page(:corporate_actions)
      |> assign(:page_title, "Corporate Actions")
      |> assign(:page_subtitle, "Manage stock splits, dividends, and other corporate actions")
      |> assign(:corporate_actions, corporate_actions)
      |> assign(:symbols, symbols)
      |> assign(:show_form, false)
      |> assign(:form_action, :new)
      |> assign(:selected_action, nil)
      |> assign(:filter_status, :all)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Corporate Actions")
    |> assign(:show_form, false)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Corporate Action")
    |> assign(:show_form, true)
    |> assign(:form_action, :new)
    |> assign(:selected_action, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    case Ash.get(CorporateAction, id, domain: Ashfolio.Portfolio) do
      {:ok, action} ->
        socket
        |> assign(:page_title, "Edit Corporate Action")
        |> assign(:show_form, true)
        |> assign(:form_action, :edit)
        |> assign(:selected_action, action)

      {:error, _} ->
        socket
        |> put_flash(:error, "Corporate action not found")
        |> push_navigate(to: ~p"/corporate-actions")
    end
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    filter_status = String.to_existing_atom(status)
    filtered_actions = filter_actions_by_status(socket.assigns.corporate_actions, filter_status)

    {:noreply,
     socket
     |> assign(:filter_status, filter_status)
     |> assign(:filtered_actions, filtered_actions)}
  end

  def handle_event("apply_action", %{"id" => id}, socket) do
    case Ash.get(CorporateAction, id, domain: Ashfolio.Portfolio) do
      {:ok, action} ->
        case CorporateActionApplier.apply_corporate_action(action) do
          {:ok, result} ->
            {:noreply,
             socket
             |> put_flash(:info, "Applied corporate action. Created #{result.adjustments_created} adjustments.")
             |> assign(:corporate_actions, list_corporate_actions())}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Failed to apply: #{reason}")}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Corporate action not found")}
    end
  end

  def handle_event("preview_action", %{"id" => id}, socket) do
    case Ash.get(CorporateAction, id, domain: Ashfolio.Portfolio) do
      {:ok, action} ->
        case CorporateActionApplier.preview_application(action) do
          {:ok, preview} ->
            {:noreply,
             socket
             |> put_flash(:info, "Preview: Would affect #{preview.affected_transactions} transactions, creating #{preview.estimated_adjustments} adjustments.")}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Preview failed: #{reason}")}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Corporate action not found")}
    end
  end

  def handle_event("reverse_action", %{"id" => id}, socket) do
    case CorporateActionApplier.reverse_application(id, "Manual reversal from UI") do
      {:ok, result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Reversed corporate action. Reversed #{result.adjustments_reversed} adjustments.")
         |> assign(:corporate_actions, list_corporate_actions())}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to reverse: #{reason}")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    case Ash.get(CorporateAction, id, domain: Ashfolio.Portfolio) do
      {:ok, action} ->
        case Ash.destroy(action, domain: Ashfolio.Portfolio) do
          :ok ->
            {:noreply,
             socket
             |> put_flash(:info, "Corporate action deleted successfully")
             |> assign(:corporate_actions, list_corporate_actions())}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to delete corporate action")}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Corporate action not found")}
    end
  end

  @impl true
  def handle_info({:corporate_action, _action}, socket) do
    # Refresh the list when corporate actions are updated
    {:noreply, assign(socket, :corporate_actions, list_corporate_actions())}
  end

  # Private functions

  defp list_corporate_actions do
    case Ash.read(CorporateAction, domain: Ashfolio.Portfolio) do
      {:ok, actions} -> 
        # Load the symbol relationship
        Enum.map(actions, fn action ->
          case Ash.get(Symbol, action.symbol_id, domain: Ashfolio.Portfolio) do
            {:ok, symbol} -> %{action | symbol: symbol}
            {:error, _} -> %{action | symbol: %{ticker: "N/A", name: "Unknown"}}
          end
        end)
      {:error, _} -> []
    end
  end

  defp list_symbols do
    case Ash.read(Symbol, domain: Ashfolio.Portfolio) do
      {:ok, symbols} -> symbols
      {:error, _} -> []
    end
  end

  defp filter_actions_by_status(actions, :all), do: actions
  defp filter_actions_by_status(actions, status) do
    Enum.filter(actions, &(&1.status == status))
  end

  defp format_action_type(:stock_split), do: "Stock Split"
  defp format_action_type(:cash_dividend), do: "Cash Dividend"
  defp format_action_type(:stock_dividend), do: "Stock Dividend"
  defp format_action_type(:merger), do: "Merger"
  defp format_action_type(:spinoff), do: "Spinoff"
  defp format_action_type(:return_of_capital), do: "Return of Capital"
  defp format_action_type(type), do: to_string(type) |> String.capitalize()

  defp status_color(:pending), do: "bg-yellow-100 text-yellow-800"
  defp status_color(:applied), do: "bg-green-100 text-green-800"
  defp status_color(:reversed), do: "bg-red-100 text-red-800"
  defp status_color(:cancelled), do: "bg-gray-100 text-gray-800"
end