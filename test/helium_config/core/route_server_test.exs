defmodule HeliumConfig.Core.RouteServerTest do
  use ExUnit.Case

  alias Proto.Helium.Config.ServerV1
  alias HeliumConfig.Core.RouteServer
  alias HeliumConfig.Core.HttpRoamingOpts
  alias HeliumConfig.Core.GwmpOpts
  alias HeliumConfig.Core.PacketRouterOpts

  describe "RouteServer.from_proto/1" do
    test "can decode an HTTP roaming server from a ServerV1 protobuf" do
      bin =
        %{
          host: "server1.testdomain.com",
          port: 9999,
          protocol: {:http_roaming, %{dedupe_timeout: 1200, flow_type: :sync, path: "/helium"}}
        }
        |> ServerV1.new()
        |> ServerV1.encode()

      got =
        bin
        |> ServerV1.decode()
        |> RouteServer.from_proto()

      expected = %RouteServer{
        host: "server1.testdomain.com",
        port: 9999,
        protocol_opts: %HttpRoamingOpts{
          dedupe_window: 1200,
          flow_type: :sync,
          path: "/helium"
        }
      }

      assert(got == expected)
    end

    test "can decode a GWMP from a ServerV1 protobuf" do
      bin =
        %{
          host: "server1.testdomain.com",
          port: 9999,
          protocol:
            {:gwmp,
             %{
               mapping: [
                 %{region: :US915, port: 1000},
                 %{region: :EU868, port: 2000}
               ]
             }}
        }
        |> ServerV1.new()
        |> ServerV1.encode()

      got =
        bin
        |> ServerV1.decode()
        |> RouteServer.from_proto()

      expected = %RouteServer{
        host: "server1.testdomain.com",
        port: 9999,
        protocol_opts: %GwmpOpts{mapping: [{:US915, 1000}, {:EU868, 2000}]}
      }

      assert(got == expected)
    end

    test "can decode a Packet Router server from a ServerV1 protobuf" do
      bin =
        %{
          host: "server1.testdomain.com",
          port: 9999,
          protocol: {:packet_router, %{dummy_arg: true}}
        }
        |> ServerV1.new()
        |> ServerV1.encode()

      got =
        bin
        |> ServerV1.decode()
        |> RouteServer.from_proto()

      expected = %RouteServer{
        host: "server1.testdomain.com",
        port: 9999,
        protocol_opts: %PacketRouterOpts{}
      }

      assert(got == expected)
    end
  end
end
