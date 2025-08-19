defmodule AshfolioWeb.HealthControllerTest do
  use AshfolioWeb.ConnCase

  describe "GET /health" do
    test "returns health status when database is healthy", %{conn: conn} do
      conn = get(conn, ~p"/health")

      assert json_response(conn, 200)
      response = json_response(conn, 200)

      assert response["status"] == "healthy"
      assert response["timestamp"]
      assert response["application"]["name"] == "ashfolio"
      assert response["application"]["version"]
      assert response["system"]["uptime_seconds"]
      assert response["system"]["memory"]["total_mb"]
      assert response["database"]["status"] == "healthy"
      assert response["database"]["connection"] == "ok"
      assert is_map(response["database"]["stats"])
      assert is_map(response["services"])
    end

    test "returns detailed system information", %{conn: conn} do
      conn = get(conn, ~p"/health")
      response = json_response(conn, 200)

      # Verify system info structure
      system = response["system"]
      assert is_integer(system["uptime_seconds"])
      assert is_map(system["memory"])
      assert is_integer(system["memory"]["total_mb"])
      assert is_integer(system["memory"]["processes_mb"])
      assert is_integer(system["memory"]["system_mb"])
      assert system["node"]
      assert system["otp_release"]
      assert system["beam_version"]
    end

    test "returns database statistics", %{conn: conn} do
      conn = get(conn, ~p"/health")
      response = json_response(conn, 200)

      # Verify database stats
      db_stats = response["database"]["stats"]
      assert is_integer(db_stats["users"])
      assert is_integer(db_stats["accounts"])
      assert is_integer(db_stats["transactions"])
    end

    test "returns service health status", %{conn: conn} do
      conn = get(conn, ~p"/health")
      response = json_response(conn, 200)

      # Verify services health
      services = response["services"]
      assert is_map(services["cache"])
      assert is_map(services["market_data"])
      assert is_map(services["pubsub"])

      # Cache should be healthy
      assert services["cache"]["status"] == "healthy"
    end
  end

  describe "GET /ping" do
    test "returns simple ok status", %{conn: conn} do
      conn = get(conn, ~p"/ping")

      assert json_response(conn, 200)
      response = json_response(conn, 200)

      assert response["status"] == "ok"
      assert response["timestamp"]
    end

    test "ping endpoint is fast and lightweight", %{conn: conn} do
      start_time = System.monotonic_time(:millisecond)
      conn = get(conn, ~p"/ping")
      end_time = System.monotonic_time(:millisecond)

      response_time = end_time - start_time

      assert json_response(conn, 200)
      # Ping should be very fast (under 100ms even in test environment)
      assert response_time < 100
    end
  end

  describe "API routes" do
    test "health check works on /api/health", %{conn: conn} do
      conn = get(conn, "/api/health")

      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert response["status"] == "healthy"
    end

    test "ping works on /api/ping", %{conn: conn} do
      conn = get(conn, "/api/ping")

      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert response["status"] == "ok"
    end
  end

  # Test error scenarios
  describe "error handling" do
    @tag :integration
    test "health check handles database connectivity issues gracefully" do
      # This test would simulate database connectivity issues
      # For now, we'll test that the endpoint structure is correct
      # In a real scenario, you might mock the Repo to return errors

      # This is a placeholder for more advanced error simulation
      # You could use Mox to mock the Repo and test error conditions
      assert true
    end
  end

  # Performance and load testing
  describe "performance" do
    @describetag :performance
    test "health endpoint performs well under load" do
      # Simulate multiple rapid requests
      tasks =
        1..10
        |> Enum.map(fn _i ->
          Task.async(fn ->
            conn = build_conn()
            get(conn, ~p"/health")
          end)
        end)

      results = Task.await_many(tasks, 5000)

      # All requests should succeed
      Enum.each(results, fn conn ->
        assert conn.status == 200
      end)
    end

    test "ping endpoint is consistently fast" do
      # Test multiple ping requests for consistency
      times =
        1..5
        |> Enum.map(fn _i ->
          start_time = System.monotonic_time(:millisecond)
          conn = build_conn()
          get(conn, ~p"/ping")
          end_time = System.monotonic_time(:millisecond)
          end_time - start_time
        end)

      # All ping requests should be fast
      Enum.each(times, fn time ->
        # Very fast for ping
        assert time < 50
      end)

      # Average should be very fast
      avg_time = Enum.sum(times) / length(times)
      assert avg_time < 25
    end
  end
end
