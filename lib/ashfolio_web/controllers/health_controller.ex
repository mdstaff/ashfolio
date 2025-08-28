defmodule AshfolioWeb.HealthController do
  use AshfolioWeb, :controller

  @doc """
  Health check endpoint for monitoring and QA testing.

  Returns application status including:
  - Database connectivity
  - Application uptime
  - Memory usage
  - Key service availability
  """
  def check(conn, _params) do
    health_data = %{
      status: "healthy",
      timestamp: DateTime.to_iso8601(DateTime.utc_now()),
      application: %{
        name: "ashfolio",
        version: :ashfolio |> Application.spec(:vsn) |> to_string(),
        environment: :ashfolio |> Application.get_env(:environment, Mix.env()) |> to_string()
      },
      system: get_system_info(),
      database: check_database_health(),
      services: check_services_health()
    }

    case health_data.database.status do
      "healthy" ->
        conn
        |> put_status(200)
        |> json(health_data)

      _ ->
        conn
        |> put_status(503)
        |> json(%{health_data | status: "unhealthy"})
    end
  end

  @doc """
  Simple health check endpoint that returns minimal response for load balancers.
  """
  def ping(conn, _params) do
    json(conn, %{status: "ok", timestamp: DateTime.to_iso8601(DateTime.utc_now())})
  end

  # Private helper functions

  defp get_system_info do
    {uptime_ms, _} = :erlang.statistics(:wall_clock)
    memory_info = :erlang.memory()

    %{
      uptime_seconds: div(uptime_ms, 1000),
      memory: %{
        total_mb: div(memory_info[:total], 1024 * 1024),
        processes_mb: div(memory_info[:processes], 1024 * 1024),
        system_mb: div(memory_info[:system], 1024 * 1024)
      },
      node: Node.self(),
      otp_release: :otp_release |> :erlang.system_info() |> to_string(),
      beam_version: :version |> :erlang.system_info() |> to_string()
    }
  end

  defp check_database_health do
    # Test database connectivity with a simple query
    case Ashfolio.Repo.query("SELECT 1 as test", []) do
      {:ok, %{rows: [[1]]}} ->
        # Get basic stats about the database - handle missing tables gracefully
        user_count = safe_count_query("users")
        account_count = safe_count_query("accounts")
        transaction_count = safe_count_query("transactions")

        %{
          status: "healthy",
          connection: "ok",
          stats: %{
            users: user_count,
            accounts: account_count,
            transactions: transaction_count
          }
        }

      {:error, reason} ->
        %{
          status: "unhealthy",
          connection: "failed",
          error: inspect(reason)
        }
    end
  rescue
    exception ->
      %{
        status: "unhealthy",
        connection: "failed",
        error: Exception.message(exception)
      }
  end

  defp check_services_health do
    %{
      cache: check_cache_health(),
      market_data: check_market_data_health(),
      pubsub: check_pubsub_health()
    }
  end

  defp check_cache_health do
    # Test ETS cache table availability and get basic stats
    stats = Ashfolio.Cache.stats()

    %{
      status: "healthy",
      table_exists: true,
      entries: stats.size,
      memory_mb: Float.round(stats.memory_bytes / (1024 * 1024), 2)
    }
  rescue
    _exception ->
      %{status: "unhealthy", table_exists: false, error: "cache_unavailable"}
  end

  defp check_market_data_health do
    # Check if market data service is available
    case GenServer.whereis(Ashfolio.MarketData.PriceManager) do
      nil ->
        %{status: "unhealthy", reason: "price_manager_not_running"}

      _pid ->
        %{status: "healthy", price_manager: "running"}
    end
  rescue
    _exception ->
      %{status: "unhealthy", reason: "check_failed"}
  end

  defp check_pubsub_health do
    # Test PubSub system
    case GenServer.whereis(Ashfolio.PubSub) do
      nil ->
        %{status: "unhealthy", reason: "pubsub_not_running"}

      _pid ->
        %{status: "healthy", pubsub: "running"}
    end
  rescue
    _exception ->
      %{status: "unhealthy", reason: "check_failed"}
  end

  # Helper function to safely count table rows
  defp safe_count_query(table_name) do
    case Ashfolio.Repo.query("SELECT COUNT(*) FROM #{table_name}", []) do
      {:ok, %{rows: [[count]]}} -> count
      # Table doesn't exist or other error
      {:error, _} -> 0
    end
  end
end
