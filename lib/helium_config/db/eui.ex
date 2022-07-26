defmodule HeliumConfig.DB.EUI do
  @moduledoc """
  Schema representing an App/Dev EUI pair.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias HeliumConfig.DB.Route

  schema "route_euis" do
    field :app_eui, :integer
    field :dev_eui, :integer

    belongs_to :route, Route

    timestamps()
  end

  def changeset(eui, fields) do
    eui
    |> cast(fields, [:app_eui, :dev_eui])
  end
end
