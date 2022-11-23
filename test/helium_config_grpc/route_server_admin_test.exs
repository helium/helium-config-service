defmodule HeliumConfigGRPC.RouteServerAdminTest do
  use HeliumConfig.DataCase, async: false

  import HeliumConfig.Fixtures

  alias HeliumConfig.Core

  alias HeliumConfigGRPC.RouteView

  alias Proto.Helium.Config.RouteV1
  alias Proto.Helium.Config.RouteDeleteReqV1
  alias Proto.Helium.Config.RouteGetReqV1
  alias Proto.Helium.Config.RouteListReqV1
  alias Proto.Helium.Config.RouteListResV1
  alias Proto.Helium.Config.RouteStreamReqV1
  alias Proto.Helium.Config.RouteCreateReqV1
  alias Proto.Helium.Config.RouteUpdateReqV1
  alias Proto.Helium.Config.Route.Stub, as: RouteStub

  setup ctx do
    previous_env = Application.get_env(:helium_config, HeliumConfigGRPC)
    on_exit(fn -> Application.put_env(:helium_config, HeliumConfigGRPC, previous_env) end)
    create_admin_keys(ctx)
  end

  describe "stream" do
    setup [:create_default_org]

    test "returns a stream of RouteStreamResV1 given a valid RouteStreamReqV1", %{
      admin_pubkey_bin: pubkey_bin,
      admin_sigfun: sigfun
    } do
      req =
        %{
          pub_key: pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteStreamReqV1.new()
        |> sign_request(sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = RouteStub.stream(channel, req)

      assert({:ok, _} = result)
    end

    test "returns an RPC 'permission_denied' given a RouteStreamReqV1 signed by a non-admin key" do
      %{public: bad_pubkey, secret: bad_privkey} = Core.Crypto.generate_key_pair()
      bad_pubkey_bin = Core.Crypto.pubkey_to_bin(bad_pubkey)
      bad_sigfun = Core.Crypto.mk_sig_fun(bad_privkey)

      req =
        %{
          pub_key: bad_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteStreamReqV1.new()
        |> sign_request(bad_sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = RouteStub.stream(channel, req)

      assert(
        {:error,
         %GRPC.RPCError{status: GRPC.Status.permission_denied(), message: "Permission denied."}} ==
          result
      )
    end

    test "returns an RPC 'unauthenticated' status given a RouteStreamReqV1 with an invalid signature",
         %{admin_sigfun: sigfun} do
      %{public: bad_pubkey} = Core.Crypto.generate_key_pair()
      bad_pubkey_bin = Core.Crypto.pubkey_to_bin(bad_pubkey)

      req =
        %{
          pub_key: bad_pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteStreamReqV1.new()
        |> sign_request(sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = RouteStub.stream(channel, req)

      assert(
        {:error,
         %GRPC.RPCError{
           status: GRPC.Status.unauthenticated(),
           message: "Invalid request signature"
         }} == result
      )
    end
  end

  describe "create" do
    setup [:create_default_org]

    test "returns a RouteV1 given a valid RouteCreateReqV1 signed by an admin key", %{
      valid_org: valid_org,
      admin_pubkey: pubkey,
      admin_sigfun: sigfun
    } do
      oui = valid_org.oui
      pubkey_bin = Core.Crypto.pubkey_to_bin(pubkey)

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
          owner: pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteCreateReqV1.new()
        |> sign_request(sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.create(channel, req)

      assert({:ok, %{__struct__: RouteV1}} = result)
    end
  end

  describe "get" do
    setup [:create_default_org]

    test "returns a RouteV1 given a valid RouteGetReqV1 signed by an admin key", %{
      valid_org: valid_org,
      admin_pubkey: pubkey,
      admin_sigfun: sigfun
    } do
      {:ok, channel} = GRPC.Stub.connect("localhost:50051")
      route = hd(valid_org.routes)
      pubkey_bin = Core.Crypto.pubkey_to_bin(pubkey)

      req =
        %{
          id: route.id,
          owner: pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteGetReqV1.new()
        |> sign_request(sigfun)

      result = Proto.Helium.Config.Route.Stub.get(channel, req)
      assert({:ok, %{__struct__: RouteV1}} = result)
    end
  end

  describe "list" do
    setup [:create_default_org]

    test "returns a RouteListResV1 given a valid RouteListReqV1 signed by an admin key", %{
      valid_org: valid_org,
      admin_pubkey_bin: pubkey_bin,
      admin_sigfun: sigfun
    } do
      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      req =
        %{
          oui: valid_org.oui,
          owner: pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteListReqV1.new()
        |> sign_request(sigfun)

      result = Proto.Helium.Config.Route.Stub.list(channel, req)
      assert({:ok, %{__struct__: RouteListResV1} = res} = result)
      assert(length(res.routes) > 1)
      assert(length(valid_org.routes) == length(res.routes))
    end
  end

  describe "update" do
    setup [:create_default_org]

    test "returns an updated RouteV1 given a valid RouteUpdateReqV1 signed by an admin key", %{
      valid_org: valid_org,
      admin_pubkey_bin: pubkey_bin,
      admin_sigfun: sigfun
    } do
      route = hd(valid_org.routes)

      route_params =
        route
        |> Map.put(:server, %Core.RouteServer{
          host: "updated_server.testdomain.com",
          port: 4567,
          protocol_opts: %Core.PacketRouterOpts{}
        })
        |> RouteView.route_params()

      req =
        %{
          oui: route.oui,
          route: route_params,
          owner: pubkey_bin,
          timestamp: utc_now_msec()
        }
        |> RouteUpdateReqV1.new()
        |> sign_request(sigfun)

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = Proto.Helium.Config.Route.Stub.update(channel, req)

      assert({:ok, %{__struct__: RouteV1}} = result)
    end
  end

  describe "delete" do
    setup [:create_default_org]

    test "returns a RouteV1 containing the deleted object given a valid RouteDeleteReqV1 signed by an admin key",
         %{
           valid_org: valid_org,
           admin_pubkey_bin: pubkey,
           admin_sigfun: sigfun
         } do
      starting_route_len = length(valid_org.routes)
      route = hd(valid_org.routes)

      req =
        %{
          id: route.id,
          owner: pubkey,
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
  end

  defp sign_request(%{__struct__: RouteStreamReqV1} = req, sigfun) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> RouteStreamReqV1.encode()

    signature = sigfun.(base_req_bin)

    %{req | signature: signature}
  end

  defp sign_request(%{__struct__: RouteCreateReqV1} = req, sigfun) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> RouteCreateReqV1.encode()

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
      |> RouteDeleteReqV1.encode()

    signature = sigfun.(base_req_bin)

    %{req | signature: signature}
  end

  defp create_admin_keys(ctx) do
    %{public: pubkey, secret: privkey} = HeliumConfig.Core.Crypto.generate_key_pair()
    pubkey_b58 = Core.Crypto.pubkey_to_b58(pubkey)
    pubkey_bin = Core.Crypto.pubkey_to_bin(pubkey)
    sigfun = Core.Crypto.mk_sig_fun(privkey)

    Application.put_env(:helium_config, HeliumConfigGRPC,
      auth_enabled: true,
      admin_keys: [pubkey_b58],
      admin_sigfun: sigfun
    )

    ctx
    |> Map.put(:admin_pubkey, pubkey)
    |> Map.put(:admin_pubkey_b58, pubkey_b58)
    |> Map.put(:admin_pubkey_bin, pubkey_bin)
    |> Map.put(:admin_sigfun, sigfun)
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
end
