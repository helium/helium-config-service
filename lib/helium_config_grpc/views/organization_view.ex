defmodule HeliumConfigGRPC.OrganizationView do

  alias HeliumConfig.Core

  def organization_params(%Core.Organization{} = org) do
    %{
      oui: org.oui,
      owner: org.owner_wallet_id,
      payer: org.payer_wallet_id
    }
  end
end
