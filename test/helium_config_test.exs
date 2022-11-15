defmodule HeliumConfigTest do
  use HeliumConfig.DataCase

  import HeliumConfig.Fixtures

  alias HeliumConfig.DB
  alias HeliumConfig.Core

  describe "HeliumConfig.list_routes_for_organization/1" do
    test "returns a list of %Core.Route{} when records exist for the given OUI" do
      org = create_valid_organization()
      result = HeliumConfig.list_routes_for_organization(org.oui)
      assert([%Core.Route{}, %Core.Route{}, %Core.Route{}] = result)
    end
  end

  describe "HeliumConfig.create_roamer_organization!/3" do
    test "returns an Organization given valid public keys and a net ID" do
      owner = Core.Crypto.generate_key_pair()
      payer = Core.Crypto.generate_key_pair()
      net_id = Core.NetID.new(:net_id_sponsor, 11, 42)

      got = HeliumConfig.create_roamer_organization(owner.public, payer.public, net_id)
      got_minus_oui = Map.put(got, :oui, nil)

      expected = %Core.Organization{
        oui: nil,
        owner_pubkey: owner.public,
        payer_pubkey: payer.public,
        routes: []
      }

      assert(expected == got_minus_oui)
      assert(got.oui != nil)
    end
  end

  defp create_valid_organization do
    valid_org = valid_core_organization()

    %DB.Organization{}
    |> DB.Organization.changeset(valid_org)
    |> Repo.insert!(returning: true)
  end
end
