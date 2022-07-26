defmodule HeliumConfig.Repo.Migrations.AddRouteEuisTable do
  use Ecto.Migration

  def change do
    create table(:route_euis) do
      add :route_id, references(:routes, on_delete: :delete_all)
      add :app_eui, :integer, null: false
      add :dev_eui, :integer, null: false

      timestamps()
    end

    alter table(:routes) do
      remove :euis
    end
  end
end
