defmodule HeliumConfig.DB.Organization do
  use Ecto.Schema

  import Ecto.Changeset

  alias HeliumConfig.Core
  alias HeliumConfig.DB

  @primary_key {:oui, :decimal, []}
  @derive {Phoenix.Param, key: :oui}
  schema("organizations") do
    field :owner_pubkey, :string
    field :payer_pubkey, :string

    has_many :routes, DB.Route,
      foreign_key: :oui,
      references: :oui,
      on_replace: :delete

    has_many :devaddr_constraints, DB.DevaddrConstraint,
      foreign_key: :oui,
      references: :oui,
      on_replace: :delete

    timestamps()
  end

  def changeset(organization = %__MODULE__{}, core_org = %Core.Organization{}) do
    fields =
      %{
        oui: core_org.oui,
        owner_pubkey: Core.Crypto.pubkey_to_b58(core_org.owner_pubkey),
        payer_pubkey: Core.Crypto.pubkey_to_b58(core_org.payer_pubkey),
        devaddr_constraints: constraint_params(core_org.devaddr_constraints)
      }
      |> maybe_add_routes(core_org.routes)

    changeset(organization, fields)
  end

  def changeset(organization = %__MODULE__{}, fields = %{}) do
    organization
    |> cast(fields, [:oui, :owner_pubkey, :payer_pubkey])
    |> cast_assoc(:routes)
    |> cast_assoc(:devaddr_constraints)
  end

  defp maybe_add_routes(fields, routes) when is_list(routes) do
    Map.put(fields, :routes, routes)
  end

  defp maybe_add_routes(fields, _), do: fields

  defp constraint_params(ranges) do
    Enum.map(ranges, fn {%Core.Devaddr{} = s, %Core.Devaddr{} = e} ->
      %{
        type: s.type,
        nwk_id: s.nwk_id,
        start_nwk_addr: s.nwk_addr,
        end_nwk_addr: e.nwk_addr
      }
    end)
  end
end
