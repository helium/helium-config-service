defmodule HeliumConfig.Repo.Migrations.AddDevaddrRangeTable do
  use Ecto.Migration

  def change do
    create table(:devaddr_ranges, primary_key: false) do
      add :route_id, references(:routes, on_delete: :delete_all), primary_key: true
      add :start_addr, :integer, primary_key: true
      add :end_addr, :integer, primary_key: true

      timestamps()
    end
  end
end
