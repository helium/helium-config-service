defmodule HeliumConfig.Core.OrganizationTest do
  use ExUnit.Case

  alias HeliumConfig.Core.Organization
  alias HeliumConfig.Core.HttpRoamingOpts
  alias HeliumConfig.Core.RouteServer
  alias HeliumConfig.Core.Route
  alias HeliumConfig.Core.GwmpOpts
  alias HeliumConfig.Core.Crypto

  alias Proto.Helium.Config, as: ConfigProto

  describe "Organization.from_web/1" do
    test "returns a properly formed %Organization{} given properly formed json params" do
      %{public: owner_pubkey} = Crypto.generate_key_pair()
      owner_b58 = Crypto.pubkey_to_b58(owner_pubkey)

      %{public: payer_pubkey} = Crypto.generate_key_pair()
      payer_b58 = Crypto.pubkey_to_b58(payer_pubkey)

      json_params = %{
        "oui" => 1,
        "owner_pubkey" => owner_b58,
        "payer_pubkey" => payer_b58,
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
        owner_pubkey: owner_pubkey,
        payer_pubkey: payer_pubkey,
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

  describe "Organization.from_proto/1" do
    test "returns a properly formed %Organization{} given a properly formed OrgV1" do
      big_oui = 0xFFFFFFFF_FFFFFFFF
      %{public: owner_pubkey} = Crypto.generate_key_pair()
      owner_pubkey_bin = Crypto.pubkey_to_bin(owner_pubkey)

      %{public: payer_pubkey} = Crypto.generate_key_pair()
      payer_pubkey_bin = Crypto.pubkey_to_bin(payer_pubkey)

      proto_org =
        ConfigProto.OrgV1.new(%{
          oui: big_oui,
          owner: owner_pubkey_bin,
          payer: payer_pubkey_bin
        })

      proto_org_bin = ConfigProto.OrgV1.encode(proto_org)

      got =
        proto_org_bin
        |> ConfigProto.OrgV1.decode()
        |> Organization.from_proto()

      expected = %Organization{
        oui: big_oui,
        owner_pubkey: owner_pubkey,
        payer_pubkey: payer_pubkey
      }

      assert(expected == got)
    end
  end
end
