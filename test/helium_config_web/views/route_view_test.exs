defmodule HeliumConfigWeb.RouteViewTest do
  use ExUnit.Case

  alias HeliumConfig.Core.Route, as: CoreRoute
  alias HeliumConfigWeb.RouteView

  test "route_json/1 returns all of the required fields from a Route" do
    core_route =
      CoreRoute.new(%{
        net_id: 7,
        lns_address: "lns1.testdomain.com",
        protocol: :gwmp,
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
end
