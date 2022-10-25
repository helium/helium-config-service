defmodule StartOver.Core.Organization do
  defstruct [:oui, :owner_wallet_id, :payer_wallet_id, :routes]

  alias StartOver.Core.Route
  alias StartOver.DB

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
      oui: db_org.oui,
      owner_wallet_id: db_org.owner_wallet_id,
      payer_wallet_id: db_org.payer_wallet_id,
      routes: Enum.map(db_org.routes, &Route.from_db/1)
    }
  end
end
