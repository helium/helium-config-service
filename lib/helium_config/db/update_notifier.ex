defmodule HeliumConfig.DB.UpdateNotifier do
  @moduledoc """

  This module is a GenServer that implements a simple
  publish/subscribe system to signal other processes whenever there is
  a change to configuration data.  It is primarily used by
  `HeliumConfigGRPC.RouteStreamWorker` to push updates to RPC callers.

  If started without arguments, UpdateNotifier will register itself as
  `:update_notifier`.  In that case, the functions `subscribe/0`,
  `unsubscribe/0`, can be used.

  If started with `registered: false`, functions `subscribe/1`,
  `subscribe/2`, `unsubscribe/1`, and `unsubscribe/2` must be used.
  This is mainly useful in testing scenarios.

  If a change is made to the database (say, through calls to the
  `HeliumConfig` module), subscribed processes will receive an
  `:update` message.  It is recommended that subscribers implement
  callbacks for BOTH calls and casts.  For example:


  ```
  @impl true
  def handle_call(:update, _from, state) do
    # Handle update...
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(:update, state) do
    # Handle update...
    {:noreply, state}
  end
  ```

  """

  use GenServer

  defmodule State do
    @moduledoc """

    This module represents the internal state of an UpdateNotifier
    process and contains functions for manipulating the state.

    """

    defstruct subscribers: MapSet.new()

    def subscribe(state = %State{subscribers: subscribers}, pid) do
      %State{state | subscribers: MapSet.put(subscribers, pid)}
    end

    def unsubscribe(state = %State{subscribers: subscribers}, pid) do
      %State{state | subscribers: MapSet.delete(subscribers, pid)}
    end
  end

  alias __MODULE__.State

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(registered: false) do
    {:ok, %State{}}
  end

  def init(_) do
    Process.register(self(), :update_notifier)
    {:ok, %State{}}
  end

  def subscribe do
    subscribe(:update_notifier, self())
  end

  def subscribe(notifier) do
    subscribe(notifier, self())
  end

  def subscribe(notifier, pid) do
    GenServer.call(notifier, {:subscribe, pid})
  end

  def unsubscribe do
    unsubscribe(:update_notifier, self())
  end

  def unsubscribe(notifier) do
    unsubscribe(notifier, self())
  end

  def unsubscribe(notifier, pid) do
    GenServer.call(notifier, {:unsubscribe, pid})
  end

  def notify_call do
    notify_call(:update_notifier)
  end

  def notify_call(notifier) do
    GenServer.call(notifier, :notify)
  end

  def notify_cast do
    notify_cast(:update_notifier)
  end

  def notify_cast(notifier) do
    GenServer.cast(notifier, :notify)
  end

  @impl true
  def handle_call({:subscribe, pid}, _from, state) do
    Process.monitor(pid)
    state2 = State.subscribe(state, pid)
    {:reply, :ok, state2}
  end

  def handle_call({:unsubscribe, pid}, _from, state) do
    {:reply, :ok, State.unsubscribe(state, pid)}
  end

  def handle_call(:notify, _from, state) do
    :ok =
      Enum.each(state.subscribers, fn subscriber ->
        GenServer.call(subscriber, :update)
      end)

    {:reply, :ok, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_cast(:notify, state) do
    :ok =
      Enum.each(state.subscribers, fn subscriber ->
        GenServer.cast(subscriber, :update)
      end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, State.unsubscribe(state, pid)}
  end
end
