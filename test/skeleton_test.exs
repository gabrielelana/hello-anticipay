defmodule Anticipay.SkeletonTest do
  use ExUnit.Case, async: true
  use Plug.Test

  setup_all do
    Mongo.run_command(Anticipay.MongoDB, [dropDatabase: 1])
  end

  test "GET /ping" do
    conn = conn(:get, "/ping") |> call

    assert conn.status == 200
    assert conn.resp_body == "pong"
  end

  test "POST /counters/:name" do
    conn = conn(:post, "/counters/1/up") |> call
    assert conn.status == 200
    assert conn.resp_body == Poison.encode!(%{counter: 1})

    conn(:post, "/counters/1/up") |> call
    conn(:post, "/counters/1/up") |> call
    conn = conn(:post, "/counters/1/up") |> call
    assert conn.resp_body == Poison.encode!(%{counter: 4})
  end

  test "anything else returns 404" do
    conn = conn(:get, "/not-a-valid-route") |> call

    assert conn.status == 404
    assert conn.resp_body == "oops"
  end

  @opts Anticipay.HTTP.init([])

  defp call(conn), do: Anticipay.HTTP.call(conn, @opts)
end
