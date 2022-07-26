defmodule HeliumConfig.DB.Organization do
  @moduledoc """
  Schema representing an Organization.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias HeliumConfig.Core
  alias HeliumConfig.DB.Route

  @primary_key {:oui, :integer, []}
  @derive {Phoenix.Param, key: :oui}
  schema "organizations" do
    field :owner_wallet_id, :string
    field :payer_wallet_id, :string

    has_many :routes, Route,
      foreign_key: :oui,
      references: :oui,
      on_replace: :delete

    timestamps()
  end

  def changeset(fields) do
    changeset(%__MODULE__{}, fields)
  end

  def changeset(nil, params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(organization, core_org = %Core.Organization{}) do
    fields = %{
      oui: core_org.oui,
      owner_wallet_id: core_org.owner_wallet_id,
      payer_wallet_id: core_org.payer_wallet_id,
      routes: core_org.routes
    }

    organization
    |> cast(fields, [:oui, :owner_wallet_id, :payer_wallet_id])
    |> cast_assoc(:routes)
  end

  def changeset(organization, fields = %{}) do
    organization
    |> cast(fields, [:oui, :owner_wallet_id, :payer_wallet_id])
    |> cast_assoc(:routes)
  end
end
