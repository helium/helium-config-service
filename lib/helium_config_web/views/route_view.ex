defmodule HeliumConfigWeb.RouteView do
  use HeliumConfigWeb, :view

  def render("routes.json", %{routes: routes}) do
    %{
      routes: Enum.map(routes, &route_json/1)
    }
  end

  def route_json(route) do
    %{
      net_id: route.net_id,
      lns_address: route.lns_address,
      protocol: protocol_json(route.protocol),
      euis: route.euis,
      devaddr_ranges: Enum.map(route.devaddr_ranges, &devaddr_range_json/1)
    }
  end

  def protocol_json(proto) when is_atom(proto), do: to_string(proto)

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
