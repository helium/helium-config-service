defmodule HeliumConfig.Core.OrganizationTest do
  use HeliumConfig.DataCase

  alias HeliumConfig.Core.GwmpLns
  alias HeliumConfig.Core.HttpRoamingLns
  alias HeliumConfig.Core.Organization
  alias HeliumConfig.Core.Route
  alias HeliumConfig.DB.Organization, as: DBOrg

  test "new/1 returns a struct with the expected fields" do
    expected =
      MapSet.new([
        :oui,
        :owner_wallet_id,
        :payer_wallet_id,
        :routes
      ])

    got_struct = Organization.new()

    got =
      got_struct
      |> Map.from_struct()
      |> Map.keys()
      |> MapSet.new()

    assert(got == expected)
    assert(is_list(got_struct.routes))
  end

  test "from_db/1 correctly converts a valid DB.Organization to a Core.Organization" do
    range1_start = String.to_integer("00000000", 16)
    range1_end = String.to_integer("00000100", 16)

    range2_start = String.to_integer("00000100", 16)
    range2_end = String.to_integer("000001FF", 16)

    range3_start = String.to_integer("00000200", 16)
    range3_end = String.to_integer("000002FF", 16)

    range4_start = String.to_integer("00000300", 16)
    range4_end = String.to_integer("000003FF", 16)

    route_params = [
      %{
        net_id: 7,
        lns: %HttpRoamingLns{
          host: "a.testdomain.com",
          port: 8080,
          dedupe_window: 1200,
          auth_header: "x-helium-auth"
        },
        euis: [
          %{app_eui: 1, dev_eui: 2},
          %{app_eui: 3, dev_eui: 4}
        ],
        devaddr_ranges: [
          %{
            start_addr: range1_start,
            end_addr: range1_end
          },
          %{
            start_addr: range2_start,
            end_addr: range2_end
          }
        ]
      },
      %{
        net_id: 7,
        lns: %GwmpLns{
          host: "b.testdomain.com",
          port: 1234
        },
        euis: [
          %{app_eui: 5, dev_eui: 6},
          %{app_eui: 7, dev_eui: 8}
        ],
        devaddr_ranges: [
          %{
            start_addr: range3_start,
            end_addr: range3_end
          },
          %{
            start_addr: range4_start,
            end_addr: range4_end
          }
        ]
      }
    ]

    org_params = %{
      oui: 1,
      owner_wallet_id: "owner_wallet_id_ASDFASDFASDF",
      payer_wallet_id: "payer_wallet_id_ASQWERQERTQWERQWER",
      routes: route_params
    }

    changeset = DBOrg.changeset(%DBOrg{}, org_params)

    assert(true == changeset.valid?)

    got =
      changeset
      |> Ecto.Changeset.apply_changes()
      |> Organization.from_db()

    expected = %Organization{
      oui: 1,
      owner_wallet_id: "owner_wallet_id_ASDFASDFASDF",
      payer_wallet_id: "payer_wallet_id_ASQWERQERTQWERQWER",
      routes: [
        %Route{
          net_id: 7,
          lns: %HttpRoamingLns{
            host: "a.testdomain.com",
            port: 8080,
            dedupe_window: 1200,
            auth_header: "x-helium-auth"
          },
          euis: [
            %{app_eui: 1, dev_eui: 2},
            %{app_eui: 3, dev_eui: 4}
          ],
          devaddr_ranges: [
            {range1_start, range1_end},
            {range2_start, range2_end}
          ]
        },
        %Route{
          net_id: 7,
          lns: %GwmpLns{
            host: "b.testdomain.com",
            port: 1234
          },
          euis: [
            %{app_eui: 5, dev_eui: 6},
            %{app_eui: 7, dev_eui: 8}
          ],
          devaddr_ranges: [
            {range3_start, range3_end},
            {range4_start, range4_end}
          ]
        }
      ]
    }

    assert(got == expected)
  end
end
