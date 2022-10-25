defmodule StartOver.DB.OrganizationTest do
  use StartOver.DataCase, async: false

  alias StartOver.DB

  import StartOver.Fixtures

  describe "Organization.changeset/2" do
    test "returns a valid changeset given a valid Core.Organization" do
      core_org = valid_core_organization()
      got = DB.Organization.changeset(%DB.Organization{}, core_org)

      assert(true == got.valid?)

      assert({:ok, %DB.Organization{}} = Repo.insert(got))
    end
  end
end
