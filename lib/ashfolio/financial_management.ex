defmodule Ashfolio.FinancialManagement do
  @moduledoc """
  FinancialManagement domain for Ashfolio.

  This domain handles comprehensive financial management features including:
  - Cash account balance management
  - Net worth calculations across investment and cash accounts
  - Transaction categorization for investments
  - Symbol search and autocomplete functionality
  """

  use Ash.Domain

  resources do
    resource(Ashfolio.FinancialManagement.TransactionCategory)
    resource(Ashfolio.FinancialManagement.Expense)
    resource(Ashfolio.FinancialManagement.NetWorthSnapshot)
    resource(Ashfolio.FinancialManagement.FinancialGoal)
    resource(Ashfolio.FinancialManagement.FinancialProfile)
  end
end
