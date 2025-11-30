# Task: Audit Logging Implementation

**Phase**: 3 - Legal & Consent
**Priority**: P2
**Estimate**: 3-4 hours
**Status**: Not Started

## Objective

Implement comprehensive audit logging for MCP tool invocations, enabling compliance reporting, debugging, and security monitoring.

## Prerequisites

- [ ] Phase 1 complete
- [ ] Task P3-01 (Consent Resource) complete
- [ ] Understanding of audit requirements

## Acceptance Criteria

### Functional Requirements

1. All tool invocations logged
2. Logs include: tool name, arguments (filtered), timestamp, duration
3. Privacy-filtered arguments (no sensitive data in logs)
4. Query interface for audit reports
5. Log retention policy support

### Non-Functional Requirements

1. Logging adds < 1ms overhead
2. Async write to prevent blocking
3. Queryable within 1 second
4. Storage efficient (compressed)

## TDD Test Cases

### Test File: `test/ashfolio_web/mcp/audit_log_test.exs`

```elixir
defmodule AshfolioWeb.Mcp.AuditLogTest do
  use Ashfolio.DataCase, async: false

  alias AshfolioWeb.Mcp.AuditLog
  alias Ashfolio.Legal.McpInvocation

  describe "logging tool invocations" do
    test "log_invocation creates record" do
      {:ok, log} = AuditLog.log_invocation(%{
        tool_name: "list_accounts",
        arguments: %{},
        privacy_mode: :anonymized,
        session_id: "test-session"
      })

      assert log.tool_name == "list_accounts"
      assert log.privacy_mode == :anonymized
      assert log.session_id == "test-session"
      assert log.invoked_at != nil
    end

    test "log_invocation filters sensitive arguments" do
      {:ok, log} = AuditLog.log_invocation(%{
        tool_name: "list_transactions",
        arguments: %{
          filter: %{account_id: "uuid-123"},
          limit: 10
        },
        privacy_mode: :full,
        session_id: "test-session"
      })

      # Account ID should be filtered in anonymized modes
      logged_args = log.arguments_hash
      refute logged_args |> inspect() |> String.contains?("uuid-123")
    end

    test "log_invocation records duration" do
      {:ok, log} = AuditLog.log_invocation(%{
        tool_name: "list_accounts",
        arguments: %{},
        privacy_mode: :anonymized,
        session_id: "test",
        started_at: DateTime.add(DateTime.utc_now(), -100, :millisecond)
      })

      assert log.duration_ms >= 100
    end

    test "log_invocation records result status" do
      {:ok, success_log} = AuditLog.log_invocation(%{
        tool_name: "list_accounts",
        arguments: %{},
        privacy_mode: :anonymized,
        session_id: "test",
        result: :success
      })

      {:ok, error_log} = AuditLog.log_invocation(%{
        tool_name: "unknown_tool",
        arguments: %{},
        privacy_mode: :anonymized,
        session_id: "test",
        result: :error,
        error_code: -32602
      })

      assert success_log.result == :success
      assert error_log.result == :error
      assert error_log.error_code == -32602
    end
  end

  describe "complete_invocation/2" do
    test "updates log with result" do
      {:ok, log} = AuditLog.log_invocation(%{
        tool_name: "list_accounts",
        arguments: %{},
        privacy_mode: :anonymized,
        session_id: "test"
      })

      {:ok, completed} = AuditLog.complete_invocation(log, %{
        result: :success,
        result_count: 3
      })

      assert completed.result == :success
      assert completed.result_count == 3
      assert completed.duration_ms != nil
    end

    test "updates log with error" do
      {:ok, log} = AuditLog.log_invocation(%{
        tool_name: "list_accounts",
        arguments: %{},
        privacy_mode: :anonymized,
        session_id: "test"
      })

      {:ok, completed} = AuditLog.complete_invocation(log, %{
        result: :error,
        error_code: -32001,
        error_message: "Privacy mode insufficient"
      })

      assert completed.result == :error
      assert completed.error_code == -32001
    end
  end

  describe "query interface" do
    setup do
      # Create test logs
      for i <- 1..5 do
        AuditLog.log_invocation(%{
          tool_name: "list_accounts",
          arguments: %{},
          privacy_mode: :anonymized,
          session_id: "session-#{i}",
          result: :success
        })
      end

      for i <- 1..3 do
        AuditLog.log_invocation(%{
          tool_name: "list_transactions",
          arguments: %{},
          privacy_mode: :full,
          session_id: "session-#{i}",
          result: :error,
          error_code: -32001
        })
      end

      :ok
    end

    test "query by tool name" do
      logs = AuditLog.query(tool_name: "list_accounts")

      assert length(logs) == 5
      assert Enum.all?(logs, &(&1.tool_name == "list_accounts"))
    end

    test "query by session" do
      logs = AuditLog.query(session_id: "session-1")

      assert length(logs) == 2
    end

    test "query by date range" do
      yesterday = DateTime.add(DateTime.utc_now(), -1, :day)
      tomorrow = DateTime.add(DateTime.utc_now(), 1, :day)

      logs = AuditLog.query(from: yesterday, to: tomorrow)

      assert length(logs) == 8
    end

    test "query by result status" do
      error_logs = AuditLog.query(result: :error)

      assert length(error_logs) == 3
      assert Enum.all?(error_logs, &(&1.result == :error))
    end

    test "query with limit" do
      logs = AuditLog.query(limit: 3)

      assert length(logs) == 3
    end

    test "query returns newest first by default" do
      logs = AuditLog.query(limit: 2)

      [first, second] = logs
      assert DateTime.compare(first.invoked_at, second.invoked_at) in [:gt, :eq]
    end
  end

  describe "statistics" do
    setup do
      for _ <- 1..10 do
        AuditLog.log_invocation(%{
          tool_name: "list_accounts",
          arguments: %{},
          privacy_mode: :anonymized,
          session_id: "test",
          result: :success,
          duration_ms: :rand.uniform(100)
        })
      end

      for _ <- 1..5 do
        AuditLog.log_invocation(%{
          tool_name: "list_transactions",
          arguments: %{},
          privacy_mode: :anonymized,
          session_id: "test",
          result: :error,
          duration_ms: :rand.uniform(50)
        })
      end

      :ok
    end

    test "stats returns invocation counts" do
      stats = AuditLog.stats()

      assert stats.total_invocations == 15
      assert stats.successful_invocations == 10
      assert stats.failed_invocations == 5
    end

    test "stats returns tool breakdown" do
      stats = AuditLog.stats()

      assert stats.by_tool["list_accounts"] == 10
      assert stats.by_tool["list_transactions"] == 5
    end

    test "stats returns average duration" do
      stats = AuditLog.stats()

      assert stats.avg_duration_ms > 0
    end

    test "stats supports date range" do
      yesterday = DateTime.add(DateTime.utc_now(), -1, :day)
      stats = AuditLog.stats(from: yesterday)

      assert stats.total_invocations == 15
    end
  end

  describe "retention policy" do
    test "cleanup removes old logs" do
      # Create old log
      old_log = %McpInvocation{
        tool_name: "test",
        invoked_at: DateTime.add(DateTime.utc_now(), -100, :day),
        privacy_mode: :anonymized,
        session_id: "old"
      }
      Ashfolio.Repo.insert!(old_log)

      # Run cleanup with 90 day retention
      {:ok, deleted_count} = AuditLog.cleanup(retention_days: 90)

      assert deleted_count >= 1
    end

    test "cleanup preserves recent logs" do
      {:ok, recent} = AuditLog.log_invocation(%{
        tool_name: "test",
        arguments: %{},
        privacy_mode: :anonymized,
        session_id: "recent"
      })

      {:ok, _deleted} = AuditLog.cleanup(retention_days: 90)

      # Recent log should still exist
      assert AuditLog.get(recent.id) != nil
    end
  end

  describe "argument filtering" do
    test "hashes arguments for privacy" do
      {:ok, log} = AuditLog.log_invocation(%{
        tool_name: "list_transactions",
        arguments: %{
          filter: %{account_id: "secret-uuid"},
          limit: 10
        },
        privacy_mode: :anonymized,
        session_id: "test"
      })

      # Arguments should be hashed/filtered
      assert log.arguments_hash != nil
      assert is_binary(log.arguments_hash)
      # Original arguments not stored in plain text
      refute log |> Map.get(:arguments) |> inspect() |> String.contains?("secret-uuid")
    end

    test "stores argument shape for debugging" do
      {:ok, log} = AuditLog.log_invocation(%{
        tool_name: "list_transactions",
        arguments: %{
          filter: %{account_id: "secret"},
          sort: [%{field: "date"}],
          limit: 10
        },
        privacy_mode: :anonymized,
        session_id: "test"
      })

      # Should store argument structure
      assert log.argument_shape == %{
        "filter" => ["account_id"],
        "sort" => ["list"],
        "limit" => "integer"
      }
    end
  end
end
```

