defmodule HeliumConfigGRPC.OrganizationView do
  alias HeliumConfig.Core

  def organization_params(%Core.Organization{} = org) do
    %{
      oui: org.oui,
      owner: Core.Crypto.pubkey_to_bin(org.owner_pubkey),
      payer: Core.Crypto.pubkey_to_bin(org.payer_pubkey)
    }
  end
end
