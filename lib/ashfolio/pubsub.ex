defmodule Ashfolio.PubSub do
  @moduledoc """
  Phoenix PubSub wrapper for Ashfolio application events.
  Provides consistent interface for broadcasting and subscribing to application events.
  """

  @pubsub Ashfolio.PubSub

  @doc """
  Subscribe to a topic.
  """
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(@pubsub, topic)
  end

  @doc """
  Broadcast a message to all subscribers of a topic.
  """
  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast(@pubsub, topic, message)
  end

  @doc """
  Broadcast a message to all subscribers of a topic, raising on failure.
  """
  def broadcast!(topic, message) do
    Phoenix.PubSub.broadcast!(@pubsub, topic, message)
  end

  @doc """
  Unsubscribe from a topic.
  """
  def unsubscribe(topic) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic)
  end
end
