defmodule Ashfolio.FinancialManagement.TransactionCategoryTest do
  use Ashfolio.DataCase, async: false

  @moduletag :ash_resources
  @moduletag :unit
  @moduletag :fast

  alias Ashfolio.FinancialManagement.TransactionCategory
  alias Ashfolio.Portfolio.User
  alias Ashfolio.SQLiteHelpers

  setup do
    # Use the global default user - no concurrency issues with async: false
    user = SQLiteHelpers.get_default_user()
    %{user: user}
  end

  describe "TransactionCategory resource" do
    test "can create category with required attributes", %{user: user} do
      {:ok, category} =
        Ash.create(TransactionCategory, %{
          name: "Growth",
          user_id: user.id
        })

      assert category.name == "Growth"
      assert category.user_id == user.id
      assert category.is_system == false
      assert category.color == nil
      assert category.parent_category_id == nil
      assert category.id != nil
    end

    test "can create category with all attributes", %{user: user} do
      {:ok, parent_category} =
        Ash.create(TransactionCategory, %{
          name: "Equity",
          color: "#3B82F6",
          user_id: user.id
        })

      {:ok, category} =
        Ash.create(TransactionCategory, %{
          name: "Growth",
          color: "#10B981",
          is_system: true,
          user_id: user.id,
          parent_category_id: parent_category.id
        })

      assert category.name == "Growth"
      assert category.color == "#10B981"
      assert category.is_system == true
      assert category.user_id == user.id
      assert category.parent_category_id == parent_category.id
    end

    test "can update category attributes", %{user: user} do
      {:ok, category} =
        Ash.create(TransactionCategory, %{
          name: "Test Category",
          color: "#FF0000",
          user_id: user.id
        })

      {:ok, updated_category} =
        Ash.update(category, %{
          name: "Updated Category",
          color: "#00FF00"
        })

      assert updated_category.name == "Updated Category"
      assert updated_category.color == "#00FF00"
    end

    test "can delete non-system category", %{user: user} do
      {:ok, category} =
        Ash.create(TransactionCategory, %{
          name: "Test Category",
          is_system: false,
          user_id: user.id
        })

      :ok = Ash.destroy(category)

      # Verify the specific category is deleted
      {:ok, categories} = Ash.read(TransactionCategory)
      category_ids = Enum.map(categories, & &1.id)
      refute category.id in category_ids
    end

    test "validates required name field", %{user: user} do
      {:error, changeset} =
        Ash.create(TransactionCategory, %{
          user_id: user.id
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)
    end

    test "validates required user_id field" do
      {:error, changeset} =
        Ash.create(TransactionCategory, %{
          name: "Test Category"
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :user_id end)
    end




    test "validates name uniqueness per user", %{user: user} do
      # Create another user
      {:ok, other_user} =
        Ash.create(User, %{
          name: "Other User",
          currency: "USD",
          locale: "en-US"
        })

      # Create category for first user
      {:ok, _category1} =
        Ash.create(TransactionCategory, %{
          name: "Growth",
          user_id: user.id
        })

      # Should fail to create same name for same user
      {:error, changeset} =
        Ash.create(TransactionCategory, %{
          name: "Growth",
          user_id: user.id
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)

      # Should succeed to create same name for different user
      {:ok, category2} =
        Ash.create(TransactionCategory, %{
          name: "Growth",
          user_id: other_user.id
        })

      assert category2.name == "Growth"
      assert category2.user_id == other_user.id
    end

    test "prevents circular parent relationships", %{user: user} do
      {:ok, category} =
        Ash.create(TransactionCategory, %{
          name: "Test Category",
          user_id: user.id
        })

      # Try to make category its own parent
      {:error, changeset} =
        Ash.update(category, %{
          parent_category_id: category.id
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :parent_category_id end)
    end

    test "prevents updating system categories", %{user: user} do
      {:ok, system_category} =
        Ash.create(TransactionCategory, %{
          name: "System Category",
          is_system: true,
          user_id: user.id
        })

      {:error, changeset} =
        Ash.update(system_category, %{
          name: "Updated Name"
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :is_system end)
    end

    test "prevents deleting system categories", %{user: user} do
      {:ok, system_category} =
        Ash.create(TransactionCategory, %{
          name: "System Category",
          is_system: true,
          user_id: user.id
        })

      {:error, changeset} = Ash.destroy(system_category)

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :is_system end)
    end
  end

  describe "TransactionCategory actions" do
    test "by_user action returns categories for specific user", %{user: user} do
      # Create another user
      {:ok, other_user} =
        Ash.create(User, %{
          name: "Other User",
          currency: "USD",
          locale: "en-US"
        })

      # Create category for first user
      {:ok, user_category} =
        Ash.create(TransactionCategory, %{
          name: "User Category",
          user_id: user.id
        })

      # Create category for other user
      {:ok, _other_category} =
        Ash.create(TransactionCategory, %{
          name: "Other Category",
          user_id: other_user.id
        })

      {:ok, user_categories} = TransactionCategory.categories_for_user(user.id)

      # Verify our category is in the results and all categories belong to the user
      user_category_ids = Enum.map(user_categories, & &1.id)
      assert user_category.id in user_category_ids
      assert Enum.all?(user_categories, fn category -> category.user_id == user.id end)
    end

    test "system_categories action returns only system categories", %{user: user} do
      # Create system category
      {:ok, system_category} =
        Ash.create(TransactionCategory, %{
          name: "System Category",
          is_system: true,
          user_id: user.id
        })

      # Create user category
      {:ok, _user_category} =
        Ash.create(TransactionCategory, %{
          name: "User Category",
          is_system: false,
          user_id: user.id
        })

      {:ok, system_categories} = TransactionCategory.system_categories()

      # Verify our system category is in the results and all are system categories
      system_category_ids = Enum.map(system_categories, & &1.id)
      assert system_category.id in system_category_ids
      assert Enum.all?(system_categories, fn category -> category.is_system == true end)
    end

    test "user_categories action returns only user categories", %{user: user} do
      # Create system category
      {:ok, _system_category} =
        Ash.create(TransactionCategory, %{
          name: "System Category",
          is_system: true,
          user_id: user.id
        })

      # Create user category
      {:ok, user_category} =
        Ash.create(TransactionCategory, %{
          name: "User Category",
          is_system: false,
          user_id: user.id
        })

      {:ok, user_categories} = TransactionCategory.user_categories()

      # Verify our user category is in the results and all are user categories
      user_category_ids = Enum.map(user_categories, & &1.id)
      assert user_category.id in user_category_ids
      assert Enum.all?(user_categories, fn category -> category.is_system == false end)
    end

    test "root_categories action returns categories without parents", %{user: user} do
      # Create root category
      {:ok, root_category} =
        Ash.create(TransactionCategory, %{
          name: "Root Category",
          user_id: user.id
        })

      # Create child category
      {:ok, _child_category} =
        Ash.create(TransactionCategory, %{
          name: "Child Category",
          parent_category_id: root_category.id,
          user_id: user.id
        })

      {:ok, root_categories} = TransactionCategory.root_categories()

      # Verify our root category is in the results and all have no parent
      root_category_ids = Enum.map(root_categories, & &1.id)
      assert root_category.id in root_category_ids
      assert Enum.all?(root_categories, fn category -> category.parent_category_id == nil end)
    end

    test "by_parent action returns categories with specific parent", %{user: user} do
      # Create parent category
      {:ok, parent_category} =
        Ash.create(TransactionCategory, %{
          name: "Parent Category",
          user_id: user.id
        })

      # Create child category
      {:ok, child_category} =
        Ash.create(TransactionCategory, %{
          name: "Child Category",
          parent_category_id: parent_category.id,
          user_id: user.id
        })

      # Create another parent and child
      {:ok, other_parent} =
        Ash.create(TransactionCategory, %{
          name: "Other Parent",
          user_id: user.id
        })

      {:ok, _other_child} =
        Ash.create(TransactionCategory, %{
          name: "Other Child",
          parent_category_id: other_parent.id,
          user_id: user.id
        })

      {:ok, child_categories} = TransactionCategory.categories_by_parent(parent_category.id)

      # Verify our child category is in the results and all have the correct parent
      child_category_ids = Enum.map(child_categories, & &1.id)
      assert child_category.id in child_category_ids
      assert Enum.all?(child_categories, fn category -> category.parent_category_id == parent_category.id end)
    end
  end

  describe "TransactionCategory code interface" do
    test "create function works", %{user: user} do
      {:ok, category} =
        TransactionCategory.create(%{
          name: "Interface Category",
          color: "#FF5733",
          user_id: user.id
        })

      assert category.name == "Interface Category"
      assert category.color == "#FF5733"
    end

    test "list function works", %{user: user} do
      {:ok, category} =
        Ash.create(TransactionCategory, %{
          name: "Test Category",
          user_id: user.id
        })

      {:ok, categories} = TransactionCategory.list()

      # Verify our category is in the results
      category_names = Enum.map(categories, & &1.name)
      assert "Test Category" in category_names
      assert length(categories) >= 1
    end

    test "get_by_id function works", %{user: user} do
      {:ok, category} =
        Ash.create(TransactionCategory, %{
          name: "Test Category",
          user_id: user.id
        })

      {:ok, found_category} = TransactionCategory.get_by_id(category.id)

      assert found_category.id == category.id
      assert found_category.name == "Test Category"
    end

    test "categories_for_user function works", %{user: user} do
      {:ok, category} =
        Ash.create(TransactionCategory, %{
          name: "User Category",
          user_id: user.id
        })

      {:ok, user_categories} = TransactionCategory.categories_for_user(user.id)

      # Verify our category is in the results and all belong to the user
      user_category_ids = Enum.map(user_categories, & &1.id)
      assert category.id in user_category_ids
      assert Enum.all?(user_categories, fn cat -> cat.user_id == user.id end)
    end

    test "system_categories function works", %{user: user} do
      {:ok, system_category} =
        Ash.create(TransactionCategory, %{
          name: "System Category",
          is_system: true,
          user_id: user.id
        })

      {:ok, _user_category} =
        Ash.create(TransactionCategory, %{
          name: "User Category",
          is_system: false,
          user_id: user.id
        })

      {:ok, system_categories} = TransactionCategory.system_categories()

      # Verify our system category is in the results
      system_category_ids = Enum.map(system_categories, & &1.id)
      assert system_category.id in system_category_ids
      assert Enum.all?(system_categories, fn cat -> cat.is_system == true end)
    end

    test "user_categories function works", %{user: user} do
      {:ok, _system_category} =
        Ash.create(TransactionCategory, %{
          name: "System Category",
          is_system: true,
          user_id: user.id
        })

      {:ok, user_category} =
        Ash.create(TransactionCategory, %{
          name: "User Category",
          is_system: false,
          user_id: user.id
        })

      {:ok, user_categories} = TransactionCategory.user_categories()

      # Verify our user category is in the results
      user_category_ids = Enum.map(user_categories, & &1.id)
      assert user_category.id in user_category_ids
      assert Enum.all?(user_categories, fn cat -> cat.is_system == false end)
    end

    test "root_categories function works", %{user: user} do
      {:ok, root_category} =
        Ash.create(TransactionCategory, %{
          name: "Root Category",
          user_id: user.id
        })

      {:ok, _child_category} =
        Ash.create(TransactionCategory, %{
          name: "Child Category",
          parent_category_id: root_category.id,
          user_id: user.id
        })

      {:ok, root_categories} = TransactionCategory.root_categories()

      # Verify our root category is in the results
      root_category_ids = Enum.map(root_categories, & &1.id)
      assert root_category.id in root_category_ids
      assert Enum.all?(root_categories, fn cat -> cat.parent_category_id == nil end)
    end

    test "categories_by_parent function works", %{user: user} do
      {:ok, parent_category} =
        Ash.create(TransactionCategory, %{
          name: "Parent Category",
          user_id: user.id
        })

      {:ok, child_category} =
        Ash.create(TransactionCategory, %{
          name: "Child Category",
          parent_category_id: parent_category.id,
          user_id: user.id
        })

      {:ok, child_categories} = TransactionCategory.categories_by_parent(parent_category.id)

      # Verify our child category is in the results
      child_category_ids = Enum.map(child_categories, & &1.id)
      assert child_category.id in child_category_ids
      assert Enum.all?(child_categories, fn cat -> cat.parent_category_id == parent_category.id end)
    end

    test "update function works", %{user: user} do
      {:ok, category} =
        Ash.create(TransactionCategory, %{
          name: "Original Name",
          user_id: user.id
        })

      {:ok, updated_category} = TransactionCategory.update(category, %{name: "Updated Name"})

      assert updated_category.name == "Updated Name"
    end

    test "destroy function works", %{user: user} do
      {:ok, category} =
        Ash.create(TransactionCategory, %{
          name: "Test Category",
          is_system: false,
          user_id: user.id
        })

      :ok = TransactionCategory.destroy(category)

      # Verify the specific category is deleted
      {:ok, categories} = TransactionCategory.list()
      category_ids = Enum.map(categories, & &1.id)
      refute category.id in category_ids
    end

    test "get_by_name_for_user function works", %{user: user} do
      {:ok, category} =
        Ash.create(TransactionCategory, %{
          name: "Unique Category",
          user_id: user.id
        })

      {:ok, found_category} = TransactionCategory.get_by_name_for_user(user.id, "Unique Category")

      assert found_category.id == category.id
      assert found_category.name == "Unique Category"
      assert found_category.user_id == user.id
    end

    test "get_user_categories_with_children function works", %{user: user} do
      {:ok, parent_category} =
        Ash.create(TransactionCategory, %{
          name: "Parent Category",
          user_id: user.id
        })

      {:ok, child_category} =
        Ash.create(TransactionCategory, %{
          name: "Child Category",
          parent_category_id: parent_category.id,
          user_id: user.id
        })

      {:ok, categories_with_children} = TransactionCategory.get_user_categories_with_children(user.id)

      # Find our parent category in the results
      parent_in_results = Enum.find(categories_with_children, fn cat -> cat.id == parent_category.id end)
      child_in_results = Enum.find(categories_with_children, fn cat -> cat.id == child_category.id end)

      assert parent_in_results != nil
      assert child_in_results != nil
      assert child_in_results.parent_category != nil
      assert child_in_results.parent_category.id == parent_category.id
    end
  end

  describe "TransactionCategory relationships" do
    test "belongs_to user relationship works", %{user: user} do
      {:ok, category} =
        Ash.create(TransactionCategory, %{
          name: "Test Category",
          user_id: user.id
        })

      # Load the user relationship
      category_with_user = Ash.load!(category, :user)

      assert category_with_user.user.id == user.id
      assert category_with_user.user.name == user.name
    end

    test "parent/child category relationships work", %{user: user} do
      {:ok, parent_category} =
        Ash.create(TransactionCategory, %{
          name: "Parent Category",
          user_id: user.id
        })

      {:ok, child_category} =
        Ash.create(TransactionCategory, %{
          name: "Child Category",
          parent_category_id: parent_category.id,
          user_id: user.id
        })

      # Load the parent relationship
      child_with_parent = Ash.load!(child_category, :parent_category)
      assert child_with_parent.parent_category.id == parent_category.id
      assert child_with_parent.parent_category.name == "Parent Category"

      # Load the children relationship
      parent_with_children = Ash.load!(parent_category, :child_categories)
      child_ids = Enum.map(parent_with_children.child_categories, & &1.id)
      assert child_category.id in child_ids
    end
  end
end
