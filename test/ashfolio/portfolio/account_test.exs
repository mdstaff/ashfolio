defmodule Ashfolio.Portfolio.AccountTest do
  use Ashfolio.DataCase, async: false

  @moduletag :ash_resources
  @moduletag :unit
  @moduletag :fast
  @moduletag :smoke

  alias Ashfolio.Portfolio.{User, Account}
  alias Ashfolio.SQLiteHelpers

  setup do
    # Use the global default user - no concurrency issues with async: false
    user = SQLiteHelpers.get_default_user()
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
      # Default value
      assert account.account_type == :investment
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

      # Verify the specific account is deleted
      {:ok, accounts} = Ash.read(Account)
      account_ids = Enum.map(accounts, & &1.id)
      refute account.id in account_ids
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



    test "can create cash account with all attributes", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "High Yield Savings",
          platform: "Bank",
          account_type: :savings,
          interest_rate: Decimal.new("0.045"),
          minimum_balance: Decimal.new("1000.00"),
          balance: Decimal.new("5000.00"),
          user_id: user.id
        })

      assert account.name == "High Yield Savings"
      assert account.platform == "Bank"
      assert account.account_type == :savings
      assert Decimal.equal?(account.interest_rate, Decimal.new("0.045"))
      assert Decimal.equal?(account.minimum_balance, Decimal.new("1000.00"))
      assert Decimal.equal?(account.balance, Decimal.new("5000.00"))
      assert account.user_id == user.id
    end

    test "can create checking account", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Primary Checking",
          platform: "Bank",
          account_type: :checking,
          balance: Decimal.new("2500.00"),
          user_id: user.id
        })

      assert account.account_type == :checking
      assert Decimal.equal?(account.balance, Decimal.new("2500.00"))
    end

    test "can create money market account", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Money Market",
          platform: "Bank",
          account_type: :money_market,
          interest_rate: Decimal.new("0.035"),
          minimum_balance: Decimal.new("2500.00"),
          user_id: user.id
        })

      assert account.account_type == :money_market
      assert Decimal.equal?(account.interest_rate, Decimal.new("0.035"))
      assert Decimal.equal?(account.minimum_balance, Decimal.new("2500.00"))
    end

    test "can create CD account", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "12-Month CD",
          platform: "Bank",
          account_type: :cd,
          interest_rate: Decimal.new("0.055"),
          minimum_balance: Decimal.new("10000.00"),
          user_id: user.id
        })

      assert account.account_type == :cd
      assert Decimal.equal?(account.interest_rate, Decimal.new("0.055"))
      assert Decimal.equal?(account.minimum_balance, Decimal.new("10000.00"))
    end

    test "validates account_type constraints", %{user: user} do
      {:error, changeset} =
        Ash.create(Account, %{
          name: "Invalid Account",
          account_type: :invalid_type,
          user_id: user.id
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :account_type end)
    end

    test "validates non-negative interest rate", %{user: user} do
      {:error, changeset} =
        Ash.create(Account, %{
          name: "Savings Account",
          account_type: :savings,
          interest_rate: Decimal.new("-0.01"),
          user_id: user.id
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :interest_rate end)
    end

    test "validates non-negative minimum balance", %{user: user} do
      {:error, changeset} =
        Ash.create(Account, %{
          name: "Savings Account",
          account_type: :savings,
          minimum_balance: Decimal.new("-100.00"),
          user_id: user.id
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :minimum_balance end)
    end

    test "validates interest rate only for appropriate account types", %{user: user} do
      # Should fail for investment account with interest rate
      {:error, changeset} =
        Ash.create(Account, %{
          name: "Investment Account",
          account_type: :investment,
          interest_rate: Decimal.new("0.05"),
          user_id: user.id
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :interest_rate end)

      # Should fail for checking account with interest rate
      {:error, changeset} =
        Ash.create(Account, %{
          name: "Checking Account",
          account_type: :checking,
          interest_rate: Decimal.new("0.01"),
          user_id: user.id
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :interest_rate end)
    end

    test "allows interest rate for savings accounts", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Savings Account",
          account_type: :savings,
          interest_rate: Decimal.new("0.025"),
          user_id: user.id
        })

      assert Decimal.equal?(account.interest_rate, Decimal.new("0.025"))
    end

    test "allows interest rate for money market accounts", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "Money Market Account",
          account_type: :money_market,
          interest_rate: Decimal.new("0.035"),
          user_id: user.id
        })

      assert Decimal.equal?(account.interest_rate, Decimal.new("0.035"))
    end

    test "allows interest rate for CD accounts", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "CD Account",
          account_type: :cd,
          interest_rate: Decimal.new("0.045"),
          user_id: user.id
        })

      assert Decimal.equal?(account.interest_rate, Decimal.new("0.045"))
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

      # Verify our active account is in the results and all accounts are non-excluded
      active_account_ids = Enum.map(active_accounts, & &1.id)
      assert active_account.id in active_account_ids
      assert Enum.all?(active_accounts, fn account -> account.is_excluded == false end)
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

      # Verify our account is in the results and all accounts belong to the user
      user_account_ids = Enum.map(user_accounts, & &1.id)
      assert user_account.id in user_account_ids
      assert Enum.all?(user_accounts, fn account -> account.user_id == user.id end)
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

    test "by_type action returns accounts of specific type", %{user: user} do
      # Create investment account
      {:ok, investment_account} =
        Ash.create(Account, %{
          name: "Investment Account",
          account_type: :investment,
          user_id: user.id
        })

      # Create savings account
      {:ok, _savings_account} =
        Ash.create(Account, %{
          name: "Savings Account",
          account_type: :savings,
          user_id: user.id
        })

      {:ok, investment_accounts} = Account.accounts_by_type(:investment)

      # Verify our investment account is in the results and all are investment type
      investment_account_ids = Enum.map(investment_accounts, & &1.id)
      assert investment_account.id in investment_account_ids
      assert Enum.all?(investment_accounts, fn account -> account.account_type == :investment end)
    end

    test "cash_accounts action returns only cash accounts", %{user: user} do
      # Create investment account
      {:ok, _investment_account} =
        Ash.create(Account, %{
          name: "Investment Account",
          account_type: :investment,
          user_id: user.id
        })

      # Create cash accounts
      {:ok, checking_account} =
        Ash.create(Account, %{
          name: "Checking Account",
          account_type: :checking,
          user_id: user.id
        })

      {:ok, savings_account} =
        Ash.create(Account, %{
          name: "Savings Account",
          account_type: :savings,
          user_id: user.id
        })

      {:ok, money_market_account} =
        Ash.create(Account, %{
          name: "Money Market Account",
          account_type: :money_market,
          user_id: user.id
        })

      {:ok, cd_account} =
        Ash.create(Account, %{
          name: "CD Account",
          account_type: :cd,
          user_id: user.id
        })

      {:ok, cash_accounts} = Ash.read(Account, action: :cash_accounts)

      # Verify all our cash accounts are in the results
      cash_account_ids = Enum.map(cash_accounts, & &1.id)
      assert checking_account.id in cash_account_ids
      assert savings_account.id in cash_account_ids
      assert money_market_account.id in cash_account_ids
      assert cd_account.id in cash_account_ids

      # Verify all accounts are cash account types
      cash_types = [:checking, :savings, :money_market, :cd]
      assert Enum.all?(cash_accounts, fn account -> account.account_type in cash_types end)
    end

    test "investment_accounts action returns only investment accounts", %{user: user} do
      # Create investment account
      {:ok, investment_account} =
        Ash.create(Account, %{
          name: "Investment Account",
          account_type: :investment,
          user_id: user.id
        })

      # Create cash account
      {:ok, _savings_account} =
        Ash.create(Account, %{
          name: "Savings Account",
          account_type: :savings,
          user_id: user.id
        })

      {:ok, investment_accounts} = Ash.read(Account, action: :investment_accounts)

      # Verify our investment account is in the results
      investment_account_ids = Enum.map(investment_accounts, & &1.id)
      assert investment_account.id in investment_account_ids

      # Verify all accounts are investment type
      assert Enum.all?(investment_accounts, fn account -> account.account_type == :investment end)
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
      {:ok, account} =
        Ash.create(Account, %{
          name: "Test Account",
          user_id: user.id
        })

      {:ok, accounts} = Account.list()

      # Verify our account is in the results
      account_names = Enum.map(accounts, & &1.name)
      assert "Test Account" in account_names
      assert length(accounts) >= 1
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

      # Verify our active account is in the results and all are non-excluded
      active_account_ids = Enum.map(active_accounts, & &1.id)
      assert active_account.id in active_account_ids
      assert Enum.all?(active_accounts, fn account -> account.is_excluded == false end)
    end

    test "accounts_for_user function works", %{user: user} do
      {:ok, account} =
        Ash.create(Account, %{
          name: "User Account",
          user_id: user.id
        })

      {:ok, user_accounts} = Account.accounts_for_user(user.id)

      # Verify our account is in the results and all belong to the user
      user_account_ids = Enum.map(user_accounts, & &1.id)
      assert account.id in user_account_ids
      assert Enum.all?(user_accounts, fn acc -> acc.user_id == user.id end)
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

      # Verify the specific account is deleted
      {:ok, accounts} = Account.list()
      account_ids = Enum.map(accounts, & &1.id)
      refute account.id in account_ids
    end

    test "accounts_by_type function works", %{user: user} do
      {:ok, savings_account} =
        Ash.create(Account, %{
          name: "Savings Account",
          account_type: :savings,
          user_id: user.id
        })

      {:ok, _investment_account} =
        Ash.create(Account, %{
          name: "Investment Account",
          account_type: :investment,
          user_id: user.id
        })

      {:ok, savings_accounts} = Account.accounts_by_type(:savings)

      # Verify our savings account is in the results and all are savings type
      savings_account_ids = Enum.map(savings_accounts, & &1.id)
      assert savings_account.id in savings_account_ids
      assert Enum.all?(savings_accounts, fn account -> account.account_type == :savings end)
    end

    test "cash_accounts function works", %{user: user} do
      {:ok, checking_account} =
        Ash.create(Account, %{
          name: "Checking Account",
          account_type: :checking,
          user_id: user.id
        })

      {:ok, _investment_account} =
        Ash.create(Account, %{
          name: "Investment Account",
          account_type: :investment,
          user_id: user.id
        })

      {:ok, cash_accounts} = Account.cash_accounts()

      # Verify our checking account is in the results
      cash_account_ids = Enum.map(cash_accounts, & &1.id)
      assert checking_account.id in cash_account_ids

      # Verify all accounts are cash account types
      cash_types = [:checking, :savings, :money_market, :cd]
      assert Enum.all?(cash_accounts, fn account -> account.account_type in cash_types end)
    end

    test "investment_accounts function works", %{user: user} do
      {:ok, investment_account} =
        Ash.create(Account, %{
          name: "Investment Account",
          account_type: :investment,
          user_id: user.id
        })

      {:ok, _checking_account} =
        Ash.create(Account, %{
          name: "Checking Account",
          account_type: :checking,
          user_id: user.id
        })

      {:ok, investment_accounts} = Account.investment_accounts()

      # Verify our investment account is in the results
      investment_account_ids = Enum.map(investment_accounts, & &1.id)
      assert investment_account.id in investment_account_ids

      # Verify all accounts are investment type
      assert Enum.all?(investment_accounts, fn account -> account.account_type == :investment end)
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
