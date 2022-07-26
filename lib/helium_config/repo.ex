defmodule HeliumConfig.Repo do
  use Ecto.Repo,
    otp_app: :helium_config,
    adapter: Ecto.Adapters.Postgres
end
