defmodule HeliumConfig.Repo.Migrations.AddOrganizationsTable do
  use Ecto.Migration

  def change do
    create table(:organizations, primary_key: false) do
      add :oui, :integer, primary_key: true
      add :owner_wallet_id, :string, null: false
      add :payer_wallet_id, :string, null: false

      timestamps()
    end
  end
end
