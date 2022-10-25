defmodule StartOverGRPC.RouteStreamWorker do
  use GenServer

  alias StartOver.DB.UpdateNotifier
  alias StartOverGRPC.RouteView

  alias Proto.Helium.Config.RoutesResV1
  alias Proto.Helium.Config.RouteV1

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def update(pid) do
    GenServer.cast(pid, :update)
  end

  @impl true
  def init(notifier: notifier, stream: stream) do
    :ok = UpdateNotifier.subscribe(notifier, self())
    update(self())
    {:ok, %{stream: stream}}
  end

  @impl true
  def handle_call(:update, _from, state = %{stream: stream}) do
    stream2 =
      get_routes()
      |> push_routes(stream)

    {:reply, :ok, %{state | stream: stream2}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(:update, state = %{stream: stream}) do
    stream2 =
      get_routes()
      |> push_routes(stream)

    {:noreply, %{state | stream: stream2}}
  end

  defp get_routes do
    StartOver.list_routes()
    |> Enum.map(&RouteView.route_params/1)
    |> Enum.map(&RouteV1.new/1)
  end

  defp push_routes(routes, stream) do
    reply = RoutesResV1.new(routes: routes)
    GRPC.Server.send_reply(stream, reply)
  end
end
