defmodule Ashfolio.MarketData.HttpClient do
  @moduledoc """
  HTTP client wrapper for external API calls.
  """

  @behaviour Ashfolio.MarketData.HttpClientBehaviour

  def get(url, headers, opts) do
    HTTPoison.get(url, headers, opts)
  end
end
