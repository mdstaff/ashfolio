defmodule Ashfolio.Parsing.AmountParser do
  @moduledoc """
  Rule-based parser for monetary amounts.

  Supports various formats commonly used in financial contexts:
  - Basic numbers: `100`, `1000.50`
  - Currency symbols: `$100`, `€500`, `£250`, `¥10000`, `EUR 500`
  - Thousands separators: `1,000.00`, `$10,000`
  - Abbreviations: `10k`, `1.5M`, `2B`
  - Ranges (returns midpoint): `$50-100`, `50 to 100`
  - Negative amounts: `-$100`, `($500)`

  All results are returned as `Decimal` for financial precision.

  ## Examples

      iex> AmountParser.parse("$1,234.56")
      {:ok, #Decimal<1234.56>}

      iex> AmountParser.parse("85k")
      {:ok, #Decimal<85000>}

      iex> AmountParser.parse("$50-100")
      {:ok, #Decimal<75>}
  """

  @behaviour Ashfolio.Parsing.Parseable

  alias Decimal, as: D

  # Currency symbols and codes to strip
  # Using Unicode flag for proper symbol matching
  @currency_patterns ~r/^[\$€£¥]|\s*(USD|EUR|GBP|JPY)\s*/iu

  # Multiplier suffixes
  @multipliers %{
    "k" => D.new("1000"),
    "K" => D.new("1000"),
    "m" => D.new("1000000"),
    "M" => D.new("1000000"),
    "b" => D.new("1000000000"),
    "B" => D.new("1000000000")
  }

  # =============================================================================
  # Parseable Behaviour Implementation
  # =============================================================================

  @impl true
  def name, do: "parse_amount"

  @impl true
  def description do
    "Parses monetary amounts from various formats (e.g., '$1,234', '85k', 'EUR 500')"
  end

  @impl true
  def input_schema do
    %{
      type: "object",
      properties: %{
        amount: %{
          type: "string",
          description: "Amount to parse. Supports currency symbols, thousands separators, and abbreviations (k/M/B)"
        }
      },
      required: ["amount"]
    }
  end

  @impl true
  def validate(%{"amount" => amount}) when is_binary(amount) and amount != "", do: :ok
  def validate(_), do: {:error, "amount must be a non-empty string"}

  @impl true
  def execute(%{"amount" => amount}) do
    parse(amount)
  end

  @impl true
  def can_quick_parse?(input) when is_binary(input), do: true
  def can_quick_parse?(_), do: false

  @impl true
  def quick_parse(input) when is_binary(input), do: parse(input)
  def quick_parse(_), do: {:error, "input must be a string"}

  # =============================================================================
  # Core Parsing Logic
  # =============================================================================

  @doc """
  Parses a monetary amount string into a Decimal.

  ## Examples

      iex> AmountParser.parse("$1,234.56")
      {:ok, #Decimal<1234.56>}

      iex> AmountParser.parse("invalid")
      {:error, "could not parse amount: invalid"}
  """
  @spec parse(String.t() | nil) :: {:ok, D.t()} | {:error, String.t()}
  def parse(nil), do: {:error, "amount cannot be nil"}
  def parse(""), do: {:error, "amount cannot be empty"}

  def parse(input) when is_binary(input) do
    input
    |> String.trim()
    |> handle_range()
    |> case do
      {:range, low, high} ->
        with {:ok, low_dec} <- parse_single(low),
             {:ok, high_dec} <- parse_single(high) do
          # Return midpoint for ranges
          {:ok, D.div(D.add(low_dec, high_dec), 2)}
        end

      {:single, value} ->
        parse_single(value)
    end
  end

  def parse(_), do: {:error, "amount must be a string"}

  # =============================================================================
  # Private Helpers
  # =============================================================================

  defp handle_range(input) do
    cond do
      # Check for "X to Y" format
      String.contains?(input, " to ") ->
        [low, high] = String.split(input, " to ", parts: 2)
        {:range, String.trim(low), String.trim(high)}

      # Check for "X-Y" format (but not "-X" negative)
      Regex.match?(~r/\d+-\$?\d/, input) ->
        # Split on hyphen between digits
        case Regex.split(~r/(?<=\d)-(?=\$?\d)/, input, parts: 2) do
          [low, high] -> {:range, low, high}
          _ -> {:single, input}
        end

      true ->
        {:single, input}
    end
  end

  defp parse_single(input) do
    input
    |> normalize()
    |> extract_number()
  end

  defp normalize(input) do
    input
    |> String.trim()
    |> handle_negative_notation()
  end

  defp handle_negative_notation(input) do
    # Handle accounting notation: ($500) -> -500
    case Regex.run(~r/^\((.+)\)$/, input) do
      [_, inner] -> "-" <> inner
      nil -> input
    end
  end

  defp extract_number(input) do
    # Check for leading negative sign
    {negative, rest} =
      case input do
        "-" <> remainder -> {true, remainder}
        _ -> {false, input}
      end

    # Remove currency symbols/codes
    cleaned = Regex.replace(@currency_patterns, rest, "")

    # Remove thousands separators (commas)
    cleaned = String.replace(cleaned, ",", "")

    # Trim any remaining whitespace
    cleaned = String.trim(cleaned)

    # Check for multiplier suffix
    {base, multiplier} = extract_multiplier(cleaned)

    # Try to parse as decimal
    case parse_decimal(base) do
      {:ok, decimal} ->
        result = D.mult(decimal, multiplier)
        {:ok, if(negative, do: D.negate(result), else: result)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_multiplier(input) do
    case Regex.run(~r/^([\d.]+)([kKmMbB])$/, input) do
      [_, number, suffix] ->
        {number, Map.get(@multipliers, suffix, D.new(1))}

      nil ->
        {input, D.new(1)}
    end
  end

  defp parse_decimal(input) do
    case D.parse(input) do
      {decimal, ""} ->
        {:ok, decimal}

      {_decimal, _remainder} ->
        {:error, "could not parse amount: #{input}"}

      :error ->
        {:error, "could not parse amount: #{input}"}
    end
  end
end
