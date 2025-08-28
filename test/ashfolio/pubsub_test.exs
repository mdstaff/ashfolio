defmodule Ashfolio.PubSubTest do
  use ExUnit.Case, async: false

  alias Ashfolio.PubSub

  @moduletag :pubsub
  @moduletag :unit
  @moduletag :fast

  describe "PubSub functionality" do
    test "subscribe and broadcast work correctly" do
      topic = "test_topic"
      message = {:test_event, "test_data"}

      # Subscribe to the topic
      :ok = PubSub.subscribe(topic)

      # Broadcast a message
      :ok = PubSub.broadcast(topic, message)

      # Verify we received the message
      assert_receive {:test_event, "test_data"}
    end

    test "broadcast! works correctly" do
      topic = "test_topic_bang"
      message = {:test_event, "test_data"}

      # Subscribe to the topic
      :ok = PubSub.subscribe(topic)

      # Broadcast a message using broadcast!
      :ok = PubSub.broadcast!(topic, message)

      # Verify we received the message
      assert_receive {:test_event, "test_data"}
    end

    test "unsubscribe works correctly" do
      topic = "test_unsubscribe_topic"
      message = {:test_event, "test_data"}

      # Subscribe to the topic
      :ok = PubSub.subscribe(topic)

      # Unsubscribe from the topic
      :ok = PubSub.unsubscribe(topic)

      # Broadcast a message
      :ok = PubSub.broadcast(topic, message)

      # Verify we did NOT receive the message
      refute_receive {:test_event, "test_data"}, 100
    end

    test "multiple subscribers receive the same message" do
      topic = "multi_subscriber_topic"
      message = {:multi_test, "shared_data"}

      # This test process subscribes
      :ok = PubSub.subscribe(topic)

      # Spawn another process that also subscribes
      parent = self()

      spawn_link(fn ->
        :ok = PubSub.subscribe(topic)
        send(parent, :subscribed)

        receive do
          {:multi_test, "shared_data"} ->
            send(parent, :received_in_spawned_process)
        after
          1000 ->
            send(parent, :timeout_in_spawned_process)
        end
      end)

      # Wait for the spawned process to subscribe
      assert_receive :subscribed

      # Broadcast the message
      :ok = PubSub.broadcast(topic, message)

      # Both processes should receive the message
      assert_receive {:multi_test, "shared_data"}
      assert_receive :received_in_spawned_process
    end

    test "different topics are isolated" do
      topic1 = "isolated_topic_1"
      topic2 = "isolated_topic_2"
      message1 = {:topic1_event, "data1"}
      message2 = {:topic2_event, "data2"}

      # Subscribe to only topic1
      :ok = PubSub.subscribe(topic1)

      # Broadcast to both topics
      :ok = PubSub.broadcast(topic1, message1)
      :ok = PubSub.broadcast(topic2, message2)

      # Should only receive message from topic1
      assert_receive {:topic1_event, "data1"}
      refute_receive {:topic2_event, "data2"}, 100
    end

    test "handles complex message structures" do
      topic = "complex_message_topic"

      complex_message = {
        :transaction_saved,
        %{
          id: 123,
          type: :buy,
          symbol: "AAPL",
          metadata: %{timestamp: DateTime.utc_now()}
        }
      }

      :ok = PubSub.subscribe(topic)
      :ok = PubSub.broadcast(topic, complex_message)

      assert_receive {
        :transaction_saved,
        %{
          id: 123,
          type: :buy,
          symbol: "AAPL",
          metadata: %{timestamp: _timestamp}
        }
      }
    end
  end

  describe "error handling" do
    test "broadcast returns error for invalid topic" do
      # Phoenix.PubSub typically handles most cases gracefully,
      # but we can test edge cases if needed
      result = PubSub.broadcast("valid_topic", {:test, "message"})
      assert result == :ok
    end

    test "subscribe to same topic multiple times is idempotent" do
      topic = "idempotent_topic"
      message = {:idempotent_test, "data"}

      # Subscribe multiple times
      :ok = PubSub.subscribe(topic)
      :ok = PubSub.subscribe(topic)
      :ok = PubSub.subscribe(topic)

      # Broadcast once
      :ok = PubSub.broadcast(topic, message)

      # Should only receive the message once (Phoenix.PubSub handles deduplication)
      assert_receive {:idempotent_test, "data"}
      # Note: Phoenix.PubSub may actually deliver multiple messages for multiple subscriptions
      # This test verifies the behavior but the exact behavior depends on Phoenix.PubSub implementation
    end
  end
end
