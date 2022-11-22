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

    test "returns a RouteListResV1 given a valid RouteListReqV1", %{
      valid_org: valid_org,
      owner_pubkey_bin: owner_pubkey_bin,
      owner_sigfun: sigfun
    } do
      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      req =
        %{
          oui: valid_org.oui,
          owner: owner_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteListReqV1.new()
        |> sign_request(sigfun)

      result = Proto.Helium.Config.Route.Stub.list(channel, req)
      assert({:ok, %{__struct__: RouteListResV1} = res} = result)
      assert(length(res.routes) > 1)
      assert(length(valid_org.routes) == length(res.routes))
    end

    test "returns an RPC 'permission_denied' status given a RouteListReqV1 where the 'owner' does not match the owner_pubkey of the referenced Organization",
         %{valid_org: valid_org} do
      %{public: bad_pubkey, secret: bad_privkey} = Core.Crypto.generate_key_pair()
      bad_pubkey_bin = Core.Crypto.pubkey_to_bin(bad_pubkey)
      bad_sigfun = Core.Crypto.mk_sig_fun(bad_privkey)

      req =
        %{
          oui: valid_org.oui,
          owner: bad_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteListReqV1.new()
        |> sign_request(bad_sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.list(channel, req)

      assert(
        {:error,
         %GRPC.RPCError{
           status: GRPC.Status.permission_denied(),
           message: "Request owner does not match Organization owner."
         }} == result
      )
    end
  end

  describe "get" do
    setup [:create_default_org]

    test "returns a RouteV1 given a valid RouteGetReqV1 signed by the Organization owner", %{
      valid_org: valid_org,
      owner_pubkey_bin: owner_pubkey_bin,
      owner_sigfun: sigfun
    } do
      {:ok, channel} = GRPC.Stub.connect("localhost:50051")
      route = hd(valid_org.routes)

      req =
        %{
          id: route.id,
          owner: owner_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteGetReqV1.new()
        |> sign_request(sigfun)

      result = Proto.Helium.Config.Route.Stub.get(channel, req)
      assert({:ok, %{__struct__: RouteV1}} = result)
    end

    test "returns an RPC 'unauthenticated' status given a RouteGetReqV1 with an invalid signature",
         %{valid_org: valid_org, owner_pubkey_bin: owner_pubkey_bin} do
      %{secret: bad_privkey} = Core.Crypto.generate_key_pair()
      bad_sigfun = Core.Crypto.mk_sig_fun(bad_privkey)

      route = hd(valid_org.routes)

      req =
        %{
          id: route.id,
          owner: owner_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteGetReqV1.new()
        |> sign_request(bad_sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.get(channel, req)

      assert(
        {:error,
         %GRPC.RPCError{
           status: GRPC.Status.unauthenticated(),
           message: "Invalid request signature"
         }} == result
      )
    end

    test "returns an RPC 'permission_denied' status given a RouteGetReqV1 where the 'owner' does not match the owner_pubkey of the referenced Organization",
         %{valid_org: valid_org} do
      %{public: bad_pubkey, secret: bad_privkey} = Core.Crypto.generate_key_pair()
      bad_pubkey_bin = Core.Crypto.pubkey_to_bin(bad_pubkey)
      bad_sigfun = Core.Crypto.mk_sig_fun(bad_privkey)

      route = hd(valid_org.routes)

      req =
        %{
          id: route.id,
          owner: bad_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteGetReqV1.new()
        |> sign_request(bad_sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.get(channel, req)

      assert(
        {:error,
         %GRPC.RPCError{
           status: GRPC.Status.permission_denied(),
           message: "Request owner does not match Organization owner."
         }} == result
      )
    end
  end

  describe "create" do
    setup [:create_default_org]

    test "returns a RouteV1 given a valid RouteCreateReqV1 signed by the Organization owner", %{
      valid_org: valid_org,
      owner_pubkey_bin: owner_pubkey_bin,
      owner_sigfun: sigfun
    } do
      oui = valid_org.oui

      new_route =
        %{
          oui: oui,
          net_id: Core.NetID.to_integer(Core.NetID.new(:net_id_sponsor, 11)),
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
          oui: oui,
          owner: owner_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteCreateReqV1.new()
        |> sign_request(sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.create(channel, req)

      assert({:ok, %{__struct__: RouteV1}} = result)
    end

    test "returns an RPC 'unauthenticated' status given a RouteCreateReqV1 with an invalid signature",
         %{
           valid_org: valid_org,
           owner_pubkey_bin: owner_pubkey_bin
         } do
      %{secret: bad_key} = Core.Crypto.generate_key_pair()
      bad_sigfun = Core.Crypto.mk_sig_fun(bad_key)

      oui = valid_org.oui

      new_route =
        %{
          oui: oui,
          net_id: Core.NetID.to_integer(Core.NetID.new(:net_id_sponsor, 11)),
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
          oui: oui,
          owner: owner_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteCreateReqV1.new()
        |> sign_request(bad_sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.create(channel, req)

      assert(
        {:error,
         %GRPC.RPCError{
           status: GRPC.Status.unauthenticated(),
           message: "Invalid request signature"
         }} == result
      )
    end

    test "returns an RPC 'invalid_argument' status given a RouteCreateReqV1 where the 'oui' field does not match the OUI of the Route",
         %{valid_org: valid_org, owner_sigfun: sigfun, owner_pubkey_bin: owner_pubkey_bin} do
      oui = valid_org.oui
      bad_oui = oui + 1

      new_route =
        %{
          oui: bad_oui,
          net_id: Core.NetID.to_integer(Core.NetID.new(:net_id_sponsor, 11)),
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
          oui: oui,
          owner: owner_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteCreateReqV1.new()
        |> sign_request(sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.create(channel, req)

      assert(
        {:error,
         %GRPC.RPCError{
           status: GRPC.Status.invalid_argument(),
           message: "Request OUI does not match Route OUI."
         }} == result
      )
    end

    test "returns an RPC 'permission_denied' status given a RouteCreateReqV1 where 'owner' field does not match the 'owner_pubkey' of the referenced Organization",
         %{valid_org: valid_org} do
      %{public: bad_pubkey, secret: bad_privkey} = Core.Crypto.generate_key_pair()
      bad_pubkey_bin = Core.Crypto.pubkey_to_bin(bad_pubkey)
      bad_sigfun = Core.Crypto.mk_sig_fun(bad_privkey)

      oui = valid_org.oui

      new_route =
        %{
          oui: oui,
          net_id: Core.NetID.to_integer(Core.NetID.new(:net_id_sponsor, 11)),
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
          oui: oui,
          owner: bad_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteCreateReqV1.new()
        |> sign_request(bad_sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.create(channel, req)

      assert({:error, %GRPC.RPCError{}} = result)
    end
  end

  describe "update" do
    setup [:create_default_org]

    test "returns an updated RouteV1 given a valid RouteUpdateReqV1 signed by the Organization owner",
         %{
           valid_org: valid_org,
           owner_sigfun: sigfun,
           owner_pubkey_bin: owner_pubkey_bin
         } do
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
          route: route_params,
          owner: owner_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteUpdateReqV1.new()
        |> sign_request(sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.update(channel, req)

      assert({:ok, %{__struct__: RouteV1}} = result)
    end

    test "returns an RPC 'unauthenticated' status given a RouteUpdatedReqV1 with an invalid signature",
         %{valid_org: valid_org, owner_sigfun: sigfun} do
      %{public: bad_pubkey} = Core.Crypto.generate_key_pair()
      bad_pubkey_bin = Core.Crypto.pubkey_to_bin(bad_pubkey)

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
          route: route_params,
          owner: bad_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteUpdateReqV1.new()
        |> sign_request(sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.update(channel, req)

      assert(
        {:error,
         %GRPC.RPCError{
           status: GRPC.Status.unauthenticated(),
           message: "Invalid request signature"
         }} == result
      )
    end

    test "returns an RPC 'permission_dened' status given a RouteUpdatedReqV1 where 'owner' does not match the 'owner_pubkey' of the referenced Organization",
         %{valid_org: valid_org} do
      %{public: bad_pubkey, secret: bad_privkey} = Core.Crypto.generate_key_pair()
      bad_pubkey_bin = Core.Crypto.pubkey_to_bin(bad_pubkey)
      bad_sigfun = Core.Crypto.mk_sig_fun(bad_privkey)

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
          route: route_params,
          owner: bad_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteUpdateReqV1.new()
        |> sign_request(bad_sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.update(channel, req)

      assert(
        {:error,
         %GRPC.RPCError{
           status: GRPC.Status.permission_denied(),
           message: "Request owner does not match Organization owner."
         }} == result
      )
    end
  end

  describe "delete" do
    setup [:create_default_org]

    test "returns a RouteV1 containing the deleted object given a valid RouteDeleteReqV1", %{
      valid_org: valid_org,
      owner_sigfun: sigfun,
      owner_pubkey_bin: owner_pubkey_bin
    } do
      starting_route_len = length(valid_org.routes)
      route = hd(valid_org.routes)

      req =
        %{
          id: route.id,
          owner: owner_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteDeleteReqV1.new()
        |> sign_request(sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.delete(channel, req)

      assert({:ok, %{__struct__: RouteV1}} = result)

      remaining_route_len = length(HeliumConfig.list_routes())

      assert(remaining_route_len == starting_route_len - 1)
    end

    test "returns an RPC 'unauthenticated' status given a RouteDeleteReqV1 with an invalid signature",
         %{
           valid_org: valid_org,
           owner_pubkey_bin: owner_pubkey_bin
         } do
      %{secret: bad_privkey} = Core.Crypto.generate_key_pair()
      bad_sigfun = Core.Crypto.mk_sig_fun(bad_privkey)

      route = hd(valid_org.routes)

      req =
        %{
          id: route.id,
          owner: owner_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteDeleteReqV1.new()
        |> sign_request(bad_sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.delete(channel, req)

      assert(
        {:error,
         %GRPC.RPCError{
           status: GRPC.Status.unauthenticated(),
           message: "Invalid request signature"
         }} == result
      )
    end

    test "returns an RPC 'unauthenticated' status given a RouteDeleteReqV1 with an invalid 'owner'",
         %{valid_org: valid_org, owner_sigfun: sigfun} do
      route = hd(valid_org.routes)

      req =
        %{
          id: route.id,
          owner: "",
          timestamp: utc_now_msec()
        }
        |> RouteDeleteReqV1.new()
        |> sign_request(sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.delete(channel, req)

      assert(
        {:error, %GRPC.RPCError{status: GRPC.Status.unauthenticated(), message: "Invalid owner"}} ==
          result
      )
    end

    test "returns an RPC 'permission_denied' status given a RouteDeleteReqV1 where the 'owner' does not match the owner_pubkey of the referenced Organization",
         %{valid_org: valid_org} do
      %{public: bad_pubkey, secret: bad_privkey} = Core.Crypto.generate_key_pair()
      bad_pubkey_bin = Core.Crypto.pubkey_to_bin(bad_pubkey)
      bad_sigfun = Core.Crypto.mk_sig_fun(bad_privkey)

      route = hd(valid_org.routes)

      req =
        %{
          id: route.id,
          owner: bad_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteDeleteReqV1.new()
        |> sign_request(bad_sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.delete(channel, req)

      assert(
        {:error,
         %GRPC.RPCError{
           status: GRPC.Status.permission_denied(),
           message: "Request owner does not match Organization owner."
         }} == result
      )
    end
  end

  defp create_default_org(ctx) do
    %{public: owner_pubkey, secret: owner_privkey} = Core.Crypto.generate_key_pair()
    owner_sigfun = Core.Crypto.mk_sig_fun(owner_privkey)
    owner_pubkey_bin = Core.Crypto.pubkey_to_bin(owner_pubkey)

    valid_org =
      valid_core_organization(owner_pubkey: owner_pubkey)
      |> HeliumConfig.create_organization!()

    ctx
    |> Map.put(:valid_org, valid_org)
    |> Map.put(:owner_pubkey, owner_pubkey)
    |> Map.put(:owner_pubkey_bin, owner_pubkey_bin)
    |> Map.put(:owner_sigfun, owner_sigfun)
  end

  defp sign_request(%{__struct__: RouteCreateReqV1} = req, sigfun) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> RouteCreateReqV1.encode()

    signature = sigfun.(base_req_bin)

    %{req | signature: signature}
  end

  defp sign_request(%{__struct__: RouteUpdateReqV1} = req, sigfun) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> RouteUpdateReqV1.encode()

    signature = sigfun.(base_req_bin)

    %{req | signature: signature}
  end

  defp sign_request(%{__struct__: RouteDeleteReqV1} = req, sigfun) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> RouteUpdateReqV1.encode()

    signature = sigfun.(base_req_bin)

    %{req | signature: signature}
  end

  defp sign_request(%{__struct__: RouteGetReqV1} = req, sigfun) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> RouteGetReqV1.encode()

    signature = sigfun.(base_req_bin)

    %{req | signature: signature}
  end

  defp sign_request(%{__struct__: RouteListReqV1} = req, sigfun) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> RouteListReqV1.encode()

    signature = sigfun.(base_req_bin)

    %{req | signature: signature}
  end
end
