defmodule OtrBunq.GenBalance do
  use GenServer

  import Ecto.Query

  alias OtrBunq.Client
  alias OtrBunq.Repo
  alias OtrBunq.Donation

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_balance do
    GenServer.call(__MODULE__, :get_balance)
  end

  def get_latest_donations do
    GenServer.call(__MODULE__, :get_latest_donations)
  end

  def get_top_donations do
    GenServer.call(__MODULE__, :get_top_donations)
  end

  @impl true
  def init(_) do
    IO.puts("Initializing GenBalance...")
    Process.send(self(), :fetch_initial_balance, [])
    {:ok, %{balance: nil, latest_donations: []}}
  end

  @impl true
  def handle_info(:fetch_initial_balance, state) do
    IO.puts("Fetching initial balance...")

    case Client.get_account_balance() do
      {:ok, balance} ->
        IO.puts("Fetched initial balance: #{balance}")
        schedule_polling()
        {:noreply, %{state | balance: balance}}

      {:error, reason} ->
        IO.puts("Failed to fetch initial balance: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(:get_balance, _from, state) do
    {:reply, state.balance, state}
  end

  @impl true
  def handle_call(:get_latest_donations, _from, state) do
    latest_donations =
      Repo.all(
        from(d in Donation,
          order_by: [desc: d.inserted_at],
          limit: 25
        )
      )

    {:reply, latest_donations, state}
  end

  @impl true
  def handle_call(:get_top_donations, _from, state) do
    top_donations =
      Repo.all(
        from(d in Donation,
          order_by: [desc: d.amount],
          limit: 5
        )
      )

    {:reply, top_donations, state}
  end

  @impl true
  def handle_info(:poll_balance, state) do
    case Client.get_account_balance() do
      {:ok, updated_balance} ->
        delta =
          Float.round(String.to_float(updated_balance) - String.to_float(state.balance || "0"), 2)

        if delta > 0 do
          Repo.insert!(%Donation{
            amount: delta,
            timestamp: DateTime.truncate(DateTime.utc_now(), :second)
          })

          Phoenix.PubSub.broadcast(OtrBunq.PubSub, "balance:updates", %{
            balance: updated_balance,
            delta: delta
          })
        end

        schedule_polling()
        {:noreply, %{state | balance: updated_balance}}

      {:error, reason} ->
        IO.puts("Error polling balance: #{inspect(reason)}")
        schedule_polling()
        {:noreply, state}
    end
  end

  defp schedule_polling do
    Process.send_after(self(), :poll_balance, 10_000)
  end
end
