defmodule HeliumConfig.DB do
  alias HeliumConfig.Core
  alias HeliumConfig.DB
  alias HeliumConfig.Repo

  import Ecto.Query

  def next_helium_devaddr_constraint_start do
    {start_addr, _} = Core.DevaddrRange.from_net_id(Core.NetID.from_integer(0xC00053))

    n =
      from(d in DB.DevaddrConstraint, select: max(d.end_nwk_addr))
      |> Repo.one()

    case n do
      nil -> start_addr
      n when is_integer(n) -> Core.Devaddr.with_addr(start_addr, n + 1)
    end
  end

  def list_routes do
    DB.Route
    |> Repo.all()
    |> Enum.map(&route_preloads/1)
  end

  def list_routes_for_organization(oui) do
    from(DB.Route, where: [oui: ^oui])
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

    DB.UpdateNotifier.cast_route_created(result)
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

    DB.UpdateNotifier.cast_route_updated(result)
    result
  end

  def delete_route!(id) do
    current = get_route!(id)

    case Repo.delete(current) do
      {:ok, _} ->
        DB.UpdateNotifier.cast_route_deleted(current)
        current

      {:error, e} ->
        {:error, e}
    end
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
      |> Repo.insert!(returning: true)

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
      |> organization_preloads()

    result
  end

  def delete_organization!(oui) when is_integer(oui) do
    current = get_organization!(oui)

    case Repo.delete(current) do
      {:ok, _} ->
        Enum.each(current.routes, &DB.UpdateNotifier.cast_route_deleted(&1))
        :ok

      {:error, e} ->
        {:error, e}
    end
  end

  defp route_preloads(%DB.Route{} = route) do
    Repo.preload(route, [:server, :devaddr_ranges, :euis])
  end

  defp organization_preloads(%DB.Organization{} = org) do
    Repo.preload(org, [:devaddr_constraints, :routes, [routes: [:server, :devaddr_ranges, :euis]]])
  end
end
