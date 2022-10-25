defmodule StartOver.DBTest do
  use StartOver.DataCase, async: false

  alias StartOver.DB
  alias StartOver.Core

  import StartOver.Fixtures

  ##
  ## Routes
  ##

  describe "DB.list_routes/0" do
    test "returns an empty list when no route records exist" do
      assert [] == DB.list_routes()
    end

    test "returns a %DB.Route{} when a route record exists" do
      db_org = create_valid_organization()
      assert length(db_org.routes) > 0
      assert Enum.sort(db_org.routes) == Enum.sort(DB.list_routes())
    end
  end

  describe "DB.get_route!/1" do
    test "raises an exception if no record exists for the given ID" do
      assert_raise Ecto.NoResultsError, fn ->
        some_uuid = Ecto.UUID.generate()
        DB.get_route!(some_uuid)
      end
    end

    test "returns a %DB.Route{} if a record exists for the given ID" do
      db_org = create_valid_organization()
      expected_route = hd(db_org.routes)

      got = DB.get_route!(expected_route.id)

      assert expected_route == got
    end
  end

  describe "DB.create_route!/1" do
    test "returns a %DB.Route{} given valid inputs" do
      valid_org = create_valid_organization()

      new_core_route = %Core.Route{
        oui: valid_org.oui,
        net_id: 11,
        max_copies: 2,
        server: %Core.RouteServer{
          host: "newserver.testdomain.com",
          port: 4567,
          protocol_opts: %Core.HttpRoamingOpts{
            dedupe_window: 1200,
            auth_header: "x-helium-auth"
          }
        },
        devaddr_ranges: [
          {0x1000_0000, 0x1000_FFFF}
        ],
        euis: [
          %{
            app_eui: 0x10000000_00000000,
            dev_eui: 0x20000000_00000000
          }
        ]
      }

      got = DB.create_route!(new_core_route)

      assert %DB.Route{} = got
    end

    test "raises InvalidChangesetError if the inputs refer to a non-existant Organization" do
      assert [] == Repo.all(DB.Organization)

      new_core_route = %Core.Route{
        oui: 99,
        net_id: 11,
        max_copies: 2,
        server: %Core.RouteServer{
          host: "newserver.testdomain.com",
          port: 4567,
          protocol_opts: %Core.HttpRoamingOpts{
            dedupe_window: 1200,
            auth_header: "x-helium-auth"
          }
        },
        devaddr_ranges: [
          {0x1000_0000, 0x1000_FFFF}
        ],
        euis: [
          %{
            app_eui: 0x10000000_00000000,
            dev_eui: 0x20000000_00000000
          }
        ]
      }

      assert_raise Ecto.InvalidChangesetError, fn ->
        DB.create_route!(new_core_route)
      end
    end

    test "raises ConstraintError if a record with the given ID already exists" do
      valid_org = create_valid_organization()

      valid_route_id =
        valid_org
        |> Map.get(:routes)
        |> hd()
        |> Map.get(:id)

      new_core_route = %Core.Route{
        id: valid_route_id,
        oui: valid_org.oui,
        net_id: 11,
        max_copies: 2,
        server: %Core.RouteServer{
          host: "newserver.testdomain.com",
          port: 4567,
          protocol_opts: %Core.HttpRoamingOpts{
            dedupe_window: 1200,
            auth_header: "x-helium-auth"
          }
        },
        devaddr_ranges: [
          {0x1000_0000, 0x1000_FFFF}
        ],
        euis: [
          %{
            app_eui: 0x10000000_00000000,
            dev_eui: 0x20000000_00000000
          }
        ]
      }

      assert_raise Ecto.ConstraintError, fn ->
        DB.create_route!(new_core_route)
      end
    end
  end

  describe "DB.update_route!/1" do
    test "returns a %DB.Route{} given valid inputs" do
      valid_org = create_valid_organization()
      existing_db_route = hd(valid_org.routes)

      updated_core_route = %Core.Route{
        id: existing_db_route.id,
        oui: valid_org.oui,
        net_id: 11,
        max_copies: 2,
        server: %Core.RouteServer{
          host: "newserver.testdomain.com",
          port: 4567,
          protocol_opts: %Core.HttpRoamingOpts{
            dedupe_window: 1200,
            auth_header: "x-helium-auth"
          }
        },
        devaddr_ranges: [
          {0x1000_0000, 0x1000_FFFF}
        ],
        euis: [
          %{
            app_eui: 0x10000000_00000000,
            dev_eui: 0x20000000_00000000
          }
        ]
      }

      got =
        updated_core_route
        |> DB.update_route!()
        |> Core.Route.from_db()

      assert updated_core_route == got
    end

    test "raises Ecto.InvalidChangesetError given a valid ID and invalid OUI" do
      valid_org = create_valid_organization()
      existing_db_route = hd(valid_org.routes)

      updated_core_route = %Core.Route{
        id: existing_db_route.id,
        oui: 666,
        net_id: 11,
        max_copies: 2,
        server: %Core.RouteServer{
          host: "newserver.testdomain.com",
          port: 4567,
          protocol_opts: %Core.HttpRoamingOpts{
            dedupe_window: 1200,
            auth_header: "x-helium-auth"
          }
        },
        devaddr_ranges: [
          {0x1000_0000, 0x1000_FFFF}
        ],
        euis: [
          %{
            app_eui: 0x10000000_00000000,
            dev_eui: 0x20000000_00000000
          }
        ]
      }

      assert_raise Ecto.InvalidChangesetError, fn ->
        DB.update_route!(updated_core_route)
      end
    end

    test "raises Ecto.NoResultsError given an invalid ID" do
      valid_org = create_valid_organization()

      non_existant_uuid = Ecto.UUID.generate()

      updated_core_route = %Core.Route{
        id: non_existant_uuid,
        oui: valid_org.oui,
        net_id: 11,
        max_copies: 2,
        server: %Core.RouteServer{
          host: "newserver.testdomain.com",
          port: 4567,
          protocol_opts: %Core.HttpRoamingOpts{
            dedupe_window: 1200,
            auth_header: "x-helium-auth"
          }
        },
        devaddr_ranges: [
          {0x1000_0000, 0x1000_FFFF}
        ],
        euis: [
          %{
            app_eui: 0x10000000_00000000,
            dev_eui: 0x20000000_00000000
          }
        ]
      }

      assert_raise Ecto.NoResultsError, fn ->
        DB.update_route!(updated_core_route)
      end
    end
  end

  ##
  ## Organizations
  ##

  describe "DB.list_organizations/1" do
    test "returns an empty list when no organizations records exist" do
      assert [] == Repo.all(DB.Organization)
      assert [] == DB.list_organizations()
    end

    test "returns a list of %DB.Organization{} when records exist" do
      assert [] == Repo.all(DB.Organization)
      valid_org = valid_core_organization()

      expected_org =
        %DB.Organization{}
        |> DB.Organization.changeset(valid_org)
        |> Repo.insert!()
        |> Repo.preload([:routes, routes: [:server, :devaddr_ranges, :euis]])

      assert [expected_org] == DB.list_organizations()
    end
  end

  describe "DB.create_organization!/1" do
    test "inserts database records given a valid Core.Organization" do
      assert(organization_tables_empty())

      valid_org = valid_core_organization()
      assert(%DB.Organization{} = DB.create_organization!(valid_org))

      assert(1 == length(Repo.all(DB.Organization)))
      assert(3 == length(Repo.all(DB.Route)))
      assert(3 == length(Repo.all(DB.EuiPair)))
      assert(6 == length(Repo.all(DB.DevaddrRange)))
      assert(3 == length(Repo.all(DB.RouteServer)))
    end

    test "raises ConstraintError if the organization record already exists" do
      valid_core_org = valid_core_organization()

      %DB.Organization{}
      |> DB.Organization.changeset(valid_core_org)
      |> Repo.insert!()

      assert_raise Ecto.ConstraintError, fn ->
        DB.create_organization!(valid_core_org)
      end
    end
  end

  describe "DB.get_organization!/1" do
    test "returns a DB.Organization with fields correctly preloaded when a record exists with the given OUI" do
      valid_org = valid_core_organization()
      DB.create_organization!(valid_org)

      assert(
        %DB.Organization{
          routes: [
            %DB.Route{
              server: %DB.RouteServer{},
              euis: [
                %DB.EuiPair{}
              ],
              devaddr_ranges: [
                %DB.DevaddrRange{},
                %DB.DevaddrRange{}
              ]
            },
            %DB.Route{
              server: %DB.RouteServer{},
              euis: [
                %DB.EuiPair{}
              ],
              devaddr_ranges: [
                %DB.DevaddrRange{},
                %DB.DevaddrRange{}
              ]
            },
            %DB.Route{
              server: %DB.RouteServer{},
              euis: [
                %DB.EuiPair{}
              ],
              devaddr_ranges: [
                %DB.DevaddrRange{},
                %DB.DevaddrRange{}
              ]
            }
          ]
        } = DB.get_organization!(valid_org.oui)
      )
    end

    test "raises NoResultsError when no record exists with the given OUI" do
      assert [] == Repo.all(DB.Organization)

      assert_raise Ecto.NoResultsError, fn ->
        DB.get_organization!(1)
      end
    end
  end

  describe "DB.update_organization!/1" do
    test "returns a DB.Organization when inputs are valid" do
      valid_db_org = create_valid_organization()
      valid_core_org = Core.Organization.from_db(valid_db_org)

      updated_core_org =
        valid_core_org
        |> Map.put(:owner_wallet_id, "updated_owner_wallet")
        |> Map.put(:payer_wallet_id, "updated_payer_wallet")

      updated_db_org = DB.update_organization!(updated_core_org)

      got = Core.Organization.from_db(updated_db_org)

      assert updated_core_org == got
    end

    test "returns a DB.Organization when no record exists" do
      assert [] == Repo.all(DB.Organization)
      valid_core_org = valid_core_organization()
      assert %DB.Organization{} = DB.update_organization!(valid_core_org)
    end
  end

  describe "DB.delete_organization!/1" do
    test "removes records from all relations" do
      assert(organization_tables_empty())
      valid_org = valid_core_organization()
      assert %DB.Organization{} = DB.create_organization!(valid_org)

      assert(1 == length(Repo.all(DB.Organization)))
      assert(3 == length(Repo.all(DB.Route)))
      assert(3 == length(Repo.all(DB.EuiPair)))
      assert(6 == length(Repo.all(DB.DevaddrRange)))
      assert(3 == length(Repo.all(DB.RouteServer)))

      :ok = DB.delete_organization!(valid_org.oui)

      assert(organization_tables_empty())
    end

    test "raises NoResultsError when no record with the given OUI exists" do
      assert [] == Repo.all(DB.Organization)

      assert_raise Ecto.NoResultsError, fn ->
        DB.delete_organization!(666)
      end
    end
  end

  ##
  ## Private Functions
  ##

  defp organization_tables_empty do
    [] == Repo.all(DB.Organization) &&
      [] == Repo.all(DB.Route) &&
      [] == Repo.all(DB.EuiPair) &&
      [] == Repo.all(DB.DevaddrRange) &&
      [] == Repo.all(DB.RouteServer)
  end

  defp create_valid_organization do
    valid_org = valid_core_organization()

    %DB.Organization{}
    |> DB.Organization.changeset(valid_org)
    |> Repo.insert!()
  end
end
