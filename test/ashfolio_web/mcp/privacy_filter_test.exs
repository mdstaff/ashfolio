defmodule AshfolioWeb.Mcp.PrivacyFilterTest do
  use Ashfolio.DataCase, async: true

  alias AshfolioWeb.Mcp.PrivacyFilter

  # Test data fixtures
  @sample_accounts [
    %{
      id: "uuid-1",
      name: "Fidelity 401k",
      type: :investment,
      balance: Decimal.new("125432.17"),
      holdings: [%{symbol: "VTI", shares: 100}, %{symbol: "VXUS", shares: 50}]
    },
    %{
      id: "uuid-2",
      name: "Chase Checking",
      type: :checking,
      balance: Decimal.new("8500.00"),
      holdings: []
    }
  ]

  @sample_transactions [
    %{
      id: "txn-1",
      type: :buy,
      symbol: "VTI",
      quantity: Decimal.new("10"),
      price: Decimal.new("250.00"),
      total_amount: Decimal.new("2500.00"),
      date: ~D[2024-06-15],
      account_name: "Fidelity 401k"
    }
  ]

  describe "current_mode/0" do
    test "returns configured mode" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :strict)
      assert PrivacyFilter.current_mode() == :strict
    end

    test "defaults to :anonymized when not configured" do
      Application.delete_env(:ashfolio, :mcp)
      assert PrivacyFilter.current_mode() == :anonymized
    end

    test "Process dictionary override takes precedence over Application config" do
      # Set Application config to :full
      Application.put_env(:ashfolio, :mcp, privacy_mode: :full)

      # Override with Process dictionary (for thread-safe testing)
      Process.put(:mcp_privacy_mode, :strict)

      # Process dictionary should take precedence
      assert PrivacyFilter.current_mode() == :strict

      # Cleanup
      Process.delete(:mcp_privacy_mode)

      # After cleanup, should fall back to Application config
      assert PrivacyFilter.current_mode() == :full
    end
  end

  describe "filter_result/3 with :strict mode" do
    setup do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :strict)
      :ok
    end

    test "accounts become count and total only" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      assert result.account_count == 2
      assert Map.has_key?(result, :total_value)
      refute Map.has_key?(result, :accounts)
      refute result |> inspect() |> String.contains?("Fidelity")
      refute result |> inspect() |> String.contains?("125432")
    end

    test "transactions become summary only" do
      result = PrivacyFilter.filter_result(@sample_transactions, :list_transactions)

      assert result.transaction_count == 1
      assert Map.has_key?(result, :by_type)
      refute result |> inspect() |> String.contains?("VTI")
      refute result |> inspect() |> String.contains?("2500")
    end
  end

  describe "filter_result/3 with :anonymized mode" do
    setup do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized)
      :ok
    end

    test "account names become letter IDs" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      account_ids = Enum.map(result.accounts, & &1.id)
      assert "A" in account_ids
      assert "B" in account_ids
      refute Enum.any?(result.accounts, &(&1[:name] == "Fidelity 401k"))
    end

    test "balances become weights" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      weights = Enum.map(result.accounts, & &1.weight)
      assert_in_delta Enum.sum(weights), 1.0, 0.01
      refute result |> inspect() |> String.contains?("125432")
    end

    test "net worth becomes tier" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      assert result.portfolio.value_tier in [:five_figures, :six_figures, :seven_figures]
    end

    test "symbols become asset classes" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      first_account = hd(result.accounts)
      assert Map.has_key?(first_account, :asset_classes)
      refute first_account |> inspect() |> String.contains?("VTI")
    end

    test "dates become relative strings" do
      result = PrivacyFilter.filter_result(@sample_transactions, :list_transactions)

      assert result.summary.date_range.oldest_relative =~ ~r/(ago|today|yesterday)/
    end

    test "ratios pass through unchanged" do
      input = %{
        savings_rate: 0.22,
        debt_to_income: 0.15,
        total_value: Decimal.new("100000")
      }

      result = PrivacyFilter.filter_result(input, :get_portfolio_summary)

      assert result.ratios.savings_rate == 0.22
      assert result.ratios.debt_to_income == 0.15
    end
  end

  describe "filter_result/3 with :standard mode" do
    setup do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :standard)
      :ok
    end

    test "account names are included" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      names = Enum.map(result.accounts, & &1.name)
      assert "Fidelity 401k" in names
    end

    test "exact balances still hidden" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      # Standard shows names but not exact amounts
      refute result |> inspect() |> String.contains?("125432.17")
    end

    test "transaction summaries include account names" do
      result = PrivacyFilter.filter_result(@sample_transactions, :list_transactions)

      assert result |> inspect() |> String.contains?("Fidelity")
    end
  end

  describe "filter_result/3 with :full mode" do
    setup do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :full)
      :ok
    end

    test "returns unfiltered data" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      assert result == @sample_accounts
    end

    test "all sensitive data included" do
      result = PrivacyFilter.filter_result(@sample_accounts, :list_accounts)

      assert result |> inspect() |> String.contains?("Fidelity 401k")
      assert result |> inspect() |> String.contains?("125432.17")
      assert result |> inspect() |> String.contains?("VTI")
    end
  end

  describe "mode_allows?/2" do
    test ":strict allows only aggregate tools" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :strict)

      assert PrivacyFilter.mode_allows?(:get_portfolio_summary, :strict)
      refute PrivacyFilter.mode_allows?(:list_transactions, :strict)
    end

    test ":full allows all tools" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :full)

      assert PrivacyFilter.mode_allows?(:list_accounts, :full)
      assert PrivacyFilter.mode_allows?(:list_transactions, :full)
      assert PrivacyFilter.mode_allows?(:calculate_tax_lots, :full)
    end
  end

  describe "edge cases" do
    test "empty list returns empty result" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized)

      result = PrivacyFilter.filter_result([], :list_accounts)

      assert result.accounts == []
      assert result.portfolio.account_count == 0
    end

    test "nil input handled gracefully" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized)

      result = PrivacyFilter.filter_result(nil, :list_accounts)

      assert result == %{accounts: [], portfolio: %{account_count: 0}}
    end

    test "unknown tool type passes through with warning" do
      Application.put_env(:ashfolio, :mcp, privacy_mode: :anonymized)

      # Should log warning but not crash
      result = PrivacyFilter.filter_result(%{foo: "bar"}, :unknown_tool)

      assert result == %{foo: "bar"}
    end
  end
end
