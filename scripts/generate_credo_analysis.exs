#!/usr/bin/env elixir

# Generate Credo Analysis Reports
# Creates credo-raw.json, credo-grouped.json, and credo-summary.txt

defmodule CredoAnalyzer do
  def run do
    IO.puts("📊 Generating Credo analysis reports...")

    # Run Credo and capture JSON output
    IO.puts("🔍 Running Credo analysis...")
    {output, _exit_code} = System.cmd("mix", ["credo", "--format=json"], stderr_to_stdout: true)
    File.write!("credo-raw.json", output)

    # Parse and process the data
    raw_data = Jason.decode!(output)
    issues = raw_data["issues"]

    # Generate grouped analysis
    IO.puts("📋 Processing grouped analysis...")
    generate_grouped_analysis(issues)

    # Generate summary report
    IO.puts("📄 Generating summary...")
    generate_summary_report(issues)

    IO.puts("✅ Credo analysis complete!")
    IO.puts("📁 Generated files:")
    IO.puts("   - credo-raw.json (detailed results)")
    IO.puts("   - credo-grouped.json (grouped by file)")
    IO.puts("   - credo-summary.txt (summary report)")
  end

  defp generate_grouped_analysis(issues) do
    grouped =
      issues
      |> Enum.group_by(&(&1["filename"]))
      |> Enum.map(fn {file, file_issues} ->
          %{
            "file" => file,
            "total_issues" => length(file_issues),
            "by_category" => group_and_count(file_issues, "category"),
            "by_priority" => group_and_count(file_issues, "priority"),
            "issues" => file_issues
          }
        end)
      |> Enum.sort_by(&(-&1["total_issues"]))

    File.write!("credo-grouped.json", Jason.encode!(grouped, pretty: true))
  end

  defp generate_summary_report(issues) do
    total = length(issues)

    by_category =
      issues
      |> Enum.group_by(&(&1["category"]))
      |> Enum.map(fn {cat, cat_issues} -> {cat, length(cat_issues)} end)
      |> Enum.sort_by(&(-elem(&1, 1)))

    by_file =
      issues
      |> Enum.group_by(&(&1["filename"]))
      |> Enum.map(fn {file, file_issues} -> {file, length(file_issues)} end)
      |> Enum.sort_by(&(-elem(&1, 1)))
      |> Enum.take(10)

    high_priority =
      issues
      |> Enum.filter(&(&1["priority"] <= 3))
      |> Enum.group_by(&(&1["filename"]))
      |> Enum.map(fn {file, file_issues} -> {file, length(file_issues)} end)
      |> Enum.sort_by(&(-elem(&1, 1)))

    summary_lines = [
      "# Credo Code Quality Summary - v0.4.3 Analysis",
      "",
      "Total Issues: #{total}",
      "",
      "## Issues by Category:"
    ] ++
    Enum.map(by_category, fn {cat, count} -> "- #{cat}: #{count}" end) ++
    [
      "",
      "## Top Files Needing Attention:"
    ] ++
    Enum.map(by_file, fn {file, count} -> "- #{Path.basename(file)}: #{count} issues" end) ++
    [
      "",
      "## High Priority Issues (Priority 1-3):"
    ] ++
    Enum.map(high_priority, fn {file, count} -> "- #{Path.basename(file)}: #{count} high-priority issues" end) ++
    [""]

    File.write!("credo-summary.txt", Enum.join(summary_lines, "\n"))
  end

  defp group_and_count(items, key) do
    items
    |> Enum.group_by(&(&1[key]))
    |> Enum.map(fn {value, group_items} ->
        %{"#{key}" => value, "count" => length(group_items)}
       end)
  end
end

CredoAnalyzer.run()
