defmodule StartOverWeb.OrganizationView do
  use StartOverWeb, :view

  alias StartOverWeb.RouteView

  def render("organizations.json", %{organizations: orgs}) do
    Enum.map(orgs, &organization_json/1)
  end

  def render("organization.json", %{organization: org}) do
    organization_json(org)
  end

  def organization_json(org) do
    %{
      oui: org.oui,
      owner_wallet_id: org.owner_wallet_id,
      payer_wallet_id: org.payer_wallet_id,
      routes: Enum.map(org.routes, &RouteView.organization_route_json/1)
    }
  end
end
