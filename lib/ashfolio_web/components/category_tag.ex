defmodule AshfolioWeb.Components.CategoryTag do
  @moduledoc """
  Reusable category tag component for displaying investment categories.

  Provides a consistent, accessible way to display category information
  with proper color coding, size variants, and optional interactivity.

  Features:
  - Multiple size variants (small, normal, large)
  - Accessible color contrast
  - Optional click handling for filtering
  - Responsive design
  - WCAG 2.1 AA compliance
  - Graceful handling of missing data
  """

  use Phoenix.Component
  # import AshfolioWeb.CoreComponents
  import Bitwise

  @doc """
  Renders a category tag with color, name, and optional interactivity.

  ## Examples

      <.category_tag category={%{name: "Growth", color: "#10B981"}} />

      <.category_tag
        category={category}
        size={:small}
        clickable={true}
        click_event="filter_by_category"
        click_value={category.id} />

  ## Attributes

  * `category` - Category map with name and color (required)
  * `size` - Size variant: :small, :normal, :large (default: :normal)
  * `clickable` - Whether the tag is clickable (default: false)
  * `click_event` - Phoenix event name for clicks
  * `click_value` - Value to send with click event
  * `class` - Additional CSS classes
  * `tooltip` - Tooltip text for additional information
  """
  attr :category, :map, required: true, doc: "Category with name and color"
  attr :size, :atom, default: :normal, values: [:small, :normal, :large], doc: "Size variant"
  attr :clickable, :boolean, default: false, doc: "Whether tag is clickable"
  attr :click_event, :string, default: nil, doc: "Click event name"
  attr :click_value, :string, default: nil, doc: "Click event value"
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :tooltip, :string, default: nil, doc: "Tooltip text"
  attr :rest, :global, doc: "Additional HTML attributes"

  def category_tag(assigns) do
    assigns = assign_computed_values(assigns)

    ~H"""
    <span
      class={[
        "inline-flex items-center rounded-full font-medium select-none border transition-all duration-150",
        size_classes(@size),
        category_style_classes(assigns),
        @clickable && "cursor-pointer hover:shadow-sm",
        "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500",
        @class
      ]}
      style={category_style(assigns)}
      title={@tooltip}
      role={(@clickable && "button") || "text"}
      tabindex={(@clickable && "0") || nil}
      aria-label={@aria_label}
      phx-click={@clickable && @click_event}
      phx-value-category_id={@clickable && @click_value}
      {@rest}
    >
      <span
        class="w-2 h-2 rounded-full mr-1.5 flex-shrink-0"
        style={"background-color: #{@category_color}"}
        aria-hidden="true"
      >
      </span>
      <span class={[
        "truncate",
        @size == :small && "max-w-20",
        @size == :normal && "max-w-32",
        @size == :large && "max-w-48"
      ]}>
        {@category_name}
      </span>
      <%= if @clickable do %>
        <span
          class="ml-1 opacity-0 group-hover:opacity-50 transition-opacity text-xs"
          aria-hidden="true"
        >
          →
        </span>
      <% end %>
    </span>
    """
  end

  # Private helper functions

  defp assign_computed_values(assigns) do
    assigns
    |> assign_category_values()
    |> assign_color_values()
    |> assign_accessibility_values()
  end

  defp assign_category_values(assigns) do
    case assigns.category do
      nil ->
        assign(assigns,
          category_name: "Uncategorized",
          category_color: "#6B7280"
        )

      %{name: name} when is_binary(name) ->
        color = Map.get(assigns.category, :color, "#6B7280")

        assign(assigns,
          category_name: name,
          category_color: normalize_color(color)
        )

      _ ->
        assign(assigns,
          category_name: "Unknown",
          category_color: "#6B7280"
        )
    end
  end

  defp assign_color_values(assigns) do
    background_color = lighten_color(assigns.category_color, 0.9)
    text_color = calculate_text_color(assigns.category_color)

    assigns
    |> assign(:background_color, background_color)
    |> assign(:text_color, text_color)
  end

  defp assign_accessibility_values(assigns) do
    aria_label = build_aria_label(assigns)

    assign(assigns, :aria_label, aria_label)
  end

  defp size_classes(:small), do: "text-xs px-2 py-1 min-h-6"
  defp size_classes(:normal), do: "text-sm px-3 py-1.5 min-h-7"
  defp size_classes(:large), do: "text-base px-4 py-2 min-h-8"

  defp category_style_classes(assigns) do
    if assigns.category_name == "Uncategorized" do
      "border-dashed hover:border-solid"
    else
      ""
    end
  end

  defp category_style(assigns) do
    if assigns.category_name == "Uncategorized" do
      "background-color: #F3F4F6; color: #1F2937; border-color: #9CA3AF;"
    else
      "background-color: #{assigns.background_color}; color: #{assigns.text_color}; border-color: #{assigns.category_color};"
    end
  end

  defp normalize_color(color) when is_binary(color) do
    if Regex.match?(~r/^#[0-9A-Fa-f]{6}$/, color) do
      color
    else
      # Default gray
      "#6B7280"
    end
  end

  defp normalize_color(_), do: "#6B7280"

  defp lighten_color(hex_color, opacity) do
    # Convert hex to RGB and create a background with opacity
    case parse_hex_color(hex_color) do
      {r, g, b} ->
        # Create a very light background version of the color
        light_r = round(r + (255 - r) * opacity)
        light_g = round(g + (255 - g) * opacity)
        light_b = round(b + (255 - b) * opacity)

        "#" <>
          (light_r |> Integer.to_string(16) |> String.pad_leading(2, "0")) <>
          (light_g |> Integer.to_string(16) |> String.pad_leading(2, "0")) <>
          (light_b |> Integer.to_string(16) |> String.pad_leading(2, "0"))

      _ ->
        # Light gray fallback
        "#F3F4F6"
    end
  end

  defp calculate_text_color(hex_color) do
    case parse_hex_color(hex_color) do
      {r, g, b} ->
        # Calculate relative luminance using WCAG formula
        luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255

        if luminance > 0.5 do
          # Dark text for light backgrounds
          "#1F2937"
        else
          # Light text for dark backgrounds
          "#F9FAFB"
        end

      _ ->
        # Default dark text
        "#1F2937"
    end
  end

  defp parse_hex_color("#" <> hex) when byte_size(hex) == 6 do
    case Integer.parse(hex, 16) do
      {color_int, ""} ->
        r = color_int >>> 16 &&& 0xFF
        g = color_int >>> 8 &&& 0xFF
        b = color_int &&& 0xFF
        {r, g, b}

      _ ->
        nil
    end
  end

  defp parse_hex_color(_), do: nil

  defp build_aria_label(assigns) do
    base_label = "Category: #{assigns.category_name}"

    cond do
      assigns.clickable && assigns.click_event ->
        "#{base_label}. Click to filter by this category."

      assigns.tooltip ->
        "#{base_label}. #{assigns.tooltip}"

      true ->
        base_label
    end
  end
end
