defmodule Ashfolio.AI.DispatcherTest do
  use ExUnit.Case, async: true

  alias Ashfolio.AI.Dispatcher

  # Mock handler for testing
  defmodule MockHandler do
    @moduledoc false
    @behaviour Ashfolio.AI.Handler

    def can_handle?("test_match"), do: true
    def can_handle?(_), do: false
    def handle("test_match"), do: {:ok, %{type: :mock, data: "handled"}}
  end

  # We need to override the config for this test, but Application.put_env
  # affects global state. For a robust test, we'd use Mox or dependency injection.
  # For this unit test, we'll test the find_handler logic indirectly if possible,
  # or rely on the integration test.
  #
  # Given the constraints, we'll create an integration test that uses the real
  # TransactionParser configuration.
end

defmodule Ashfolio.AI.DispatcherIntegrationTest do
  use Ashfolio.DataCase, async: false

  alias Ashfolio.AI.Dispatcher

  describe "process_text/1" do
    @tag :ai_integration
    test "returns :ai_unavailable when AI provider is not available" do
      # When Ollama isn't running (test environment), should return :ai_unavailable
      # This takes precedence over handler detection
      text = "this is just random text without any transaction keywords"
      assert {:error, :ai_unavailable} = Dispatcher.process_text(text)
    end

    test "returns :ai_unavailable when AI provider is not configured" do
      # Save original config
      original_provider = Application.get_env(:ashfolio, :ai_provider)
      original_key = Application.get_env(:langchain, :openai_key)

      # Temporarily disable AI (set to Ollama which won't be running in tests)
      Application.put_env(:ashfolio, :ai_provider, :ollama)
      Application.delete_env(:langchain, :openai_key)

      # Test
      result = Dispatcher.process_text("Buy 10 AAPL")

      # Restore config
      Application.put_env(:ashfolio, :ai_provider, original_provider)
      if original_key, do: Application.put_env(:langchain, :openai_key, original_key)

      # Assert - should gracefully return error, not crash
      assert result == {:error, :ai_unavailable}
    end

    @tag :ai_integration
    test "finds TransactionParser handler for transaction keywords" do
      # These texts should match the TransactionParser's can_handle? logic
      transaction_texts = [
        "bought 10 shares of AAPL",
        "sold 5 TSLA yesterday",
        "received dividend from MSFT",
        "deposited 1000 into savings",
        "withdraw 500 from checking"
      ]

      for text <- transaction_texts do
        result = Dispatcher.process_text(text)
        # Should NOT return :no_handler_found (it found the handler)
        # May return :ai_unavailable or other error if LLM isn't configured
        assert result != {:error, :no_handler_found},
               "Expected handler to be found for: #{text}"
      end
    end
  end

  describe "AI availability checks" do
    test "gracefully handles missing Ollama installation" do
      # This test documents the behavior when Ollama isn't running
      # Set provider to Ollama (which likely isn't running in test environment)
      original_provider = Application.get_env(:ashfolio, :ai_provider)
      Application.put_env(:ashfolio, :ai_provider, :ollama)

      result = Dispatcher.process_text("Buy 10 AAPL")

      # Restore
      Application.put_env(:ashfolio, :ai_provider, original_provider)

      # Should return ai_unavailable, not crash
      assert result == {:error, :ai_unavailable}
    end
  end
end
