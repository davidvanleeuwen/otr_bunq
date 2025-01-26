defmodule OtrBunq.Repo do
  use Ecto.Repo,
    otp_app: :otr_bunq,
    adapter: Ecto.Adapters.SQLite3
end
