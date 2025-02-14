defmodule OtrBunq.Donations do
  @moduledoc """
  Provides an interface for retrieving donation-related data.
  """

  import Ecto.Query
  alias OtrBunq.{Repo, Donation}
  alias Phoenix.PubSub

  @doc """
  Inserts a new donation, then broadcasts updates.
  """
  def add_donation(%{
        amount: amount,
        bunq_payment_id: payment_id,
        description: description,
        created: created
      }) do
    rounded_amount = Decimal.new(amount) |> Decimal.round(2)

    donation =
      %Donation{
        amount: rounded_amount,
        bunq_payment_id: payment_id,
        description: description,
        timestamp: created
      }
      |> Repo.insert!()

    latest_donations = get_latest_donations()
    top_donations = get_top_donations()
    balance = get_balance()

    # Broadcast to all clients listening on "donations:updates"
    PubSub.broadcast(OtrBunq.PubSub, "donations:updates", %{
      latest_donations: latest_donations,
      top_donations: top_donations,
      balance: balance,
      delta: amount
    })

    donation
  end

  @doc """
  Returns the total balance from all donations.
  """
  def get_balance do
    balance = Repo.aggregate(Donation, :sum, :amount) || Decimal.new(0)
    Decimal.round(balance, 2)
  end

  @doc """
  Returns the latest 25 donations.
  """
  def get_latest_donations do
    Donation
    |> where([d], d.bunq_payment_id != 0)
    |> order_by([d], desc: d.inserted_at)
    |> limit(25)
    |> Repo.all()
  end

  @doc """
  Returns the top 5 highest donations.
  """
  def get_top_donations do
    Donation
    |> where([d], d.bunq_payment_id != 0)
    |> order_by([d], desc: d.amount)
    |> limit(5)
    |> Repo.all()
  end
end
