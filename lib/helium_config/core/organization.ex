defmodule HeliumConfig.Core.Organization do
  defstruct [:oui, :owner_wallet_id, :payer_wallet_id, :routes]

  alias HeliumConfig.Core.Route
  alias HeliumConfig.DB
  alias Proto.Helium.Config, as: ConfigProto

  def new(params \\ %{}) do
    routes =
      params
      |> Map.get(:routes, [])
      |> Enum.map(&Route.new/1)

    params = Map.put(params, :routes, routes)

    struct!(__MODULE__, params)
  end

  def from_web(json_params) do
    Enum.reduce(
      json_params,
      %__MODULE__{},
      fn
        {"oui", oui}, acc -> Map.put(acc, :oui, oui_from_web(oui))
        {"owner_wallet_id", id}, acc -> Map.put(acc, :owner_wallet_id, id)
        {"payer_wallet_id", id}, acc -> Map.put(acc, :payer_wallet_id, id)
        {"routes", routes}, acc -> Map.put(acc, :routes, Enum.map(routes, &Route.from_web/1))
      end
    )
  end

  def oui_from_web(oui) when is_integer(oui), do: oui

  def oui_from_web(oui) when is_binary(oui), do: String.to_integer(oui)

  def from_db(%DB.Organization{} = db_org) do
    %__MODULE__{
      oui: Decimal.to_integer(db_org.oui),
      owner_wallet_id: db_org.owner_wallet_id,
      payer_wallet_id: db_org.payer_wallet_id
    }
    |> maybe_routes_from_db(db_org.routes)
  end

  defp maybe_routes_from_db(core_org, routes) when is_list(routes) do
    Map.put(core_org, :routes, Enum.map(routes, &Route.from_db/1))
  end

  defp maybe_routes_from_db(core_org, _), do: core_org

  def from_proto(%{__struct__: ConfigProto.OrgV1} = proto_org) do
    %__MODULE__{
      oui: proto_org.oui,
      owner_wallet_id: proto_org.owner,
      payer_wallet_id: proto_org.payer
    }
  end
end
