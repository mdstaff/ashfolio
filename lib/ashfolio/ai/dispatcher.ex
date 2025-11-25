defmodule Ashfolio.AI.Dispatcher do
  @moduledoc """
  Central dispatcher for AI commands.
  Broadcasts events and delegates processing to registered handlers.

  ## Configuration

  Register handlers in config/config.exs:

      config :ashfolio,
        ai_handlers: [
          Ashfolio.AI.Handlers.TransactionParser
        ]
  """

  require Logger

  @doc """
  Processes the given text by delegating to registered handlers.

  Returns:
  - `{:ok, result}` if successfully processed
  - `{:error, :no_handler_found}` if no handler matches
  - `{:error, :ai_unavailable}` if AI provider is not configured
  - `{:error, reason}` for other errors
  """
  def process_text(text, _context \\ []) do
    # Check if AI is configured before attempting to process
    case check_ai_availability() do
      :ok ->
        do_process_text(text)

      {:error, reason} ->
        Logger.warning("AI features unavailable: #{inspect(reason)}")
        {:error, :ai_unavailable}
    end
  end

  defp do_process_text(text) do
    # 1. Broadcast event (optional, for pure listeners)
    Phoenix.PubSub.broadcast(
      Ashfolio.PubSub,
      "ai:commands",
      {:ai_text_submitted, text}
    )

    # 2. Find a handler
    handlers = Application.get_env(:ashfolio, :ai_handlers, [])

    case find_handler(handlers, text) do
      {:ok, handler} ->
        Logger.info("AI Dispatcher: Delegating to #{inspect(handler)}")
        handler.handle(text)

      {:error, :no_handler} ->
        Logger.info("AI Dispatcher: No handler found for text")
        {:error, :no_handler_found}
    end
  end

  defp find_handler([], _text), do: {:error, :no_handler}

  defp find_handler([handler | rest], text) do
    if handler.can_handle?(text) do
      {:ok, handler}
    else
      find_handler(rest, text)
    end
  end

  defp check_ai_availability do
    # Quick check: just verify the model can be instantiated
    case Ashfolio.AI.Model.default() do
      {:error, reason} -> {:error, reason}
      _model -> :ok
    end
  end
end
