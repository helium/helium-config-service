defmodule HeliumConfig.DB.ProtocolOpts do
  use Ecto.Schema

  alias HeliumConfig.Core

  import Ecto.Changeset

  embedded_schema do
    field :type, Ecto.Enum, values: [:http_roaming, :gwmp, :packet_router]
    field :opts, :map
  end

  def changeset(%__MODULE__{} = protocol_opts, %Core.HttpRoamingOpts{} = opts) do
    fields = %{
      type: :http_roaming,
      opts: %{
        "dedupe_timeout" => opts.dedupe_timeout,
        "flow_type" => Atom.to_string(opts.flow_type),
        "path" => opts.path
      }
    }

    changeset(protocol_opts, fields)
  end

  def changeset(%__MODULE__{} = protocol_opts, %Core.GwmpOpts{} = opts) do
    fields = %{
      type: :gwmp,
      opts: %{
        "mapping" =>
          Enum.map(opts.mapping, fn {region, port} ->
            %{"region" => Atom.to_string(region), "port" => port}
          end)
      }
    }

    changeset(protocol_opts, fields)
  end

  def changeset(%__MODULE__{} = protocol_opts, %Core.PacketRouterOpts{}) do
    fields = %{
      type: :packet_router,
      opts: %{}
    }

    changeset(protocol_opts, fields)
  end

  def changeset(%__MODULE__{} = protocol_opts, %{} = fields) do
    protocol_opts
    |> cast(fields, [:type, :opts])
  end
end
