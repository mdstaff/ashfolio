defmodule Ashfolio.AI.Handlers.TransactionParser do
  @moduledoc """
  AI Handler for parsing financial transaction text.
  Wraps the `Ashfolio.Portfolio.Transaction.parse_from_text` action.
  """

  @behaviour Ashfolio.AI.Handler

  alias Ashfolio.Portfolio.Transaction

  @impl true
  def can_handle?(text) do
    # Simple heuristic: does it look like a transaction?
    # Keywords: buy, sell, bought, sold, dividend, deposit, withdraw
    text = String.downcase(text)
    keywords = ~w(buy sell bought sold dividend deposit withdraw paid received)

    Enum.any?(keywords, &String.contains?(text, &1))
  end

  @impl true
  def handle(text) do
    case Transaction.parse_from_text(text) do
      {:ok, result} ->
        {:ok, %{type: :transaction_draft, data: result}}

      {:error, error} ->
        {:error, error}
    end
  end
end
