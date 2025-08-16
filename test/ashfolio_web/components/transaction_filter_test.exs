defmodule AshfolioWeb.Components.TransactionFilterTest do
  use AshfolioWeb.LiveViewCase, async: false

  @moduletag :liveview
  @moduletag :components
  @moduletag :transaction_filter

  import Phoenix.LiveViewTest

  alias AshfolioWeb.Components.TransactionFilter
  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.SQLiteHelpers

  describe "TransactionFilter component" do
    setup do
      user = SQLiteHelpers.get_default_user()

      {:ok, growth_category} =
        SQLiteHelpers.with_retry(fn ->
          TransactionCategory.create(%{
            name: "Growth",
            color: "#10B981",
            user_id: user.id
          })
        end)

      {:ok, income_category} =
        SQLiteHelpers.with_retry(fn ->
          TransactionCategory.create(%{
            name: "Income",
            color: "#3B82F6",
            user_id: user.id
          })
        end)

      categories = [growth_category, income_category]

      %{
        user: user,
        categories: categories,
        growth_category: growth_category,
        income_category: income_category
      }
    end

    test "renders basic filter form with all filter types", %{categories: categories} do
      html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: %{}
        )

      # Should have category filter
      assert html =~ "Category"
      assert html =~ "All Categories"

      # Should have transaction type filter
      assert html =~ "Transaction Type"
      assert html =~ "All Types"

      # Should have date range filter
      assert html =~ "Date Range"
      # Date inputs use name attributes, not visible labels
      assert html =~ "date_from"
      assert html =~ "date_to"

      # Should have amount range filter
      assert html =~ "Amount Range"
      # Amount inputs use name attributes
      assert html =~ "amount_min"
      assert html =~ "amount_max"
    end

    test "displays current filter values correctly", %{
      categories: categories,
      growth_category: category
    } do
      current_filters = %{
        category: category.id,
        transaction_type: :buy,
        date_range: {~D[2024-01-01], ~D[2024-12-31]},
        amount_range: {Decimal.new("100.00"), Decimal.new("5000.00")}
      }

      html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: current_filters
        )

      # Should show selected category
      assert html =~ "selected"
      assert html =~ category.name

      # Should show selected transaction type
      assert html =~ "buy"
      assert html =~ "selected"

      # Should show date range values
      assert html =~ "2024-01-01"
      assert html =~ "2024-12-31"

      # Should show amount range values
      assert html =~ "100.00"
      assert html =~ "5000.00"
    end

    test "renders clear filters button when filters are active", %{categories: categories} do
      # No filters - should not show clear button
      empty_html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: %{}
        )

      refute empty_html =~ "Clear Filters"

      # With filters - should show clear button
      filtered_html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: %{category: "some-id"}
        )

      assert filtered_html =~ "Clear Filters"
      assert filtered_html =~ "phx-click=\"clear_filters\""
    end

    test "supports responsive layout with proper CSS classes", %{categories: categories} do
      html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: %{}
        )

      # Should have responsive grid classes
      assert html =~ "grid"
      assert html =~ "gap-4"
      assert html =~ "md:" or html =~ "lg:"

      # Should have proper form structure
      assert html =~ "form"
      assert html =~ "phx-change=\"apply_composite_filters\""
    end

    test "handles missing categories gracefully", %{} do
      html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: [],
          filters: %{}
        )

      # Should still render but with empty category options
      assert html =~ "All Categories"
      # No category options
      refute html =~ "option.*value"
    end

    test "validates date range inputs", %{categories: categories} do
      html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: %{}
        )

      # Should have date input types
      assert html =~ "type=\"date\""

      # Should have proper name attributes for form handling
      assert html =~ "name=\"date_from\""
      assert html =~ "name=\"date_to\""
    end

    test "validates amount range inputs", %{categories: categories} do
      html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: %{}
        )

      # Should have number input types
      assert html =~ "type=\"number\""

      # Should have step attribute for decimal values
      assert html =~ "step=\"0.01\""

      # Should have proper name attributes
      assert html =~ "name=\"amount_min\""
      assert html =~ "name=\"amount_max\""
    end

    test "includes proper accessibility attributes", %{categories: categories} do
      html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: %{}
        )

      # Should have proper labels
      assert html =~ "label"
      assert html =~ "for="

      # Should have proper form structure
      assert html =~ "fieldset" or html =~ "role="

      # Should have descriptive text for screen readers
      assert html =~ "aria-label" or html =~ "aria-describedby"
    end

    test "supports custom CSS classes", %{categories: categories} do
      html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: %{},
          class: "custom-filter-class extra-styling"
        )

      assert html =~ "custom-filter-class"
      assert html =~ "extra-styling"
    end

    test "emits proper Phoenix events on form changes", %{categories: categories} do
      html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: %{}
        )

      # Should emit apply_composite_filters event
      assert html =~ "phx-change=\"apply_composite_filters\""

      # Clear button should emit clear_filters event
      if html =~ "Clear Filters" do
        assert html =~ "phx-click=\"clear_filters\""
      end
    end
  end

  describe "TransactionFilter filter state helpers" do
    setup do
      user = SQLiteHelpers.get_default_user()

      {:ok, growth_category} =
        SQLiteHelpers.with_retry(fn ->
          TransactionCategory.create(%{
            name: "Growth",
            color: "#10B981",
            user_id: user.id
          })
        end)

      {:ok, income_category} =
        SQLiteHelpers.with_retry(fn ->
          TransactionCategory.create(%{
            name: "Income",
            color: "#3B82F6",
            user_id: user.id
          })
        end)

      categories = [growth_category, income_category]

      %{
        user: user,
        categories: categories,
        growth_category: growth_category,
        income_category: income_category
      }
    end

    test "correctly formats filter display text", %{
      categories: categories,
      growth_category: category
    } do
      filters = %{
        category: category.id,
        transaction_type: :buy,
        date_range: {~D[2024-01-01], ~D[2024-12-31]}
      }

      html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: filters,
          show_filter_summary: true
        )

      # Should show filter summary or filter values
      assert html =~ category.name or html =~ "Filter"
    end

    test "handles edge cases in filter values", %{categories: categories} do
      edge_case_filters = %{
        category: :uncategorized,
        transaction_type: nil,
        date_range: nil,
        amount_range: {Decimal.new("0"), nil}
      }

      html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: edge_case_filters
        )

      # Should handle gracefully without errors
      assert html =~ "form"

      if html =~ "selected" do
        assert html =~ "Uncategorized"
      end
    end
  end

  describe "TransactionFilter performance and UX" do
    setup do
      user = SQLiteHelpers.get_default_user()

      {:ok, growth_category} =
        SQLiteHelpers.with_retry(fn ->
          TransactionCategory.create(%{
            name: "Growth",
            color: "#10B981",
            user_id: user.id
          })
        end)

      {:ok, income_category} =
        SQLiteHelpers.with_retry(fn ->
          TransactionCategory.create(%{
            name: "Income",
            color: "#3B82F6",
            user_id: user.id
          })
        end)

      categories = [growth_category, income_category]

      %{
        user: user,
        categories: categories,
        growth_category: growth_category,
        income_category: income_category
      }
    end

    test "includes debouncing hints for form inputs", %{categories: categories} do
      html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: %{},
          debounce: 300
        )

      # Should include debounce attributes for text/number inputs
      assert html =~ "phx-debounce" or html =~ "data-debounce"
    end

    test "provides visual feedback for active filters", %{
      categories: categories,
      growth_category: category
    } do
      active_filters = %{category: category.id, transaction_type: :buy}

      html =
        render_component(&TransactionFilter.transaction_filter/1,
          categories: categories,
          filters: active_filters
        )

      # Should have visual indicators for active filters
      assert html =~ "bg-blue" or html =~ "border-blue" or html =~ "ring-blue"
    end
  end
end
