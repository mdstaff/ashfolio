defmodule Mix.Tasks.CodeGps.QualityAnalyzer do
  @moduledoc """
  Handles code quality analysis including Credo and Dialyzer integration.

  Extracted from Mix.Tasks.CodeGps to reduce complexity and improve maintainability.
  """

  @doc """
  Performs comprehensive code quality analysis.
  """
  def analyze_code_quality do
    {credo_issues, credo_summary} = run_credo_analysis()

    %{
      credo_issues: credo_issues,
      dialyzer_warnings: [],
      total_issues: length(credo_issues),
      quality_score: calculate_quality_score(credo_issues, []),
      credo_summary: credo_summary
    }
  end

  @doc """
  Analyzes project routes and their existence.
  """
  def analyze_routes do
    router_file = "lib/ashfolio_web/router.ex"

    if File.exists?(router_file) do
      content = File.read!(router_file)
      extract_routes_from_content(content)
    else
      []
    end
  end

  @doc """
  Analyzes project dependencies and their usage.
  """
  def analyze_dependencies do
    mix_file = "mix.exs"

    if File.exists?(mix_file) do
      analyze_mix_dependencies(mix_file)
    else
      %{}
    end
  end

  @doc """
  Analyzes git repository freshness information.
  """
  def analyze_git_freshness do
    recent_files = get_recent_files()
    uncommitted_files = get_uncommitted_files()
    commits_ahead = get_commits_ahead()

    %{
      recent_files: recent_files,
      uncommitted_files: uncommitted_files,
      commits_ahead: commits_ahead
    }
  end

  # Private functions for code quality

  defp run_credo_analysis do
    # Capture credo output
    {output, exit_code} = System.cmd("mix", ["credo", "--format", "json"], stderr_to_stdout: true)

    case exit_code do
      0 ->
        case Jason.decode(output) do
          {:ok, %{"issues" => issues, "summary" => summary}} ->
            parsed_issues = parse_credo_issues(issues)
            summary_text = format_credo_summary(summary)
            {parsed_issues, summary_text}

          _ ->
            {[], "JSON parsing failed"}
        end

      _ ->
        # Fallback to text parsing
        issues = parse_credo_text_output(output)
        summary = extract_credo_summary_from_text(output)
        {issues, summary}
    end
  rescue
    _ ->
      {[], "Credo analysis failed"}
  end

  defp parse_credo_issues(issues) when is_list(issues) do
    Enum.map(issues, fn issue ->
      %{
        filename: Map.get(issue, "filename", ""),
        line_no: Map.get(issue, "line_no", 0),
        message: Map.get(issue, "message", ""),
        category: Map.get(issue, "category", "unknown"),
        priority: Map.get(issue, "priority", 0)
      }
    end)
  end

  defp parse_credo_issues(_), do: []

  defp format_credo_summary(%{"files" => files, "issues" => _issues}) do
    "#{files.analyzed} mods/funs, #{files.issues} files (#{files.time}s)"
  end

  defp format_credo_summary(_), do: "Summary unavailable"

  defp parse_credo_text_output(output) do
    # Simple regex-based parsing for fallback
    issues = Regex.scan(~r/([^:]+):(\d+):.*?(refactor|design|warning): (.+)/, output)

    Enum.map(issues, fn [_, filename, line_no, category, message] ->
      %{
        filename: filename,
        line_no: String.to_integer(line_no),
        message: String.trim(message),
        category: category,
        priority: 1
      }
    end)
  end

  defp extract_credo_summary_from_text(output) do
    case Regex.run(~r/Analyzed (\d+) files?, found (\d+) issues?/, output) do
      [_, files, issues] -> "#{files} files, #{issues} issues"
      _ -> "Text parsing summary"
    end
  end

  defp calculate_quality_score(credo_issues, _dialyzer_warnings) do
    base_score = 100
    # Max 40 point deduction
    credo_penalty = min(length(credo_issues) * 2, 40)

    max(base_score - credo_penalty, 0)
  end

  # Private functions for routes analysis

  defp extract_routes_from_content(content) do
    # Extract live_session and live routes
    live_routes = Regex.scan(~r/live\s+"([^"]+)",\s+(\w+)/, content)

    Map.new(live_routes, fn [_, path, module] ->
      module_name = "AshfolioWeb.#{module}"
      file_path = module_to_file_path(module_name)

      {path, %{module: module_name, exists: File.exists?(file_path)}}
    end)
  end

  defp module_to_file_path(module_name) do
    module_name
    |> String.replace("AshfolioWeb.", "")
    |> Macro.underscore()
    |> String.replace("_", "/")
    |> then(&"lib/ashfolio_web/live/#{&1}.ex")
  end

  # Private functions for dependencies analysis

  defp analyze_mix_dependencies(mix_file) do
    content = File.read!(mix_file)

    # Extract deps from mix.exs
    case Regex.run(~r/defp deps do\s*\[(.*?)\]/s, content) do
      [_, deps_content] ->
        extract_deps_from_content(deps_content)

      _ ->
        %{}
    end
  end

  defp extract_deps_from_content(content) do
    # Simple extraction of dependency names
    deps = Regex.scan(~r/{:(\w+),/, content)

    Map.new(deps, fn [_, dep_name] ->
      analyze_dependency(dep_name, content)
    end)
  end

  defp analyze_dependency(dep_name, _deps_content) do
    # Count references to this dependency across the codebase
    references = count_dependency_usage(dep_name)

    {dep_name,
     %{
       used: references > 0,
       references: references
     }}
  end

  defp count_dependency_usage(dep_name) do
    # Search for usage patterns
    search_patterns = [
      "alias #{String.capitalize(dep_name)}",
      "import #{String.capitalize(dep_name)}",
      "use #{String.capitalize(dep_name)}"
    ]

    lib_files = Path.wildcard("lib/**/*.ex")

    Enum.reduce(lib_files, 0, fn file, acc ->
      content = File.read!(file)

      matches =
        search_patterns
        |> Enum.map(&(~r/#{&1}/ |> Regex.scan(content) |> length()))
        |> Enum.sum()

      acc + matches
    end)
  end

  # Private functions for git analysis

  defp get_recent_files do
    {output, 0} =
      System.cmd("git", ["log", "--name-only", "--since=7 days ago", "--pretty=format:", "--", "lib/"],
        stderr_to_stdout: true
      )

    output
    |> String.split("\n")
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.take(5)
  rescue
    _ -> []
  end

  defp get_uncommitted_files do
    {output, _} = System.cmd("git", ["status", "--porcelain"], stderr_to_stdout: true)

    output
    |> String.split("\n")
    |> Enum.reject(&(&1 == ""))
    |> length()
  rescue
    _ -> 0
  end

  defp get_commits_ahead do
    {output, 0} = System.cmd("git", ["rev-list", "--count", "HEAD", "^origin/main"], stderr_to_stdout: true)

    output
    |> String.trim()
    |> String.to_integer()
  rescue
    _ -> 0
  end
end
