defmodule HeliumConfigGRPC.RouteStreamWorker do
  @moduledoc """
  This module is a GenServer that handles streaming replies to
  `helium_config.config_service/route_updates` RPC calls.

  It is started by HeliumConfigGRPC.Server.

  On startup, it sends one `RoutesResV1` reply and then it waits for
  an `:update` message from HeliumConfig.DB.UpdateNotifier.  If that
  message arrives, the worker crafts another `RoutesResV1` and sends
  that to the caller. 
  """

  use GenServer

  alias HeliumConfig.DB.UpdateNotifier
  alias HeliumConfigGRPC.RouteView

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
    HeliumConfig.list_routes()
    |> Enum.map(&RouteView.route_params/1)
    |> Enum.map(&RouteV1.new/1)
  end

  defp push_routes(routes, stream) do
    reply = RoutesResV1.new(routes: routes)
    GRPC.Server.send_reply(stream, reply)
  end
end
