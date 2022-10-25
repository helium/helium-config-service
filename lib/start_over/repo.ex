defmodule StartOver.Repo do
  use Ecto.Repo,
    otp_app: :start_over,
    adapter: Ecto.Adapters.Postgres
end
