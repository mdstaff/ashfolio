defmodule Ashfolio.AI.Model do
  @moduledoc """
  Provides the configured LLM model for Ash AI actions.
  Supports switching between providers (OpenAI, Anthropic, Ollama) via configuration.

  ## Configuration

  Configure the AI provider in config/config.exs:

      config :ashfolio,
        ai_provider: :ollama,  # or :openai
        ai_model: "llama3"     # or "gpt-4o"

  ## Providers

  - `:ollama` - Local LLM (requires Ollama running on localhost:11434)
  - `:openai` - OpenAI API (requires OPENAI_API_KEY environment variable)
  - `:anthropic` - Not yet supported
  """

  alias LangChain.ChatModels.ChatOpenAI

  require Logger

  @doc """
  Returns the default configured LLM model.

  Returns `{:error, reason}` if the provider is unavailable or misconfigured.
  """
  def default do
    provider = Application.get_env(:ashfolio, :ai_provider, :openai)
    model_name = Application.get_env(:ashfolio, :ai_model)

    case provider do
      :openai ->
        create_openai_model(model_name)

      :ollama ->
        create_ollama_model(model_name)

      :anthropic ->
        {:error, :anthropic_not_supported}

      _ ->
        Logger.warning("Unknown AI provider #{inspect(provider)}, falling back to OpenAI")
        create_openai_model(model_name)
    end
  end

  defp create_openai_model(model_name) do
    api_key = Application.get_env(:langchain, :openai_key) || System.get_env("OPENAI_API_KEY")

    if api_key do
      ChatOpenAI.new!(%{
        model: model_name || "gpt-4o",
        temperature: 0.0
      })
    else
      Logger.error("OpenAI API key not configured. Set OPENAI_API_KEY environment variable.")
      {:error, :openai_api_key_missing}
    end
  end

  defp create_ollama_model(model_name) do
    # Check if Ollama is running before creating the model
    case check_ollama_availability() do
      :ok ->
        LangChain.ChatModels.ChatOllamaAI.new!(%{
          model: model_name || "llama3",
          temperature: 0.0
        })

      {:error, reason} ->
        Logger.error("""
        Ollama is not available: #{reason}

        To use AI features with Ollama:
        1. Install Ollama: https://ollama.ai
        2. Start Ollama: `ollama serve`
        3. Pull a model: `ollama pull llama3`
        """)

        {:error, :ollama_unavailable}
    end
  end

  defp check_ollama_availability do
    case :httpc.request(:get, {~c"http://localhost:11434/api/tags", []}, [], []) do
      {:ok, {{_, 200, _}, _, _}} -> :ok
      {:ok, {{_, status, _}, _, _}} -> {:error, "Ollama returned status #{status}"}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end
end
