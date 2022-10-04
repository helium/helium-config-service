defmodule HeliumConfig.HeliumConfigTest do
  use HeliumConfig.DataCase

  alias HeliumConfig.Core
  alias HeliumConfig.DB
  alias HeliumConfig.Repo

  describe "insert_organization/1" do
    test "returns :ok on a successful save" do
      core_org = valid_org()
      assert(:ok == HeliumConfig.insert_organization(core_org))
    end

    test "inserts a record into the database on successful save" do
      core_org = valid_org()

      assert(nil == Repo.get(DB.Organization, 5))

      :ok = HeliumConfig.insert_organization(core_org)

      got = Repo.get(DB.Organization, 5)

      assert(%DB.Organization{oui: 5} = got)
    end
  end

  describe "save_organization/1" do
    test "returns :ok on successful save" do
      core_org = valid_org()
      assert(nil == Repo.get(DB.Organization, core_org.oui))
      assert(:ok == HeliumConfig.save_organization(core_org))
    end

    test "creates new records if none exist" do
      core_org = valid_org()
      assert([] == Repo.all(DB.Organization))
      assert([] == Repo.all(DB.Route))
      assert([] == Repo.all(DB.DevaddrRange))

      assert(:ok == HeliumConfig.save_organization(core_org))

      assert([_one_org] = Repo.all(DB.Organization))
      assert([_one_route] = Repo.all(DB.Route))
      assert([_one_range] = Repo.all(DB.DevaddrRange))
    end

    test "removes devaddr_ranges not present in the saved struct" do
      org = valid_org()
      assert(nil == Repo.get(DB.Organization, org.oui))
      assert(:ok == HeliumConfig.save_organization(org))
      assert([_one_thing] = Repo.all(DB.DevaddrRange))

      %Core.Organization{routes: [route1]} = org
      org2 = %Core.Organization{org | routes: [%Core.Route{route1 | devaddr_ranges: []}]}

      assert(:ok == HeliumConfig.save_organization(org2))

      assert([] == Repo.all(DB.DevaddrRange))
    end

    test "removes routes not present in the saved struct" do
      org = valid_org()
      assert(nil == Repo.get(DB.Organization, org.oui))
      assert(:ok == HeliumConfig.save_organization(org))
      assert([_one_route] = Repo.all(DB.Route))

      org2 = %Core.Organization{org | routes: []}

      assert(:ok == HeliumConfig.save_organization(org2))
      assert([] == Repo.all(DB.Route))
    end
  end

  describe "delete_organization/1" do
    test "deletes organization records given a Core.Organization" do
      core_org = valid_org()
      :ok = HeliumConfig.save_organization(core_org)
      assert([_one_org] = Repo.all(DB.Organization))

      :ok = HeliumConfig.delete_organization(core_org)

      assert([] == Repo.all(DB.Organization))
      assert([] == Repo.all(DB.Route))
      assert([] == Repo.all(DB.DevaddrRange))
    end

    test "deletes organization records given an integer OUI" do
      core_org = valid_org()
      :ok = HeliumConfig.save_organization(core_org)
      assert([_one_org] = Repo.all(DB.Organization))

      :ok = HeliumConfig.delete_organization(core_org.oui)
      assert([] == Repo.all(DB.Organization))
      assert([] == Repo.all(DB.Route))
      assert([] == Repo.all(DB.DevaddrRange))
      assert([] == Repo.all(DB.Lns))
    end
  end

  defp valid_org do
    Core.Organization.new(%{
      oui: 5,
      owner_wallet_id: "TheOwnersWalletID",
      payer_wallet_id: "ThePayersWalletID",
      routes: [
        %{
          net_id: 7,
          lns: %Core.HttpRoamingLns{
            host: "route1.testdomain.com",
            port: 8000,
            dedupe_window: 1200,
            auth_header: "x-helium-auth"
          },
          euis: [
            %{
              dev_eui: 100,
              app_eui: 200
            }
          ],
          devaddr_ranges: [
            {1, 100}
          ]
        }
      ]
    })
  end
end
