defmodule OtrBunq.Repo.Migrations.ChangeAmountToDecimal do
  use Ecto.Migration

  def change do
    create table(:donations_new) do
      add :amount, :decimal, precision: 10, scale: 2, null: false
      add :bunq_payment_id, :integer, null: true
      add :description, :string
      add :timestamp, :utc_datetime

      timestamps()
    end

    execute "INSERT INTO donations_new (id, amount, bunq_payment_id, description, timestamp, inserted_at, updated_at)
             SELECT id, ROUND(amount, 2), bunq_payment_id, description, timestamp, inserted_at, updated_at FROM donations"

    drop table(:donations)

    execute "ALTER TABLE donations_new RENAME TO donations"
  end

end
