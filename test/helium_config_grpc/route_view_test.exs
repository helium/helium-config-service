defmodule HeliumConfigGRPC.RouteViewTest do
  use ExUnit.Case

  alias HeliumConfig.Core.Route, as: CoreRoute

  alias HeliumConfigGRPC.RouteView

  alias Proto.Helium.Config.RouteV1

  test "route_params/1 returns a map suitable for encoding a RouteV1" do
    core_route =
      CoreRoute.new(%{
        net_id: 7,
        lns_address: "lns1.testdomain.com",
        protocol: :gwmp,
        euis: [
          %{
            app_eui: 87,
            dev_eui: 88
          }
        ],
        devaddr_ranges: [
          {1, 10},
          {15, 20}
        ]
      })

    route_params = RouteView.route_params(core_route)

    # route_params is "suitable" if:
    #
    # 1.  we can use it to encode
    # 2.  we can successfully decode the result
    # 3.  the decoded result is identical to our original input.

    proto_route = RouteV1.new(route_params)
    route_bin = RouteV1.encode(proto_route)

    decoded =
      route_bin
      |> RouteV1.decode()
      |> CoreRoute.from_proto()

    assert(decoded == core_route)
  end
end
