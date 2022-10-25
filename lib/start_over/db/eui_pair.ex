defmodule StartOver.DB.EuiPair do
  use Ecto.Schema

  import Ecto.Changeset

  alias StartOver.DB

  schema("route_eui_pairs") do
    field :app_eui, :decimal
    field :dev_eui, :decimal

    belongs_to :route, DB.Route, type: Ecto.UUID

    timestamps()
  end

  def changeset(pair = %__MODULE__{}, fields \\ %{}) do
    pair
    |> cast(fields, [:app_eui, :dev_eui])
  end
end
