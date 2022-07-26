import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :helium_config, HeliumConfig.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "helium_config_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :helium_config, HeliumConfigWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "YtGQrwZ2cAvWmFbk7gmDLTXE36JzPbtNNGOcg4GpN4KW1H3/5PyP0mMXhYat/Rer",
  server: false

config :helium_config, HeliumConfigGRPC, auth_enabled: true

# In test we don't send emails.
config :helium_config, HeliumConfig.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

config :grpc, start_server: true

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
