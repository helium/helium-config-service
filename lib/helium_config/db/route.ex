defmodule HeliumConfig.DB.Route do
  use Ecto.Schema

  import Ecto.Changeset

  alias HeliumConfig.DB
  alias HeliumConfig.Core

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema("routes") do
    field :oui, :decimal
    field :net_id, :integer
    field :max_copies, :integer

    has_one :server, DB.RouteServer, on_replace: :delete

    has_many :euis, DB.EuiPair, on_replace: :delete

    has_many :devaddr_ranges, DB.DevaddrRange, on_replace: :delete

    timestamps()
  end

  def changeset(route, fields \\ %{})

  def changeset(%__MODULE__{} = route, %Core.Route{} = core_route) do
    route_params = %{
      id: core_route.id,
      oui: core_route.oui,
      net_id: core_route.net_id,
      max_copies: core_route.max_copies,
      server: core_route.server,
      euis: core_route.euis,
      devaddr_ranges: devaddr_range_params(core_route.devaddr_ranges)
    }

    changeset(route, route_params)
  end

  def changeset(%__MODULE__{} = route, fields) do
    route
    |> cast(fields, [:id, :net_id, :max_copies, :oui])
    |> unique_constraint(:id)
    |> foreign_key_constraint(:oui)
    |> cast_assoc(:devaddr_ranges)
    |> cast_assoc(:euis)
    |> cast_assoc(:server)
  end

  defp devaddr_range_params(ranges) do
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
