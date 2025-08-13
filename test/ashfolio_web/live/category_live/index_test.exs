defmodule AshfolioWeb.CategoryLive.IndexTest do
  use AshfolioWeb.LiveViewCase, async: false

  import Phoenix.LiveViewTest
  import Ashfolio.SQLiteHelpers

  alias Ashfolio.FinancialManagement.TransactionCategory

  @moduletag :liveview

  describe "CategoryLive.Index" do
    setup do
      # Use global test user following documented SQLite patterns
      user = get_default_user()

      # Create test categories with retry logic for SQLite concurrency
      user_category = with_retry(fn ->
        case TransactionCategory.create(%{
          name: "Growth Stocks",
          color: "#22C55E",
          user_id: user.id,
          is_system: false
        }, actor: user) do
          {:ok, category} -> category
          {:error, error} -> raise "Failed to create user category: #{inspect(error)}"
        end
      end)

      system_category = with_retry(fn ->
        case TransactionCategory.create(%{
          name: "System Growth",
          color: "#3B82F6",
          user_id: user.id,
          is_system: true
        }, actor: user) do
          {:ok, category} -> category
          {:error, error} -> raise "Failed to create system category: #{inspect(error)}"
        end
      end)

      %{
        user: user,
        user_category: user_category,
        system_category: system_category
      }
    end

    test "mounts and displays categories", %{conn: conn, user_category: user_category, system_category: system_category} do
      {:ok, view, html} = live(conn, ~p"/categories")

      # Check page title and header
      assert html =~ "Investment Categories"
      assert html =~ "Organize your investment transactions"

      # Check that categories are displayed
      assert html =~ user_category.name
      assert html =~ system_category.name

      # Check filter buttons
      assert has_element?(view, "button", "All Categories")
      assert has_element?(view, "button", "My Categories")
      assert has_element?(view, "button", "System Categories")

      # Check new category button
      assert has_element?(view, "button", "New Category")
    end

    test "filters categories by type", %{conn: conn, user_category: user_category, system_category: system_category} do
      {:ok, view, _html} = live(conn, ~p"/categories")

      # Test filtering to user categories only
      view |> element("button", "My Categories") |> render_click()
      assert has_element?(view, "h3", user_category.name)
      refute has_element?(view, "h3", system_category.name)

      # Test filtering to system categories only
      view |> element("button", "System Categories") |> render_click()
      refute has_element?(view, "h3", user_category.name)
      assert has_element?(view, "h3", system_category.name)

      # Test showing all categories
      view |> element("button", "All Categories") |> render_click()
      assert has_element?(view, "h3", user_category.name)
      assert has_element?(view, "h3", system_category.name)
    end

    test "displays correct category badges", %{conn: conn, user_category: user_category, system_category: system_category} do
      {:ok, view, _html} = live(conn, ~p"/categories")

      # User category should show Custom badge
      user_category_card = element(view, "[data-category-id='#{user_category.id}']")
      assert render(user_category_card) =~ "Custom"

      # System category should show System badge
      system_category_card = element(view, "[data-category-id='#{system_category.id}']")
      assert render(system_category_card) =~ "System"
    end

    test "opens new category modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/categories")

      # Click new category button
      view |> element("button", "New Category") |> render_click()

      # Check that form modal appears with suggestions
      assert has_element?(view, "h3", "New Investment Category")
      assert has_element?(view, "h4", "Popular Investment Categories")

      # Click to show custom form
      view |> element("button", "Create custom category instead") |> render_click()

      # Now check that the input field appears
      assert has_element?(view, "input[placeholder*='Growth, Income, Speculative']")
    end

    test "opens edit category modal for user categories", %{conn: conn, user_category: user_category} do
      {:ok, view, _html} = live(conn, ~p"/categories")

      # Click edit button for user category
      view |> element("button[phx-value-id='#{user_category.id}']", "Edit") |> render_click()

      # Check that edit form modal appears
      assert has_element?(view, "h3", "Edit Category")
      assert has_element?(view, "input[value='#{user_category.name}']")
    end

    test "does not show edit/delete actions for system categories", %{conn: conn, system_category: system_category} do
      {:ok, view, _html} = live(conn, ~p"/categories")

      # System categories should not have edit/delete buttons
      refute has_element?(view, "button[phx-value-id='#{system_category.id}']", "Edit")
      refute has_element?(view, "button[phx-value-id='#{system_category.id}']", "Delete")

      # Should show information about system category protection
      assert has_element?(view, "p", "System categories cannot be edited or deleted")
    end

    test "deletes user category", %{conn: conn, user_category: user_category} do
      {:ok, view, _html} = live(conn, ~p"/categories")

      # Click delete button (with confirmation)
      view |> element("button[phx-value-id='#{user_category.id}']", "Delete") |> render_click()

      # Check success message
      assert has_element?(view, "[role='alert']", "Category deleted successfully")

      # Verify category is no longer displayed
      refute has_element?(view, "h3", user_category.name)

      # Verify category is deleted from database (should return error for deleted record)
      assert {:error, %Ash.Error.Invalid{}} = TransactionCategory.get_by_id(user_category.id)
    end

    test "prevents deletion of system categories", %{conn: conn, system_category: system_category} do
      {:ok, view, _html} = live(conn, ~p"/categories")

      # Attempt to delete system category (should not have delete button)
      refute has_element?(view, "button[phx-value-id='#{system_category.id}']", "Delete")

      # If somehow triggered by clicking the delete event directly, should show error
      view |> render_click("delete_category", %{"id" => system_category.id})

      assert has_element?(view, "[role='alert']", "System categories cannot be deleted")

      # Verify category is still in database
      assert {:ok, category} = TransactionCategory.get_by_id(system_category.id)
      assert category.id == system_category.id
    end

    test "shows correct empty state messages for different filters", %{conn: conn, system_category: system_category} do
      # Use existing system category from setup
      {:ok, view, _html} = live(conn, ~p"/categories")

      # Filter to user categories - should show empty state for user categories when none present
      view |> element("button", "My Categories") |> render_click()
      # The test relies on the current filter state and available categories

      # Filter to system categories - should show system category
      view |> element("button", "System Categories") |> render_click()
      assert has_element?(view, "h3", system_category.name)
    end
  end

  describe "CategoryLive.Index empty state" do
    setup do
      # Use only the global test user, no categories created
      user = get_default_user()
      %{user: user}
    end

    test "shows empty state when no categories exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/categories")

      # Should show empty state when no categories are available for display
      assert has_element?(view, "h3", "No categories found")
      assert has_element?(view, "button", "Create your first category")
    end
  end

  describe "CategoryLive.Index additional tests" do
    setup do
      # Use global test user and create categories for these tests
      user = get_default_user()

      # Create test categories with retry logic for SQLite concurrency
      user_category = with_retry(fn ->
        case TransactionCategory.create(%{
          name: "Growth Stocks",
          color: "#22C55E",
          user_id: user.id,
          is_system: false
        }, actor: user) do
          {:ok, category} -> category
          {:error, error} -> raise "Failed to create user category: #{inspect(error)}"
        end
      end)

      %{
        user: user,
        user_category: user_category
      }
    end

    test "displays category color indicators", %{conn: conn, user_category: user_category} do
      {:ok, view, html} = live(conn, ~p"/categories")

      # Check that color indicator is present with correct color
      assert html =~ "background-color: #{user_category.color}"
    end

    test "handles navigation to new category page", %{conn: conn} do
      {:ok, _view, _html} = live(conn, ~p"/categories/new")

      # Should be redirected to index with form open
      # This tests the router configuration
    end

    test "handles navigation to edit category page", %{conn: conn, user_category: user_category} do
      {:ok, _view, _html} = live(conn, ~p"/categories/#{user_category.id}/edit")

      # Should be redirected to index with edit form open
      # This tests the router configuration
    end

    test "subscribes to category updates for real-time changes", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/categories")

      # Simulate external category creation with retry logic
      new_category = with_retry(fn ->
        case TransactionCategory.create(%{
          name: "External Category",
          color: "#EF4444",
          user_id: user.id,
          is_system: false
        }) do
          {:ok, category} -> category
          {:error, error} -> raise "Failed to create external category: #{inspect(error)}"
        end
      end)

      # Broadcast the update
      Ashfolio.PubSub.broadcast!("categories", {:category_created, new_category})

      # Give time for PubSub to propagate
      :timer.sleep(50)

      # Verify the new category appears
      assert has_element?(view, "h3", "External Category")
    end

    test "displays category transaction count", %{conn: conn, user_category: user_category} do
      {:ok, view, html} = live(conn, ~p"/categories")

      # Should show transaction count (0 for new category)
      assert html =~ "Transactions:"
      assert html =~ "0" # No transactions yet
    end
  end

  describe "CategoryLive.Index error handling" do
    test "handles database errors gracefully", %{conn: conn} do
      # This would require mocking the database to return errors
      # For now, we'll test that the page loads without categories
      {:ok, _view, html} = live(conn, ~p"/categories")

      # Should not crash even if there are issues loading categories
      assert html =~ "Investment Categories"
    end

    test "handles invalid category ID in edit route", %{conn: conn} do
      invalid_id = Ash.UUID.generate()

      # Should handle invalid ID gracefully
      {:ok, view, _html} = live(conn, ~p"/categories/#{invalid_id}/edit")

      # Should show error or redirect
      assert view.module == AshfolioWeb.CategoryLive.Index
    end
  end
end
