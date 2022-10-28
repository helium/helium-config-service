defmodule HeliumConfigGRPC.OrgServerTest do
  use HeliumConfig.DataCase

  import HeliumConfig.Fixtures

  alias HeliumConfig.DB
  alias HeliumConfig.Repo
  alias Proto.Helium.Config, as: ConfigProto
  alias HeliumConfigGRPC.OrganizationView

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

  describe "create" do
    test "returns an OrgV1 given a valid OrgCreateReqV1" do
      assert(0 == length(Repo.all(DB.Organization)))
      
      org =
	valid_core_organization()
      |> OrganizationView.organization_params()
      |> ConfigProto.OrgV1.new()

      req = ConfigProto.OrgCreateReqV1.new(%{org: org})

      {:ok, channel} = GRPC.Stub.connect("localhost:50051")

      result = ConfigProto.Org.Stub.create(channel, req)

      assert({:ok, %{__struct__: ConfigProto.OrgV1}} = result)

      assert(1 == length(Repo.all(DB.Organization)))
    end
  end

  defp create_default_org(ctx) do
    valid_org =
      valid_core_organization()
      |> HeliumConfig.create_organization()

    Map.put(ctx, :valid_org, valid_org)
  end
end
