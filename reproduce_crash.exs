# reproduce_crash.exs
try do
  # Attempt to run the action that triggered the error
  # We don't need a real OpenAI key if the error happens during schema generation (before the call)
  # But if it happens during the run, we might need it.
  # The stacktrace said `AshAi.Actions.Prompt.run` -> `get_json_schema`.
  # This likely happens before the HTTP call.

  IO.puts("Attempting to run Transaction.parse_from_text...")
  Ashfolio.Portfolio.Transaction.parse_from_text!("Buy 10 AAPL")
  IO.puts("Success!")
rescue
  e ->
    IO.puts("Crashed: #{inspect(e)}")
    IO.puts(Exception.format(:error, e, __STACKTRACE__))
end
