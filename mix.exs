defmodule Ashfolio.MixProject do
  use Mix.Project

  def project do
    [
      app: :ashfolio,
      version: "0.10.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Ashfolio.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:lazy_html, ">= 0.0.0", only: :test},
      {:phoenix, "~> 1.8.0"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, "~> 0.17"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons", tag: "v2.1.1", sparse: "optimized", app: false, compile: false, depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},

      # Credo
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},

      # Styler - auto-formatting plugin
      {:styler, "~> 1.5", only: [:dev, :test], runtime: false},

      # Dialyzer - static type analysis
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

      # Ash Framework dependencies
      {:ash, "~> 3.0"},
      {:ash_sqlite, "~> 0.2"},
      {:ash_phoenix, "~> 2.0"},

      # Additional dependencies for portfolio management
      {:decimal, "~> 2.0"},
      {:httpoison, "~> 2.0"},

      # v0.3.0 Financial Analytics dependencies
      {:oban, "~> 2.17"},
      {:contex, "~> 0.5.0"},

      # v0.3.2 Data Import/Export dependencies
      {:csv, "~> 3.2"},

      # Test dependencies
      {:meck, "~> 0.9", only: :test},
      {:mox, "~> 1.0", only: :test},

      # Development tools
      {:igniter, "~> 0.6", only: [:dev, :test]},

      # AI Integration
      {:ash_ai, "~> 0.3.0"},
      {:langchain, "~> 0.4.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind ashfolio", "esbuild ashfolio"],
      "assets.deploy": [
        "tailwind ashfolio --minify",
        "esbuild ashfolio --minify",
        "phx.digest"
      ]
    ]
  end
end
