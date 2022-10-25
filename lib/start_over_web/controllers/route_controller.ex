defmodule StartOverWeb.RouteController do
  use StartOverWeb, :controller

  alias StartOver.Core

  def init(conn), do: conn

  def index(conn, _params) do
    routes = StartOver.list_routes()
    render(conn, "routes.json", routes: routes)
  end

  def show(conn, %{"id" => id}) do
    route = StartOver.get_route(id)
    render(conn, "route.json", route: route)
  end

  def create(conn, route_params) do
    route =
      route_params
      |> Core.Route.from_web()
      |> StartOver.create_route()

    render(conn, "route.json", route: route)
  end

  def update(conn, route_params) do
    route =
      route_params
      |> Core.Route.from_web()
      |> StartOver.update_route()

    render(conn, "route.json", route: route)
  end
end
