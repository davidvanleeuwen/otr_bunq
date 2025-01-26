defmodule OtrBunq.Repo.Migrations.CreateDonations do
  use Ecto.Migration

  def change do
    create table(:donations) do
      add :amount, :float
      add :timestamp, :utc_datetime

      timestamps()
    end
  end
end
