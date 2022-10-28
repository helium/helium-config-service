defmodule HeliumConfigGRPC.RouteServerTest do
  use HeliumConfig.DataCase

  import HeliumConfig.Fixtures

  alias HeliumConfig.Core
  alias HeliumConfigGRPC.RouteView

  alias Proto.Helium.Config.RouteV1
  alias Proto.Helium.Config.RouteGetReqV1
  alias Proto.Helium.Config.RouteListReqV1
  alias Proto.Helium.Config.RouteListResV1
  alias Proto.Helium.Config.RouteCreateReqV1
  alias Proto.Helium.Config.RouteUpdateReqV1
  alias Proto.Helium.Config.RouteDeleteReqV1

  describe "list" do
    setup [:create_default_org]

    test "returns a RouteListResV1 given a valid RouteListReqV1", %{valid_org: valid_org} do
      {:ok, channel} = GRPC.Stub.connect("localhost:50051")
      req = RouteListReqV1.new(%{dummy_value: true})
      result = Proto.Helium.Config.Route.Stub.list(channel, req)
      assert({:ok, %{__struct__: RouteListResV1} = res} = result)
      assert(length(res.routes) > 1)
      assert(length(valid_org.routes) == length(res.routes))
    end
  end

  describe "get" do
    setup [:create_default_org]

    test "returns a RouteV1 given a valid RouteGetReqV1", %{valid_org: valid_org} do
      {:ok, channel} = GRPC.Stub.connect("localhost:50051")
      route = hd(valid_org.routes)
      req = RouteGetReqV1.new(%{id: route.id})
      result = Proto.Helium.Config.Route.Stub.get(channel, req)
      assert({:ok, %{__struct__: RouteV1}} = result)
    end
  end

  describe "create" do
    setup [:create_default_org]

    test "returns a RouteV1 given a valid RouteCreateReqV1", %{valid_org: valid_org} do
      oui = valid_org.oui

      new_route =
        %{
          oui: oui,
          net_id: Core.NetID.to_integer(Core.NetID.new(:net_id_sponsor, 1, 11)),
          devaddr_ranges: [
            %{
              start_addr: Core.Devaddr.to_integer(Core.Devaddr.new(:devaddr_6x25, 11, 1)),
              end_addr: Core.Devaddr.to_integer(Core.Devaddr.new(:devaddr_6x25, 11, 10))
            }
          ],
          euis: [
            %{app_eui: 42, dev_eui: 43}
          ],
          server: %{
            host: "server4.testdomain.com",
            port: 4444,
            protocol: {:packet_router, %{dummy_arg: true}}
          },
          max_copies: 3
        }
        |> RouteV1.new()

      req =
        %{
          route: new_route,
          oui: oui
        }
        |> RouteCreateReqV1.new()

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.create(channel, req)

      assert({:ok, %{__struct__: RouteV1}} = result)
    end
  end

  describe "update" do
    setup [:create_default_org]

    test "returns an updated RouteV1 given a valid RouteUpdateReqV1", %{valid_org: valid_org} do
      route = hd(valid_org.routes)

      updated_route =
        route
        |> Map.put(:server, %Core.RouteServer{
          host: "updated_server.testdomain.com",
          port: 4567,
          protocol_opts: %Core.PacketRouterOpts{}
        })

      route_params = RouteView.route_params(updated_route)

      req =
        %{
          oui: route.oui,
          route: route_params
        }
        |> RouteUpdateReqV1.new()

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.update(channel, req)

      assert({:ok, %{__struct__: RouteV1}} = result)
    end
  end

  describe "delete" do
    setup [:create_default_org]

    test "returns a RouteV1 containing the deleted object given a valid RouteDeleteReqV1", %{valid_org: valid_org} do
      starting_route_len = length(valid_org.routes)
      route = hd(valid_org.routes)
      req = RouteDeleteReqV1.new(%{
	    id: route.id,
				 })

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.delete(channel, req)

      assert({:ok, %{__struct__: RouteV1}} = result)

      remaining_route_len = length(HeliumConfig.list_routes())

      assert(remaining_route_len == (starting_route_len - 1))
    end
  end

  defp create_default_org(ctx) do
    valid_org =
      valid_core_organization()
      |> HeliumConfig.create_organization()

    Map.put(ctx, :valid_org, valid_org)
  end
end
