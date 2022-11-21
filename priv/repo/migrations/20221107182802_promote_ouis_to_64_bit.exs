defmodule HeliumConfig.Repo.Migrations.PromoteOuisTo64Bit do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      modify :oui, :numeric
    end

    alter table(:routes) do
      modify :oui, :numeric
    end
  end
end