## Implementation Steps

### Step 1: Create McpInvocation Resource

```elixir
# lib/ashfolio/legal/mcp_invocation.ex

defmodule Ashfolio.Legal.McpInvocation do
  @moduledoc """
  Audit log for MCP tool invocations.
  """

  use Ash.Resource,
    domain: Ashfolio.Legal,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "mcp_invocations"
    repo Ashfolio.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :tool_name, :string do
      allow_nil? false
    end

    attribute :session_id, :string

    attribute :privacy_mode, :atom do
      constraints one_of: [:strict, :anonymized, :standard, :full]
    end

    attribute :arguments_hash, :string do
      description "SHA256 hash of arguments for correlation"
    end

    attribute :argument_shape, :map do
      description "Structure of arguments without values"
      default %{}
    end

    attribute :result, :atom do
      constraints one_of: [:pending, :success, :error]
      default :pending
    end

    attribute :result_count, :integer do
      description "Number of items returned"
    end

    attribute :error_code, :integer
    attribute :error_message, :string

    attribute :duration_ms, :integer

    attribute :invoked_at, :utc_datetime_usec do
      allow_nil? false
      default &DateTime.utc_now/0
    end

    attribute :completed_at, :utc_datetime_usec

    timestamps()
  end

  actions do
    defaults [:read]

    create :log do
      accept [
        :tool_name, :session_id, :privacy_mode,
        :arguments_hash, :argument_shape, :invoked_at
      ]
    end

    update :complete do
      accept [:result, :result_count, :error_code, :error_message, :duration_ms]

      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.change_attribute(:completed_at, DateTime.utc_now())
      end
    end

    read :query do
      argument :tool_name, :string
      argument :session_id, :string
      argument :result, :atom
      argument :from, :utc_datetime
      argument :to, :utc_datetime
      argument :limit, :integer, default: 100

      prepare fn query, _context ->
        query
        |> maybe_filter_tool_name()
        |> maybe_filter_session()
        |> maybe_filter_result()
        |> maybe_filter_date_range()
        |> Ash.Query.sort(invoked_at: :desc)
        |> Ash.Query.limit(query.arguments[:limit] || 100)
      end
    end

    action :stats, :map do
      argument :from, :utc_datetime
      argument :to, :utc_datetime

      run fn input, _context ->
        logs = __MODULE__
          |> maybe_filter_dates(input.arguments)
          |> Ash.read!()

        stats = %{
          total_invocations: length(logs),
          successful_invocations: Enum.count(logs, &(&1.result == :success)),
          failed_invocations: Enum.count(logs, &(&1.result == :error)),
          by_tool: Enum.frequencies_by(logs, & &1.tool_name),
          avg_duration_ms: average_duration(logs)
        }

        {:ok, stats}
      end
    end

    destroy :cleanup do
      argument :retention_days, :integer, default: 90

      change fn changeset, _context ->
        cutoff = DateTime.add(DateTime.utc_now(), -changeset.arguments[:retention_days], :day)
        # This is a bulk operation
        changeset
        |> Ash.Changeset.filter(invoked_at < ^cutoff)
      end
    end
  end

  defp average_duration(logs) do
    durations = logs
      |> Enum.map(& &1.duration_ms)
      |> Enum.reject(&is_nil/1)

    if Enum.empty?(durations) do
      0
    else
      Enum.sum(durations) / length(durations)
    end
  end

  defp maybe_filter_tool_name(query) do
    if query.arguments[:tool_name] do
      Ash.Query.filter(query, tool_name == ^query.arguments[:tool_name])
    else
      query
    end
  end

  defp maybe_filter_session(query) do
    if query.arguments[:session_id] do
      Ash.Query.filter(query, session_id == ^query.arguments[:session_id])
    else
      query
    end
  end

  defp maybe_filter_result(query) do
    if query.arguments[:result] do
      Ash.Query.filter(query, result == ^query.arguments[:result])
    else
      query
    end
  end

  defp maybe_filter_date_range(query) do
    query
    |> maybe_filter_from()
    |> maybe_filter_to()
  end

  defp maybe_filter_from(query) do
    if query.arguments[:from] do
      Ash.Query.filter(query, invoked_at >= ^query.arguments[:from])
    else
      query
    end
  end

  defp maybe_filter_to(query) do
    if query.arguments[:to] do
      Ash.Query.filter(query, invoked_at <= ^query.arguments[:to])
    else
      query
    end
  end

  defp maybe_filter_dates(query, args) do
    query
    |> then(fn q ->
      if args[:from], do: Ash.Query.filter(q, invoked_at >= ^args[:from]), else: q
    end)
    |> then(fn q ->
      if args[:to], do: Ash.Query.filter(q, invoked_at <= ^args[:to]), else: q
    end)
  end
end
```

