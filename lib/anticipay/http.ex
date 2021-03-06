defmodule Anticipay.HTTP do
  use Plug.Router
  require Logger

  plug Plug.Logger
  plug Plug.Static, at: "/", from: "priv/static"
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison
  plug CORSPlug
  plug :match
  plug :dispatch

  get "/ping" do
    conn
    |> put_resp_header("content-type", "text/plain")
    |> send_resp(200, "pong")
  end

  get "/counters/:name" do
    %{"counter" => counter} = counter(name)
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, Poison.encode!(%{counter: counter}))
  end

  post "/counters/:name/up" do
    %{"counter" => counter} = count_up(name, 1)
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, Poison.encode!(%{counter: counter}))
  end

  post "/counters/:name/down" do
    %{"counter" => counter} = count_up(name, -1)
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, Poison.encode!(%{counter: counter}))
  end

  defp count_up(counter_name, amount) do
    collection = "counters"
    query = %{name: counter_name}
    Mongo.update_one(Anticipay.MongoDB, collection, query, %{"$inc": %{counter: amount}}, upsert: true)
    Mongo.find(Anticipay.MongoDB, collection, query) |> Enum.to_list |> List.first
  end

  defp counter(counter_name) do
    collection = "counters"
    query = %{name: counter_name}
    Mongo.find(Anticipay.MongoDB, collection, query) |> Enum.to_list |> List.first
  end

  post "/commands" do
    case Anticipay.Aggregates.handle(conn) do
      {:ok, command} ->
        conn
        |> put_resp_header("content-type", "application/json")
        |> put_resp_header("location", url_for(conn, "/projections/command-status?command_id=#{command["_id"]}"))
        |> send_resp(201, Poison.encode!(command))
      {:error, reason} ->
        conn
        |> put_resp_header("content-type", "application/json")
        |> send_resp(400, Poison.encode!(%{error: reason}))
    end
  end

  get "/projections/:name" do
    case Anticipay.Projections.dispatch(conn, name) do
      {:ok, report} ->
        conn
        |> put_resp_header("content-type", "application/json")
        |> send_resp(200, Poison.encode!(report))
      {:error, reason} when reason in [:report_not_found, :record_not_found] ->
        conn
        |> send_resp(404, "")
      {:error, reason} ->
        conn
        |> put_resp_header("content-type", "application/json")
        |> send_resp(400, Poison.encode!(%{error: reason}))
    end
  end

  match _ do
    conn
    |> put_resp_header("content-type", "plain/text")
    |> send_resp(404, "oops")
  end

  defp url_for(conn, path) do
    Atom.to_string(conn.scheme) <> "://" <>
      conn.host <> ":" <> Integer.to_string(conn.port) <>
      path
  end
end
