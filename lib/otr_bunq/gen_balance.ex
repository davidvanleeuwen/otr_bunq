defmodule OtrBunq.GenBalance do
  use GenServer

  import Ecto.Query

  alias OtrBunq.{Client, Repo, Donation}

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    Process.send(self(), :fetch_initial_balance, [])
    Process.send(self(), :register_webhook, [])
    {:ok, %{balance: nil}}
  end

  @impl true
  def handle_info(:fetch_initial_balance, state) do
    IO.puts("Checking if we need to fetch an initial balance...")

    case Repo.one(from(d in Donation, select: count(d.id))) do
      0 ->
        IO.puts("No donations found, fetching initial balance from Bunq...")

        case Client.get_account_balance() do
          {:ok, balance} ->
            initial_amount = String.to_float(balance)

            IO.puts("Fetched initial balance: #{initial_amount}, storing as first donation.")

            Repo.insert!(%Donation{
              amount: initial_amount,
              timestamp: DateTime.truncate(DateTime.utc_now(), :second),
              bunq_payment_id: 0
            })

            {:noreply, %{state | balance: initial_amount}}

          {:error, reason} ->
            IO.puts("Failed to fetch initial balance: #{inspect(reason)}")
            {:noreply, state}
        end

      _ ->
        IO.puts("Existing donations found, skipping Bunq API call.")
        balance = Repo.aggregate(Donation, :sum, :amount) || 0
        {:noreply, %{state | balance: balance}}
    end
  end

  @impl true
  def handle_info(:register_webhook, state) do
    case Client.register_webhook() do
      {:ok, _} -> IO.puts("Webhook setup complete.")
      {:error, reason} -> IO.puts("Webhook setup failed: #{inspect(reason)}")
    end

    {:noreply, state}
  end
end
