defmodule HeliumConfig.DB.UpdateNotifier do
  use GenServer

  defmodule State do
    defstruct subscribers: MapSet.new()

    def subscribe(state = %State{subscribers: subscribers}, pid) do
      %State{state | subscribers: MapSet.put(subscribers, pid)}
    end

    def unsubscribe(state = %State{subscribers: subscribers}, pid) do
      %State{state | subscribers: MapSet.delete(subscribers, pid)}
    end
  end

  alias __MODULE__.State
  alias HeliumConfig.Core

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

  ##
  ## Route Created
  ##

  def call_route_created(db_route, notifier \\ :update_notifier) do
    core_route = Core.Route.from_db(db_route)
    GenServer.call(notifier, {:notify, {:route_created, core_route}})
  end

  def cast_route_created(db_route, notifier \\ :update_notifier) do
    core_route = Core.Route.from_db(db_route)
    GenServer.cast(notifier, {:notify, {:route_created, core_route}})
  end

  ##
  ## Route Updated
  ##

  def call_route_updated(db_route, notifier \\ :update_notifier) do
    core_route = Core.Route.from_db(db_route)
    GenServer.call(notifier, {:notify, {:route_updated, core_route}})
  end

  def cast_route_updated(db_route, notifier \\ :update_notifier) do
    core_route = Core.Route.from_db(db_route)
    GenServer.cast(notifier, {:notify, {:route_updated, core_route}})
  end

  ##
  ## Route Deleted
  ##

  def call_route_deleted(db_route, notifier \\ :update_notifier) do
    core_route = Core.Route.from_db(db_route)
    GenServer.call(notifier, {:notify, {:route_deleted, core_route}})
  end

  def cast_route_deleted(db_route, notifier \\ :update_notifier) do
    core_route = Core.Route.from_db(db_route)
    GenServer.cast(notifier, {:notify, {:route_deleted, core_route}})
  end

  ##
  ## GenServer Callbacks
  ##

  @impl true
  def handle_call({:subscribe, pid}, _from, state) do
    Process.monitor(pid)
    state2 = State.subscribe(state, pid)
    {:reply, :ok, state2}
  end

  def handle_call({:unsubscribe, pid}, _from, state) do
    {:reply, :ok, State.unsubscribe(state, pid)}
  end

  def handle_call({:notify, msg}, _from, state) do
    :ok =
      Enum.each(state.subscribers, fn subscriber ->
        GenServer.call(subscriber, msg)
      end)

    {:reply, :ok, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_cast({:notify, msg}, state) do
    :ok =
      Enum.each(state.subscribers, fn subscriber ->
        GenServer.cast(subscriber, msg)
      end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, State.unsubscribe(state, pid)}
  end
end
