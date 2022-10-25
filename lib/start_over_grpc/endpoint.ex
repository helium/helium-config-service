defmodule StartOverGRPC.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run(StartOverGRPC.Server)
end

defmodule StartOverGRPC.Server do
  use GRPC.Server, service: Proto.Helium.Config.ConfigService.Service

  alias StartOverGRPC.RouteStreamWorker

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

defmodule StartOverGRPC.Stub do
  use GRPC.Stub, service: Proto.Helium.Config.ConfigService.Service
end