### Step 2: Create AuditLog Module

```elixir
# lib/ashfolio_web/mcp/audit_log.ex

defmodule AshfolioWeb.Mcp.AuditLog do
  @moduledoc """
  Handles logging of MCP tool invocations for compliance and debugging.
  """

  alias Ashfolio.Legal.McpInvocation

  @doc """
  Log a tool invocation. Call at start of execution.
  """
  def log_invocation(params) do
    args = params[:arguments] || %{}

    McpInvocation.log(%{
      tool_name: params[:tool_name],
      session_id: params[:session_id],
      privacy_mode: params[:privacy_mode],
      arguments_hash: hash_arguments(args),
      argument_shape: extract_shape(args),
      invoked_at: params[:started_at] || DateTime.utc_now()
    })
  end

  @doc """
  Complete a logged invocation with result.
  """
  def complete_invocation(log, params) do
    duration = if log.invoked_at do
      DateTime.diff(DateTime.utc_now(), log.invoked_at, :millisecond)
    end

    McpInvocation.complete(log, Map.merge(params, %{
      duration_ms: duration
    }))
  end

  @doc """
  Query audit logs.
  """
  def query(opts \\ []) do
    McpInvocation.query!(opts)
  end

  @doc """
  Get statistics about tool usage.
  """
  def stats(opts \\ []) do
    McpInvocation.stats!(opts)
  end

  @doc """
  Get a specific log entry.
  """
  def get(id) do
    McpInvocation.get(id)
  end

  @doc """
  Clean up old logs based on retention policy.
  """
  def cleanup(opts \\ []) do
    retention_days = Keyword.get(opts, :retention_days, 90)
    McpInvocation.cleanup(%{retention_days: retention_days})
  end

  # Private helpers

  defp hash_arguments(args) do
    args
    |> Jason.encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp extract_shape(args) when is_map(args) do
    Map.new(args, fn {k, v} -> {to_string(k), value_shape(v)} end)
  end

  defp value_shape(v) when is_map(v), do: Map.keys(v)
  defp value_shape(v) when is_list(v), do: "list"
  defp value_shape(v) when is_binary(v), do: "string"
  defp value_shape(v) when is_integer(v), do: "integer"
  defp value_shape(v) when is_float(v), do: "float"
  defp value_shape(v) when is_boolean(v), do: "boolean"
  defp value_shape(nil), do: "null"
  defp value_shape(_), do: "unknown"
end
```

