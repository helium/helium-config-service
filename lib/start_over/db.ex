defmodule StartOver.DB do
  alias StartOver.Core
  alias StartOver.DB
  alias StartOver.Repo

  def list_routes do
    DB.Route
    |> Repo.all()
    |> Enum.map(&route_preloads/1)
  end

  def get_route!(id) do
    DB.Route
    |> Repo.get!(id)
    |> route_preloads()
  end

  def create_route!(params) do
    result =
      %DB.Route{}
      |> DB.Route.changeset(params)
      |> Repo.insert!()

    DB.UpdateNotifier.notify_cast()
    result
  end

  def update_route!(params) do
    current =
      DB.Route
      |> Repo.get!(params.id)
      |> route_preloads()

    result =
      current
      |> DB.Route.changeset(params)
      |> Repo.insert_or_update!()

    DB.UpdateNotifier.notify_cast()
    result
  end

  def list_organizations do
    DB.Organization
    |> Repo.all()
    |> Enum.map(&organization_preloads/1)
  end

  def create_organization!(%Core.Organization{} = core_org) do
    result =
      %DB.Organization{}
      |> DB.Organization.changeset(core_org)
      |> Repo.insert!()

    DB.UpdateNotifier.notify_cast()
    result
  end

  def get_organization!(oui) when is_integer(oui) do
    DB.Organization
    |> Repo.get!(oui)
    |> organization_preloads()
  end

  def update_organization!(%Core.Organization{} = new_org) do
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
      |> Repo.insert_or_update!()

    DB.UpdateNotifier.notify_cast()
    result
  end

  def delete_organization!(oui) when is_integer(oui) do
    current = Repo.get!(DB.Organization, oui)

    case Repo.delete(current) do
      {:ok, _} ->
        DB.UpdateNotifier.notify_cast()
        :ok

      {:error, e} ->
        {:error, e}
    end
  end

  defp route_preloads(%DB.Route{} = route) do
    Repo.preload(route, [:server, :devaddr_ranges, :euis])
  end

  defp organization_preloads(%DB.Organization{} = org) do
    Repo.preload(org, [:routes, [routes: [:server, :devaddr_ranges, :euis]]])
  end
end
