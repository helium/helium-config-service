defmodule StartOver.DB.UpdateNotifier do
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
