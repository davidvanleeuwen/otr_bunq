defmodule OtrBunq.Donation do
  use Ecto.Schema

  schema "donations" do
    field(:amount, :float)
    field(:timestamp, :utc_datetime)

    timestamps()
  end
end
