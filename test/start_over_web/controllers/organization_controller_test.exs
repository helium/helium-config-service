defmodule StartOverWeb.OrganizationControllerTest do
  use StartOverWeb.ConnCase

  alias StartOver.DB
  alias StartOver.Repo

  alias StartOverWeb.OrganizationView

  import StartOver.Fixtures

  describe "index" do
    test "returns an empty list when no organizations exist", %{conn: conn} do
      conn = get(conn, Routes.organization_path(conn, :index))
      assert json_response(conn, 200) == []
    end

    test "returns a list of organizations when organizations exist", %{conn: conn} do
      %DB.Organization{oui: expected_oui} =
        valid_core_organization()
        |> DB.create_organization!()

      conn = get(conn, Routes.organization_path(conn, :index))
      assert [%{"oui" => ^expected_oui}] = json_response(conn, 200)
    end
  end

  describe "create organization" do
    test "returns 201 given valid inputs", %{conn: conn} do
      assert [] == Repo.all(DB.Organization)

      valid_org = valid_core_organization()
      valid_json = OrganizationView.organization_json(valid_org)

      conn = post(conn, Routes.organization_path(conn, :create), valid_json)

      assert %{"oui" => _oui} = json_response(conn, 201)
      assert [%DB.Organization{}] = Repo.all(DB.Organization)
    end

    test "returns 409 when a record with the given OUI already exists", %{conn: conn} do
      valid_org = valid_core_organization()
      valid_json = OrganizationView.organization_json(valid_org)

      conn = post(conn, Routes.organization_path(conn, :create), valid_json)
      assert json_response(conn, 201)

      assert_error_sent 409, fn ->
        post(conn, Routes.organization_path(conn, :create), valid_json)
      end
    end

    test "returns 400 given invalid inputs", %{conn: conn} do
      bad_org =
        valid_core_organization()
        |> Map.put(:oui, -1)

      bad_json = OrganizationView.organization_json(bad_org)

      {400, _headers, body} =
        assert_error_sent 400, fn ->
          post(conn, Routes.organization_path(conn, :create), bad_json)
        end

      assert(
        body ==
          Jason.encode!(%{
            error: "invalid organization: [oui: \"oui must be a positive unsigned integer\"]"
          })
      )
    end
  end

  describe "update organization" do
    test "returns 200 given valid inputs", %{conn: conn} do
      valid_org = valid_core_organization()
      %DB.Organization{oui: oui} = DB.create_organization!(valid_org)

      updated_org =
        valid_org
        |> Map.put(:owner_wallet_id, "updated_wallet_id")

      updated_json = OrganizationView.organization_json(updated_org)

      conn = put(conn, Routes.organization_path(conn, :update, valid_org.oui), updated_json)

      assert %{"oui" => ^oui} = json_response(conn, 200)
    end

    test "returns 200 when no organization record exists and inputs are valid", %{conn: conn} do
      assert [] == Repo.all(DB.Organization)

      valid_org = valid_core_organization()
      valid_json = OrganizationView.organization_json(valid_org)

      conn = put(conn, Routes.organization_path(conn, :update, valid_org.oui), valid_json)

      assert %{"oui" => _oui} = json_response(conn, 200)
      assert [%DB.Organization{}] = Repo.all(DB.Organization)
    end
  end

  describe "show organization" do
    test "returns 200 when a record exists for the given OUI", %{conn: conn} do
      org =
        valid_core_organization()
        |> DB.create_organization!()

      conn = get(conn, Routes.organization_path(conn, :show, org.oui))

      expected_oui = org.oui

      assert %{"oui" => ^expected_oui} = json_response(conn, 200)
    end

    test "returns 404 when no record exists for the given OUI", %{conn: conn} do
      assert [] == Repo.all(DB.Organization)

      assert_error_sent 404, fn ->
        get(conn, Routes.organization_path(conn, :show, -1))
      end
    end
  end

  describe "delete organization" do
    test "returns 404 when no record exists for the given OUI", %{conn: conn} do
      assert_error_sent 404, fn ->
        delete(conn, Routes.organization_path(conn, :delete, 666))
      end
    end

    test "returns 204 given valid inputs", %{conn: conn} do
      valid_core_org = valid_core_organization()
      DB.create_organization!(valid_core_org)

      conn = delete(conn, Routes.organization_path(conn, :delete, valid_core_org.oui))

      assert conn.status == 204
    end
  end
end
