defmodule Ashfolio.Portfolio.AccountTest do
  use Ashfolio.DataCase, async: false

  @moduletag :ash_resources
  @moduletag :unit
  @moduletag :fast
  @moduletag :smoke

  alias Ashfolio.Portfolio.Account

  setup do
    # Database-as-user architecture: No user entity needed
    %{}
  end

  describe "Account resource" do
    test "can create account with required attributes" do
      {:ok, account} =
        Account.create(%{
          name: "Schwab Brokerage",
          platform: "Schwab"
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
      # Database-as-user architecture: No user_id field needed
      assert account.id != nil
    end

    test "can create account with all attributes" do
      {:ok, account} =
        Account.create(%{
          name: "Fidelity 401k",
          platform: "Fidelity",
          currency: "USD",
          is_excluded: true,
          balance: Decimal.new("50000.00")
        })

      assert account.name == "Fidelity 401k"
      assert account.platform == "Fidelity"
      assert account.currency == "USD"
      assert account.is_excluded == true
      assert Decimal.equal?(account.balance, Decimal.new("50000.00"))
      # Database-as-user architecture: No user_id field needed
    end

    test "can update account attributes" do
      {:ok, account} =
        Account.create(%{
          name: "Test Account",
          platform: "Test"
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

    test "can delete account" do
      {:ok, account} =
        Account.create(%{
          name: "Test Account"
        })

      :ok = Ash.destroy(account)

      # Verify the specific account is deleted
      {:ok, accounts} = Ash.read(Account)
      account_ids = Enum.map(accounts, & &1.id)
      refute account.id in account_ids
    end

    test "validates required name field" do
      {:error, changeset} =
        Account.create(%{
          platform: "Test"
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)
    end

    # Database-as-user architecture: No user_id validation needed
    # All accounts belong to the database user by default

    test "can create cash account with all attributes" do
      {:ok, account} =
        Account.create(%{
          name: "High Yield Savings",
          platform: "Bank",
          account_type: :savings,
          interest_rate: Decimal.new("0.045"),
          minimum_balance: Decimal.new("1000.00"),
          balance: Decimal.new("5000.00")
        })

      assert account.name == "High Yield Savings"
      assert account.platform == "Bank"
      assert account.account_type == :savings
      assert Decimal.equal?(account.interest_rate, Decimal.new("0.045"))
      assert Decimal.equal?(account.minimum_balance, Decimal.new("1000.00"))
      assert Decimal.equal?(account.balance, Decimal.new("5000.00"))
      # Database-as-user architecture: No user_id field needed
    end

    test "can create checking account" do
      {:ok, account} =
        Account.create(%{
          name: "Primary Checking",
          platform: "Bank",
          account_type: :checking,
          balance: Decimal.new("2500.00")
        })

      assert account.account_type == :checking
      assert Decimal.equal?(account.balance, Decimal.new("2500.00"))
    end

    test "can create money market account" do
      {:ok, account} =
        Account.create(%{
          name: "Money Market",
          platform: "Bank",
          account_type: :money_market,
          interest_rate: Decimal.new("0.035"),
          minimum_balance: Decimal.new("2500.00")
        })

      assert account.account_type == :money_market
      assert Decimal.equal?(account.interest_rate, Decimal.new("0.035"))
      assert Decimal.equal?(account.minimum_balance, Decimal.new("2500.00"))
    end

    test "can create CD account" do
      {:ok, account} =
        Account.create(%{
          name: "12-Month CD",
          platform: "Bank",
          account_type: :cd,
          interest_rate: Decimal.new("0.055"),
          minimum_balance: Decimal.new("10000.00")
        })

      assert account.account_type == :cd
      assert Decimal.equal?(account.interest_rate, Decimal.new("0.055"))
      assert Decimal.equal?(account.minimum_balance, Decimal.new("10000.00"))
    end

    test "validates account_type constraints" do
      {:error, changeset} =
        Account.create(%{
          name: "Invalid Account",
          account_type: :invalid_type
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :account_type end)
    end

    test "validates non-negative interest rate" do
      {:error, changeset} =
        Account.create(%{
          name: "Savings Account",
          account_type: :savings,
          interest_rate: Decimal.new("-0.01")
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :interest_rate end)
    end

    test "validates non-negative minimum balance" do
      {:error, changeset} =
        Account.create(%{
          name: "Savings Account",
          account_type: :savings,
          minimum_balance: Decimal.new("-100.00")
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :minimum_balance end)
    end

    test "validates interest rate only for appropriate account types" do
      # Should fail for investment account with interest rate
      {:error, changeset} =
        Account.create(%{
          name: "Investment Account",
          account_type: :investment,
          interest_rate: Decimal.new("0.05")
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :interest_rate end)

      # Should fail for checking account with interest rate
      {:error, changeset} =
        Account.create(%{
          name: "Checking Account",
          account_type: :checking,
          interest_rate: Decimal.new("0.01")
        })

      assert changeset.errors != []
      assert Enum.any?(changeset.errors, fn error -> error.field == :interest_rate end)
    end

    test "allows interest rate for savings accounts" do
      {:ok, account} =
        Account.create(%{
          name: "Savings Account",
          account_type: :savings,
          interest_rate: Decimal.new("0.025")
        })

      assert Decimal.equal?(account.interest_rate, Decimal.new("0.025"))
    end

    test "allows interest rate for money market accounts" do
      {:ok, account} =
        Account.create(%{
          name: "Money Market Account",
          account_type: :money_market,
          interest_rate: Decimal.new("0.035")
        })

      assert Decimal.equal?(account.interest_rate, Decimal.new("0.035"))
    end

    test "allows interest rate for CD accounts" do
      {:ok, account} =
        Account.create(%{
          name: "CD Account",
          account_type: :cd,
          interest_rate: Decimal.new("0.045")
        })

      assert Decimal.equal?(account.interest_rate, Decimal.new("0.045"))
    end
  end

  describe "Account actions" do
    test "active action returns only non-excluded accounts" do
      # Create active account
      {:ok, active_account} =
        Account.create(%{
          name: "Active Account",
          is_excluded: false
        })

      # Create excluded account
      {:ok, _excluded_account} =
        Account.create(%{
          name: "Excluded Account",
          is_excluded: true
        })

      {:ok, active_accounts} = Ash.read(Account, action: :active)

      # Verify our active account is in the results and all accounts are non-excluded
      active_account_ids = Enum.map(active_accounts, & &1.id)
      assert active_account.id in active_account_ids
      assert Enum.all?(active_accounts, fn account -> account.is_excluded == false end)
    end

    test "list action returns all accounts in database" do
      # Database-as-user architecture: All accounts belong to this database
      {:ok, account1} =
        Account.create(%{
          name: "Account 1"
        })

      {:ok, account2} =
        Account.create(%{
          name: "Account 2"
        })

      {:ok, all_accounts} = Account.list()

      # Verify our accounts are in the results
      account_ids = Enum.map(all_accounts, & &1.id)
      assert account1.id in account_ids
      assert account2.id in account_ids
      assert length(all_accounts) >= 2
    end

    test "toggle_exclusion action works correctly" do
      {:ok, account} =
        Account.create(%{
          name: "Test Account",
          is_excluded: false
        })

      {:ok, updated_account} =
        Ash.update(account, %{is_excluded: true}, action: :toggle_exclusion)

      assert updated_account.is_excluded == true
    end

    test "update_balance action works correctly" do
      {:ok, account} =
        Account.create(%{
          name: "Test Account",
          balance: Decimal.new("1000.00")
        })

      {:ok, updated_account} =
        Ash.update(account, %{balance: Decimal.new("2000.00")}, action: :update_balance)

      assert Decimal.equal?(updated_account.balance, Decimal.new("2000.00"))
    end

    test "by_type action returns accounts of specific type" do
      # Create investment account
      {:ok, investment_account} =
        Account.create(%{
          name: "Investment Account",
          account_type: :investment
        })

      # Create savings account
      {:ok, _savings_account} =
        Account.create(%{
          name: "Savings Account",
          account_type: :savings
        })

      {:ok, investment_accounts} = Account.accounts_by_type(:investment)

      # Verify our investment account is in the results and all are investment type
      investment_account_ids = Enum.map(investment_accounts, & &1.id)
      assert investment_account.id in investment_account_ids
      assert Enum.all?(investment_accounts, fn account -> account.account_type == :investment end)
    end

    test "cash_accounts action returns only cash accounts" do
      # Create investment account
      {:ok, _investment_account} =
        Account.create(%{
          name: "Investment Account",
          account_type: :investment
        })

      # Create cash accounts
      {:ok, checking_account} =
        Account.create(%{
          name: "Checking Account",
          account_type: :checking
        })

      {:ok, savings_account} =
        Account.create(%{
          name: "Savings Account",
          account_type: :savings
        })

      {:ok, money_market_account} =
        Account.create(%{
          name: "Money Market Account",
          account_type: :money_market
        })

      {:ok, cd_account} =
        Account.create(%{
          name: "CD Account",
          account_type: :cd
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

    test "investment_accounts action returns only investment accounts" do
      # Create investment account
      {:ok, investment_account} =
        Account.create(%{
          name: "Investment Account",
          account_type: :investment
        })

      # Create cash account
      {:ok, _savings_account} =
        Account.create(%{
          name: "Savings Account",
          account_type: :savings
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
    test "create function works" do
      {:ok, account} =
        Account.create(%{
          name: "Interface Account",
          platform: "Interface"
        })

      assert account.name == "Interface Account"
      assert account.platform == "Interface"
    end

    test "list function works" do
      {:ok, _account} =
        Account.create(%{
          name: "Test Account"
        })

      {:ok, accounts} = Account.list()

      # Verify our account is in the results
      account_names = Enum.map(accounts, & &1.name)
      assert "Test Account" in account_names
      assert length(accounts) >= 1
    end

    test "get_by_id function works" do
      {:ok, account} =
        Account.create(%{
          name: "Test Account"
        })

      {:ok, found_account} = Account.get_by_id(account.id)

      assert found_account.id == account.id
      assert found_account.name == "Test Account"
    end

    test "active_accounts function works" do
      {:ok, active_account} =
        Account.create(%{
          name: "Active Account",
          is_excluded: false
        })

      {:ok, _excluded_account} =
        Account.create(%{
          name: "Excluded Account",
          is_excluded: true
        })

      {:ok, active_accounts} = Account.active_accounts()

      # Verify our active account is in the results and all are non-excluded
      active_account_ids = Enum.map(active_accounts, & &1.id)
      assert active_account.id in active_account_ids
      assert Enum.all?(active_accounts, fn account -> account.is_excluded == false end)
    end

    test "list function works (database-as-user architecture)" do
      {:ok, account} =
        Account.create(%{
          name: "Database Account"
        })

      {:ok, all_accounts} = Account.list()

      # Verify our account is in the results (database-as-user architecture)
      account_ids = Enum.map(all_accounts, & &1.id)
      assert account.id in account_ids
      assert length(all_accounts) >= 1
    end

    test "update function works" do
      {:ok, account} =
        Account.create(%{
          name: "Original Name"
        })

      {:ok, updated_account} = Account.update(account, %{name: "Updated Name"})

      assert updated_account.name == "Updated Name"
    end

    test "toggle_exclusion function works" do
      {:ok, account} =
        Account.create(%{
          name: "Test Account",
          is_excluded: false
        })

      {:ok, updated_account} = Account.toggle_exclusion(account, %{is_excluded: true})

      assert updated_account.is_excluded == true
    end

    test "update_balance function works" do
      {:ok, account} =
        Account.create(%{
          name: "Test Account",
          balance: Decimal.new("1000.00")
        })

      {:ok, updated_account} = Account.update_balance(account, %{balance: Decimal.new("2500.00")})

      assert Decimal.equal?(updated_account.balance, Decimal.new("2500.00"))
    end

    test "destroy function works" do
      {:ok, account} =
        Account.create(%{
          name: "Test Account"
        })

      :ok = Account.destroy(account)

      # Verify the specific account is deleted
      {:ok, accounts} = Account.list()
      account_ids = Enum.map(accounts, & &1.id)
      refute account.id in account_ids
    end

    test "accounts_by_type function works" do
      {:ok, savings_account} =
        Account.create(%{
          name: "Savings Account",
          account_type: :savings
        })

      {:ok, _investment_account} =
        Account.create(%{
          name: "Investment Account",
          account_type: :investment
        })

      {:ok, savings_accounts} = Account.accounts_by_type(:savings)

      # Verify our savings account is in the results and all are savings type
      savings_account_ids = Enum.map(savings_accounts, & &1.id)
      assert savings_account.id in savings_account_ids
      assert Enum.all?(savings_accounts, fn account -> account.account_type == :savings end)
    end

    test "cash_accounts function works" do
      {:ok, checking_account} =
        Account.create(%{
          name: "Checking Account",
          account_type: :checking
        })

      {:ok, _investment_account} =
        Account.create(%{
          name: "Investment Account",
          account_type: :investment
        })

      {:ok, cash_accounts} = Account.cash_accounts()

      # Verify our checking account is in the results
      cash_account_ids = Enum.map(cash_accounts, & &1.id)
      assert checking_account.id in cash_account_ids

      # Verify all accounts are cash account types
      cash_types = [:checking, :savings, :money_market, :cd]
      assert Enum.all?(cash_accounts, fn account -> account.account_type in cash_types end)
    end

    test "investment_accounts function works" do
      {:ok, investment_account} =
        Account.create(%{
          name: "Investment Account",
          account_type: :investment
        })

      {:ok, _checking_account} =
        Account.create(%{
          name: "Checking Account",
          account_type: :checking
        })

      {:ok, investment_accounts} = Account.investment_accounts()

      # Verify our investment account is in the results
      investment_account_ids = Enum.map(investment_accounts, & &1.id)
      assert investment_account.id in investment_account_ids

      # Verify all accounts are investment type
      assert Enum.all?(investment_accounts, fn account -> account.account_type == :investment end)
    end
  end

  # Database-as-user architecture: No user relationships needed
  # All accounts in the database belong to the single user represented by the database
end
