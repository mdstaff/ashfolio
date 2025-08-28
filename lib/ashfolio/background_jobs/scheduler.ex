defmodule Ashfolio.BackgroundJobs.Scheduler do
  @moduledoc """
  Simple background job scheduler for SQLite compatibility.

  Provides basic job scheduling without the overhead of Oban's
  notifier system which doesn't work well with SQLite.
  """

  use GenServer

  alias Ashfolio.FinancialManagement.NetWorthCalculator

  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Schedule the first check in 1 minute
    :timer.send_after(60_000, :check_monthly_snapshots)

    {:ok, %{last_snapshot_check: Date.utc_today()}}
  end

  @impl true
  def handle_info(:check_monthly_snapshots, state) do
    today = Date.utc_today()

    # Check if we need to create a monthly snapshot
    if should_create_monthly_snapshot?(today, state.last_snapshot_check) do
      Logger.info("Creating automated monthly net worth snapshot")

      case NetWorthCalculator.create_snapshot(today) do
        {:ok, snapshot} ->
          Logger.info("Created net worth snapshot: #{snapshot.id}")

        {:error, reason} ->
          Logger.error("Failed to create net worth snapshot: #{inspect(reason)}")
      end
    end

    # Schedule next check in 24 hours
    :timer.send_after(24 * 60 * 60 * 1000, :check_monthly_snapshots)

    {:noreply, %{state | last_snapshot_check: today}}
  end

  @doc """
  Manually trigger a net worth snapshot.
  """
  def create_snapshot(date \\ nil) do
    GenServer.cast(__MODULE__, {:create_snapshot, date || Date.utc_today()})
  end

  @impl true
  def handle_cast({:create_snapshot, date}, state) do
    Task.start(fn ->
      Logger.info("Creating manual net worth snapshot for #{date}")

      case NetWorthCalculator.create_snapshot(date) do
        {:ok, snapshot} ->
          Logger.info("Created net worth snapshot: #{snapshot.id}")

        {:error, reason} ->
          Logger.error("Failed to create net worth snapshot: #{inspect(reason)}")
      end
    end)

    {:noreply, state}
  end

  # Private functions

  defp should_create_monthly_snapshot?(today, last_check) do
    # Create snapshot if it's the 1st of the month and we haven't checked today
    today.day == 1 and today != last_check
  end
end
