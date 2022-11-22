defmodule HeliumConfigGRPC.OrgServerTest do
  use HeliumConfig.DataCase

  import HeliumConfig.Fixtures

  alias Proto.Helium.Config, as: ConfigProto

  describe "list" do
    setup [:create_default_org]

    test "returns an OrgListResV1 given a valid OrgListReqV1" do
      req = ConfigProto.OrgListResV1.new()
      {:ok, channel} = GRPC.Stub.connect("localhost:50051")
      result = ConfigProto.Org.Stub.list(channel, req)

      assert({:ok, %{__struct__: ConfigProto.OrgListResV1} = org_res} = result)
      assert(length(org_res.orgs) == 1)
    end
  end

  describe "get" do
    setup [:create_default_org]

    test "returns a an OrgResV1 given a valid OrgGetReqV1", %{valid_org: org} do
      req = ConfigProto.OrgGetReqV1.new(%{oui: org.oui})
      {:ok, channel} = GRPC.Stub.connect("localhost:50051")
      result = ConfigProto.Org.Stub.get(channel, req)
      net_id = valid_net_id(0)

      assert({:ok, %{__struct__: ConfigProto.OrgResV1} = org_res} = result)
      assert(%{__struct__: ConfigProto.OrgV1} = org_res.org)
      assert(net_id == org_res.net_id)
      assert(1 == length(org_res.devaddr_ranges))
    end
  end

  describe "create" do
    test "roaming org" do
      %{public: owner_pubkey, secret: owner_secret} = HeliumConfig.Core.Crypto.generate_key_pair()
      %{public: payer_pubkey} = HeliumConfig.Core.Crypto.generate_key_pair()
      :ok = store_pubkey_as_admin_key(owner_pubkey)

      req =
        sign_request(
          owner_secret,
          ConfigProto.OrgCreateRoamerReqV1.new(%{
            owner: HeliumConfig.Core.Crypto.pubkey_to_bin(owner_pubkey),
            payer: HeliumConfig.Core.Crypto.pubkey_to_bin(payer_pubkey),
            timestamp: HeliumConfig.Fixtures.utc_now_msec(),
            net_id: 0xC00053
          })
        )

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")
      result = ConfigProto.Org.Stub.create_roamer(channel, req)

      assert({:ok, %{__struct__: ConfigProto.OrgResV1} = org_res} = result)
      assert(%{__struct__: ConfigProto.OrgV1} = org_res.org)
      assert(0xC00053 == org_res.net_id)
      assert(1 == length(org_res.devaddr_ranges))

      {start_addr, end_addr} =
        HeliumConfig.Core.NetID.from_integer(0xC00053)
        |> HeliumConfig.Core.DevaddrRange.from_net_id()

      assert([%{__struct__: ConfigProto.DevaddrRangeV1} = range] = org_res.devaddr_ranges)
      assert(HeliumConfig.Core.Devaddr.to_integer(start_addr) == range.start_addr)
      assert(HeliumConfig.Core.Devaddr.to_integer(end_addr) == range.end_addr)
    end

    test "helium org" do
      %{public: owner_pubkey, secret: owner_secret} = HeliumConfig.Core.Crypto.generate_key_pair()
      %{public: payer_pubkey} = HeliumConfig.Core.Crypto.generate_key_pair()
      :ok = store_pubkey_as_admin_key(owner_pubkey)

      req =
        sign_request(
          owner_secret,
          ConfigProto.OrgCreateHeliumReqV1.new(%{
            owner: HeliumConfig.Core.Crypto.pubkey_to_bin(owner_pubkey),
            payer: HeliumConfig.Core.Crypto.pubkey_to_bin(payer_pubkey),
            timestamp: HeliumConfig.Fixtures.utc_now_msec()
          })
        )

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")
      result = ConfigProto.Org.Stub.create_helium(channel, req)

      assert({:ok, %{__struct__: ConfigProto.OrgResV1} = org_res} = result)
      assert(%{__struct__: ConfigProto.OrgV1} = org_res.org)
      assert(0xC00053 == org_res.net_id)
      assert(1 == length(org_res.devaddr_ranges))

      {start_addr, _end_addr} =
        HeliumConfig.Core.NetID.from_integer(0xC00053)
        |> HeliumConfig.Core.DevaddrRange.from_net_id()

      assert([%{__struct__: ConfigProto.DevaddrRangeV1} = range] = org_res.devaddr_ranges)
      # NOTE: assuming default allocation of 8 devaddrs for now
      assert(HeliumConfig.Core.Devaddr.to_integer(start_addr) == range.start_addr)
      # NOTE: checking for 7, range includes start address
      assert(HeliumConfig.Core.Devaddr.to_integer(start_addr) + 7 == range.end_addr)

      # ====================================================
      # Make sure we choose the next 8 devaddrs
      # ====================================================
      %{public: owner_pubkey} = HeliumConfig.Core.Crypto.generate_key_pair()
      %{public: payer_pubkey} = HeliumConfig.Core.Crypto.generate_key_pair()

      # This is being signed with the previous owners key because it's been
      # inserted as an admin key.
      req =
        sign_request(
          owner_secret,
          ConfigProto.OrgCreateHeliumReqV1.new(%{
            owner: HeliumConfig.Core.Crypto.pubkey_to_bin(owner_pubkey),
            payer: HeliumConfig.Core.Crypto.pubkey_to_bin(payer_pubkey),
            timestamp: HeliumConfig.Fixtures.utc_now_msec()
          })
        )

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")
      result = ConfigProto.Org.Stub.create_helium(channel, req)

      assert({:ok, %{__struct__: ConfigProto.OrgResV1} = org_res} = result)
      assert(%{__struct__: ConfigProto.OrgV1} = org_res.org)
      assert(0xC00053 == org_res.net_id)
      assert(1 == length(org_res.devaddr_ranges))

      assert([%{__struct__: ConfigProto.DevaddrRangeV1} = range] = org_res.devaddr_ranges)
      # NOTE: assuming default allocation of 8 devaddrs for now
      assert(HeliumConfig.Core.Devaddr.to_integer(start_addr) + 8 == range.start_addr)
      # NOTE: checking for 7, range includes start address
      assert(HeliumConfig.Core.Devaddr.to_integer(start_addr) + 8 + 7 == range.end_addr)
    end
  end

  defp create_default_org(ctx) do
    valid_org =
      valid_core_organization()
      |> HeliumConfig.create_organization!()

    Map.put(ctx, :valid_org, valid_org)
  end

  defp sign_request(secret_key, request) do
    sig_fun = HeliumConfig.Core.Crypto.mk_sig_fun(secret_key)
    encoded = ConfigProto.OrgCreateHeliumReqV1.encode(request)
    %{request | signature: sig_fun.(encoded)}
  end

  defp store_pubkey_as_admin_key(pubkey) do
    b58 = HeliumConfig.Core.Crypto.pubkey_to_b58(pubkey)
    grpc_env = Application.get_env(:helium_config, HeliumConfigGRPC)
    grpc_env = Keyword.put(grpc_env, :admin_keys, [b58])
    Application.put_env(:helium_config, HeliumConfigGRPC, grpc_env)
    :ok
  end
end
