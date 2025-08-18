defmodule Ashfolio.PerformanceFormatter do
  @moduledoc """
  Custom ExUnit formatter for performance tests that shows progress and timing.
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
      total_tests: 0,
      failures_counter: 0,
      skipped_counter: 0,
      start_time: nil,
      current_test: nil
    }

    {:ok, config}
  end

  def handle_cast({:suite_started, opts}, config) do
    IO.puts("\n🚀 Performance Test Suite Started")
    IO.puts("━" <> String.duplicate("━", 50))

    config = %{
      config
      | start_time: System.monotonic_time(:millisecond),
        total_tests: opts[:max_cases] || 0
    }

    {:noreply, config}
  end

  def handle_cast({:test_started, %ExUnit.Test{} = test}, config) do
    test_name = format_test_name(test)
    IO.write("\n⏱️  #{test_name} ")

    config = %{config | current_test: {test, System.monotonic_time(:millisecond)}}
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{} = test}, config) do
    {_current_test, start_time} =
      config.current_test || {nil, System.monotonic_time(:millisecond)}

    duration = System.monotonic_time(:millisecond) - start_time

    result =
      case test.state do
        :passed ->
          IO.write(green("✓ (#{format_time(duration)})"))
          config

        :failed ->
          IO.write(red("✗ (#{format_time(duration)})"))
          %{config | failures_counter: config.failures_counter + 1}

        :skipped ->
          IO.write(yellow("⊘ (skipped)"))
          %{config | skipped_counter: config.skipped_counter + 1}

        _ ->
          config
      end

    progress = config.tests_counter + 1

    if config.total_tests > 0 do
      percentage = round(progress / config.total_tests * 100)
      IO.write(cyan(" [#{progress}/#{config.total_tests} - #{percentage}%]"))
    end

    {:noreply, %{result | tests_counter: progress, current_test: nil}}
  end

  def handle_cast({:suite_finished, _run_us, _load_us}, config) do
    total_time = System.monotonic_time(:millisecond) - config.start_time

    IO.puts("\n")
    IO.puts("━" <> String.duplicate("━", 50))
    IO.puts("📊 Performance Test Results:")
    IO.puts("  Tests run: #{config.tests_counter}")

    if config.failures_counter > 0 do
      IO.puts(red("  Failures: #{config.failures_counter}"))
    else
      IO.puts(green("  All tests passed! ✅"))
    end

    if config.skipped_counter > 0 do
      IO.puts(yellow("  Skipped: #{config.skipped_counter}"))
    end

    IO.puts("  Total time: #{format_time(total_time)}")
    IO.puts("  Avg time per test: #{format_time(div(total_time, max(config.tests_counter, 1)))}")
    IO.puts("")

    {:noreply, config}
  end

  def handle_cast(_event, config) do
    {:noreply, config}
  end

  # Helper functions
  defp format_test_name(%ExUnit.Test{module: module, name: name}) do
    module_name = module |> Module.split() |> List.last()
    test_name = name |> Atom.to_string() |> String.replace("test ", "")

    # Truncate long test names
    max_length = 60
    formatted = "#{module_name}: #{test_name}"

    if String.length(formatted) > max_length do
      String.slice(formatted, 0, max_length - 3) <> "..."
    else
      formatted
    end
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
