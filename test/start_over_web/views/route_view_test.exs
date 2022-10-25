defmodule StartOverWeb.Views.RouteViewTest do
  use StartOverWeb.ConnCase, async: true

  alias StartOver.Core
  alias StartOverWeb.RouteView

  import Phoenix.View
  import StartOver.Fixtures

  test "can render an empty list of routes" do
    got = render(RouteView, "routes.json", %{routes: []})
    expected = []
    assert(got == expected)
  end

  test "can render a list of routes" do
    route = valid_http_roaming_route()
    got = render(RouteView, "routes.json", %{routes: [route]})

    expected = [
      %{
        id: "11111111-2222-3333-4444-555555555555",
        oui: 1,
        net_id: "000A80",
        max_copies: 2,
        server: %{
          host: "server1.testdomain.com",
          port: 8888,
          protocol: %{
            type: "http_roaming",
            dedupe_window: 1200,
            auth_header: "x-helium-auth"
          }
        },
        euis: [
          %{
            app_eui: "BEEEEEEEEEEEEEEF",
            dev_eui: "FAAAAAAAAAAAAACE"
          }
        ],
        devaddr_ranges: [
          %{start_addr: "00010000", end_addr: "001F0000"},
          %{start_addr: "00300000", end_addr: "0030001A"}
        ]
      }
    ]

    assert(got == expected)
  end

  test "RouteView.organization_route_json/1 returns a Map properly formatted for an Organization view" do
    route = valid_http_roaming_route()
    got = RouteView.organization_route_json(route)

    # When viewed as part of an Organization, we omit the :oui field.

    expected = %{
      id: "11111111-2222-3333-4444-555555555555",
      net_id: "000A80",
      max_copies: 2,
      server: %{
        host: "server1.testdomain.com",
        port: 8888,
        protocol: %{
          type: "http_roaming",
          dedupe_window: 1200,
          auth_header: "x-helium-auth"
        }
      },
      euis: [
        %{
          app_eui: "BEEEEEEEEEEEEEEF",
          dev_eui: "FAAAAAAAAAAAAACE"
        }
      ],
      devaddr_ranges: [
        %{start_addr: "00010000", end_addr: "001F0000"},
        %{start_addr: "00300000", end_addr: "0030001A"}
      ]
    }

    assert(got == expected)
  end

  test "EUI strings are 16 hex characters wide" do
    got =
      0xFF
      |> RouteView.eui_to_hex_string()
      |> String.length()

    expected = 16

    assert(got == expected)
  end

  test "Devaddr strings are 8 hex characters wide" do
    got =
      0xFFFF
      |> RouteView.devaddr_to_hex_string()
      |> String.length()

    expected = 8

    assert(got == expected)
  end

  test "NetID strings are 6 hex characters wide" do
    got =
      0xFF
      |> RouteView.net_id_json()
      |> String.length()

    expected = 6

    assert(got == expected)
  end

  describe "RouteView.protocol_json/1" do
    test "renders HttpRoamingOpts correctly" do
      opts = %Core.HttpRoamingOpts{
        dedupe_window: 1200,
        auth_header: "x-helium-auth"
      }

      got = RouteView.protocol_json(opts)

      expected = %{
        type: "http_roaming",
        dedupe_window: 1200,
        auth_header: "x-helium-auth"
      }

      assert(got == expected)
    end

    test "renders GwmpOpts correctly" do
      opts = %Core.GwmpOpts{
        mapping: [
          {:US915, 1000},
          {:EU433, 2000},
          {:CN470, 3000},
          {:CD900_1A, 4000}
        ]
      }

      got = RouteView.protocol_json(opts)

      expected = %{
        type: "gwmp",
        mapping: [
          %{region: "US915", port: 1000},
          %{region: "EU433", port: 2000},
          %{region: "CN470", port: 3000},
          %{region: "CD900_1A", port: 4000}
        ]
      }

      assert(got == expected)
    end

    test "renders PacketRouterOpts correctly" do
      got = RouteView.protocol_json(%Core.PacketRouterOpts{})

      expected = %{
        type: "packet_router"
      }

      assert(got == expected)
    end
  end
end
