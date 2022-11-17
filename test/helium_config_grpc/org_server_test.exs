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

      assert({:ok, %{__struct__: ConfigProto.OrgResV1}} = result)
    end
  end

  defp create_default_org(ctx) do
    valid_org =
      valid_core_organization()
      |> HeliumConfig.create_organization()

    Map.put(ctx, :valid_org, valid_org)
  end
end
