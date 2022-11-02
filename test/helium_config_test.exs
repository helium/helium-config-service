defmodule HeliumConfigTest do
  use HeliumConfig.DataCase

  import HeliumConfig.Fixtures

  alias HeliumConfig.DB
  alias HeliumConfig.Core

  describe "HeliumConfig.list_routes_for_organization/1" do
    test "returns a list of %Core.Route{} when records exist for the given OUI" do
      create_valid_organization()
      result = HeliumConfig.list_routes_for_organization(1)
      assert([%Core.Route{}, %Core.Route{}, %Core.Route{}] = result)
    end
  end

  defp create_valid_organization do
    valid_org = valid_core_organization()

    %DB.Organization{}
    |> DB.Organization.changeset(valid_org)
    |> Repo.insert!()
  end
end
