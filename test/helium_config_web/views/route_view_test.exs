defmodule HeliumConfigWeb.RouteViewTest do
  use ExUnit.Case

  alias HeliumConfig.Core.Route
  alias HeliumConfigWeb.RouteView

  test "route_json/1 returns all of the required fields from a Route" do
    route = %Route{
      net_id: 7,
      lns_address: "lns1.testdomain.com",
      protocol: :gwmp,
      euis: ["eui1"],
      devaddr_ranges: [
        {1, 5},
        {6, 10}
      ]
    }

    assert(
      %{
        net_id: 7,
        lns_address: "lns1.testdomain.com",
        protocol: "gwmp",
        euis: ["eui1"],
        devaddr_ranges: [
          %{
            start_addr: "00000001",
            end_addr: "00000005"
          },
          %{
            start_addr: "00000006",
            end_addr: "0000000A"
          }
        ]
      } = RouteView.route_json(route)
    )
  end

  test "devaddr_hex_string/1 returns a 8-digit, 0-padded hex string" do
    assert("00000001" == RouteView.devaddr_hex_string(1))
    assert("0000000F" == RouteView.devaddr_hex_string(15))
    assert("FFFFFFFF" == RouteView.devaddr_hex_string(0xFFFFFFFF))
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
