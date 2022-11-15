defmodule HeliumConfigGRPC.OrgServer do
  use GRPC.Server, service: Proto.Helium.Config.Org.Service

  alias Proto.Helium.Config, as: ConfigProto
  alias HeliumConfigGRPC.OrganizationView
  alias HeliumConfig.Core

  def list(%{__struct__: ConfigProto.OrgListReqV1}, _stream) do
    orgs =
      HeliumConfig.list_organizations()
      |> Enum.map(&OrganizationView.organization_params/1)

    ConfigProto.OrgListResV1.new(%{orgs: orgs})
  end

  def create(%{__struct__: ConfigProto.OrgCreateReqV1} = req, _stream) do
    try do
      req
      |> Map.get(:org)
      |> Core.Organization.from_proto()
      |> Core.OrganizationValidator.validate!()
      |> HeliumConfig.create_organization()
      |> OrganizationView.organization_params()
      |> ConfigProto.OrgV1.new()
    rescue
      e in Core.InvalidDataError ->
        raise GRPC.RPCError, status: GRPC.Status.invalid_argument(), message: e.message
    end
  end

  def create_roamer(%{__struct__: ConfigProto.Org.CreateRoamerReqV1} = req, _stream) do
    org =
      req.owner
      |> Core.Organization.new_roamer(req.payer, Core.NetID.from_integer(req.net_id))
      |> Core.OrganizationValidator.validate!()
      |> HeliumConfig.create_organization()
      |> OrganizationView.organization_params()
      |> ConfigProto.OrgV1.new()


    ConfigProto.OrgResV1.new(%{
	  org: org,
	  net_id: req.net_id,
	  devaddr_ranges: []
			     })
  end

  def get(%{__struct__: ConfigProto.OrgGetReqV1} = req, _stream) do
    req.oui
    |> HeliumConfig.get_organization()
    |> OrganizationView.organization_params()
    |> ConfigProto.OrgV1.new()
  end
end
