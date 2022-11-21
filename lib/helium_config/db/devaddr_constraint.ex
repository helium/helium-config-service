defmodule HeliumConfig.DB.DevaddrConstraint do
  use Ecto.Schema

  import Ecto.Changeset

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

  schema("organization_devaddr_constraints") do
    field :oui, :decimal
    field :type, Ecto.Enum, values: @devaddr_types
    field :nwk_id, :integer
    field :start_nwk_addr, :integer
    field :end_nwk_addr, :integer

    timestamps()
  end

  def changeset(%__MODULE__{} = range, fields) do
    range
    |> cast(fields, [:oui, :type, :nwk_id, :start_nwk_addr, :end_nwk_addr])
  end
end
