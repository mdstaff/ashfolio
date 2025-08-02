defmodule Ashfolio.Portfolio do
  use Ash.Domain

  resources do
    resource Ashfolio.Portfolio.User
    resource Ashfolio.Portfolio.Account
    resource Ashfolio.Portfolio.Symbol
    resource Ashfolio.Portfolio.Transaction
  end
end
