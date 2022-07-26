defmodule HeliumConfigGRPC.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run(HeliumConfigGRPC.Server)
end

defmodule HeliumConfigGRPC.Server do
  use GRPC.Server, service: Proto.Helium.RouterConfig.Config.Service

  alias HeliumConfigGRPC.OrganizationView
  alias Proto.Helium.RouterConfig.PacketRouterRoutesResV1
  alias Proto.Helium.RouterConfig.PacketRouterRouteV1

  # alias Proto.Helium.RouterConfig.PacketRouterRoutesResV1, as: RoutesResponseV1

  def route_updates(_requests_enum, stream) do
    routes =
      HeliumConfig.list_routes()
      |> Enum.map(&OrganizationView.route_params/1)
      |> Enum.map(&PacketRouterRouteV1.new/1)

    reply = PacketRouterRoutesResV1.new(routes: routes)

    GRPC.Server.send_reply(stream, reply)
  end
end
