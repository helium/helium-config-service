defmodule HeliumConfig.Core.OrganizationTest do
  use ExUnit.Case

  alias HeliumConfig.Core.Devaddr
  alias HeliumConfig.Core.DevaddrRange
  alias HeliumConfig.Core.NetID
  alias HeliumConfig.Core.Organization
  alias HeliumConfig.Core.HttpRoamingOpts
  alias HeliumConfig.Core.RouteServer
  alias HeliumConfig.Core.Route
  alias HeliumConfig.Core.GwmpOpts
  alias HeliumConfig.Core.Crypto

  alias Proto.Helium.Config, as: ConfigProto

  import HeliumConfig.Fixtures

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
                "flow_type" => "sync",
                "path" => "/auth/path"
              }
            },
            "euis" => [
              %{"app_eui" => 100, "dev_eui" => 200}
            ],
            "devaddr_ranges" => [
              %{"start_addr" => "00000001", "end_addr" => "0000001F"}
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
              %{"start_addr" => "00000020", "end_addr" => "0000002F"}
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
                flow_type: :sync,
                path: "/auth/path"
              }
            },
            euis: [
              %{app_eui: 100, dev_eui: 200}
            ],
            devaddr_ranges: [
              {%Devaddr{type: :devaddr_6x25, nwk_id: 0, nwk_addr: 0x1},
               %Devaddr{type: :devaddr_6x25, nwk_id: 0, nwk_addr: 0x1F}}
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
              {%Devaddr{type: :devaddr_6x25, nwk_id: 0, nwk_addr: 0x20},
               %Devaddr{type: :devaddr_6x25, nwk_id: 0, nwk_addr: 0x2F}}
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

  describe "Organization.member?/1" do
    test "returns true given a devaddr within the Organization's devaddr_constraints" do
      range = DevaddrRange.new(:devaddr_6x24, 11, 5, 20)
      devaddr = Devaddr.new(:devaddr_6x24, 11, 6)

      org = %Organization{
        devaddr_constraints: [range]
      }

      assert(true == Organization.member?(org, devaddr))
    end

    test "returns false given a devaddr outside the Organization's devaddr_constraints" do
      range = DevaddrRange.new(:devaddr_6x24, 11, 5, 20)
      devaddr1 = Devaddr.new(:devaddr_6x24, 11, 21)
      devaddr2 = Devaddr.new(:devaddr_6x24, 11, 4)
      devaddr3 = Devaddr.new(:devaddr_6x25, 11, 6)

      org = %Organization{
        devaddr_constraints: [range]
      }

      assert(false == Organization.member?(org, devaddr1))
      assert(false == Organization.member?(org, devaddr2))
      assert(false == Organization.member?(org, devaddr3))
    end
  end

  describe "Organization.routes/2" do
    test "returns the list of the given organization's routes that include the given devaddr" do
      nwk_id = 42
      nwk_id_2 = 88

      range1 = DevaddrRange.new(:devaddr_13x13, nwk_id, 15, 20)
      range2 = DevaddrRange.new(:devaddr_13x13, nwk_id, 50, 60)
      range3 = DevaddrRange.new(:devaddr_6x25, nwk_id_2, 0, 1000)

      devaddr = Devaddr.new(:devaddr_13x13, nwk_id, 16)

      route1 =
        valid_core_route()
        |> Map.put(:net_id, NetID.new(:net_id_contributor, 11, nwk_id))
        |> Map.put(:devaddr_ranges, [range1])

      route2 =
        valid_core_route()
        |> Map.put(:net_id, NetID.new(:net_id_contributor, 11, nwk_id))
        |> Map.put(:devaddr_ranges, [range2, range1])

      route3 =
        valid_core_route()
        |> Map.put(:net_id, NetID.new(:net_id_contributor, 11, nwk_id))
        |> Map.put(:devaddr_ranges, [range2])

      route4 =
        valid_core_route()
        |> Map.put(:net_id, NetID.new(:net_id_sponsor, 12, nwk_id_2))
        |> Map.put(:devaddr_ranges, [range3])

      org = %Organization{
        routes: [route1, route2, route3, route4]
      }

      got = Organization.routes(org, devaddr)

      assert(true == Enum.member?(got, route1))
      assert(true == Enum.member?(got, route2))
      assert(false == Enum.member?(got, route3))
      assert(false == Enum.member?(got, route4))
    end
  end

  describe "Organization.new_roamer/3" do
    test "returns an %Organization{} with Devaddr constraints computed from the given NetID" do
      net_id = NetID.new(:net_id_sponsor, 11, 42)
      %{public: owner_key} = Crypto.generate_key_pair()
      %{public: payer_key} = Crypto.generate_key_pair()

      expected = %Organization{
        oui: nil,
        owner_pubkey: owner_key,
        payer_pubkey: payer_key,
        devaddr_constraints: [
          {
            %Devaddr{type: :devaddr_6x25, nwk_id: 42, nwk_addr: 0},
            %Devaddr{type: :devaddr_6x25, nwk_id: 42, nwk_addr: 0x1FFFFFF}
          }
        ],
        routes: []
      }

      got = Organization.new_roamer(owner_key, payer_key, net_id)

      assert(expected == got)
    end
  end
end
