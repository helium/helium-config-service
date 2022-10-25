defmodule HeliumConfig.DB.OrganizationTest do
  use HeliumConfig.DataCase, async: false

  alias HeliumConfig.DB

  import HeliumConfig.Fixtures

  describe "Organization.changeset/2" do
    test "returns a valid changeset given a valid Core.Organization" do
      core_org = valid_core_organization()
      got = DB.Organization.changeset(%DB.Organization{}, core_org)

      assert(true == got.valid?)

      assert({:ok, %DB.Organization{}} = Repo.insert(got))
    end
  end
end
