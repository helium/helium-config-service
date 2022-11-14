defmodule HeliumConfigGRPC.RouteView do
  @moduledoc """
  Provides functions to convert HeliumConfig.Core.Route structs to maps suitable for encoding protobuf messages.
  """

  alias HeliumConfig.Core.Devaddr
  alias HeliumConfig.Core.GwmpOpts
  alias HeliumConfig.Core.PacketRouterOpts
  alias HeliumConfig.Core.HttpRoamingOpts
  alias HeliumConfig.Core.Route
  alias HeliumConfig.Core.RouteServer

  def route_params(route = %Route{}) do
    %{
      id: route.id,
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

  def devaddr_range_params({%Devaddr{} = s, %Devaddr{} = e}) do
    %{
      start_addr: Devaddr.to_integer(s),
      end_addr: Devaddr.to_integer(e)
    }
  end
end
