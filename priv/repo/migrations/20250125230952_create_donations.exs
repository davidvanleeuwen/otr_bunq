defmodule OtrBunq.Repo.Migrations.CreateDonations do
  use Ecto.Migration

  def change do
    create table(:donations) do
      add :amount, :float
      add :timestamp, :utc_datetime
      add :bunq_payment_id, :integer, null: true
      add :description, :string

      timestamps()
    end
  end
end
