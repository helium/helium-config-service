defmodule HeliumConfig.Core.OrganizationValidatorTest do
  use ExUnit.Case

  alias HeliumConfig.Core
  alias HeliumConfig.Core.OrganizationValidator

  import HeliumConfig.Fixtures

  describe "OrganizationValidator.validate/1" do
    test "returns an error when given a Route outside the Organization's devaddr_constraints" do
      net_id = Core.NetID.new(:net_id_contributor, 11, 42)
      constraint = Core.DevaddrRange.from_net_id(net_id)

      bad_range = Core.DevaddrRange.new(:devaddr_13x13, 12, 10, 20)

      bad_route =
        valid_core_route()
        |> Map.put(:devaddr_ranges, [bad_range])

      org =
        valid_core_organization()
        |> Map.put(:devaddr_constraints, [constraint])
        |> Map.put(:routes, [bad_route])

      got = OrganizationValidator.validate(org)

      assert({:errors, [routes: route_errors]} = got)

      assert(
        [
          "start addr in {%HeliumConfig.Core.Devaddr{F801800A}, %HeliumConfig.Core.Devaddr{F8018014}} must have the same NwkID as %HeliumConfig.Core.NetID{000A80}"
        ] == route_errors
      )
    end

    test "returns an error when given an OUI that is not an integer" do
      given =
        valid_core_organization()
        |> Map.put(:oui, "eeeergh_wrong")

      expected = {:errors, [oui: "oui must be a positive unsigned integer"]}

      assert(expected == OrganizationValidator.validate(given))
    end

    test "returns an error when given an OUI that is a negative number" do
      given =
        valid_core_organization()
        |> Map.put(:oui, -1)

      expected = {:errors, [oui: "oui must be a positive unsigned integer"]}

      assert(expected == OrganizationValidator.validate(given))
    end

    test "returns an error when given an invalid owner pubkey" do
      given =
        valid_core_organization()
        |> Map.put(:owner_pubkey, nil)

      expected = {:errors, [owner_pubkey: "pubkey must be type :ecc_compact or :ed25519"]}

      assert(expected == OrganizationValidator.validate(given))
    end

    test "returns an error when given an invalid payer pubkey" do
      given =
        valid_core_organization()
        |> Map.put(:payer_pubkey, nil)

      expected = {:errors, [payer_pubkey: "pubkey must be type :ecc_compact or :ed25519"]}

      assert(expected == OrganizationValidator.validate(given))
    end

    test "returns an error when :routes is not a list" do
      given =
        valid_core_organization()
        |> Map.put(:routes, :foo)

      expected = {:errors, [routes: "routes must be a list or nil"]}

      assert(expected == OrganizationValidator.validate(given))
    end

    test "returns an error when :routes contains an invalid route" do
      nwk_id = 7
      net_id = Core.NetID.new(:net_id_sponsor, 42, nwk_id)
      net_id_bin = Core.NetID.to_integer(net_id)

      invalid_start = Core.Devaddr.new(:devaddr_6x25, nwk_id + 1, 1)
      invalid_bin = Core.Devaddr.to_integer(invalid_start)

      valid_end = Core.Devaddr.new(:devaddr_6x25, nwk_id, 255)
      valid_bin = Core.Devaddr.to_integer(valid_end)

      given =
        valid_core_organization()
        |> Map.put(:routes, [
          %Core.Route{
            oui: 1,
            net_id: net_id_bin,
            max_copies: 5,
            server: %Core.RouteServer{
              host: "server1.testdomain.com",
              port: 8888,
              protocol_opts: %Core.PacketRouterOpts{}
            },
            devaddr_ranges: [
              {invalid_bin, valid_bin}
            ],
            euis: [
              %{app_eui: valid_app_eui_integer(), dev_eui: valid_dev_eui_integer()}
            ]
          }
        ])

      expected =
        {:errors,
         [
           routes: [
             devaddr_ranges:
               "start and end addr in {%HeliumConfig.Core.Devaddr{10000001}, %HeliumConfig.Core.Devaddr{0E0000FF}} must have the same NwkID"
           ]
         ]}

      assert(expected == OrganizationValidator.validate(given))
    end

    test "returns :ok when given valid inputs" do
      given = valid_core_organization()
      assert(:ok == OrganizationValidator.validate(given))
    end
  end
end
