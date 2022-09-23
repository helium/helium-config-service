defmodule HeliumConfig.Core.Organization do
  @moduledoc """
  A data model representing an organization.

  If you're looking for an OUI, this is it.

  In conversation, we often use the term "OUI" to refer both to an
  Organizationally Unique Identifier and to the metadata associated
  with that identifier.  In HeliumConfig.Core, a distinction is drawn
  between the two: an OUI is an integer.  An Organization is a struct.
  An Organization has an OUI.
  """

  alias HeliumConfig.Core.Route
  alias HeliumConfig.DB

  @type b58_pubkey :: String.t()

  @type t :: %__MODULE__{
          oui: integer,
          owner_wallet_id: b58_pubkey,
          payer_wallet_id: b58_pubkey,
          routes: [Route.t()]
        }

  # Valid keys for json_params are:
  # "oui" => integer,
  # "owner_wallet_id" => bf8_pubkey,
  # "payer_wallet_id" => bf8_pubkey,
  # "routes" => [ Route.json_params ]
  @type json_params :: %{String.t() => any()}

  defstruct oui: nil,
            owner_wallet_id: nil,
            payer_wallet_id: nil,
            routes: []

  @spec new(json_params) :: t
  def new(fields \\ %{}) do
    routes =
      fields
      |> Map.get(:routes, [])
      |> Enum.map(&Route.new/1)

    fields = Map.put(fields, :routes, routes)

    struct!(__MODULE__, fields)
  end

  @spec from_web(map()) :: t()
  def from_web(web_fields = %{"oui" => _}) do
    params =
      web_fields
      |> Enum.reduce(%{}, fn
        {"oui", oui}, acc ->
          Map.put(acc, :oui, oui)

        {"owner_wallet_id", id}, acc ->
          Map.put(acc, :owner_wallet_id, id)

        {"payer_wallet_id", id}, acc ->
          Map.put(acc, :payer_wallet_id, id)

        {"routes", web_routes}, acc ->
          Map.put(acc, :routes, Enum.map(web_routes, &Route.from_web/1))
      end)

    struct!(__MODULE__, params)
  end

  def from_db(db_org = %DB.Organization{}) do
    struct!(__MODULE__, %{
      oui: db_org.oui,
      owner_wallet_id: db_org.owner_wallet_id,
      payer_wallet_id: db_org.payer_wallet_id,
      routes: Enum.map(db_org.routes, &Route.from_db/1)
    })
  end
end
