defmodule Ashfolio.PubSub do
  @moduledoc """
  Phoenix PubSub wrapper for Ashfolio application events.
  """

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(__MODULE__, topic)
  end

  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast(__MODULE__, topic, message)
  end

  def broadcast!(topic, message) do
    Phoenix.PubSub.broadcast!(__MODULE__, topic, message)
  end
end
