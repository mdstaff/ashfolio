defmodule Ashfolio.ClearFailureFormatter do
  @moduledoc """
  Enhanced ExUnit formatter that provides clearer test failure reporting with:
  - Better failure demarcation with clear separators
  - Color-coded failure types
  - Concise failure summaries
  - Progress indicators during test runs
  """
  use GenServer

  @doc false
  def init(opts) do
    config = %{
      seed: opts[:seed],
      trace: opts[:trace],
      colors: opts[:colors],
      width: opts[:width] || 80,
      tests_counter: 0,
      failures_counter: 0,
      skipped_counter: 0,
      excluded_counter: 0,
      start_time: nil,
      current_test: nil,
      failures: []
    }

    {:ok, config}
  end

  def handle_cast({:suite_started, _opts}, config) do
    IO.puts("\n🧪 Test Suite Started")
    IO.puts("━" <> String.duplicate("━", 60))
    
    config = %{config | 
      start_time: System.monotonic_time(:millisecond)
    }
    
    {:noreply, config}
  end

  def handle_cast({:test_started, %ExUnit.Test{} = test}, config) do
    if config.trace do
      test_name = format_test_name(test)
      IO.write("#{test_name} ")
    end
    
    config = %{config | current_test: {test, System.monotonic_time(:millisecond)}}
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{} = test}, config) do
    {_current_test, start_time} = config.current_test || {nil, System.monotonic_time(:millisecond)}
    duration = System.monotonic_time(:millisecond) - start_time
    
    result = case test.state do
      :passed -> 
        if config.trace, do: IO.puts(green("✓ (#{format_time(duration)})"))
        IO.write(green("."))
        config
      :failed -> 
        if config.trace, do: IO.puts(red("✗ (#{format_time(duration)})"))
        IO.write(red("F"))
        failure_info = extract_failure_info(test)
        %{config | 
          failures_counter: config.failures_counter + 1,
          failures: [failure_info | config.failures]
        }
      :skipped ->
        if config.trace, do: IO.puts(yellow("⊘ (skipped)"))
        IO.write(yellow("S"))
        %{config | skipped_counter: config.skipped_counter + 1}
      :excluded ->
        %{config | excluded_counter: config.excluded_counter + 1}
      _ ->
        config
    end
    
    progress = config.tests_counter + 1
    
    # Show progress every 50 tests
    if rem(progress, 50) == 0 do
      IO.write(cyan(" [#{progress} tests]"))
      IO.write("\n")
    end
    
    {:noreply, %{result | tests_counter: progress, current_test: nil}}
  end

  def handle_cast({:suite_finished, _run_us, _load_us}, config) do
    total_time = System.monotonic_time(:millisecond) - config.start_time
    
    IO.puts("\n")
    IO.puts("━" <> String.duplicate("━", 60))
    
    # Show clear failure summaries
    if config.failures_counter > 0 do
      IO.puts(red("📋 FAILURE SUMMARY (#{config.failures_counter} failures)"))
      IO.puts("━" <> String.duplicate("━", 60))
      
      config.failures
      |> Enum.reverse()
      |> Enum.with_index(1)
      |> Enum.each(fn {failure, index} ->
        print_failure_summary(failure, index)
      end)
      
      IO.puts("━" <> String.duplicate("━", 60))
    end
    
    # Final results
    IO.puts("📊 Test Results:")
    IO.puts("  Tests run: #{config.tests_counter}")
    
    if config.failures_counter > 0 do
      IO.puts(red("  ❌ Failures: #{config.failures_counter}"))
    else
      IO.puts(green("  ✅ All tests passed!"))
    end
    
    if config.skipped_counter > 0 do
      IO.puts(yellow("  ⊘ Skipped: #{config.skipped_counter}"))
    end
    
    if config.excluded_counter > 0 do
      IO.puts(cyan("  ⚪ Excluded: #{config.excluded_counter}"))
    end
    
    IO.puts("  ⏱️  Total time: #{format_time(total_time)}")
    
    if config.tests_counter > 0 do
      avg_time = div(total_time, config.tests_counter)
      IO.puts("  📈 Avg per test: #{format_time(avg_time)}")
    end
    
    IO.puts("")
    
    {:noreply, config}
  end

  def handle_cast(_event, config) do
    {:noreply, config}
  end

  # Helper functions
  defp extract_failure_info(%ExUnit.Test{} = test) do
    %{
      module: test.module,
      name: test.name,
      file: test.tags[:file],
      line: test.tags[:line],
      error: format_error(test.state)
    }
  end

  defp format_error({:failed, [{:error, error, _stacktrace} | _]}) do
    case error do
      %KeyError{key: key, term: term} ->
        "KeyError: key #{inspect(key)} not found in #{inspect_term(term)}"
      %ArgumentError{message: message} ->
        "ArgumentError: #{message}"
      %RuntimeError{message: message} ->
        "RuntimeError: #{message}"
      error when is_binary(error) ->
        error
      error ->
        inspect(error)
    end
  end
  defp format_error(_), do: "Unknown error"

  defp inspect_term(term) when is_map(term) do
    keys = Map.keys(term) |> Enum.take(3)
    if length(keys) > 3 do
      "%{#{Enum.join(keys, ", ")}, ...}"
    else
      "%{#{Enum.join(keys, ", ")}}"
    end
  end
  defp inspect_term(term), do: inspect(term)

  defp print_failure_summary(failure, index) do
    IO.puts("#{red("#{index}.")} #{failure.module |> Module.split() |> List.last()}")
    IO.puts("   #{format_test_name_from_atom(failure.name)}")
    IO.puts("   #{cyan("#{failure.file}:#{failure.line}")}")
    IO.puts("   #{red("Error:")} #{failure.error}")
    IO.puts("")
  end

  defp format_test_name(%ExUnit.Test{module: module, name: name}) do
    module_name = module |> Module.split() |> List.last()
    test_name = format_test_name_from_atom(name)
    
    # Truncate long test names
    max_length = 50
    formatted = "#{module_name}: #{test_name}"
    if String.length(formatted) > max_length do
      String.slice(formatted, 0, max_length - 3) <> "..."
    else
      formatted
    end
  end

  defp format_test_name_from_atom(name) do
    name 
    |> Atom.to_string() 
    |> String.replace("test ", "")
    |> String.slice(0, 80)
  end

  defp format_time(ms) when ms < 1000, do: "#{ms}ms"
  defp format_time(ms) do
    seconds = ms / 1000
    "#{:erlang.float_to_binary(seconds, decimals: 1)}s"
  end

  # Color helpers
  defp green(text), do: IO.ANSI.green() <> text <> IO.ANSI.reset()
  defp red(text), do: IO.ANSI.red() <> text <> IO.ANSI.reset()
  defp yellow(text), do: IO.ANSI.yellow() <> text <> IO.ANSI.reset()
  defp cyan(text), do: IO.ANSI.cyan() <> text <> IO.ANSI.reset()
end