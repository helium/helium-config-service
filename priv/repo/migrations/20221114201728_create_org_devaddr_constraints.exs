defmodule HeliumConfig.Repo.Migrations.CreateOrgDevaddrConstraints do
  use Ecto.Migration

  def change do
    create table("organization_devaddr_constraints") do
      add :oui, references(:organizations, column: :oui, type: :numeric, on_delete: :delete_all)
      add :type, :string, null: false
      add :nwk_id, :integer, null: false
      add :start_nwk_addr, :integer, null: false
      add :end_nwk_addr, :integer, null: false

      timestamps()
    end
  end
end
