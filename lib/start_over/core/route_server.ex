defmodule StartOver.Core.RouteServer do
  defstruct [:host, :port, :protocol_opts]

  alias StartOver.Core.HttpRoamingOpts
  alias StartOver.Core.GwmpOpts
  alias StartOver.Core.PacketRouterOpts
  alias StartOver.DB

  def new(params \\ %{}) do
    protocol_params =
      params
      |> Map.get(:protocol_opts)
      |> new_protocol_params()

    params = Map.put(params, :protocol_opts, protocol_params)

    struct!(__MODULE__, params)
  end

  def new_protocol_params(%{type: :http_roaming} = opts) do
    HttpRoamingOpts.new(opts)
  end

  def new_protocol_params(%{type: :gwmp} = opts) do
    GwmpOpts.new(opts)
  end

  def new_protocol_params(%{type: :packet_router} = opts) do
    PacketRouterOpts.new(opts)
  end

  def from_db(%DB.RouteServer{} = server) do
    %__MODULE__{
      host: server.host,
      port: server.port,
      protocol_opts: protocol_opts_from_db(server.protocol_opts)
    }
  end

  def protocol_opts_from_db(%DB.ProtocolOpts{type: :http_roaming, opts: opts}) do
    HttpRoamingOpts.from_db(opts)
  end

  def protocol_opts_from_db(%DB.ProtocolOpts{type: :gwmp, opts: opts}) do
    GwmpOpts.from_db(opts)
  end

  def protocol_opts_from_db(%DB.ProtocolOpts{type: :packet_router, opts: opts}) do
    PacketRouterOpts.from_db(opts)
  end

  def from_proto(%{__struct__: Proto.Helium.Config.ServerV1} = server) do
    params = %{
      host: server.host,
      port: server.port,
      protocol_opts: protocol_opts_from_proto(server.protocol)
    }

    struct!(__MODULE__, params)
  end

  def protocol_opts_from_proto({:http_roaming, roaming}) do
    HttpRoamingOpts.from_proto(roaming)
  end

  def protocol_opts_from_proto({:gwmp, gwmp}) do
    GwmpOpts.from_proto(gwmp)
  end

  def protocol_opts_from_proto({:packet_router, packet_router}) do
    PacketRouterOpts.from_proto(packet_router)
  end

  def from_web(json_params) do
    Enum.reduce(json_params, %__MODULE__{}, fn
      {"host", host}, acc ->
        Map.put(acc, :host, host)

      {"port", port}, acc ->
        Map.put(acc, :port, port)

      {"protocol", proto_opts}, acc ->
        Map.put(acc, :protocol_opts, protocol_opts_from_web(proto_opts))
    end)
  end

  def protocol_opts_from_web(%{"type" => "http_roaming"} = opts) do
    HttpRoamingOpts.from_web(opts)
  end

  def protocol_opts_from_web(%{"type" => "gwmp"} = opts) do
    GwmpOpts.from_web(opts)
  end

  def protocol_opts_from_web(%{"type" => "packet_router"} = opts) do
    PacketRouterOpts.from_web(opts)
  end
end
