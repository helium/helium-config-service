defmodule HeliumConfigWeb.RouteController do
  use HeliumConfigWeb, :controller

  def init(conn), do: conn

  def index(conn, _params) do
    routes = HeliumConfig.list_routes()
    render(conn, "routes.json", routes: routes)
  end
end
