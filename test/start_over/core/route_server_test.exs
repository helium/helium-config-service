defmodule StartOver.Core.RouteServerTest do
  use ExUnit.Case

  alias Proto.Helium.Config.ServerV1
  alias StartOver.Core.RouteServer
  alias StartOver.Core.HttpRoamingOpts
  alias StartOver.Core.GwmpOpts
  alias StartOver.Core.PacketRouterOpts

  describe "RouteServer.from_proto/1" do
    test "can decode an HTTP roaming server from a ServerV1 protobuf" do
      bin =
        %{
          host: "server1.testdomain.com",
          port: 9999,
          protocol: {:http_roaming, %{dummy_arg: true}}
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
        protocol_opts: %HttpRoamingOpts{}
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
