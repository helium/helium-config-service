defmodule HeliumConfig.Core.HttpRoamingOpts do
  defstruct [:dedupe_timeout, :flow_type, :path]

  alias Proto.Helium.Config.ProtocolHttpRoamingV1

  def new(params \\ %{}) do
    %__MODULE__{
      dedupe_timeout: Map.get(params, :dedupe_timeout),
      flow_type: Map.get(params, :flow_type),
      path: Map.get(params, :path)
    }
  end

  def from_proto(%{__struct__: ProtocolHttpRoamingV1} = proto) do
    %__MODULE__{
      dedupe_timeout: proto.dedupe_timeout,
      flow_type: flow_type_from_proto(proto.flow_type),
      path: proto.path
    }
  end

  def flow_type_from_proto(:async), do: :async
  def flow_type_from_proto(:sync), do: :sync

  def from_web(%{"type" => "http_roaming"} = fields) do
    fields
    |> Enum.reduce(%__MODULE__{}, fn
      {"type", "http_roaming"}, acc -> acc
      {"dedupe_timeout", window}, acc -> Map.put(acc, :dedupe_timeout, window)
      {"flow_type", type}, acc -> Map.put(acc, :flow_type, flow_type_from_web(type))
      {"path", path}, acc -> Map.put(acc, :path, path)
    end)
  end

  def flow_type_from_web("async"), do: :async
  def flow_type_from_web("sync"), do: :sync

  def from_db(db_opts) do
    db_opts
    |> Enum.reduce(%__MODULE__{}, fn
      {"dedupe_timeout", window}, acc -> Map.put(acc, :dedupe_timeout, window)
      {"flow_type", type}, acc -> Map.put(acc, :flow_type, flow_type_from_db(type))
      {"path", path}, acc -> Map.put(acc, :path, path)
    end)
  end

  def flow_type_from_db("sync"), do: :sync
  def flow_type_from_db("async"), do: :async
end
