defmodule StartOver.DB.RouteTest do
  use StartOver.DataCase, async: false

  alias StartOver.DB.Organization
  alias StartOver.DB.Route
  alias StartOver.Repo

  import StartOver.Fixtures

  setup ctx do
    # The tests in this module require an organization with no routes.
    org_params =
      valid_core_organization()
      |> Map.put(:routes, [])

    org = Organization.changeset(%Organization{}, org_params)

    Repo.insert!(org)

    ctx
  end

  describe "Route.changeset/2" do
    test "returns a valid changeset given a valid HTTP Roaming Core.Route" do
      roaming_route = valid_http_roaming_route()
      got = Route.changeset(%Route{}, roaming_route)

      assert(true == got.valid?)

      assert({:ok, %Route{}} = Repo.insert(got))
    end

    test "returns a valid changeset given a valid GWMP Core.Route" do
      gwmp_route = valid_gwmp_route()
      got = Route.changeset(%Route{}, gwmp_route)

      assert(true == got.valid?)

      assert({:ok, %Route{}} = Repo.insert(got))
    end

    test "returns a valid changeset given a valid Packet Router Route" do
      router_route = valid_packet_router_route()
      got = Route.changeset(%Route{}, router_route)

      assert(true == got.valid?)

      assert({:ok, %Route{}} = Repo.insert(got))
    end
  end

  test "the underlying data type for EUIs is sufficiently large" do
    route =
      valid_core_route()
      |> Map.put(:euis, [
        %{
          app_eui: 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF,
          dev_eui: 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF
        }
      ])

    got = Route.changeset(%Route{}, route)

    assert(true == got.valid?)

    assert({:ok, %Route{euis: [eui]}} = Repo.insert(got))

    expected = Decimal.new(0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF)

    assert(expected == eui.app_eui)
    assert(expected == eui.dev_eui)
  end
end
