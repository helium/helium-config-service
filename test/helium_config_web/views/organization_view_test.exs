defmodule HeliumConfigWeb.OrganizationViewTest do
  use ExUnit.Case

  alias HeliumConfig.Core
  alias HeliumConfigWeb.OrganizationView

  import HeliumConfig.Fixtures

  describe "organization_json/1" do
    test "returns a correct rendering of a Core.Organiztion" do
      %{public: owner_pubkey} = Core.Crypto.generate_key_pair()
      owner_b58 = Core.Crypto.pubkey_to_b58(owner_pubkey)

      %{public: payer_pubkey} = Core.Crypto.generate_key_pair()
      payer_b58 = Core.Crypto.pubkey_to_b58(payer_pubkey)

      valid_org = valid_core_organization(owner_pubkey: owner_pubkey, payer_pubkey: payer_pubkey)
      got = OrganizationView.organization_json(valid_org)

      expected = %{
        oui: 1,
        owner_pubkey: owner_b58,
        payer_pubkey: payer_b58,
        routes: [
          %{
            id: "11111111-2222-3333-4444-555555555555",
            devaddr_ranges: [
              %{end_addr: "001F0000", start_addr: "00010000"},
              %{end_addr: "0030001A", start_addr: "00300000"}
            ],
            euis: [
              %{
                app_eui: "BEEEEEEEEEEEEEEF",
                dev_eui: "FAAAAAAAAAAAAACE"
              }
            ],
            net_id: "000A80",
            max_copies: 2,
            server: %{
              host: "server1.testdomain.com",
              port: 8888,
              protocol: %{
                type: "http_roaming",
                dedupe_window: 1200,
                flow_type: "async",
                path: "/helium"
              }
            }
          },
          %{
            id: "22222222-2222-3333-4444-555555555555",
            devaddr_ranges: [
              %{end_addr: "001F0000", start_addr: "00010000"},
              %{end_addr: "0030001A", start_addr: "00300000"}
            ],
            euis: [
              %{
                app_eui: "BEEEEEEEEEEEEEEF",
                dev_eui: "FAAAAAAAAAAAAACE"
              }
            ],
            net_id: "000A80",
            max_copies: 2,
            server: %{
              host: "server1.testdomain.com",
              port: 8888,
              protocol: %{
                mapping: [
                  %{port: 1000, region: "US915"},
                  %{port: 1001, region: "EU868"},
                  %{port: 1002, region: "EU433"},
                  %{port: 1003, region: "CN470"},
                  %{port: 1004, region: "CN779"},
                  %{port: 1005, region: "AU915"},
                  %{port: 1006, region: "AS923_1"},
                  %{port: 1007, region: "KR920"},
                  %{port: 1008, region: "IN865"},
                  %{port: 1009, region: "AS923_2"},
                  %{port: 10010, region: "AS923_3"},
                  %{port: 10011, region: "AS923_4"},
                  %{port: 10012, region: "AS923_1B"},
                  %{port: 10013, region: "CD900_1A"}
                ],
                type: "gwmp"
              }
            }
          },
          %{
            id: "33333333-2222-3333-4444-555555555555",
            devaddr_ranges: [
              %{start_addr: "00010000", end_addr: "001F0000"},
              %{start_addr: "00300000", end_addr: "0030001A"}
            ],
            euis: [
              %{
                app_eui: "BEEEEEEEEEEEEEEF",
                dev_eui: "FAAAAAAAAAAAAACE"
              }
            ],
            net_id: "000A80",
            max_copies: 2,
            server: %{
              host: "server1.testdomain.com",
              port: 8888,
              protocol: %{type: "packet_router"}
            }
          }
        ]
      }

      assert(expected == got)
    end
  end
end
