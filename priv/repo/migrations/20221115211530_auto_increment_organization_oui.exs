defmodule HeliumConfig.Repo.Migrations.AutoIncrementOrganizationOui do
  use Ecto.Migration

  def change do
    repo().query!("create sequence organization_oui_seq")

    repo().query!(
      "ALTER TABLE organizations ALTER COLUMN oui SET DEFAULT nextval('organization_oui_seq')"
    )
  end
end
