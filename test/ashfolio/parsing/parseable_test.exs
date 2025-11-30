defmodule Ashfolio.Parsing.ParseableTest do
  @moduledoc """
  Tests for the Parseable behaviour definition.
  """
  use Ashfolio.DataCase, async: true

  alias Ashfolio.Parsing.Parseable

  # Test implementation module
  defmodule TestParser do
    @moduledoc false
    @behaviour Parseable

    @impl true
    def name, do: "test_parser"

    @impl true
    def description, do: "A test parser for unit tests"

    @impl true
    def input_schema do
      %{
        type: "object",
        properties: %{
          value: %{type: "string"}
        },
        required: ["value"]
      }
    end

    @impl true
    def validate(%{"value" => value}) when is_binary(value), do: :ok
    def validate(_), do: {:error, "value must be a string"}

    @impl true
    def execute(%{"value" => value}), do: {:ok, String.upcase(value)}

    # Optional callbacks implemented
    @impl true
    def can_quick_parse?("quick:" <> _), do: true
    def can_quick_parse?(_), do: false

    @impl true
    def quick_parse("quick:" <> rest), do: {:ok, String.upcase(rest)}
    def quick_parse(_), do: {:error, :not_quick_parseable}
  end

  # Minimal implementation (only required callbacks)
  defmodule MinimalParser do
    @moduledoc false
    @behaviour Parseable

    @impl true
    def name, do: "minimal_parser"

    @impl true
    def description, do: "Minimal parser with only required callbacks"

    @impl true
    def input_schema, do: %{type: "object"}

    @impl true
    def validate(_), do: :ok

    @impl true
    def execute(input), do: {:ok, input}
  end

  describe "behaviour definition" do
    test "TestParser implements all required callbacks" do
      assert TestParser.name() == "test_parser"
      assert TestParser.description() == "A test parser for unit tests"
      assert is_map(TestParser.input_schema())
      assert TestParser.validate(%{"value" => "test"}) == :ok
      assert TestParser.execute(%{"value" => "test"}) == {:ok, "TEST"}
    end

    test "MinimalParser implements only required callbacks" do
      assert MinimalParser.name() == "minimal_parser"
      assert MinimalParser.description() == "Minimal parser with only required callbacks"
      assert is_map(MinimalParser.input_schema())
      assert MinimalParser.validate(%{}) == :ok
      assert MinimalParser.execute(%{foo: "bar"}) == {:ok, %{foo: "bar"}}
    end
  end

  describe "validation" do
    test "validate returns :ok for valid input" do
      assert TestParser.validate(%{"value" => "hello"}) == :ok
    end

    test "validate returns error for invalid input" do
      assert TestParser.validate(%{"value" => 123}) == {:error, "value must be a string"}
      assert TestParser.validate(%{}) == {:error, "value must be a string"}
    end
  end

  describe "execution" do
    test "execute transforms valid input" do
      assert TestParser.execute(%{"value" => "hello"}) == {:ok, "HELLO"}
    end
  end

  describe "optional quick_parse callbacks" do
    test "can_quick_parse? detects quick-parseable input" do
      assert TestParser.can_quick_parse?("quick:test") == true
      assert TestParser.can_quick_parse?("normal input") == false
    end

    test "quick_parse handles quick-parseable input" do
      assert TestParser.quick_parse("quick:hello") == {:ok, "HELLO"}
    end

    test "quick_parse returns error for non-quick input" do
      assert TestParser.quick_parse("normal") == {:error, :not_quick_parseable}
    end
  end

  describe "Parseable.parse/2 unified interface" do
    test "uses quick_parse when available and applicable" do
      assert Parseable.parse(TestParser, "quick:fast") == {:ok, "FAST"}
    end

    test "falls back to validate + execute for non-quick input" do
      assert Parseable.parse(TestParser, %{"value" => "slow"}) == {:ok, "SLOW"}
    end

    test "returns validation error when validate fails" do
      assert Parseable.parse(TestParser, %{"value" => 123}) == {:error, "value must be a string"}
    end

    test "works with minimal parser that lacks quick_parse" do
      assert Parseable.parse(MinimalParser, %{data: "test"}) == {:ok, %{data: "test"}}
    end
  end
end
