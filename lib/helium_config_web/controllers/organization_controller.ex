defmodule HeliumConfigWeb.OrganizationController do
  use HeliumConfigWeb, :controller

  alias HeliumConfig.Core.Organization

  def init(conn), do: conn

  def index(conn, _params) do
    orgs = HeliumConfig.list_organizations()
    render(conn, "organizations.json", organizations: orgs)
  end

  def create(conn, %{"organization" => org_params}) do
    :ok =
      org_params
      |> Organization.from_web()
      |> HeliumConfig.save_organization()

    conn
    |> put_status(201)
    |> json(%{status: "success"})
  end

  def show(conn, %{"id" => id}) do
    org = HeliumConfig.get_organization(id)

    conn
    |> put_status(200)
    |> render("organization.json", organization: org)
  end
end
