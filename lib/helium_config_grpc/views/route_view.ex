defmodule HeliumConfigGRPC.RouteView do
  @moduledoc """
  Provides functions to convert HeliumConfig.Core.Route structs to maps suitable for encoding protobuf messages.
  """

  alias HeliumConfig.Core.GwmpLns
  alias HeliumConfig.Core.HeliumRouterLns
  alias HeliumConfig.Core.HttpRoamingLns
  alias HeliumConfig.Core.Route

  def route_params(route = %Route{}) do
    %{
      net_id: route.net_id,
      protocol: lns_params(route.lns),
      euis: Enum.map(route.euis, &eui_pair_params/1),
      devaddr_ranges: Enum.map(route.devaddr_ranges, &devaddr_range_params/1)
    }
  end

  def lns_params(%HttpRoamingLns{host: host, port: port}) do
    {:http_roaming,
     %{
       ip: host,
       port: port
     }}
  end

  def lns_params(%GwmpLns{host: host, port: port}) do
    {:gwmp,
     %{
       ip: host,
       port: port
     }}
  end

  def lns_params(%HeliumRouterLns{host: host, port: port}) do
    {:router,
     %{
       ip: host,
       port: port
     }}
  end

  def eui_pair_params(pair = %{app_eui: _app, dev_eui: _dev}), do: pair

  def devaddr_range_params({s, e}) do
    %{
      start_addr: s,
      end_addr: e
    }
  end
end
