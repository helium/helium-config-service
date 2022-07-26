defmodule HeliumConfig.DB.Route do
  @moduledoc """
  Database schema for Routes
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias HeliumConfig.Core.Route, as: CoreRoute
  alias HeliumConfig.DB.DevaddrRange
  alias HeliumConfig.DB.EUI
  alias HeliumConfig.DB.Organization

  defmodule ProtocolType do
    @moduledoc """
    Ecto Type for storing LNS protocol in the database.

    The supported input values are :http and :gwmp.
    """

    use Ecto.Type
    def type, do: :string

    def cast(term), do: {:ok, term}

    def load("http"), do: {:ok, :http}
    def load("gwmp"), do: {:ok, :gwmp}
    def load(_), do: :error

    def dump(:http), do: Ecto.Type.dump(:string, "http")
    def dump(:gwmp), do: Ecto.Type.dump(:string, "gwmp")
    def dump(_), do: :error
  end

  schema "routes" do
    field :net_id, :integer
    field :lns_address, :string
    field :protocol, __MODULE__.ProtocolType

    has_many :euis,
             EUI,
             on_replace: :delete

    has_many :devaddr_ranges,
             DevaddrRange,
             on_replace: :delete

    belongs_to :organization, Organization, foreign_key: :oui, references: :oui

    timestamps()
  end

  def changeset(core_route = %CoreRoute{}) do
    changeset(%__MODULE__{}, core_route)
  end

  def changeset(route = %__MODULE__{}, core_route = %CoreRoute{}) do
    fields = %{
      net_id: core_route.net_id,
      lns_address: core_route.lns_address,
      protocol: core_route.protocol,
      euis: core_route.euis,
      devaddr_ranges:
        Enum.map(core_route.devaddr_ranges, fn {s, e} -> %{start_addr: s, end_addr: e} end)
    }

    changeset(route, fields)
  end

  def changeset(route = %__MODULE__{}, fields = %{}) do
    route
    |> cast(fields, [:net_id, :lns_address, :protocol])
    |> cast_assoc(:devaddr_ranges)
    |> cast_assoc(:euis)
  end
end
