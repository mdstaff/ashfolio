# Script to benchmark Expense loading performance
# Run with: mix run scripts/benchmark_seeds.exs

alias Ashfolio.FinancialManagement.Expense
alias Ashfolio.Portfolio.Account
alias Ashfolio.FinancialManagement.TransactionCategory

defmodule Benchmark do
  def run do
    IO.puts("🚀 Starting benchmark...")
    
    # Ensure we have an account and category
    account = Ash.read!(Account) |> List.first() || create_dummy_account()
    category = Ash.read!(TransactionCategory) |> List.first() || create_dummy_category()
    
    # 1. Seed Data
    target_count = 10_000
    current_count = Ash.count!(Expense)
    
    if current_count < target_count do
      needed = target_count - current_count
      IO.puts("🌱 Seeding #{needed} expenses...")
      
      # Batch insert for speed (simulated via async tasks for Ash)
      1..needed
      |> Enum.chunk_every(100)
      |> Enum.each(fn chunk ->
        chunk
        |> Enum.map(fn _ ->
          Task.async(fn ->
            Expense.create!(%{
              amount: Decimal.new("10.00"),
              date: Date.utc_today(),
              description: "Benchmark Expense",
              account_id: account.id,
              category_id: category.id
            })
          end)
        end)
        |> Enum.each(&Task.await/1)
        IO.write(".")
      end)
      IO.puts("\n✅ Seeding complete.")
    else
      IO.puts("✅ Data already exists (#{current_count} records).")
    end
    
    # 2. Benchmark Load All
    IO.puts("\n⏱️  Benchmarking 'Load All'...")
    {time_all, _result} = :timer.tc(fn ->
      Ash.read!(Expense)
    end)
    IO.puts("   Time: #{time_all / 1000} ms")
    
    # 3. Benchmark Aggregate
    IO.puts("\n⏱️  Benchmarking 'Aggregate'...")
    {time_agg, _result} = :timer.tc(fn ->
      Ashfolio.Repo.aggregate(Expense, :sum, :amount)
    end)
    IO.puts("   Time: #{time_agg / 1000} ms")
    
    IO.puts("\n🏁 Benchmark complete.")
  end
  
  defp create_dummy_account do
    Account.create!(%{name: "Benchmark Account", type: :checking, balance: 0})
  end
  
  defp create_dummy_category do
    TransactionCategory.create!(%{name: "Benchmark Category", type: :expense})
  end
end

Benchmark.run()
