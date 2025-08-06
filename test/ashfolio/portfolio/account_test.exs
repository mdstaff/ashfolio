defmodule Ashfolio.Portfolio.AccountTest do
  use ExUnit.Case, async: true

  alias Ashfolio.Portfolio.{User, Account}

  setup do
    # Explicitly checkout a connection for this test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ashfolio.Repo)

    # Create a test user for each test
    {:ok, user} =
      Ash.create(User, %{
        name: "Local User",
        currency: "USD",
        locale: "en-US"
      })

    %{user: user}
  end

  describe "Account resource" do
    test "can create account with required attributes", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Schwab Brokerage",
          platform: "Schwab",
          user_id: user.id
        })

      assert account.name == "Schwab Brokerage"
      assert account.platform == "Schwab"
      # Default value
      assert account.currency == "USD"
      # Default value
      assert account.is_excluded == false
      # Default value
      assert Decimal.equal?(account.balance, Decimal.new(0))
      assert account.user_id == user.id
      assert account.id != nil
    end

    test "can create account with all attributes", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Fidelity 401k",
          platform: "Fidelity",
          currency: "USD",
          is_excluded: true,
          balance: Decimal.new("50000.00"),
          user_id: user.id
        })

      assert account.name == "Fidelity 401k"
      assert account.platform == "Fidelity"
      assert account.currency == "USD"
      assert account.is_excluded == true
      assert Decimal.equal?(account.balance, Decimal.new("50000.00"))
      assert account.user_id == user.id
    end

    test "can update account attributes", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Test Account",
          platform: "Test",
          user_id: user.id
        })

      {:ok, updated_account} =
        Ash.update(account, %{
          name: "Updated Account",
          platform: "Updated Platform",
          balance: Decimal.new("1000.00")
        })

      assert updated_account.name == "Updated Account"
      assert updated_account.platform == "Updated Platform"
      assert Decimal.equal?(updated_account.balance, Decimal.new("1000.00"))
    end

    test "can delete account", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Test Account",
          user_id: user.id
        })

      :ok = Ash.destroy(account)

      # Verify account is deleted
      {:ok, accounts} = Ash.read(Account)
      assert Enum.empty?(accounts)
    end

    test "validates required name field", %{user: user} do
      {:error, changeset} =
        Ash.create(Account, %{
          platform: "Test",
          user_id: user.id
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)
    end

    test "validates required user_id field" do
      {:error, changeset} =
        Ash.create(Account, %{
          name: "Test Account",
          platform: "Test"
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :user_id end)
    end

    test "validates USD-only currency", %{user: user} do
      {:error, changeset} =
        Ash.create(Account, %{
          name: "Test Account",
          currency: "EUR",
          user_id: user.id
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :currency end)
    end

    test "validates non-negative balance", %{user: user} do
      {:error, changeset} =
        Ash.create(Account, %{
          name: "Test Account",
          balance: Decimal.new("-100.00"),
          user_id: user.id
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :balance end)
    end
  end

  describe "Account actions" do
    test "active action returns only non-excluded accounts", %{user: user} do
      # Create active account
      {:ok, active_account} =
        Ash.create(Account, %{
          name: "Active Account",
          is_excluded: false,
          user_id: user.id
        })

      # Create excluded account
      {:ok, _excluded_account} =
        Ash.create(Account, %{
          name: "Excluded Account",
          is_excluded: true,
          user_id: user.id
        })

      {:ok, active_accounts} = Ash.read(Account, action: :active)

      assert length(active_accounts) == 1
      assert hd(active_accounts).id == active_account.id
      assert hd(active_accounts).is_excluded == false
    end

    test "by_user action returns accounts for specific user", %{user: user} do
      # Create another user
      {:ok, other_user} =
        Ash.create(User, %{
          name: "Other User",
          currency: "USD",
          locale: "en-US"
        })

      # Create account for first user
      {:ok, user_account} =
        Ash.create(Account, %{
          name: "User Account",
          user_id: user.id
        })

      # Create account for other user
      {:ok, _other_account} =
        Ash.create(Account, %{
          name: "Other Account",
          user_id: other_user.id
        })

      {:ok, user_accounts} = Account.accounts_for_user(user.id)

      assert length(user_accounts) == 1
      assert hd(user_accounts).id == user_account.id
      assert hd(user_accounts).user_id == user.id
    end

    test "toggle_exclusion action works correctly", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Test Account",
          is_excluded: false,
          user_id: user.id
        })

      {:ok, updated_account} =
        Ash.update(account, %{is_excluded: true}, action: :toggle_exclusion)

      assert updated_account.is_excluded == true
    end

    test "update_balance action works correctly", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Test Account",
          balance: Decimal.new("1000.00"),
          user_id: user.id
        })

      {:ok, updated_account} =
        Ash.update(account, %{balance: Decimal.new("2000.00")}, action: :update_balance)

      assert Decimal.equal?(updated_account.balance, Decimal.new("2000.00"))
    end
  end

  describe "Account code interface" do
    test "create function works", %{user: user} do
      {:ok, account} =
        Account.create(%{
          name: "Interface Account",
          platform: "Interface",
          user_id: user.id
        })

      assert account.name == "Interface Account"
      assert account.platform == "Interface"
    end

    test "list function works", %{user: user} do
      {:ok, _account} =
        Ash.create(Account, %{
          name: "Test Account",
          user_id: user.id
        })

      {:ok, accounts} = Account.list()

      assert length(accounts) == 1
      assert hd(accounts).name == "Test Account"
    end

    test "get_by_id function works", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Test Account",
          user_id: user.id
        })

      {:ok, found_account} = Account.get_by_id(account.id)

      assert found_account.id == account.id
      assert found_account.name == "Test Account"
    end

    test "active_accounts function works", %{user: user} do
      {:ok, active_account} =
        Ash.create(Account, %{
          name: "Active Account",
          is_excluded: false,
          user_id: user.id
        })

      {:ok, _excluded_account} =
        Ash.create(Account, %{
          name: "Excluded Account",
          is_excluded: true,
          user_id: user.id
        })

      {:ok, active_accounts} = Account.active_accounts()

      assert length(active_accounts) == 1
      assert hd(active_accounts).id == active_account.id
    end

    test "accounts_for_user function works", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "User Account",
          user_id: user.id
        })

      {:ok, user_accounts} = Account.accounts_for_user(user.id)

      assert length(user_accounts) == 1
      assert hd(user_accounts).id == account.id
    end

    test "update function works", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Original Name",
          user_id: user.id
        })

      {:ok, updated_account} = Account.update(account, %{name: "Updated Name"})

      assert updated_account.name == "Updated Name"
    end

    test "toggle_exclusion function works", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Test Account",
          is_excluded: false,
          user_id: user.id
        })

      {:ok, updated_account} = Account.toggle_exclusion(account, %{is_excluded: true})

      assert updated_account.is_excluded == true
    end

    test "update_balance function works", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Test Account",
          balance: Decimal.new("1000.00"),
          user_id: user.id
        })

      {:ok, updated_account} = Account.update_balance(account, %{balance: Decimal.new("2500.00")})

      assert Decimal.equal?(updated_account.balance, Decimal.new("2500.00"))
    end

    test "destroy function works", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Test Account",
          user_id: user.id
        })

      :ok = Account.destroy(account)

      # Verify account is deleted
      {:ok, accounts} = Account.list()
      assert Enum.empty?(accounts)
    end
  end

  describe "Account relationships" do
    test "belongs_to user relationship works", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Test Account",
          user_id: user.id
        })

      # Load the user relationship
      account_with_user = Ash.load!(account, :user)

      assert account_with_user.user.id == user.id
      assert account_with_user.user.name == user.name
    end
  end
end
