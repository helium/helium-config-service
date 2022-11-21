defmodule HeliumConfigWeb.OrganizationView do
  use HeliumConfigWeb, :view

  alias HeliumConfig.Core
  alias HeliumConfigWeb.RouteView

  def render("organizations.json", %{organizations: orgs}) do
    Enum.map(orgs, &organization_json/1)
  end

  def render("organization.json", %{organization: org}) do
    organization_json(org)
  end

  def organization_json(org) do
    %{
      oui: org.oui,
      owner_pubkey: Core.Crypto.pubkey_to_b58(org.owner_pubkey),
      payer_pubkey: Core.Crypto.pubkey_to_b58(org.payer_pubkey),
      routes: Enum.map(org.routes, &RouteView.organization_route_json/1),
      devaddr_constraints: RouteView.devaddr_range_json(org.devaddr_constraints)
    }
  end
end
