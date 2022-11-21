defmodule HeliumConfig.Repo.Migrations.RenameOrgWalletIdColumns do
  use Ecto.Migration

  def change do
    rename table(:organizations), :owner_wallet_id, to: :owner_pubkey
    rename table(:organizations), :payer_wallet_id, to: :payer_pubkey
  end
end
