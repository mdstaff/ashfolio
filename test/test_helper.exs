ExUnit.configure(
  trace: false,
  max_cases: 10,
  capture_log: true,
  colors: [enabled: true],
  timeout: 120_000,
  exclude_tags: [:seeding],
  formatters: [ExUnit.CLIFormatter]
)

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Ashfolio.Repo, :manual)

# Set up Mox for mocking
Mox.defmock(YahooFinanceMock, for: Ashfolio.MarketData.YahooFinanceBehaviour)
