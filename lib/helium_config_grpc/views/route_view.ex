defmodule HeliumConfigGRPC.RouteView do
  @moduledoc """
  Provides functions to convert HeliumConfig.Core.Route structs to maps suitable for encoding protobuf messages.
  """

  alias HeliumConfig.Core.Route

  def route_params(route = %Route{}) do
    %{
      net_id: route.net_id,
      lns: route.lns_address,
      protocol: route.protocol,
      euis: Enum.map(route.euis, &eui_pair_params/1),
      devaddr_ranges: Enum.map(route.devaddr_ranges, &devaddr_range_params/1)
    }
  end

  def eui_pair_params(pair = %{app_eui: _app, dev_eui: _dev}), do: pair

  def devaddr_range_params({s, e}) do
    %{
      start_addr: s,
      end_addr: e
    }
  end
end
