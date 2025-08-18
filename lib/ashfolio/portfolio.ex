defmodule Ashfolio.Portfolio do
  use Ash.Domain

  resources do
    resource(Ashfolio.Portfolio.UserSettings)
    resource(Ashfolio.Portfolio.Account)
    resource(Ashfolio.Portfolio.Symbol)
    resource(Ashfolio.Portfolio.Transaction)
  end
end
