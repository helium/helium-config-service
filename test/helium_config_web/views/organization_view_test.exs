defmodule HeliumConfigWeb.OrganizationViewTest do
  use ExUnit.Case

  alias HeliumConfig.Core.Organization
  alias HeliumConfigWeb.OrganizationView

  test "organization_json/1 renders all of the required fields from an Organization" do
    org =
      %{
        oui: 1,
        owner_wallet_id: "owner",
        payer_wallet_id: "payer",
        routes: [
          %{
            net_id: 7,
            lns_address: "lns1.testdomain.com",
            protocol: :http,
            euis: ["eui1"],
            devaddr_ranges: [{0, 10}, {15, 20}]
          }
        ]
      }
      |> Organization.new()

    assert(
      %{
        oui: 1,
        owner_wallet_id: "owner",
        payer_wallet_id: "payer",
        routes: [
          %{
            net_id: 7,
            lns_address: "lns1.testdomain.com",
            protocol: "http",
            euis: ["eui1"],
            devaddr_ranges: [
              %{
                start_addr: "00000000",
                end_addr: "0000000A"
              },
              %{
                start_addr: "0000000F",
                end_addr: "00000014"
              }
            ]
          }
        ]
      } == OrganizationView.organization_json(org)
    )
  end
end
