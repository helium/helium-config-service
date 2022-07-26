defmodule HeliumConfig.Core.Organization do
  defstruct [:oui, :owner_pubkey, :payer_pubkey, :routes, :devaddr_constraints]

  alias HeliumConfig.Core
  alias HeliumConfig.DB
  alias Proto.Helium.Config, as: ConfigProto

  def new(params \\ %{}) do
    routes =
      params
      |> Map.get(:routes, [])
      |> Enum.map(&Core.Route.new/1)

    constraints =
      params
      |> Map.get(:devaddr_constraints, [])
      |> Enum.map(&maybe_new_devaddr_range/1)

    params =
      params
      |> Map.put(:routes, routes)
      |> Map.put(:devaddr_constraints, constraints)

    struct!(__MODULE__, params)
  end

  def new_roamer(owner_pubkey, payer_pubkey, net_id) do
    constraints = [Core.DevaddrRange.from_net_id(net_id)]

    new(%{
      owner_pubkey: owner_pubkey,
      payer_pubkey: payer_pubkey,
      devaddr_constraints: constraints
    })
  end

  def new_helium(owner_pubkey, payer_pubkey) do
    next_addr = DB.next_helium_devaddr_constraint_start()
    constraints = [Core.Devaddr.to_devaddr_range(next_addr, 8)]

    new(%{
      owner_pubkey: owner_pubkey,
      payer_pubkey: payer_pubkey,
      devaddr_constraints: constraints
    })
  end

  def member?(%__MODULE__{devaddr_constraints: constraints}, %Core.Devaddr{} = devaddr) do
    Enum.any?(constraints, &Core.DevaddrRange.member?(&1, devaddr))
  end

  def routes(%__MODULE__{routes: routes}, %Core.Devaddr{} = devaddr) do
    Enum.filter(routes, &Core.Route.member?(&1, devaddr))
  end

  def routes(%__MODULE__{} = o, devaddr) when is_binary(devaddr) do
    routes(o, Core.Devaddr.from_str(devaddr))
  end

  def from_web(json_params) do
    Enum.reduce(
      json_params,
      %__MODULE__{},
      fn
        {"oui", oui}, acc ->
          Map.put(acc, :oui, oui_from_web(oui))

        {"owner_pubkey", id}, acc ->
          Map.put(acc, :owner_pubkey, pubkey_from_web(id))

        {"payer_pubkey", id}, acc ->
          Map.put(acc, :payer_pubkey, pubkey_from_web(id))

        {"routes", routes}, acc ->
          Map.put(acc, :routes, Enum.map(routes, &Core.Route.from_web/1))

        {"devaddr_constraints", constraints}, acc ->
          Map.put(acc, :devaddr_constraints, Enum.map(constraints, &Core.DevaddrRange.from_web/1))
      end
    )
  end

  defp pubkey_from_web(b58), do: Core.Crypto.b58_to_pubkey(b58)

  def oui_from_web(oui) when is_integer(oui), do: oui

  def oui_from_web(oui) when is_binary(oui), do: String.to_integer(oui)

  def from_db(%DB.Organization{} = db_org) do
    %__MODULE__{
      oui: Decimal.to_integer(db_org.oui),
      owner_pubkey: Core.Crypto.b58_to_pubkey(db_org.owner_pubkey),
      payer_pubkey: Core.Crypto.b58_to_pubkey(db_org.payer_pubkey),
      devaddr_constraints: Enum.map(db_org.devaddr_constraints, &constraint_from_db/1)
    }
    |> maybe_routes_from_db(db_org.routes)
  end

  defp constraint_from_db(%DB.DevaddrConstraint{
         type: type,
         nwk_id: nwk_id,
         start_nwk_addr: start_addr,
         end_nwk_addr: end_addr
       }) do
    Core.DevaddrRange.new(type, nwk_id, start_addr, end_addr)
  end

  defp maybe_routes_from_db(core_org, routes) when is_list(routes) do
    Map.put(core_org, :routes, Enum.map(routes, &Core.Route.from_db/1))
  end

  defp maybe_routes_from_db(core_org, _), do: core_org

  def from_proto(%{__struct__: ConfigProto.OrgV1} = proto_org) do
    %__MODULE__{
      oui: proto_org.oui,
      owner_pubkey: pubkey_bin_from_proto(proto_org.owner),
      payer_pubkey: pubkey_bin_from_proto(proto_org.payer)
    }
  end

  defp pubkey_bin_from_proto(proto_id) do
    HeliumConfig.Core.Crypto.bin_to_pubkey(proto_id)
  end

  defp maybe_new_devaddr_range({%Core.Devaddr{}, %Core.Devaddr{}} = range), do: range

  defp maybe_new_devaddr_range(%{} = params), do: Core.DevaddrRange.new(params)
end