### Step 3: Wire Into Tool Execution

```elixir
# Update lib/ashfolio_web/mcp/module_registry.ex

defp invoke_tool(tool, arguments, session_id) do
  alias AshfolioWeb.Mcp.AuditLog

  {:ok, log} = AuditLog.log_invocation(%{
    tool_name: tool.name,
    arguments: arguments,
    privacy_mode: PrivacyFilter.current_mode(),
    session_id: session_id
  })

  result = do_invoke_tool(tool, arguments)

  case result do
    {:ok, data} ->
      AuditLog.complete_invocation(log, %{
        result: :success,
        result_count: count_results(data)
      })
      result

    {:error, reason} ->
      {code, message} = format_error(reason)
      AuditLog.complete_invocation(log, %{
        result: :error,
        error_code: code,
        error_message: message
      })
      result
  end
end
```

### Step 4: Run Tests

```bash
mix test test/ashfolio_web/mcp/audit_log_test.exs --trace
```

## Definition of Done

- [ ] McpInvocation resource created
- [ ] AuditLog module created
- [ ] Logging integrated with tool execution
- [ ] Query interface works
- [ ] Statistics calculated
- [ ] Retention cleanup works
- [ ] Arguments filtered/hashed
- [ ] All TDD tests pass
- [ ] `mix test` passes (no regressions)

## Dependencies

**Blocked By**: Phase 1, Task P3-01
**Blocks**: None

## Notes

- Consider async logging for performance
- Add log compression for storage efficiency
- Future: Real-time monitoring dashboard

---

*Parent: [../README.md](../README.md)*
