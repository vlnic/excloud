defmodule Excloud.Repo do
  use Ecto.Repo,
    otp_app: :excloud,
    adapter: Ecto.Adapters.Postgres
end
