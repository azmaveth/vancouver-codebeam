defmodule NoThanks.Repo do
  use Ecto.Repo,
    otp_app: :no_thanks,
    adapter: Ecto.Adapters.Postgres
end
