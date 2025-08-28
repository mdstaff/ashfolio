defmodule Ashfolio.Portfolio do
  @moduledoc """
  Ash domain for portfolio management resources.

  Contains resources for managing user settings, accounts, symbols, and transactions
  in the portfolio system.
  """
  use Ash.Domain

  resources do
    resource(Ashfolio.Portfolio.UserSettings)
    resource(Ashfolio.Portfolio.Account)
    resource(Ashfolio.Portfolio.Symbol)
    resource(Ashfolio.Portfolio.Transaction)
  end
end
