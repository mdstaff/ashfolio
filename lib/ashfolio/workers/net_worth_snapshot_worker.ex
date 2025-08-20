defmodule Ashfolio.Workers.NetWorthSnapshotWorker do
  @moduledoc """
  Worker for creating net worth snapshots.

  This worker can be triggered manually for immediate snapshot creation
  or scheduled for automated monthly snapshots.
  """

  use Oban.Worker, queue: :snapshots, max_attempts: 3

  alias Ashfolio.FinancialManagement.NetWorthCalculator

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"manual" => true} = args}) do
    snapshot_date =
      case Map.get(args, "snapshot_date") do
        nil -> Date.utc_today()
        date_string -> Date.from_iso8601!(date_string)
      end

    case NetWorthCalculator.create_snapshot(snapshot_date) do
      {:ok, snapshot} ->
        {:ok, %{snapshot_id: snapshot.id, snapshot_date: snapshot.snapshot_date}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"automated" => true}}) do
    # For automated monthly snapshots
    case NetWorthCalculator.create_snapshot() do
      {:ok, snapshot} ->
        {:ok, %{snapshot_id: snapshot.id, snapshot_date: snapshot.snapshot_date}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    # Default: manual snapshot for today
    snapshot_date =
      case Map.get(args, "snapshot_date") do
        nil -> Date.utc_today()
        date_string -> Date.from_iso8601!(date_string)
      end

    case NetWorthCalculator.create_snapshot(snapshot_date) do
      {:ok, snapshot} ->
        {:ok, %{snapshot_id: snapshot.id, snapshot_date: snapshot.snapshot_date}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Enqueues a manual snapshot job.
  """
  def enqueue_manual_snapshot(snapshot_date \\ nil) do
    args = %{manual: true}

    args =
      if snapshot_date,
        do: Map.put(args, "snapshot_date", Date.to_iso8601(snapshot_date)),
        else: args

    %{args: args}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  @doc """
  Enqueues an automated snapshot job (typically from cron).
  """
  def enqueue_automated_snapshot do
    %{args: %{automated: true}}
    |> __MODULE__.new()
    |> Oban.insert()
  end
end
