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
    IO.puts("Fetching all transactions from Bunq...")

    case fetch_and_sync_all_transactions() do
      {:ok, total_amount} ->
        IO.puts("Computed total amount from transactions: #{total_amount}")

        {:noreply, %{state | balance: total_amount}}

      {:error, reason} ->
        IO.puts("Failed to fetch transactions: #{inspect(reason)}")
        {:noreply, state}
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

  defp fetch_and_sync_all_transactions do
    case Client.get_all_transactions() do
      {:ok, transactions} ->
        total_amount =
          transactions
          |> Enum.reduce(Decimal.new("0.0"), fn tx, acc ->
            Decimal.add(acc, Decimal.new(tx.amount))
          end)

        Enum.each(transactions, fn tx ->
          unless transaction_exists?(tx.bunq_payment_id) do
            created_at = ensure_utc_offset(tx.created_at)

            case DateTime.from_iso8601(created_at) do
              {:ok, timestamp, _offset} ->
                timestamp = DateTime.truncate(timestamp, :second)

                Repo.insert!(%Donation{
                  amount: Decimal.new(tx.amount),
                  bunq_payment_id: tx.bunq_payment_id,
                  description: tx.description,
                  timestamp: timestamp
                })

                IO.puts("Inserted missing transaction: #{tx.bunq_payment_id}")

              {:error, reason} ->
                IO.puts(
                  "Failed to parse DateTime for transaction #{tx.bunq_payment_id}: #{inspect(reason)}"
                )
            end
          end
        end)

        {:ok, total_amount}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp ensure_utc_offset(datetime) do
    if String.ends_with?(datetime, "Z") or Regex.match?(~r/([+-]\d{2}:\d{2})$/, datetime) do
      datetime
    else
      datetime <> "Z"
    end
  end

  defp transaction_exists?(payment_id) do
    Repo.exists?(from(d in Donation, where: d.bunq_payment_id == ^payment_id))
  end
end
