defmodule HeliumConfigWeb.OrganizationController do
  use HeliumConfigWeb, :controller

  alias HeliumConfig.Core

  def init(conn), do: conn

  def index(conn, _params) do
    orgs = HeliumConfig.list_organizations()
    render(conn, "organizations.json", organizations: orgs)
  end

  def create(conn, params) do
    org =
      params
      |> Core.Organization.from_web()
      |> Core.OrganizationValidator.validate!()
      |> HeliumConfig.create_organization!()

    conn
    |> put_status(201)
    |> render("organization.json", organization: org)
  end

  def update(
        %{
          path_params: %{"oui" => oui},
          body_params: updated_params
        } = conn,
        _params
      ) do
    updated_org =
      updated_params
      |> Core.Organization.from_web()
      |> Map.put(:oui, oui)
      |> HeliumConfig.update_organization!()

    conn
    |> put_status(200)
    |> render("organization.json", organization: updated_org)
  end

  def show(conn, %{"oui" => oui_param}) do
    org =
      oui_param
      |> Core.Organization.oui_from_web()
      |> HeliumConfig.get_organization()

    conn
    |> put_status(200)
    |> render("organization.json", organization: org)
  end

  def delete(conn, %{"oui" => oui}) when is_binary(oui) do
    oui = String.to_integer(oui, 10)
    HeliumConfig.delete_organization!(oui)

    conn
    |> put_status(204)
  end
end
