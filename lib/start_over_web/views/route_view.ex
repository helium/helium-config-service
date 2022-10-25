defmodule StartOverWeb.RouteView do
  use StartOverWeb, :view

  alias StartOver.Core.Route
  alias StartOver.Core.RouteServer
  alias StartOver.Core.HttpRoamingOpts
  alias StartOver.Core.GwmpOpts
  alias StartOver.Core.PacketRouterOpts

  @nybbles_in_an_eui 16
  @nybbles_in_a_devaddr 8
  @nybbles_in_a_net_id 6

  def render("route.json", %{route: route}) do
    route_json(route)
  end

  def render("routes.json", %{routes: routes}) do
    Enum.map(routes, &route_json/1)
  end

  def route_json(%Route{} = route) do
    %{
      id: route.id,
      oui: route.oui,
      net_id: net_id_json(route.net_id),
      max_copies: route.max_copies,
      server: server_json(route.server),
      euis: Enum.map(route.euis, &eui_pair_to_hex_strings/1),
      devaddr_ranges: devaddr_range_json(route.devaddr_ranges)
    }
  end

  def organization_route_json(%Route{} = route) do
    %{
      id: route.id,
      net_id: net_id_json(route.net_id),
      max_copies: route.max_copies,
      server: server_json(route.server),
      euis: Enum.map(route.euis, &eui_pair_to_hex_strings/1),
      devaddr_ranges: devaddr_range_json(route.devaddr_ranges)
    }
  end

  def net_id_json(id) when is_integer(id) do
    id
    |> Integer.to_string(16)
    |> String.pad_leading(@nybbles_in_a_net_id, "0")
  end

  def server_json(%RouteServer{} = server) do
    %{
      host: server.host,
      port: server.port,
      protocol: protocol_json(server.protocol_opts)
    }
  end

  def protocol_json(%HttpRoamingOpts{} = opts) do
    %{
      type: "http_roaming",
      dedupe_window: opts.dedupe_window,
      auth_header: opts.auth_header
    }
  end

  def protocol_json(%GwmpOpts{mapping: mappings}) do
    %{
      type: "gwmp",
      mapping:
        Enum.map(mappings, fn {region, port} ->
          %{
            region: region_json(region),
            port: port
          }
        end)
    }
  end

  def protocol_json(%PacketRouterOpts{}) do
    %{
      type: "packet_router"
    }
  end

  def eui_pair_to_hex_strings(%{app_eui: app, dev_eui: dev})
      when is_integer(app) and is_integer(dev) do
    %{
      app_eui: eui_to_hex_string(app),
      dev_eui: eui_to_hex_string(dev)
    }
  end

  def eui_to_hex_string(eui) do
    eui
    |> Integer.to_string(16)
    |> String.pad_leading(@nybbles_in_an_eui, "0")
  end

  def devaddr_to_hex_string(devaddr) do
    devaddr
    |> Integer.to_string(16)
    |> String.pad_leading(@nybbles_in_a_devaddr, "0")
  end

  def devaddr_range_json(ranges) do
    Enum.map(ranges, fn {start_addr, end_addr} ->
      %{
        start_addr: devaddr_to_hex_string(start_addr),
        end_addr: devaddr_to_hex_string(end_addr)
      }
    end)
  end

  def region_json(:US915), do: "US915"
  def region_json(:EU868), do: "EU868"
  def region_json(:EU433), do: "EU433"
  def region_json(:CN470), do: "CN470"
  def region_json(:CN779), do: "CN779"
  def region_json(:AU915), do: "AU915"
  def region_json(:AS923_1), do: "AS923_1"
  def region_json(:KR920), do: "KR920"
  def region_json(:IN865), do: "IN865"
  def region_json(:AS923_2), do: "AS923_2"
  def region_json(:AS923_3), do: "AS923_3"
  def region_json(:AS923_4), do: "AS923_4"
  def region_json(:AS923_1B), do: "AS923_1B"
  def region_json(:CD900_1A), do: "CD900_1A"
end
