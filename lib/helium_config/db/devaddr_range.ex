defmodule HeliumConfig.DB.DevaddrRange do
  use Ecto.Schema

  import Ecto.Changeset

  alias HeliumConfig.DB

  @devaddr_types [
    :devaddr_6x25,
    :devaddr_6x24,
    :devaddr_9x20,
    :devaddr_11x17,
    :devaddr_12x15,
    :devaddr_13x13,
    :devaddr_15x10,
    :devaddr_17x7
  ]

  schema("route_devaddr_ranges") do
    field :type, Ecto.Enum, values: @devaddr_types
    field :nwk_id, :integer
    field :start_nwk_addr, :integer
    field :end_nwk_addr, :integer

    belongs_to :route, DB.Route, type: Ecto.UUID

    timestamps()
  end

  def changeset(%__MODULE__{} = range, fields) do
    range
    |> cast(fields, [:type, :nwk_id, :start_nwk_addr, :end_nwk_addr])
  end
end
