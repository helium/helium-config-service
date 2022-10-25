defmodule StartOverGRPC.RouteView do
  @moduledoc """
  Provides functions to convert StartOver.Core.Route structs to maps suitable for encoding protobuf messages.
  """

  alias StartOver.Core.GwmpOpts
  alias StartOver.Core.PacketRouterOpts
  alias StartOver.Core.HttpRoamingOpts
  alias StartOver.Core.Route
  alias StartOver.Core.RouteServer

  def route_params(route = %Route{}) do
    %{
      oui: route.oui,
      net_id: route.net_id,
      max_copies: route.max_copies,
      server: server_params(route.server),
      euis: Enum.map(route.euis, &eui_pair_params/1),
      devaddr_ranges: Enum.map(route.devaddr_ranges, &devaddr_range_params/1)
    }
  end

  def server_params(%RouteServer{host: host, port: port, protocol_opts: opts}) do
    %{
      host: host,
      port: port,
      protocol: protocol_params(opts)
    }
  end

  def protocol_params(%HttpRoamingOpts{}), do: {:http_roaming, %{dummy_value: true}}

  def protocol_params(%GwmpOpts{mapping: mapping}) do
    {:gwmp,
     %{
       mapping:
         Enum.map(
           mapping,
           fn
             {region, port} -> %{region: region, port: port}
           end
         )
     }}
  end

  def protocol_params(%PacketRouterOpts{}), do: {:packet_router, %{dummy_value: true}}

  def eui_pair_params(%{app_eui: _app, dev_eui: _dev} = pair), do: pair

  def devaddr_range_params({s, e}) do
    %{
      start_addr: s,
      end_addr: e
    }
  end
end
