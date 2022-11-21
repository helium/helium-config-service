defmodule HeliumConfigGRPC.OrganizationView do
  alias HeliumConfig.Core

  def org_res_params(%Core.Organization{} = org) do
    net_id = net_id_from_constraint(hd(org.devaddr_constraints))

    %{
      org: organization_params(org),
      net_id: net_id,
      devaddr_ranges: Enum.map(org.devaddr_constraints, &constraint_params/1)
    }
  end

  def constraint_params({%Core.Devaddr{} = s, %Core.Devaddr{} = e}) do
    %{
      start_addr: Core.Devaddr.to_integer(s),
      end_addr: Core.Devaddr.to_integer(e)
    }
  end

  def net_id_from_constraint(range) do
    range
    |> Core.DevaddrRange.to_net_id()
    |> Core.NetID.to_integer()
  end

  def organization_params(%Core.Organization{} = org) do
    %{
      oui: org.oui,
      owner: Core.Crypto.pubkey_to_bin(org.owner_pubkey),
      payer: Core.Crypto.pubkey_to_bin(org.payer_pubkey)
    }
  end
end
