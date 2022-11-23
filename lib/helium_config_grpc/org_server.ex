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
      |> HeliumConfig.create_organization!()
      |> OrganizationView.organization_params()
      |> ConfigProto.OrgV1.new()
    rescue
      e in Core.InvalidDataError ->
        raise GRPC.RPCError, status: GRPC.Status.invalid_argument(), message: e.message
    end
  end

  def create_helium(%{__struct__: ConfigProto.OrgCreateHeliumReqV1} = req, _steram) do
    owner_pubkey = Core.Crypto.bin_to_pubkey(req.owner)
    payer_pubkey = Core.Crypto.bin_to_pubkey(req.payer)

    with true <- maybe_auth_admin(req) do
      Core.Organization.new_helium(owner_pubkey, payer_pubkey)
      |> Core.OrganizationValidator.validate!()
      |> HeliumConfig.create_organization!()
      |> OrganizationView.org_res_params()
      |> ConfigProto.OrgResV1.new()
    else
      false ->
        raise GRPC.RPCError,
          status: GRPC.Status.permission_denied(),
          message: "Permission denied."
    end
  end

  def create_roamer(%{__struct__: ConfigProto.OrgCreateRoamerReqV1} = req, _stream) do
    owner_pubkey = Core.Crypto.bin_to_pubkey(req.owner)
    payer_pubkey = Core.Crypto.bin_to_pubkey(req.payer)
    net_id = Core.NetID.from_integer(req.net_id)

    with true <- maybe_auth_admin(req) do
      Core.Organization.new_roamer(owner_pubkey, payer_pubkey, net_id)
      |> Core.OrganizationValidator.validate!()
      |> HeliumConfig.create_organization!()
      |> OrganizationView.org_res_params()
      |> ConfigProto.OrgResV1.new()
    else
      false ->
        raise GRPC.RPCError,
          status: GRPC.Status.permission_denied(),
          message: "Permission denied."
    end
  end

  def get(%{__struct__: ConfigProto.OrgGetReqV1} = req, _stream) do
    req.oui
    |> HeliumConfig.get_organization()
    |> OrganizationView.org_res_params()
    |> ConfigProto.OrgResV1.new()
  end

  # ===================================================================

  def maybe_auth_admin(req) do
    # Rather than threading the booleans through all the way, let's just check
    # if we are returned out the original request. That means, we haven't thrown,
    # and we haven't been rejected.

    # NOTE: Only Admins can create organizations
    # pubkeys = [req.owner | Enum.map(get_admin_keys(), &Core.Crypto.b58_to_bin/1)]
    pubkeys = Enum.map(get_admin_keys(), &Core.Crypto.b58_to_bin/1)
    checks =
      Enum.map(pubkeys, fn pubkey ->
        try do
          do_maybe_auth_admin(req, pubkey) == req
        rescue
          _e in GRPC.RPCError -> false
        end
      end)

    case Enum.any?(checks) do
      true -> true
      # If none pass, call again with the first pubkey to raise an error
      false -> do_maybe_auth_admin(req, List.first(pubkeys))
    end
  end

  def do_maybe_auth_admin(req, pubkey) do
    case get_auth_enabled() do
      true ->
        req
        |> authenticate(pubkey)
        |> authorize_admin()

      false ->
        req
    end
  end

  defp get_auth_enabled do
    :helium_config
    |> Application.get_env(HeliumConfigGRPC, [])
    |> Keyword.get(:auth_enabled, false)
  end

  def authenticate(
        %{
          __struct__: ConfigProto.OrgCreateHeliumReqV1,
          signature: signature,
          timestamp: timestamp
        } = req,
        pubkey
      ) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> ConfigProto.OrgCreateHeliumReqV1.encode()

    authenticate(req, base_req_bin, signature, pubkey, timestamp)
  end

  def authenticate(
        %{
          __struct__: ConfigProto.OrgCreateRoamerReqV1,
          signature: signature,
          timestamp: timestamp
        } = req,
        pubkey
      ) do
    base_req_bin =
      req
      |> Map.put(:signature, nil)
      |> ConfigProto.OrgCreateRoamerReqV1.encode()

    authenticate(req, base_req_bin, signature, pubkey, timestamp)
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

  # FIXME: I don't think this is correct. We want messages signed by an admin
  # key to take any action, not force admin keys to be the owners or requests.
  def authorize_admin(%{owner: _pubkey_bin} = req) do
    req
    # pubkey_b58 = Core.Crypto.bin_to_b58(pubkey_bin)
    # admin_keys = get_admin_keys()

    # case Enum.member?(admin_keys, pubkey_b58) do
    #   true ->
    #     req

    #   false ->
    #     raise GRPC.RPCError,
    #       status: GRPC.Status.permission_denied(),
    #       message: "Permission denied."
    # end
  end

  def get_admin_keys do
    :helium_config
    |> Application.get_env(HeliumConfigGRPC, [])
    |> Keyword.get(:admin_keys, [])
  end
end
