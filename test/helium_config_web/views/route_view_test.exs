defmodule HeliumConfigWeb.RouteViewTest do
  use ExUnit.Case

  alias HeliumConfig.Core.GwmpLns
  alias HeliumConfig.Core.HeliumRouterLns
  alias HeliumConfig.Core.HttpRoamingLns
  alias HeliumConfig.Core.Route, as: CoreRoute
  alias HeliumConfigWeb.RouteView

  test "route_json/1 returns all of the required fields from a Route" do
    core_route =
      CoreRoute.new(%{
        net_id: 7,
        lns: %HttpRoamingLns{
          host: "lns1.testdomain.com",
          port: 8080,
          dedupe_window: 1000,
          auth_header: "x-helium-auth"
        },
        euis: [%{app_eui: 1, dev_eui: 2}],
        devaddr_ranges: [
          {1, 5},
          {6, 10}
        ]
      })

    json_params = RouteView.route_json(core_route)
    json = Jason.encode!(json_params)

    decoded =
      json
      |> Jason.decode!()
      |> CoreRoute.from_web()

    assert(decoded == core_route)
  end

  test "devaddr_to_hex_string/1 returns a 8-digit, 0-padded hex string" do
    assert("00000001" == RouteView.devaddr_to_hex_string(1))
    assert("0000000F" == RouteView.devaddr_to_hex_string(15))
    assert("FFFFFFFF" == RouteView.devaddr_to_hex_string(0xFFFFFFFF))
  end

  describe "devaddr_range_json/1" do
    test "returns a map of %{start_addr: _, end_addr: _}" do
      assert(%{start_addr: _, end_addr: _} = RouteView.devaddr_range_json({1, 15}))
    end

    test "returns start and end values as hex strings" do
      assert(
        %{start_addr: "00000001", end_addr: "0000000F"} = RouteView.devaddr_range_json({1, 15})
      )
    end
  end

  describe "lns_json/1" do
    test "returns the correct rendering of an HttpRoamingLns" do
      expected = %{
        type: "http_roaming",
        host: "lns1.testdomain.com",
        port: 8080,
        dedupe_window: 5000,
        auth_header: "x-helium-auth"
      }

      given = %HttpRoamingLns{
        host: "lns1.testdomain.com",
        port: 8080,
        dedupe_window: 5000,
        auth_header: "x-helium-auth"
      }

      assert(expected == RouteView.lns_json(given))
    end

    test "returns the correct rendering of a GwmpLns" do
      expected = %{
        type: "gwmp",
        host: "lns2.testdomain.com",
        port: 5555
      }

      given = %GwmpLns{
        host: "lns2.testdomain.com",
        port: 5555
      }

      assert(expected == RouteView.lns_json(given))
    end

    test "returns the correct rendering of a HeliumRouterLns" do
      expected = %{
        type: "helium_router",
        host: "router.helium.com",
        port: 4000
      }

      given = %HeliumRouterLns{
        host: "router.helium.com",
        port: 4000
      }

      assert(expected == RouteView.lns_json(given))
    end
  end
end
