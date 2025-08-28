# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :ashfolio, Ashfolio.Mailer, adapter: Swoosh.Adapters.Local

# Configure PriceManager
config :ashfolio, Ashfolio.MarketData.PriceManager,
  refresh_timeout: 30_000,
  batch_size: 50,
  max_retries: 3,
  retry_delay: 1_000

# Configures the endpoint
config :ashfolio, AshfolioWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: AshfolioWeb.ErrorHTML, json: AshfolioWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Ashfolio.PubSub,
  live_view: [signing_salt: System.get_env("LIVE_VIEW_SIGNING_SALT") || "yC+J6S1X"]

# Configure Oban for background jobs
config :ashfolio, Oban,
  repo: Ashfolio.Repo,
  # Disable notifier for SQLite compatibility (manual job management)
  notifier: false,
  plugins: [
    Oban.Plugins.Pruner
    # Future: Add cron jobs when needed
    # {Oban.Plugins.Cron,
    #  crontab: [
    #    # Monthly net worth snapshots on the 1st at 6 AM
    #    {"0 6 1 * *", Ashfolio.Workers.NetWorthSnapshotWorker}
    #  ]}
  ],
  queues: [
    default: 10,
    snapshots: 1,
    analytics: 2
  ]

# Configure Ash Framework
config :ashfolio, ash_domains: [Ashfolio.Portfolio, Ashfolio.FinancialManagement]

config :ashfolio,
  ecto_repos: [Ashfolio.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  ashfolio: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  ashfolio: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),

    # Import environment specific config. This must remain at the bottom
    # of this file so it overrides the configuration defined above.
    cd: Path.expand("../assets", __DIR__)
  ]

import_config "#{config_env()}.exs"
