ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Ashfolio.Repo, :manual)

# Set up Mox for mocking
Mox.defmock(YahooFinanceMock, for: Ashfolio.MarketData.YahooFinanceBehaviour)
