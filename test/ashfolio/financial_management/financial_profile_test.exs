defmodule Ashfolio.FinancialManagement.FinancialProfileTest do
  use Ashfolio.DataCase

  alias Ashfolio.FinancialManagement.FinancialProfile

  describe "create/1" do
    @tag :unit
    test "creates a financial profile with valid attributes" do
      attrs = %{
        gross_annual_income: Decimal.new("100000.00"),
        birth_year: 1985,
        household_members: 2
      }

      assert {:ok, profile} = FinancialProfile.create(attrs)
      assert Decimal.equal?(profile.gross_annual_income, Decimal.new("100000.00"))
      assert profile.birth_year == 1985
      assert profile.household_members == 2
      assert profile.primary_residence_value == nil
      assert profile.mortgage_balance == nil
      assert profile.student_loan_balance == nil
    end

    @tag :unit
    test "fails without required fields" do
      assert {:error, _} = FinancialProfile.create(%{})
      assert {:error, _} = FinancialProfile.create(%{gross_annual_income: Decimal.new("100000")})
      assert {:error, _} = FinancialProfile.create(%{birth_year: 1985})
    end

    @tag :unit
    test "creates with optional fields" do
      attrs = %{
        gross_annual_income: Decimal.new("120000.00"),
        birth_year: 1980,
        household_members: 3,
        primary_residence_value: Decimal.new("450000.00"),
        mortgage_balance: Decimal.new("320000.00"),
        student_loan_balance: Decimal.new("25000.00")
      }

      assert {:ok, profile} = FinancialProfile.create(attrs)
      assert Decimal.equal?(profile.primary_residence_value, Decimal.new("450000.00"))
      assert Decimal.equal?(profile.mortgage_balance, Decimal.new("320000.00"))
      assert Decimal.equal?(profile.student_loan_balance, Decimal.new("25000.00"))
    end
  end

  describe "validation rules" do
    @tag :unit
    test "requires positive income" do
      attrs = %{
        gross_annual_income: Decimal.new("-1000.00"),
        birth_year: 1985
      }

      assert {:error, changeset} = FinancialProfile.create(attrs)
      assert "must be greater than 0" in errors_on(changeset).gross_annual_income
    end

    @tag :unit
    test "requires valid age range" do
      current_year = Date.utc_today().year

      # Test too young (under 18)
      attrs_young = %{
        gross_annual_income: Decimal.new("50000.00"),
        birth_year: current_year - 17
      }

      assert {:error, changeset} = FinancialProfile.create(attrs_young)
      assert "age must be between 18 and 100" in errors_on(changeset).birth_year

      # Test too old (over 100)
      attrs_old = %{
        gross_annual_income: Decimal.new("50000.00"),
        birth_year: current_year - 101
      }

      assert {:error, changeset} = FinancialProfile.create(attrs_old)
      assert "age must be between 18 and 100" in errors_on(changeset).birth_year
    end

    @tag :unit
    test "requires non-negative monetary values" do
      attrs = %{
        gross_annual_income: Decimal.new("100000.00"),
        birth_year: 1985,
        mortgage_balance: Decimal.new("-1000.00")
      }

      assert {:error, changeset} = FinancialProfile.create(attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).mortgage_balance
    end

    @tag :unit
    test "defaults household_members to 1" do
      attrs = %{
        gross_annual_income: Decimal.new("75000.00"),
        birth_year: 1990
      }

      assert {:ok, profile} = FinancialProfile.create(attrs)
      assert profile.household_members == 1
    end
  end

  describe "age calculation" do
    @tag :unit
    test "calculates current age correctly" do
      # Test with known birth year
      birth_year = 1985

      attrs = %{
        gross_annual_income: Decimal.new("100000.00"),
        birth_year: birth_year
      }

      assert {:ok, profile} = FinancialProfile.create(attrs)

      expected_age = Date.utc_today().year - birth_year
      assert FinancialProfile.calculate_age(profile) == expected_age
    end

    @tag :unit
    test "handles different birth years correctly" do
      current_year = Date.utc_today().year
      # 30 years old
      birth_year = current_year - 30

      attrs = %{
        gross_annual_income: Decimal.new("100000.00"),
        birth_year: birth_year
      }

      assert {:ok, profile} = FinancialProfile.create(attrs)
      assert FinancialProfile.calculate_age(profile) == 30
    end
  end

  describe "update/2" do
    @tag :integration
    test "updates profile attributes" do
      {:ok, profile} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("100000.00"),
          birth_year: 1985
        })

      update_attrs = %{
        gross_annual_income: Decimal.new("110000.00"),
        mortgage_balance: Decimal.new("250000.00")
      }

      assert {:ok, updated_profile} = FinancialProfile.update(profile, update_attrs)
      assert Decimal.equal?(updated_profile.gross_annual_income, Decimal.new("110000.00"))
      assert Decimal.equal?(updated_profile.mortgage_balance, Decimal.new("250000.00"))
    end
  end

  describe "read operations" do
    @tag :integration
    test "reads profile by id" do
      {:ok, profile} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("100000.00"),
          birth_year: 1985
        })

      assert {:ok, found_profile} = FinancialProfile.by_id(profile.id)
      assert found_profile.id == profile.id
      assert Decimal.equal?(found_profile.gross_annual_income, profile.gross_annual_income)
    end

    @tag :integration
    test "lists all profiles" do
      {:ok, _profile1} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("100000.00"),
          birth_year: 1985
        })

      {:ok, _profile2} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("75000.00"),
          birth_year: 1990
        })

      {:ok, profiles} = FinancialProfile.read_all()
      assert length(profiles) == 2
    end
  end

  describe "destroy/1" do
    @tag :integration
    test "destroys profile" do
      {:ok, profile} =
        FinancialProfile.create(%{
          gross_annual_income: Decimal.new("100000.00"),
          birth_year: 1985
        })

      assert :ok = FinancialProfile.destroy(profile)
      assert {:error, _} = FinancialProfile.by_id(profile.id)
    end
  end
end
