defmodule HeliumConfigWeb.RouteView do
  use HeliumConfigWeb, :view

  alias HeliumConfig.Core.GwmpLns
  alias HeliumConfig.Core.HeliumRouterLns
  alias HeliumConfig.Core.HttpRoamingLns

  def render("routes.json", %{routes: routes}) do
    %{
      routes: Enum.map(routes, &route_json/1)
    }
  end

  def route_json(route) do
    %{
      net_id: route.net_id,
      lns: lns_json(route.lns),
      euis: route.euis,
      devaddr_ranges: Enum.map(route.devaddr_ranges, &devaddr_range_json/1)
    }
  end

  def lns_json(lns = %HttpRoamingLns{}) do
    %{
      type: "http_roaming",
      host: lns.host,
      port: lns.port,
      auth_header: lns.auth_header,
      dedupe_window: lns.dedupe_window
    }
  end

  def lns_json(lns = %GwmpLns{}) do
    %{
      type: "gwmp",
      host: lns.host,
      port: lns.port
    }
  end

  def lns_json(lns = %HeliumRouterLns{}) do
    %{
      type: "helium_router",
      host: lns.host,
      port: lns.port
    }
  end

  def devaddr_range_json({s, e}) do
    %{
      start_addr: devaddr_to_hex_string(s),
      end_addr: devaddr_to_hex_string(e)
    }
  end

  def devaddr_to_hex_string(devaddr) do
    devaddr
    |> Integer.to_string(16)
    |> String.pad_leading(8, "0")
  end
end
