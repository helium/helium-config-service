defmodule HeliumConfigGRPC.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run(HeliumConfigGRPC.RouteServer)
  run(HeliumConfigGRPC.OrgServer)
end

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
    req.org
    |> Core.Organization.from_proto()
    |> HeliumConfig.create_organization()
    |> OrganizationView.organization_params()
    |> ConfigProto.OrgV1.new()
  end
end

defmodule HeliumConfigGRPC.RouteServer do
  use GRPC.Server, service: Proto.Helium.Config.Route.Service

  alias Proto.Helium.Config, as: ConfigProto
  alias HeliumConfig.Core
  alias HeliumConfigGRPC.RouteStreamWorker
  alias HeliumConfigGRPC.RouteView

  def stream(%{__struct__: ConfigProto.RouteStreamReqV1}, stream) do
    {:ok, worker} =
      GenServer.start_link(RouteStreamWorker, notifier: :update_notifier, stream: stream)

    ref = Process.monitor(worker)

    receive do
      {:DOWN, ^ref, _, _, _} -> :ok
    end

    stream
  end

  def list(%{__struct__: ConfigProto.RouteListReqV1}, _stream) do
    routes =
      HeliumConfig.list_routes()
      |> Enum.map(&RouteView.route_params/1)
      |> Enum.map(&ConfigProto.RouteV1.new/1)

    ConfigProto.RouteListResV1.new(%{routes: routes})
  end

  def get(%{__struct__: ConfigProto.RouteGetReqV1} = req, _stream) do
    req.id
    |> HeliumConfig.get_route()
    |> RouteView.route_params()
    |> ConfigProto.RouteV1.new()
  end

  def create(%{__struct__: ConfigProto.RouteCreateReqV1} = req, _stream) do
    req.route
    |> Core.Route.from_proto()
    |> HeliumConfig.create_route()
    |> RouteView.route_params()
    |> ConfigProto.RouteV1.new()
  end

  def update(%{__struct__: ConfigProto.RouteUpdateReqV1} = req, _stream) do
    req.route
    |> Core.Route.from_proto()
    |> HeliumConfig.update_route()
    |> RouteView.route_params()
    |> ConfigProto.RouteV1.new()
  end

  def delete(%{__struct__: ConfigProto.RouteDeleteReqV1} = req, _stream) do
    req.id
    |> HeliumConfig.delete_route()
    |> RouteView.route_params()
    |> ConfigProto.RouteV1.new()
  end
end
