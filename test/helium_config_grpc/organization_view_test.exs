defmodule HeliumConfigGRPC.OrganizationViewTest do
  use ExUnit.Case

  alias HeliumConfig.Core.Route, as: CoreRoute
  alias HeliumConfigGRPC.OrganizationView

  alias Proto.Helium.RouterConfig.PacketRouterRouteV1

  test "route_view/1 returns a map suitable for encoding a PacketRouterRouteV1" do
    route_params =
      %{
        net_id: 7,
        lns_address: "lns1.testdomain.com",
        protocol: :gwmp,
        euis: [],
        devaddr_ranges: [
          {1, 10},
          {15, 20}
        ]
      }
      |> CoreRoute.new()
      |> OrganizationView.route_params()

    route = PacketRouterRouteV1.new(route_params)
    result = Protobuf.encode(route)

    assert(is_binary(result))
  end
end
