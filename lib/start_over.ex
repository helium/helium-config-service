defmodule StartOver do
  @moduledoc """
  StartOver keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  alias StartOver.Core
  alias StartOver.DB

  def list_routes do
    DB.list_routes()
    |> Enum.map(&Core.Route.from_db/1)
  end

  def get_route(id) do
    id
    |> DB.get_route!()
    |> Core.Route.from_db()
  end

  def create_route(params) do
    params
    |> DB.create_route!()
    |> Core.Route.from_db()
  end

  def update_route(params) do
    params
    |> DB.update_route!()
    |> Core.Route.from_db()
  end

  def list_organizations do
    DB.list_organizations()
    |> Enum.map(&Core.Organization.from_db/1)
  end

  def get_organization(oui) when is_integer(oui) do
    oui
    |> DB.get_organization!()
    |> Core.Organization.from_db()
  end

  def create_organization(%Core.Organization{} = org) do
    org
    |> DB.create_organization!()
    |> Core.Organization.from_db()
  end

  def update_organization(%Core.Organization{} = org) do
    org
    |> DB.update_organization!()
    |> Core.Organization.from_db()
  end

  def delete_organization!(oui) when is_integer(oui) do
    :ok = DB.delete_organization!(oui)
  end
end
