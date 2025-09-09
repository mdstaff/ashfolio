defmodule Ashfolio.MarketData.RateLimiter do
  @moduledoc """
  Simple rate limiter for API calls to prevent overwhelming external services.

  Implements token bucket algorithm with configurable rates for different operations.
  """

  use GenServer

  require Logger

  # requests per minute
  @default_rate_limit 10
  # burst capacity
  @default_burst_limit 5

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Check if an API call is allowed under current rate limits.

  ## Parameters
  - operation: :price_refresh | :batch_fetch | :individual_fetch
  - count: number of requests (default: 1)

  ## Returns
  - :ok if allowed
  - {:error, :rate_limited, retry_after_ms} if rate limited
  """
  def check_rate_limit(operation \\ :price_refresh, count \\ 1) do
    # Disable rate limiting in test environment to avoid interfering with tests
    if Application.get_env(:ashfolio, :environment, :prod) == :test do
      :ok
    else
      GenServer.call(__MODULE__, {:check_rate_limit, operation, count})
    end
  end

  @doc """
  Get current rate limit status for monitoring.
  """
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    state = %{
      tokens: @default_burst_limit,
      last_refill: System.monotonic_time(:millisecond),
      rate_per_minute: @default_rate_limit,
      burst_limit: @default_burst_limit
    }

    # Schedule token refill every 6 seconds (10 requests/minute = 1 request/6 seconds)
    schedule_refill()

    Logger.info("RateLimiter started with #{@default_rate_limit} requests/minute")
    {:ok, state}
  end

  @impl true
  def handle_call({:check_rate_limit, _operation, count}, _from, state) do
    updated_state = refill_tokens(state)

    if updated_state.tokens >= count do
      new_state = %{updated_state | tokens: updated_state.tokens - count}
      {:reply, :ok, new_state}
    else
      # Calculate retry after time based on token refill rate
      tokens_needed = count - updated_state.tokens
      retry_after_ms = tokens_needed * (60_000 / updated_state.rate_per_minute)

      Logger.warning("Rate limit exceeded, retry after #{retry_after_ms}ms")
      {:reply, {:error, :rate_limited, retry_after_ms}, updated_state}
    end
  end

  def handle_call(:get_status, _from, state) do
    updated_state = refill_tokens(state)

    status = %{
      available_tokens: updated_state.tokens,
      rate_per_minute: updated_state.rate_per_minute,
      burst_limit: updated_state.burst_limit
    }

    {:reply, status, updated_state}
  end

  @impl true
  def handle_info(:refill_tokens, state) do
    updated_state = refill_tokens(state)
    schedule_refill()
    {:noreply, updated_state}
  end

  # Private functions

  defp refill_tokens(state) do
    now = System.monotonic_time(:millisecond)
    time_passed = now - state.last_refill

    # Refill tokens based on time passed (rate_per_minute / 60_000 ms)
    tokens_to_add = trunc(time_passed * state.rate_per_minute / 60_000)

    if tokens_to_add > 0 do
      new_tokens = min(state.tokens + tokens_to_add, state.burst_limit)
      %{state | tokens: new_tokens, last_refill: now}
    else
      state
    end
  end

  defp schedule_refill do
    # Refill every 6 seconds for smooth token distribution
    Process.send_after(self(), :refill_tokens, 6_000)
  end
end
