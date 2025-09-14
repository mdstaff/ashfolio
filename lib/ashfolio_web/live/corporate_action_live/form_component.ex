defmodule AshfolioWeb.CorporateActionLive.FormComponent do
  @moduledoc false
  use AshfolioWeb, :live_component

  alias Ashfolio.Portfolio.CorporateAction

  @impl true
  def update(assigns, socket) do
    form =
      case assigns.action do
        :new ->
          CorporateAction
          |> AshPhoenix.Form.for_create(:create,
            domain: Ashfolio.Portfolio
          )
          |> to_form()

        :edit ->
          assigns.corporate_action
          |> AshPhoenix.Form.for_update(:update,
            domain: Ashfolio.Portfolio
          )
          |> to_form()
      end

    # Initialize action_type for conditional field rendering
    action_type =
      case assigns.action do
        :edit -> assigns.corporate_action.action_type || ""
        :new -> ""
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, form)
      |> assign(:action_type, action_type)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    # Extract action type for conditional field rendering
    action_type = params["action_type"] || ""

    form = socket.assigns.form.source |> AshPhoenix.Form.validate(params) |> to_form()

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:action_type, action_type)}
  end

  def handle_event("save", %{"form" => params}, socket) do
    save_corporate_action(socket, socket.assigns.action, params)
  end

  defp save_corporate_action(socket, _action, params) do
    form = AshPhoenix.Form.validate(socket.assigns.form.source, params)

    case AshPhoenix.Form.submit(form, params: params) do
      {:ok, _corporate_action} ->
        message =
          case socket.assigns.action do
            :new -> "Corporate action created successfully"
            :edit -> "Corporate action updated successfully"
          end

        socket =
          socket
          |> put_flash(:info, message)
          |> push_navigate(to: socket.assigns.navigate)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  defp action_type_options do
    [
      {"Stock Split", "stock_split"},
      {"Cash Dividend", "cash_dividend"},
      {"Stock Dividend", "stock_dividend"},
      {"Merger", "merger"},
      {"Spinoff", "spinoff"},
      {"Return of Capital", "return_of_capital"}
    ]
  end
end
