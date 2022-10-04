defmodule HeliumConfig do
  @moduledoc """
  HeliumConfig keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias HeliumConfig.Core
  alias HeliumConfig.DB
  alias HeliumConfig.Repo

  def get_organization(oui) do
    DB.Organization
    |> Repo.get(oui)
    |> organization_preloads()
    |> Core.Organization.from_db()
  end

  def insert_organization(org = %Core.Organization{}) do
    result =
      org
      |> DB.Organization.changeset()
      |> Repo.insert()

    case result do
      {:ok, _} ->
        DB.UpdateNotifier.notify_cast()
        :ok

      {:error, e} ->
        {:error, e}
    end
  end

  def save_organization(new_org = %Core.Organization{}) do
    current =
      case Repo.get(DB.Organization, new_org.oui) do
        nil ->
          %DB.Organization{oui: new_org.oui}

        existing_org ->
          existing_org
          |> organization_preloads()
      end

    result =
      current
      |> DB.Organization.changeset(new_org)
      |> Repo.insert_or_update()

    case result do
      {:ok, _} ->
        DB.UpdateNotifier.notify_cast()
        :ok

      {:error, e} ->
        {:error, e}
    end
  end

  def delete_organization(%Core.Organization{oui: oui}) do
    delete_organization(oui)
  end

  def delete_organization(oui) when is_integer(oui) do
    current =
      DB.Organization
      |> Repo.get!(oui)

    case Repo.delete(current) do
      {:ok, _} ->
        DB.UpdateNotifier.notify_cast()
        :ok

      {:error, e} ->
        {:error, e}
    end
  end

  def list_organizations do
    DB.Organization
    |> Repo.all()
    |> organization_preloads()
    |> Enum.map(&Core.Organization.from_db/1)
  end

  def list_routes do
    DB.Route
    |> Repo.all()
    |> Repo.preload([:devaddr_ranges, :euis, :lns])
    |> Enum.map(&Core.Route.from_db/1)
  end

  defp organization_preloads(org) do
    org
    |> Repo.preload(routes: [:devaddr_ranges, :euis, :lns])
  end
end
