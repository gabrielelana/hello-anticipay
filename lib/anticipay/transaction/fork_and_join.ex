defmodule Anticipay.Transaction.ForkAndJoin do
  use GenServer

  def start(parent, commands) do
    {:ok, pid} = GenServer.start(__MODULE__, [parent, commands])
    GenServer.cast(pid, :start)
  end


  def init([parent, commands]) do
    {:ok, %{parent: parent, commands: commands}}
  end

  def handle_cast(:start, %{commands: commands} = state) do
    Enum.each(commands, fn(command) ->
      command_id = command["id"]
      Anticipay.EventStore.subscribe(self(), &match?(%{"event" => "CommandSucceeded", "command_id" => ^command_id}, &1))
      Anticipay.EventStore.subscribe(self(), &match?(%{"event" => "CommandFailed", "command_id" => ^command_id}, &1))
      Anticipay.Aggregates.handle(command)
    end)
    state =
      state
      |> Map.put(:waiting_for, Enum.map(commands, &Map.get(&1, "id")))
      |> Map.put(:succeeded, [])
      |> Map.put(:failed, [])
    {:noreply, state}
  end

  def handle_cast(:done, %{parent: command, failed: []} = state) do
    Anticipay.EventStore.emit(%{"event" => "CommandSucceeded",
                            "command_id" => command["id"],
                            "id" => Anticipay.UUID.new})
    {:stop, :normal, state}
  end
  def handle_cast(:done, %{parent: command, failed: failed, succeeded: []} = state) do
    Anticipay.EventStore.emit(%{"event" => "CommandFailed",
                            "command_id" => command["id"],
                            "why" => %{"failed_commands" => failed},
                            "id" => Anticipay.UUID.new})
    {:stop, :normal, state}
  end
  def handle_cast(:done, %{parent: command, failed: failed, succeeded: succeeded} = state) do
    # TODO: use a map for commands
    Enum.each(succeeded, fn(command_id) ->
      state.commands
      |> Enum.filter(fn(command) -> command["id"] == command_id end)
      |> List.first
      |> Anticipay.Aggregates.rollback
    end)
    Anticipay.EventStore.emit(%{"event" => "CommandFailed",
                            "command_id" => command["id"],
                            "why" => %{"failed_commands" => failed},
                            "id" => Anticipay.UUID.new})
    {:stop, :normal, state}
  end

  def handle_info({:event, %{"event" => "CommandSucceeded"} = event}, %{waiting_for: waiting_for} = state) do
    state = %{state | waiting_for: waiting_for -- [event["command_id"]], succeeded: [event["command_id"]]}
    if [] == state.waiting_for, do: GenServer.cast(self(), :done)
    {:noreply, state}
  end
  def handle_info({:event, %{"event" => "CommandFailed"} = event}, %{waiting_for: waiting_for} = state) do
    state = %{state | waiting_for: waiting_for -- [event["command_id"]], failed: [event["command_id"]]}
    if [] == state.waiting_for, do: GenServer.cast(self(), :done)
    {:noreply, state}
  end
end
