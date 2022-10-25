defmodule StartOver.Core.OrganizationValidatorTest do
  use ExUnit.Case

  alias StartOver.Core
  alias StartOver.Core.OrganizationValidator

  import StartOver.Fixtures

  describe "OrganizationValidator.validate/1" do
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

    test "returns an error when given an invalid owner wallet id" do
      given =
        valid_core_organization()
        |> Map.put(:owner_wallet_id, nil)

      expected = {:errors, [owner_wallet_id: "wallet ID must be a string"]}

      assert(expected == OrganizationValidator.validate(given))
    end

    test "returns an error when given an invalid payer wallet id" do
      given =
        valid_core_organization()
        |> Map.put(:payer_wallet_id, nil)

      expected = {:errors, [payer_wallet_id: "wallet ID must be a string"]}

      assert(expected == OrganizationValidator.validate(given))
    end

    test "returns an error when :routes is not a list" do
      given =
        valid_core_organization()
        |> Map.put(:routes, :foo)

      expected = {:errors, [routes: "routes must be a list"]}

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
           {:routes,
            {:errors,
             [
               devaddr_ranges:
                 {:error,
                  "start and end addr in {%StartOver.Core.Devaddr{10000001}, %StartOver.Core.Devaddr{0E0000FF}} must have the same NwkID"}
             ]}}
         ]}

      assert(expected == OrganizationValidator.validate(given))
    end

    test "returns :ok when given valid inputs" do
      given = valid_core_organization()
      assert(:ok == OrganizationValidator.validate(given))
    end
  end
end
