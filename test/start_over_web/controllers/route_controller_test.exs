defmodule StartOverWeb.RouteControllerTest do
  use StartOverWeb.ConnCase

  alias StartOver.Core
  alias StartOver.DB
  alias StartOver.Repo
  alias StartOverWeb.RouteView

  import StartOver.Fixtures

  describe "index" do
    test "returns an empty list when no routes exist", %{conn: conn} do
      conn = get(conn, Routes.route_path(conn, :index))
      assert json_response(conn, 200) == []
    end

    test "returns routes when routes exist", %{conn: conn} do
      core_org = valid_core_organization()
      DB.create_organization!(core_org)

      conn = get(conn, Routes.route_path(conn, :index))
      assert [_one, _two, _three] = json_response(conn, 200)
    end
  end

  describe "show" do
    test "returns 404 when the given route ID does not exist", %{conn: conn} do
      assert [] == Repo.all(DB.Route)

      some_uuid = Ecto.UUID.generate()

      assert_error_sent 404, fn ->
        get(conn, Routes.route_path(conn, :show, some_uuid))
      end
    end

    test "returns a route when a record exists for the given route ID", %{conn: conn} do
      core_org = valid_core_organization()
      org = DB.create_organization!(core_org)

      a_route = hd(org.routes)

      conn = get(conn, Routes.route_path(conn, :show, a_route.id))

      assert json = json_response(conn, 200)
      assert a_route.id == Map.get(json, "id")
    end
  end

  describe "create" do
    test "returns 201 given valid inputs", %{conn: conn} do
      core_org = valid_core_organization()
      org = DB.create_organization!(core_org)

      new_route_params = %{
        "oui" => org.oui,
        "net_id" => "00000A",
        "max_copies" => 3,
        "server" => %{
          "host" => "server10.testdomain.com",
          "port" => 4567,
          "protocol" => %{
            "type" => "packet_router"
          }
        },
        "devaddr_ranges" => [
          %{"start_addr" => "00020000", "end_addr" => "0002FFFF"}
        ],
        "euis" => [
          %{"app_eui" => "1111111100000000", "dev_eui" => "2222222200000000"}
        ]
      }

      conn = post(conn, Routes.route_path(conn, :create), new_route_params)

      assert got = json_response(conn, 200)

      assert new_route_params == Map.delete(got, "id")
    end

    test "returns 409 given a route that already exists", %{conn: conn} do
      core_org = valid_core_organization()
      org = DB.create_organization!(core_org)

      valid_route_id =
        org
        |> Map.get(:routes)
        |> hd()
        |> Map.get(:id)

      new_route_params = %{
        "id" => valid_route_id,
        "oui" => org.oui,
        "net_id" => "00000A",
        "max_copies" => 5,
        "server" => %{
          "host" => "server10.testdomain.com",
          "port" => 4567,
          "protocol" => %{
            "type" => "packet_router"
          }
        },
        "devaddr_ranges" => [
          %{"start_addr" => "00020000", "end_addr" => "0002FFFF"}
        ],
        "euis" => [
          %{"app_eui" => "1111111100000000", "dev_eui" => "2222222200000000"}
        ]
      }

      assert_error_sent 409, fn ->
        post(conn, Routes.route_path(conn, :create), new_route_params)
      end
    end

    test "returns 400 given a route that refers to a non-existant Organization", %{conn: conn} do
      assert [] == Repo.all(DB.Organization)

      new_route_params = %{
        "oui" => 666,
        "net_id" => "00000A",
        "max_copies" => 3,
        "server" => %{
          "host" => "server10.testdomain.com",
          "port" => 4567,
          "protocol" => %{
            "type" => "packet_router"
          }
        },
        "devaddr_ranges" => [
          %{"start_addr" => "00020000", "end_addr" => "0002FFFF"}
        ],
        "euis" => [
          %{"app_eui" => "1111111100000000", "dev_eui" => "2222222200000000"}
        ]
      }

      assert_error_sent 400, fn ->
        post(conn, Routes.route_path(conn, :create), new_route_params)
      end
    end
  end

  describe "update" do
    test "returns 200 given valid inputs", %{conn: conn} do
      core_org = valid_core_organization()
      org = StartOver.create_organization(core_org)

      existing_route =
        org.routes
        |> hd()

      updated_route =
        existing_route
        |> Map.put(:net_id, 11)
        |> Map.put(:devaddr_ranges, [{0xAAAA_0000, 0xAAAA_FFFF}])
        |> Map.put(:euis, [%{app_eui: 5000, dev_eui: 6000}])
        |> Map.put(:server, %Core.RouteServer{
          host: "updated_host.testdomain.com",
          port: 7890,
          protocol_opts: %Core.PacketRouterOpts{}
        })

      updated_json = RouteView.route_json(updated_route)

      conn = put(conn, Routes.route_path(conn, :update, updated_route.id), updated_json)
      assert json = json_response(conn, 200)

      expected = updated_route
      got = Core.Route.from_web(json)

      assert expected == got
    end

    test "returns 404 given a route ID for which there is no record", %{conn: conn} do
      assert [] == Repo.all(DB.Organization)

      non_existant_uuid = Ecto.UUID.generate()

      new_route_params = %{
        "id" => non_existant_uuid,
        "oui" => 666,
        "net_id" => "00000A",
        "max_copies" => 7,
        "server" => %{
          "host" => "server10.testdomain.com",
          "port" => 4567,
          "protocol" => %{
            "type" => "packet_router"
          }
        },
        "devaddr_ranges" => [
          %{"start_addr" => "00020000", "end_addr" => "0002FFFF"}
        ],
        "euis" => [
          %{"app_eui" => "1111111100000000", "dev_eui" => "2222222200000000"}
        ]
      }

      assert_error_sent 404, fn ->
        put(conn, Routes.route_path(conn, :update, non_existant_uuid), new_route_params)
      end
    end

    test "returns 400 given a route with a valid ID and an invalid OUI", %{conn: conn} do
      valid_org = valid_core_organization()
      db_org = StartOver.create_organization(valid_org)

      existing_db_route = hd(db_org.routes)

      new_route_params = %{
        "id" => existing_db_route.id,
        "oui" => 666,
        "net_id" => "00000A",
        "max_copies" => 4,
        "server" => %{
          "host" => "server10.testdomain.com",
          "port" => 4567,
          "protocol" => %{
            "type" => "packet_router"
          }
        },
        "devaddr_ranges" => [
          %{"start_addr" => "00020000", "end_addr" => "0002FFFF"}
        ],
        "euis" => [
          %{"app_eui" => "1111111100000000", "dev_eui" => "2222222200000000"}
        ]
      }

      assert_error_sent 400, fn ->
        put(conn, Routes.route_path(conn, :update, existing_db_route.id), new_route_params)
      end
    end
  end
end
