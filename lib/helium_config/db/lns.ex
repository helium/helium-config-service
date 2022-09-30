defmodule HeliumConfig.DB.Lns do
  @moduledoc """
  This is a database representation of a LoRaWAN network server.

  The HeliumConfig.Core data model has three kinds of LNS:
  HttpRoamingLns, GwmpLns, and HeliumRouterLns.  This schema allows us
  to store the three types in the same database table under a
  normalized format.  The `type` field indicates which kind it is.
  The `protocol_params` field holds a map containing LNS type-specific
  options, and the remaining fields, like 'host' and 'port', are common
  to all LNS implementations.

  """

  use Ecto.Schema

  import Ecto.Changeset

  defmodule LnsType do
    @moduledoc false

    use Ecto.Type
    def type, do: :string

    def cast(term), do: {:ok, term}

    def load("http_roaming"), do: {:ok, :http_roaming}
    def load("gwmp"), do: {:ok, :gwmp}
    def load("helium_router"), do: {:ok, :helium_router}
    def load(_), do: :error

    def dump(:http_roaming), do: Ecto.Type.dump(:string, "http_roaming")
    def dump(:gwmp), do: Ecto.Type.dump(:string, "gwmp")
    def dump(:helium_router), do: Ecto.Type.dump(:string, "helium_router")
    def dump(_), do: :error
  end

  alias HeliumConfig.Core.GwmpLns
  alias HeliumConfig.Core.HeliumRouterLns
  alias HeliumConfig.Core.HttpRoamingLns

  schema "route_lns" do
    belongs_to :route, HeliumConfig.DB.Route
    field :type, __MODULE__.LnsType
    field :host, :string
    field :port, :integer
    field :protocol_params, :map

    timestamps()
  end

  def changeset(lns, fields \\ %{})

  def changeset(lns = %__MODULE__{}, roaming = %HttpRoamingLns{}) do
    roaming_params =
      %{}
      |> Map.put("auth_header", roaming.auth_header)
      |> Map.put("dedupe_window", roaming.dedupe_window)

    lns_params =
      %{}
      |> Map.put(:type, :http_roaming)
      |> Map.put(:host, roaming.host)
      |> Map.put(:port, roaming.port)
      |> Map.put(:protocol_params, roaming_params)

    changeset(lns, lns_params)
  end

  def changeset(lns = %__MODULE__{}, roaming = %GwmpLns{}) do
    lns_params = %{
      type: :gwmp,
      host: roaming.host,
      port: roaming.port,
      protocol_params: %{}
    }

    changeset(lns, lns_params)
  end

  def changeset(lns = %__MODULE__{}, roaming = %HeliumRouterLns{}) do
    lns_params = %{
      type: :helium_router,
      host: roaming.host,
      port: roaming.port,
      protocol_params: %{}
    }

    changeset(lns, lns_params)
  end

  def changeset(lns = %__MODULE__{}, fields) do
    lns
    |> cast(fields, [:type, :host, :port, :protocol_params])
    |> validate_required([:type, :host, :port])
  end
end
