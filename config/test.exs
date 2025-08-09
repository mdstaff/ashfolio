import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ashfolio, Ashfolio.Repo,
  adapter: Ecto.Adapters.SQLite3,
  database: "data/ashfolio_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  # SQLite optimizations for testing
  pragma: [
    journal_mode: :wal,
    synchronous: :normal,
    temp_store: :memory,
    mmap_size: 268_435_456,
    busy_timeout: 30_000
  ]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ashfolio, AshfolioWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "rH1VB8pW+sXdD2khpNfLs4VqO+N+IMLTUPOcDRgWAnxU8+1//6Dk7k7RVSYYNgqe",
  server: false

# In test we don't send emails
config :ashfolio, Ashfolio.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# PriceManager test configuration
config :ashfolio, Ashfolio.MarketData.PriceManager,
  # Fast tests
  refresh_timeout: 5_000,
  batch_size: 5,
  # Don't retry in tests
  max_retries: 1

# Use mock for Yahoo Finance in tests
config :ashfolio, :yahoo_finance_module, YahooFinanceMock
