defmodule StartOver.DB.RouteServer do
  use Ecto.Schema

  import Ecto.Changeset

  alias StartOver.Core
  alias StartOver.DB

  schema("route_servers") do
    field :host, :string
    field :port, :integer

    embeds_one :protocol_opts, DB.ProtocolOpts

    belongs_to :route, DB.Route, type: Ecto.UUID

    timestamps()
  end

  def changeset(%__MODULE__{} = server, %Core.RouteServer{} = core_server) do
    fields = %{
      host: core_server.host,
      port: core_server.port,
      protocol_opts: core_server.protocol_opts
    }

    changeset(server, fields)
  end

  def changeset(server = %__MODULE__{}, fields) do
    server
    |> cast(fields, [:host, :port])
    |> cast_embed(:protocol_opts)
  end
end
