defmodule HeliumConfigGRPC.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run(HeliumConfigGRPC.Server)
end

defmodule HeliumConfigGRPC.Server do
  use GRPC.Server, service: Proto.Helium.Config.ConfigService.Service

  alias HeliumConfigGRPC.RouteStreamWorker

  def route_updates(%{__struct__: Proto.Helium.Config.RoutesReqV1}, stream) do
    {:ok, worker} =
      GenServer.start_link(RouteStreamWorker, notifier: :update_notifier, stream: stream)

    ref = Process.monitor(worker)

    receive do
      {:DOWN, ^ref, _, _, _} ->
        :ok
    end

    stream
  end
end

defmodule HeliumConfigGRPC.Stub do
  use GRPC.Stub, service: Proto.Helium.Config.ConfigService.Service
end
