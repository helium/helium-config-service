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

  def get(%{__struct__: ConfigProto.OrgGetReqV1} = req, _stream) do
    req.oui
    |> HeliumConfig.get_organization()
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

  def stream(%{__struct__: ConfigProto.RouteStreamReqV1} = req, stream) do
    req
    |> maybe_auth_admin()

    {:ok, worker} =
      GenServer.start_link(RouteStreamWorker, notifier: :update_notifier, stream: stream)

    ref = Process.monitor(worker)

    receive do
      {:DOWN, ^ref, _, _, _} -> :ok
    end

    stream
  end

  def list(%{__struct__: ConfigProto.RouteListReqV1} = req, _stream) do
    routes =
      req
      |> maybe_auth()
      |> Map.get(:oui)
      |> HeliumConfig.list_routes_for_organization()
      |> Enum.map(&RouteView.route_params/1)
      |> Enum.map(&ConfigProto.RouteV1.new/1)

    ConfigProto.RouteListResV1.new(%{routes: routes})
  end

  def get(%{__struct__: ConfigProto.RouteGetReqV1} = req, _stream) do
    req
    |> maybe_auth()
    |> Map.get(:id)
    |> HeliumConfig.get_route()
    |> RouteView.route_params()
    |> ConfigProto.RouteV1.new()
  end

  def create(%{__struct__: ConfigProto.RouteCreateReqV1} = req, _stream) do
    try do
      req
      |> maybe_auth()
      |> Map.get(:route)
      |> Core.Route.from_proto()
      |> Core.RouteValidator.validate!()
      |> HeliumConfig.create_route()
      |> RouteView.route_params()
      |> ConfigProto.RouteV1.new()
    rescue
      e in Core.InvalidDataError ->
        raise GRPC.RPCError, status: GRPC.Status.invalid_argument(), message: e.message
    end
  end

  def update(%{__struct__: ConfigProto.RouteUpdateReqV1} = req, _stream) do
    try do
      req
      |> maybe_auth()
      |> Map.get(:route)
      |> Core.Route.from_proto()
      |> Core.RouteValidator.validate!()
      |> HeliumConfig.update_route()
      |> RouteView.route_params()
      |> ConfigProto.RouteV1.new()
    rescue
      e in Core.InvalidDataError ->
        raise GRPC.RPCError, status: GRPC.Status.invalid_argument(), message: e.message
    end
  end

  def delete(%{__struct__: ConfigProto.RouteDeleteReqV1} = req, _stream) do
    req
    |> maybe_auth()
    |> Map.get(:id)
    |> HeliumConfig.delete_route()
    |> RouteView.route_params()
    |> ConfigProto.RouteV1.new()
  end

  def maybe_auth(req) do
    case get_auth_enabled() do
      true ->
        req
        |> authenticate()
        |> authorize_admin_or_owner()

      false ->
        req
    end
  end

  def maybe_auth_admin(req) do
    case get_auth_enabled() do
      true ->
        req
        |> authenticate()
        |> authorize_admin()

      false ->
        req
    end
  end

  def authenticate(%{__struct__: ConfigProto.RouteCreateReqV1} = req) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> ConfigProto.RouteCreateReqV1.encode()

    authenticate(req, base_req_bin, req.signature, req.owner, req.timestamp)
  end

  def authenticate(%{__struct__: ConfigProto.RouteUpdateReqV1} = req) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> ConfigProto.RouteUpdateReqV1.encode()

    authenticate(req, base_req_bin, req.signature, req.owner, req.timestamp)
  end

  def authenticate(%{__struct__: ConfigProto.RouteDeleteReqV1} = req) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> ConfigProto.RouteDeleteReqV1.encode()

    authenticate(req, base_req_bin, req.signature, req.owner, req.timestamp)
  end

  def authenticate(%{__struct__: ConfigProto.RouteGetReqV1} = req) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> ConfigProto.RouteGetReqV1.encode()

    authenticate(req, base_req_bin, req.signature, req.owner, req.timestamp)
  end

  def authenticate(%{__struct__: ConfigProto.RouteListReqV1} = req) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> ConfigProto.RouteListReqV1.encode()

    authenticate(req, base_req_bin, req.signature, req.owner, req.timestamp)
  end

  def authenticate(%{__struct__: ConfigProto.RouteStreamReqV1} = req) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> ConfigProto.RouteStreamReqV1.encode()

    authenticate(req, base_req_bin, req.signature, req.pub_key, req.timestamp)
  end

  @dialyzer {:nowarn_function, {:authenticate, 5}}
  def authenticate(req, req_bin, signature, pubkey_bin, timestamp) do
    with {:pubkey_bin_valid?, true} <- {:pubkey_bin_valid?, pubkey_bin_valid?(pubkey_bin)},
         pubkey <- Core.Crypto.bin_to_pubkey(pubkey_bin),
         {:signature_valid?, true} <-
           {:signature_valid?, signature_valid?(req_bin, signature, pubkey)},
         {:signature_not_expired?, true} <-
           {:signature_not_expired?, signature_not_expired?(timestamp)} do
      req
    else
      {:pubkey_bin_valid?, false} ->
        raise GRPC.RPCError, status: GRPC.Status.unauthenticated(), message: "Invalid owner"

      {:signature_valid?, false} ->
        raise GRPC.RPCError,
          status: GRPC.Status.unauthenticated(),
          message: "Invalid request signature"

      {:signature_not_expired?, false} ->
        raise GRPC.RPCError, status: GRPC.Status.permission_denied(), message: "Signature expired"

      other ->
        raise GRPC.RPCError,
          status: GRPC.Status.internal(),
          message: "Internal server error: #{inspect(other)}"
    end
  end

  def pubkey_bin_valid?(bin) do
    is_binary(bin) and byte_size(bin) > 20
  end

  def signature_valid?(bin, signature, pubkey) do
    Core.Crypto.verify(bin, signature, pubkey)
  end

  def signature_not_expired?(timestamp) do
    now_msec =
      DateTime.utc_now()
      |> DateTime.to_unix(:millisecond)

    time_diff = abs(now_msec - timestamp)
    time_diff < 60_000
  end

  def authorize_admin_or_owner(
        %{__struct__: ConfigProto.RouteCreateReqV1, owner: req_owner_bin} = req
      ) do
    owner_b58 = Core.Crypto.bin_to_b58(req_owner_bin)
    admin_keys = get_admin_keys()

    case Enum.member?(admin_keys, owner_b58) do
      true -> req
      false -> authorize(req)
    end
  end

  def authorize_admin_or_owner(
        %{__struct__: ConfigProto.RouteGetReqV1, owner: req_owner_bin} = req
      ) do
    req_owner_b58 = Core.Crypto.bin_to_b58(req_owner_bin)
    admin_keys = get_admin_keys()

    case Enum.member?(admin_keys, req_owner_b58) do
      true -> req
      false -> authorize(req)
    end
  end

  def authorize_admin_or_owner(
        %{__struct__: ConfigProto.RouteListReqV1, owner: req_owner_bin} = req
      ) do
    req_owner_b58 = Core.Crypto.bin_to_b58(req_owner_bin)
    admin_keys = get_admin_keys()

    case Enum.member?(admin_keys, req_owner_b58) do
      true -> req
      false -> authorize(req)
    end
  end

  def authorize_admin_or_owner(
        %{__struct__: ConfigProto.RouteUpdateReqV1, owner: req_owner_bin} = req
      ) do
    req_owner_b58 = Core.Crypto.bin_to_b58(req_owner_bin)
    admin_keys = get_admin_keys()

    case Enum.member?(admin_keys, req_owner_b58) do
      true -> req
      false -> authorize(req)
    end
  end

  def authorize_admin_or_owner(
        %{__struct__: ConfigProto.RouteDeleteReqV1, owner: req_owner_bin} = req
      ) do
    req_owner_b58 = Core.Crypto.bin_to_b58(req_owner_bin)
    admin_keys = get_admin_keys()

    case Enum.member?(admin_keys, req_owner_b58) do
      true -> req
      false -> authorize(req)
    end
  end

  @dialyzer {:nowarn_function, {:authorize, 1}}
  def authorize(
        %{__struct__: ConfigProto.RouteCreateReqV1, owner: req_owner_bin, oui: oui, route: route} =
          req
      ) do
    with req_owner_pubkey <- Core.Crypto.bin_to_pubkey(req_owner_bin),
         {:req_oui_matches_route_oui, true} <- {:req_oui_matches_route_oui, oui == route.oui},
         {:db_org, db_org} <- {:db_org, HeliumConfig.get_organization(oui)},
         {:org_owner_matches_req_owner, true} <-
           {:org_owner_matches_req_owner, db_org.owner_pubkey == req_owner_pubkey} do
      req
    else
      {:req_oui_matches_route_oui, false} ->
        raise GRPC.RPCError,
          status: GRPC.Status.invalid_argument(),
          message: "Request OUI does not match Route OUI."

      {:org_owner_matches_req_owner, false} ->
        raise GRPC.RPCError,
          status: GRPC.Status.permission_denied(),
          message: "Request owner does not match Organization owner."

      other ->
        raise GRPC.RPCError,
          status: GRPC.Status.internal(),
          message: "Internal error: #{inspect(other)}"
    end
  end

  def authorize(
        %{__struct__: ConfigProto.RouteUpdateReqV1, owner: req_owner_bin, route: route} = req
      ) do
    with req_owner_pubkey = Core.Crypto.bin_to_pubkey(req_owner_bin),
         {:db_org, db_org} <- {:db_org, HeliumConfig.get_organization(route.oui)},
         {:org_owner_matches_req_owner, true} <-
           {:org_owner_matches_req_owner, db_org.owner_pubkey == req_owner_pubkey} do
      req
    else
      {:org_owner_matches_req_owner, false} ->
        raise GRPC.RPCError,
          status: GRPC.Status.permission_denied(),
          message: "Request owner does not match Organization owner."
    end
  end

  def authorize(
        %{__struct__: ConfigProto.RouteDeleteReqV1, owner: req_owner_bin, id: route_id} = req
      ) do
    with req_owner_pubkey <- Core.Crypto.bin_to_pubkey(req_owner_bin),
         {:db_route, db_route} <- {:db_route, HeliumConfig.get_route(route_id)},
         {:db_org, db_org} <- {:db_org, HeliumConfig.get_organization(db_route.oui)},
         {:org_owner_matches_req_owner, true} <-
           {:org_owner_matches_req_owner, db_org.owner_pubkey == req_owner_pubkey} do
      req
    else
      {:org_owner_matches_req_owner, false} ->
        raise GRPC.RPCError,
          status: GRPC.Status.permission_denied(),
          message: "Request owner does not match Organization owner."
    end
  end

  def authorize(
        %{__struct__: ConfigProto.RouteGetReqV1, owner: req_owner_bin, id: route_id} = req
      ) do
    with req_owner_pubkey <- Core.Crypto.bin_to_pubkey(req_owner_bin),
         {:db_route, db_route} <- {:db_route, HeliumConfig.get_route(route_id)},
         {:db_org, db_org} <- {:db_org, HeliumConfig.get_organization(db_route.oui)},
         {:org_owner_matches_req_owner, true} <-
           {:org_owner_matches_req_owner, db_org.owner_pubkey == req_owner_pubkey} do
      req
    else
      {:org_owner_matches_req_owner, false} ->
        raise GRPC.RPCError,
          status: GRPC.Status.permission_denied(),
          message: "Request owner does not match Organization owner."
    end
  end

  def authorize(%{__struct__: ConfigProto.RouteListReqV1, owner: req_owner_bin, oui: oui} = req) do
    with req_owner_pubkey <- Core.Crypto.bin_to_pubkey(req_owner_bin),
         {:db_org, db_org} <- {:db_org, HeliumConfig.get_organization(oui)},
         {:org_owner_matches_req_owner, true} <-
           {:org_owner_matches_req_owner, db_org.owner_pubkey == req_owner_pubkey} do
      req
    else
      {:org_owner_matches_req_owner, false} ->
        raise GRPC.RPCError,
          status: GRPC.Status.permission_denied(),
          message: "Request owner does not match Organization owner."
    end
  end

  def authorize_admin(%{pub_key: pubkey_bin} = req) do
    pubkey_b58 = Core.Crypto.bin_to_b58(pubkey_bin)
    admin_keys = get_admin_keys()

    case Enum.member?(admin_keys, pubkey_b58) do
      true ->
        req

      false ->
        raise GRPC.RPCError,
          status: GRPC.Status.permission_denied(),
          message: "Permission denied."
    end
  end

  defp get_admin_keys do
    :helium_config
    |> Application.get_env(HeliumConfigGRPC, [])
    |> Keyword.get(:admin_keys, [])
  end

  defp get_auth_enabled do
    :helium_config
    |> Application.get_env(HeliumConfigGRPC, [])
    |> Keyword.get(:auth_enabled, false)
  end
end
