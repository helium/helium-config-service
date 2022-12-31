defmodule HeliumConfigGRPC.RouteViewTest do
  use ExUnit.Case

  alias HeliumConfigGRPC.RouteView

  alias Proto.Helium.Config.RouteV1

  import HeliumConfig.Fixtures

  describe "RouteView.route_params/1" do
    test "returns a correct map given a valid HTTP Roaming %Core.Route{}" do
      got = RouteView.route_params(valid_http_roaming_route())

      expected = %{
        id: "11111111-2222-3333-4444-555555555555",
        oui: 1,
        net_id: valid_net_id(0),
        max_copies: 2,
        server: %{
          host: "server1.testdomain.com",
          port: 8888,
          protocol: {:http_roaming, %{dedupe_timeout: 1200, flow_type: :async, path: "/helium"}}
        },
        euis: [
          %{app_eui: valid_app_eui_integer(), dev_eui: valid_dev_eui_integer()}
        ],
        devaddr_ranges: [
          %{start_addr: 0x0001_0000, end_addr: 0x001F_0000},
          %{start_addr: 0x0030_0000, end_addr: 0x0030_001A}
        ]
      }

      assert(got == expected)
    end

    test "returns a map compatible with a RouteV1 given a valid HTTP Roaming Route" do
      core_route = valid_http_roaming_route()

      bin =
        core_route
        |> RouteView.route_params()
        |> RouteV1.new()
        |> RouteV1.encode()

      assert(is_binary(bin))
    end

    test "returns a correct map given a valid GWMP %Core.Route{}" do
      got = RouteView.route_params(valid_gwmp_route())

      expected = %{
        id: "22222222-2222-3333-4444-555555555555",
        oui: 1,
        net_id: valid_net_id(0),
        max_copies: 2,
        server: %{
          host: "server1.testdomain.com",
          port: 8888,
          protocol:
            {:gwmp,
             %{
               mapping: [
                 %{region: :US915, port: 1000},
                 %{region: :EU868, port: 1001},
                 %{region: :EU433, port: 1002},
                 %{region: :CN470, port: 1003},
                 %{region: :CN779, port: 1004},
                 %{region: :AU915, port: 1005},
                 %{region: :AS923_1, port: 1006},
                 %{region: :KR920, port: 1007},
                 %{region: :IN865, port: 1008},
                 %{region: :AS923_2, port: 1009},
                 %{region: :AS923_3, port: 10010},
                 %{region: :AS923_4, port: 10011},
                 %{region: :AS923_1A, port: 10012},
                 %{region: :AS923_1B, port: 10013},
                 %{region: :AS923_1C, port: 10014},
                 %{region: "AS923_1D, port: 10015},
                 %{region: :AS923_1E, port: 10016},
                 %{region: :AS923_1F, port: 10017},
                 %{region: :AU915_SB1, port: 10018},
                 %{region: :AU915_SB2, port: 10019},
                 %{region: :EU868_A, port: 10020},
                 %{region: :EU868_B, port: 10021},
                 %{region: :EU868_C, port: 10022},
                 %{region: :EU868_D, port: 10023},
                 %{region: :EU868_E, port: 10024},
                 %{region: :EU868_F, port: 10025},
                 %{region: :CD900_1A, port: 10026}
               ]
             }}
        },
        euis: [
          %{app_eui: valid_app_eui_integer(), dev_eui: valid_dev_eui_integer()}
        ],
        devaddr_ranges: [
          %{start_addr: 0x0001_0000, end_addr: 0x001F_0000},
          %{start_addr: 0x0030_0000, end_addr: 0x0030_001A}
        ]
      }

      assert(got == expected)
    end

    test "returns a map compatible with a RouteV1 given a valid GWMP Route" do
      core_route = valid_gwmp_route()

      bin =
        core_route
        |> RouteView.route_params()
        |> RouteV1.new()
        |> RouteV1.encode()

      assert(is_binary(bin))
    end

    test "returns a correct map given a valid Packet Router %Core.Route{}" do
      got = RouteView.route_params(valid_packet_router_route())

      expected = %{
        id: "33333333-2222-3333-4444-555555555555",
        oui: 1,
        net_id: valid_net_id(0),
        max_copies: 2,
        server: %{
          host: "server1.testdomain.com",
          port: 8888,

          # ProtocolPacketRouterV1 doesn't support options in this
          # verison, but Protobuf will encode it null if it's empty,
          # so we have to use a dummy value here.
          protocol: {:packet_router, %{dummy_value: true}}
        },
        euis: [
          %{app_eui: valid_app_eui_integer(), dev_eui: valid_dev_eui_integer()}
        ],
        devaddr_ranges: [
          %{start_addr: 0x0001_0000, end_addr: 0x001F_0000},
          %{start_addr: 0x0030_0000, end_addr: 0x0030_001A}
        ]
      }

      assert(got == expected)
    end

    test "returns a map compatible with a RouteV1 given a valid Packet Router Route" do
      core_route = valid_packet_router_route()

      bin =
        core_route
        |> RouteView.route_params()
        |> RouteV1.new()
        |> RouteV1.encode()

      assert(is_binary(bin))
    end
  end
end
