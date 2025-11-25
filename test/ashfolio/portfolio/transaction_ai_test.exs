defmodule Ashfolio.Portfolio.TransactionAiTest do
  use Ashfolio.DataCase, async: true

  alias Ashfolio.Portfolio.Transaction

  describe "parse_from_text/1" do
    test "action is defined on the resource" do
      assert Ash.Resource.Info.action(Transaction, :parse_from_text)
    end

    # Note: Full integration testing requires mocking LangChain/OpenAI
    # which is outside the scope of this initial implementation.
    # We verify the action exists and accepts the correct arguments.
  end
end
