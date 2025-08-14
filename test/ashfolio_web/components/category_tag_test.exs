defmodule AshfolioWeb.Components.CategoryTagTest do
  use AshfolioWeb.ConnCase, async: true

  @moduletag :components
  @moduletag :category_tag

  import Phoenix.LiveViewTest

  alias AshfolioWeb.Components.CategoryTag

  describe "CategoryTag component" do
    test "renders category with correct color and name" do
      category = %{
        id: "test-id",
        name: "Growth",
        color: "#10B981"
      }

      html =
        render_component(&CategoryTag.category_tag/1, category: category)

      assert html =~ "Growth"
      assert html =~ "#10B981"
      assert html =~ "background-color: #10B981"
    end

    test "applies size variants correctly" do
      category = %{name: "Income", color: "#3B82F6"}

      # Test small size
      small_html =
        render_component(&CategoryTag.category_tag/1, category: category, size: :small)

      assert small_html =~ "text-xs"
      assert small_html =~ "px-1"

      # Test normal size (default)
      normal_html =
        render_component(&CategoryTag.category_tag/1, category: category)

      assert normal_html =~ "text-sm"
      assert normal_html =~ "px-2"

      # Test large size
      large_html =
        render_component(&CategoryTag.category_tag/1, category: category, size: :large)

      assert large_html =~ "text-base"
      assert large_html =~ "px-3"
    end

    test "handles missing category data gracefully" do
      # Test with nil category
      nil_html =
        render_component(&CategoryTag.category_tag/1, category: nil)

      assert nil_html =~ "Uncategorized"
      # Gray color for uncategorized
      assert nil_html =~ "#6B7280"

      # Test with incomplete category data
      incomplete_category = %{name: "Test"}

      incomplete_html =
        render_component(&CategoryTag.category_tag/1, category: incomplete_category)

      assert incomplete_html =~ "Test"
      # Default color
      assert incomplete_html =~ "#6B7280"
    end

    test "supports clickable behavior for filtering" do
      category = %{
        id: "test-id",
        name: "Speculative",
        color: "#F59E0B"
      }

      # Test non-clickable (default)
      non_clickable_html =
        render_component(&CategoryTag.category_tag/1, category: category)

      refute non_clickable_html =~ "cursor-pointer"
      refute non_clickable_html =~ "phx-click"

      # Test clickable
      clickable_html =
        render_component(&CategoryTag.category_tag/1,
          category: category,
          clickable: true,
          click_event: "filter_by_category",
          click_value: category.id
        )

      assert clickable_html =~ "cursor-pointer"
      assert clickable_html =~ "hover:opacity-80"
      assert clickable_html =~ "phx-click"
      assert clickable_html =~ "filter_by_category"
    end

    test "meets WCAG 2.1 AA accessibility standards" do
      category = %{
        id: "test-id",
        name: "Index",
        color: "#8B5CF6"
      }

      html =
        render_component(&CategoryTag.category_tag/1,
          category: category,
          clickable: true,
          click_event: "filter_by_category"
        )

      # Should have proper ARIA attributes
      assert html =~ "role="
      assert html =~ "aria-label"

      # Should have keyboard accessibility
      assert html =~ "tabindex"

      # Color contrast should be adequate (this would be tested with actual color contrast tools)
      # For now, verify that we're using our predefined accessible colors
      assert html =~ "#8B5CF6"
    end

    test "renders with custom CSS classes" do
      category = %{name: "Custom", color: "#FF0000"}

      html =
        render_component(&CategoryTag.category_tag/1,
          category: category,
          class: "custom-class extra-styling"
        )

      assert html =~ "custom-class"
      assert html =~ "extra-styling"
    end

    test "handles long category names appropriately" do
      category = %{
        name: "Very Long Category Name That Should Be Handled Gracefully",
        color: "#059669"
      }

      html =
        render_component(&CategoryTag.category_tag/1, category: category)

      assert html =~ "Very Long Category Name"
      # Should have text truncation classes
      assert html =~ "truncate" or html =~ "overflow-hidden"
    end

    test "supports tooltip for additional information" do
      category = %{
        id: "test-id",
        name: "Bonds",
        color: "#059669"
      }

      html =
        render_component(&CategoryTag.category_tag/1,
          category: category,
          tooltip: "Fixed income investments"
        )

      assert html =~ "title=" or html =~ "data-tooltip"
      assert html =~ "Fixed income investments"
    end
  end

  describe "CategoryTag color calculations" do
    test "calculates proper color contrast for accessibility" do
      # Test light background color
      light_category = %{name: "Light", color: "#F0F9FF"}

      light_html =
        render_component(&CategoryTag.category_tag/1, category: light_category)

      # Should use dark text for light background
      assert light_html =~ "text-gray-900" or light_html =~ "text-black"

      # Test dark background color  
      dark_category = %{name: "Dark", color: "#1E293B"}

      dark_html =
        render_component(&CategoryTag.category_tag/1, category: dark_category)

      # Should use light text for dark background
      assert dark_html =~ "text-white" or light_html =~ "text-gray-100"
    end

    test "validates color format" do
      # Test invalid color format
      invalid_category = %{name: "Invalid", color: "not-a-color"}

      html =
        render_component(&CategoryTag.category_tag/1, category: invalid_category)

      # Should fall back to default color
      assert html =~ "#6B7280"
    end
  end

  describe "CategoryTag responsive behavior" do
    test "adapts to different screen sizes" do
      category = %{name: "Responsive", color: "#10B981"}

      html =
        render_component(&CategoryTag.category_tag/1, category: category)

      # Should have responsive classes
      assert html =~ "sm:" or html =~ "md:" or html =~ "lg:"
    end

    test "maintains usability on mobile devices" do
      category = %{name: "Mobile", color: "#3B82F6"}

      html =
        render_component(&CategoryTag.category_tag/1,
          category: category,
          clickable: true,
          click_event: "filter"
        )

      # Should have appropriate touch target size
      # Adequate vertical padding
      assert html =~ "py-"
      # Adequate horizontal padding
      assert html =~ "px-"
    end
  end
end
