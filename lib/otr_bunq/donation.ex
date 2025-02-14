defmodule OtrBunq.Donation do
  use Ecto.Schema

  schema "donations" do
    field(:amount, :decimal)
    field(:timestamp, :utc_datetime)
    field(:bunq_payment_id, :integer)
    field(:description, :string)

    timestamps()
  end
end
