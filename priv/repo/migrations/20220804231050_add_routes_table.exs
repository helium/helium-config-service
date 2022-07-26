defmodule HeliumConfig.Repo.Migrations.AddRoutesTable do
  use Ecto.Migration

  def change do
    create table(:routes) do
      add :oui, references(:organizations, column: :oui, on_delete: :delete_all)
      add :net_id, :integer, null: false
      add :lns_address, :string, null: false
      add :protocol, :string, null: false
      add :euis, {:array, :binary}, null: false

      timestamps()
    end
  end
end
