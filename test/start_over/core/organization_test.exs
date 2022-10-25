defmodule StartOver.Core.OrganizationTest do
  use ExUnit.Case

  alias StartOver.Core.Organization
  alias StartOver.Core.HttpRoamingOpts
  alias StartOver.Core.RouteServer
  alias StartOver.Core.Route
  alias StartOver.Core.GwmpOpts

  describe "Organization.from_web/1" do
    test "returns a properly formed %Organization{} given properly formed json params" do
      json_params = %{
        "oui" => 1,
        "owner_wallet_id" => "the_owners_wallet_id",
        "payer_wallet_id" => "the_payers_wallet_id",
        "routes" => [
          %{
            "net_id" => 7,
            "max_copies" => 2,
            "server" => %{
              "host" => "server1.testdomain.com",
              "port" => 8080,
              "protocol" => %{
                "type" => "http_roaming",
                "dedupe_window" => 1200,
                "auth_header" => "x-helium-auth"
              }
            },
            "euis" => [
              %{"app_eui" => 100, "dev_eui" => 200}
            ],
            "devaddr_ranges" => [
              %{"start_addr" => "0000000000000001", "end_addr" => "000000000000001F"}
            ]
          },
          %{
            "net_id" => 8,
            "max_copies" => 2,
            "server" => %{
              "host" => "server2.testdomain.com",
              "port" => 8080,
              "protocol" => %{
                "type" => "gwmp",
                "mapping" => [
                  %{"region" => "US915", "port" => 5555},
                  %{"region" => "EU433", "port" => 7777}
                ]
              }
            },
            "euis" => [
              %{"app_eui" => 300, "dev_eui" => 400}
            ],
            "devaddr_ranges" => [
              %{"start_addr" => "0000000000000020", "end_addr" => "000000000000002F"}
            ]
          }
        ]
      }

      got = Organization.from_web(json_params)

      expected = %Organization{
        oui: 1,
        owner_wallet_id: "the_owners_wallet_id",
        payer_wallet_id: "the_payers_wallet_id",
        routes: [
          %Route{
            net_id: 7,
            max_copies: 2,
            server: %RouteServer{
              host: "server1.testdomain.com",
              port: 8080,
              protocol_opts: %HttpRoamingOpts{
                dedupe_window: 1200,
                auth_header: "x-helium-auth"
              }
            },
            euis: [
              %{app_eui: 100, dev_eui: 200}
            ],
            devaddr_ranges: [
              {0x1, 0x1F}
            ]
          },
          %Route{
            net_id: 8,
            max_copies: 2,
            server: %RouteServer{
              host: "server2.testdomain.com",
              port: 8080,
              protocol_opts: %GwmpOpts{
                mapping: [
                  {:US915, 5555},
                  {:EU433, 7777}
                ]
              }
            },
            euis: [
              %{app_eui: 300, dev_eui: 400}
            ],
            devaddr_ranges: [
              {0x20, 0x2F}
            ]
          }
        ]
      }

      assert(got == expected)
    end
  end
end
