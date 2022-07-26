defmodule HeliumConfig.DB.OrganizationTest do
  use ExUnit.Case

  alias HeliumConfig.DB.Organization

  describe "changeset/1" do
    test "returns a valid changeset given a Map of valid parameters" do
      route_params = [
        %{
          net_id: 7,
          lns_address: "a.testdomain.com",
          protocol: :http,
          euis: [
            %{app_eui: 1, dev_eui: 2},
            %{app_eui: 3, dev_eui: 4}
          ],
          devaddr_ranges: [
            %{
              start_addr: String.to_integer("00000000", 16),
              end_addr: String.to_integer("000000FF", 16)
            },
            %{
              start_addr: String.to_integer("00000100", 16),
              end_addr: String.to_integer("000001FF", 16)
            }
          ]
        },
        %{
          net_id: 7,
          lns_address: "b.testdomain.com",
          protocol: :gwmp,
          euis: [
            %{app_eui: 5, dev_eui: 6},
            %{app_eui: 7, dev_eui: 8}
          ],
          devaddr_ranges: [
            %{
              start_addr: String.to_integer("00010000", 16),
              end_addr: String.to_integer("000100FF", 16)
            },
            %{
              start_addr: String.to_integer("00020000", 16),
              end_addr: String.to_integer("000200EF", 16)
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

      changeset = Organization.changeset(%Organization{}, org_params)

      assert(true == changeset.valid?)
    end
  end
end
