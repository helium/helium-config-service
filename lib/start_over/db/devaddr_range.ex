defmodule StartOver.DB.DevaddrRange do
  use Ecto.Schema

  import Ecto.Changeset

  alias StartOver.DB

  schema("route_devaddr_ranges") do
    field :start_addr, :integer
    field :end_addr, :integer

    belongs_to :route, DB.Route, type: Ecto.UUID

    timestamps()
  end

  def changeset(%__MODULE__{} = range, fields) do
    range
    |> cast(fields, [:start_addr, :end_addr])
  end
end
