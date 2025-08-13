defmodule Ashfolio.MarketData.HttpClientBehaviour do
  @moduledoc """
  Behaviour for HTTP client operations to enable mocking in tests.
  """

  @callback get(String.t(), list(), keyword()) ::
              {:ok, %{status_code: integer(), body: String.t()}}
              | {:error, %HTTPoison.Error{}}
end
