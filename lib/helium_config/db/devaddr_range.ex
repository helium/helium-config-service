defmodule HeliumConfig.DB.DevaddrRange do
  @moduledoc """
  A schema representing a range of devaddrs.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias HeliumConfig.DB.Route

  @primary_key false
  schema "devaddr_ranges" do
    field :start_addr, :integer
    field :end_addr, :integer

    belongs_to :route, Route

    timestamps()
  end

  def changeset(range, fields) do
    range
    |> cast(fields, [:start_addr, :end_addr])
    |> validate_number(:start_addr, greater_than_or_equal_to: 0)
    |> validate_number(:end_addr, greater_than_or_equal_to: 0)
  end
end
