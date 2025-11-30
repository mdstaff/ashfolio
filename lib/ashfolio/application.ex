defmodule Ashfolio.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Initialize ETS cache before starting other processes
    Ashfolio.Cache.init()

    children = [
      AshfolioWeb.Telemetry,
      Ashfolio.Repo,
      {DNSCluster, query: Application.get_env(:ashfolio, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Ashfolio.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Ashfolio.Finch},
      # Background job scheduler (SQLite-compatible alternative to Oban)
      Ashfolio.BackgroundJobs.Scheduler,
      # Start the RateLimiter for API rate limiting
      Ashfolio.MarketData.RateLimiter,
      # Start the PriceManager for coordinating market data updates
      Ashfolio.MarketData.PriceManager,
      # Start the PerformanceCache for analytics caching
      Ashfolio.Portfolio.PerformanceCache,
      # Start the MCP Module Registry for tool discovery
      AshfolioWeb.Mcp.ModuleRegistry,
      # Start to serve requests, typically the last entry
      AshfolioWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ashfolio.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AshfolioWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
