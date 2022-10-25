defmodule StartOver.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      StartOver.Repo,
      # Start the Telemetry supervisor
      StartOverWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: StartOver.PubSub},
      # Start the Endpoint (http/https)
      StartOverWeb.Endpoint,
      # Start a worker by calling: StartOver.Worker.start_link(arg)
      # {StartOver.Worker, arg}
      {GRPC.Server.Supervisor, {StartOverGRPC.Endpoint, 50_051}},
      StartOver.DB.UpdateNotifier
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StartOver.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StartOverWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
