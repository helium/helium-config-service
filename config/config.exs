# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :helium_config,
  ecto_repos: [HeliumConfig.Repo]

# Configures the endpoint
config :helium_config, HeliumConfigWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: HeliumConfigWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: HeliumConfig.PubSub,
  live_view: [signing_salt: "6eyJ5uKZ"]

config :helium_config, HeliumConfigGRPC.Endpoint, port: 50051

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :helium_config, HeliumConfig.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :grpc, start_server: true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
