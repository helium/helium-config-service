defmodule HeliumConfigGRPC.RouteStreamWorker do
  use GenServer

  alias HeliumConfig.DB.UpdateNotifier
  alias HeliumConfigGRPC.RouteView

  alias Proto.Helium.Config.RouteStreamResV1

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def update(pid) do
    GenServer.cast(pid, :send_all)
  end

  @impl true
  def init(notifier: notifier, stream: stream) do
    :ok = UpdateNotifier.subscribe(notifier, self())
    update(self())
    {:ok, %{stream: stream}}
  end

  @impl true
  def handle_call(:send_all, _from, %{stream: stream} = state) do
    stream2 =
      HeliumConfig.list_routes()
      |> Enum.reduce(stream, fn route, s ->
        send_reply(s, route, :create)
      end)

    {:reply, :ok, %{state | stream: stream2}}
  end

  def handle_call({:route_created, route}, _from, %{stream: stream} = state) do
    stream2 = send_reply(stream, route, :create)
    {:reply, :ok, %{state | stream: stream2}}
  end

  def handle_call({:route_updated, route}, _from, %{stream: stream} = state) do
    stream2 = send_reply(stream, route, :update)
    {:reply, :ok, %{state | stream: stream2}}
  end

  def handle_call({:route_deleted, route}, _from, %{stream: stream} = state) do
    stream2 = send_reply(stream, route, :delete)
    {:reply, :ok, %{state | stream: stream2}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(:send_all, %{stream: stream} = state) do
    stream2 =
      HeliumConfig.list_routes()
      |> Enum.reduce(stream, fn route, s ->
        send_reply(s, route, :create)
      end)

    {:noreply, %{state | stream: stream2}}
  end

  def handle_cast({:route_created, route}, %{stream: stream} = state) do
    stream2 = send_reply(stream, route, :create)
    {:noreply, %{state | stream: stream2}}
  end

  def handle_cast({:route_updated, route}, %{stream: stream} = state) do
    stream2 = send_reply(stream, route, :update)
    {:noreply, %{state | stream: stream2}}
  end

  def handle_cast({:route_deleted, route}, %{stream: stream} = state) do
    stream2 = send_reply(stream, route, :delete)
    {:noreply, %{state | stream: stream2}}
  end

  def handle_cast(_msg, state) do
    {:reply, :ok, state}
  end

  defp route_reply(route, action) do
    route_proto_params = RouteView.route_params(route)
    RouteStreamResV1.new(%{route: route_proto_params, action: action})
  end

  defp send_reply(stream, route, action) do
    reply = route_reply(route, action)
    GRPC.Server.send_reply(stream, reply)
  end
end
