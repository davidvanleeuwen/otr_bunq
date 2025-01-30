defmodule OtrBunqWeb.WebhookController do
  use OtrBunqWeb, :controller

  alias OtrBunq.Donations

  @allowed_ips ["185.40.108.0/22"]

  plug :verify_bunq_ip

  def receive_webhook(conn, %{"NotificationUrl" => %{"object" => %{"Payment" => payment}}}) do
    account_id = payment["monetary_account_id"]

    if account_id == OtrBunq.Client.account_id() do
      {:ok, created, _} = DateTime.from_iso8601(payment["created"] <> "Z")

      Donations.add_donation(%{
        amount: String.to_float(payment["amount"]["value"]),
        bunq_payment_id: payment["id"],
        description: payment["description"],
        created: created |> DateTime.truncate(:second)
      })
    end

    send_resp(conn, 200, "OK")
  end

  defp verify_bunq_ip(conn, _opts) do
    if Enum.any?(@allowed_ips, fn ip ->
         :inet.parse_address(to_charlist(ip)) == {:ok, conn.remote_ip}
       end) do
      conn
    else
      conn |> send_resp(403, "Unauthorized") |> halt()
    end
  end
end
