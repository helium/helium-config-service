defmodule HeliumConfig.DB.Organization do
  use Ecto.Schema

  import Ecto.Changeset

  alias HeliumConfig.Core
  alias HeliumConfig.DB

  @primary_key {:oui, :integer, []}
  @derive {Phoenix.Param, key: :oui}
  schema("organizations") do
    field :owner_wallet_id, :string
    field :payer_wallet_id, :string

    has_many :routes, DB.Route,
      foreign_key: :oui,
      references: :oui,
      on_replace: :delete

    timestamps()
  end

  def changeset(organization = %__MODULE__{}, core_org = %Core.Organization{}) do
    fields = %{
      oui: core_org.oui,
      owner_wallet_id: core_org.owner_wallet_id,
      payer_wallet_id: core_org.payer_wallet_id
    }
    |> maybe_add_routes(core_org.routes)

    changeset(organization, fields)
  end

  def changeset(organization = %__MODULE__{}, fields = %{}) do
    organization
    |> cast(fields, [:oui, :owner_wallet_id, :payer_wallet_id])
    |> unique_constraint(:oui)
    |> cast_assoc(:routes)
  end

  defp maybe_add_routes(fields, routes) when is_list(routes) do
    Map.put(fields, :routes, routes)
  end

  defp maybe_add_routes(fields, _), do: fields
end
