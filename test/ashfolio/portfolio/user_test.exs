defmodule Ashfolio.Portfolio.UserTest do
  use Ashfolio.DataCase, async: false

  @moduletag :ash_resources
  @moduletag :unit
  @moduletag :fast
  @moduletag :smoke

  alias Ashfolio.Portfolio.User

  setup do
    # Use the global default user for most tests
    user = Ashfolio.SQLiteHelpers.get_default_user()
    %{user: user}
  end

  describe "User resource" do
    test "has correct default attributes", %{user: user} do
      # Check default values
      assert user.name == "Test User"
      assert user.currency == "USD"
      assert user.locale == "en-US"
      assert user.id != nil
    end

    test "can update user preferences", %{user: user} do
      # Update preferences
      {:ok, updated_user} =
        Ash.update(
          user,
          %{
            name: "John Doe",
            locale: "en-CA"
          },
          action: :update_preferences
        )

      assert updated_user.name == "John Doe"
      assert updated_user.locale == "en-CA"
      # Should remain unchanged
      assert updated_user.currency == "USD"
    end

    test "validates required fields", %{user: user} do
      # Try to update with empty name
      {:error, changeset} = Ash.update(user, %{name: ""}, action: :update_preferences)

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)
    end

    test "validates USD-only currency" do
      # Try to create a user with non-USD currency (this should fail validation)
      {:error, changeset} =
        User.create( %{
          name: "Test User",
          currency: "EUR",
          locale: "en-US"
        })

      assert changeset.errors != []
      # Check that there's a currency validation error
      assert Enum.any?(changeset.errors, fn error -> error.field == :currency end)
    end

    test "default_user action works correctly" do
      # Create a user first
      {:ok, _user} =
        User.create( %{
          name: "Test User",
          currency: "USD",
          locale: "en-US"
        })

      # Test the default_user action returns the first user
      {:ok, [user]} = Ash.read(User, action: :default_user)
      assert user.name != nil
      assert user.currency == "USD"
    end

    test "code interface works correctly", %{user: user} do
      # Test update through code interface
      {:ok, updated_user} = User.update_preferences(user, %{name: "Test User"})
      assert updated_user.name == "Test User"
    end
  end

  describe "User validations" do
    test "validates name presence", %{user: user} do
      {:error, changeset} = Ash.update(user, %{name: nil}, action: :update_preferences)

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)
    end

    test "validates locale presence", %{user: user} do
      {:error, changeset} = Ash.update(user, %{locale: nil}, action: :update_preferences)

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :locale end)
    end
  end
end
