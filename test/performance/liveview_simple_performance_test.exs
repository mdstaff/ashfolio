defmodule Ashfolio.Performance.LiveViewSimplePerformanceTest do
  @moduledoc """
  Simplified LiveView performance tests for Task 14 Stage 5.

  Basic performance tests to establish baseline:
  - PubSub broadcast performance: <10ms
  - Message delivery latency: <20ms
  - Memory efficiency during updates
  """

  use Ashfolio.DataCase, async: false

  @moduletag :performance
  @moduletag :slow
  @moduletag :liveview_performance

  alias Ashfolio.SQLiteHelpers

  describe "PubSub Performance" do
    # Database-as-user architecture: No user setup needed

    test "PubSub broadcast under 10ms" do
      net_worth_data = %{
        net_worth: Decimal.new("100000"),
        investment_value: Decimal.new("75000"),
        cash_value: Decimal.new("25000"),
        breakdown: %{}
      }

      {time_us, :ok} =
        :timer.tc(fn ->
          Phoenix.PubSub.broadcast(
            Ashfolio.PubSub,
            "net_worth",
            {:net_worth_updated, net_worth_data}
          )
        end)

      time_ms = time_us / 1000

      assert time_ms < 10,
             "PubSub broadcast took #{time_ms}ms, expected < 10ms"
    end

    test "concurrent broadcasts under 10ms each" do
      # Test concurrent broadcasting
      tasks =
        for i <- 1..5 do
          Task.async(fn ->
            data = %{
              net_worth: Decimal.new("#{100_000 + i * 1000}"),
              investment_value: Decimal.new("75000"),
              cash_value: Decimal.new("25000"),
              breakdown: %{}
            }

            {time_us, :ok} =
              :timer.tc(fn ->
                Phoenix.PubSub.broadcast(
                  Ashfolio.PubSub,
                  "net_worth",
                  {:net_worth_updated, data}
                )
              end)

            time_us / 1000
          end)
        end

      times = Task.await_many(tasks, 5_000)
      avg_time = Enum.sum(times) / length(times)

      assert avg_time < 8,
             "Concurrent broadcasts averaged #{avg_time}ms, expected < 8ms"
    end

    test "PubSub message delivery latency under 20ms" do
      # Subscribe to the topic
      Phoenix.PubSub.subscribe(Ashfolio.PubSub, "net_worth")

      data = %{
        net_worth: Decimal.new("100000"),
        investment_value: Decimal.new("75000"),
        cash_value: Decimal.new("25000"),
        breakdown: %{}
      }

      start_time = System.monotonic_time(:microsecond)

      Phoenix.PubSub.broadcast(
        Ashfolio.PubSub,
        "net_worth",
        {:net_worth_updated, data}
      )

      # Wait for message
      receive do
        {:net_worth_updated, _received_data} ->
          end_time = System.monotonic_time(:microsecond)
          latency_ms = (end_time - start_time) / 1000

          assert latency_ms < 20,
                 "PubSub delivery latency #{latency_ms}ms, expected < 20ms"
      after
        100 ->
          flunk("PubSub message not received within 100ms")
      end
    end

    test "multiple topic broadcasts maintain performance" do
      topics = [
        "net_worth",
        "transactions",
        "prices",
        "portfolio"
      ]

      times =
        for topic <- topics do
          {time_us, :ok} =
            :timer.tc(fn ->
              Phoenix.PubSub.broadcast(
                Ashfolio.PubSub,
                topic,
                {:test_update, System.monotonic_time()}
              )
            end)

          time_us / 1000
        end

      avg_time = Enum.sum(times) / length(times)
      max_time = Enum.max(times)

      assert avg_time < 8, "Multi-topic broadcast average #{avg_time}ms too high"
      assert max_time < 15, "Multi-topic broadcast max #{max_time}ms indicates issue"
    end
  end

  describe "Update Cycle Performance" do
    # Database-as-user architecture: No user setup needed

    test "rapid update cycles maintain performance" do
      # Simulate rapid updates (like real-time price changes)
      update_times =
        for i <- 1..10 do
          {time_us, _result} =
            :timer.tc(fn ->
              # Simulate different types of updates
              case rem(i, 3) do
                0 ->
                  # Net worth update
                  Phoenix.PubSub.broadcast(
                    Ashfolio.PubSub,
                    "net_worth",
                    {:net_worth_updated, %{net_worth: Decimal.new("#{100_000 + i * 1000}")}}
                  )

                1 ->
                  # Price update
                  Phoenix.PubSub.broadcast(
                    Ashfolio.PubSub,
                    "prices",
                    {:price_updated, "AAPL", Decimal.new("#{150 + i}")}
                  )

                2 ->
                  # Transaction update
                  Phoenix.PubSub.broadcast(
                    Ashfolio.PubSub,
                    "transactions",
                    {:transaction_updated, %{id: "test-#{i}"}}
                  )
              end

              # Small delay to simulate realistic update frequency
              Process.sleep(2)
            end)

          time_us / 1000
        end

      avg_update_time = Enum.sum(update_times) / length(update_times)

      assert avg_update_time < 25,
             "Rapid updates averaged #{avg_update_time}ms, expected < 25ms"
    end

    test "burst updates handle efficiently" do
      # Simulate burst of updates (like market open)
      burst_size = 20

      {total_time_us, _results} =
        :timer.tc(fn ->
          for i <- 1..burst_size do
            Phoenix.PubSub.broadcast(
              Ashfolio.PubSub,
              "prices",
              {:price_updated, "SYM#{rem(i, 5)}", Decimal.new("#{100 + i}")}
            )
          end
        end)

      total_time_ms = total_time_us / 1000
      avg_per_update = total_time_ms / burst_size

      assert total_time_ms < 100,
             "Burst of #{burst_size} updates took #{total_time_ms}ms, expected < 100ms"

      assert avg_per_update < 5,
             "Average per update #{avg_per_update}ms, expected < 5ms"
    end
  end

  describe "Memory Efficiency" do
    test "memory usage stays reasonable during heavy update cycles" do
      :erlang.garbage_collect()
      initial_memory = :erlang.memory(:total)

      # Simulate heavy update cycle
      for i <- 1..100 do
        Phoenix.PubSub.broadcast(
          Ashfolio.PubSub,
          "net_worth",
          {:net_worth_updated,
           %{
             net_worth: Decimal.new("#{100_000 + i * 100}"),
             investment_value: Decimal.new("75000"),
             cash_value: Decimal.new("25000"),
             breakdown: %{}
           }}
        )

        # Simulate realistic update frequency
        if rem(i, 20) == 0 do
          Process.sleep(1)
        end
      end

      :erlang.garbage_collect()
      final_memory = :erlang.memory(:total)

      memory_increase = final_memory - initial_memory
      memory_increase_mb = memory_increase / (1024 * 1024)

      assert memory_increase_mb < 50,
             "Heavy update cycle used #{memory_increase_mb}MB, expected < 50MB"
    end

    test "PubSub subscriber cleanup works efficiently" do
      topic = "test_cleanup:"

      :erlang.garbage_collect()
      initial_memory = :erlang.memory(:total)

      # Subscribe and unsubscribe multiple times
      for _ <- 1..50 do
        Phoenix.PubSub.subscribe(Ashfolio.PubSub, topic)
        Phoenix.PubSub.broadcast(Ashfolio.PubSub, topic, {:test_message, :ok})
        Phoenix.PubSub.unsubscribe(Ashfolio.PubSub, topic)
      end

      :erlang.garbage_collect()
      final_memory = :erlang.memory(:total)

      memory_increase = final_memory - initial_memory
      memory_increase_mb = memory_increase / (1024 * 1024)

      assert memory_increase_mb < 10,
             "PubSub cleanup used #{memory_increase_mb}MB, expected < 10MB"
    end
  end

  describe "Real-time Update Simulation" do
    test "end-to-end update latency simulation under 50ms", %{} do
      # Subscribe to updates
      Phoenix.PubSub.subscribe(Ashfolio.PubSub, "net_worth")

      # Measure end-to-end latency
      start_time = System.monotonic_time(:microsecond)

      # Simulate a data change that triggers updates
      Phoenix.PubSub.broadcast(
        Ashfolio.PubSub,
        "net_worth",
        {:net_worth_updated,
         %{
           net_worth: Decimal.new("150000"),
           investment_value: Decimal.new("100000"),
           cash_value: Decimal.new("50000")
         }}
      )

      # Wait for the update
      receive do
        {:net_worth_updated, _data} ->
          end_time = System.monotonic_time(:microsecond)
          total_latency_ms = (end_time - start_time) / 1000

          # End-to-end latency should be reasonable
          assert total_latency_ms < 50,
                 "End-to-end update latency #{total_latency_ms}ms, expected < 50ms"
      after
        100 ->
          flunk("Update not received within 100ms")
      end
    end

    test "concurrent subscribers receive updates efficiently", %{} do
      topic = "concurrent_test:"

      # Create multiple subscribers
      subscriber_tasks =
        for i <- 1..5 do
          Task.async(fn ->
            Phoenix.PubSub.subscribe(Ashfolio.PubSub, topic)

            start_time = System.monotonic_time(:microsecond)

            receive do
              {:test_message, _data} ->
                end_time = System.monotonic_time(:microsecond)
                (end_time - start_time) / 1000
            after
              200 ->
                flunk("Subscriber #{i} did not receive message")
            end
          end)
        end

      # Small delay to ensure all subscriptions are active
      Process.sleep(10)

      # Broadcast to all subscribers
      Phoenix.PubSub.broadcast(
        Ashfolio.PubSub,
        topic,
        {:test_message, %{timestamp: System.monotonic_time()}}
      )

      # Collect latencies from all subscribers
      latencies = Task.await_many(subscriber_tasks, 1_000)
      avg_latency = Enum.sum(latencies) / length(latencies)
      max_latency = Enum.max(latencies)

      assert avg_latency < 30,
             "Average subscriber latency #{avg_latency}ms, expected < 30ms"

      assert max_latency < 50,
             "Max subscriber latency #{max_latency}ms, expected < 50ms"
    end
  end
end
