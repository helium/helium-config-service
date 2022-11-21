defmodule HeliumConfigWeb.RouteController do
  use HeliumConfigWeb, :controller

  alias HeliumConfig.Core

  def init(conn), do: conn

  def index(conn, _params) do
    routes = HeliumConfig.list_routes()
    render(conn, "routes.json", routes: routes)
  end

  def show(conn, %{"id" => id}) do
    route = HeliumConfig.get_route(id)
    render(conn, "route.json", route: route)
  end

  def create(conn, route_params) do
    route =
      route_params
      |> Core.Route.from_web()
      |> Core.RouteValidator.validate!()
      |> HeliumConfig.create_route()

    render(conn, "route.json", route: route)
  end

  def update(conn, route_params) do
    route =
      route_params
      |> Core.Route.from_web()
      |> HeliumConfig.update_route()

    render(conn, "route.json", route: route)
  end
end
