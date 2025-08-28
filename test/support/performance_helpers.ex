defmodule Ashfolio.PerformanceHelpers do
  @moduledoc """
  Helper functions for performance tests to show progress and measure timing.
  """

  @doc """
  Runs a performance test block with progress indication.

  ## Examples

      with_progress "Loading 1000 accounts", fn ->
        # ... test code ...
      end
  """
  def with_progress(description, fun) do
    IO.write("  ⏱️  #{description}... ")
    start_time = System.monotonic_time(:millisecond)

    try do
      result = fun.()
      duration = System.monotonic_time(:millisecond) - start_time
      IO.puts(green("✓ (#{format_time(duration)})"))
      result
    rescue
      error ->
        duration = System.monotonic_time(:millisecond) - start_time
        IO.puts(red("✗ (#{format_time(duration)})"))
        reraise error, __STACKTRACE__
    end
  end

  @doc """
  Measures and reports the performance of a code block.

  ## Examples

      measure_performance "Net worth calculation", fn ->
        NetWorthCalculator.calculate_current_net_worth()
      end
  """
  def measure_performance(label, fun) do
    IO.write("    Measuring #{label}... ")

    # Warm up run
    fun.()

    # Actual measurement (average of 3 runs)
    times =
      for _ <- 1..3 do
        start = System.monotonic_time(:microsecond)
        result = fun.()
        duration = System.monotonic_time(:microsecond) - start
        {duration, result}
      end

    avg_time =
      times
      |> Enum.map(&elem(&1, 0))
      |> Enum.sum()
      |> div(3)
      # Convert to milliseconds
      |> div(1000)

    IO.puts("#{avg_time}ms avg")

    # Return the result from the first run
    elem(List.first(times), 1)
  end

  @doc """
  Shows a progress bar for batch operations.

  ## Examples

      with_progress_bar 100, "Creating accounts", fn i ->
        # Create account i
      end
  """
  def with_progress_bar(total, description, fun) do
    IO.puts("\n  #{description}: ")
    IO.write("  [")

    chunk_size = max(div(total, 20), 1)

    result =
      Enum.map(1..total, fn i ->
        result = fun.(i)

        if rem(i, chunk_size) == 0 do
          IO.write("█")
        end

        result
      end)

    remaining = 20 - div(total, chunk_size)

    if remaining > 0 do
      IO.write(String.duplicate(" ", remaining))
    end

    IO.puts("] #{green("✓")}")
    result
  end

  @doc """
  Benchmarks multiple implementations and compares them.

  ## Examples

      benchmark_compare %{
        "Original" => fn -> original_implementation() end,
        "Optimized" => fn -> optimized_implementation() end
      }
  """
  def benchmark_compare(implementations) do
    IO.puts("\n  📊 Performance Comparison:")
    IO.puts("  " <> String.duplicate("─", 50))

    results =
      Enum.map(implementations, fn {name, fun} ->
        IO.write("  #{String.pad_trailing(name, 20)}: ")

        # Warm up
        fun.()

        # Measure
        times =
          for _ <- 1..5 do
            start = System.monotonic_time(:microsecond)
            fun.()
            System.monotonic_time(:microsecond) - start
          end

        avg = times |> Enum.sum() |> div(5) |> div(1000)
        min = times |> Enum.min() |> div(1000)
        max = times |> Enum.max() |> div(1000)

        IO.puts("#{String.pad_leading("#{avg}ms", 6)} (min: #{min}ms, max: #{max}ms)")

        {name, avg}
      end)

    # Find the fastest
    {fastest_name, fastest_time} = Enum.min_by(results, &elem(&1, 1))

    IO.puts("  " <> String.duplicate("─", 50))
    IO.puts("  🏆 Fastest: #{fastest_name} at #{fastest_time}ms")
    IO.puts("")

    results
  end

  # Helper functions
  defp format_time(ms) when ms < 1000, do: "#{ms}ms"

  defp format_time(ms) do
    seconds = ms / 1000
    "#{:erlang.float_to_binary(seconds, decimals: 1)}s"
  end

  defp green(text), do: IO.ANSI.green() <> text <> IO.ANSI.reset()
  defp red(text), do: IO.ANSI.red() <> text <> IO.ANSI.reset()
end
