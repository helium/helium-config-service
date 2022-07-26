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

  defstruct oui: nil,
            owner_wallet_id: nil,
            payer_wallet_id: nil,
            routes: []

  alias HeliumConfig.Core.Route
  alias HeliumConfig.DB

  def new(fields \\ %{}) do
    routes =
      fields
      |> Map.get(:routes, [])
      |> Enum.map(&Route.new/1)

    fields = Map.put(fields, :routes, routes)

    struct!(__MODULE__, fields)
  end

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
