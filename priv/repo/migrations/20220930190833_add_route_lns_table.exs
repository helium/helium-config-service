defmodule HeliumConfig.Repo.Migrations.AddRouteLnsTable do
  use Ecto.Migration

  def change do
    alter table("routes") do
      remove :lns_address
      remove :protocol
    end

    create table("route_lns") do
      add :route_id, references(:routes, on_delete: :delete_all), primary_key: true
      add :type, :string
      add :host, :string
      add :port, :integer
      add :protocol_params, :map

      timestamps()
    end
  end
end
