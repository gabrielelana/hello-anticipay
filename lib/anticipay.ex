defmodule Anticipay do
  use Application
  import Supervisor.Spec, warn: false

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do

    # Define workers and child supervisors to be supervised
    children = [
      Anticipay.MongoDB.child_spec,
      worker(Anticipay.EventStore, []),
      aggregates(),
      projections(),
      Plug.Adapters.Cowboy.child_spec(:http, Anticipay.HTTP, [],
        [port: port(System.get_env("PORT")), dispatch: dispatch()]),
    ] |> Enum.reject(&is_nil/1)

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Anticipay.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp aggregates do
    if Application.get_env(:anticipay, :enable_aggregates, true),
      do: worker(Anticipay.Aggregates, [[]]),
      else: nil
  end

  defp projections do
    if Application.get_env(:anticipay, :enable_projections, true),
      do: worker(Anticipay.Projections, [[Anticipay.Projection.Commands]]),
      else: nil
  end

  defp dispatch do
    websocket = {"/ws", Anticipay.WS, []}
    otherwise = {:_, Plug.Adapters.Cowboy.Handler, {Anticipay.HTTP, []}}
    [{:_, [websocket, otherwise]}]
  end

  defp port(nil), do: 4000
  defp port(port), do: String.to_integer(port)
end
