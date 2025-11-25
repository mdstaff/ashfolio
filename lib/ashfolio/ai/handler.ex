defmodule Ashfolio.AI.Handler do
  @moduledoc """
  Behaviour for AI command handlers.
  Handlers are responsible for processing natural language text and performing actions.
  """

  @callback can_handle?(text :: String.t()) :: boolean() | {:ok, float()}
  @callback handle(text :: String.t()) :: {:ok, map()} | {:error, any()}
end
