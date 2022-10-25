defmodule StartOverWeb.Router do
  use StartOverWeb, :router

  use Plug.ErrorHandler

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", StartOverWeb do
    pipe_through :api

    get "/organizations", OrganizationController, :index
    post "/organizations", OrganizationController, :create
    get "/organizations/:oui", OrganizationController, :show
    put "/organizations/:oui", OrganizationController, :update
    delete "/organizations/:oui", OrganizationController, :delete

    get "/routes", RouteController, :index
    get "/routes/:id", RouteController, :show
    post "/routes", RouteController, :create
    put "/routes/:id", RouteController, :update
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{
        kind: :error,
        reason: %StartOver.Core.InvalidDataError{message: message}
      }) do
    send_resp(conn, 400, Jason.encode!(%{error: message}))
  end

  def handle_errors(conn, %{kind: :error, reason: %Ecto.NoResultsError{}}) do
    send_resp(conn, 404, "")
  end

  def handle_errors(conn, %{kind: :error, reason: %Ecto.InvalidChangesetError{}}) do
    send_resp(conn, 400, "")
  end

  def handle_errors(conn, %{kind: :error, reason: %Ecto.ConstraintError{}}) do
    send_resp(conn, 409, "")
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: StartOverWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
